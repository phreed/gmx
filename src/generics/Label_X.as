package generics 
{
	import flash.display.DisplayObject;
	import flash.text.TextFieldAutoSize;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import mx.core.UITextField;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import records.Record;
	import flash.text.TextLineMetrics;
	
	import mx.controls.Alert;
	import mx.controls.Label;
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class Label_X extends Label implements IField
	{		
		public function get componentValue():String { 
			return this.text;
		}
		public function set componentValue(val:String):void {
			this.text = val;
		}
		
		public function Label_X() 
		{
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
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			
			if (field != null) {
				if (xml.@text != undefined) {
					this.field.value = xml.@text.toString();
				}
				if (xml.@attributes != undefined) { 
					this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString());
				}
			}
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
		}
		
		public function _set_observer(val:String):void { } // not used anymore
		public function _set_fontSize(val:String):void { this.setStyle("fontSize", parseFloat(val)); }
		public function _set_fontWeight(val:String):void { this.setStyle("fontWeight", val); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_textAlign(val:String):void { this.setStyle("textAlign", val); }// left | right | center
		public function _set_selectable(val:String):void { this.selectable = GMXComponentBuilder.parseBoolean(val); }
		public function _set_disabledColor(val:String):void { this.setStyle("disabledColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_fontAntiAliasType(val:String):void { this.setStyle("fontAntiAliasType", val); }
		public function _set_fontFamily(val:String):void { this.setStyle("fontFamily", val); }
		public function _set_fontGridFitType(val:String):void { this.setStyle("fontGridFitType", val); }
		public function _set_fontSharpness(val:String):void { this.setStyle("fontSharpness", parseFloat(val)); }
		public function _set_fontStyle(val:String):void { this.setStyle("fontStyle", val); }
		public function _set_fontThickness(val:String):void { this.setStyle("fontThickness", parseFloat(val)); }
		public function _set_paddingLeft(val:String):void { this.setStyle("paddingLeft", parseFloat(val)); }
		public function _set_paddingRight(val:String):void { this.setStyle("paddingRight", parseFloat(val)); }
		public function _set_paddingTop(val:String):void { this.setStyle("paddingTop", parseFloat(val)); }
		public function _set_paddingBottom(val:String):void { this.setStyle("paddingBottom", parseFloat(val)); }
		public function _set_textDecoration(val:String):void { this.setStyle("textDecoration", val); }
		public function _set_textIndent(val:String):void { this.setStyle("textIndent", parseFloat(val)); }
		public function _set_fid(val:String):void { this.fid = val; }
		public function _set_text(val:String):void { this.text = val; } // handles field change in build function
		public function _set_attributes(val:String):void { } // handles field change in build function
		public function _set_ruid(val:String):void { } // handles in build function
		public function _set_multiLine(val:String):void {
			if (!(GMXComponentBuilder.parseBoolean(val))) { return; }
			if (!textField) {
				textField = new UITextField();
				textField.styleName = this;
				addChild(DisplayObject(textField));
			}
			textField.multiline = true;
			textField.wordWrap = true;
			textField.autoSize = TextFieldAutoSize.LEFT;
		}
		
		
		
		override protected function measure():void {
			
			
			super.measure();
			if (textField.multiline) {
				this.measuredWidth = textField.textWidth + 3;
				this.measuredHeight = textField.textHeight + 3;
			}
			//var metrics:TextLineMetrics = this.measureText(this.text);
			//this.measuredWidth += 3; // help eliminate the "..." stuff happening
		}
		
		override protected function commitProperties():void {
			if (_field != null) { this.text = _field.value; }
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