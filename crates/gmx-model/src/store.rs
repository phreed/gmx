//! The data store.
//!
//! The store holds every record and collection, applies updates and reports
//! what changed. Update types here are independent of the wire format;
//! `gmx-proto` converts messages into them.

use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::fmt;

use crate::attributes::{AttributeUpdate, InvalidAttribute};
use crate::collection::{Collection, CollectionError, CollectionOp};
use crate::ids::{Cuid, Fid, Ruid};
use crate::record::{LayoutUpdate, Record};

/// New values for some fields of one record.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RecordUpdate {
    /// The record to update. It is created if missing.
    pub ruid: Ruid,
    /// The change to the record's Layout Manager command.
    pub layout: LayoutUpdate,
    /// Field values, applied in order.
    pub fields: Vec<(Fid, String)>,
}

/// Operations on one collection.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CollectionUpdate {
    /// The collection to update. It is created if missing.
    pub cuid: Cuid,
    /// Operations, applied in order.
    pub ops: Vec<CollectionOp>,
}

/// New attribute values for one field.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AttributeChange {
    /// The record holding the field. It is created if missing.
    pub ruid: Ruid,
    /// The field. It is created if missing.
    pub fid: Fid,
    /// The attributes to change.
    pub update: AttributeUpdate,
}

/// A problem found while applying an update. Other parts still apply.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StoreWarning {
    /// A collection operation was rejected.
    Collection {
        /// The collection.
        cuid: Cuid,
        /// Index of the rejected operation within its message.
        index: usize,
        /// Why it was rejected.
        error: CollectionError,
    },
    /// An attribute value was not recognized and was ignored.
    InvalidAttribute {
        /// The record.
        ruid: Ruid,
        /// The field.
        fid: Fid,
        /// The rejected value.
        error: InvalidAttribute,
    },
    /// A required identifier was empty, so the item was skipped.
    MissingId(&'static str),
    /// A record held content that is not part of the protocol, which was
    /// ignored.
    Unsupported {
        /// The record.
        ruid: Ruid,
        /// What was ignored, and what to do instead.
        message: &'static str,
    },
}

impl fmt::Display for StoreWarning {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Collection { cuid, index, error } => {
                write!(f, "collection '{cuid}' operation {index}: {error}")
            }
            Self::InvalidAttribute { ruid, fid, error } => {
                write!(f, "field '{ruid}.{fid}': {error}")
            }
            Self::MissingId(what) => f.write_str(what),
            Self::Unsupported { ruid, message } => write!(f, "record '{ruid}': {message}"),
        }
    }
}

/// What an update changed.
///
/// Sets are ordered so that results are deterministic in tests and logs.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct ChangeSet {
    /// Fields whose values changed or were created, by record.
    pub fields: BTreeMap<Ruid, BTreeSet<Fid>>,
    /// Records whose Layout Manager command changed.
    pub layouts: BTreeSet<Ruid>,
    /// Fields whose attributes changed, by record.
    pub attributes: BTreeMap<Ruid, BTreeSet<Fid>>,
    /// Collections whose structure, or one of whose records, changed.
    pub collections: BTreeSet<Cuid>,
    /// Problems found while applying.
    pub warnings: Vec<StoreWarning>,
}

impl ChangeSet {
    /// Returns true when nothing changed and nothing went wrong.
    pub fn is_empty(&self) -> bool {
        self.fields.is_empty()
            && self.layouts.is_empty()
            && self.attributes.is_empty()
            && self.collections.is_empty()
            && self.warnings.is_empty()
    }

    /// Merges another change set into this one.
    pub fn merge(&mut self, other: ChangeSet) {
        for (ruid, fids) in other.fields {
            self.fields.entry(ruid).or_default().extend(fids);
        }
        self.layouts.extend(other.layouts);
        for (ruid, fids) in other.attributes {
            self.attributes.entry(ruid).or_default().extend(fids);
        }
        self.collections.extend(other.collections);
        self.warnings.extend(other.warnings);
    }
}

