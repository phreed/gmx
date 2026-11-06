//! GMX widget-source server.
//!
//! Publishes a widget catalog and delivers versioned widget packages to
//! clients. Scheduled for phase 6 of `doc/rust-rewrite/plan.adoc`.

use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    eprintln!("{}: not yet implemented (phase 6)", env!("CARGO_PKG_NAME"));
    ExitCode::FAILURE
}
