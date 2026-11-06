//! Applying messages to a [`Store`].
//!
//! This is where wire strings are validated. Problems become warnings in
//! the returned [`ChangeSet`], and the rest of the message still applies,
//! as in the legacy client.

use std::str::FromStr;

use gmx_model::{
    AttributeChange, AttributeUpdate, ChangeSet, CollectionOp, CollectionUpdate, Fid,
    InvalidAttribute, LayoutUpdate, RecordUpdate, Ruid, Store, StoreWarning,
};

use crate::message::{Message, WireAttribute, WireCollection, WireRecord};

/// Applies a data message to the store and reports what changed.
///
/// `ISISRecord`, `ISISDataEdit`, `ISISCollection` and `ISISAttributes`
/// change the store. Every other message returns an empty change set.
///
/// A data edit is applied like a record update. That is what a service
/// does on receiving one; the client never receives them.
pub fn apply(store: &mut Store, message: &Message) -> ChangeSet {
    match message {
        Message::Record(records) | Message::DataEdit(records) => apply_records(store, records),
        Message::Collection(collections) => apply_collections(store, collections),
        Message::Attributes(attributes) => apply_attributes(store, attributes),
        _ => ChangeSet::default(),
    }
}

fn apply_records(store: &mut Store, records: &[WireRecord]) -> ChangeSet {
    let mut warnings = Vec::new();
    let mut updates = Vec::new();
    let mut attributes = Vec::new();
    for record in records {
        if record.ruid.is_empty() {
            warnings.push(StoreWarning::MissingId(
                "ISISRecord record has an empty ruid",
            ));
            continue;
        }
        let ruid = Ruid::from(record.ruid.as_str());
        let mut fields = Vec::new();
        for field in &record.fields {
            if field.fid.is_empty() {
                warnings.push(StoreWarning::MissingId("ISISRecord field has an empty fid"));
                continue;
            }
            let fid = Fid::from(field.fid.as_str());
            if let Some(send) = &field.send {
                if let Some(send) = parse(&ruid, &fid, send, &mut warnings) {
                    attributes.push(AttributeChange {
                        ruid: ruid.clone(),
                        fid: fid.clone(),
                        update: AttributeUpdate {
                            send: Some(send),
                            ..Default::default()
                        },
                    });
                }
            }
            fields.push((fid, field.value.clone()));
        }
        if record.ignored_attributes > 0 {
            warnings.push(StoreWarning::Unsupported {
                ruid: ruid.clone(),
                message: "Attribute elements inside ISISRecord are not part of the GMX \
                          protocol and were ignored; use ISISAttributes to set field attributes",
            });
        }
        updates.push(RecordUpdate {
            ruid,
            layout: LayoutUpdate::from_wire(record.layout.as_deref()),
            fields,
        });
    }
    let mut changes = store.apply_records(&updates);
    changes.merge(store.apply_attributes(&attributes));
    changes.warnings.splice(0..0, warnings);
    changes
}

fn apply_collections(store: &mut Store, collections: &[WireCollection]) -> ChangeSet {
    let mut changes = ChangeSet::default();
    for collection in collections {
        if collection.cuid.is_empty() {
            changes
                .warnings
                .push(StoreWarning::MissingId("ISISCollection has an empty cuid"));
            continue;
        }
        let cuid = gmx_model::Cuid::from(collection.cuid.as_str());
        // Keep each op's index in the message, so warnings point at it.
        let mut ops = Vec::new();
        let mut positions = Vec::new();
        let mut warnings = Vec::new();
        for (index, wire) in collection.ruids.iter().enumerate() {
            match CollectionOp::from_wire(&wire.ruid, &wire.select, &wire.reference) {
                Ok(op) => {
                    ops.push(op);
                    positions.push(index);
                }
                Err(error) => warnings.push(StoreWarning::Collection {
                    cuid: cuid.clone(),
                    index,
                    error,
                }),
            }
        }
        let mut applied = store.apply_collections(&[CollectionUpdate {
            cuid: cuid.clone(),
            ops,
        }]);
        for mut warning in applied.warnings.drain(..) {
            if let StoreWarning::Collection { index, .. } = &mut warning {
                *index = positions[*index];
            }
            warnings.push(warning);
        }
        warnings.sort_by_key(|w| match w {
            StoreWarning::Collection { index, .. } => *index,
            _ => 0,
        });
        changes.merge(applied);
        changes.warnings.extend(warnings);
    }
    changes
}

fn apply_attributes(store: &mut Store, attributes: &[WireAttribute]) -> ChangeSet {
    let mut warnings = Vec::new();
    let mut changes = Vec::new();
    for attribute in attributes {
        if attribute.ruid.is_empty() || attribute.fid.is_empty() {
            warnings.push(StoreWarning::MissingId(
                "ISISAttributes attribute has an empty ruid or fid",
            ));
            continue;
        }
        let ruid = Ruid::from(attribute.ruid.as_str());
        let fid = Fid::from(attribute.fid.as_str());
        let update = AttributeUpdate {
            send: attribute
                .send
                .as_deref()
                .and_then(|s| parse(&ruid, &fid, s, &mut warnings)),
            permissions: attribute
                .permissions
                .as_deref()
                .and_then(|s| parse(&ruid, &fid, s, &mut warnings)),
            action_state: attribute
                .action_state
                .as_deref()
                .and_then(|s| parse(&ruid, &fid, s, &mut warnings)),
        };
        if !update.is_empty() {
            changes.push(AttributeChange { ruid, fid, update });
        }
    }
    let mut applied = store.apply_attributes(&changes);
    applied.warnings.splice(0..0, warnings);
    applied
}

