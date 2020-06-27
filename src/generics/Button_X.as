package generics 
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.SpriteAsset;
	import mx.events.FlexEvent;
	/**
	 * ...
	 * @author Alan Nelson
	 */
	public class Button_X extends Button implements IField
	{
		public function Button_X() {
			super();
		}
		
		protected var _widthIsExplicit:Boolean = false;
		protected var _heightIsExplicit:Boolean = false;
		protected var _iconXIsExplicit:Boolean = false;
		protected var _iconYIsExplicit:Boolean = false;
		protected var _iconWidthIsExplicit:Boolean = false;
		protected var _iconHeightIsExplicit:Boolean = false;
		
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		// true when you want a button without a field but still initiates message sending
		protected var _sendButton:Boolean = false;
		public function get sendButton():Boolean { return _sendButton; }
		public function set sendButton(val:Boolean):void { _sendButton = val; }
		
		protected var _icon:Image = null;
		public function get icon():Image { return _icon; }
		public function set icon(val:Image):void { _icon = val; }
		public function changeIcon(icon:String):void {
			var replacing:Boolean = false;
			if (_icon != null) {
				replacing = true;
				var oldX:Number = _icon.x;
				var oldY:Number = _icon.y;
				var oldWidth:Number = _icon.width;
				var oldHeight:Number = _icon.height;
				try {
					this.removeChild(_icon);
				} catch(e:Error) { } // in case it wasn't added as a child before for some strange reason
			} else _icon = new Image();
			//_icon.addEventListener(FlexEvent.UPDATE_COMPLETE, iconUpdateComplete);
			_icon.mouseEnabled = false;
			var svgAsset:SpriteAsset;
			_iconID = icon;
			svgAsset = getIcon(icon);
			
			_icon.source = svgAsset;
			if (replacing) {
				_icon.x = oldX;
				_icon.y = oldY;
				_icon.width = oldWidth;
				_icon.height = oldHeight; 
			}
			addChild(_icon);
		}
		
		protected function getIcon(icon:String):SpriteAsset {
			return ComponentIcons.pickImage(icon);
		}
		
		protected var _iconID:String = null;
		public function get iconID():String { return _iconID; }
		
		public function build(xml:XML):void {
			// (1) assuming this is an IField or IMultiField component, check to see if it has an assigned ruid... if it does, push that
			//    ruid on the stack and set a flag.
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			// (2) generally the IFieldStandardImpl class is called in order to handle setFields for all GMX components.  Note that for components
			//   with "named" fields (like the Dial's), there is 
			IFieldStandardImpl.setFields(this, xml);
			// (3) the "setPropertiesFromXML" function has some generic functions for handling attributes available to all GMX UIComponents--e.g.
			//    width, height, luid, static... also, if it is a Flex Container, some more attributes are handled by this function-e.g. paddingLeft, etc.
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			// (4) after handling
			if (_icon != null) {
				if (xml.@iconWidth != undefined) { _icon.width = GMXComponentBuilder.parseMM(xml.@iconWidth.toString()); _iconWidthIsExplicit = true; }
				if (xml.@iconHeight != undefined) { _icon.height = GMXComponentBuilder.parseMM(xml.@iconHeight.toString()); _iconHeightIsExplicit = true; }
				if (xml.@iconX != undefined) { _icon.x = GMXComponentBuilder.parseMM(xml.@iconX.toString()); _iconXIsExplicit = true; }
				if (xml.@iconY != undefined) { _icon.y = GMXComponentBuilder.parseMM(xml.@iconY.toString()); _iconYIsExplicit = true; }
			}
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		
		public function _set_fid(val:String):void {
				this.fid = val;
				this.addEventListener(MouseEvent.CLICK, GMXComponentListeners.buttonClick, false, 0, true);
		}
		public function _set_sendButton(val:String):void {
			// although the button does not have a field, clicking it initiates a DataEdit message
			_sendButton = GMXComponentBuilder.parseBoolean(val);
			if (_sendButton) { this.addEventListener(MouseEvent.CLICK, sendButtonClick, false, 0, true); }
		}
		public function _set_width(val:String):void { var value:Number = GMXComponentBuilder.parseMM(val);  if (isNaN(value)) { return; } _widthIsExplicit = true; this.width = value; }
		public function _set_height(val:String):void { var value:Number = GMXComponentBuilder.parseMM(val);  if (isNaN(value)) { return; } _heightIsExplicit = true; this.height = value; }
		public function _set_sendMessage(val:String):void { this.sendMessage = GMXComponentBuilder.parseBoolean(val); }
		public function _set_text(val:String):void { this.label = val; }
		public function _set_icon(val:String):void { _iconID = val; changeIcon(val); }			
			//---- standard Flex Button properties / styles: ----
		public function _set_autoRepeat(val:String):void { this.autoRepeat = GMXComponentBuilder.parseBoolean(val); }
		public function _set_emphasized(val:String):void { this.emphasized = GMXComponentBuilder.parseBoolean(val); }
		public function _set_labelPlacement(val:String):void { this.labelPlacement = val; }
		public function _set_label(val:String):void { this.label = val; }
		public function _set_toggle(val:String):void {	this.toggle = GMXComponentBuilder.parseBoolean(val); }
		public function _set_stickyHighlighting(val:String):void {	this.stickyHighlighting = GMXComponentBuilder.parseBoolean(val); }
		public function _set_borderColor(val:String):void { this.setStyle("borderColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_cornerRadius(val:String):void { this.setStyle("cornerRadius", parseFloat(val)); }
		public function _set_disabledColor(val:String):void { this.setStyle("disabledColor", GMXComponentBuilder.parseColor(val)); }
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
		public function _set_horizontalGap(val:String):void { this.setStyle("horizontalGap", parseFloat(val)); }
		public function _set_kerning(val:String):void { this.setStyle("kerning", GMXComponentBuilder.parseBoolean(val)); }
		public function _set_leading(val:String):void { this.setStyle("leading", parseFloat(val)); }
		public function _set_letterSpacing(val:String):void { this.setStyle("letterSpacing", parseFloat(val)); }
		public function _set_paddingBottom(val:String):void { this.setStyle("paddingBottom", parseFloat(val)); }
		public function _set_paddingLeft(val:String):void { this.setStyle("paddingLeft", parseFloat(val)); }
		public function _set_paddingRight(val:String):void { this.setStyle("paddingRight", parseFloat(val)); }
		public function _set_paddingTop(val:String):void { this.setStyle("paddingTop", parseFloat(val)); }
		public function _set_repeatDelay(val:String):void { this.setStyle("repeatDelay", parseFloat(val)); }
		public function _set_repeatInterval(val:String):void { this.setStyle("repeatInterval", parseFloat(val)); }
		public function _set_textAlign(val:String):void { this.setStyle("textAlign", val); }
		public function _set_textDecoration(val:String):void { this.setStyle("textDecoration", val); }
		public function _set_textIndent(val:String):void { this.setStyle("textIndent", parseFloat(val)); }
		public function _set_textRollOverColor(val:String):void { this.setStyle("textRollOverColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_textSelectedColor(val:String):void { this.setStyle("textSelectedColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_verticalGap(val:String):void { this.setStyle("verticalGap", parseFloat(val)); }
		public function _set_fillAlphas(val:String):void { this.setStyle("fillAlphas", GMXComponentBuilder.parseNumberArray(val)); }
		public function _set_fillColors(val:String):void { this.setStyle("fillColors", GMXComponentBuilder.parseColorArray(val)); }
		public function _set_highlightAlphas(val:String):void { this.setStyle("highlightAlphas", GMXComponentBuilder.parseNumberArray(val)); }
		public function _set_attributes(val:String):void { } // handled in build function 
		public function _set_iconWidth(val:String):void { } // handled in build function 
		public function _set_iconHeight(val:String):void { } // handled in build function
		public function _set_iconX(val:String):void { } // handled in build function
		public function _set_iconY(val:String):void { } // handled in build function
		public function _set_ruid(val:String):void { } // handled in build function
		
		
		protected function sendButtonClick(event:MouseEvent):void {
			this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
		}
		
		override protected function createChildren():void {
			super.createChildren();
		}
		override protected function measure():void {
			super.measure();
		}
		override protected function commitProperties():void {
			if (this.field != null) { this.componentValue = this.field.value; }
			super.commitProperties();
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_icon != null) {
				if (!_iconXIsExplicit) _icon.x = Size.MM;
				if (!_iconYIsExplicit) _icon.y = Size.MM;
				if (!_iconWidthIsExplicit) _icon.width = this.width - 2 * Size.MM;
				if (!_iconHeightIsExplicit) _icon.height = this.height  - 2 * Size.MM;
				this.addChild(_icon);
			}
		}

//====== BEGIN IField implementation =========================================================
		public function get componentValue():String { 
			if (this.toggle == true) {
				return this.selected + "";
			} else return "false"; 
		}
		public function set componentValue(val:String):void {
			if (this.toggle == true) {
				val == "true" ? this.selected = true : this.selected = false;
			}
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
			if (field.value == "" || field.value == null) { field.value = "false"; }
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
			this.record = null;
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