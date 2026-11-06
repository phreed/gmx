//! A client connection that keeps itself connected.

use std::fmt;
use std::net::SocketAddr;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use gmx_proto::{DEFAULT_MAX_FRAME_BYTES, Dialect, Message, Refresh};
use tokio::net::TcpStream;
use tokio::sync::mpsc;
use tokio::sync::mpsc::error::TrySendError;
use tokio::task::JoinHandle;
use tracing::{debug, warn};

use crate::codec::{Inbound, OutFrame};
use crate::connection::Connection;

/// Endpoint behavior.
#[derive(Clone, Debug)]
pub struct EndpointConfig {
    /// The dialect for [`Endpoint::send`] and the connect-time refresh.
    pub dialect: Dialect,
    /// Send `ISISRefresh` with an empty command after each connect, as the
    /// legacy client did.
    pub refresh_on_connect: bool,
    /// Largest accepted inbound frame.
    pub max_frame_bytes: usize,
    /// Frames that may wait to be written.
    pub queue_frames: usize,
    /// Delay before the first retry. Doubles per failure.
    pub min_backoff: Duration,
    /// Longest delay between retries.
    pub max_backoff: Duration,
    /// Time allowed for one connection attempt.
    pub connect_timeout: Duration,
}

impl Default for EndpointConfig {
    fn default() -> Self {
        Self {
            dialect: Dialect::Invoke,
            refresh_on_connect: true,
            max_frame_bytes: DEFAULT_MAX_FRAME_BYTES,
            queue_frames: 1024,
            min_backoff: Duration::from_millis(250),
            max_backoff: Duration::from_secs(10),
            connect_timeout: Duration::from_secs(5),
        }
    }
}

/// Something that happened on an endpoint.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum EndpointEvent {
    /// A connection was established.
    Connected {
        /// The server's address.
        peer: SocketAddr,
    },
    /// The server sent a frame.
    Received(Inbound),
    /// The connection ended. A reconnect follows.
    Disconnected {
        /// The I/O error, or `None` when the server closed cleanly.
        error: Option<String>,
        /// Frames that were queued and are discarded.
        discarded: usize,
    },
    /// A connection attempt failed.
    ConnectFailed {
        /// Why.
        error: String,
        /// Delay before the next attempt.
        retry_in: Duration,
    },
}

/// Why a frame was not queued.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SendError {
    /// There is no connection. GMX does not queue across reconnects, as
    /// stale edits could reach a later session.
    NotConnected,
    /// The write queue is full.
    QueueFull,
}

impl fmt::Display for SendError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotConnected => f.write_str("not connected"),
            Self::QueueFull => f.write_str("send queue full"),
        }
    }
}

impl std::error::Error for SendError {}

/// A connection to one GMX server that reconnects on failure.
///
/// Dropping the endpoint closes the connection.
#[derive(Debug)]
pub struct Endpoint {
    queue: mpsc::Sender<OutFrame>,
    events: mpsc::Receiver<EndpointEvent>,
    connected: Arc<AtomicBool>,
    dialect: Dialect,
    task: JoinHandle<()>,
}

impl Endpoint {
    /// Starts connecting to `addr`, a `host:port` string.
    ///
    /// Must be called within a tokio runtime.
    pub fn spawn(addr: impl Into<String>, config: EndpointConfig) -> Self {
        let (queue, outgoing) = mpsc::channel(config.queue_frames.max(1));
        let (events_tx, events) = mpsc::channel(1024);
        let connected = Arc::new(AtomicBool::new(false));
        let dialect = config.dialect;
        let task = tokio::spawn(run(
            addr.into(),
            config,
            outgoing,
            events_tx,
            connected.clone(),
        ));
        Self {
            queue,
            events,
            connected,
            dialect,
            task,
        }
    }

    /// Returns true while a connection is established.
    pub fn is_connected(&self) -> bool {
        self.connected.load(Ordering::Acquire)
    }

