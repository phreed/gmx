package generics
{
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import interfaces.UIComponent_ISIS;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	
	/**
	 * The video widget has its own socket and communication protocol.
	 * It only needs two attributes: host and port
	 * The luid is an optional standard field.
	 * width and height should always be specified as the map is a 
	 * window into an unlimited area.
	 * 
	 * <Video luid="map_1" ruid="dog" width="56mm" height="43mm">
	 *   <field name="host" fid="host_fid" value="192.168.5.101"/>
	 *   <field name="port" fid="port_fid" value="12202"/>
	 * </Video>
	 * 
	 * The other standard attributes are not typically used by the video.
	 * 
	 * When "new Field(fid)" is called, it attaches the field to the record on top
	 * of the GMXDictionaries.recordStack
	 */
	public class Video_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["host", "port", "cameramove"]; }
		override public function get defaultValues():Array { return ["", "-1", "0"]; }
		
		private var _iRobotVersion:Boolean = false;
		
		private var _videoSocket:Socket;
		private var _loader:Loader;
		private var _timer:Timer;
		private var _decumulator:int = 0;
		
		public static const CAM_FPS:Number = 50;
		public static const DELAY:Number = 1000.0 / CAM_FPS;
		public static const MAX_FRAME_DELAY:int = CAM_FPS;
		
		public function Video_X() {
			super();
			this.width = 100;
			this.height = 100;
		}
		
		override public function build(xml:XML):void
		{
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			if (xml.@static.toString() == "false") {
				Alert.show("WARNING: Video layout with static=false ... it is highly recommended that static=true !");
			} else {
				if (!GMXMain.staticComponents.contains(this)) { GMXMain.staticComponents.addItem(this); }
			}
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			// draw area for detecting mouse events
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(0, 0, this.width, this.height);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			invalidateProperties();
		}
		
		public var host:Field;
		public var port:Field;
		public var cameramove:Field;
		
		/**
		 * As properties are changed it may be necessary to reconnect the port
		 */
		private var _hostValue:String = "";
		private var _portValue:String = "-1";
		private var _static:Boolean = false;
		
		override protected function createChildren():void {
			super.createChildren();
			_videoSocket = new Socket();
			addListeners(_videoSocket);
			_videoSocket.endian = Endian.LITTLE_ENDIAN;
			
			_loader = new Loader();
			this.addChild(_loader);
			_timer = new Timer(DELAY);
			_timer.addEventListener(TimerEvent.TIMER, time);
		}
				
		override protected function measure():void {
			super.measure();
			if (_loader == null || _loader.content == null) { return; } 
			
			this.measuredHeight = _loader.content.height;
			this.measuredWidth = _loader.content.width;
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			var needReconnect:Boolean = false;
			if (host != null && _hostValue != host.value) {
				needReconnect = true;
				_hostValue = host.value;
				return;
			}  
			if (port != null && _portValue != port.value ) {
				needReconnect = true;
				_portValue = port.value;
			    return;
			}
			//camermove field is not used by this component to update its display, only to communicate
			//user interaction to the service
			if (needReconnect && _portValue != "-1") {
				reconnect();
			}
		}

			override public function disintegrate():void {
			return; // this should always be a static component!
			/*
			for (var i:int = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) {
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			if (GMXMain.staticComponents.contains(this)) { return; }
			if (host != null) { host.removeComponentRequiringUpdate(this); host = null; }
			if (port != null) { port.removeComponentRequiringUpdate(this); port = null; }
			if (cameramove != null) { cameramove.removeComponentRequiringUpdate(this); cameramove = null; }
			_record = null;
			*/
		}
		
// ==== BEGIN cameraMove stuff (as of 4/21/2011, this is simply an idea that we had toyed with--the idea of ==========
// being able to click and drag on the video component and have it send messages that could be used to
// move the camera
		private var _downPoint:Point = new Point(0, 0);
		private var _currentPoint:Point = new Point(0, 0);
		private var _mouseDown:Boolean = false;
		private function mouseDown(event:MouseEvent):void {
			_downPoint.x = mouseX;
			_downPoint.y = mouseY;
			_currentPoint.x = mouseX;
			_currentPoint.y = mouseY;
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			_mouseDown = true;
		}
		
		private function mouseMove(event:MouseEvent):void {
			_currentPoint.x = mouseX;
			_currentPoint.y = mouseY;
			
			cameramove.value = "|MC|:ref:" + _downPoint.x + ":" + _downPoint.y + "|:tgt:" + _currentPoint.x + ":" + _currentPoint.y;
			dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, cameramove, true, true));
		}
		
		private function mouseUp(event:MouseEvent):void {
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			_mouseDown = false;
		}		
