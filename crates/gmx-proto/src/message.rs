//! GMX messages and their two XML dialects.
//!
//! # Dialects
//!
//! *Invoke* is the legacy RPC envelope. The legacy client reads it by
//! local name and writes it without namespaces:
//!
//! ```xml
//! <invoke fn="ISISRecord"><args><arg><RecordList>
//!   <Record><ruid>r1</ruid><fieldList>
//!     <Field><fid>a</fid><value>1</value></Field>
//!   </fieldList></Record>
//! </RecordList></arg></args></invoke>
//! ```
//!
//! *Bare* is the attribute form used by the Python reference servers and
//! most of `examples/`:
//!
//! ```xml
//! <ISISRecord ruid="r1"><Field fid="a" value="1"/></ISISRecord>
//! ```
//!
//! Both are always accepted. The encoder writes the one it is asked for.
//! The invoke encoder writes what the legacy client writes, so legacy peers
//! can read it; namespaced input such as `fn:invoke` decodes the same way.
//!
//! # Fidelity
//!
//! Message payloads keep the wire strings, so a message decoded from one
//! dialect and re-encoded in it decodes to an equal message. Conversion to
//! store updates, where strings are validated, is done separately by
//! [`crate::apply()`].
//!
//! The bare dialect's `send` attribute on `Field` is carried through invoke
//! as a `<send>` child element, which the legacy client ignores.
//!
//! `Attribute` elements inside a record are not part of the protocol. They
//! are counted, so that [`crate::apply()`] can warn, and otherwise dropped.
//! Field attributes are set with `ISISAttributes`.
//!
//! The bare dialect has no data-edit message; the Python servers expect
//! client edits as `ISISRecord`. A [`Message::DataEdit`] therefore encodes
//! to bare `ISISRecord` and decodes back as [`Message::Record`]. Bare
//! records and collections also carry one item per message, so encoding a
//! list produces one frame per item.

use std::fmt;

use gmx_model::Luid;

use crate::command::{Command, UnknownCommand};
use crate::xml::{self, Element, XmlError};

/// The XML form to encode messages in.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub enum Dialect {
    /// The legacy `<invoke fn="...">` envelope.
    #[default]
    Invoke,
    /// Bare `ISIS*` root elements with attributes, as the Python servers use.
    Bare,
}

/// One field of a record, as sent.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct WireField {
    /// Field identifier.
    pub fid: String,
    /// Field value. An absent value is sent and read as empty.
    pub value: String,
    /// Optional `send` attribute (bare dialect extension).
    pub send: Option<String>,
}

/// One attribute change, as sent.
///
/// Empty attribute strings are read as absent, as in the legacy client.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct WireAttribute {
    /// Record identifier.
    pub ruid: String,
    /// Field identifier.
    pub fid: String,
    /// `always`, `changed` or `never`.
    pub send: Option<String>,
    /// `waiting`, `failed`, `ok` or `active`.
    pub action_state: Option<String>,
    /// `readOnly`, `disabled` or `readWrite`.
    pub permissions: Option<String>,
}

/// One record, as sent in `ISISRecord` or `ISISDataEdit`.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct WireRecord {
    /// Record identifier.
    pub ruid: String,
    /// Layout Manager command, if the element or attribute was present.
    pub layout: Option<String>,
    /// Field values, in order.
    pub fields: Vec<WireField>,
    /// How many `Attribute` elements the record held.
    ///
    /// Earlier GMX documentation showed `Attribute` inside `ISISRecord` as
    /// a cross-record reference, but no implementation ever gave it a
    /// meaning. It is not part of the protocol, so the elements are dropped.
    /// The count lets [`crate::apply()`] warn. It is never encoded.
    pub ignored_attributes: usize,
}

/// One collection operation, as sent. Empty strings mean absent.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct WireRuid {
    /// The record to place or remove.
    pub ruid: String,
    /// The selector, such as `after` or `after:x`.
    pub select: String,
    /// The reference record.
    pub reference: String,
}

/// One collection, as sent in `ISISCollection`.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct WireCollection {
    /// Collection identifier.
    pub cuid: String,
    /// Operations, in order.
    pub ruids: Vec<WireRuid>,
}

