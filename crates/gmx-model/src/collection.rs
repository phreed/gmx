//! Collections: ordered trees of records.
//!
//! A collection holds each RUID at most once. Its top level is an ordered
//! list of root nodes, and every node has an ordered list of children.
//! Lists and grids show the roots; tree grids show the whole tree.
//!
//! # Operations
//!
//! An `ISISCollection` message carries a list of operations. Each one names
//! a record (`ruid`), a selector (`select`) and an optional reference record
//! (`ref`).
//!
//! | `select` | without `ref`                   | with `ref`                                     |
//! |----------|---------------------------------|------------------------------------------------|
//! | `first`  | `ruid` becomes the first root   | `ruid` becomes the first sibling of `ref`      |
//! | `last`   | `ruid` becomes the last root    | `ruid` becomes the last sibling of `ref`       |
//! | `child`  | same as `last`                  | `ruid` becomes the last child of `ref`         |
//! | `before` | error                           | `ruid` is placed just before `ref`             |
//! | `after`  | error                           | `ruid` is placed just after `ref`              |
//! | `parent` | error                           | `ref` becomes the last child of `ruid`         |
//! | `clear`  | removes every node              | removes every descendant of `ref`              |
//! | `delete` | removes `ruid` and descendants  | removes `ref` and its descendants              |
//! | `splice` | error                           | removes `ref`, lifting its children into place |
//!
//! Placing a RUID that is already in the collection moves it, together with
//! its descendants. `clear`, `delete` and `splice` ignore `ruid` when `ref`
//! is given, as the legacy client did. `remove` is accepted as an alias of
//! `delete`, because `docs/protocol_reference.adoc` uses it. A selector of
//! the form `after:x` is read as `select="after" ref="x"`, for the same
//! reason.
//!
//! # Deliberate differences from the legacy client
//!
//! The semantics follow `Collection.processRuidList` and `RecordRef` in the
//! legacy client (commit `073e595`), with these corrections.
//!
//! * A `ref` that is not in the collection is an error. The legacy client
//!   created a detached node for it, which made later inserts relative to it
//!   silently invisible.
//! * `parent` with a `ruid` that is not yet in the collection puts `ruid` at
//!   the position `ref` held. The legacy client left `ruid` detached, so both
//!   records vanished from view.
//! * With an empty `ruid`, `clear` and `delete` act on `ref`. The legacy code
//!   had these two branches swapped, and the no-`ref` branch dereferenced an
//!   unset variable.
//! * `delete` without `ref` removes `ruid`. The legacy client rejected it;
//!   the Python reference server and the protocol reference accept it.
//! * Moves that would make a node its own ancestor are errors. The legacy
//!   client could build such cycles.

use std::collections::HashMap;
use std::fmt;

use crate::ids::Ruid;

/// The `select` value of a collection operation.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Select {
    /// First position.
    First,
    /// Last position.
    Last,
    /// Just before the reference.
    Before,
    /// Just after the reference.
    After,
    /// Last child of the reference.
    Child,
    /// Parent of the reference.
    Parent,
    /// Remove all descendants.
    Clear,
    /// Remove a node and its descendants.
    Delete,
    /// Remove a node, keeping its children.
    Splice,
}

impl Select {
    /// The canonical wire spelling.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::First => "first",
            Self::Last => "last",
            Self::Before => "before",
            Self::After => "after",
            Self::Child => "child",
            Self::Parent => "parent",
            Self::Clear => "clear",
            Self::Delete => "delete",
            Self::Splice => "splice",
        }
    }

    /// Parses a selector case-insensitively. `remove` means `delete`.
    pub fn parse(s: &str) -> Option<Self> {
        Some(match s.to_ascii_lowercase().as_str() {
            "first" => Self::First,
            "last" => Self::Last,
            "before" => Self::Before,
            "after" => Self::After,
            "child" => Self::Child,
            "parent" => Self::Parent,
            "clear" => Self::Clear,
            "delete" | "remove" => Self::Delete,
            "splice" => Self::Splice,
            _ => return None,
        })
    }
}

