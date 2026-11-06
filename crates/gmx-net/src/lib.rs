//! GMX transport.
//!
//! * [`codec`]: the tokio codec for NUL-terminated frames.
//! * [`connection`]: one framed TCP connection.
//! * [`server`]: a listening server that reports client events in order
//!   and sends through a shared [`Hub`].
//! * [`endpoint`]: a client connection that reconnects with back-off and
//!   sends `ISISRefresh` on every connect, as the legacy client did.
//! * [`capture`]: a JSON Lines record of frames, for capture and replay.

pub mod capture;
pub mod codec;
pub mod connection;
pub mod endpoint;
pub mod server;

pub use codec::{FrameCodec, Inbound, OutFrame};
pub use connection::{Connection, ConnectionReader, ConnectionWriter};
pub use endpoint::{Endpoint, EndpointConfig, EndpointEvent, SendError};
pub use server::{ClientId, DisconnectReason, Hub, Server, ServerConfig, ServerEvent};
