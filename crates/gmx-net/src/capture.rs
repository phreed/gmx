//! Capture files: a timestamped record of the frames on one or more
//! connections.
//!
//! The format is JSON Lines, one entry per line, so captures can be read,
//! diffed and edited by hand. The first line is a header:
//!
//! ```text
//! {"event":"header","format":"gmx-capture","version":1}
//! {"event":"open","t":0.0,"conn":0,"peer":"127.0.0.1:12345"}
//! {"event":"frame","t":0.001,"conn":0,"dir":"to_server","frame":"LIST_LAYOUTS"}
//! {"event":"frame","t":0.004,"conn":0,"dir":"to_client","frame":"LAYOUTS:[\"mainLuid\"]"}
//! {"event":"close","t":1.2,"conn":0}
//! ```
//!
//! `t` is seconds since the capture started. GMX frames are UTF-8; a frame
//! that is not is stored with invalid bytes replaced and `"lossy":true`.

use std::fmt;
use std::io::{self, BufRead, Write};
use std::time::Instant;

use serde::{Deserialize, Serialize};

/// The `format` value in the header.
pub const FORMAT: &str = "gmx-capture";

/// The capture format version this code writes and reads.
pub const VERSION: u32 = 1;

/// Which way a frame travelled.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Direction {
    /// From the client to the server.
    ToServer,
    /// From the server to the client.
    ToClient,
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Self::ToServer => "to_server",
            Self::ToClient => "to_client",
        })
    }
}

fn is_false(b: &bool) -> bool {
    !*b
}

/// One line of a capture.
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(tag = "event", rename_all = "snake_case")]
pub enum Entry {
    /// The first line.
    Header {
        /// Always [`FORMAT`].
        format: String,
        /// The format version.
        version: u32,
    },
    /// A connection opened.
    Open {
        /// Seconds since the capture started.
        t: f64,
        /// Connection number within the capture.
        conn: u32,
        /// The remote address, as seen by the recorder.
        peer: String,
    },
    /// A frame, without its NUL.
    Frame {
        /// Seconds since the capture started.
        t: f64,
        /// Connection number.
        conn: u32,
        /// Which way it travelled.
        dir: Direction,
        /// The frame text.
        frame: String,
        /// True when invalid UTF-8 was replaced.
        #[serde(default, skip_serializing_if = "is_false")]
        lossy: bool,
    },
    /// An oversized frame was dropped.
    Dropped {
        /// Seconds since the capture started.
        t: f64,
        /// Connection number.
        conn: u32,
        /// Which way it travelled.
        dir: Direction,
        /// The size limit it exceeded.
        limit: usize,
    },
    /// A connection closed.
    Close {
        /// Seconds since the capture started.
        t: f64,
        /// Connection number.
        conn: u32,
    },
}

impl Entry {
    /// The entry's connection, if it has one.
    pub fn conn(&self) -> Option<u32> {
        match self {
            Self::Header { .. } => None,
            Self::Open { conn, .. }
            | Self::Frame { conn, .. }
            | Self::Dropped { conn, .. }
            | Self::Close { conn, .. } => Some(*conn),
        }
    }

    /// The entry's time, if it has one.
    pub fn time(&self) -> Option<f64> {
        match self {
            Self::Header { .. } => None,
            Self::Open { t, .. }
            | Self::Frame { t, .. }
            | Self::Dropped { t, .. }
            | Self::Close { t, .. } => Some(*t),
        }
    }
}

/// Writes a capture, one flushed line per entry, so a capture survives the
/// recorder being killed.
#[derive(Debug)]
pub struct CaptureWriter<W: Write> {
    out: W,
    start: Instant,
}

impl<W: Write> CaptureWriter<W> {
    /// Writes the header and starts the clock.
    pub fn new(out: W) -> io::Result<Self> {
        let mut writer = Self {
            out,
            start: Instant::now(),
        };
        writer.write(&Entry::Header {
            format: FORMAT.into(),
            version: VERSION,
        })?;
        Ok(writer)
    }

    /// Seconds since the capture started, to the microsecond.
    pub fn now(&self) -> f64 {
        (self.start.elapsed().as_secs_f64() * 1e6).round() / 1e6
    }

    /// Records a connection opening.
    pub fn open(&mut self, conn: u32, peer: impl fmt::Display) -> io::Result<()> {
        let entry = Entry::Open {
            t: self.now(),
            conn,
            peer: peer.to_string(),
        };
        self.write(&entry)
    }

    /// Records a frame.
    pub fn frame(&mut self, conn: u32, dir: Direction, bytes: &[u8]) -> io::Result<()> {
        let (frame, lossy) = match std::str::from_utf8(bytes) {
            Ok(text) => (text.to_owned(), false),
            Err(_) => (String::from_utf8_lossy(bytes).into_owned(), true),
        };
        let entry = Entry::Frame {
            t: self.now(),
            conn,
            dir,
            frame,
            lossy,
        };
        self.write(&entry)
    }

    /// Records a dropped frame.
    pub fn dropped(&mut self, conn: u32, dir: Direction, limit: usize) -> io::Result<()> {
        let entry = Entry::Dropped {
            t: self.now(),
            conn,
            dir,
            limit,
        };
        self.write(&entry)
    }

