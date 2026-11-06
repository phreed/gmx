//! A small owned XML element tree.
//!
//! GMX messages are short, so the codec parses each one into a tree and
//! then reads it. The tree keeps element and attribute names exactly as
//! written, prefixes included, so unknown messages can be passed on
//! unchanged. Lookups match by local name and ignore namespaces, as the
//! legacy client did for the `invoke` root.
//!
//! Parsing drops comments, processing instructions, the XML declaration and
//! whitespace-only text nodes. That matches the legacy client, whose E4X
//! parser ran with `ignoreComments` and `ignoreWhitespace` set.

use std::fmt;

use quick_xml::XmlVersion;
use quick_xml::escape::resolve_predefined_entity;
use quick_xml::events::{BytesStart, Event};
use quick_xml::reader::Reader;

/// A node in an element's content.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Node {
    /// A child element.
    Element(Element),
    /// Character data, with entities and CDATA sections resolved.
    Text(String),
}

/// An XML element with its attributes and content.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Element {
    /// The qualified name as written, for example `fn:invoke`.
    pub name: String,
    /// Attributes in document order, names as written.
    pub attributes: Vec<(String, String)>,
    /// Child nodes in document order.
    pub children: Vec<Node>,
}

/// A parse failure, with the byte offset where it was detected.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct XmlError {
    /// What went wrong.
    pub message: String,
    /// Byte offset into the input.
    pub position: u64,
}

impl fmt::Display for XmlError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} at byte {}", self.message, self.position)
    }
}

impl std::error::Error for XmlError {}

fn local(name: &str) -> &str {
    name.rsplit_once(':').map_or(name, |(_, l)| l)
}

fn is_namespace_declaration(name: &str) -> bool {
    name == "xmlns" || name.starts_with("xmlns:")
}

impl Element {
    /// Creates an element with no attributes or content.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            ..Self::default()
        }
    }

    /// Adds an attribute.
    pub fn with_attr(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        self.attributes.push((name.into(), value.into()));
        self
    }

    /// Adds a child element.
    pub fn with_child(mut self, child: Element) -> Self {
        self.children.push(Node::Element(child));
        self
    }

    /// Adds text content. Empty text adds nothing.
    pub fn with_text(mut self, text: impl Into<String>) -> Self {
        let text = text.into();
        if !text.is_empty() {
            self.children.push(Node::Text(text));
        }
        self
    }

    /// Creates `<name>text</name>`.
    pub fn text_element(name: impl Into<String>, text: impl Into<String>) -> Self {
        Self::new(name).with_text(text)
    }

    /// The name without any namespace prefix.
    pub fn local_name(&self) -> &str {
        local(&self.name)
    }

    /// Looks up an attribute by local name. Namespace declarations are
    /// never matched, so `attr("fn")` does not find `xmlns:fn`.
    pub fn attr(&self, name: &str) -> Option<&str> {
        self.attributes
            .iter()
            .find(|(k, _)| !is_namespace_declaration(k) && local(k) == name)
            .map(|(_, v)| v.as_str())
    }

    /// Iterates over the child elements.
    pub fn elements(&self) -> impl Iterator<Item = &Element> {
        self.children.iter().filter_map(|n| match n {
            Node::Element(e) => Some(e),
            Node::Text(_) => None,
        })
    }

    /// The first child element with the given local name.
    pub fn child(&self, name: &str) -> Option<&Element> {
        self.elements().find(|e| e.local_name() == name)
    }

    /// Like [`Element::child`], ignoring ASCII case.
    pub fn child_ignore_case(&self, name: &str) -> Option<&Element> {
        self.elements()
            .find(|e| e.local_name().eq_ignore_ascii_case(name))
    }

    /// The child elements with the given local name.
    pub fn children_named<'a>(&'a self, name: &'a str) -> impl Iterator<Item = &'a Element> + 'a {
        self.elements().filter(move |e| e.local_name() == name)
    }

    /// True when the element has at least one child element.
    pub fn has_elements(&self) -> bool {
        self.elements().next().is_some()
    }

    /// The direct text content, trimmed.
    ///
    /// Trimming matches the legacy client, whose parser dropped leading and
    /// trailing whitespace from text nodes.
    pub fn text(&self) -> String {
        let mut text = String::new();
        for node in &self.children {
            if let Node::Text(t) = node {
                text.push_str(t);
            }
        }
        match text.trim() {
            t if t.len() == text.len() => text,
            t => t.to_owned(),
        }
    }

    /// The text of the named child element, if present.
    pub fn child_text(&self, name: &str) -> Option<String> {
        self.child(name).map(Element::text)
    }

    /// Serializes the element without an XML declaration.
    pub fn to_xml(&self) -> String {
        let mut out = String::new();
        self.write(&mut out);
        out
    }

    fn write(&self, out: &mut String) {
        out.push('<');
        out.push_str(&self.name);
        for (name, value) in &self.attributes {
            out.push(' ');
            out.push_str(name);
            out.push_str("=\"");
            escape_into(out, value, true);
            out.push('"');
        }
        if self.children.is_empty() {
            out.push_str("/>");
            return;
        }
        out.push('>');
        for child in &self.children {
            match child {
                Node::Element(e) => e.write(out),
                Node::Text(t) => escape_into(out, t, false),
            }
        }
        out.push_str("</");
        out.push_str(&self.name);
        out.push('>');
    }
}

