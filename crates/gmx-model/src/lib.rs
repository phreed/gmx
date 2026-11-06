//! GMX data model.
//!
//! Holds the identifier newtypes (LUID, RUID, CUID, FID), records, fields,
//! attributes, collections and the store that applies updates. This crate
//! has no I/O, XML or UI dependencies.
//!
//! The semantics follow the legacy client at commit `073e595` (see the
//! `royale` branch). Deliberate differences are documented on the items
//! concerned, chiefly in [`collection`].

pub mod attributes;
pub mod collection;
pub mod ids;
pub mod record;
pub mod store;

pub use attributes::{
    ActionState, AttributeUpdate, Attributes, InvalidAttribute, Permissions, Send,
};
pub use collection::{Collection, CollectionError, CollectionOp, Select};
pub use ids::{Cuid, Fid, Luid, Ruid};
pub use record::{Field, LayoutUpdate, Record};
pub use store::{AttributeChange, ChangeSet, CollectionUpdate, RecordUpdate, Store, StoreWarning};
