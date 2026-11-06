//! Plain-text debug commands.
//!
//! The Python reference servers in `examples/servers/` accept a few
//! plain-text requests alongside XML, and `tests/test_gmx.py` relies on
//! them. Listing replies carry a JSON array formatted as Python's
//! `json.dumps` formats it, so that Rust and Python servers can be compared
//! byte for byte.

use std::fmt;
use std::fmt::Write as _;

use gmx_model::{Cuid, Luid, Ruid};

/// A plain-text request or reply.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    /// `GET_LAYOUT:<luid>`: send the layout stored under the LUID.
    GetLayout(Luid),
    /// `LIST_LAYOUTS`: reply with [`Command::Layouts`].
    ListLayouts,
    /// `GET_RECORD:<ruid>`: send the record.
    GetRecord(Ruid),
    /// `GET_COLLECTION:<cuid>`: send the collection.
    GetCollection(Cuid),
    /// `LIST_RECORDS`: reply with [`Command::Records`].
    ListRecords,
    /// `LIST_COLLECTIONS`: reply with [`Command::Collections`].
    ListCollections,
    /// `LAYOUTS:[...]`: the stored layout names.
    Layouts(Vec<String>),
    /// `RECORDS:[...]`: the stored record names.
    Records(Vec<String>),
    /// `COLLECTIONS:[...]`: the stored collection names.
    Collections(Vec<String>),
}

/// Text that is not a known command.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UnknownCommand(pub String);

impl fmt::Display for UnknownCommand {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        const LIMIT: usize = 60;
        match self.0.char_indices().nth(LIMIT) {
            Some((i, _)) => write!(f, "unknown command '{}...'", &self.0[..i]),
            None => write!(f, "unknown command '{}'", self.0),
        }
    }
}

impl std::error::Error for UnknownCommand {}

impl Command {
    /// Parses a trimmed frame.
    pub fn parse(text: &str) -> Result<Self, UnknownCommand> {
        let unknown = || UnknownCommand(text.to_owned());
        let list = |json: &str| serde_json::from_str::<Vec<String>>(json).map_err(|_| unknown());
        if let Some((verb, arg)) = text.split_once(':') {
            return match verb {
                "GET_LAYOUT" => Ok(Self::GetLayout(arg.into())),
                "GET_RECORD" => Ok(Self::GetRecord(arg.into())),
                "GET_COLLECTION" => Ok(Self::GetCollection(arg.into())),
                "LAYOUTS" => list(arg).map(Self::Layouts),
                "RECORDS" => list(arg).map(Self::Records),
                "COLLECTIONS" => list(arg).map(Self::Collections),
                _ => Err(unknown()),
            };
        }
        match text {
            "LIST_LAYOUTS" => Ok(Self::ListLayouts),
            "LIST_RECORDS" => Ok(Self::ListRecords),
            "LIST_COLLECTIONS" => Ok(Self::ListCollections),
            _ => Err(unknown()),
        }
    }

    /// The wire form, without the NUL terminator.
    pub fn encode(&self) -> String {
        match self {
            Self::GetLayout(luid) => format!("GET_LAYOUT:{luid}"),
            Self::ListLayouts => "LIST_LAYOUTS".into(),
            Self::GetRecord(ruid) => format!("GET_RECORD:{ruid}"),
            Self::GetCollection(cuid) => format!("GET_COLLECTION:{cuid}"),
            Self::ListRecords => "LIST_RECORDS".into(),
            Self::ListCollections => "LIST_COLLECTIONS".into(),
            Self::Layouts(names) => format!("LAYOUTS:{}", python_json_list(names)),
            Self::Records(names) => format!("RECORDS:{}", python_json_list(names)),
            Self::Collections(names) => format!("COLLECTIONS:{}", python_json_list(names)),
        }
    }
}

/// Formats strings as Python's `json.dumps(list)` does by default:
/// `", "` between items and every non-ASCII character escaped.
fn python_json_list(items: &[String]) -> String {
    let mut out = String::from("[");
    for (i, item) in items.iter().enumerate() {
        if i > 0 {
            out.push_str(", ");
        }
        out.push('"');
        for ch in item.chars() {
            match ch {
                '"' => out.push_str("\\\""),
                '\\' => out.push_str("\\\\"),
                '\n' => out.push_str("\\n"),
                '\r' => out.push_str("\\r"),
                '\t' => out.push_str("\\t"),
                '\u{8}' => out.push_str("\\b"),
                '\u{c}' => out.push_str("\\f"),
                c if c.is_ascii() && !c.is_ascii_control() => out.push(c),
                c => {
                    let mut units = [0u16; 2];
                    for unit in c.encode_utf16(&mut units) {
                        let _ = write!(out, "\\u{unit:04x}");
                    }
                }
            }
        }
        out.push('"');
    }
    out.push(']');
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_requests() {
        assert_eq!(
            Command::parse("GET_LAYOUT:mainLuid"),
            Ok(Command::GetLayout("mainLuid".into()))
        );
        assert_eq!(
            Command::parse("GET_RECORD:a:b"),
            Ok(Command::GetRecord("a:b".into()))
        );
        assert_eq!(
            Command::parse("GET_COLLECTION:"),
            Ok(Command::GetCollection("".into()))
        );
        assert_eq!(Command::parse("LIST_LAYOUTS"), Ok(Command::ListLayouts));
        assert_eq!(Command::parse("LIST_RECORDS"), Ok(Command::ListRecords));
        assert_eq!(
            Command::parse("LIST_COLLECTIONS"),
            Ok(Command::ListCollections)
        );
    }

    #[test]
    fn rejects_unknown_text() {
        assert!(Command::parse("HELLO").is_err());
        assert!(Command::parse("list_layouts").is_err());
        assert!(Command::parse("LAYOUTS:not json").is_err());
        let long = "X".repeat(100);
        assert!(UnknownCommand(long).to_string().ends_with("...'"));
    }

    #[test]
    fn listing_matches_python_json_dumps() {
        // Python: json.dumps(["mainLuid", "simple"]) == '["mainLuid", "simple"]'
        let cmd = Command::Layouts(vec!["mainLuid".into(), "simple".into()]);
        assert_eq!(cmd.encode(), r#"LAYOUTS:["mainLuid", "simple"]"#);
        assert_eq!(Command::Records(vec![]).encode(), "RECORDS:[]");
        // Python: json.dumps(['a"b\\c', 'é😀', '\x01']) ==
        //   '["a\\"b\\\\c", "\\u00e9\\ud83d\\ude00", "\\u0001"]'
        let cmd = Command::Collections(vec!["a\"b\\c".into(), "é😀".into(), "\u{1}".into()]);
        assert_eq!(
            cmd.encode(),
            r#"COLLECTIONS:["a\"b\\c", "\u00e9\ud83d\ude00", "\u0001"]"#
        );
    }

    #[test]
    fn round_trips() {
        let cases = [
            Command::GetLayout("x".into()),
            Command::ListLayouts,
            Command::GetRecord("r".into()),
            Command::GetCollection("c".into()),
            Command::ListRecords,
            Command::ListCollections,
            Command::Layouts(vec!["a".into(), "é".into()]),
            Command::Records(vec!["r\"1".into()]),
            Command::Collections(vec![]),
        ];
        for cmd in cases {
            assert_eq!(Command::parse(&cmd.encode()), Ok(cmd.clone()), "{cmd:?}");
        }
    }
}
