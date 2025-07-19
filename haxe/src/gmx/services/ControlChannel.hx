package gmx.services;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import sys.net.Socket;
import sys.net.Host;
import haxe.Timer;

/**
 * ControlChannel - Network communication service
 * Converted from ActionScript to Haxe for cross-platform socket communication
 * Handles connection to control server and message exchange
 */
class ControlChannel {

    // Connection properties
    private var socket:Socket;
    private var host:String;
    private var port:Int;
    private var isConnected:Bool = false;
    private var isConnecting:Bool = false;

    // Message handling
    private var messageBuffer:BytesOutput;
    private var onMessageReceived:String->Void;
    private var onConnectionStatusChanged:(Bool)->Void;

    // Reconnection handling
    private var reconnectTimer:Timer;
    private var reconnectInterval:Float = 5.0; // seconds
    private var maxReconnectAttempts:Int = 10;
    private var reconnectAttempts:Int = 0;
    private var autoReconnect:Bool = true;

    // Message queue for when disconnected
    private var messageQueue:Array<String>;
    private var maxQueueSize:Int = 100;

    public function new(?host:String, ?port:Int) {
        this.host = host != null ? host : "localhost";
        this.port = port != null ? port : 12141;

        this.messageBuffer = new BytesOutput();
        this.messageQueue = new Array<String>();

        trace('ControlChannel initialized for $host:$port');
    }

    /**
     * Connect to the control server
     */
    public function connect():Void {
        if (isConnected || isConnecting) {
            trace("Already connected or connecting");
            return;
        }

        isConnecting = true;
        trace('Attempting to connect to $host:$port');

        try {
            // Create new socket
            socket = new Socket();
            socket.setTimeout(5.0); // 5 second timeout

            // Connect to server
            var hostObj = new Host(host);
            socket.connect(hostObj, port);

            // Set non-blocking mode for real-time operation
            socket.setBlocking(false);

            isConnected = true;
            isConnecting = false;
            reconnectAttempts = 0;

            trace("Successfully connected to control server");

            // Notify connection status change
            if (onConnectionStatusChanged != null) {
                onConnectionStatusChanged(true);
            }

            // Send any queued messages
            flushMessageQueue();

        } catch (e:Dynamic) {
            trace('Connection failed: $e');
            isConnecting = false;
            handleConnectionError();
        }
    }

    /**
     * Disconnect from the control server
     */
    public function disconnect():Void {
        if (socket != null) {
            try {
                socket.close();
            } catch (e:Dynamic) {
                trace('Error closing socket: $e');
            }
            socket = null;
        }

        isConnected = false;
        isConnecting = false;

        // Stop reconnection timer
        if (reconnectTimer != null) {
            reconnectTimer.stop();
            reconnectTimer = null;
        }

        trace("Disconnected from control server");

        // Notify connection status change
        if (onConnectionStatusChanged != null) {
            onConnectionStatusChanged(false);
        }
    }

    /**
     * Send a message to the control server
     */
    public function sendMessage(message:String):Bool {
        if (!isConnected || socket == null) {
            // Queue message if not connected
            if (messageQueue.length < maxQueueSize) {
                messageQueue.push(message);
                trace('Message queued (not connected): ${message.substr(0, 50)}...');
            } else {
                trace("Message queue full, dropping message");
            }
            return false;
        }

        try {
            // Add message terminator
            var fullMessage = message + "\n";
            var bytes = Bytes.ofString(fullMessage);

            socket.output.writeBytes(bytes, 0, bytes.length);
            socket.output.flush();

            trace('Message sent: ${message.substr(0, 50)}...');
            return true;

        } catch (e:Dynamic) {
            trace('Error sending message: $e');
            handleConnectionError();
            return false;
        }
    }

    /**
     * Send XML data to the control server
     */
    public function sendXML(xml:Xml):Bool {
        if (xml == null) return false;
        return sendMessage(xml.toString());
    }

