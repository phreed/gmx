package generics 
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import records.Attributes;
	import records.Field;
	import records.Record;
	
	import flash.events.FocusEvent;
	
	import mx.controls.Alert;
	import mx.controls.TextArea;
	import mx.events.FlexEvent;
	import records.RecordEvent;
	
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class TextAreaCumulative_X extends TextArea implements IMultiField
	{
		public function get fieldNames():Array { return ["totalconversation", "diff", "readytoreceive", "handle"]; }
		public function get defaultValues():Array { return ["", "", "true", "User" + Math.round(Math.random() * 1000000)]; }
		
		public var totalconversation:Field;  // used to hold all previous conversation so that even with swapping layouts, it retains state
		private var _totalconversationValue:String = "";
		
		public var diff:Field;
		private var _diffValue:String = "";
		
		public var readytoreceive:Field;
		
			
		public function TextAreaCumulative_X() 
		{
			super();
			this.editable = false;
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			IFieldStandardImpl.setFields(this, xml, fieldNames, defaultValues);
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			if (totalconversation == null) { displayWarning("totalconversation"); } 
			else {
				totalconversation.attributes.send = Attributes.SEND_NEVER;
				this.htmlText = totalconversation.value;
			}
			if (readytoreceive == null) { displayWarning("readytoreceive"); }
			else {
				readytoreceive.value = "true";
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, readytoreceive));
			}
			if (diff == null) { displayWarning("diff"); }
			else {
				diff.attributes.updateComponentsCondition = Attributes.UPDATE_COMPONENTS_ALWAYS;
			}
			
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
		}
		
		private function displayWarning(fieldName:String):void {
			Alert.show("WARNING: TextAreaCumulative did not have '"+ fieldName +"' field.  The current implementation of this widget "
					+ "requires this field.  The way this widget works is:  The external service keeps track of the entire conversation in a field "
					+ "mapping to the 'totalconversation' field of this component.  As soon as this widget is created, it sends a Record "
					+ "to the external service with a 'true' value in the 'readytoreceive' field.  The service then sends the 'totalconversation' "
					+ "to the widget so that it is completely up-to-date with the service (and state is maintained on the service if desired).  "
					+ "After that, the service sends new incoming messages to the 'diff' field, and this component automatically adds them to whatever "
					+ "is already displayed.");
		}
		
		public function _set_text(val:String):void { } 
		public function _set_value(val:String):void { } 
			//---- standard Flex Button properties / styles: ----
		public function _set_condenseWhite(val:String):void { this.condenseWhite = GMXComponentBuilder.parseBoolean(val); }
			//data="undefined"
		public function _set_displayAsPassword(val:String):void { this.displayAsPassword = GMXComponentBuilder.parseBoolean(val); }
		public function _set_editable(val:String):void { this.editable = GMXComponentBuilder.parseBoolean(val); }
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
		public function _set_ruid(val:String):void { } // handled in the build function
		public function _set_attributes(val:String):void { } // handled in the build function
		
		public function _set_horizontalScrollPolicy(val:String):void { this.horizontalScrollPolicy = val; }
		public function _set_horizontalScrollPosition(val:String):void { this.horizontalScrollPosition = parseFloat(val); }
		public function _set_liveScrolling(val:String):void { this.liveScrolling = GMXComponentBuilder.parseBoolean(val); }
		public function _set_maxHorizontalScrollPosition(val:String):void { this.maxHorizontalScrollPosition = parseFloat(val); }
		public function _set_maxVerticalScrollPosition(val:String):void { this.maxVerticalScrollPosition = parseFloat(val); }
			//  scrollTipFunction="undefined"
		public function _set_showScrollTips(val:String):void { this.showScrollTips = GMXComponentBuilder.parseBoolean(val); }
		public function _set_verticalScrollPolicy(val:String):void { this.verticalScrollPolicy = val; }
		public function _set_verticalScrollPosition(val:String):void { this.verticalScrollPosition = parseFloat(val); }
		public function _set_horizontalScrollBarStyleName(val:String):void { this.setStyle("horizontalScrollBarStyleName", val); }
		public function _set_verticalScrollBarStyleName(val:String):void { this.setStyle("verticalScrollBarStyleName", val); }
		
		
		override protected function commitProperties():void {
			if (totalconversation != null) {
			// check the last part of totalconversation to see if it matches what was there previously -- determine whether it needs updated
				if (_totalconversationValue.length != totalconversation.value.length) {
					// assume that this has changed AND that a diff has not occured
					_totalconversationValue = totalconversation.value;
					this.htmlText = _totalconversationValue;
				} else {
					// assume that a diff has occured
					if (diff != null) {
						//trace("TOP");
						_diffValue = diff.value;
						this.htmlText += _diffValue;
					} 
				}
			} else {
				// in the absence of a totalconversation field, we must assume that a diff has occured
				if (diff != null) {
					//trace("BOTTOM");
					_diffValue = diff.value;
					this.htmlText += _diffValue;
				}
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			this.verticalScrollPosition = this.maxVerticalScrollPosition;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
				
//========= BEGIN IMultiField Implementation ==============================================
		private var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			var rec:Record = GMXDictionaries.getRuid(val);
			if (rec == null) {
				this.record = new Record(val);
			} else { 
				this.record = rec;
			}
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set fields(xml:XML):void {
			IFieldStandardImpl.setFields(this, xml, [], []);
		}	
//========= END IMultiField Implementation ================================================
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			_record = null;
			
			if (totalconversation != null) { totalconversation.removeComponentRequiringUpdate(this); totalconversation = null; }
			if (diff != null) { diff.removeComponentRequiringUpdate(this); diff = null;  }
			if (readytoreceive != null) { readytoreceive.removeComponentRequiringUpdate(this); readytoreceive = null; }
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}