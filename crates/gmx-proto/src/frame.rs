//! NUL-terminated framing.
//!
//! GMX inherited its framing from the Flash `XMLSocket`: each message is a
//! UTF-8 string followed by one NUL byte. This module splits a byte stream
//! into frames without doing any I/O, so `gmx-net` can wrap it in an async
//! codec and tests can drive it directly.

use std::fmt;

/// The default largest accepted frame, excluding the NUL: 1 MiB.
pub const DEFAULT_MAX_FRAME_BYTES: usize = 1 << 20;

/// The frame terminator.
pub const TERMINATOR: u8 = 0;

/// A frame that could not be delivered. Later frames are unaffected.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum FrameError {
    /// A frame exceeded the size limit and was dropped.
    TooLong {
        /// The configured limit.
        limit: usize,
    },
}

impl fmt::Display for FrameError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::TooLong { limit } => write!(f, "frame exceeds {limit} bytes and was dropped"),
        }
    }
}

impl std::error::Error for FrameError {}

/// Splits a byte stream into NUL-terminated frames.
///
/// Empty frames, such as two NULs in a row, are skipped. A frame longer
/// than the limit is reported once and then skipped up to the next NUL, so
/// one bad peer message cannot exhaust memory or stall the stream.
#[derive(Clone, Debug)]
pub struct FrameDecoder {
    buffer: Vec<u8>,
    /// Bytes at the start of `buffer` already known to hold no NUL.
    scanned: usize,
    max_frame_bytes: usize,
    discarding: bool,
}

impl Default for FrameDecoder {
    fn default() -> Self {
        Self::new(DEFAULT_MAX_FRAME_BYTES)
    }
}

impl FrameDecoder {
    /// Creates a decoder with the given frame size limit.
    pub fn new(max_frame_bytes: usize) -> Self {
        Self {
            buffer: Vec::new(),
            scanned: 0,
            max_frame_bytes,
            discarding: false,
        }
    }

    /// Appends received bytes.
    pub fn push(&mut self, bytes: &[u8]) {
        self.buffer.extend_from_slice(bytes);
    }

    /// Bytes buffered and not yet returned as a frame.
    pub fn buffered(&self) -> usize {
        self.buffer.len()
    }

    /// Returns the next complete frame, without its NUL.
    ///
    /// Returns `None` when more input is needed.
    pub fn next_frame(&mut self) -> Option<Result<Vec<u8>, FrameError>> {
        loop {
            let found = self.buffer[self.scanned..]
                .iter()
                .position(|&b| b == TERMINATOR)
                .map(|i| self.scanned + i);
            let Some(end) = found else {
                self.scanned = self.buffer.len();
                if !self.discarding && self.buffer.len() > self.max_frame_bytes {
                    self.discarding = true;
                    self.buffer.clear();
                    self.scanned = 0;
                    return Some(Err(FrameError::TooLong {
                        limit: self.max_frame_bytes,
                    }));
                }
                if self.discarding {
                    self.buffer.clear();
                    self.scanned = 0;
                }
                return None;
            };
            let mut frame: Vec<u8> = self.buffer.drain(..=end).collect();
            frame.pop();
            self.scanned = 0;
            if std::mem::take(&mut self.discarding) {
                continue;
            }
            if frame.len() > self.max_frame_bytes {
                return Some(Err(FrameError::TooLong {
                    limit: self.max_frame_bytes,
                }));
            }
            if frame.is_empty() {
                continue;
            }
            return Some(Ok(frame));
        }
    }

    /// Ends the stream, returning any unterminated bytes as a last frame.
    ///
    /// The Python servers drop such a tail, but returning it lets tools
    /// such as `printf '<a/>' | ...`, which send no final NUL, work.
    /// Returns `None` when nothing is buffered or an oversized frame was
    /// being skipped. Call [`FrameDecoder::next_frame`] until it returns
    /// `None` first.
    pub fn finish(&mut self) -> Option<Vec<u8>> {
        let discarding = std::mem::take(&mut self.discarding);
        self.scanned = 0;
        let tail = std::mem::take(&mut self.buffer);
        (!discarding && !tail.is_empty()).then_some(tail)
    }
}