    /**
     * Update method called each frame to handle incoming messages
     */
    public function update(dt:Float):Void {
        if (!isConnected || socket == null) return;

        try {
            // Check for incoming data
            var input = socket.input;
            // available property removed in newer Haxe versions
            // Use try-catch approach to detect available data
            var available = 1024; // Default buffer size

            try {
                var buffer = Bytes.alloc(available);
                var bytesRead = input.readBytes(buffer, 0, available);

                if (bytesRead > 0) {
                    processIncomingData(buffer, bytesRead);
                }
            }

        } catch (e:Dynamic) {
            // Check if it's just no data available (non-blocking socket)
            var errorMsg = Std.string(e);
            if (errorMsg.indexOf("would block") == -1) {
                trace('Error reading from socket: $e');
                handleConnectionError();
            }
        }
    }

    /**
     * Process incoming data and extract complete messages
     */
    private function processIncomingData(buffer:Bytes, length:Int):Void {
        // Add to message buffer
        messageBuffer.writeBytes(buffer, 0, length);

        // Convert buffer to string and look for complete messages
        var bufferData = messageBuffer.getBytes();
        var dataString = bufferData.toString();

        // Split by newlines to get individual messages
        var messages = dataString.split("\n");

        // Process all complete messages (all but the last one)
        for (i in 0...(messages.length - 1)) {
            var message = StringTools.trim(messages[i]);
            if (message.length > 0) {
                handleIncomingMessage(message);
            }
        }

        // Keep the incomplete message (last part) in buffer
        var remaining = messages[messages.length - 1];
        messageBuffer = new BytesOutput();
        if (remaining.length > 0) {
            messageBuffer.writeString(remaining);
        }
    }

    /**
     * Handle a complete incoming message
     */
    private function handleIncomingMessage(message:String):Void {
        trace('Message received: ${message.substr(0, 50)}...');

        if (onMessageReceived != null) {
            onMessageReceived(message);
        }
    }

    /**
     * Handle connection errors and attempt reconnection
     */
    private function handleConnectionError():Void {
        disconnect();

        if (autoReconnect && reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            trace('Scheduling reconnection attempt $reconnectAttempts in $reconnectInterval seconds');

            reconnectTimer = Timer.delay(function() {
                connect();
            }, Std.int(reconnectInterval * 1000));
        } else {
            trace("Max reconnection attempts reached or auto-reconnect disabled");
        }
    }

    /**
     * Send all queued messages
     */
    private function flushMessageQueue():Void {
        while (messageQueue.length > 0 && isConnected) {
            var message = messageQueue.shift();
            if (!sendMessage(message)) {
                // If send fails, put message back at front of queue
                messageQueue.unshift(message);
                break;
            }
        }

        if (messageQueue.length == 0) {
            trace("Message queue flushed successfully");
        }
    }

    /**
     * Set callback for when messages are received
     */
    public function setMessageHandler(handler:String->Void):Void {
        onMessageReceived = handler;
    }

    /**
     * Set callback for connection status changes
     */
    public function setConnectionStatusHandler(handler:(Bool)->Void):Void {
        onConnectionStatusChanged = handler;
    }

    /**
     * Get connection status
     */
    public function getConnectionStatus():Bool {
        return isConnected;
    }

    /**
     * Set auto-reconnect behavior
     */
    public function setAutoReconnect(enabled:Bool):Void {
        autoReconnect = enabled;
    }

    /**
     * Set reconnection parameters
     */
    public function setReconnectionParams(interval:Float, maxAttempts:Int):Void {
        reconnectInterval = interval;
        maxReconnectAttempts = maxAttempts;
    }

    /**
     * Get number of queued messages
     */
    public function getQueuedMessageCount():Int {
        return messageQueue.length;
    }

    /**
     * Clear message queue
     */
    public function clearMessageQueue():Void {
        messageQueue = new Array<String>();
    }
}