impl fmt::Display for Select {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// One collection operation.
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct CollectionOp {
    /// The record being placed or removed. `None` when sent empty.
    pub ruid: Option<Ruid>,
    /// What to do.
    pub select: Select,
    /// The reference record. `None` means the collection itself.
    pub reference: Option<Ruid>,
}

impl CollectionOp {
    /// Builds an operation from its three wire strings.
    ///
    /// Empty strings mean "absent". A selector such as `after:x` supplies
    /// the reference when `ref` is empty; an explicit `ref` takes precedence.
    pub fn from_wire(ruid: &str, select: &str, reference: &str) -> Result<Self, CollectionError> {
        let (select_str, reference) = match select.split_once(':') {
            Some((sel, embedded)) if reference.is_empty() => (sel, embedded),
            Some((sel, _)) => (sel, reference),
            None => (select, reference),
        };
        let select = Select::parse(select_str.trim())
            .ok_or_else(|| CollectionError::UnknownSelect(select.to_owned()))?;
        let non_empty = |s: &str| (!s.is_empty()).then(|| Ruid::from(s));
        Ok(Self {
            ruid: non_empty(ruid),
            select,
            reference: non_empty(reference),
        })
    }
}

/// Why a collection operation was rejected. The collection is unchanged.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CollectionError {
    /// `select` is not a known selector.
    UnknownSelect(String),
    /// The selector needs a `ruid`, and none was given.
    MissingRuid(Select),
    /// The selector needs a `ref`, and none was given.
    MissingReference(Select),
    /// `ref` names a record that is not in the collection.
    UnknownReference(Ruid),
    /// The record to delete is not in the collection.
    NotInCollection(Ruid),
    /// `ruid` and `ref` are the same record.
    SelfReference(Ruid),
    /// The move would make a record its own ancestor.
    Cycle {
        /// The record being moved.
        moving: Ruid,
        /// The record it would be placed under.
        under: Ruid,
    },
}

impl fmt::Display for CollectionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnknownSelect(s) => write!(
                f,
                "unknown select='{s}'; expected one of before, after, first, last, \
                 parent, child, clear, delete, splice"
            ),
            Self::MissingRuid(sel) => write!(f, "select='{sel}' requires a ruid"),
            Self::MissingReference(sel) => write!(f, "select='{sel}' requires a ref"),
            Self::UnknownReference(r) => write!(f, "ref='{r}' is not in the collection"),
            Self::NotInCollection(r) => write!(f, "ruid='{r}' is not in the collection"),
            Self::SelfReference(r) => write!(f, "ruid and ref are both '{r}'"),
            Self::Cycle { moving, under } => write!(
                f,
                "moving '{moving}' under '{under}' would make it its own ancestor"
            ),
        }
    }
}

impl std::error::Error for CollectionError {}

#[derive(Clone, Debug, Default, PartialEq, Eq)]
struct Node {
    parent: Option<Ruid>,
    children: Vec<Ruid>,
}

/// An ordered tree of RUIDs.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Collection {
    roots: Vec<Ruid>,
    nodes: HashMap<Ruid, Node>,
}

impl Collection {
    /// Creates an empty collection.
    pub fn new() -> Self {
        Self::default()
    }

    /// Number of records in the collection, at any depth.
    pub fn len(&self) -> usize {
        self.nodes.len()
    }

    /// Returns true when the collection holds no records.
    pub fn is_empty(&self) -> bool {
        self.nodes.is_empty()
    }

    /// Returns true when the record is anywhere in the collection.
    pub fn contains(&self, ruid: &str) -> bool {
        self.nodes.contains_key(ruid)
    }

    /// The top-level records, in order.
    pub fn roots(&self) -> &[Ruid] {
        &self.roots
    }