// ========END cameraMove stuff =====================================================================

// ========BEGIN iRobot Camera stuff ================================================================
		private function time(event:TimerEvent):void {
			if (!_videoSocket.connected) { return; }
		
			_decumulator--;
			//trace(_decumulator);
			if (_decumulator < 1) {
				// send out a 'C' to ask for an image (THIS INDICATES TO THE IROBOT to send a new image)
				_videoSocket.writeByte(99);
				_videoSocket.flush();
				// reset decumulator
				_decumulator = MAX_FRAME_DELAY;
			}
		}
		
		private var _frameLoaded:Boolean = false;
		private var _imageSize:int = 0;
		private var _imageData:ByteArray = new ByteArray();
		private function onSocketData(event:ProgressEvent):void {
			//if (_loader.content != null) { this.removeChild(_loader) }
			//trace("image size: " + _imageSize + "   image data length: " + _imageData.length);
			if (_imageSize == 0) {
				//if (_loader.content != null) { _loaderBackup = Bitmap(_loader.content); }
				//trace("New image");
				_imageSize = _videoSocket.readUnsignedInt();
				//trace("  size: " + _imageSize);
				if(_videoSocket.bytesAvailable == 0) {
					return;
				}
			}
			
			var byteArray:ByteArray = new ByteArray();
			try {
				//trace("Reading bytes");
				_videoSocket.readBytes(byteArray, 0, _videoSocket.bytesAvailable);
				//trace("  Got " + byteArray.length + " bytes");
				//_loader.loadBytes(byteArray);
				_imageData.writeBytes(byteArray, 0, byteArray.length);
				//trace("  Received so far: " + _imageData.length);
				if (_imageData.length == _imageSize) {
					//trace("Got whole image");
					_loader.loadBytes(_imageData);
					_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
					_imageData = new ByteArray();
					_imageSize = 0;
					//trace("IMAGE DONE");
					_decumulator = 0; // indicates another frame wanted when the timer is hit
				}
			} catch(e:Error) {
				//trace("LOST CONNECTION: " + e.message);
				//_videoSocket.close();
			}
		}
		
		private function loadComplete(event:Event):void {
			if (!_videoSocket.connected) { return; }
			
			_loader.width = this.width;
			_loader.height = this.height;
		}
		
//===========SOCKET HANDLERS==============================================================
		private function addListeners(sock:Socket):void {
			sock.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			sock.addEventListener(Event.CLOSE, closeHandler); 
			sock.addEventListener(Event.CONNECT, connectedHandler); 
			sock.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function connectedHandler(event:Event):void {
			trace("VIDEO SOCKET: connect handler reached");
			_timer.start();
			//GMXMain.do_refresh_ISISFormLayout();
		}
		
		private function closeHandler(event:Event):void {
			trace("VIDEO SOCKET: closeHandler: " + event);
			_timer.stop();
			
			if (_iRobotVersion) {
				Alert.show("VIDEO Connection Interrupted!  Attempt reconnect?", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
			}
		}
		private function alertClick(event:CloseEvent):void {
            if (event.detail==Alert.YES)
				reconnect();
        }
		
		private function reconnect():void {
			if (_videoSocket.connected) {
				_videoSocket.close();
			}
			trace("Video component attempted connect to: " + _hostValue + " port=" + _portValue);
			_videoSocket.connect(_hostValue, parseInt(_portValue));
			//trace("Currently, host = " + host);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("VIDEO SOCKET: ioErrorHandler: " + event);
			_timer.stop();
			if (_iRobotVersion) {
				Alert.show("VIDEO Connection not established!  Press 'ok' to attempt reconnect", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			_timer.stop();
			trace("VIDEO SOCKET: securityErrorHandler: " + event);
		}
	}
}