    /// Queues a frame.
    pub fn send_frame(&self, frame: OutFrame) -> Result<(), SendError> {
        if !self.is_connected() {
            return Err(SendError::NotConnected);
        }
        self.queue.try_send(frame).map_err(|error| match error {
            TrySendError::Full(_) => SendError::QueueFull,
            TrySendError::Closed(_) => SendError::NotConnected,
        })
    }

    /// Encodes a message in the configured dialect and queues it.
    pub fn send(&self, message: &Message) -> Result<(), SendError> {
        for frame in OutFrame::from_message(message, self.dialect) {
            self.send_frame(frame)?;
        }
        Ok(())
    }

    /// Waits for the next event.
    pub async fn next_event(&mut self) -> Option<EndpointEvent> {
        self.events.recv().await
    }
}

impl Drop for Endpoint {
    fn drop(&mut self) {
        self.task.abort();
    }
}

async fn run(
    addr: String,
    config: EndpointConfig,
    mut outgoing: mpsc::Receiver<OutFrame>,
    events: mpsc::Sender<EndpointEvent>,
    connected: Arc<AtomicBool>,
) {
    let mut backoff = config.min_backoff;
    loop {
        let attempt = tokio::time::timeout(config.connect_timeout, TcpStream::connect(&addr)).await;
        let connection = match attempt {
            Ok(Ok(stream)) => Connection::new(stream, config.max_frame_bytes),
            Ok(Err(error)) => Err(error),
            Err(_) => Err(std::io::Error::new(
                std::io::ErrorKind::TimedOut,
                "connection attempt timed out",
            )),
        };
        let mut conn = match connection {
            Ok(conn) => conn,
            Err(error) => {
                let event = EndpointEvent::ConnectFailed {
                    error: error.to_string(),
                    retry_in: backoff,
                };
                if events.send(event).await.is_err() {
                    return;
                }
                tokio::time::sleep(backoff).await;
                backoff = (backoff * 2).min(config.max_backoff);
                continue;
            }
        };
        backoff = config.min_backoff;
        let peer = conn.peer();
        debug!(%peer, "endpoint connected");
        connected.store(true, Ordering::Release);
        if events
            .send(EndpointEvent::Connected { peer })
            .await
            .is_err()
        {
            return;
        }

        let mut error = None;
        if config.refresh_on_connect {
            let refresh = Message::Refresh(Refresh::default());
            if let Err(e) = conn.send_message(&refresh, config.dialect).await {
                error = Some(e.to_string());
            }
        }
        if error.is_none() {
            match session(&mut conn, &mut outgoing, &events).await {
                Session::Ended(e) => error = e,
                Session::Abandoned => return,
            }
        }

        connected.store(false, Ordering::Release);
        let mut discarded = 0;
        while outgoing.try_recv().is_ok() {
            discarded += 1;
        }
        if discarded > 0 {
            warn!(%peer, discarded, "discarding frames queued for a closed connection");
        }
        let event = EndpointEvent::Disconnected { error, discarded };
        if events.send(event).await.is_err() {
            return;
        }
        // Pause before reconnecting, so a server that accepts and closes
        // at once is not hammered.
        tokio::time::sleep(config.min_backoff).await;
    }
}

enum Session {
    /// The connection ended, with an error if it failed.
    Ended(Option<String>),
    /// The endpoint was dropped.
    Abandoned,
}