    /// The children of a record, in order. Empty if absent.
    pub fn children(&self, ruid: &str) -> &[Ruid] {
        self.nodes.get(ruid).map_or(&[], |n| n.children.as_slice())
    }

    /// The parent of a record. `None` for roots and absent records.
    pub fn parent(&self, ruid: &str) -> Option<&Ruid> {
        self.nodes.get(ruid).and_then(|n| n.parent.as_ref())
    }

    /// Visits every record depth first, yielding its depth and RUID.
    pub fn iter(&self) -> impl Iterator<Item = (usize, &Ruid)> {
        let mut stack: Vec<(usize, &Ruid)> = self.roots.iter().rev().map(|r| (0, r)).collect();
        std::iter::from_fn(move || {
            let (depth, ruid) = stack.pop()?;
            stack.extend(self.children(ruid).iter().rev().map(|c| (depth + 1, c)));
            Some((depth, ruid))
        })
    }

    /// Applies one operation. Returns whether the collection changed.
    ///
    /// On error the collection is left exactly as it was.
    pub fn apply(&mut self, op: &CollectionOp) -> Result<bool, CollectionError> {
        use Select::*;
        let sel = op.select;
        match (sel, &op.reference) {
            (Clear, None) => {
                let changed = !self.is_empty();
                self.roots.clear();
                self.nodes.clear();
                Ok(changed)
            }
            (Clear, Some(target)) => {
                self.require(target)?;
                let children = std::mem::take(&mut self.node_mut(target).children);
                for child in &children {
                    self.forget_subtree(child);
                }
                Ok(!children.is_empty())
            }
            (Delete, None) => {
                let ruid = op.ruid.as_ref().ok_or(CollectionError::MissingRuid(sel))?;
                if !self.contains(ruid) {
                    return Err(CollectionError::NotInCollection(ruid.clone()));
                }
                self.remove_subtree(ruid);
                Ok(true)
            }
            (Delete, Some(target)) => {
                self.require(target)?;
                self.remove_subtree(target);
                Ok(true)
            }
            (Splice, Some(target)) => {
                self.require(target)?;
                let parent = self.nodes[target].parent.clone();
                let index = self.detach(target);
                let children = self
                    .nodes
                    .remove(target)
                    .map(|n| n.children)
                    .unwrap_or_default();
                for child in &children {
                    self.node_mut(child).parent = parent.clone();
                }
                self.siblings_mut(&parent).splice(index..index, children);
                Ok(true)
            }
            (Splice | Before | After | Parent, None) => Err(CollectionError::MissingReference(sel)),
            (First | Last | Child, None) => {
                let ruid = op.ruid.as_ref().ok_or(CollectionError::MissingRuid(sel))?;
                let previous = self.take(ruid);
                let index = if sel == First { 0 } else { usize::MAX };
                let placed = self.attach(ruid, None, index);
                Ok(previous != Some(placed))
            }
            (First | Last | Before | After | Child, Some(target)) => {
                let ruid = op.ruid.as_ref().ok_or(CollectionError::MissingRuid(sel))?;
                self.require(target)?;
                if ruid == target {
                    return Err(CollectionError::SelfReference(ruid.clone()));
                }
                // The new parent is `target` for Child, otherwise its parent.
                let parent = match sel {
                    Child => Some(target.clone()),
                    _ => self.nodes[target].parent.clone(),
                };
                if let Some(under) = &parent {
                    if self.is_ancestor_or_self(ruid, under) {
                        return Err(CollectionError::Cycle {
                            moving: ruid.clone(),
                            under: under.clone(),
                        });
                    }
                }
                // Detach first so that the target's index is final.
                let previous = self.take(ruid);
                let index = match sel {
                    First => 0,
                    Last | Child => usize::MAX,
                    Before => self.index_of(target),
                    After => self.index_of(target) + 1,
                    _ => unreachable!(),
                };
                let placed = self.attach(ruid, parent, index);
                Ok(previous != Some(placed))
            }
            (Parent, Some(target)) => {
                let ruid = op.ruid.as_ref().ok_or(CollectionError::MissingRuid(sel))?;
                self.require(target)?;
                if ruid == target {
                    return Err(CollectionError::SelfReference(ruid.clone()));
                }
                if self.contains(ruid) {
                    if self.is_ancestor_or_self(target, ruid) {
                        return Err(CollectionError::Cycle {
                            moving: target.clone(),
                            under: ruid.clone(),
                        });
                    }
                    let previous = self.take(target);
                    let placed = self.attach(target, Some(ruid.clone()), usize::MAX);
                    Ok(previous != Some(placed))
                } else {
                    // The new record takes the target's place, then adopts it.
                    let (parent, index) = self.take(target).expect("target is present");
                    self.attach(ruid, parent, index);
                    self.attach(target, Some(ruid.clone()), usize::MAX);
                    Ok(true)
                }
            }
        }
    }

