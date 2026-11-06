//! A TCP server for GMX services.
//!
//! [`Server`] accepts connections and turns everything that happens on them
//! into one ordered stream of [`ServerEvent`]s. A service handles that
//! stream in a single task, so it can own its state without locks, and
//! replies through the cloneable [`Hub`].
//!
//! Each client has a bounded send queue. A client that falls so far
//! behind that its queue fills is disconnected, rather than letting it
//! hold an unbounded amount of server memory. Inbound back-pressure comes
//! from the bounded event stream: when the service falls behind, client
//! sockets stop being read and TCP slows the senders.

use std::collections::HashMap;
use std::fmt;
use std::io;
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use gmx_proto::{DEFAULT_MAX_FRAME_BYTES, Dialect, Message};
use tokio::net::{TcpListener, TcpStream, ToSocketAddrs};
use tokio::sync::mpsc::error::TrySendError;
use tokio::sync::{Notify, mpsc};
use tokio::task::{JoinHandle, JoinSet};
use tracing::{debug, warn};

use crate::codec::{Inbound, OutFrame};
use crate::connection::Connection;

/// Identifies one client connection for the life of a [`Server`].
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct ClientId(u64);

impl fmt::Display for ClientId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "client#{}", self.0)
    }
}

/// Server limits.
#[derive(Clone, Debug)]
pub struct ServerConfig {
    /// Largest accepted inbound frame.
    pub max_frame_bytes: usize,
    /// Frames that may wait in one client's send queue.
    pub client_queue_frames: usize,
    /// Events that may wait for the service to handle them.
    pub event_queue: usize,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            max_frame_bytes: DEFAULT_MAX_FRAME_BYTES,
            client_queue_frames: 1024,
            event_queue: 1024,
        }
    }
}

/// Why a client connection ended.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum DisconnectReason {
    /// The client closed the connection.
    Closed,
    /// Reading or writing failed.
    Error(String),
    /// The client's send queue filled up.
    SlowConsumer,
    /// [`Hub::disconnect`] was called.
    Kicked,
}

impl fmt::Display for DisconnectReason {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Closed => f.write_str("closed by peer"),
            Self::Error(e) => write!(f, "I/O error: {e}"),
            Self::SlowConsumer => f.write_str("send queue full"),
            Self::Kicked => f.write_str("disconnected by server"),
        }
    }
}

/// Something that happened on a client connection.
///
/// For each client, `Connected` comes first and `Disconnected` last.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ServerEvent {
    /// A client connected.
    Connected {
        /// The new client.
        client: ClientId,
        /// Its address.
        peer: SocketAddr,
    },
    /// A client sent a frame.
    Received {
        /// The sender.
        client: ClientId,
        /// What arrived.
        inbound: Inbound,
    },
    /// A client's connection ended.
    Disconnected {
        /// The client.
        client: ClientId,
        /// Why.
        reason: DisconnectReason,
    },
}

#[derive(Debug)]
struct ClientSlot {
    queue: mpsc::Sender<OutFrame>,
    /// Set before the slot is removed, so the client task can report why.
    reason: Arc<Mutex<Option<DisconnectReason>>>,
    /// Wakes the client task even while it is blocked writing to a peer
    /// that has stopped reading.
    close: Arc<Notify>,
}

/// Sends frames to connected clients. Cheap to clone.
#[derive(Clone, Debug, Default)]
pub struct Hub {
    clients: Arc<Mutex<HashMap<ClientId, ClientSlot>>>,
}

impl Hub {
    /// Queues frames for one client.
    ///
    /// Returns false if the client is gone, or was just disconnected
    /// because its queue is full.
    pub fn send(&self, client: ClientId, frames: &[OutFrame]) -> bool {
        let mut clients = self.lock();
        Self::send_locked(&mut clients, client, frames)
    }

    /// Encodes a message and queues it for one client.
    pub fn send_message(&self, client: ClientId, message: &Message, dialect: Dialect) -> bool {
        self.send(client, &OutFrame::from_message(message, dialect))
    }

    /// Queues frames for every client. Returns how many were reached.
    pub fn broadcast(&self, frames: &[OutFrame]) -> usize {
        self.broadcast_filtered(frames, |_| true)
    }

    /// Queues frames for every client except one.
    pub fn broadcast_except(&self, except: ClientId, frames: &[OutFrame]) -> usize {
        self.broadcast_filtered(frames, |client| client != except)
    }

