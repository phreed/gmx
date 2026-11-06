//! Golden tests over the XML files in `examples/`.
//!
//! These are the phase 1 exit criteria in `doc/rust-rewrite/plan.adoc`:
//! every example message decodes and round-trips, and applying the example
//! data builds the structures the UX designer guide describes.
//!
//! The CSV files beside the layouts are Layout Manager inputs. They are
//! covered with the layout server in phase 3.

use std::fs;
use std::path::{Path, PathBuf};

use gmx_model::Store;
use gmx_proto::xml::{self, Element};
use gmx_proto::{Dialect, Layout, Message, apply};

fn examples_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../examples")
}

/// Every `.xml` file under `examples/`, sorted, relative to it.
fn example_files() -> Vec<PathBuf> {
    fn walk(dir: &Path, out: &mut Vec<PathBuf>) {
        for entry in fs::read_dir(dir).unwrap() {
            let path = entry.unwrap().path();
            if path.is_dir() {
                walk(&path, out);
            } else if path.extension().is_some_and(|e| e == "xml") {
                out.push(path);
            }
        }
    }
    let root = examples_dir();
    let mut files = Vec::new();
    walk(&root, &mut files);
    files.sort();
    files
        .into_iter()
        .map(|p| p.strip_prefix(&root).unwrap().to_path_buf())
        .collect()
}

fn read(relative: &str) -> String {
    fs::read_to_string(examples_dir().join(relative)).unwrap()
}

/// Decodes every top-level element of an example file.
fn decode_file(relative: &Path) -> Vec<Message> {
    let text = fs::read_to_string(examples_dir().join(relative)).unwrap();
    let roots =
        xml::parse_documents(&text).unwrap_or_else(|e| panic!("{}: {e}", relative.display()));
    assert!(!roots.is_empty(), "{}: no elements", relative.display());
    roots
        .into_iter()
        .map(|root| {
            Message::from_element(root).unwrap_or_else(|e| panic!("{}: {e}", relative.display()))
        })
        .collect()
}

fn kinds(messages: &[Message]) -> Vec<&str> {
    messages.iter().map(Message::kind).collect()
}

/// Encodes in `dialect` and decodes each frame again.
fn reencode(message: &Message, dialect: Dialect) -> Vec<Message> {
    message
        .encode(dialect)
        .iter()
        .map(|frame| Message::decode(frame).unwrap_or_else(|e| panic!("{e}: {frame}")))
        .collect()
}

#[test]
fn every_example_file_is_covered() {
    let files: Vec<String> = example_files()
        .iter()
        .map(|p| p.to_string_lossy().replace('\\', "/"))
        .collect();
    assert_eq!(
        files,
        [
            "collections/alerts_list.xml",
            "collections/basic_collection_message.xml",
            "collections/role_options.xml",
            "collections/system_metrics.xml",
            "layouts/attitude_indicator_with_values.xml",
            "layouts/basic_form.xml",
            "layouts/basic_layout_message.xml",
            "layouts/dashboard.xml",
            "layouts/layout_manager_main.xml",
            "layouts/layout_replacement_message.xml",
            "layouts/simple_button.xml",
            "records/attitude_indicator_record_message.xml",
            "records/basic_record_message.xml",
            "records/navigation_record.xml",
            "records/system_status_record.xml",
            "records/user_form_record.xml",
        ],
        "an example was added or removed; update the expectations in this file"
    );
}