    fn require(&self, ruid: &Ruid) -> Result<(), CollectionError> {
        if self.contains(ruid) {
            Ok(())
        } else {
            Err(CollectionError::UnknownReference(ruid.clone()))
        }
    }

    fn node_mut(&mut self, ruid: &Ruid) -> &mut Node {
        self.nodes.get_mut(ruid).expect("node is in the collection")
    }

    fn siblings_mut(&mut self, parent: &Option<Ruid>) -> &mut Vec<Ruid> {
        match parent {
            None => &mut self.roots,
            Some(p) => &mut self.node_mut(p).children,
        }
    }

    fn siblings(&self, parent: &Option<Ruid>) -> &[Ruid] {
        match parent {
            None => &self.roots,
            Some(p) => self.children(p),
        }
    }

    fn index_of(&self, ruid: &Ruid) -> usize {
        let parent = &self.nodes[ruid].parent;
        self.siblings(parent)
            .iter()
            .position(|r| r == ruid)
            .expect("node is listed by its parent")
    }

    /// True when `ancestor` is `node` or one of its ancestors.
    fn is_ancestor_or_self(&self, ancestor: &Ruid, node: &Ruid) -> bool {
        let mut current = Some(node);
        while let Some(n) = current {
            if n == ancestor {
                return true;
            }
            current = self.parent(n);
        }
        false
    }

    /// Unlinks a node from its parent's list, keeping its subtree.
    /// Returns the index it held.
    fn detach(&mut self, ruid: &Ruid) -> usize {
        let index = self.index_of(ruid);
        let parent = self.nodes[ruid].parent.clone();
        self.siblings_mut(&parent).remove(index);
        self.node_mut(ruid).parent = None;
        index
    }

    /// Detaches a node if present, keeping its subtree.
    /// Returns the position it held, for change detection.
    fn take(&mut self, ruid: &Ruid) -> Option<(Option<Ruid>, usize)> {
        if !self.contains(ruid) {
            return None;
        }
        let parent = self.nodes[ruid].parent.clone();
        Some((parent, self.detach(ruid)))
    }

    /// Links a new or detached node into place. `index` is clamped.
    /// Returns the position it now holds.
    fn attach(&mut self, ruid: &Ruid, parent: Option<Ruid>, index: usize) -> (Option<Ruid>, usize) {
        let siblings = self.siblings_mut(&parent);
        let index = index.min(siblings.len());
        siblings.insert(index, ruid.clone());
        self.nodes.entry(ruid.clone()).or_default().parent = parent.clone();
        (parent, index)
    }

    fn remove_subtree(&mut self, ruid: &Ruid) {
        self.detach(ruid);
        self.forget_subtree(ruid);
    }

    /// Drops a node and its descendants from the node map.
    fn forget_subtree(&mut self, ruid: &Ruid) {
        let mut stack = vec![ruid.clone()];
        while let Some(r) = stack.pop() {
            if let Some(node) = self.nodes.remove(&r) {
                stack.extend(node.children);
            }
        }
    }