    /// Encodes a message once and queues it for every client.
    pub fn broadcast_message(&self, message: &Message, dialect: Dialect) -> usize {
        self.broadcast(&OutFrame::from_message(message, dialect))
    }

    /// Closes a client's connection. Frames already queued are discarded.
    pub fn disconnect(&self, client: ClientId) -> bool {
        Self::remove_locked(&mut self.lock(), client, DisconnectReason::Kicked)
    }

    /// The connected clients, in connection order.
    pub fn clients(&self) -> Vec<ClientId> {
        let mut clients: Vec<_> = self.lock().keys().copied().collect();
        clients.sort();
        clients
    }

    /// Number of connected clients.
    pub fn len(&self) -> usize {
        self.lock().len()
    }

    /// Returns true when no client is connected.
    pub fn is_empty(&self) -> bool {
        self.lock().is_empty()
    }

    fn broadcast_filtered(&self, frames: &[OutFrame], include: impl Fn(ClientId) -> bool) -> usize {
        let mut clients = self.lock();
        let targets: Vec<_> = clients.keys().copied().filter(|&c| include(c)).collect();
        targets
            .into_iter()
            .filter(|&client| Self::send_locked(&mut clients, client, frames))
            .count()
    }

    fn send_locked(
        clients: &mut HashMap<ClientId, ClientSlot>,
        client: ClientId,
        frames: &[OutFrame],
    ) -> bool {
        let Some(slot) = clients.get(&client) else {
            return false;
        };
        for frame in frames {
            match slot.queue.try_send(frame.clone()) {
                Ok(()) => {}
                Err(TrySendError::Full(_)) => {
                    warn!(%client, "send queue full; disconnecting slow client");
                    Self::remove_locked(clients, client, DisconnectReason::SlowConsumer);
                    return false;
                }
                Err(TrySendError::Closed(_)) => {
                    clients.remove(&client);
                    return false;
                }
            }
        }
        true
    }

    fn remove_locked(
        clients: &mut HashMap<ClientId, ClientSlot>,
        client: ClientId,
        reason: DisconnectReason,
    ) -> bool {
        match clients.remove(&client) {
            Some(slot) => {
                *slot.reason.lock().unwrap_or_else(|e| e.into_inner()) = Some(reason);
                slot.close.notify_one();
                true
            }
            None => false,
        }
    }

    fn lock(&self) -> std::sync::MutexGuard<'_, HashMap<ClientId, ClientSlot>> {
        // A panic while holding the lock cannot leave the map inconsistent.
        self.clients.lock().unwrap_or_else(|e| e.into_inner())
    }
}

/// A listening GMX server. Dropping it closes every connection.
#[derive(Debug)]
pub struct Server {
    local_addr: SocketAddr,
    hub: Hub,
    events: mpsc::Receiver<ServerEvent>,
    accept: JoinHandle<()>,
}

impl Server {
    /// Binds and starts accepting connections.
    ///
    /// Must be called within a tokio runtime.
    pub async fn bind(addr: impl ToSocketAddrs, config: ServerConfig) -> io::Result<Self> {
        let listener = TcpListener::bind(addr).await?;
        let local_addr = listener.local_addr()?;
        let hub = Hub::default();
        let (events_tx, events) = mpsc::channel(config.event_queue.max(1));
        let accept = tokio::spawn(accept_loop(listener, hub.clone(), events_tx, config));
        Ok(Self {
            local_addr,
            hub,
            events,
            accept,
        })
    }

    /// The address the server listens on.
    pub fn local_addr(&self) -> SocketAddr {
        self.local_addr
    }

    /// A handle for sending to clients.
    pub fn hub(&self) -> Hub {
        self.hub.clone()
    }

    /// Waits for the next event.
    pub async fn next_event(&mut self) -> Option<ServerEvent> {
        self.events.recv().await
    }
}

impl Drop for Server {
    fn drop(&mut self) {
        // Dropping the accept task's JoinSet aborts every client task.
        self.accept.abort();
    }
}