/// All records and collections.
#[derive(Clone, Debug, Default)]
pub struct Store {
    records: HashMap<Ruid, Record>,
    collections: HashMap<Cuid, Collection>,
}

impl Store {
    /// Creates an empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Looks up a record.
    pub fn record(&self, ruid: &str) -> Option<&Record> {
        self.records.get(ruid)
    }

    /// Looks up a field value.
    pub fn value(&self, ruid: &str, fid: &str) -> Option<&str> {
        self.records.get(ruid)?.value(fid)
    }

    /// Looks up a collection.
    pub fn collection(&self, cuid: &str) -> Option<&Collection> {
        self.collections.get(cuid)
    }

    /// Iterates over all records, in no particular order.
    pub fn records(&self) -> impl Iterator<Item = &Record> {
        self.records.values()
    }

    /// Iterates over all collections, in no particular order.
    pub fn collections(&self) -> impl Iterator<Item = (&Cuid, &Collection)> {
        self.collections.iter()
    }

    /// Returns the record, creating it if needed.
    pub fn record_mut(&mut self, ruid: &Ruid) -> &mut Record {
        self.records
            .entry(ruid.clone())
            .or_insert_with(|| Record::new(ruid.clone()))
    }

    /// Applies record updates, as from one `ISISRecord` message.
    pub fn apply_records(&mut self, updates: &[RecordUpdate]) -> ChangeSet {
        let mut changes = ChangeSet::default();
        for update in updates {
            let record = self.record_mut(&update.ruid);
            let mut touched = false;
            if record.update_layout(&update.layout) {
                changes.layouts.insert(update.ruid.clone());
                touched = true;
            }
            for (fid, value) in &update.fields {
                if record.set_value(fid.clone(), value.clone()) {
                    changes
                        .fields
                        .entry(update.ruid.clone())
                        .or_default()
                        .insert(fid.clone());
                    touched = true;
                }
            }
            if touched {
                self.mark_collections_containing(&update.ruid, &mut changes);
            }
        }
        changes
    }

    /// Applies collection updates, as from one `ISISCollection` message.
    ///
    /// A rejected operation becomes a warning; later operations still apply,
    /// as in the legacy client.
    pub fn apply_collections(&mut self, updates: &[CollectionUpdate]) -> ChangeSet {
        let mut changes = ChangeSet::default();
        for update in updates {
            let collection = self.collections.entry(update.cuid.clone()).or_default();
            for (index, op) in update.ops.iter().enumerate() {
                match collection.apply(op) {
                    Ok(true) => {
                        changes.collections.insert(update.cuid.clone());
                    }
                    Ok(false) => {}
                    Err(error) => changes.warnings.push(StoreWarning::Collection {
                        cuid: update.cuid.clone(),
                        index,
                        error,
                    }),
                }
            }
        }
        changes
    }

    /// Applies attribute changes, as from one `ISISAttributes` message.
    pub fn apply_attributes(&mut self, updates: &[AttributeChange]) -> ChangeSet {
        let mut changes = ChangeSet::default();
        for change in updates {
            let field = self.record_mut(&change.ruid).field_mut(change.fid.clone());
            if field.attributes.apply(&change.update) {
                changes
                    .attributes
                    .entry(change.ruid.clone())
                    .or_default()
                    .insert(change.fid.clone());
            }
        }
        changes
    }

