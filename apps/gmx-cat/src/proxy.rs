//! `gmx-cat proxy`: relay connections to a server and record both
//! directions.

use std::io;
use std::path::PathBuf;
use std::process::ExitCode;

use gmx_net::capture::Direction;
use gmx_net::{Connection, ConnectionReader, ConnectionWriter, Inbound, OutFrame};
use tokio::net::TcpListener;
use tracing::{info, warn};

use crate::Fail;
use crate::session::Recorder;

/// Arguments for `proxy`.
#[derive(clap::Args, Debug)]
pub struct ProxyArgs {
    /// Address to accept clients on, `host:port`.
    #[arg(long, value_name = "ADDR")]
    pub listen: String,
    /// Server to relay to, `host:port`.
    #[arg(long, value_name = "ADDR")]
    pub upstream: String,
    /// Capture file to write.
    #[arg(long, value_name = "FILE")]
    pub record: PathBuf,
    /// Largest accepted frame, in bytes, in either direction.
    #[arg(long, default_value_t = gmx_proto::DEFAULT_MAX_FRAME_BYTES)]
    pub max_frame_bytes: usize,
}

pub async fn run(args: ProxyArgs) -> Result<ExitCode, Fail> {
    let recorder = Recorder::create(&args.record)
        .map_err(|e| Fail::Io(format!("{}: {e}", args.record.display())))?;
    let listener = TcpListener::bind(&args.listen)
        .await
        .map_err(|e| Fail::Io(format!("{}: {e}", args.listen)))?;
    let local = listener.local_addr().map_err(|e| Fail::Io(e.to_string()))?;
    eprintln!(
        "gmx-cat: relaying {local} to {}, recording to {}; press Ctrl-C to stop",
        args.upstream,
        args.record.display()
    );

    let mut next_id = 0u32;
    let mut relays = tokio::task::JoinSet::new();
    loop {
        tokio::select! {
            accepted = listener.accept() => {
                let (stream, peer) = match accepted {
                    Ok(accepted) => accepted,
                    Err(error) => {
                        warn!(%error, "accept failed");
                        continue;
                    }
                };
                let id = next_id;
                next_id += 1;
                let recorder = recorder.clone();
                let upstream = args.upstream.clone();
                let max = args.max_frame_bytes;
                relays.spawn(async move {
                    info!(conn = id, %peer, "client connected");
                    if let Err(error) = relay(id, stream, &upstream, max, &recorder).await {
                        warn!(conn = id, %error, "relay ended with an error");
                    }
                    if let Err(error) = recorder.close(id) {
                        warn!(conn = id, %error, "cannot write capture");
                    }
                    info!(conn = id, "connection closed");
                });
            }
            Some(_) = relays.join_next(), if !relays.is_empty() => {}
            _ = tokio::signal::ctrl_c() => break,
        }
    }
    eprintln!("gmx-cat: stopped after {next_id} connections");
    Ok(ExitCode::SUCCESS)
}

async fn relay(
    id: u32,
    stream: tokio::net::TcpStream,
    upstream: &str,
    max_frame_bytes: usize,
    recorder: &Recorder,
) -> io::Result<()> {
    let client = Connection::new(stream, max_frame_bytes)?;
    let server = Connection::connect(upstream, max_frame_bytes).await?;
    recorder.open(id, server.peer())?;
    let (client_rx, client_tx) = client.into_split();
    let (server_rx, server_tx) = server.into_split();
    // When one side finishes sending, half-close toward the other so it sees
    // end of input, then keep relaying the replies.
    let (to_server, to_client) = tokio::join!(
        pump(id, Direction::ToServer, client_rx, server_tx, recorder),
        pump(id, Direction::ToClient, server_rx, client_tx, recorder),
    );
    to_server.and(to_client)
}

async fn pump(
    id: u32,
    dir: Direction,
    mut from: ConnectionReader,
    mut to: ConnectionWriter,
    recorder: &Recorder,
) -> io::Result<()> {
    while let Some(inbound) = from.recv().await {
        let inbound = inbound?;
        recorder.inbound(id, dir, &inbound)?;
        match &inbound {
            Inbound::Frame(bytes) => to.send(OutFrame::from_payload(bytes)).await?,
            Inbound::Dropped(error) => {
                warn!(conn = id, %dir, %error, "not relaying an oversized frame")
            }
        }
    }
    Ok(())
}