    /// Checks the tree's structural invariants.
    ///
    /// Every node is listed exactly once by its parent (or by the roots),
    /// parent links agree with child lists, and there are no cycles.
    pub fn check_invariants(&self) -> Result<(), String> {
        let mut seen = HashMap::new();
        let mut stack: Vec<(Option<&Ruid>, &Ruid)> = self.roots.iter().map(|r| (None, r)).collect();
        while let Some((parent, ruid)) = stack.pop() {
            if seen.insert(ruid, ()).is_some() {
                return Err(format!("'{ruid}' is listed more than once or in a cycle"));
            }
            let node = self
                .nodes
                .get(ruid)
                .ok_or_else(|| format!("'{ruid}' is listed but has no node"))?;
            if node.parent.as_ref() != parent {
                return Err(format!(
                    "'{ruid}' has parent {:?} but is listed under {parent:?}",
                    node.parent
                ));
            }
            stack.extend(node.children.iter().map(|c| (Some(ruid), c)));
        }
        if seen.len() != self.nodes.len() {
            return Err(format!(
                "{} nodes are unreachable",
                self.nodes.len() - seen.len()
            ));
        }
        Ok(())
    }
}

impl fmt::Display for Collection {
    /// Renders the tree with two spaces of indent per level.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for (depth, ruid) in self.iter() {
            writeln!(f, "{:indent$}{ruid}", "", indent = depth * 2)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn op(ruid: &str, select: &str, reference: &str) -> CollectionOp {
        CollectionOp::from_wire(ruid, select, reference).unwrap()
    }

    fn run(ops: &[(&str, &str, &str)]) -> Collection {
        let mut c = Collection::new();
        for &(r, s, x) in ops {
            c.apply(&op(r, s, x))
                .unwrap_or_else(|e| panic!("{r} {s} {x}: {e}"));
        }
        c
    }

    fn tree(c: &Collection) -> String {
        c.to_string()
    }

    fn apply_err(c: &mut Collection, r: &str, s: &str, x: &str) -> CollectionError {
        let before = c.clone();
        let err = c.apply(&op(r, s, x)).unwrap_err();
        assert_eq!(*c, before, "a failed op must not change the collection");
        err
    }

    #[test]
    fn wire_parsing() {
        assert_eq!(
            op("a", "AFTER", ""),
            CollectionOp {
                ruid: Some("a".into()),
                select: Select::After,
                reference: None
            }
        );
        assert_eq!(op("a", "after:b", "").reference, Some("b".into()));
        assert_eq!(op("a", "after:b", "c").select, Select::After);
        assert_eq!(op("", "remove", "").select, Select::Delete);
        assert_eq!(op("", "clear", "").ruid, None);
        assert_eq!(
            CollectionOp::from_wire("a", "sideways", ""),
            Err(CollectionError::UnknownSelect("sideways".into()))
        );
    }

    #[test]
    fn first_and_last_at_top_level() {
        let c = run(&[("a", "last", ""), ("b", "last", ""), ("c", "first", "")]);
        assert_eq!(tree(&c), "c\na\nb\n");
    }

    #[test]
    fn child_without_ref_appends() {
        let c = run(&[("a", "child", ""), ("b", "child", "")]);
        assert_eq!(tree(&c), "a\nb\n");
    }

    #[test]
    fn placing_an_existing_record_moves_it() {
        let mut c = run(&[("a", "last", ""), ("b", "last", ""), ("c", "last", "")]);
        assert!(c.apply(&op("a", "last", "")).unwrap());
        assert_eq!(tree(&c), "b\nc\na\n");
        assert!(!c.apply(&op("a", "last", "")).unwrap(), "no-op move");
        assert_eq!(c.len(), 3);
    }

