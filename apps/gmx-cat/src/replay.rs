//! `gmx-cat replay`: resend a capture's client frames and compare the
//! server's replies with the captured ones.

use std::collections::BTreeMap;
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::Duration;

use futures_util::future::join_all;
use gmx_net::capture::{Direction, Entry, read_capture};
use gmx_net::{Inbound, OutFrame};
use gmx_proto::FrameError;
use tracing::warn;

use crate::Fail;
use crate::compare::{Comparable, FieldMask, compare};
use crate::session::{self, SessionOptions};

/// Arguments for `replay`.
#[derive(clap::Args, Debug)]
pub struct ReplayArgs {
    /// The capture file to replay.
    pub capture: PathBuf,
    /// Server address, `host:port`.
    #[arg(long, value_name = "ADDR")]
    pub to: String,
    /// Replay speed. `2` is twice as fast as recorded.
    #[arg(long, default_value_t = 1.0, conflicts_with = "fast")]
    pub speed: f64,
    /// Send without the recorded delays.
    #[arg(long)]
    pub fast: bool,
    /// Ignore values of matching record fields, given as `RUID.FID` with
    /// `*` wildcards. Repeatable.
    #[arg(long = "ignore-field", value_name = "RUID.FID")]
    pub ignore_fields: Vec<FieldMask>,
    /// Succeed even when the server sends frames the capture lacks.
    #[arg(long)]
    pub allow_extra: bool,
    /// Stop a connection once the server has been quiet this long after its
    /// last send.
    #[arg(long, default_value = "1s", value_parser = crate::parse_duration)]
    pub wait: Duration,
    /// Stop a connection after this long regardless.
    #[arg(long, default_value = "60s", value_parser = crate::parse_duration)]
    pub timeout: Duration,
    /// Largest accepted inbound frame, in bytes.
    #[arg(long, default_value_t = gmx_proto::DEFAULT_MAX_FRAME_BYTES)]
    pub max_frame_bytes: usize,
}

/// What one captured connection did.
#[derive(Debug, Default)]
struct Recorded {
    opened: Option<f64>,
    peer: String,
    sent: Vec<(f64, String)>,
    received: Vec<Inbound>,
}

fn group(entries: Vec<Entry>) -> BTreeMap<u32, Recorded> {
    let mut conns: BTreeMap<u32, Recorded> = BTreeMap::new();
    for entry in entries {
        let Some(id) = entry.conn() else { continue };
        let conn = conns.entry(id).or_default();
        if conn.opened.is_none() {
            conn.opened = entry.time();
        }
        match entry {
            Entry::Open { peer, .. } => conn.peer = peer,
            Entry::Frame {
                t,
                dir: Direction::ToServer,
                frame,
                lossy,
                ..
            } => {
                if lossy {
                    warn!(
                        conn = id,
                        "replaying a frame that was not valid UTF-8 when captured"
                    );
                }
                conn.sent.push((t, frame));
            }
            Entry::Frame {
                dir: Direction::ToClient,
                frame,
                ..
            } => conn.received.push(Inbound::Frame(frame.into_bytes())),
            Entry::Dropped {
                dir: Direction::ToClient,
                limit,
                ..
            } => conn
                .received
                .push(Inbound::Dropped(FrameError::TooLong { limit })),
            Entry::Dropped { .. } | Entry::Close { .. } | Entry::Header { .. } => {}
        }
    }
    conns
}

fn seconds(value: f64, speed: f64) -> Duration {
    Duration::from_secs_f64((value / speed).max(0.0))
}

fn describe(inbound: &Inbound) -> String {
    const LIMIT: usize = 160;
    match inbound {
        Inbound::Dropped(error) => format!("[{error}]"),
        Inbound::Frame(bytes) => {
            let text = String::from_utf8_lossy(bytes);
            match text.char_indices().nth(LIMIT) {
                Some((i, _)) => format!("{}...", &text[..i]),
                None => text.into_owned(),
            }
        }
    }
}

pub async fn run(args: ReplayArgs) -> Result<ExitCode, Fail> {
    if !(args.speed.is_finite() && args.speed > 0.0) {
        return Err(Fail::Input(format!(
            "--speed must be positive, not {}",
            args.speed
        )));
    }
    let file = File::open(&args.capture)
        .map_err(|e| Fail::Input(format!("{}: {e}", args.capture.display())))?;
    let entries = read_capture(BufReader::new(file))
        .map_err(|e| Fail::Input(format!("{}: {e}", args.capture.display())))?;
    let conns = group(entries);
    if conns.is_empty() {
        return Err(Fail::Input(format!(
            "{}: the capture holds no connections",
            args.capture.display()
        )));
    }

    let speed = if args.fast { f64::INFINITY } else { args.speed };
    let options = SessionOptions {
        wait: args.wait,
        timeout: args.timeout,
        connect_timeout: Duration::from_secs(5),
        max_frame_bytes: args.max_frame_bytes,
    };
    let first_open = conns
        .values()
        .filter_map(|c| c.opened)
        .fold(f64::INFINITY, f64::min);
    let sessions = conns.iter().map(|(id, conn)| {
        let opened = conn.opened.unwrap_or(first_open);
        let start_delay = seconds(opened - first_open, speed);
        let script = conn
            .sent
            .iter()
            .map(|(t, frame)| (seconds(t - opened, speed), OutFrame::new(frame)))
            .collect();
        let addr = args.to.clone();
        async move {
            tokio::time::sleep(start_delay).await;
            (
                *id,
                session::run(&addr, script, options, None, |_| {}).await,
            )
        }
    });
    let results = join_all(sessions).await;

    let mut failed = false;
    for (id, result) in results {
        let recorded = &conns[&id];
        let result = result.map_err(|e| Fail::Io(format!("{} (connection {id}): {e}", args.to)))?;
        let expected: Vec<_> = recorded
            .received
            .iter()
            .map(|i| Comparable::new(i, &args.ignore_fields))
            .collect();
        let actual: Vec<_> = result
            .received
            .iter()
            .map(|i| Comparable::new(i, &args.ignore_fields))
            .collect();
        let comparison = compare(&expected, &actual);
        let ok = comparison.missing.is_empty()
            && (args.allow_extra || comparison.unexpected.is_empty())
            && result.unsent == 0;
        failed |= !ok;

        let peer = if recorded.peer.is_empty() {
            String::new()
        } else {
            format!(" (captured from {})", recorded.peer)
        };
        println!(
            "connection {id}{peer}: {} sent, {} expected, {} received, {} matched, \
             {} missing, {} unexpected{}",
            recorded.sent.len() - result.unsent,
            expected.len(),
            actual.len(),
            comparison.matched,
            comparison.missing.len(),
            comparison.unexpected.len(),
            if ok { "" } else { "  FAILED" },
        );
        for &i in &comparison.missing {
            println!("  missing    #{i}: {}", describe(&recorded.received[i]));
        }
        for &j in &comparison.unexpected {
            println!("  unexpected #{j}: {}", describe(&result.received[j]));
        }
        if result.unsent > 0 {
            println!(
                "  the server closed the connection with {} frames unsent",
                result.unsent
            );
        }
        if result.timed_out {
            println!("  stopped after --timeout while the server was still sending");
        }
    }
    Ok(if failed {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    })
}
