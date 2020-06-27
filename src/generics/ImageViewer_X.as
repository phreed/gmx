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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.Socket;
	import flash.net.URLRequest;
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
	 * <ImageViewer luid="imageViewer_1" ruid="imageViewer_1" width="56mm" height="43mm">
	 *   <field name="host" fid="host_fid" value="localhost"/>
	 *   <field name="port" fid="port_fid" value="12202"/>
	 * </ImageViewer>
	 * 
	 * The other standard attributes are not typically used by the video.
	 * 
	 * When "new Field(fid)" is called, it attaches the field to the record on top
	 * of the GMXDictionaries.recordStack
	 */
	public class ImageViewer_X extends UIComponent_ISIS implements IMultiField
	{	
		override public function get fieldNames():Array { return ["host","port","cameramove","imagepath"]; }
		override public function get defaultValues():Array { return ["0", "0", "0", ""]; }
		public static const DEFAULT_COMPONENT_WIDTH:Number = 100;
		public static const DEFAULT_COMPONENT_HEIGHT:Number = 100;
		
		private var _imageSocket:Socket;
		private var _loader:Loader;
		private var _mask:Sprite;
		private var _dimensionsDirty:Boolean = false;

		//private var _timer:Timer;
		//private var _decumulator:int = 0;
		
		public function ImageViewer_X() {
			super();
			_mask = new Sprite();
			this.addChild(_mask);
			this.width = DEFAULT_COMPONENT_WIDTH;
			this.height = DEFAULT_COMPONENT_HEIGHT;
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_dimensionsDirty = true;
		}
		
		override public function set width(val:Number):void {
			super.width = val;
			this.invalidateDisplayList();
			_dimensionsDirty = true;
		}
		override public function set height(val:Number):void {
			super.height = val;
			this.invalidateDisplayList();
			_dimensionsDirty = true;
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
			if (xml.@luid == undefined) {
				Alert.show("WARNING: Image layout without a luid!!! A luid is required in order to reuse the component, which "
							+ "is important so that you don't run into problems with socket connections!");
			}
			if (xml.@static.toString() == "false") {
				Alert.show("WARNING: Image layout with static=false ... it is highly recommended that static=true !");
			} else xml.@static = "true";
			GMXComponentBuilder.setStandardValues(xml, this);
			// draw area for detecting mouse events
			this.graphics.beginFill(0, 0);
			this.graphics.drawRect(0, 0, this.width, this.height);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			invalidateProperties();
		}
		
		override public function disintegrate():void {
			// this is a static component
			return;
		}
		
		// child components
		public var host:Field;
		private var _hostValue:String = "";
		private var _hostDirty:Boolean = false;
		
		public var port:Field;
		private var _portValue:String = "";
		private var _portDirty:Boolean = false;
		
		public var cameramove:Field;
		private var _cameramoveValue:String = "Track";
		private var _cameramoveDirty:Boolean = false;
		
		public var imagepath:Field;
		private var _imagepathValue:String = "";
		private var _imagepathDirty:Boolean = false;
		/**
		 * As properties are changed it may be necessary to reconnect the port
		 */
		private var _static:Boolean = false;
		
		override protected function createChildren():void {
			super.createChildren();
			_imageSocket = new Socket();
			addListeners(_imageSocket);
			_imageSocket.endian = Endian.LITTLE_ENDIAN;
			
			_loader = new Loader();
			_loader.mask = _mask;
			this.addChild(_loader);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fileIoErrorHandler);
			//_loader.load(new URLRequest("assets/foto.jpg"));
			//_loader.load(new URLRequest("assets/test.png"));
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			if (host != null && _hostValue != host.value) {
				_hostValue = host.value;
				_hostDirty = true;
			}  
			if (port != null && _portValue != port.value ) {
				_portValue = port.value;
				_portDirty = true;
			}
			if (_portDirty == true || _hostDirty == true) {
				if (port != null && host != null) { // make sure it at least has both fields
					reconnect();
				}
				_portDirty = false;
				_hostDirty = false;
			}
			if (imagepath != null && _imagepathValue != imagepath.value) {
				_imagepathValue = imagepath.value;
				if (_imagepathValue != "") {
					try {
						_loader.load(new URLRequest(_imagepathValue));
					} catch (e:Error) {
						Alert.show("WARNING: ImageViewer attempted to load image at path=" + _imagepathValue + ", but encountered the following error: " + e.message);
					}
				}
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			// add graphic area to catch mouse events
			if (_dimensionsDirty) {
				this.graphics.clear();
				this.graphics.beginFill(0);
				this.graphics.drawRect(0, 0, this.width, this.height);
				_mask.graphics.clear();
				_mask.graphics.beginFill(0);
				_mask.graphics.drawRect(0, 0, this.width, this.height);
				_mask.graphics.endFill();
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		private var _currentImageScale:Number = 1.0;
		private var _downPoint:Point = new Point(0, 0);
		private var _initalLoaderXY:Point = new Point(0, 0);
		private var _mouseDown:Boolean = false;
		private function mouseDown(event:MouseEvent):void {
			//if (cameramove == null) { return; }
			var newX:Number;
			var newY:Number;
			if (event.shiftKey || event.altKey) {
				// center the image on the zoom point and scale it up
				var centerPointOnImage:Point = new Point(_loader.mouseX, _loader.mouseY);
				
				if (event.shiftKey) {
					// zoom in
					_currentImageScale = _loader.scaleX = _loader.scaleY = _currentImageScale * 1.5;
				} else if (event.altKey) {
					// zoom out
					_currentImageScale = _loader.scaleX = _loader.scaleY = _currentImageScale * 0.75;
					var loaderHeightToWidthRatio:Number = _loader.height / _loader.width;
					var imageViewerHeightToWidthRatio:Number = this.height / this.width;
					var maxZoomOutReached:Boolean = false;
					if (loaderHeightToWidthRatio > imageViewerHeightToWidthRatio) {
						// image limited by its height
						if (_loader.height < this.height) { 
							maxZoomOutReached = true; newX = 0;  newY = 0;
							_currentImageScale = _loader.scaleX = _loader.scaleY = this.height / _loader.content.height;
						}
					} else {
						// image limited by its width
						if (_loader.width < this.width) { 
							maxZoomOutReached = true; newX = 0;  newY = 0;
							_currentImageScale = _loader.scaleX = _loader.scaleY = this.width / _loader.content.width;
						}
					}
				}
					
				if (!maxZoomOutReached) {
					newX = this.width / 2 - centerPointOnImage.x * _currentImageScale;
					newY = this.height / 2 - centerPointOnImage.y * _currentImageScale;
					if (newX > 0) {
						newX = 0;
					} else if (newX <= this.width - _loader.width) {
						newX = this.width -_loader.width;
					}
					if (newY > 0) {
						newY = 0;
					} else if (newY <= this.height - _loader.height) {
						newY = this.height -_loader.height;
					}
				}
				
				_loader.x = newX; 
				_loader.y = newY;
				return;
			}
			_initalLoaderXY.x = _loader.x;
			_initalLoaderXY.y = _loader.y;
			_downPoint.x = mouseX;
			_downPoint.y = mouseY;
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			_mouseDown = true;
		}
		
		private function mouseMove(event:MouseEvent):void {
			var diffX:Number = mouseX - _downPoint.x;
			var diffY:Number = mouseY - _downPoint.y;
			var newX:Number = _initalLoaderXY.x + diffX;
			var newY:Number = _initalLoaderXY.y + diffY;
			if (newX > 0) {
				newX = 0;
			} else if (newX <= this.width - _loader.width) {
				newX = this.width -_loader.width;
			}
			if (newY > 0) {
				newY = 0;
			} else if (newY <= this.height - _loader.height) {
				newY = this.height -_loader.height;
			}
			_loader.x = newX;
			_loader.y = newY;
		
			invalidateDisplayList();
			//_cameraMove.value = "|MC|:ref:" + _downPoint.x + ":" + _downPoint.y + "|:tgt:" + _currentPoint.x + ":" + _currentPoint.y;
			//dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, _cameraMove, true, true));
		}
		
		private function mouseUp(event:MouseEvent):void {
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			_mouseDown = false;
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
				_imageSize = _imageSocket.readUnsignedInt();
				//trace("  size: " + _imageSize);
				if(_imageSocket.bytesAvailable == 0) {
					return;
				}
			}
			
			var byteArray:ByteArray = new ByteArray();
			try {
				//trace("Reading bytes");
				_imageSocket.readBytes(byteArray, 0, _imageSocket.bytesAvailable);
				//trace("  Got " + byteArray.length + " bytes");
				_loader.loadBytes(byteArray);
				_imageData.writeBytes(byteArray, 0, byteArray.length);
				//trace("  Received so far: " + _imageData.length);
				if (_imageData.length == _imageSize) {
					//trace("Got whole image");
					_loader.loadBytes(_imageData);
					_imageData = new ByteArray();
					_imageSize = 0;
					//trace("IMAGE DONE");
				}
			} catch(e:Error) {
				trace("IMAGE VIEWER onSocketData error: " + e.message);
				//_imageSocket.close();
			}
		}
		
		private function loadComplete(event:Event):void {
			//trace("_loader.height: " + _loader.height + "   _loader.width: " + _loader.width);
			//trace("_loader.content.height: " + _loader.content.height + "   _loader.content.width: " + _loader.content.width);
			var loaderHeightToWidthRatio:Number = _loader.content.height / _loader.content.width;
			var imageViewerHeightToWidthRatio:Number = this.height / this.width;
			var newScale:Number;
			// need to scale isotropically in x and y
			if (loaderHeightToWidthRatio > imageViewerHeightToWidthRatio) {
				// image limited by its height
				newScale = this.height / _loader.content.height;
			} else {
				// image limited by its width
				newScale = this.width / _loader.content.width;
			}
			_loader.scaleX = _loader.scaleY = newScale;
			_currentImageScale = newScale;
			//trace("_currentImageScale: " + _currentImageScale);
			if (!_imageSocket.connected) { return; }
		}
		
		private function addListeners(sock:Socket):void {
			sock.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			sock.addEventListener(Event.CLOSE, closeHandler); 
			sock.addEventListener(Event.CONNECT, connectedHandler); 
			sock.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		//===========SOCKET HANDLERS==============================================================
		private function connectedHandler(event:Event):void {
			trace("IMAGE SOCKET: connect handler reached");
		}
		
		private function closeHandler(event:Event):void {
			trace("IMAGE SOCKET: closeHandler: " + event);
			Alert.show("IMAGE Socket Connection Interrupted (host="+_hostValue+"  port="+_portValue+")!  Attempt reconnect?", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
				null, alertClick);
		}
		private function alertClick(event:CloseEvent):void {
            if (event.detail==Alert.YES)
				reconnect();
        }
		
		private function reconnect():void {
			if (_imageSocket.connected) {
				_imageSocket.close();
			}
			trace("attempted connect to: " + _hostValue + " port=" + _portValue);
			_imageSocket.connect(_hostValue, parseInt(_portValue));
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("IMAGE SOCKET: ioErrorHandler: " + event);
				Alert.show("IMAGE Connection not established (host="+_hostValue+"  port="+_portValue+")!  Press 'Yes' to attempt reconnect", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
		}
		
		private function fileIoErrorHandler(event:IOErrorEvent):void {
			Alert.show("WARNING: ImageViewer attempted to load image at path=" + _imagepathValue + ", but encountered the following error: " + event.text);
		}
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("VIDEO SOCKET: securityErrorHandler: " + event);
		}
	}
}