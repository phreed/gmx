//! One scripted client session, shared by `send` and `replay`.

use std::fs::File;
use std::io::{self, BufWriter};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use gmx_net::capture::{CaptureWriter, Direction};
use gmx_net::{Connection, Inbound, OutFrame};
use tokio::time::{Instant, sleep_until, timeout};

/// A capture file shared by concurrent sessions.
#[derive(Clone, Debug)]
pub struct Recorder(Arc<Mutex<CaptureWriter<BufWriter<File>>>>);

impl Recorder {
    /// Creates the capture file, replacing any existing one.
    pub fn create(path: &std::path::Path) -> io::Result<Self> {
        let file = File::create(path)?;
        Ok(Self(Arc::new(Mutex::new(CaptureWriter::new(
            BufWriter::new(file),
        )?))))
    }

    fn with<T>(&self, f: impl FnOnce(&mut CaptureWriter<BufWriter<File>>) -> T) -> T {
        f(&mut self.0.lock().unwrap_or_else(|e| e.into_inner()))
    }

    pub fn open(&self, conn: u32, peer: impl std::fmt::Display) -> io::Result<()> {
        self.with(|w| w.open(conn, peer))
    }

    pub fn inbound(&self, conn: u32, dir: Direction, inbound: &Inbound) -> io::Result<()> {
        self.with(|w| match inbound {
            Inbound::Frame(bytes) => w.frame(conn, dir, bytes),
            Inbound::Dropped(gmx_proto::FrameError::TooLong { limit }) => {
                w.dropped(conn, dir, *limit)
            }
        })
    }

    pub fn close(&self, conn: u32) -> io::Result<()> {
        self.with(|w| w.close(conn))
    }
}

/// Timing and limits for a session.
#[derive(Clone, Copy, Debug)]
pub struct SessionOptions {
    /// End once nothing has arrived for this long after the last send.
    pub wait: Duration,
    /// End after this long regardless.
    pub timeout: Duration,
    /// Time allowed to connect.
    pub connect_timeout: Duration,
    /// Largest accepted inbound frame.
    pub max_frame_bytes: usize,
}

/// How a session ended.
#[derive(Debug, Default)]
pub struct SessionResult {
    /// Everything the server sent, in order.
    pub received: Vec<Inbound>,
    /// The overall timeout was reached.
    pub timed_out: bool,
    /// The server closed the connection before the session ended.
    pub closed_by_peer: bool,
    /// Frames from the script that were not sent because the server closed.
    pub unsent: usize,
}

/// Connects, sends each frame at its offset from the connection time, and
/// collects replies until the server goes quiet.
///
/// The sending side stays open until the session ends: the Python servers
/// close the connection as soon as they see end of input.
pub async fn run(
    addr: &str,
    script: Vec<(Duration, OutFrame)>,
    options: SessionOptions,
    recorder: Option<(&Recorder, u32)>,
    mut on_frame: impl FnMut(&Inbound),
) -> io::Result<SessionResult> {
    let conn = timeout(
        options.connect_timeout,
        Connection::connect(addr, options.max_frame_bytes),
    )
    .await
    .map_err(|_| {
        io::Error::new(
            io::ErrorKind::TimedOut,
            format!("connecting to {addr} timed out"),
        )
    })??;
    if let Some((rec, id)) = recorder {
        rec.open(id, conn.peer())?;
    }
    let (mut reader, mut writer) = conn.into_split();

    let start = Instant::now();
    let total = script.len();
    let sent = std::cell::Cell::new(0usize);
    let sender = async {
        for (offset, frame) in script {
            sleep_until(start + offset).await;
            writer.send(frame.clone()).await?;
            if let Some((rec, id)) = recorder {
                rec.inbound(
                    id,
                    Direction::ToServer,
                    &Inbound::Frame(frame.payload().to_vec()),
                )?;
            }
            sent.set(sent.get() + 1);
        }
        Ok::<_, io::Error>(())
    };
    tokio::pin!(sender);

    let mut result = SessionResult::default();
    let mut sending = true;
    let deadline = start + options.timeout;
    let mut idle = Instant::now() + options.wait;
    loop {
        tokio::select! {
            done = &mut sender, if sending => {
                done?;
                sending = false;
                idle = Instant::now() + options.wait;
            }
            inbound = reader.recv() => match inbound {
                None => {
                    result.closed_by_peer = true;
                    break;
                }
                Some(Err(error)) => return Err(error),
                Some(Ok(inbound)) => {
                    if let Some((rec, id)) = recorder {
                        rec.inbound(id, Direction::ToClient, &inbound)?;
                    }
                    on_frame(&inbound);
                    result.received.push(inbound);
                    idle = Instant::now() + options.wait;
                }
            },
            () = sleep_until(idle), if !sending => break,
            () = sleep_until(deadline) => {
                result.timed_out = true;
                break;
            }
        }
    }
    result.unsent = total - sent.get();
    if let Some((rec, id)) = recorder {
        rec.close(id)?;
    }
    Ok(result)
}
