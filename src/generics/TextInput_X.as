package generics 
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import constants.Size;
	
	import flash.events.FocusEvent;
	
	import mx.controls.Alert;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class TextInput_X extends TextInput implements IField
	{
		public static const FORMATTED:String = "formatted";
		public static const NUMERIC:String = "numeric";
		public static const DEFAULT:String = "default";
		
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
				
		public function get componentValue():String { 
			return this.text;
		}
		public function set componentValue(val:String):void {
			this.text = val;
		}
		
		public function TextInput_X() 
		{
			super();
		}
		
		public function changeType(textInputType:String):void {
			switch(textInputType) {
				case FORMATTED:
					
					break;
				case NUMERIC:
					this.restrict = "-.0123456789"
					break;
				case DEFAULT:
				
					break;
			}
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
		public function _set_observer(val:String):void { } // not used anymore
		public function _set_text(val:String):void { this.text = val; } 
		public function _set_value(val:String):void { this.text = val; }
		public function _set_sendMessage(val:String):void { _sendMessage = GMXComponentBuilder.parseBoolean(val); } 
			//---- standard Flex Button properties / styles: ----
		public function _set_condenseWhite(val:String):void { this.condenseWhite = GMXComponentBuilder.parseBoolean(val); }
			//data="undefined"
		public function _set_displayAsPassword(val:String):void { this.displayAsPassword = GMXComponentBuilder.parseBoolean(val); }
		public function _set_editable(val:String):void { this.editable = GMXComponentBuilder.parseBoolean(val); }
		public function _set_horizontalScrollPosition(val:String):void { this.horizontalScrollPosition = parseFloat(val); }
		public function _set_htmlText(val:String):void { this.htmlText = val; }
		public function _set_imeMode(val:String):void { this.imeMode = val; }
			//if (xml.@length(val:String):void { this.length = int(xml.@length); }
			//listData="null"
		public function _set_maxChars(val:String):void { this.maxChars = parseInt(val); }
		public function _set_restrict(val:String):void { this.restrict = val; }
		public function _set_selectionBeginIndex(val:String):void { this.selectionBeginIndex = parseInt(val); }
		public function _set_selectionEndIndex(val:String):void { this.selectionEndIndex = parseInt(val); }
		public function _set_backgroundAlpha(val:String):void { this.setStyle("backgroundAlpha", parseFloat(val)); }
		public function _set_backgroundColor(val:String):void { this.setStyle("backgroundColor", GMXComponentBuilder.parseColor(val)); }
			//backgroundImage="undefined"
		public function _set_backgroundSize(val:String):void { this.setStyle("backgroundSize", val); }
		public function _set_borderColor(val:String):void { this.setStyle("borderColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_borderSides(val:String):void { this.setStyle("borderSides", val); }
			//borderSkin="mx.skins.halo.HaloBorder"
		public function _set_borderStyle(val:String):void { this.setStyle("borderStyle", val); }
		public function _set_borderThickness(val:String):void { this.setStyle("borderThickness", parseFloat(val)); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_cornerRadius(val:String):void { this.setStyle("cornerRadius", parseFloat(val)); }
		public function _set_disabledColor(val:String):void { this.setStyle("disabledColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_dropShadowColor(val:String):void { this.setStyle("dropShadowColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_dropShadowEnabled(val:String):void { this.setStyle("dropShadowEnabled", GMXComponentBuilder.parseBoolean(val)); }
		public function _set_focusAlpha(val:String):void { this.setStyle("focusAlpha", parseFloat(val)); }
		public function _set_focusRoundedCorners(val:String):void { this.setStyle("focusRoundedCorners", val); }
		public function _set_fontAntiAliasType(val:String):void { this.setStyle("fontAntiAliasType", val); }
		public function _set_fontFamily(val:String):void { this.setStyle("fontFamily", val); }
		public function _set_fontGridFitType(val:String):void { this.setStyle("fontGridFitType", val); }
		public function _set_fontSharpness(val:String):void { this.setStyle("fontSharpness", parseFloat(val)); }
		public function _set_fontSize(val:String):void { this.setStyle("fontSize", parseFloat(val)); }
		public function _set_fontStyle(val:String):void { this.setStyle("fontStyle", val); }
		public function _set_fontThickness(val:String):void { this.setStyle("fontThickness", parseFloat(val)); }
		public function _set_fontWeight(val:String):void { this.setStyle("fontWeight", val); }
		public function _set_paddingLeft(val:String):void { this.setStyle("paddingLeft", parseFloat(val)); }
		public function _set_paddingRight(val:String):void { this.setStyle("paddingRight", parseFloat(val)); }
		public function _set_shadowDirection(val:String):void { this.setStyle("shadowDirection", val); }
		public function _set_shadowDistance(val:String):void { this.setStyle("shadowDistance", parseFloat(val)); }
		public function _set_textAlign(val:String):void { this.setStyle("textAlign", val); }
		public function _set_textDecoration(val:String):void { this.setStyle("textDecoration", val); }
		public function _set_textIndent(val:String):void { this.setStyle("textIndent", parseFloat(val)); }
			//****************************************************
		public function _set_type(val:String):void { changeType(val); }
		public function _set_fid(val:String):void {	this.fid = val; }
		public function _set_ruid(val:String):void { } // handled in the build function
		public function _set_attributes(val:String):void { } // handled in the build function
		
		
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
			this.addEventListener(FlexEvent.ENTER, GMXComponentListeners.textInputCallback);
			this.addEventListener(FocusEvent.FOCUS_OUT, GMXComponentListeners.textInputFocusOutCallback);
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