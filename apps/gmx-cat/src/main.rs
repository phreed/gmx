//! `gmx-cat`: a netcat-like tool for GMX.
//!
//! Sends, captures and replays NUL-framed GMX message streams. Scheduled for
//! phase 2 of `doc/rust-rewrite/plan.adoc`.

use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    eprintln!("{}: not yet implemented (phase 2)", env!("CARGO_PKG_NAME"));
    ExitCode::FAILURE
}