#[test]
fn every_example_decodes_to_the_expected_messages() {
    let expected: &[(&str, &[&str])] = &[
        (
            "collections/alerts_list.xml",
            &["ISISCollection", "ISISRecord"],
        ),
        (
            "collections/basic_collection_message.xml",
            &["ISISCollection"],
        ),
        (
            "collections/role_options.xml",
            &["ISISCollection", "ISISRecord"],
        ),
        (
            "collections/system_metrics.xml",
            &["ISISCollection", "ISISRecord"],
        ),
        (
            "layouts/attitude_indicator_with_values.xml",
            &["set_ISISFormLayout"],
        ),
        ("layouts/basic_form.xml", &["VBox"]),
        ("layouts/basic_layout_message.xml", &["set_ISISFormLayout"]),
        ("layouts/dashboard.xml", &["HBox"]),
        ("layouts/layout_manager_main.xml", &["layout_manager"]),
        (
            "layouts/layout_replacement_message.xml",
            &["set_ISISFormLayout"],
        ),
        ("layouts/simple_button.xml", &["VBox"]),
        (
            "records/attitude_indicator_record_message.xml",
            &["ISISRecord"],
        ),
        ("records/basic_record_message.xml", &["ISISRecord"]),
        ("records/navigation_record.xml", &["ISISRecord"]),
        ("records/system_status_record.xml", &["ISISRecord"]),
        ("records/user_form_record.xml", &["ISISRecord"]),
    ];
    for &(file, want) in expected {
        let messages = decode_file(Path::new(file));
        let mut got = kinds(&messages);
        got.dedup();
        assert_eq!(got, want, "{file}");
    }
}

#[test]
fn every_example_message_round_trips_in_both_dialects() {
    for file in example_files() {
        for message in decode_file(&file) {
            for dialect in [Dialect::Invoke, Dialect::Bare] {
                let once = reencode(&message, dialect);
                let twice: Vec<Message> = once.iter().flat_map(|m| reencode(m, dialect)).collect();
                assert_eq!(once, twice, "{}: {dialect:?} is not stable", file.display());
                // Bare splits lists into one message per item; rejoin them.
                let rejoined = rejoin(once);
                assert_eq!(
                    rejoined,
                    message,
                    "{}: {dialect:?} changed the message",
                    file.display()
                );
            }
        }
    }
}

/// Merges consecutive single-item record or collection messages.
fn rejoin(messages: Vec<Message>) -> Message {
    let mut iter = messages.into_iter();
    let first = iter.next().expect("at least one message");
    iter.fold(first, |acc, next| match (acc, next) {
        (Message::Record(mut a), Message::Record(b)) => {
            a.extend(b);
            Message::Record(a)
        }
        (Message::Collection(mut a), Message::Collection(b)) => {
            a.extend(b);
            Message::Collection(a)
        }
        (a, b) => panic!("cannot rejoin {} and {}", a.kind(), b.kind()),
    })
}

#[test]
fn layout_files_round_trip_as_isis_layout() {
    for file in [
        "layouts/basic_form.xml",
        "layouts/dashboard.xml",
        "layouts/layout_manager_main.xml",
        "layouts/simple_button.xml",
    ] {
        let root = xml::parse_element(&read(file)).unwrap();
        let message = Message::Layout(Layout::new(root.clone()));
        for dialect in [Dialect::Invoke, Dialect::Bare] {
            let back = reencode(&message, dialect);
            let [Message::Layout(layout)] = back.as_slice() else {
                panic!("{file}: {dialect:?} gave {back:?}");
            };
            assert_eq!(layout.root, root, "{file}: {dialect:?} changed the tree");
        }
    }
}

#[test]
fn layout_manager_calls_carry_their_layout_tree() {
    // `set_ISISFormLayout` is a Layout Manager function, not a client one.
    // Phase 3 interprets it; here the tree must survive intact.
    let messages = decode_file(Path::new("layouts/layout_replacement_message.xml"));
    let [Message::Other(invoke)] = messages.as_slice() else {
        panic!("{messages:?}")
    };
    let parent = invoke
        .child("args")
        .and_then(|a| a.child("arg"))
        .and_then(|a| a.child("Parent"))
        .expect("Parent element");
    assert_eq!(parent.attr("luid"), Some("hbox2"));
    let button = parent.child("Button").unwrap();
    assert_eq!(button.attr("label1"), Some("NewTop"));
}

fn apply_file(store: &mut Store, file: &str) {
    for message in decode_file(Path::new(file)) {
        let changes = apply(store, &message);
        assert!(
            changes.warnings.is_empty(),
            "{file}: {}",
            changes
                .warnings
                .iter()
                .map(ToString::to_string)
                .collect::<Vec<_>>()
                .join("; ")
        );
    }
}

