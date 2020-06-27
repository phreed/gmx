package generics
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.TextInput;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	
	/**
	 * ...
	 * @author 
	 */
	public class FileBrowser extends HBox implements IField {
		private var _basePath:String = "";
		private var _browseButton:Button = new Button();
		private var _selectedFilePathTextInput:TextInput = new TextInput();
		
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		public function FileBrowser() {
			_browseButton.addEventListener(MouseEvent.CLICK, browseClick);
		}
		
		public function set componentValue(val:String):void {
			_selectedFilePathTextInput.text = val;
		}
		public function get componentValue():String {
			return _selectedFilePathTextInput.text;
		}
		
		override protected function createChildren():void {
			_browseButton.label = "Browse Files";
			
			super.createChildren();
			this.addChild(_selectedFilePathTextInput);
			this.addChild(_browseButton);
			_selectedFilePathTextInput.invalidateSize();
			_browseButton.invalidateSize();
			this.invalidateSize();
		}
		
		private function browseClick(event:MouseEvent):void {
			var file:FileReference = new FileReference();
			addListeners(file);
			file.browse();
		}
		
		private function addListeners(file:FileReference):void {
			file.addEventListener(Event.CANCEL, cancelHandler);
			file.addEventListener(Event.COMPLETE, completeHandler);
			file.addEventListener(Event.SELECT, selectHandler);
            file.addEventListener(Event.OPEN, openHandler);
            file.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			file.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			IFieldStandardImpl.setFields(this, xml);
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
				if (xml.@value != undefined) { this.field.value = xml.@value.toString(); }
				if (xml.@text != undefined) { this.field.value = xml.@text.toString(); }
			}
		}
		public function _set_sendMessage(val:String):void { this.sendMessage = GMXComponentBuilder.parseBoolean(val); }
		public function _set_fid(val:String):void {	this.fid = val; }
		public function _set_value(val:String):void {} // handles in build function
		public function _set_ruid(val:String):void {} // handles in build function
		public function _set_default(val:String):void {}	 // handles in build function
		
		private function cancelHandler(event:Event):void {
			trace("FileBrowser: cancel handler");
		}
		private function openHandler(event:Event):void {
			trace("FileBrowser: open handler");
		}
		private function selectHandler(event:Event):void {
			trace("FileBrowser: select handler");
			var file:FileReference = event.target as FileReference;
			var lastChar:String = _basePath.substring(_basePath.length - 1);
			var newVal:String = _basePath + ((lastChar == "/" || lastChar == "\\") ? "" : "/") + file.name;
			this.componentValue = newVal;
			this._field.value = newVal;
		}
		private function completeHandler(event:Event):void {
			trace("FileBrowser: complete handler");
		}
		private function progressHandler(event:ProgressEvent):void {
			trace("FileBrowser: progress handler");
		}
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("FileBrowser: securityError handler");
		}
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("FileBrowser: ioError handler");
		}
		
		override protected function commitProperties():void {
			if (_field != null) { this.componentValue = _field.value; }
			super.commitProperties();
		}
//====== BEGIN IField implementation =========================================================
		protected var _field:Field;
		public function get field():Field { return _field; }
		public function set field(newField:Field):void {
			_field = newField;
		}
		public function get fid():String { if (_field == null) return null; else return _field.fid; }
		public function set fid(val:String):void {
			if (GMXDictionaries.getCurrentRecord() == null) { return; }
			IFieldStandardImpl.setFid(this, val);
		}
		
		protected var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			IFieldStandardImpl.setRuid(this, val);
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set layout(val:String):void {
			IFieldStandardImpl.setLayout(val);
		}
//====== END IField implementation =========================================================
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			_record = null;
			if (field == null) { return; }
			
			_field.removeComponentRequiringUpdate(this);
			_field = null;
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}