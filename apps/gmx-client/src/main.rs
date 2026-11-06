//! GMX UI client.
//!
//! Renders layouts, binds widgets to records and collections, and sends user
//! edits back to the servers. Scheduled for phase 4 of
//! `doc/rust-rewrite/plan.adoc`.

use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    eprintln!("{}: not yet implemented (phase 4)", env!("CARGO_PKG_NAME"));
    ExitCode::FAILURE
}