async fn accept_loop(
    listener: TcpListener,
    hub: Hub,
    events: mpsc::Sender<ServerEvent>,
    config: ServerConfig,
) {
    let mut tasks = JoinSet::new();
    let mut next_id = 0u64;
    loop {
        tokio::select! {
            accepted = listener.accept() => match accepted {
                Ok((stream, peer)) => {
                    let client = ClientId(next_id);
                    next_id += 1;
                    let (queue, outgoing) = mpsc::channel(config.client_queue_frames.max(1));
                    let reason = Arc::new(Mutex::new(None));
                    let close = Arc::new(Notify::new());
                    hub.lock().insert(client, ClientSlot {
                        queue,
                        reason: reason.clone(),
                        close: close.clone(),
                    });
                    tasks.spawn(run_client(ClientTask {
                        client,
                        peer,
                        hub: hub.clone(),
                        events: events.clone(),
                        outgoing,
                        reason,
                        close,
                        max_frame_bytes: config.max_frame_bytes,
                    }, stream));
                }
                Err(error) => {
                    // Usually a transient resource limit; avoid spinning.
                    warn!(%error, "accept failed");
                    tokio::time::sleep(Duration::from_millis(100)).await;
                }
            },
            Some(_) = tasks.join_next(), if !tasks.is_empty() => {}
        }
    }
}

struct ClientTask {
    client: ClientId,
    peer: SocketAddr,
    hub: Hub,
    events: mpsc::Sender<ServerEvent>,
    outgoing: mpsc::Receiver<OutFrame>,
    reason: Arc<Mutex<Option<DisconnectReason>>>,
    close: Arc<Notify>,
    max_frame_bytes: usize,
}

impl ClientTask {
    fn removal_reason(&self) -> DisconnectReason {
        let reason = self.reason.lock().unwrap_or_else(|e| e.into_inner()).take();
        reason.unwrap_or(DisconnectReason::Kicked)
    }
}

/// Most frames written before one flush, so a burst is batched.
const MAX_BATCH: usize = 64;

async fn run_client(mut task: ClientTask, stream: TcpStream) {
    let client = task.client;
    let reason = match Connection::new(stream, task.max_frame_bytes) {
        Err(error) => DisconnectReason::Error(error.to_string()),
        Ok(mut conn) => {
            let connected = ServerEvent::Connected {
                client,
                peer: task.peer,
            };
            if task.events.send(connected).await.is_err() {
                return;
            }
            debug!(%client, peer = %task.peer, "connected");
            match serve(&mut task, &mut conn).await {
                Some(reason) => reason,
                None => return,
            }
        }
    };
    Hub::remove_locked(&mut task.hub.lock(), client, reason.clone());
    debug!(%client, %reason, "disconnected");
    let _ = task
        .events
        .send(ServerEvent::Disconnected { client, reason })
        .await;
}