/// An `ISISLayout` message: a layout tree to show at a LUID.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Layout {
    /// The `luid` of a bare `ISISLayout` wrapper, if one was sent.
    pub target: Option<Luid>,
    /// The layout tree.
    pub root: Element,
}

impl Layout {
    /// Creates a layout message with no separate target.
    pub fn new(root: Element) -> Self {
        Self { target: None, root }
    }

    /// The LUID the layout replaces.
    ///
    /// The root's own `luid` wins, as in the legacy client. The wrapper's
    /// `luid` is used when the root has none, as the Python layout server
    /// expects.
    pub fn luid(&self) -> Option<Luid> {
        self.root
            .attr("luid")
            .map(Luid::from)
            .or_else(|| self.target.clone())
    }

    /// The command text when the root is a `<Command>` element.
    ///
    /// The legacy client passed such layouts to its control channel instead
    /// of rendering them.
    pub fn command(&self) -> Option<String> {
        self.root
            .local_name()
            .eq_ignore_ascii_case("command")
            .then(|| self.root.text())
    }

    /// The root with `target` filled in as its `luid` when it has none.
    fn root_with_luid(&self) -> Element {
        let mut root = self.root.clone();
        if root.attr("luid").is_none() {
            if let Some(target) = &self.target {
                root.attributes.push(("luid".into(), target.to_string()));
            }
        }
        root
    }
}

/// An `ISISRefresh` message.
///
/// The legacy client sends one with an empty command when it connects.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Refresh {
    /// The command, such as `reset`. Bare dialect: the `action` attribute.
    pub command: String,
}

/// Any message that can travel in one frame, or one decoded item of an
/// example file.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Message {
    /// `ISISLayout`: show a layout tree.
    Layout(Layout),
    /// `ISISRecord`: create or update records.
    Record(Vec<WireRecord>),
    /// `ISISDataEdit`: user edits, from client to service.
    DataEdit(Vec<WireRecord>),
    /// `ISISCollection`: change collections.
    Collection(Vec<WireCollection>),
    /// `ISISAttributes`: change field attributes.
    Attributes(Vec<WireAttribute>),
    /// `ISISRefresh`: ask for the current layout and data.
    Refresh(Refresh),
    /// A plain-text debug command or reply.
    Command(Command),
    /// Any other XML, kept unchanged. Includes Layout Manager calls such as
    /// `set_ISISFormLayout`, and bare layout files.
    Other(Element),
}

/// Why a frame could not be decoded.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum DecodeError {
    /// The frame was empty or only whitespace.
    Empty,
    /// The frame was not valid UTF-8.
    NotUtf8,
    /// The frame was not well-formed XML.
    Xml(XmlError),
    /// The frame held more than one root element.
    MultipleRoots(usize),
    /// The frame was text but not a known command.
    Command(UnknownCommand),
    /// The XML was well formed but not a valid message.
    Malformed(String),
}

impl fmt::Display for DecodeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Empty => f.write_str("empty frame"),
            Self::NotUtf8 => f.write_str("frame is not valid UTF-8"),
            Self::Xml(e) => write!(f, "malformed XML: {e}"),
            Self::MultipleRoots(n) => write!(f, "frame holds {n} root elements, expected 1"),
            Self::Command(e) => e.fmt(f),
            Self::Malformed(m) => f.write_str(m),
        }
    }
}

impl std::error::Error for DecodeError {}

impl From<XmlError> for DecodeError {
    fn from(e: XmlError) -> Self {
        Self::Xml(e)
    }
}

fn malformed(message: impl Into<String>) -> DecodeError {
    DecodeError::Malformed(message.into())
}

fn non_empty(s: Option<String>) -> Option<String> {
    s.filter(|s| !s.is_empty())
}

impl Message {
    /// Decodes one frame's bytes.
    pub fn decode_frame(frame: &[u8]) -> Result<Self, DecodeError> {
        let text = std::str::from_utf8(frame).map_err(|_| DecodeError::NotUtf8)?;
        Self::decode(text)
    }

    /// Decodes one frame's text.
    ///
    /// Text starting with `<` is XML; anything else is a debug command.
    pub fn decode(frame: &str) -> Result<Self, DecodeError> {
        let text = frame.trim();
        if text.is_empty() {
            return Err(DecodeError::Empty);
        }
        if !text.starts_with('<') {
            return Command::parse(text)
                .map(Self::Command)
                .map_err(DecodeError::Command);
        }
        let mut roots = xml::parse_documents(text)?;
        match roots.len() {
            0 => Err(DecodeError::Empty),
            1 => Self::from_element(roots.pop().expect("one root")),
            n => Err(DecodeError::MultipleRoots(n)),
        }
    }

