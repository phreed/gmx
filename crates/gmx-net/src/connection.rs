//! One framed TCP connection.

use std::io;
use std::net::SocketAddr;

use futures_util::{SinkExt, StreamExt};
use gmx_proto::{Dialect, Message};
use tokio::net::tcp::{OwnedReadHalf, OwnedWriteHalf};
use tokio::net::{TcpStream, ToSocketAddrs};
use tokio_util::codec::{Framed, FramedRead, FramedWrite};

use crate::codec::{FrameCodec, Inbound, OutFrame};

/// A TCP stream carrying NUL-terminated frames.
///
/// [`Connection::recv`] is cancel safe, so it can be used in
/// `tokio::select!` alongside other work.
#[derive(Debug)]
pub struct Connection {
    framed: Framed<TcpStream, FrameCodec>,
    peer: SocketAddr,
}

impl Connection {
    /// Connects to a peer.
    pub async fn connect(addr: impl ToSocketAddrs, max_frame_bytes: usize) -> io::Result<Self> {
        Self::new(TcpStream::connect(addr).await?, max_frame_bytes)
    }

    /// Wraps an accepted or connected stream.
    ///
    /// Disables Nagle's algorithm: GMX messages are small and latency
    /// sensitive.
    pub fn new(stream: TcpStream, max_frame_bytes: usize) -> io::Result<Self> {
        stream.set_nodelay(true)?;
        let peer = stream.peer_addr()?;
        Ok(Self {
            framed: Framed::new(stream, FrameCodec::new(max_frame_bytes)),
            peer,
        })
    }

    /// The remote address.
    pub fn peer(&self) -> SocketAddr {
        self.peer
    }

    /// The local address.
    pub fn local_addr(&self) -> io::Result<SocketAddr> {
        self.framed.get_ref().local_addr()
    }

    /// Sends one frame and flushes.
    pub async fn send(&mut self, frame: OutFrame) -> io::Result<()> {
        self.framed.send(frame).await
    }

    /// Sends several frames with one flush.
    pub async fn send_all(&mut self, frames: impl IntoIterator<Item = OutFrame>) -> io::Result<()> {
        for frame in frames {
            self.framed.feed(frame).await?;
        }
        self.framed.flush().await
    }

    /// Encodes and sends a message.
    pub async fn send_message(&mut self, message: &Message, dialect: Dialect) -> io::Result<()> {
        self.send_all(OutFrame::from_message(message, dialect))
            .await
    }

    /// Queues a frame without flushing. Pair with [`Connection::flush`].
    pub async fn feed(&mut self, frame: OutFrame) -> io::Result<()> {
        self.framed.feed(frame).await
    }

    /// Flushes queued frames.
    pub async fn flush(&mut self) -> io::Result<()> {
        self.framed.flush().await
    }

    /// Receives the next frame. `None` when the peer has closed.
    pub async fn recv(&mut self) -> Option<io::Result<Inbound>> {
        self.framed.next().await
    }

    /// Splits into halves that can be used from separate tasks.
    ///
    /// Buffered input, partial frames and unflushed output carry over.
    /// Dropping the writer shuts down the sending side of the socket.
    pub fn into_split(self) -> (ConnectionReader, ConnectionWriter) {
        let peer = self.peer;
        let parts = self.framed.into_parts();
        let (read_half, write_half) = parts.io.into_split();
        let mut reader = FramedRead::new(read_half, parts.codec);
        reader.read_buffer_mut().extend_from_slice(&parts.read_buf);
        // Encoding is stateless, so a fresh codec serves the writer.
        let mut writer = FramedWrite::new(write_half, FrameCodec::default());
        writer
            .write_buffer_mut()
            .extend_from_slice(&parts.write_buf);
        (
            ConnectionReader { reader, peer },
            ConnectionWriter { writer, peer },
        )
    }
}

/// The receiving half of a [`Connection`].
#[derive(Debug)]
pub struct ConnectionReader {
    reader: FramedRead<OwnedReadHalf, FrameCodec>,
    peer: SocketAddr,
}

