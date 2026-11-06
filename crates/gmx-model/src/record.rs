//! Records and fields.

use indexmap::IndexMap;

use crate::attributes::{Attributes, Send};
use crate::ids::{Fid, Ruid};

/// One named value in a record, with its attributes.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Field {
    /// The current value. GMX values are always strings.
    pub value: String,
    /// Attributes set by `ISISAttributes`.
    pub attributes: Attributes,
}

/// How an incoming record message changes the record's `layout` string.
///
/// The `layout` string carries Layout Manager commands such as
/// `|Shortcut|:sample_main:tabPortal|:sampleh_tab`.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum LayoutUpdate {
    /// Leave the layout unchanged. Sent as an absent or empty `layout`.
    #[default]
    Keep,
    /// Remove the layout. Sent as a value starting with `|null`.
    Clear,
    /// Replace the layout.
    Set(String),
}

impl LayoutUpdate {
    /// Interprets the wire value of a record's `layout` element.
    ///
    /// The legacy client meant to ignore empty values, but its condition
    /// tested the stored layout instead of the incoming one
    /// (`GMXMain.ISISRecord`, commit `073e595`). This implements the intent.
    pub fn from_wire(layout: Option<&str>) -> Self {
        match layout {
            None | Some("") => Self::Keep,
            Some(s) if s.starts_with("|null") => Self::Clear,
            Some(s) => Self::Set(s.to_owned()),
        }
    }
}

/// A record: an ordered set of fields under one RUID.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Record {
    ruid: Ruid,
    layout: Option<String>,
    fields: IndexMap<Fid, Field>,
}

impl Record {
    /// Creates an empty record.
    pub fn new(ruid: Ruid) -> Self {
        Self {
            ruid,
            layout: None,
            fields: IndexMap::new(),
        }
    }

    /// The record's identifier.
    pub fn ruid(&self) -> &Ruid {
        &self.ruid
    }

    /// The Layout Manager command attached to the record, if any.
    pub fn layout(&self) -> Option<&str> {
        self.layout.as_deref()
    }

    /// Applies a layout update and reports whether the layout changed.
    pub fn update_layout(&mut self, update: &LayoutUpdate) -> bool {
        let new = match update {
            LayoutUpdate::Keep => return false,
            LayoutUpdate::Clear => None,
            LayoutUpdate::Set(s) => Some(s.clone()),
        };
        let changed = self.layout != new;
        self.layout = new;
        changed
    }

    /// Looks up a field.
    pub fn field(&self, fid: &str) -> Option<&Field> {
        self.fields.get(fid)
    }

    /// Looks up a field's value.
    pub fn value(&self, fid: &str) -> Option<&str> {
        self.fields.get(fid).map(|f| f.value.as_str())
    }

    /// Iterates over the fields in insertion order.
    pub fn fields(&self) -> impl Iterator<Item = (&Fid, &Field)> {
        self.fields.iter()
    }

    /// Returns the field, creating it with an empty value if needed.
    pub fn field_mut(&mut self, fid: Fid) -> &mut Field {
        self.fields.entry(fid).or_default()
    }

    /// Sets a field value, creating the field if needed.
    ///
    /// Returns true when the field is new or its value changed. The legacy
    /// client likewise skipped widget updates when a value was unchanged.
    pub fn set_value(&mut self, fid: Fid, value: impl Into<String>) -> bool {
        let value = value.into();
        match self.fields.get_mut(&fid) {
            Some(field) if field.value == value => false,
            Some(field) => {
                field.value = value;
                true
            }
            None => {
                self.fields.insert(
                    fid,
                    Field {
                        value,
                        ..Field::default()
                    },
                );
                true
            }
        }
    }

    /// Selects the fields to include in an outbound `ISISDataEdit`.
    ///
    /// Follows `Record.sendMessage` in the legacy client: fields marked
    /// `never` are skipped, and fields marked `changed` are included only
    /// when they are the field the user edited.
    pub fn data_edit_fields(&self, changed: Option<&str>) -> Vec<(&Fid, &str)> {
        self.fields
            .iter()
            .filter(|(fid, field)| match field.attributes.send {
                Send::Always => true,
                Send::Never => false,
                Send::Changed => changed == Some(fid.as_str()),
            })
            .map(|(fid, field)| (fid, field.value.as_str()))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn layout_update_from_wire() {
        assert_eq!(LayoutUpdate::from_wire(None), LayoutUpdate::Keep);
        assert_eq!(LayoutUpdate::from_wire(Some("")), LayoutUpdate::Keep);
        assert_eq!(LayoutUpdate::from_wire(Some("|null")), LayoutUpdate::Clear);
        assert_eq!(
            LayoutUpdate::from_wire(Some("|nullify")),
            LayoutUpdate::Clear
        );
        assert_eq!(
            LayoutUpdate::from_wire(Some("|Shortcut|:a:b")),
            LayoutUpdate::Set("|Shortcut|:a:b".into())
        );
    }

    #[test]
    fn layout_keep_set_clear() {
        let mut rec = Record::new("r".into());
        assert!(!rec.update_layout(&LayoutUpdate::Keep));
        assert!(rec.update_layout(&LayoutUpdate::Set("x".into())));
        assert!(!rec.update_layout(&LayoutUpdate::Set("x".into())));
        assert!(!rec.update_layout(&LayoutUpdate::Keep));
        assert_eq!(rec.layout(), Some("x"));
        assert!(rec.update_layout(&LayoutUpdate::Clear));
        assert_eq!(rec.layout(), None);
    }

    #[test]
    fn set_value_reports_changes_and_keeps_order() {
        let mut rec = Record::new("r".into());
        assert!(rec.set_value("b".into(), "1"));
        assert!(rec.set_value("a".into(), "2"));
        assert!(!rec.set_value("b".into(), "1"));
        assert!(rec.set_value("b".into(), "3"));
        let order: Vec<_> = rec.fields().map(|(fid, _)| fid.as_str()).collect();
        assert_eq!(order, ["b", "a"]);
        assert_eq!(rec.value("b"), Some("3"));
        assert_eq!(rec.value("zz"), None);
    }

    #[test]
    fn data_edit_respects_send_attribute() {
        let mut rec = Record::new("r".into());
        rec.set_value("always".into(), "1");
        rec.set_value("never".into(), "2");
        rec.set_value("changed".into(), "3");
        rec.field_mut("never".into()).attributes.send = Send::Never;
        rec.field_mut("changed".into()).attributes.send = Send::Changed;

        let fids = |changed| -> Vec<String> {
            rec.data_edit_fields(changed)
                .into_iter()
                .map(|(fid, _)| fid.to_string())
                .collect()
        };
        assert_eq!(fids(None), ["always"]);
        assert_eq!(fids(Some("always")), ["always"]);
        assert_eq!(fids(Some("changed")), ["always", "changed"]);
    }
}