    /// Decodes a parsed root element.
    pub fn from_element(root: Element) -> Result<Self, DecodeError> {
        match root.local_name() {
            "invoke" => decode_invoke(root),
            "ISISLayout" => bare_layout(&root).map(Self::Layout),
            "ISISRecord" => Ok(Self::Record(vec![bare_record(&root)])),
            "ISISCollection" => Ok(Self::Collection(vec![bare_collection(&root)])),
            "ISISAttributes" => Ok(Self::Attributes(
                root.children_named("Attribute")
                    .map(bare_attribute)
                    .collect(),
            )),
            "ISISRefresh" => Ok(Self::Refresh(Refresh {
                command: root.attr("action").unwrap_or_default().to_owned(),
            })),
            _ => Ok(Self::Other(root)),
        }
    }

    /// The message's name, for logs.
    pub fn kind(&self) -> &str {
        match self {
            Self::Layout(_) => "ISISLayout",
            Self::Record(_) => "ISISRecord",
            Self::DataEdit(_) => "ISISDataEdit",
            Self::Collection(_) => "ISISCollection",
            Self::Attributes(_) => "ISISAttributes",
            Self::Refresh(_) => "ISISRefresh",
            Self::Command(_) => "command",
            Self::Other(e) => match e.attr("fn") {
                Some(function) if e.local_name() == "invoke" => function,
                _ => e.local_name(),
            },
        }
    }

    /// Encodes the message as XML elements, one per frame.
    ///
    /// Returns an empty list for [`Message::Command`], which is not XML.
    pub fn to_elements(&self, dialect: Dialect) -> Vec<Element> {
        match dialect {
            Dialect::Invoke => self.to_invoke().into_iter().collect(),
            Dialect::Bare => self.to_bare(),
        }
    }

    /// Encodes the message as frame payloads, without NUL terminators.
    pub fn encode(&self, dialect: Dialect) -> Vec<String> {
        match self {
            Self::Command(cmd) => vec![cmd.encode()],
            _ => self
                .to_elements(dialect)
                .iter()
                .map(Element::to_xml)
                .collect(),
        }
    }

    fn to_invoke(&self) -> Option<Element> {
        let list = |name: &str, items: Vec<Element>| {
            items
                .into_iter()
                .fold(Element::new(name), Element::with_child)
        };
        let (function, payload) = match self {
            Self::Layout(layout) => (
                "ISISLayout",
                Element::text_element("Layout", layout.root_with_luid().to_xml()),
            ),
            Self::Record(records) => (
                "ISISRecord",
                list("RecordList", records.iter().map(invoke_record).collect()),
            ),
            Self::DataEdit(records) => (
                "ISISDataEdit",
                list("RecordList", records.iter().map(invoke_record).collect()),
            ),
            Self::Collection(collections) => (
                "ISISCollection",
                list(
                    "CollectionList",
                    collections.iter().map(invoke_collection).collect(),
                ),
            ),
            Self::Attributes(attributes) => (
                "ISISAttributes",
                list(
                    "AttributeList",
                    attributes.iter().map(invoke_attribute).collect(),
                ),
            ),
            Self::Refresh(refresh) => (
                "ISISRefresh",
                Element::text_element("Command", refresh.command.clone()),
            ),
            Self::Command(_) => return None,
            Self::Other(element) => return Some(element.clone()),
        };
        Some(
            Element::new("invoke").with_attr("fn", function).with_child(
                Element::new("args").with_child(Element::new("arg").with_child(payload)),
            ),
        )
    }

