//! GMX layout server.
//!
//! Stores layout trees keyed by LUID, resolves `xi:include` references and
//! pushes `ISISLayout` messages. Scheduled for phase 3 of
//! `doc/rust-rewrite/plan.adoc`.

use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    eprintln!("{}: not yet implemented (phase 3)", env!("CARGO_PKG_NAME"));
    ExitCode::FAILURE
}
