package services
{

	import flash.errors.IOError;
	import flash.events.*;
	import flash.net.XMLSocket;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	public class SocketConnection extends EventDispatcher
	{		
		private var _id:String = "localhost";
		public function get id():String { return _id; }
		public function set id( val:String ):void {
			_id = val;
		}
		private var _host:String = "localhost";
		public function get host():String { return _host; }
		public function set host( ip:String ):void {
			_host = ip;
		}
		private var _port:uint = 12242;
		public function get port():uint { return _port; }
		public function set port( p:uint ):void {
			_port = p;
		}
		public function get connected():Boolean { return _socket.connected; }
		private var _socket:XMLSocket;
		public function get socket():XMLSocket { return _socket; }
		
		public function SocketConnection() {
			_socket = new XMLSocket();
			addListeners(socket);
		}
		
		public function connect(host:String = null, port:int = -1):void {
			if (port != -1) {
				_port = port;
			}
			if (host != null) {
				_host = host;
			}
			_socket.connect(_host, _port);
		}
		
		
		public function send( data:Object ):void {
        	try{
				_socket.send(data);
			}catch(e:IOError){
				trace("WARNING: Error sending on socket: " + e.message );
			}
		}
		private function dataHandler(event:DataEvent):void {
			//trace("dataHandler: " + event);
			if (event != null && GMXMain.debugReceive == true && GMXMain.testing == true) {
				trace("======MESSAGE RECEIVED=======\n--socket host=" + _host + "  port=" + _port + "--\n" + event.data + "\n===== END RECEIVED ========");
			}
			SocketController.dispatcher.dispatchEvent( event ); 
		}
		
		private function addListeners(sock:XMLSocket):void {
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			sock.addEventListener(Event.CLOSE, closeHandler);
			sock.addEventListener(Event.CONNECT, connectedHandler); 
			sock.addEventListener(DataEvent.DATA, dataHandler);
			sock.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			sock.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		}
		
		private function connectedHandler(event:Event):void {
			trace("connect handler reached");
			GMXMain.do_ISISRefresh("");
		}
		
		private function closeHandler(event:Event):void {
			trace("closeHandler: " + event);
			Alert.show("Connection Interrupted to (port="+ _port +")!  Attempt reconnect?", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
		}
		private function alertClick(event:CloseEvent):void {
            if (event.detail==Alert.YES)
				this.connect();
        }
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("ioErrorHandler: " + event);
			Alert.show("Connection Not established to port="+ _port +"!  Press 'ok' to attempt reconnect", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
		}
		
		private function progressHandler(event:ProgressEvent):void {
			trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}
	}
}