//! GMX wire protocol.
//!
//! * [`frame`] splits a byte stream into NUL-terminated frames, the framing
//!   inherited from the Flash `XMLSocket`.
//! * [`message`] decodes frames into [`Message`] values and encodes them in
//!   either XML [`Dialect`]: the legacy `invoke` envelope or the bare form
//!   used by the Python reference servers.
//! * [`command`] handles the plain-text debug commands.
//! * [`apply`](mod@apply) applies data messages to a [`gmx_model::Store`].
//! * [`xml`] is the small element tree the codec is built on.
//!
//! Nothing here does I/O.

pub mod apply;
pub mod command;
pub mod frame;
pub mod message;
pub mod xml;

pub use apply::apply;
pub use command::{Command, UnknownCommand};
pub use frame::{DEFAULT_MAX_FRAME_BYTES, FrameDecoder, FrameError, encode_frame};
pub use message::{
    DecodeError, Dialect, Layout, Message, Refresh, WireAttribute, WireCollection, WireField,
    WireRecord, WireRuid,
};
pub use xml::{Element, Node, XmlError};