#[test]
fn ux_guide_collection_and_records_build_expected_tree() {
    let mut store = Store::new();
    apply_file(&mut store, "collections/basic_collection_message.xml");
    apply_file(&mut store, "records/basic_record_message.xml");
    apply_file(&mut store, "records/attitude_indicator_record_message.xml");

    let collection = store.collection("datagrid1").unwrap();
    assert_eq!(collection.to_string(), "r1\n  r1-1\n  r1-2\nr2\n");

    assert_eq!(store.value("r1", "column1"), Some("col1"));
    assert_eq!(store.value("r1", "column3"), Some("col3"));
    assert_eq!(store.value("attitudeIndicator", "roll"), Some("4"));
    assert_eq!(store.value("attitudeIndicator", "sideSlip"), Some("7"));
    assert_eq!(store.value("attitudeIndicator", "pitch"), Some("10"));
}

#[test]
fn alerts_list_orders_records_and_decodes_entities() {
    let mut store = Store::new();
    apply_file(&mut store, "collections/alerts_list.xml");

    let order: Vec<_> = store
        .collection("alerts_list")
        .unwrap()
        .roots()
        .iter()
        .map(|r| r.as_str())
        .collect();
    assert_eq!(
        order,
        [
            "alert_db_001",
            "alert_sec_007",
            "alert_mem_002",
            "alert_maint_003",
            "alert_net_004",
            "alert_login_005",
            "alert_disk_006",
        ]
    );
    assert_eq!(
        store.value("alert_net_004", "detailed_message"),
        Some("Average network latency has increased to 180ms (normal: <50ms)")
    );
}

#[test]
fn bare_records_keep_unicode_and_empty_values() {
    let mut store = Store::new();
    apply_file(&mut store, "records/navigation_record.xml");
    apply_file(&mut store, "records/user_form_record.xml");
    assert_eq!(
        store.value("navigation_data", "heading_display"),
        Some("045° NE")
    );
    assert_eq!(store.value("user_form_record", "username"), Some(""));
    assert_eq!(
        store.value("user_form_record", "selected_role"),
        Some("user")
    );
}

#[test]
fn every_data_example_applies_without_warnings() {
    let mut store = Store::new();
    for file in example_files() {
        let path = file.to_string_lossy().replace('\\', "/");
        if path.starts_with("records/") || path.starts_with("collections/") {
            apply_file(&mut store, &path);
        }
    }
    for cuid in ["alerts_list", "datagrid1", "role_options", "system_metrics"] {
        let collection = store.collection(cuid).unwrap();
        assert!(!collection.is_empty(), "{cuid}");
        for (_, ruid) in collection.iter() {
            let record = store.record(ruid);
            if cuid != "datagrid1" {
                assert!(record.is_some(), "{cuid} lists '{ruid}' with no record");
            }
        }
    }
}

#[test]
fn framing_carries_every_example_message() {
    use gmx_proto::{FrameDecoder, encode_frame};

    let mut wire = Vec::new();
    let mut sent = Vec::new();
    for file in example_files() {
        for message in decode_file(&file) {
            for frame in message.encode(Dialect::Invoke) {
                encode_frame(&frame, &mut wire);
                sent.push(frame);
            }
        }
    }
    // Deliver in awkward chunks to exercise reassembly.
    let mut decoder = FrameDecoder::default();
    let mut received = Vec::new();
    for chunk in wire.chunks(97) {
        decoder.push(chunk);
        while let Some(frame) = decoder.next_frame() {
            received.push(String::from_utf8(frame.unwrap()).unwrap());
        }
    }
    assert_eq!(received, sent);
}

#[test]
fn layout_element_tree_survives_text_embedding() {
    // The invoke dialect sends a layout as escaped text inside <Layout>.
    // Values with quotes, angle brackets and newlines must survive that.
    let root = Element::new("Label")
        .with_attr("luid", "x")
        .with_attr("text", "a \"quoted\" <tag> & line\nbreak");
    let message = Message::Layout(Layout::new(root.clone()));
    let back = reencode(&message, Dialect::Invoke);
    assert_eq!(back, [message]);
}
