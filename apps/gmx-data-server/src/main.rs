//! GMX data-messages server.
//!
//! Owns the real-time data store of records and collections, applies
//! `ISISDataEdit` from clients and broadcasts the results. Scheduled for
//! phase 3 of `doc/rust-rewrite/plan.adoc`.

use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    eprintln!("{}: not yet implemented (phase 3)", env!("CARGO_PKG_NAME"));
    ExitCode::FAILURE
}
