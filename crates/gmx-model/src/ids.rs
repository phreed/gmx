//! Identifier newtypes.
//!
//! GMX names everything with strings: layouts (LUID), records (RUID),
//! collections (CUID) and fields within a record (FID). Distinct types stop
//! one kind of identifier being passed where another is expected.

use std::borrow::Borrow;
use std::fmt;
use std::ops::Deref;
use std::sync::Arc;

macro_rules! id_type {
    ($(#[$doc:meta])* $name:ident) => {
        $(#[$doc])*
        ///
        /// Cloning is cheap: the string is reference counted.
        #[derive(Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
        pub struct $name(Arc<str>);

        impl $name {
            /// Creates an identifier from any string.
            pub fn new(id: impl Into<Arc<str>>) -> Self {
                Self(id.into())
            }

            /// Returns the identifier as a string slice.
            pub fn as_str(&self) -> &str {
                &self.0
            }
        }

        impl fmt::Display for $name {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.write_str(&self.0)
            }
        }

        impl fmt::Debug for $name {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                write!(f, concat!(stringify!($name), "({:?})"), &*self.0)
            }
        }

        impl From<&str> for $name {
            fn from(id: &str) -> Self {
                Self::new(id)
            }
        }

        impl From<String> for $name {
            fn from(id: String) -> Self {
                Self::new(id)
            }
        }

        // Lets maps keyed by this type be queried with `&str`. Sound because
        // the derived `Hash` and `Eq` delegate to the inner `str`.
        impl Borrow<str> for $name {
            fn borrow(&self) -> &str {
                &self.0
            }
        }

        impl AsRef<str> for $name {
            fn as_ref(&self) -> &str {
                &self.0
            }
        }

        // Lets `&Ruid` and friends coerce to `&str` at lookup sites.
        impl Deref for $name {
            type Target = str;

            fn deref(&self) -> &str {
                &self.0
            }
        }
    };
}

id_type! {
    /// Layout unique identifier: names a node in the layout tree.
    Luid
}
id_type! {
    /// Record unique identifier: names a record in the store.
    Ruid
}
id_type! {
    /// Collection unique identifier: names an ordered tree of records.
    Cuid
}
id_type! {
    /// Field identifier: names a field, unique only within its record.
    Fid
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn map_lookup_by_str() {
        let mut map = HashMap::new();
        map.insert(Ruid::from("r1"), 1);
        assert_eq!(map.get("r1"), Some(&1));
        assert_eq!(map.get("r2"), None);
    }

    #[test]
    fn display_and_debug() {
        let id = Cuid::from("alerts_list");
        assert_eq!(id.to_string(), "alerts_list");
        assert_eq!(format!("{id:?}"), "Cuid(\"alerts_list\")");
    }
}