    fn to_bare(&self) -> Vec<Element> {
        match self {
            Self::Layout(layout) => {
                let mut wrapper = Element::new("ISISLayout");
                if let Some(luid) = layout.target.clone().or_else(|| layout.luid()) {
                    wrapper = wrapper.with_attr("luid", luid.to_string());
                }
                vec![wrapper.with_child(layout.root.clone())]
            }
            Self::Record(records) | Self::DataEdit(records) => {
                records.iter().map(bare_record_element).collect()
            }
            Self::Collection(collections) => {
                collections.iter().map(bare_collection_element).collect()
            }
            Self::Attributes(attributes) => vec![
                attributes
                    .iter()
                    .map(bare_attribute_element)
                    .fold(Element::new("ISISAttributes"), Element::with_child),
            ],
            Self::Refresh(refresh) => {
                // An absent action means `reset` to the Python layout
                // server; an empty one would mean nothing.
                let mut element = Element::new("ISISRefresh");
                if !refresh.command.is_empty() {
                    element = element.with_attr("action", refresh.command.clone());
                }
                vec![element]
            }
            Self::Command(_) => Vec::new(),
            Self::Other(element) => vec![element.clone()],
        }
    }
}

// ---------------------------------------------------------------- invoke

fn decode_invoke(root: Element) -> Result<Message, DecodeError> {
    let Some(function) = root.attr("fn") else {
        return Ok(Message::Other(root));
    };
    let arg = root.child("args").and_then(|args| args.child("arg"));
    let require_arg =
        || arg.ok_or_else(|| malformed(format!("{function} invoke has no <args><arg>")));
    let message = match function {
        "ISISLayout" => Message::Layout(invoke_layout(require_arg()?)?),
        "ISISRecord" => Message::Record(invoke_records(require_arg()?)?),
        "ISISDataEdit" => Message::DataEdit(invoke_records(require_arg()?)?),
        "ISISCollection" => Message::Collection(invoke_collections(require_arg()?)?),
        "ISISAttributes" => Message::Attributes(invoke_attributes(require_arg()?)?),
        "ISISRefresh" => Message::Refresh(Refresh {
            command: arg.map(arg_text).unwrap_or_default(),
        }),
        _ => return Ok(Message::Other(root)),
    };
    Ok(message)
}

/// The text an `<arg>` carries: its first child element's text, or its own.
fn arg_text(arg: &Element) -> String {
    arg.elements()
        .next()
        .map_or_else(|| arg.text(), Element::text)
}

/// Returns the items of a list payload such as `<RecordList>`.
///
/// The legacy client read `arg.children()[0].Record`. A bare item with no
/// list wrapper is also accepted.
fn list_items<'a>(
    arg: &'a Element,
    item: &'static str,
    function: &str,
) -> Result<Vec<&'a Element>, DecodeError> {
    match arg.elements().next() {
        Some(payload) if payload.local_name() == item => Ok(vec![payload]),
        Some(payload) => Ok(payload.children_named(item).collect()),
        None if arg.text().is_empty() => Ok(Vec::new()),
        None => Err(malformed(format!(
            "{function} argument holds text, expected <{item}> elements"
        ))),
    }
}

fn invoke_layout(arg: &Element) -> Result<Layout, DecodeError> {
    // The legacy client took `String(arg.children()[0])`: the XML of an
    // element with child elements, otherwise its text. Layout Managers send
    // `<Layout>` holding the layout as escaped text or CDATA.
    let root = match arg.elements().next() {
        Some(first) if first.has_elements() => {
            let mut inner = first.elements();
            match (inner.next(), inner.next()) {
                // Accept an element-valued <Layout> wrapper too.
                (Some(only), None) if first.local_name() == "Layout" => only.clone(),
                _ => first.clone(),
            }
        }
        Some(first) => match first.text() {
            text if text.is_empty() => first.clone(),
            text => xml::parse_element(&text)?,
        },
        None => match arg.text() {
            text if text.is_empty() => return Err(malformed("ISISLayout argument is empty")),
            text => xml::parse_element(&text)?,
        },
    };
    Ok(Layout::new(root))
}