    #[test]
    fn before_and_after() {
        let c = run(&[
            ("a", "last", ""),
            ("c", "last", ""),
            ("b", "before", "c"),
            ("d", "after", "c"),
            ("z", "after", "a"),
        ]);
        assert_eq!(tree(&c), "a\nz\nb\nc\nd\n");
    }

    #[test]
    fn before_and_after_move_earlier_siblings_correctly() {
        // Moving an earlier sibling must account for the gap it leaves,
        // the case the legacy `newRecRefIsAnEarlierSibling` flag handled.
        let mut c = run(&[("a", "last", ""), ("b", "last", ""), ("c", "last", "")]);
        c.apply(&op("a", "after", "b")).unwrap();
        assert_eq!(tree(&c), "b\na\nc\n");
        c.apply(&op("b", "before", "c")).unwrap();
        assert_eq!(tree(&c), "a\nb\nc\n");
    }

    #[test]
    fn first_and_last_with_ref_are_sibling_relative() {
        let c = run(&[
            ("p", "last", ""),
            ("x", "child", "p"),
            ("y", "last", "x"),
            ("w", "first", "y"),
        ]);
        assert_eq!(tree(&c), "p\n  w\n  x\n  y\n");
    }

    #[test]
    fn child_with_ref() {
        let c = run(&[("a", "last", ""), ("b", "child", "a"), ("c", "child", "a")]);
        assert_eq!(tree(&c), "a\n  b\n  c\n");
        assert_eq!(c.parent("b"), Some(&"a".into()));
        assert_eq!(c.children("a"), ["b".into(), "c".into()]);
    }

    #[test]
    fn ux_guide_example_builds_expected_tree() {
        // examples/collections/basic_collection_message.xml
        let c = run(&[
            ("r1", "child", ""),
            ("r2", "last", "r1"),
            ("r1-1", "child", "r1"),
            ("r1-2", "last", "r1-1"),
        ]);
        assert_eq!(tree(&c), "r1\n  r1-1\n  r1-2\nr2\n");
    }

    #[test]
    fn parent_with_new_ruid_takes_refs_place() {
        let c = run(&[
            ("a", "last", ""),
            ("b", "last", ""),
            ("c", "last", ""),
            ("p", "parent", "b"),
        ]);
        assert_eq!(tree(&c), "a\np\n  b\nc\n");
    }

    #[test]
    fn parent_with_existing_ruid_adopts_ref() {
        let c = run(&[("a", "last", ""), ("b", "last", ""), ("a", "parent", "b")]);
        assert_eq!(tree(&c), "a\n  b\n");
    }

    #[test]
    fn clear_whole_collection_and_subtree() {
        let mut c = run(&[
            ("a", "last", ""),
            ("a1", "child", "a"),
            ("a2", "child", "a1"),
            ("b", "last", ""),
        ]);
        assert!(c.apply(&op("", "clear", "a")).unwrap());
        assert_eq!(tree(&c), "a\nb\n");
        assert!(!c.contains("a2"));
        assert!(!c.apply(&op("", "clear", "a")).unwrap());
        // A ruid is ignored when clearing, as in the legacy client.
        assert!(c.apply(&op("ignored", "clear", "")).unwrap());
        assert!(c.is_empty());
        assert!(!c.apply(&op("", "clear", "")).unwrap());
    }

    #[test]
    fn delete_by_ref_or_by_ruid() {
        let mut c = run(&[
            ("a", "last", ""),
            ("a1", "child", "a"),
            ("b", "last", ""),
            ("c", "last", ""),
        ]);
        c.apply(&op("", "delete", "a")).unwrap();
        assert_eq!(tree(&c), "b\nc\n");
        assert!(!c.contains("a1"));
        c.apply(&op("c", "delete", "")).unwrap();
        assert_eq!(tree(&c), "b\n");
        // With a ref, the ref is deleted and the ruid ignored.
        c.apply(&op("zzz", "delete", "b")).unwrap();
        assert!(c.is_empty());
    }