impl fmt::Display for Element {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.to_xml())
    }
}

/// Escapes text or an attribute value.
///
/// Whitespace that the parser would normalize is written as a character
/// reference so that it survives a round trip. Control characters that XML
/// 1.0 cannot represent are replaced with U+FFFD.
fn escape_into(out: &mut String, s: &str, attribute: bool) {
    for ch in s.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' if attribute => out.push_str("&quot;"),
            '\r' => out.push_str("&#13;"),
            '\n' if attribute => out.push_str("&#10;"),
            '\t' if attribute => out.push_str("&#9;"),
            '\t' | '\n' => out.push(ch),
            c if (c as u32) < 0x20 => out.push('\u{FFFD}'),
            c => out.push(c),
        }
    }
}

/// Parses a string holding one or more top-level elements.
///
/// Several example files hold a sequence of messages, which is not a
/// well-formed XML document, so more than one root is allowed here.
pub fn parse_documents(input: &str) -> Result<Vec<Element>, XmlError> {
    let mut reader = Reader::from_str(input);
    let mut roots = Vec::new();
    let mut stack: Vec<Element> = Vec::new();

    let err = |reader: &Reader<&[u8]>, message: String| XmlError {
        message,
        position: reader.error_position(),
    };

    loop {
        let event = reader
            .read_event()
            .map_err(|e| err(&reader, e.to_string()))?;
        match event {
            Event::Start(start) => stack.push(read_start(&reader, &start)?),
            Event::Empty(start) => {
                let element = read_start(&reader, &start)?;
                attach(&mut stack, &mut roots, element);
            }
            Event::End(_) => {
                let mut element = stack
                    .pop()
                    .ok_or_else(|| err(&reader, "unexpected end tag".into()))?;
                element.children.retain(|n| match n {
                    Node::Text(t) => !t.trim().is_empty(),
                    Node::Element(_) => true,
                });
                attach(&mut stack, &mut roots, element);
            }
            Event::Text(text) => {
                let text = text
                    .xml10_content()
                    .map_err(|e| err(&reader, e.to_string()))?;
                push_text(&mut stack, &text, &reader)?;
            }
            Event::CData(data) => {
                let text = data
                    .xml10_content()
                    .map_err(|e| err(&reader, e.to_string()))?;
                push_text(&mut stack, &text, &reader)?;
            }
            Event::GeneralRef(reference) => {
                let resolved = match reference
                    .resolve_char_ref()
                    .map_err(|e| err(&reader, e.to_string()))?
                {
                    Some(ch) => ch.to_string(),
                    None => {
                        let name = reference
                            .decode()
                            .map_err(|e| err(&reader, e.to_string()))?;
                        resolve_predefined_entity(&name)
                            .ok_or_else(|| err(&reader, format!("unknown entity '&{name};'")))?
                            .to_owned()
                    }
                };
                push_text(&mut stack, &resolved, &reader)?;
            }
            Event::Eof => break,
            // Comments, processing instructions, declarations and DOCTYPE.
            _ => {}
        }
    }

    if let Some(open) = stack.last() {
        return Err(XmlError {
            message: format!("unclosed element <{}>", open.name),
            position: input.len() as u64,
        });
    }
    Ok(roots)
}

/// Parses a string that must hold exactly one top-level element.
pub fn parse_element(input: &str) -> Result<Element, XmlError> {
    let mut roots = parse_documents(input)?;
    match roots.len() {
        1 => Ok(roots.pop().expect("one root")),
        n => Err(XmlError {
            message: format!("expected one root element, found {n}"),
            position: 0,
        }),
    }
}

