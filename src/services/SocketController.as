package services
{
	import __AS3__.vec.Vector;
	
	import flash.errors.IOError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	public class SocketController extends EventDispatcher
	{		
		public static var dispatcher:EventDispatcher = new EventDispatcher();
		
		private static var _sockets:Dictionary = new Dictionary(false);
		public static function addSocket(port:int, host:String, socketId:String):void {
			var socket:SocketConnection;
			if (_sockets[socketId] != null) {
				socket = _sockets[socketId] as SocketConnection;
				if (socket.connected) {
					Alert.show("Attempted to add a socket that is already connected: port='" + port + "' host='" 
							+ host + "' socketID='" + socketId + "'");
					return;	
				}
			} else {
				socket = new SocketConnection();
				_sockets[socketId] = socket;
				socket.id = socketId;
			}
			socket.connect(host, port);
		}
		
		private static var _defaultHost:String = "localhost";
		public static function get testHost():String { return _defaultHost; }
		public static function set testHost(val:String):void { _defaultHost = val; }
		private static var _defaultPort:uint = 12242;
		public static function get testPort():uint { return _defaultPort; }
		public static function set testPort(val:uint):void { _defaultPort = val; }
		
		public static function init():void {
			
		}
		
		public static function send( data:Object, subscriptions:Vector.<String> = null ):void {
	        try {
				if (GMXMain.debugSend == true && GMXMain.testing == true) { trace("====SENDING MESSAGE====\n" + data + "\n===== END SENT ========"); }
				for each (var socket:SocketConnection in _sockets) {
					if (socket == null) { continue }
					//var socket = obj as XMLSocket;
					//if (socket.connected) {
					try {
						socket.send(data);	
					} catch (e:Error) {
						trace("Tried to send over a closed socket: " + e.message);
					}	
					//}
				}
				/*== not worrying about subscriptions yet ===
				for each (var socketId:String in subscriptions) {
					var socket:Socket = _sockets[socketID] as XMLSocket;
					if (socket.connected) {
						socket.send(data);
					}
				}*/
			} catch(e:IOError){
				trace( e );
			}
		}
	}
}