/// Runs a connection until it ends. `None` means the server is gone.
async fn serve(task: &mut ClientTask, conn: &mut Connection) -> Option<DisconnectReason> {
    let close = task.close.clone();
    loop {
        tokio::select! {
            () = close.notified() => return Some(task.removal_reason()),
            inbound = conn.recv() => match inbound {
                None => return Some(DisconnectReason::Closed),
                Some(Err(error)) => return Some(DisconnectReason::Error(error.to_string())),
                Some(Ok(inbound)) => {
                    if let Inbound::Dropped(error) = &inbound {
                        warn!(client = %task.client, %error, "dropped inbound frame");
                    }
                    let event = ServerEvent::Received { client: task.client, inbound };
                    task.events.send(event).await.ok()?;
                }
            },
            frame = task.outgoing.recv() => match frame {
                None => return Some(task.removal_reason()),
                Some(frame) => {
                    let write = async {
                        conn.feed(frame).await?;
                        for _ in 1..MAX_BATCH {
                            let Ok(frame) = task.outgoing.try_recv() else { break };
                            conn.feed(frame).await?;
                        }
                        conn.flush().await
                    };
                    // A peer that stops reading blocks the write; removal
                    // from the hub must still close the connection.
                    tokio::select! {
                        result = write => if let Err(error) = result {
                            return Some(DisconnectReason::Error(error.to_string()));
                        },
                        () = close.notified() => return Some(task.removal_reason()),
                    }
                }
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;
    use tokio::io::AsyncReadExt;
    use tokio::time::timeout;

    const WAIT: Duration = Duration::from_secs(5);

    async fn event(server: &mut Server) -> ServerEvent {
        timeout(WAIT, server.next_event())
            .await
            .expect("event in time")
            .expect("server running")
    }

    async fn connect(server: &mut Server) -> (Connection, ClientId) {
        let conn = Connection::connect(server.local_addr(), DEFAULT_MAX_FRAME_BYTES)
            .await
            .unwrap();
        match event(server).await {
            ServerEvent::Connected { client, peer } => {
                assert_eq!(peer, conn.local_addr().unwrap());
                (conn, client)
            }
            other => panic!("{other:?}"),
        }
    }

    async fn recv_text(conn: &mut Connection) -> String {
        let inbound = timeout(WAIT, conn.recv()).await.unwrap().unwrap().unwrap();
        inbound.text().unwrap().into_owned()
    }

    #[tokio::test]
    async fn events_send_and_broadcast() {
        let mut server = Server::bind("127.0.0.1:0", ServerConfig::default())
            .await
            .unwrap();
        let hub = server.hub();
        let (mut a, id_a) = connect(&mut server).await;
        let (mut b, id_b) = connect(&mut server).await;
        assert_eq!(hub.clients(), [id_a, id_b]);

        a.send(OutFrame::new("LIST_LAYOUTS")).await.unwrap();
        assert_eq!(
            event(&mut server).await,
            ServerEvent::Received {
                client: id_a,
                inbound: Inbound::Frame(b"LIST_LAYOUTS".to_vec()),
            }
        );

        assert!(hub.send(id_a, &[OutFrame::new("one")]));
        assert_eq!(recv_text(&mut a).await, "one");
        assert_eq!(hub.broadcast(&[OutFrame::new("all")]), 2);
        assert_eq!(recv_text(&mut a).await, "all");
        assert_eq!(recv_text(&mut b).await, "all");
        assert_eq!(hub.broadcast_except(id_a, &[OutFrame::new("not a")]), 1);
        assert_eq!(recv_text(&mut b).await, "not a");

        drop(a);
        assert_eq!(
            event(&mut server).await,
            ServerEvent::Disconnected {
                client: id_a,
                reason: DisconnectReason::Closed,
            }
        );
        assert_eq!(hub.clients(), [id_b]);
        assert!(!hub.send(id_a, &[OutFrame::new("gone")]));
    }

    #[tokio::test]
    async fn disconnect_closes_the_socket() {
        let mut server = Server::bind("127.0.0.1:0", ServerConfig::default())
            .await
            .unwrap();
        let (mut conn, client) = connect(&mut server).await;
        assert!(server.hub().disconnect(client));
        assert!(!server.hub().disconnect(client));
        assert_eq!(
            event(&mut server).await,
            ServerEvent::Disconnected {
                client,
                reason: DisconnectReason::Kicked,
            }
        );
        assert!(timeout(WAIT, conn.recv()).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn slow_consumer_is_disconnected() {
        let config = ServerConfig {
            client_queue_frames: 4,
            ..ServerConfig::default()
        };
        let mut server = Server::bind("127.0.0.1:0", config).await.unwrap();
        // A raw socket that never reads, so the queue backs up once the
        // kernel buffers fill.
        let mut stalled = TcpStream::connect(server.local_addr()).await.unwrap();
        let ServerEvent::Connected { client, .. } = event(&mut server).await else {
            panic!()
        };
        let hub = server.hub();
        let big = OutFrame::new(&"x".repeat(64 * 1024));
        let mut sent = 0;
        while hub.send(client, std::slice::from_ref(&big)) {
            sent += 1;
            assert!(sent < 10_000, "queue never filled");
            tokio::task::yield_now().await;
        }
        assert_eq!(
            event(&mut server).await,
            ServerEvent::Disconnected {
                client,
                reason: DisconnectReason::SlowConsumer,
            }
        );
        // The socket is closed once its buffered data is drained.
        let mut sink = Vec::new();
        timeout(WAIT, stalled.read_to_end(&mut sink))
            .await
            .unwrap()
            .unwrap();
    }

    #[tokio::test]
    async fn dropping_the_server_closes_connections() {
        let mut server = Server::bind("127.0.0.1:0", ServerConfig::default())
            .await
            .unwrap();
        let (mut conn, _) = connect(&mut server).await;
        drop(server);
        match timeout(WAIT, conn.recv()).await.unwrap() {
            None | Some(Err(_)) => {}
            Some(Ok(inbound)) => panic!("unexpected {inbound:?}"),
        }
    }
}