fn invoke_records(arg: &Element) -> Result<Vec<WireRecord>, DecodeError> {
    Ok(list_items(arg, "Record", "ISISRecord")?
        .into_iter()
        .map(|record| WireRecord {
            ruid: record.child_text("ruid").unwrap_or_default(),
            layout: record.child_text("layout"),
            fields: record
                .child("fieldList")
                .map(|list| {
                    list.children_named("Field")
                        .map(|field| WireField {
                            fid: field.child_text("fid").unwrap_or_default(),
                            value: field.child_text("value").unwrap_or_default(),
                            send: non_empty(field.child_text("send")),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            ignored_attributes: record.children_named("Attribute").count(),
        })
        .collect())
}

fn invoke_collections(arg: &Element) -> Result<Vec<WireCollection>, DecodeError> {
    Ok(list_items(arg, "Collection", "ISISCollection")?
        .into_iter()
        .map(|collection| WireCollection {
            cuid: collection.child_text("cuid").unwrap_or_default(),
            ruids: collection
                .child_ignore_case("ruidList")
                .map(|list| {
                    list.children_named("Ruid")
                        .map(|ruid| WireRuid {
                            ruid: ruid.child_text("ruid").unwrap_or_default(),
                            select: ruid.child_text("select").unwrap_or_default(),
                            reference: ruid.child_text("ref").unwrap_or_default(),
                        })
                        .collect()
                })
                .unwrap_or_default(),
        })
        .collect())
}

fn invoke_attributes(arg: &Element) -> Result<Vec<WireAttribute>, DecodeError> {
    Ok(list_items(arg, "Attribute", "ISISAttributes")?
        .into_iter()
        .map(invoke_attribute_from)
        .collect())
}

fn invoke_attribute_from(attribute: &Element) -> WireAttribute {
    WireAttribute {
        ruid: attribute.child_text("ruid").unwrap_or_default(),
        fid: attribute.child_text("fid").unwrap_or_default(),
        send: non_empty(attribute.child_text("send")),
        action_state: non_empty(attribute.child_text("actionState")),
        permissions: non_empty(attribute.child_text("permissions")),
    }
}

fn invoke_record(record: &WireRecord) -> Element {
    let mut element =
        Element::new("Record").with_child(Element::text_element("ruid", &*record.ruid));
    if let Some(layout) = &record.layout {
        element = element.with_child(Element::text_element("layout", layout.clone()));
    }
    let fields = record
        .fields
        .iter()
        .fold(Element::new("fieldList"), |list, field| {
            let mut f = Element::new("Field")
                .with_child(Element::text_element("fid", &*field.fid))
                .with_child(Element::text_element("value", &*field.value));
            if let Some(send) = &field.send {
                f = f.with_child(Element::text_element("send", &**send));
            }
            list.with_child(f)
        });
    element.with_child(fields)
}

fn invoke_collection(collection: &WireCollection) -> Element {
    let ruids = collection
        .ruids
        .iter()
        .fold(Element::new("ruidList"), |list, r| {
            list.with_child(
                Element::new("Ruid")
                    .with_child(Element::text_element("ruid", &*r.ruid))
                    .with_child(Element::text_element("ref", &*r.reference))
                    .with_child(Element::text_element("select", &*r.select)),
            )
        });
    Element::new("Collection")
        .with_child(Element::text_element("cuid", &*collection.cuid))
        .with_child(ruids)
}

fn invoke_attribute(attribute: &WireAttribute) -> Element {
    let mut element = Element::new("Attribute")
        .with_child(Element::text_element("ruid", &*attribute.ruid))
        .with_child(Element::text_element("fid", &*attribute.fid));
    for (name, value) in [
        ("send", &attribute.send),
        ("actionState", &attribute.action_state),
        ("permissions", &attribute.permissions),
    ] {
        if let Some(value) = value {
            element = element.with_child(Element::text_element(name, &**value));
        }
    }
    element
}

// ------------------------------------------------------------------ bare

fn bare_layout(root: &Element) -> Result<Layout, DecodeError> {
    let target = root.attr("luid").map(Luid::from);
    let layout_root = match root.elements().next() {
        Some(child) => child.clone(),
        None => match root.text() {
            text if text.is_empty() => {
                return Err(malformed("ISISLayout holds no layout element"));
            }
            text => xml::parse_element(&text)?,
        },
    };
    Ok(Layout {
        target,
        root: layout_root,
    })
}

fn attr_string(element: &Element, name: &str) -> String {
    element.attr(name).unwrap_or_default().to_owned()
}

fn attr_non_empty(element: &Element, name: &str) -> Option<String> {
    element
        .attr(name)
        .filter(|v| !v.is_empty())
        .map(str::to_owned)
}

fn bare_record(root: &Element) -> WireRecord {
    WireRecord {
        ruid: attr_string(root, "ruid"),
        layout: root.attr("layout").map(str::to_owned),
        fields: root
            .children_named("Field")
            .map(|field| WireField {
                fid: attr_string(field, "fid"),
                value: attr_string(field, "value"),
                send: attr_non_empty(field, "send"),
            })
            .collect(),
        ignored_attributes: root.children_named("Attribute").count(),
    }
}

fn bare_collection(root: &Element) -> WireCollection {
    WireCollection {
        cuid: attr_string(root, "cuid"),
        ruids: root
            .child_ignore_case("RuidList")
            .map(|list| {
                list.children_named("Ruid")
                    .map(|ruid| WireRuid {
                        ruid: attr_string(ruid, "ruid"),
                        select: attr_string(ruid, "select"),
                        reference: attr_string(ruid, "ref"),
                    })
                    .collect()
            })
            .unwrap_or_default(),
    }
}

fn bare_attribute(attribute: &Element) -> WireAttribute {
    WireAttribute {
        ruid: attr_string(attribute, "ruid"),
        fid: attr_string(attribute, "fid"),
        send: attr_non_empty(attribute, "send"),
        action_state: attr_non_empty(attribute, "actionState"),
        permissions: attr_non_empty(attribute, "permissions"),
    }
}

fn bare_record_element(record: &WireRecord) -> Element {
    let mut element = Element::new("ISISRecord").with_attr("ruid", &*record.ruid);
    if let Some(layout) = &record.layout {
        element = element.with_attr("layout", layout.clone());
    }
    for field in &record.fields {
        let mut f = Element::new("Field")
            .with_attr("fid", &*field.fid)
            .with_attr("value", &*field.value);
        if let Some(send) = &field.send {
            f = f.with_attr("send", &**send);
        }
        element = element.with_child(f);
    }
    element
}

fn bare_collection_element(collection: &WireCollection) -> Element {
    let ruids = collection
        .ruids
        .iter()
        .fold(Element::new("RuidList"), |list, r| {
            let mut ruid = Element::new("Ruid")
                .with_attr("ruid", &*r.ruid)
                .with_attr("select", &*r.select);
            if !r.reference.is_empty() {
                ruid = ruid.with_attr("ref", &*r.reference);
            }
            list.with_child(ruid)
        });
    Element::new("ISISCollection")
        .with_attr("cuid", &*collection.cuid)
        .with_child(ruids)
}

fn bare_attribute_element(attribute: &WireAttribute) -> Element {
    let mut element = Element::new("Attribute")
        .with_attr("ruid", &*attribute.ruid)
        .with_attr("fid", &*attribute.fid);
    for (name, value) in [
        ("send", &attribute.send),
        ("actionState", &attribute.action_state),
        ("permissions", &attribute.permissions),
    ] {
        if let Some(value) = value {
            element = element.with_attr(name, &**value);
        }
    }
    element
}

#[cfg(test)]
mod tests {
    use super::*;

    fn decode(s: &str) -> Message {
        Message::decode(s).unwrap_or_else(|e| panic!("{e}: {s}"))
    }

    fn round_trip(message: &Message, dialect: Dialect) -> Message {
        let frames = message.encode(dialect);
        assert_eq!(frames.len(), 1, "{frames:?}");
        decode(&frames[0])
    }

    fn record(ruid: &str, fields: &[(&str, &str)]) -> WireRecord {
        WireRecord {
            ruid: ruid.into(),
            fields: fields
                .iter()
                .map(|&(fid, value)| WireField {
                    fid: fid.into(),
                    value: value.into(),
                    send: None,
                })
                .collect(),
            ..Default::default()
        }
    }

    #[test]
    fn decodes_legacy_invoke_record() {
        let msg = decode(
            "<invoke fn=\"ISISRecord\"><args><arg><RecordList>\
             <Record><ruid>r1</ruid><layout>|Shortcut|:a</layout><fieldList>\
             <Field><fid>a</fid><value> 1 </value></Field>\
             <Field><fid>b</fid></Field>\
             </fieldList></Record></RecordList></arg></args></invoke>",
        );
        let Message::Record(records) = msg else {
            panic!("{msg:?}")
        };
        assert_eq!(records.len(), 1);
        assert_eq!(records[0].ruid, "r1");
        assert_eq!(records[0].layout.as_deref(), Some("|Shortcut|:a"));
        assert_eq!(records[0].fields[0].value, "1", "text is trimmed");
        assert_eq!(records[0].fields[1].value, "", "absent value is empty");
    }

    #[test]
    fn decodes_namespaced_invoke() {
        let msg = decode(
            "<fn:invoke fn=\"ISISCollection\" xmlns:fn=\"urn:f\" xmlns=\"urn:c\">\
             <fn:args><fn:arg><CollectionList><Collection><cuid>c</cuid>\
             <ruidList><Ruid><ruid>r</ruid><ref></ref><select>last</select></Ruid></ruidList>\
             </Collection></CollectionList></fn:arg></fn:args></fn:invoke>",
        );
        assert_eq!(
            msg,
            Message::Collection(vec![WireCollection {
                cuid: "c".into(),
                ruids: vec![WireRuid {
                    ruid: "r".into(),
                    select: "last".into(),
                    reference: String::new(),
                }],
            }])
        );
    }

    #[test]
    fn decodes_bare_record_with_field_send() {
        let msg = decode(
            "<ISISRecord ruid=\"r\" layout=\"\"><Field fid=\"a\" value=\"x &lt; y\" send=\"never\"/>\
             </ISISRecord>",
        );
        let Message::Record(records) = msg else {
            panic!()
        };
        let r = &records[0];
        assert_eq!(r.layout.as_deref(), Some(""));
        assert_eq!(r.fields[0].value, "x < y");
        assert_eq!(r.fields[0].send.as_deref(), Some("never"));
        assert_eq!(r.ignored_attributes, 0);
    }

    #[test]
    fn attribute_elements_in_records_are_counted_and_dropped() {
        for frame in [
            "<ISISRecord ruid=\"r\"><Field fid=\"a\" value=\"1\"/>\
             <Attribute ruid=\"o\" fid=\"f\" send=\"true\"/>\
             <Attribute ruid=\"p\" fid=\"g\"/></ISISRecord>",
            "<invoke fn=\"ISISRecord\"><args><arg><RecordList><Record><ruid>r</ruid>\
             <fieldList><Field><fid>a</fid><value>1</value></Field></fieldList>\
             <Attribute><ruid>o</ruid><fid>f</fid></Attribute>\
             <Attribute><ruid>p</ruid><fid>g</fid></Attribute>\
             </Record></RecordList></arg></args></invoke>",
        ] {
            let msg = decode(frame);
            let Message::Record(records) = &msg else {
                panic!("{msg:?}")
            };
            assert_eq!(records[0].ignored_attributes, 2, "{frame}");
            assert_eq!(records[0].fields.len(), 1);
            for dialect in [Dialect::Invoke, Dialect::Bare] {
                let encoded = msg.encode(dialect).concat();
                assert!(!encoded.contains("Attribute"), "{dialect:?}: {encoded}");
            }
        }
    }

    #[test]
    fn invoke_layout_accepts_text_cdata_and_element_forms() {
        let expected = Element::new("VBox")
            .with_attr("luid", "mainLuid")
            .with_child(Element::new("Label").with_attr("text", "hi"));
        for frame in [
            "<invoke fn=\"ISISLayout\"><args><arg><Layout>&lt;VBox luid=\"mainLuid\"&gt;\
             &lt;Label text=\"hi\"/&gt;&lt;/VBox&gt;</Layout></arg></args></invoke>",
            "<invoke fn=\"ISISLayout\"><args><arg><Layout><![CDATA[<VBox luid=\"mainLuid\">\
             <Label text=\"hi\"/></VBox>]]></Layout></arg></args></invoke>",
            "<invoke fn=\"ISISLayout\"><args><arg><VBox luid=\"mainLuid\">\
             <Label text=\"hi\"/></VBox></arg></args></invoke>",
            "<invoke fn=\"ISISLayout\"><args><arg><Layout><VBox luid=\"mainLuid\">\
             <Label text=\"hi\"/></VBox></Layout></arg></args></invoke>",
        ] {
            assert_eq!(
                decode(frame),
                Message::Layout(Layout::new(expected.clone())),
                "{frame}"
            );
        }
    }

    #[test]
    fn layout_luid_and_command() {
        let layout = Layout {
            target: Some("outer".into()),
            root: Element::new("VBox"),
        };
        assert_eq!(layout.luid(), Some("outer".into()));
        let layout = Layout {
            target: Some("outer".into()),
            root: Element::new("VBox").with_attr("luid", "inner"),
        };
        assert_eq!(layout.luid(), Some("inner".into()));
        let command = Layout::new(Element::text_element("command", " |Shortcut|:a:b "));
        assert_eq!(command.command().as_deref(), Some("|Shortcut|:a:b"));
        assert_eq!(layout.command(), None);
    }

    #[test]
    fn layout_target_survives_invoke_encoding() {
        let layout = Message::Layout(Layout {
            target: Some("mainLuid".into()),
            root: Element::new("layout_manager"),
        });
        let Message::Layout(back) = round_trip(&layout, Dialect::Invoke) else {
            panic!()
        };
        assert_eq!(back.luid(), Some("mainLuid".into()));
    }

    #[test]
    fn refresh_both_dialects() {
        let on_connect = Message::Refresh(Refresh::default());
        assert_eq!(
            on_connect.encode(Dialect::Invoke),
            ["<invoke fn=\"ISISRefresh\"><args><arg><Command/></arg></args></invoke>"]
        );
        assert_eq!(on_connect.encode(Dialect::Bare), ["<ISISRefresh/>"]);
        let reset = Message::Refresh(Refresh {
            command: "reset".into(),
        });
        assert_eq!(
            reset.encode(Dialect::Bare),
            ["<ISISRefresh action=\"reset\"/>"]
        );
        for dialect in [Dialect::Invoke, Dialect::Bare] {
            assert_eq!(round_trip(&on_connect, dialect), on_connect);
            assert_eq!(round_trip(&reset, dialect), reset);
        }
    }

    #[test]
    fn data_edit_matches_legacy_writer() {
        let edit = Message::DataEdit(vec![record("r1", &[("a", "1")])]);
        assert_eq!(
            edit.encode(Dialect::Invoke),
            [
                "<invoke fn=\"ISISDataEdit\"><args><arg><RecordList><Record><ruid>r1</ruid>\
              <fieldList><Field><fid>a</fid><value>1</value></Field></fieldList>\
              </Record></RecordList></arg></args></invoke>"
            ]
        );
        assert_eq!(round_trip(&edit, Dialect::Invoke), edit);
        // The bare dialect has no data-edit message.
        assert_eq!(
            round_trip(&edit, Dialect::Bare),
            Message::Record(vec![record("r1", &[("a", "1")])])
        );
    }

    #[test]
    fn bare_lists_encode_one_frame_per_item() {
        let msg = Message::Record(vec![record("a", &[]), record("b", &[])]);
        assert_eq!(msg.encode(Dialect::Bare).len(), 2);
        assert_eq!(msg.encode(Dialect::Invoke).len(), 1);
    }

    #[test]
    fn unknown_xml_is_kept() {
        let frame =
            "<fn:invoke xmlns:fn=\"urn:f\" fn=\"set_ISISFormLayout\"><x a=\"1\"/></fn:invoke>";
        let msg = decode(frame);
        assert_eq!(msg.kind(), "set_ISISFormLayout");
        assert_eq!(msg.encode(Dialect::Invoke), [frame]);
        assert_eq!(
            decode("<LayoutRequest luid=\"x\"/>").kind(),
            "LayoutRequest"
        );
    }

    #[test]
    fn decode_errors() {
        assert_eq!(Message::decode(" \n"), Err(DecodeError::Empty));
        assert_eq!(Message::decode_frame(&[0xff]), Err(DecodeError::NotUtf8));
        assert!(matches!(Message::decode("<a>"), Err(DecodeError::Xml(_))));
        assert_eq!(
            Message::decode("<a/><b/>"),
            Err(DecodeError::MultipleRoots(2))
        );
        assert!(matches!(
            Message::decode("HELLO"),
            Err(DecodeError::Command(_))
        ));
        assert!(matches!(
            Message::decode("<invoke fn=\"ISISRecord\"/>"),
            Err(DecodeError::Malformed(_))
        ));
        assert!(matches!(
            Message::decode("<ISISLayout luid=\"x\"/>"),
            Err(DecodeError::Malformed(_))
        ));
    }

    #[test]
    fn commands_pass_through() {
        let msg = decode("LIST_RECORDS");
        assert_eq!(msg, Message::Command(Command::ListRecords));
        assert_eq!(msg.encode(Dialect::Invoke), ["LIST_RECORDS"]);
        assert_eq!(msg.encode(Dialect::Bare), ["LIST_RECORDS"]);
    }
}
