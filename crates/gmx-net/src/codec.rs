//! The tokio codec for NUL-terminated frames.
//!
//! Splitting is delegated to [`gmx_proto::FrameDecoder`], so the async and
//! sync paths share one implementation.

use std::borrow::Cow;
use std::io;

use bytes::{Bytes, BytesMut};
use gmx_proto::{DecodeError, Dialect, FrameDecoder, FrameError, Message, encode_frame};
use tokio_util::codec::{Decoder, Encoder};

/// One unit read from a connection.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Inbound {
    /// A complete frame, without its NUL.
    Frame(Vec<u8>),
    /// A frame exceeded the size limit and was dropped. The connection
    /// stays usable.
    Dropped(FrameError),
}

impl Inbound {
    /// Decodes a frame into a message. `None` for a dropped frame.
    pub fn decode(&self) -> Option<Result<Message, DecodeError>> {
        match self {
            Self::Frame(bytes) => Some(Message::decode_frame(bytes)),
            Self::Dropped(_) => None,
        }
    }

    /// The frame as text, replacing invalid UTF-8. `None` for a dropped
    /// frame.
    pub fn text(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::Frame(bytes) => Some(String::from_utf8_lossy(bytes)),
            Self::Dropped(_) => None,
        }
    }
}

/// A frame ready to write, NUL included. Cloning is cheap, so one encoded
/// frame can be queued for many clients.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OutFrame(Bytes);

impl OutFrame {
    /// Frames a payload.
    pub fn new(payload: &str) -> Self {
        let mut bytes = Vec::with_capacity(payload.len() + 1);
        encode_frame(payload, &mut bytes);
        Self(bytes.into())
    }

    /// Frames a payload that may not be UTF-8, such as a frame being
    /// relayed unchanged. A NUL in `payload` is replaced, as in
    /// [`OutFrame::new`].
    pub fn from_payload(payload: &[u8]) -> Self {
        if payload.contains(&0) {
            return Self::new(&String::from_utf8_lossy(payload));
        }
        let mut bytes = Vec::with_capacity(payload.len() + 1);
        bytes.extend_from_slice(payload);
        bytes.push(0);
        Self(bytes.into())
    }

    /// Encodes a message as one or more frames.
    pub fn from_message(message: &Message, dialect: Dialect) -> Vec<Self> {
        message
            .encode(dialect)
            .iter()
            .map(|payload| Self::new(payload))
            .collect()
    }

    /// The payload, without the NUL.
    pub fn payload(&self) -> &[u8] {
        &self.0[..self.0.len() - 1]
    }
}

/// Decodes [`Inbound`] frames and encodes [`OutFrame`]s.
#[derive(Debug)]
pub struct FrameCodec {
    decoder: FrameDecoder,
}

impl FrameCodec {
    /// Creates a codec with the given frame size limit.
    pub fn new(max_frame_bytes: usize) -> Self {
        Self {
            decoder: FrameDecoder::new(max_frame_bytes),
        }
    }
}

impl Default for FrameCodec {
    fn default() -> Self {
        Self::new(gmx_proto::DEFAULT_MAX_FRAME_BYTES)
    }
}

impl Decoder for FrameCodec {
    type Item = Inbound;
    type Error = io::Error;

    fn decode(&mut self, src: &mut BytesMut) -> io::Result<Option<Inbound>> {
        if !src.is_empty() {
            self.decoder.push(src);
            src.clear();
        }
        Ok(self.decoder.next_frame().map(|frame| match frame {
            Ok(bytes) => Inbound::Frame(bytes),
            Err(error) => Inbound::Dropped(error),
        }))
    }

    fn decode_eof(&mut self, src: &mut BytesMut) -> io::Result<Option<Inbound>> {
        if let Some(inbound) = self.decode(src)? {
            return Ok(Some(inbound));
        }
        Ok(self.decoder.finish().map(Inbound::Frame))
    }
}

impl Encoder<OutFrame> for FrameCodec {
    type Error = io::Error;

    fn encode(&mut self, frame: OutFrame, dst: &mut BytesMut) -> io::Result<()> {
        dst.extend_from_slice(&frame.0);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use futures_util::{SinkExt, StreamExt};
    use tokio::io::AsyncWriteExt;
    use tokio_util::codec::{FramedRead, FramedWrite};

    #[tokio::test]
    async fn frames_survive_arbitrary_chunking() {
        let (client, server) = tokio::io::duplex(7);
        let writer = tokio::spawn(async move {
            let mut sink = FramedWrite::new(client, FrameCodec::default());
            for payload in ["<a/>", "", "<b>é</b>", "LIST_RECORDS"] {
                sink.send(OutFrame::new(payload)).await.unwrap();
            }
        });
        let frames: Vec<_> = FramedRead::new(server, FrameCodec::default())
            .map(|r| r.unwrap())
            .collect()
            .await;
        writer.await.unwrap();
        assert_eq!(
            frames,
            [
                Inbound::Frame(b"<a/>".to_vec()),
                Inbound::Frame("<b>é</b>".as_bytes().to_vec()),
                Inbound::Frame(b"LIST_RECORDS".to_vec()),
            ]
        );
    }

    #[tokio::test]
    async fn oversized_frame_is_reported_and_stream_continues() {
        let (mut client, server) = tokio::io::duplex(64);
        client.write_all(b"0123456789\0ok\0tail").await.unwrap();
        drop(client);
        let frames: Vec<_> = FramedRead::new(server, FrameCodec::new(4))
            .map(|r| r.unwrap())
            .collect()
            .await;
        assert_eq!(
            frames,
            [
                Inbound::Dropped(FrameError::TooLong { limit: 4 }),
                Inbound::Frame(b"ok".to_vec()),
                Inbound::Frame(b"tail".to_vec()),
            ]
        );
    }

    #[test]
    fn out_frame_payload_and_messages() {
        let frame = OutFrame::new("<a/>");
        assert_eq!(frame.payload(), b"<a/>");
        assert_eq!(OutFrame::from_payload(b"<a/>"), frame);
        assert_eq!(OutFrame::from_payload(&[0xff]).payload(), [0xff]);
        let refresh = Message::Refresh(Default::default());
        let frames = OutFrame::from_message(&refresh, Dialect::Bare);
        assert_eq!(frames, [OutFrame::new("<ISISRefresh/>")]);
        let inbound = Inbound::Frame(frames[0].payload().to_vec());
        assert_eq!(inbound.decode(), Some(Ok(refresh)));
        assert_eq!(inbound.text().as_deref(), Some("<ISISRefresh/>"));
        assert_eq!(
            Inbound::Dropped(FrameError::TooLong { limit: 1 }).decode(),
            None
        );
    }
}
