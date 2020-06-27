package generics 
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import mx.collections.ArrayCollection;
	import mx.controls.ColorPicker;
	import mx.events.FlexEvent;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	/**
	 * ...
	 * @author 
	 */
	public class ColorPicker_X extends ColorPicker implements IField
	{
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		public function get componentValue():String { 
			return this.selectedColor.toString(16);
		}
		public function set componentValue(val:String):void {
			this.selectedColor = GMXComponentBuilder.parseColor(val);
		}
		
		public function ColorPicker_X() 
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
			if (xml.@dataProvider != undefined) {
				var splitStrings:Array = GMXComponentBuilder.parseStringArray(xml.@dataProvider.toString());
				var dataProviderArray:ArrayCollection = new ArrayCollection();
				var i:int;
				for (i = 0; i < splitStrings.length; i++) {
					var obj:Object = new Object();
					obj["label"] = splitStrings[i];
					dataProviderArray.addItem(obj);
				}
				this.dataProvider = dataProviderArray;
			} else {
				//Alert.show("ERROR: ComboBoxSingleField_ISIS was expecting a dataProvider attribute!");
			}
			
			IFieldStandardImpl.setFields(this, xml);
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
				if (xml.@value != undefined) { this.field.value = xml.@value.toString(); }
			}
		}
		
		public function _set_fid(val:String):void { this.fid = val; }  		
		public function _set_editable(val:String):void { this.editable = GMXComponentBuilder.parseBoolean(val); }  // default="false|true"
		public function _set_imeMode(val:String):void { this.imeMode = val;  }  // default="null"
		public function _set_restrict(val:String):void { this.restrict = val; } // default="null"
		public function _set_colorField(val:String):void { this.colorField = val; } // default="color"
		public function _set_labelField(val:String):void { this.labelField = val; } // default="label"
		public function _set_selectedColor(val:String):void { this.selectedColor = GMXComponentBuilder.parseColor(val); } // default="0x000000"
		public function _set_selectedIndex(val:String):void { this.selectedIndex = parseInt(val); } // default="0"
		public function _set_showTextField(val:String):void { this.showTextField = GMXComponentBuilder.parseBoolean(val); } // default="true|false"
		
		public function _set_borderColor(val:String):void { setStyle("borderColor", GMXComponentBuilder.parseColor(val)); } // default="0xA5A9AE"
		public function _set_closeDuration(val:String):void { setStyle("closeDuration", parseFloat(val)); } // default="250"
		public function _set_closeEasingFunction(val:String):void { setStyle("closeEasingFunction", parseFloat(val)); } // default="undefined"
		public function _set_color(val:String):void { setStyle("color", GMXComponentBuilder.parseColor(val)); } // default="0x0B333C"

		public function _set_disabledIconColor(val:String):void { setStyle("disabledIconColor", (val)); } // default="0x999999"
		public function _set_fillAlphas(val:String):void { setStyle("fillAlphas", GMXComponentBuilder.parseColor(val)); } // default="[0.6,0.4]"
		public function _set_fillColors(val:String):void { setStyle("fillColors", GMXComponentBuilder.parseColorArray(val)); } // default="[0xFFFFFF, 0xCCCCCC]"
		public function _set_focusAlpha(val:String):void { setStyle("focusAlpha", parseFloat(val)); } // default="0.5"
		public function _set_focusRoundedCorners(val:String):void { setStyle("focusRoundedCorners", (val)); } // default="tl tr bl br"
		public function _set_fontAntiAliasType(val:String):void { setStyle("fontAntiAliasType", (val)); } // default="advanced"
		public function _set_fontfamily(val:String):void { setStyle("fontfamily", (val)); } // default="Verdana"
		public function _set_fontGridFitType(val:String):void { setStyle("fontGridFitType", (val)); } // default="pixel"
		public function _set_fontSharpness(val:String):void { setStyle("fontSharpness", parseFloat(val)); } // default="0""
		public function _set_fontSize(val:String):void { setStyle("fontSize", parseFloat(val)); } // default="10"
		public function _set_fontStyle(val:String):void { setStyle("fontStyle", (val)); } // default="normal"
		public function _set_fontThickness(val:String):void { setStyle("fontThickness", parseFloat(val)); } // default="0"
		public function _set_fontWeight(val:String):void { setStyle("fontWeight", (val)); } // default="normal"
		public function _set_highlightAlphas(val:String):void { setStyle("highlightAlphas", GMXComponentBuilder.parseNumberArray(val)); } // default="[0.3,0.0]"
		public function _set_iconColor(val:String):void { setStyle("iconColor", GMXComponentBuilder.parseColor(val)); } // default="0x000000"
		public function _set_leading(val:String):void { setStyle("leading", parseInt(val)); } // default="2"
		public function _set_openDuration(val:String):void { setStyle("openDuration", parseFloat(val)); } // default="250"
		//public function _set_openEasingFunction(val:String):void { setStyle("openEasingFunction", (val)); } // default="undefined"
		public function _set_paddingBottom(val:String):void { setStyle("paddingBottom", parseFloat(val)); } // default="5"
		public function _set_paddingLeft(val:String):void { setStyle("paddingLeft", parseFloat(val)); } // default="5"
		public function _set_paddingRight(val:String):void { setStyle("paddingRight", parseFloat(val)); } // default="5"
		public function _set_paddingTop(val:String):void { setStyle("paddingTop", parseFloat(val)); } // default="4"
		public function _set_swatchBorderColor(val:String):void { setStyle("swatchBorderColor", GMXComponentBuilder.parseColor(val)); } // default="0x000000"
		public function _set_swatchBorderSize(val:String):void { setStyle("swatchBorderSize", (val)); } // default="1"
		//public function _set_swatchPanelStyleName(val:String):void { setStyle("swatchPanelStyleName", (val)); } // default="undefined"
		public function _set_textAlign(val:String):void { setStyle("textAlign", (val)); } // default="left"
		public function _set_textDecoration(val:String):void { setStyle("textDecoration", (val)); } // default="none"
		public function _set_textIndent(val:String):void { setStyle("textIndent", parseInt(val)); } // default="0"
		
		public function _set_dataProvider(val:String):void { }   // handled in build function default="null"			
		public function _set_ruid(val:String):void { }   // handled in build function default="null"
		
		
		
		
		override protected function commitProperties():void {
			if (_field != null) { this.componentValue = _field.value; }
			super.commitProperties();
		}
		
		private function changed(event:Event):void {
			this.field.value = this.selectedColor.toString(16);
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, this.field, true, true);
			this.dispatchEvent(recordEvent);
		}
		private function textAreaCallback(event:FlexEvent):void { changed(null); }
		private function textAreaFocusOutCallback(event:FocusEvent):void { changed(null); }	
		
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
			this.addEventListener(FlexEvent.ENTER, textAreaCallback, false, 0, true);
			this.addEventListener(FocusEvent.FOCUS_OUT, textAreaFocusOutCallback, false, 0, true);
			this.addEventListener(Event.CHANGE, changed, false, 0, true);
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