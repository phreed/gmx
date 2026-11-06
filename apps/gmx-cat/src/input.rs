//! Turning input files into frames.

use std::io::Read;
use std::path::Path;

use gmx_net::OutFrame;
use gmx_proto::{Dialect, Message, xml};

/// Reads a file, or standard input for `-`.
pub fn read_input(path: &Path) -> Result<String, String> {
    if path.as_os_str() == "-" {
        let mut text = String::new();
        std::io::stdin()
            .read_to_string(&mut text)
            .map_err(|e| format!("standard input: {e}"))?;
        return Ok(text);
    }
    std::fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))
}

/// Splits input text into frames.
///
/// Text whose first non-blank character is `<` is XML; each top-level
/// element becomes one frame, so files holding several messages work.
/// Other text is plain commands, one per non-blank line.
///
/// With a dialect, each XML element is decoded as a message and encoded in
/// that dialect. Without one, elements are sent as written, minus comments
/// and insignificant whitespace.
pub fn frames_from_text(
    text: &str,
    source: &str,
    dialect: Option<Dialect>,
) -> Result<Vec<OutFrame>, String> {
    let text = text.strip_prefix('\u{feff}').unwrap_or(text);
    if !text.trim_start().starts_with('<') {
        return Ok(text
            .lines()
            .map(str::trim)
            .filter(|line| !line.is_empty())
            .map(OutFrame::new)
            .collect());
    }
    let roots = xml::parse_documents(text).map_err(|e| format!("{source}: {e}"))?;
    let mut frames = Vec::new();
    for root in roots {
        match dialect {
            None => frames.push(OutFrame::new(&root.to_xml())),
            Some(dialect) => {
                let message = Message::from_element(root).map_err(|e| format!("{source}: {e}"))?;
                frames.extend(OutFrame::from_message(&message, dialect));
            }
        }
    }
    Ok(frames)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn payloads(frames: &[OutFrame]) -> Vec<String> {
        frames
            .iter()
            .map(|f| String::from_utf8(f.payload().to_vec()).unwrap())
            .collect()
    }

    #[test]
    fn splits_xml_into_one_frame_per_root() {
        let text = "\u{feff}<?xml version=\"1.0\"?>\n<!-- c -->\n<a x=\"1\">\n  <b/>\n</a>\n<c/>\n";
        let frames = frames_from_text(text, "t", None).unwrap();
        assert_eq!(payloads(&frames), ["<a x=\"1\"><b/></a>", "<c/>"]);
    }

    #[test]
    fn plain_text_is_one_command_per_line() {
        let frames =
            frames_from_text("LIST_LAYOUTS\n\n  GET_LAYOUT:mainLuid  \n", "t", None).unwrap();
        assert_eq!(payloads(&frames), ["LIST_LAYOUTS", "GET_LAYOUT:mainLuid"]);
    }

    #[test]
    fn converts_dialects() {
        let bare = "<ISISRecord ruid=\"r\"><Field fid=\"a\" value=\"1\"/></ISISRecord>";
        let invoke = frames_from_text(bare, "t", Some(Dialect::Invoke)).unwrap();
        assert!(payloads(&invoke)[0].starts_with("<invoke fn=\"ISISRecord\">"));
        let back = frames_from_text(&payloads(&invoke)[0], "t", Some(Dialect::Bare)).unwrap();
        assert_eq!(payloads(&back), [bare]);
    }

    #[test]
    fn reports_the_source_of_errors() {
        let err = frames_from_text("<a>", "file.xml", None).unwrap_err();
        assert!(err.starts_with("file.xml: "), "{err}");
        let err = frames_from_text("<invoke fn=\"ISISRecord\"/>", "x.xml", Some(Dialect::Bare))
            .unwrap_err();
        assert!(err.starts_with("x.xml: "), "{err}");
    }
}