    #[test]
    fn splice_lifts_children_into_place() {
        let mut c = run(&[
            ("a", "last", ""),
            ("b", "last", ""),
            ("b1", "child", "b"),
            ("b2", "child", "b"),
            ("c", "last", ""),
        ]);
        c.apply(&op("", "splice", "b")).unwrap();
        assert_eq!(tree(&c), "a\nb1\nb2\nc\n");
        assert_eq!(c.parent("b1"), None);
    }

    #[test]
    fn errors_leave_collection_unchanged() {
        let mut c = run(&[("a", "last", ""), ("a1", "child", "a")]);
        for sel in ["before", "after", "parent", "splice"] {
            assert_eq!(
                apply_err(&mut c, "x", sel, ""),
                CollectionError::MissingReference(Select::parse(sel).unwrap())
            );
        }
        assert_eq!(
            apply_err(&mut c, "", "last", ""),
            CollectionError::MissingRuid(Select::Last)
        );
        assert_eq!(
            apply_err(&mut c, "", "after", "a"),
            CollectionError::MissingRuid(Select::After)
        );
        assert_eq!(
            apply_err(&mut c, "", "delete", ""),
            CollectionError::MissingRuid(Select::Delete)
        );
        assert_eq!(
            apply_err(&mut c, "x", "after", "nope"),
            CollectionError::UnknownReference("nope".into())
        );
        assert_eq!(
            apply_err(&mut c, "nope", "delete", ""),
            CollectionError::NotInCollection("nope".into())
        );
        assert_eq!(
            apply_err(&mut c, "a", "child", "a"),
            CollectionError::SelfReference("a".into())
        );
        assert_eq!(
            apply_err(&mut c, "a", "child", "a1"),
            CollectionError::Cycle {
                moving: "a".into(),
                under: "a1".into()
            }
        );
        assert_eq!(
            apply_err(&mut c, "a", "after", "a1"),
            CollectionError::Cycle {
                moving: "a".into(),
                under: "a".into()
            }
        );
        assert_eq!(
            apply_err(&mut c, "a1", "parent", "a"),
            CollectionError::Cycle {
                moving: "a".into(),
                under: "a1".into()
            }
        );
    }

    #[test]
    fn iter_is_depth_first() {
        let c = run(&[
            ("a", "last", ""),
            ("a1", "child", "a"),
            ("a1x", "child", "a1"),
            ("a2", "child", "a"),
            ("b", "last", ""),
        ]);
        let order: Vec<_> = c.iter().map(|(d, r)| (d, r.as_str())).collect();
        assert_eq!(
            order,
            [(0, "a"), (1, "a1"), (2, "a1x"), (1, "a2"), (0, "b")]
        );
    }

    mod properties {
        use super::*;
        use proptest::prelude::*;

        const SELECTS: [&str; 9] = [
            "first", "last", "before", "after", "child", "parent", "clear", "delete", "splice",
        ];

        fn arb_op() -> impl Strategy<Value = (String, &'static str, String)> {
            // A small alphabet makes references and moves collide often.
            let id = prop_oneof![Just(String::new()), "[a-e]"];
            (id.clone(), prop::sample::select(&SELECTS[..]), id)
        }

        proptest! {
            #[test]
            fn random_ops_keep_the_tree_valid(ops in prop::collection::vec(arb_op(), 0..60)) {
                let mut c = Collection::new();
                for (r, s, x) in &ops {
                    let before = c.clone();
                    let op = CollectionOp::from_wire(r, s, x).unwrap();
                    match c.apply(&op) {
                        Ok(changed) => prop_assert_eq!(changed, c != before),
                        Err(_) => prop_assert_eq!(&c, &before),
                    }
                    prop_assert_eq!(c.check_invariants(), Ok(()));
                    prop_assert_eq!(c.iter().count(), c.len());
                }
            }
        }
    }
}