impl ConnectionReader {
    /// The remote address.
    pub fn peer(&self) -> SocketAddr {
        self.peer
    }

    /// Receives the next frame. `None` when the peer has closed. Cancel safe.
    pub async fn recv(&mut self) -> Option<io::Result<Inbound>> {
        self.reader.next().await
    }
}

/// The sending half of a [`Connection`].
#[derive(Debug)]
pub struct ConnectionWriter {
    writer: FramedWrite<OwnedWriteHalf, FrameCodec>,
    peer: SocketAddr,
}

impl ConnectionWriter {
    /// The remote address.
    pub fn peer(&self) -> SocketAddr {
        self.peer
    }

    /// Sends one frame and flushes.
    pub async fn send(&mut self, frame: OutFrame) -> io::Result<()> {
        self.writer.send(frame).await
    }

    /// Encodes and sends a message.
    pub async fn send_message(&mut self, message: &Message, dialect: Dialect) -> io::Result<()> {
        for frame in OutFrame::from_message(message, dialect) {
            self.writer.feed(frame).await?;
        }
        self.writer.flush().await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use gmx_proto::{Command, DEFAULT_MAX_FRAME_BYTES};
    use tokio::net::TcpListener;

    #[tokio::test]
    async fn exchanges_messages_over_tcp() {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let (stream, _) = listener.accept().await.unwrap();
            let mut conn = Connection::new(stream, DEFAULT_MAX_FRAME_BYTES).unwrap();
            let inbound = conn.recv().await.unwrap().unwrap();
            assert_eq!(
                inbound.decode(),
                Some(Ok(Message::Command(Command::ListLayouts)))
            );
            let reply = Message::Command(Command::Layouts(vec!["mainLuid".into()]));
            conn.send_message(&reply, Dialect::Invoke).await.unwrap();
        });

        let mut conn = Connection::connect(addr, DEFAULT_MAX_FRAME_BYTES)
            .await
            .unwrap();
        assert_eq!(conn.peer(), addr);
        conn.send(OutFrame::new("LIST_LAYOUTS")).await.unwrap();
        let reply = conn.recv().await.unwrap().unwrap();
        assert_eq!(reply.text().as_deref(), Some(r#"LAYOUTS:["mainLuid"]"#));
        server.await.unwrap();
        assert!(conn.recv().await.is_none(), "server closed");
    }

    #[tokio::test]
    async fn split_halves_keep_buffered_input_and_half_close() {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let (stream, _) = listener.accept().await.unwrap();
            let mut conn = Connection::new(stream, DEFAULT_MAX_FRAME_BYTES).unwrap();
            // Two frames in one write: the second stays buffered in the
            // codec when the client splits after reading the first.
            conn.feed(OutFrame::new("one")).await.unwrap();
            conn.feed(OutFrame::new("two")).await.unwrap();
            conn.flush().await.unwrap();
            // Echo until the client half-closes, then reply once more.
            let mut seen = Vec::new();
            while let Some(inbound) = conn.recv().await {
                seen.push(inbound.unwrap().text().unwrap().into_owned());
            }
            conn.send(OutFrame::new("bye")).await.unwrap();
            seen
        });

        let mut conn = Connection::connect(addr, DEFAULT_MAX_FRAME_BYTES)
            .await
            .unwrap();
        let first = conn.recv().await.unwrap().unwrap();
        assert_eq!(first.text().as_deref(), Some("one"));
        let (mut reader, mut writer) = conn.into_split();
        assert_eq!(reader.peer(), addr);
        writer.send(OutFrame::new("hello")).await.unwrap();
        drop(writer);
        let mut rest = Vec::new();
        while let Some(inbound) = reader.recv().await {
            rest.push(inbound.unwrap().text().unwrap().into_owned());
        }
        assert_eq!(rest, ["two", "bye"]);
        assert_eq!(server.await.unwrap(), ["hello"]);
    }
}