    /// Adds every collection that contains `ruid` to the change set.
    ///
    /// Linear in the number of collections. An index can replace this if
    /// profiling shows a need.
    fn mark_collections_containing(&self, ruid: &Ruid, changes: &mut ChangeSet) {
        for (cuid, collection) in &self.collections {
            if collection.contains(ruid) {
                changes.collections.insert(cuid.clone());
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::attributes::Permissions;

    fn record_update(ruid: &str, fields: &[(&str, &str)]) -> RecordUpdate {
        RecordUpdate {
            ruid: ruid.into(),
            layout: LayoutUpdate::Keep,
            fields: fields
                .iter()
                .map(|&(f, v)| (Fid::from(f), v.to_owned()))
                .collect(),
        }
    }

    fn collection_update(cuid: &str, ops: &[(&str, &str, &str)]) -> CollectionUpdate {
        CollectionUpdate {
            cuid: cuid.into(),
            ops: ops
                .iter()
                .map(|&(r, s, x)| CollectionOp::from_wire(r, s, x).unwrap())
                .collect(),
        }
    }

    #[test]
    fn record_updates_create_and_report_changes() {
        let mut store = Store::new();
        let changes = store.apply_records(&[record_update("r1", &[("a", "1"), ("b", "2")])]);
        assert_eq!(store.value("r1", "a"), Some("1"));
        assert_eq!(changes.fields["r1"].len(), 2);

        let changes = store.apply_records(&[record_update("r1", &[("a", "1"), ("b", "3")])]);
        let fids: Vec<_> = changes.fields["r1"].iter().map(Fid::as_str).collect();
        assert_eq!(fids, ["b"]);

        let changes = store.apply_records(&[record_update("r1", &[("a", "1")])]);
        assert!(changes.is_empty());
    }

    #[test]
    fn layout_changes_are_reported() {
        let mut store = Store::new();
        let mut update = record_update("r1", &[]);
        update.layout = LayoutUpdate::Set("|Shortcut|:a:b".into());
        let changes = store.apply_records(&[update]);
        assert!(changes.layouts.contains("r1"));
        assert_eq!(store.record("r1").unwrap().layout(), Some("|Shortcut|:a:b"));
    }

    #[test]
    fn record_change_marks_containing_collections() {
        let mut store = Store::new();
        store.apply_collections(&[
            collection_update("c1", &[("r1", "last", "")]),
            collection_update("c2", &[("r2", "last", "")]),
        ]);
        let changes = store.apply_records(&[record_update("r1", &[("a", "1")])]);
        let cuids: Vec<_> = changes.collections.iter().map(Cuid::as_str).collect();
        assert_eq!(cuids, ["c1"]);
    }

    #[test]
    fn collection_errors_become_warnings_and_later_ops_apply() {
        let mut store = Store::new();
        let changes = store.apply_collections(&[collection_update(
            "c1",
            &[
                ("a", "last", ""),
                ("b", "after", "missing"),
                ("c", "last", ""),
            ],
        )]);
        assert_eq!(changes.warnings.len(), 1);
        assert!(matches!(
            &changes.warnings[0],
            StoreWarning::Collection { index: 1, error: CollectionError::UnknownReference(r), .. }
                if r.as_str() == "missing"
        ));
        assert_eq!(store.collection("c1").unwrap().to_string(), "a\nc\n");
    }

    #[test]
    fn attribute_changes_create_fields_and_report() {
        let mut store = Store::new();
        let change = AttributeChange {
            ruid: "r1".into(),
            fid: "a".into(),
            update: AttributeUpdate {
                permissions: Some(Permissions::ReadOnly),
                ..Default::default()
            },
        };
        let changes = store.apply_attributes(std::slice::from_ref(&change));
        assert!(changes.attributes["r1"].contains("a"));
        let field = store.record("r1").unwrap().field("a").unwrap();
        assert_eq!(field.attributes.permissions, Permissions::ReadOnly);
        assert_eq!(field.value, "");
        assert!(store.apply_attributes(&[change]).is_empty());
    }

    #[test]
    fn merge_combines_change_sets() {
        let mut store = Store::new();
        let mut all = store.apply_records(&[record_update("r1", &[("a", "1")])]);
        all.merge(store.apply_records(&[record_update("r1", &[("b", "1")])]));
        assert_eq!(all.fields["r1"].len(), 2);
    }
}
