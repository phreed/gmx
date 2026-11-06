//! Comparing a replay's replies with a capture's.

use std::str::FromStr;

use gmx_net::Inbound;
use gmx_proto::{FrameError, Message};

/// A `RUID.FID` pattern whose values are ignored. `*` matches any run of
/// characters, so `*.last_updated` and `navigation_data.*` both work. The
/// FID is the part after the last `.`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FieldMask {
    ruid: String,
    fid: String,
}

impl FromStr for FieldMask {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, String> {
        match s.rsplit_once('.') {
            Some((ruid, fid)) if !ruid.is_empty() && !fid.is_empty() => Ok(Self {
                ruid: ruid.to_owned(),
                fid: fid.to_owned(),
            }),
            _ => Err(format!(
                "'{s}' is not RUID.FID, for example '*.last_updated'"
            )),
        }
    }
}

impl FieldMask {
    fn matches(&self, ruid: &str, fid: &str) -> bool {
        glob(&self.ruid, ruid) && glob(&self.fid, fid)
    }
}

/// Matches `*` against any run of characters.
fn glob(pattern: &str, text: &str) -> bool {
    let mut parts = pattern.split('*');
    let first = parts.next().unwrap_or_default();
    let Some(mut rest) = text.strip_prefix(first) else {
        return false;
    };
    let parts: Vec<&str> = parts.collect();
    let Some((last, middle)) = parts.split_last() else {
        return rest.is_empty();
    };
    for part in middle {
        match rest.find(part) {
            Some(i) => rest = &rest[i + part.len()..],
            None => return false,
        }
    }
    rest.len() >= last.len() && rest.ends_with(last)
}

/// A frame in comparable form.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Comparable {
    /// A decoded message, with masked fields blanked. Formatting
    /// differences such as attribute quoting do not matter.
    Message(Message),
    /// A frame that did not decode, compared byte for byte.
    Raw(Vec<u8>),
    /// An oversized frame that was dropped.
    Dropped(usize),
}

impl Comparable {
    /// Normalizes a frame.
    pub fn new(inbound: &Inbound, masks: &[FieldMask]) -> Self {
        match inbound {
            Inbound::Dropped(FrameError::TooLong { limit }) => Self::Dropped(*limit),
            Inbound::Frame(bytes) => match Message::decode_frame(bytes) {
                Ok(mut message) => {
                    mask(&mut message, masks);
                    Self::Message(message)
                }
                Err(_) => Self::Raw(bytes.clone()),
            },
        }
    }
}

const MASKED: &str = "\u{2026}masked\u{2026}";

fn mask(message: &mut Message, masks: &[FieldMask]) {
    if masks.is_empty() {
        return;
    }
    if let Message::Record(records) | Message::DataEdit(records) = message {
        for record in records {
            for field in &mut record.fields {
                if masks.iter().any(|m| m.matches(&record.ruid, &field.fid)) {
                    field.value = MASKED.into();
                }
            }
        }
    }
}

/// The result of aligning expected and actual frames.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Comparison {
    /// Frames found in both, in order.
    pub matched: usize,
    /// Indices of expected frames that never arrived.
    pub missing: Vec<usize>,
    /// Indices of actual frames that were not expected.
    pub unexpected: Vec<usize>,
}