fn read_start(reader: &Reader<&[u8]>, start: &BytesStart<'_>) -> Result<Element, XmlError> {
    let err = |message: String| XmlError {
        message,
        position: reader.error_position(),
    };
    let qname = start.name();
    let name = std::str::from_utf8(qname.as_ref()).map_err(|e| err(e.to_string()))?;
    let mut element = Element::new(name);
    for attr in start.attributes() {
        let attr = attr.map_err(|e| err(e.to_string()))?;
        let key = std::str::from_utf8(attr.key.as_ref()).map_err(|e| err(e.to_string()))?;
        let value = attr
            .decoded_and_normalized_value(XmlVersion::Implicit1_0, reader.decoder())
            .map_err(|e| err(e.to_string()))?;
        element
            .attributes
            .push((key.to_owned(), value.into_owned()));
    }
    Ok(element)
}

fn attach(stack: &mut [Element], roots: &mut Vec<Element>, element: Element) {
    match stack.last_mut() {
        Some(parent) => parent.children.push(Node::Element(element)),
        None => roots.push(element),
    }
}

fn push_text(stack: &mut [Element], text: &str, reader: &Reader<&[u8]>) -> Result<(), XmlError> {
    let Some(parent) = stack.last_mut() else {
        if text.trim().is_empty() {
            return Ok(());
        }
        return Err(XmlError {
            message: "text outside of any element".into(),
            position: reader.error_position(),
        });
    };
    match parent.children.last_mut() {
        Some(Node::Text(existing)) => existing.push_str(text),
        _ => parent.children.push(Node::Text(text.to_owned())),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_names_attributes_and_text() {
        let el = parse_element(
            r#"<fn:invoke xmlns:fn="urn:x" fn="ISISRecord"><a b="1">t</a></fn:invoke>"#,
        )
        .unwrap();
        assert_eq!(el.name, "fn:invoke");
        assert_eq!(el.local_name(), "invoke");
        assert_eq!(el.attr("fn"), Some("ISISRecord"));
        assert_eq!(el.child("a").unwrap().attr("b"), Some("1"));
        assert_eq!(el.child_text("a").as_deref(), Some("t"));
        assert_eq!(el.child("missing"), None);
    }

    #[test]
    fn attr_skips_namespace_declarations() {
        let el = parse_element(r#"<r xmlns:fn="urn:x"/>"#).unwrap();
        assert_eq!(el.attr("fn"), None);
    }

    #[test]
    fn resolves_entities_char_refs_and_cdata() {
        let el = parse_element("<v a=\"x &lt; y &#65;\">a &amp; b &#x263A; <![CDATA[<raw>]]></v>")
            .unwrap();
        assert_eq!(el.attr("a"), Some("x < y A"));
        assert_eq!(el.text(), "a & b \u{263A} <raw>");
    }

    #[test]
    fn rejects_unknown_entities_and_bad_nesting() {
        assert!(parse_element("<v>&nbsp;</v>").is_err());
        assert!(parse_element("<a><b></a>").is_err());
        assert!(parse_element("<a>").is_err());
        assert!(parse_documents("text <a/>").is_err());
    }

    #[test]
    fn drops_comments_declarations_and_whitespace_nodes() {
        let el =
            parse_element("<?xml version=\"1.0\"?>\n<!-- c --><a>\n  <!-- c -->\n  <b/>\n</a>\n")
                .unwrap();
        assert_eq!(el.children, vec![Node::Element(Element::new("b"))]);
    }

    #[test]
    fn parses_several_roots() {
        let roots = parse_documents("<a/>\n<!-- x -->\n<b>t</b>").unwrap();
        assert_eq!(roots.len(), 2);
        assert!(parse_element("<a/><b/>").is_err());
        assert!(parse_element("").is_err());
    }

    #[test]
    fn text_is_trimmed() {
        let el = parse_element("<v>  x y  </v>").unwrap();
        assert_eq!(el.text(), "x y");
    }

    #[test]
    fn writer_escapes_and_round_trips() {
        let el = Element::new("a")
            .with_attr("q", "\"<&>\"\n\t\r end")
            .with_child(Element::text_element("t", "x < & > y\r\nz\u{1}"))
            .with_child(Element::new("empty"));
        let xml = el.to_xml();
        assert_eq!(
            xml,
            "<a q=\"&quot;&lt;&amp;&gt;&quot;&#10;&#9;&#13; end\">\
             <t>x &lt; &amp; &gt; y&#13;\nz\u{FFFD}</t><empty/></a>"
        );
        let back = parse_element(&xml).unwrap();
        assert_eq!(back.attr("q"), Some("\"<&>\"\n\t\r end"));
        assert_eq!(
            back.child_text("t").as_deref(),
            Some("x < & > y\r\nz\u{FFFD}")
        );
    }

    #[test]
    fn line_endings_are_normalized() {
        let el = parse_element("<v>a\r\nb</v>").unwrap();
        assert_eq!(el.text(), "a\nb");
    }
}
