package generics
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import flash.display.DisplayObject;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author 
	 */
	public class ShapeShifter extends UIComponent implements IField
	{
		private var _fieldValue:String;
		
		public function ShapeShifter() {
			super();
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
			if (xml.@fid != undefined) {				
				this.fid = xml.@fid.toString();
			}
			GMXComponentBuilder.setStandardValues(xml, this);
			if (xml.@layout != undefined) {
				IFieldStandardImpl.setLayout(xml.@layout.toString());
			}
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		
		override protected function commitProperties():void {
			if (_field != null) { 
				if (_fieldValue == _field.value) { super.commitProperties(); return; }
				
				_fieldValue = field.value;
				for (var i:int = 0; i < this.numChildren; i++) {
					var selfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					if (selfBuilding != null) {
						selfBuilding.disintegrate();
					}
				}
				while (this.numChildren != 0) { this.removeChildAt(0); }
				GMXComponentBuilder.processXML(this, new XML(_fieldValue));
				this.invalidateSize();
			}
			super.commitProperties();
		}
		
		override protected function measure():void {
			super.measure();
			var i:int;
			var child:DisplayObject;
			var greatestX:Number = 0;
			var greatestY:Number = 0;
			for (i = 0; i < this.numChildren; i++) {
				child = this.getChildAt(i);
				if (child.x + child.width > greatestX) { greatestX = child.x + child.width; }
				if (child.y + child.height > greatestY) { greatestY = child.y + child.height; }
			}
			this.measuredWidth = greatestX;
			this.measuredHeight = greatestY;
			trace("ShapeShifter... measuredWidth: " + measuredWidth + "    measuredHeight: " + measuredHeight);
		}
		//====== BEGIN IField implementation =========================================================
		public function get componentValue():String { 
			return _fieldValue;
		}
		public function set componentValue(val:String):void {
			return;
		}
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