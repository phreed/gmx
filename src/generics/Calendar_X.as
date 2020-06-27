package generics
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import flash.events.Event;
	import mx.controls.DateChooser;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class Calendar_X extends DateChooser implements IField
	{	
		public function get componentValue():String { 
			return _field == null ? null : _field.value; 
		}
		
		public function set componentValue(val:String):void {
			return; 
		}
		
		public function Calendar_X() {
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
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		
		public function _set_allowDisjointSelection(val:String):void { this.allowDisjointSelection = GMXComponentBuilder.parseBoolean(val); }
		public function _set_allowMultipleSelection(val:String):void { this.allowMultipleSelection = GMXComponentBuilder.parseBoolean(val); }
		public function _set_dayNames(val:String):void { this.dayNames = GMXComponentBuilder.parseStringArray(val); } //dayNames="["S", "M", "T", "W", "T", "F", "S"]"
		public function _set_disabledDays(val:String):void { this.disabledDays = GMXComponentBuilder.parseIntArray(val); }
		public function _set_displayedMonth(val:String):void { this.displayedMonth = parseFloat(val); } //January=0 and December=11
		public function _set_displayedYear(val:String):void { this.displayedYear = parseFloat(val); }
		public function _set_firstDayOfWeek(val:String):void { this.firstDayOfWeek = parseFloat(val); } //Corresponds to dayNames array element i.e. Default 0=Sunday, 1=Monday etc. 
		public function _set_maxYear(val:String):void { this.maxYear = parseFloat(val); }
		public function _set_minYear(val:String):void { this.minYear = parseFloat(val); }
		public function _set_monthNames(val:String):void { this.monthNames = GMXComponentBuilder.parseStringArray(val); }
		public function _set_monthSymbol(val:String):void { this.monthSymbol = val; } //monthSymbol=""
		public function _set_showToday(val:String):void { this.showToday = GMXComponentBuilder.parseBoolean(val); }
		public function _set_yearNavigationEnabled(val:String):void { this.yearNavigationEnabled = GMXComponentBuilder.parseBoolean(val); }
		public function _set_yearSymbol(val:String):void { this.yearSymbol = val; }
		public function _set_backgroundColor(val:String):void { this.setStyle("backgroundColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_backgroundAlpha(val:String):void { this.setStyle("backgroundAlpha", parseFloat(val)); }
		public function _set_borderColor(val:String):void { this.setStyle("borderColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_borderThickness(val:String):void { this.setStyle("borderThickness", parseFloat(val)); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_cornerRadius(val:String):void { this.setStyle("cornerRadius", parseFloat(val)); }
		public function _set_disabledColor(val:String):void { this.setStyle("disabledColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_disabledIconColor(val:String):void { this.setStyle("disabledIconColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_fillAlphas(val:String):void { this.setStyle("fillAlphas", GMXComponentBuilder.parseNumberArray(val)); } //Corresponding to fill colors
		public function _set_fillColors(val:String):void { this.setStyle("fillColors", GMXComponentBuilder.parseColorArray(val)); }
		public function _set_focusAlpha(val:String):void { this.setStyle("focusAlpha", parseFloat(val)); }
		public function _set_focusRoundedCorners(val:String):void { this.setStyle("focusRoundedCorners", val); } //focusRoundedCorners"tl tr bl br" 
		public function _set_fontAntiAliasType(val:String):void { this.setStyle("fontAntiAliasType", val); }
		public function _set_fontFamily(val:String):void { this.setStyle("fontFamily", val); }
		public function _set_fontGridFitType(val:String):void { this.setStyle("fontGridFitType", val); }
		public function _set_fontSharpness(val:String):void { this.setStyle("fontSharpness", parseFloat(val)); }
		public function _set_fontSize(val:String):void { this.setStyle("fontSize", parseFloat(val)); }
		public function _set_fontStyle(val:String):void { this.setStyle("fontStyle", val); }
		public function _set_fontThickness(val:String):void { this.setStyle("fontThickness", parseFloat(val)); }
		public function _set_fontWeight(val:String):void { this.setStyle("fontWeight", val); }
		public function _set_headerColors(val:String):void { this.setStyle("headerColors", GMXComponentBuilder.parseColorArray(val)); }
		public function _set_headerStyleName(val:String):void { this.setStyle("headerStyleName", val); }
		public function _set_highlightAlphas(val:String):void { this.setStyle("highlightAlphas", GMXComponentBuilder.parseNumberArray(val)); }
		public function _set_horizontalGap(val:String):void { this.setStyle("horizontalGap", parseFloat(val)); }
		public function _set_iconColor(val:String):void { this.setStyle("iconColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_leading(val:String):void { this.setStyle("leading", parseFloat(val)); }
		public function _set_textAlign(val:String):void { this.setStyle("textAlign", val); }
		public function _set_textDecoration(val:String):void { this.setStyle("textDecoration", val); }
		public function _set_textIndent(val:String):void { this.setStyle("textIndent", parseFloat(val)); }
		public function _set_todayColor(val:String):void { this.setStyle("todayColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_todayStyleName(val:String):void { this.setStyle("todayStyleName", val); }
		public function _set_verticalGap(val:String):void { this.setStyle("verticalGap", parseFloat(val)); }
		public function _set_weekDayStyleName(val:String):void { this.setStyle("weekDayStyleName", val); }
		public function _set_fid(val:String):void {this.fid = val; } 
		public function _set_attributes(val:String):void { }
		public function _set_ruid(val:String):void { }
		
			/*
		public function _set_disabledRanges(val:String):void { this.disabledRanges = //disabledRanges="No default"
		public function _set_selectableRange(val:String):void { this.selectableRange = //selectableRange="No default"
		public function _set_selectedDate(val:String):void { this.selectedDate = //selectedDate="No default"
		public function _set_selectedRanges(val:String):void { this.selectedRanges = //selectedRanges="No default"
		public function _set_nextMonthDisabledSkin(val:String):void { this.setStyle("nextMonthDisabledSkin", xml.@nextMonthDisabledSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextMonthDownSkin(val:String):void { this.setStyle("nextMonthDownSkin", xml.@nextMonthDownSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextMonthOverSkin(val:String):void { this.setStyle("nextMonthOverSkin", xml.@nextMonthOverSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextMonthSkin(val:String):void { this.setStyle("nextMonthSkin", xml.@nextMonthSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextMonthUpSkin(val:String):void { this.setStyle("nextMonthUpSkin", xml.@nextMonthUpSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextYearDisabledSkin(val:String):void { this.setStyle("nextYearDisabledSkin", xml.@nextYearDisabledSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_nextYearDownSkin(val:String):void { this.setStyle("nextYearDownSkin", xml.@nextYearDownSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_nextYearOverSkin(val:String):void { this.setStyle("nextYearOverSkin", xml.@nextYearOverSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_nextYearSkin(val:String):void { this.setStyle("nextYearSkin", xml.@nextYearSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_nextYearUpSkin(val:String):void { this.setStyle("nextYearUpSkin", xml.@nextYearUpSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_prevMonthDisabledSkin(val:String):void { this.setStyle("prevMonthDisabledSkin", xml.@prevMonthDisabledSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_prevMonthDownSkin(val:String):void { this.setStyle("prevMonthDownSkin", xml.@prevMonthDownSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_prevMonthOverSkin(val:String):void { this.setStyle("prevMonthOverSkin", xml.@prevMonthOverSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_prevMonthSkin(val:String):void { this.setStyle("prevMonthSkin", xml.@prevMonthSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_prevMonthUpSkin(val:String):void { this.setStyle("prevMonthUpSkin", xml.@prevMonthUpSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserMonthArrowSkin"
		public function _set_prevYearDisabledSkin(val:String):void { this.setStyle("prevYearDisabledSkin", xml.@prevYearDisabledSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_prevYearDownSkin(val:String):void { this.setStyle("prevYearDownSkin", xml.@prevYearDownSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_prevYearOverSkin(val:String):void { this.setStyle("prevYearOverSkin", xml.@prevYearOverSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_prevYearSkin(val:String):void { this.setStyle("prevYearSkin", xml.@prevYearSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_prevYearUpSkin(val:String):void { this.setStyle("prevYearUpSkin", xml.@prevYearUpSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserYearArrowSkin"
		public function _set_rollOverColor(val:String):void { this.setStyle("rollOverColor", GMXComponentBuilder.parseColor(xml.@rollOverColor.toString())); }
		public function _set_rollOverIndicatorSkin(val:String):void { this.setStyle("rollOverIndicatorSkin", xml.@rollOverIndicatorSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserIndicator"
		public function _set_selectionColor(val:String):void { this.setStyle("selectionColor", GMXComponentBuilder.parseColor(xml.@selectionColor.toString())); }
		public function _set_selectionIndicatorSkin(val:String):void { this.setStyle("selectionIndicatorSkin", xml.@selectionIndicatorSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserIndicator"
		public function _set_todayIndicatorSkin(val:String):void { this.setStyle("todayIndicatorSkin", xml.@todayIndicatorSkin); } // TAKES IN A CLASS TYPE Default:"DateChooserIndicator"
			*/
		
		
		override protected function measure():void {
			super.measure();
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
		}
		protected function calendarChange(event:Event):void {
			_field.value = this.selectedDate.toString();
			var split:Array = _field.value.split(" ");
			//var obj:Object = new Object();
			//var rangeArray:Array = new Array();
			//obj.rangeStart = new Date(2010,6,20);
			//obj.rangeEnd = new Date(2010,6,25);
			//rangeArray.push(obj);
			//this.selectedRanges = rangeArray;
			_field.value = split[0] + " " + split[1] + " " + split[2] + " " + split[5]; // Don't need the exact Hour/Minute/Sec time and time zone [Remove if those values are needed]
			this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
			trace("CALENDAR CHANGE");
			trace(_field.value);
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
			this.addEventListener(Event.CHANGE, calendarChange);
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