/// Aligns two frame sequences with a longest common subsequence, so that
/// one extra or missing frame does not misalign the rest.
pub fn compare(expected: &[Comparable], actual: &[Comparable]) -> Comparison {
    let (n, m) = (expected.len(), actual.len());
    // lcs[i][j] is the LCS length of expected[i..] and actual[j..].
    let mut lcs = vec![vec![0u32; m + 1]; n + 1];
    for i in (0..n).rev() {
        for j in (0..m).rev() {
            lcs[i][j] = if expected[i] == actual[j] {
                lcs[i + 1][j + 1] + 1
            } else {
                lcs[i + 1][j].max(lcs[i][j + 1])
            };
        }
    }
    let mut result = Comparison::default();
    let (mut i, mut j) = (0, 0);
    while i < n && j < m {
        if expected[i] == actual[j] {
            result.matched += 1;
            i += 1;
            j += 1;
        } else if lcs[i + 1][j] >= lcs[i][j + 1] {
            result.missing.push(i);
            i += 1;
        } else {
            result.unexpected.push(j);
            j += 1;
        }
    }
    result.missing.extend(i..n);
    result.unexpected.extend(j..m);
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn raw(s: &str) -> Comparable {
        Comparable::Raw(s.as_bytes().to_vec())
    }

    #[test]
    fn glob_patterns() {
        assert!(glob("*", ""));
        assert!(glob("*", "abc"));
        assert!(glob("abc", "abc"));
        assert!(!glob("abc", "abcd"));
        assert!(glob("a*", "abc"));
        assert!(glob("*c", "abc"));
        assert!(glob("a*c", "abc"));
        assert!(glob("a*c", "ac"));
        assert!(!glob("a*c", "ab"));
        assert!(glob("*b*", "abc"));
        assert!(glob("a*b*c", "a_b_c"));
        assert!(!glob("a*b*c", "a_c_b"));
        assert!(!glob("ab*ab", "ab"), "prefix and suffix may not overlap");
    }

    #[test]
    fn field_mask_parsing() {
        let mask: FieldMask = "nav.data.heading".parse().unwrap();
        assert!(mask.matches("nav.data", "heading"));
        assert!("nofid".parse::<FieldMask>().is_err());
        assert!(".fid".parse::<FieldMask>().is_err());
        assert!("ruid.".parse::<FieldMask>().is_err());
    }

    #[test]
    fn masks_blank_matching_record_fields() {
        let frame = |time: &str| {
            Inbound::Frame(
                format!(
                    "<ISISRecord ruid=\"system_status\"><Field fid=\"current_time\" value=\"{time}\"/>\
                     <Field fid=\"status_text\" value=\"ok\"/></ISISRecord>"
                )
                .into_bytes(),
            )
        };
        let masks = ["*.current_time".parse().unwrap()];
        assert_eq!(
            Comparable::new(&frame("10:00"), &masks),
            Comparable::new(&frame("10:01"), &masks)
        );
        assert_ne!(
            Comparable::new(&frame("10:00"), &[]),
            Comparable::new(&frame("10:01"), &[])
        );
    }

    #[test]
    fn formatting_differences_do_not_matter() {
        let a = Inbound::Frame(b"<ISISRefresh action='reset' />".to_vec());
        let b = Inbound::Frame(b"<ISISRefresh action=\"reset\"/>".to_vec());
        assert_eq!(Comparable::new(&a, &[]), Comparable::new(&b, &[]));
        let bad = Inbound::Frame(b"not a command".to_vec());
        assert_eq!(Comparable::new(&bad, &[]), raw("not a command"));
    }

    #[test]
    fn alignment_reports_missing_and_unexpected() {
        let seq = |s: &str| s.chars().map(|c| raw(&c.to_string())).collect::<Vec<_>>();
        assert_eq!(
            compare(&seq("abc"), &seq("abc")),
            Comparison {
                matched: 3,
                ..Default::default()
            }
        );
        // An extra frame in the middle does not misalign the rest.
        assert_eq!(
            compare(&seq("abcd"), &seq("abXcd")),
            Comparison {
                matched: 4,
                missing: vec![],
                unexpected: vec![2],
            }
        );
        assert_eq!(
            compare(&seq("abcd"), &seq("acd")),
            Comparison {
                matched: 3,
                missing: vec![1],
                unexpected: vec![],
            }
        );
        assert_eq!(
            compare(&seq("ab"), &seq("")),
            Comparison {
                matched: 0,
                missing: vec![0, 1],
                unexpected: vec![],
            }
        );
        assert_eq!(compare(&[], &seq("x")).unexpected, [0]);
    }
}
