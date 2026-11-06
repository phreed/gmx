//! `gmx-cat`: a netcat-like tool for GMX.
//!
//! * `send` sends messages or commands and prints the replies.
//! * `proxy` relays a client to a server and records both directions.
//! * `replay` resends a capture's client side and checks the replies.
//!
//! Captures are JSON Lines; see `gmx_net::capture`.

mod compare;
mod input;
mod proxy;
mod replay;
mod send;
mod session;

use std::process::ExitCode;
use std::time::Duration;

use clap::{Parser, Subcommand, ValueEnum};
use gmx_proto::Dialect;

/// Send, capture and replay GMX message streams.
#[derive(Parser, Debug)]
#[command(version, about, max_term_width = 100)]
struct Cli {
    /// More logging on standard error. Repeat for more. `RUST_LOG` also works.
    #[arg(short, long, action = clap::ArgAction::Count, global = true)]
    verbose: u8,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand, Debug)]
enum Command {
    /// Send messages or commands to a server and print its replies.
    Send(send::SendArgs),
    /// Relay clients to a server, recording every frame.
    Proxy(proxy::ProxyArgs),
    /// Replay a capture against a server and compare the replies.
    Replay(replay::ReplayArgs),
}

/// A message dialect.
#[derive(Clone, Copy, Debug, ValueEnum)]
pub enum DialectArg {
    /// The legacy `<invoke fn="...">` envelope.
    Invoke,
    /// Bare `ISIS*` elements, as the Python reference servers use.
    Bare,
}

impl From<DialectArg> for Dialect {
    fn from(arg: DialectArg) -> Self {
        match arg {
            DialectArg::Invoke => Dialect::Invoke,
            DialectArg::Bare => Dialect::Bare,
        }
    }
}

/// A failure that stops the command.
#[derive(Debug)]
pub enum Fail {
    /// Bad arguments or input files.
    Input(String),
    /// A network or file error.
    Io(String),
}

/// Parses `250ms`, `2s`, `1.5s` or `1m`. A bare number is seconds.
pub fn parse_duration(text: &str) -> Result<Duration, String> {
    let text = text.trim();
    let (number, scale) = if let Some(n) = text.strip_suffix("ms") {
        (n, 0.001)
    } else if let Some(n) = text.strip_suffix('s') {
        (n, 1.0)
    } else if let Some(n) = text.strip_suffix('m') {
        (n, 60.0)
    } else {
        (text, 1.0)
    };
    let value: f64 = number
        .trim()
        .parse()
        .map_err(|_| format!("'{text}' is not a duration such as 500ms, 2s or 1m"))?;
    if !value.is_finite() || value < 0.0 {
        return Err(format!("'{text}' must be zero or more"));
    }
    Ok(Duration::from_secs_f64(value * scale))
}

fn init_logging(verbose: u8) {
    use tracing_subscriber::EnvFilter;
    let default = match verbose {
        0 => "warn",
        1 => "info",
        _ => "debug",
    };
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(default));
    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_writer(std::io::stderr)
        .with_target(false)
        .init();
}

fn main() -> ExitCode {
    let cli = Cli::parse();
    init_logging(cli.verbose);
    let runtime = match tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
    {
        Ok(runtime) => runtime,
        Err(error) => {
            eprintln!("gmx-cat: cannot start: {error}");
            return ExitCode::from(2);
        }
    };
    let result = runtime.block_on(async move {
        match cli.command {
            Command::Send(args) => send::run(args).await,
            Command::Proxy(args) => proxy::run(args).await,
            Command::Replay(args) => replay::run(args).await,
        }
    });
    match result {
        Ok(code) => code,
        Err(Fail::Input(message) | Fail::Io(message)) => {
            eprintln!("gmx-cat: {message}");
            ExitCode::from(2)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn cli_is_well_formed() {
        Cli::command().debug_assert();
    }

    #[test]
    fn durations() {
        assert_eq!(parse_duration("250ms"), Ok(Duration::from_millis(250)));
        assert_eq!(parse_duration("2s"), Ok(Duration::from_secs(2)));
        assert_eq!(parse_duration("1.5"), Ok(Duration::from_millis(1500)));
        assert_eq!(parse_duration("1m"), Ok(Duration::from_secs(60)));
        assert_eq!(parse_duration("0"), Ok(Duration::ZERO));
        assert!(parse_duration("-1s").is_err());
        assert!(parse_duration("soon").is_err());
        assert!(parse_duration("infs").is_err());
    }
}