/// Appends a frame and its NUL to `out`.
///
/// XML text cannot contain NUL, and [`crate::xml`] never writes one, so a
/// NUL in `message` is a caller bug. It is replaced with U+FFFD rather than
/// splitting the frame.
pub fn encode_frame(message: &str, out: &mut Vec<u8>) {
    if message.as_bytes().contains(&TERMINATOR) {
        debug_assert!(false, "frame payload contains NUL");
        out.extend_from_slice(message.replace('\0', "\u{FFFD}").as_bytes());
    } else {
        out.extend_from_slice(message.as_bytes());
    }
    out.push(TERMINATOR);
}

#[cfg(test)]
mod tests {
    use super::*;

    fn frames(decoder: &mut FrameDecoder) -> Vec<Result<Vec<u8>, FrameError>> {
        std::iter::from_fn(|| decoder.next_frame()).collect()
    }

    #[test]
    fn splits_frames_and_skips_empty_ones() {
        let mut d = FrameDecoder::default();
        d.push(b"<a/>\0\0<b/>\0<c");
        assert_eq!(frames(&mut d), [Ok(b"<a/>".to_vec()), Ok(b"<b/>".to_vec())]);
        assert_eq!(d.buffered(), 2);
        d.push(b"/>\0");
        assert_eq!(frames(&mut d), [Ok(b"<c/>".to_vec())]);
        assert_eq!(d.buffered(), 0);
    }

    #[test]
    fn handles_byte_at_a_time_input() {
        let mut d = FrameDecoder::default();
        let mut out = Vec::new();
        for b in b"one\0two\0" {
            d.push(&[*b]);
            out.extend(frames(&mut d));
        }
        assert_eq!(out, [Ok(b"one".to_vec()), Ok(b"two".to_vec())]);
    }

    #[test]
    fn oversized_frame_is_reported_once_then_skipped() {
        let mut d = FrameDecoder::new(4);
        d.push(b"12345");
        assert_eq!(frames(&mut d), [Err(FrameError::TooLong { limit: 4 })]);
        d.push(b"6789");
        assert_eq!(frames(&mut d), []);
        assert_eq!(d.buffered(), 0, "discarded bytes are not kept");
        d.push(b"0\0ok\0");
        assert_eq!(frames(&mut d), [Ok(b"ok".to_vec())]);
    }

    #[test]
    fn oversized_frame_arriving_whole_is_rejected() {
        let mut d = FrameDecoder::new(4);
        d.push(b"12345\0ok\0");
        assert_eq!(
            frames(&mut d),
            [Err(FrameError::TooLong { limit: 4 }), Ok(b"ok".to_vec())]
        );
    }

    #[test]
    fn frame_at_limit_is_accepted() {
        let mut d = FrameDecoder::new(4);
        d.push(b"1234");
        assert_eq!(frames(&mut d), []);
        d.push(b"\0");
        assert_eq!(frames(&mut d), [Ok(b"1234".to_vec())]);
    }

    #[test]
    fn finish_returns_unterminated_tail() {
        let mut d = FrameDecoder::default();
        d.push(b"<a/>\0<b/>");
        assert_eq!(frames(&mut d), [Ok(b"<a/>".to_vec())]);
        assert_eq!(d.finish(), Some(b"<b/>".to_vec()));
        assert_eq!(d.finish(), None);
        assert_eq!(d.buffered(), 0);
    }

    #[test]
    fn finish_drops_tail_of_oversized_frame() {
        let mut d = FrameDecoder::new(4);
        d.push(b"123456");
        assert_eq!(frames(&mut d), [Err(FrameError::TooLong { limit: 4 })]);
        d.push(b"78");
        assert_eq!(d.finish(), None);
        d.push(b"ok\0");
        assert_eq!(frames(&mut d), [Ok(b"ok".to_vec())], "state is reset");
    }

    #[test]
    fn encode_appends_terminator() {
        let mut out = Vec::new();
        encode_frame("<a/>", &mut out);
        encode_frame("<b/>", &mut out);
        assert_eq!(out, b"<a/>\0<b/>\0");
    }
}
