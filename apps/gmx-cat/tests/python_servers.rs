//! Phase 2 exit criterion: `gmx-cat` captures sessions with the Python
//! reference servers and replays them successfully.
//!
//! Each test starts real servers from `examples/servers/`. A capture is
//! taken against one server instance and replayed against a fresh one,
//! because the servers keep state between connections.
//!
//! The tests are skipped, with a note, when no Python 3 is found. Set
//! `GMX_PYTHON` to choose the interpreter.

use std::net::{TcpListener, TcpStream};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Output, Stdio};
use std::time::{Duration, Instant};

const GMX_CAT: &str = env!("CARGO_BIN_EXE_gmx-cat");

fn servers_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../examples/servers")
}

fn examples_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../examples")
}

fn python() -> Option<String> {
    let candidates = match std::env::var("GMX_PYTHON") {
        Ok(chosen) => vec![chosen],
        Err(_) => vec!["python3".into(), "python".into()],
    };
    candidates.into_iter().find(|exe| {
        Command::new(exe)
            .args(["-c", "import sys; sys.exit(sys.version_info[0] != 3)"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|s| s.success())
    })
}

/// A Python server that is killed when dropped.
struct PythonServer {
    child: Child,
    addr: String,
}

impl PythonServer {
    fn start(python: &str, script: &str) -> Self {
        // Reserve a free port, then hand it to the server.
        let port = TcpListener::bind("127.0.0.1:0")
            .unwrap()
            .local_addr()
            .unwrap()
            .port();
        let child = Command::new(python)
            .arg(script)
            .args(["--host", "127.0.0.1", "--port", &port.to_string()])
            .current_dir(servers_dir())
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .unwrap_or_else(|e| panic!("cannot start {script}: {e}"));
        let server = Self {
            child,
            addr: format!("127.0.0.1:{port}"),
        };
        server.wait_until_listening();
        server
    }

    fn wait_until_listening(&self) {
        let deadline = Instant::now() + Duration::from_secs(20);
        while Instant::now() < deadline {
            if TcpStream::connect(&self.addr).is_ok() {
                // That probe connection is served and dropped. Give the
                // server a moment so the probe does not race the test.
                std::thread::sleep(Duration::from_millis(200));
                return;
            }
            std::thread::sleep(Duration::from_millis(100));
        }
        panic!("server at {} did not start listening", self.addr);
    }
}

impl Drop for PythonServer {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}

fn gmx_cat(args: &[&str]) -> Output {
    Command::new(GMX_CAT)
        .args(args)
        .output()
        .expect("gmx-cat runs")
}

fn text(bytes: &[u8]) -> String {
    String::from_utf8_lossy(bytes).into_owned()
}

fn capture_path(name: &str) -> String {
    let dir = Path::new(env!("CARGO_TARGET_TMPDIR"));
    dir.join(format!("{name}-{}.jsonl", std::process::id()))
        .to_string_lossy()
        .into_owned()
}

macro_rules! require_python {
    () => {
        match python() {
            Some(python) => python,
            None => {
                eprintln!("skipping: no Python 3 found; set GMX_PYTHON to run this test");
                return;
            }
        }
    };
}

#[test]
fn layout_server_session_replays() {
    let python = require_python!();
    let capture = capture_path("layout");

    let recorded = {
        let server = PythonServer::start(&python, "layout_server.py");
        gmx_cat(&[
            "send",
            &server.addr,
            "-c",
            "LIST_LAYOUTS",
            "-c",
            "GET_LAYOUT:simple",
            "--wait",
            "500ms",
            "--record",
            &capture,
        ])
    };
    let stdout = text(&recorded.stdout);
    assert!(recorded.status.success(), "{}", text(&recorded.stderr));
    assert!(
        stdout.contains(r#"LAYOUTS:["simple", "form", "dashboard", "mainLuid"]"#),
        "{stdout}"
    );
    assert!(stdout.contains(r#"<ISISLayout luid="simple">"#), "{stdout}");

    let fresh = PythonServer::start(&python, "layout_server.py");
    let replayed = gmx_cat(&["replay", &capture, "--to", &fresh.addr, "--wait", "500ms"]);
    let report = text(&replayed.stdout);
    assert!(
        replayed.status.success(),
        "{report}{}",
        text(&replayed.stderr)
    );
    assert!(
        report.contains("3 matched, 0 missing, 0 unexpected"),
        "{report}"
    );
}

#[test]
fn data_server_session_replays_with_volatile_fields_masked() {
    let python = require_python!();
    let capture = capture_path("data");
    let records = examples_dir().join("records");
    let user_form = records.join("user_form_record.xml");
    let basic = records.join("basic_record_message.xml");

    let recorded = {
        let server = PythonServer::start(&python, "data_server.py");
        gmx_cat(&[
            "send",
            &server.addr,
            "-c",
            "GET_COLLECTION:system_metrics",
            "-c",
            "LIST_RECORDS",
            // The Python server reads only bare messages, so convert the
            // invoke-dialect example.
            "--dialect",
            "bare",
            user_form.to_str().unwrap(),
            basic.to_str().unwrap(),
            "--wait",
            "500ms",
            "--quiet",
            "--record",
            &capture,
        ])
    };
    assert!(recorded.status.success(), "{}", text(&recorded.stderr));
    let log = std::fs::read_to_string(&capture).unwrap();
    assert!(
        log.contains(r#"<ISISRecord ruid=\"r1\">"#),
        "converted record was sent"
    );
    assert!(log.contains("RECORDS:["), "listing reply was recorded");

    // The simulation thread rewrites these fields as it pleases.
    let masks = [
        "--ignore-field",
        "system_status.current_time",
        "--ignore-field",
        "navigation_data.*",
        "--ignore-field",
        "*.last_updated",
    ];
    let fresh = PythonServer::start(&python, "data_server.py");
    let mut args = vec![
        "replay",
        &capture,
        "--to",
        &fresh.addr,
        "--fast",
        "--wait",
        "500ms",
    ];
    args.extend(masks);
    let replayed = gmx_cat(&args);
    let report = text(&replayed.stdout);
    assert!(
        replayed.status.success(),
        "{report}{}",
        text(&replayed.stderr)
    );
    assert!(report.contains(" 0 missing, 0 unexpected"), "{report}");
}

#[test]
fn replay_against_the_wrong_server_fails() {
    let python = require_python!();
    let capture = capture_path("wrong");
    {
        let layout = PythonServer::start(&python, "layout_server.py");
        let recorded = gmx_cat(&[
            "send",
            &layout.addr,
            "-c",
            "LIST_LAYOUTS",
            "--wait",
            "300ms",
            "--quiet",
            "--record",
            &capture,
        ]);
        assert!(recorded.status.success(), "{}", text(&recorded.stderr));
    }
    let data = PythonServer::start(&python, "data_server.py");
    let replayed = gmx_cat(&[
        "replay", &capture, "--to", &data.addr, "--fast", "--wait", "300ms",
    ]);
    let report = text(&replayed.stdout);
    assert_eq!(replayed.status.code(), Some(1), "{report}");
    assert!(report.contains("FAILED"), "{report}");
    assert!(report.contains("missing    #0: <ISISLayout"), "{report}");
}

#[test]
fn usage_errors_exit_with_code_2() {
    let missing = gmx_cat(&["replay", "no-such-capture.jsonl", "--to", "127.0.0.1:9"]);
    assert_eq!(missing.status.code(), Some(2));
    assert!(text(&missing.stderr).contains("no-such-capture.jsonl"));

    let refused = gmx_cat(&["send", "127.0.0.1:9", "-c", "LIST_LAYOUTS"]);
    assert_eq!(refused.status.code(), Some(2), "{}", text(&refused.stderr));
}