fn parse<T: FromStr<Err = InvalidAttribute>>(
    ruid: &Ruid,
    fid: &Fid,
    value: &str,
    warnings: &mut Vec<StoreWarning>,
) -> Option<T> {
    value
        .parse()
        .map_err(|error| {
            warnings.push(StoreWarning::InvalidAttribute {
                ruid: ruid.clone(),
                fid: fid.clone(),
                error,
            });
        })
        .ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::message::{WireField, WireRuid};
    use gmx_model::{ActionState, CollectionError, Permissions, Send};

    fn field(fid: &str, value: &str, send: Option<&str>) -> WireField {
        WireField {
            fid: fid.into(),
            value: value.into(),
            send: send.map(Into::into),
        }
    }

    #[test]
    fn records_apply_values_layout_and_send() {
        let mut store = Store::new();
        let msg = Message::Record(vec![WireRecord {
            ruid: "r".into(),
            layout: Some("|Shortcut|:a".into()),
            fields: vec![field("a", "1", None), field("b", "2", Some("never"))],
            ignored_attributes: 0,
        }]);
        let changes = apply(&mut store, &msg);
        assert!(changes.warnings.is_empty(), "{:?}", changes.warnings);
        let record = store.record("r").unwrap();
        assert_eq!(record.value("a"), Some("1"));
        assert_eq!(record.layout(), Some("|Shortcut|:a"));
        assert_eq!(record.field("b").unwrap().attributes.send, Send::Never);
        assert!(changes.attributes["r"].contains("b"));
    }

    #[test]
    fn ignored_attribute_elements_warn_and_values_still_apply() {
        let mut store = Store::new();
        let msg = Message::Record(vec![WireRecord {
            ruid: "r".into(),
            fields: vec![field("a", "1", None)],
            ignored_attributes: 3,
            ..Default::default()
        }]);
        let changes = apply(&mut store, &msg);
        assert!(matches!(
            changes.warnings.as_slice(),
            [StoreWarning::Unsupported { ruid, .. }] if ruid.as_str() == "r"
        ));
        assert!(
            changes.warnings[0]
                .to_string()
                .contains("use ISISAttributes")
        );
        assert_eq!(store.value("r", "a"), Some("1"));
        assert_eq!(store.records().count(), 1, "no other records are created");
    }

    #[test]
    fn records_with_empty_ids_are_skipped_with_warnings() {
        let mut store = Store::new();
        let msg = Message::Record(vec![
            WireRecord {
                ruid: String::new(),
                fields: vec![field("a", "1", None)],
                ..Default::default()
            },
            WireRecord {
                ruid: "r".into(),
                fields: vec![field("", "1", None), field("b", "2", Some("bogus"))],
                ..Default::default()
            },
        ]);
        let changes = apply(&mut store, &msg);
        assert_eq!(changes.warnings.len(), 3, "{:?}", changes.warnings);
        assert_eq!(
            store.value("r", "b"),
            Some("2"),
            "value applies despite bad send"
        );
        assert_eq!(store.records().count(), 1);
    }

    #[test]
    fn collection_warnings_point_at_message_positions() {
        let mut store = Store::new();
        let ruid = |r: &str, s: &str, x: &str| WireRuid {
            ruid: r.into(),
            select: s.into(),
            reference: x.into(),
        };
        let msg = Message::Collection(vec![
            WireCollection {
                cuid: "c".into(),
                ruids: vec![
                    ruid("a", "sideways", ""),
                    ruid("a", "last", ""),
                    ruid("b", "after", "missing"),
                    ruid("b", "after", "a"),
                ],
            },
            WireCollection::default(),
        ]);
        let changes = apply(&mut store, &msg);
        let summary: Vec<_> = changes
            .warnings
            .iter()
            .map(|w| match w {
                StoreWarning::Collection { index, error, .. } => {
                    (Some(*index), Some(error.clone()))
                }
                _ => (None, None),
            })
            .collect();
        assert_eq!(
            summary,
            [
                (
                    Some(0),
                    Some(CollectionError::UnknownSelect("sideways".into()))
                ),
                (
                    Some(2),
                    Some(CollectionError::UnknownReference("missing".into()))
                ),
                (None, None),
            ]
        );
        assert_eq!(store.collection("c").unwrap().to_string(), "a\nb\n");
    }

    #[test]
    fn attributes_apply_independently() {
        let mut store = Store::new();
        let msg = Message::Attributes(vec![
            WireAttribute {
                ruid: "r".into(),
                fid: "f".into(),
                send: Some("Changed".into()),
                action_state: Some("bogus".into()),
                permissions: Some("READONLY".into()),
            },
            WireAttribute {
                ruid: "r".into(),
                fid: String::new(),
                send: Some("never".into()),
                ..Default::default()
            },
            WireAttribute {
                ruid: "r".into(),
                fid: "g".into(),
                action_state: Some("active".into()),
                ..Default::default()
            },
        ]);
        let changes = apply(&mut store, &msg);
        assert_eq!(changes.warnings.len(), 2, "{:?}", changes.warnings);
        let attrs = store.record("r").unwrap().field("f").unwrap().attributes;
        assert_eq!(attrs.send, Send::Changed);
        assert_eq!(attrs.permissions, Permissions::ReadOnly);
        assert_eq!(attrs.action_state, ActionState::Ok);
        let g = store.record("r").unwrap().field("g").unwrap().attributes;
        assert_eq!(g.action_state, ActionState::Active);
    }

    #[test]
    fn other_messages_change_nothing() {
        let mut store = Store::new();
        let msg = Message::Refresh(Default::default());
        assert!(apply(&mut store, &msg).is_empty());
    }
}