    /// Records a connection closing.
    pub fn close(&mut self, conn: u32) -> io::Result<()> {
        let entry = Entry::Close {
            t: self.now(),
            conn,
        };
        self.write(&entry)
    }

    /// Writes and flushes one entry.
    pub fn write(&mut self, entry: &Entry) -> io::Result<()> {
        serde_json::to_writer(&mut self.out, entry)?;
        self.out.write_all(b"\n")?;
        self.out.flush()
    }

    /// Returns the underlying writer.
    pub fn into_inner(self) -> W {
        self.out
    }
}

/// A capture that could not be read.
#[derive(Debug)]
pub enum CaptureError {
    /// Reading failed.
    Io(io::Error),
    /// A line is not a valid entry.
    Line {
        /// One-based line number.
        line: usize,
        /// What is wrong with it.
        message: String,
    },
}

impl fmt::Display for CaptureError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io(e) => write!(f, "cannot read capture: {e}"),
            Self::Line { line, message } => write!(f, "capture line {line}: {message}"),
        }
    }
}

impl std::error::Error for CaptureError {}

impl From<io::Error> for CaptureError {
    fn from(e: io::Error) -> Self {
        Self::Io(e)
    }
}

/// Reads a capture, checking its header. Blank lines are skipped.
pub fn read_capture(input: impl BufRead) -> Result<Vec<Entry>, CaptureError> {
    let mut entries = Vec::new();
    for (index, line) in input.lines().enumerate() {
        let line = line?;
        if line.trim().is_empty() {
            continue;
        }
        let number = index + 1;
        let entry: Entry = serde_json::from_str(&line).map_err(|e| CaptureError::Line {
            line: number,
            message: e.to_string(),
        })?;
        match (&entry, entries.is_empty()) {
            (Entry::Header { format, version }, true) => {
                if format != FORMAT || *version != VERSION {
                    return Err(CaptureError::Line {
                        line: number,
                        message: format!(
                            "unsupported capture {format} version {version}; \
                             expected {FORMAT} version {VERSION}"
                        ),
                    });
                }
            }
            (_, true) => {
                return Err(CaptureError::Line {
                    line: number,
                    message: "the first entry must be a header".into(),
                });
            }
            (Entry::Header { .. }, false) => {
                return Err(CaptureError::Line {
                    line: number,
                    message: "header repeated".into(),
                });
            }
            _ => {}
        }
        entries.push(entry);
    }
    if entries.is_empty() {
        return Err(CaptureError::Line {
            line: 1,
            message: "capture is empty".into(),
        });
    }
    Ok(entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn writes_and_reads_back() {
        let mut writer = CaptureWriter::new(Vec::new()).unwrap();
        writer.open(0, "127.0.0.1:1").unwrap();
        writer
            .frame(0, Direction::ToServer, b"LIST_LAYOUTS")
            .unwrap();
        writer
            .frame(0, Direction::ToClient, "<a b=\"é\"/>\n".as_bytes())
            .unwrap();
        writer.frame(0, Direction::ToClient, &[b'x', 0xff]).unwrap();
        writer.dropped(0, Direction::ToClient, 4).unwrap();
        writer.close(0).unwrap();
        let bytes = writer.into_inner();
        let text = String::from_utf8(bytes.clone()).unwrap();
        assert_eq!(text.lines().count(), 7, "one line per entry:\n{text}");
        assert!(text.starts_with(r#"{"event":"header","format":"gmx-capture","version":1}"#));

        let entries = read_capture(&bytes[..]).unwrap();
        assert_eq!(entries.len(), 7);
        let frames: Vec<_> = entries
            .iter()
            .filter_map(|e| match e {
                Entry::Frame {
                    dir, frame, lossy, ..
                } => Some((*dir, frame.as_str(), *lossy)),
                _ => None,
            })
            .collect();
        assert_eq!(
            frames,
            [
                (Direction::ToServer, "LIST_LAYOUTS", false),
                (Direction::ToClient, "<a b=\"é\"/>\n", false),
                (Direction::ToClient, "x\u{FFFD}", true),
            ]
        );
        let times: Vec<f64> = entries.iter().filter_map(Entry::time).collect();
        assert!(times.windows(2).all(|w| w[0] <= w[1]), "{times:?}");
        assert!(entries.iter().skip(1).all(|e| e.conn() == Some(0)));
    }

    #[test]
    fn rejects_bad_captures() {
        let err = |text: &str| read_capture(text.as_bytes()).unwrap_err().to_string();
        assert!(err("").contains("empty"));
        assert!(err(r#"{"event":"close","t":0,"conn":0}"#).contains("must be a header"));
        assert!(
            err(r#"{"event":"header","format":"gmx-capture","version":9}"#).contains("unsupported")
        );
        let header = r#"{"event":"header","format":"gmx-capture","version":1}"#;
        assert!(err(&format!("{header}\n{header}")).contains("line 2: header repeated"));
        assert!(err(&format!("{header}\n\nnot json")).contains("line 3"));
        assert!(read_capture(format!("{header}\n\n").as_bytes()).is_ok());
    }
}