async fn session(
    conn: &mut Connection,
    outgoing: &mut mpsc::Receiver<OutFrame>,
    events: &mpsc::Sender<EndpointEvent>,
) -> Session {
    loop {
        tokio::select! {
            inbound = conn.recv() => match inbound {
                None => return Session::Ended(None),
                Some(Err(error)) => return Session::Ended(Some(error.to_string())),
                Some(Ok(inbound)) => {
                    if events.send(EndpointEvent::Received(inbound)).await.is_err() {
                        return Session::Abandoned;
                    }
                }
            },
            frame = outgoing.recv() => match frame {
                None => return Session::Abandoned,
                Some(frame) => {
                    if let Err(error) = conn.send(frame).await {
                        return Session::Ended(Some(error.to_string()));
                    }
                }
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::server::{Server, ServerConfig, ServerEvent};
    use tokio::time::timeout;

    const WAIT: Duration = Duration::from_secs(5);

    fn fast() -> EndpointConfig {
        EndpointConfig {
            min_backoff: Duration::from_millis(20),
            max_backoff: Duration::from_millis(80),
            ..EndpointConfig::default()
        }
    }

    async fn next(endpoint: &mut Endpoint) -> EndpointEvent {
        timeout(WAIT, endpoint.next_event()).await.unwrap().unwrap()
    }

    async fn server_event(server: &mut Server) -> ServerEvent {
        timeout(WAIT, server.next_event()).await.unwrap().unwrap()
    }

    #[tokio::test]
    async fn sends_refresh_on_connect_then_exchanges_frames() {
        let mut server = Server::bind("127.0.0.1:0", ServerConfig::default())
            .await
            .unwrap();
        let mut endpoint = Endpoint::spawn(server.local_addr().to_string(), fast());
        assert!(matches!(
            next(&mut endpoint).await,
            EndpointEvent::Connected { .. }
        ));
        assert!(endpoint.is_connected());

        let ServerEvent::Connected { client, .. } = server_event(&mut server).await else {
            panic!()
        };
        let ServerEvent::Received { inbound, .. } = server_event(&mut server).await else {
            panic!()
        };
        assert_eq!(
            inbound.decode(),
            Some(Ok(Message::Refresh(Refresh::default())))
        );

        endpoint
            .send(&Message::Command(gmx_proto::Command::ListRecords))
            .unwrap();
        let ServerEvent::Received { inbound, .. } = server_event(&mut server).await else {
            panic!()
        };
        assert_eq!(inbound.text().as_deref(), Some("LIST_RECORDS"));

        server.hub().send(client, &[OutFrame::new("RECORDS:[]")]);
        assert_eq!(
            next(&mut endpoint).await,
            EndpointEvent::Received(Inbound::Frame(b"RECORDS:[]".to_vec()))
        );
    }

    #[tokio::test]
    async fn retries_until_a_server_appears_and_reconnects_after_loss() {
        // Reserve a port, then free it so the first attempts fail.
        let port = std::net::TcpListener::bind("127.0.0.1:0")
            .unwrap()
            .local_addr()
            .unwrap()
            .port();
        let addr = format!("127.0.0.1:{port}");
        let mut endpoint = Endpoint::spawn(addr.clone(), fast());
        assert!(matches!(
            next(&mut endpoint).await,
            EndpointEvent::ConnectFailed { .. }
        ));
        assert_eq!(
            endpoint.send(&Message::Refresh(Refresh::default())),
            Err(SendError::NotConnected)
        );

        let server = Server::bind(&addr, ServerConfig::default()).await.unwrap();
        loop {
            match next(&mut endpoint).await {
                EndpointEvent::Connected { .. } => break,
                EndpointEvent::ConnectFailed { retry_in, .. } => {
                    assert!(retry_in <= Duration::from_millis(80), "backoff is capped");
                }
                other => panic!("{other:?}"),
            }
        }

        drop(server);
        assert!(matches!(
            next(&mut endpoint).await,
            EndpointEvent::Disconnected { .. }
        ));
        assert!(!endpoint.is_connected());

        let _server = Server::bind(&addr, ServerConfig::default()).await.unwrap();
        loop {
            match next(&mut endpoint).await {
                EndpointEvent::Connected { .. } => break,
                EndpointEvent::ConnectFailed { .. } => {}
                other => panic!("{other:?}"),
            }
        }
    }
}
