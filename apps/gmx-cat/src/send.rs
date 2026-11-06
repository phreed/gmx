//! `gmx-cat send`: send frames and print the replies.

use std::io::Write;
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::Duration;

use gmx_net::{Inbound, OutFrame};
use tracing::{info, warn};

use crate::input::{frames_from_text, read_input};
use crate::session::{self, Recorder, SessionOptions};
use crate::{DialectArg, Fail};

/// Arguments for `send`.
#[derive(clap::Args, Debug)]
pub struct SendArgs {
    /// Server address, `host:port`.
    pub addr: String,
    /// XML or command files to send, in order. `-` reads standard input.
    pub inputs: Vec<PathBuf>,
    /// A plain-text command to send, such as `LIST_LAYOUTS`. Repeatable.
    /// Commands are sent before the input files.
    #[arg(short, long = "command", value_name = "TEXT")]
    pub commands: Vec<String>,
    /// Re-encode XML input in this dialect. By default it is sent as written.
    #[arg(long, value_enum)]
    pub dialect: Option<DialectArg>,
    /// Stop once the server has been quiet this long after the last send.
    #[arg(long, default_value = "1s", value_parser = crate::parse_duration)]
    pub wait: Duration,
    /// Stop after this long regardless.
    #[arg(long, default_value = "30s", value_parser = crate::parse_duration)]
    pub timeout: Duration,
    /// Record the session to a capture file.
    #[arg(long, value_name = "FILE")]
    pub record: Option<PathBuf>,
    /// Do not print received frames.
    #[arg(short, long)]
    pub quiet: bool,
    /// Largest accepted inbound frame, in bytes.
    #[arg(long, default_value_t = gmx_proto::DEFAULT_MAX_FRAME_BYTES)]
    pub max_frame_bytes: usize,
}

pub async fn run(args: SendArgs) -> Result<ExitCode, Fail> {
    let dialect = args.dialect.map(Into::into);
    let mut frames: Vec<OutFrame> = args.commands.iter().map(|c| OutFrame::new(c)).collect();
    for path in &args.inputs {
        let text = read_input(path).map_err(Fail::Input)?;
        let source = path.display().to_string();
        frames.extend(frames_from_text(&text, &source, dialect).map_err(Fail::Input)?);
    }
    let recorder = match &args.record {
        Some(path) => {
            Some(Recorder::create(path).map_err(|e| Fail::Io(format!("{}: {e}", path.display())))?)
        }
        None => None,
    };

    let count = frames.len();
    let script = frames.into_iter().map(|f| (Duration::ZERO, f)).collect();
    let options = SessionOptions {
        wait: args.wait,
        timeout: args.timeout,
        connect_timeout: Duration::from_secs(5),
        max_frame_bytes: args.max_frame_bytes,
    };
    let quiet = args.quiet;
    let mut stdout = std::io::stdout().lock();
    let result = session::run(
        &args.addr,
        script,
        options,
        recorder.as_ref().map(|r| (r, 0)),
        |inbound| {
            if quiet {
                return;
            }
            match inbound {
                Inbound::Frame(bytes) => {
                    let _ = stdout.write_all(bytes);
                    let _ = stdout.write_all(b"\n");
                }
                Inbound::Dropped(error) => warn!(%error, "dropped a frame from the server"),
            }
            let _ = stdout.flush();
        },
    )
    .await
    .map_err(|e| Fail::Io(format!("{}: {e}", args.addr)))?;

    info!(
        sent = count - result.unsent,
        received = result.received.len(),
        "session ended"
    );
    if result.timed_out {
        warn!("stopped after --timeout while the server was still sending");
    }
    if result.unsent > 0 {
        return Err(Fail::Io(format!(
            "{}: server closed the connection with {} of {count} frames unsent",
            args.addr, result.unsent
        )));
    }
    Ok(ExitCode::SUCCESS)
}
