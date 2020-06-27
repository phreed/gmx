package generics
{
	import interfaces.ICollection;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import records.Attributes;
	import records.Collection;
	import records.Field;
	import records.RecordRef;
	import records.Record;
	import records.RecordEvent;
	import constants.Size;
	import GMX.Data.RuidVO;
	import mx.styles.CSSStyleDeclaration;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.controls.ComboBox;
	import mx.events.DropdownEvent;

	public class ComboBox_X extends ComboBox implements IField, ICollection
	{
		
		protected var _referenceItemIndex:Boolean = false;
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		
		public function ComboBox_X(buildXML:XML = null)
		{
			super();
			this.updateDropDownWidth();
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			var recordAdded:Boolean = false;
			if (xml.@referenceItemIndex.toString() == "true") { _referenceItemIndex = true; }
			if (xml.@cuid != undefined) { 
				this.cuid = xml.@cuid.toString();
			} else { Alert.show("WARNING: Incoming ComboBox (in layout message) does not have a cuid.  This ComboBox WILL NOT BE FUNCTIONAL!!!"); }
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.pushCurrentRecord(this.record);
				recordAdded = true;
			}
			this.addEventListener(Event.CHANGE, sendSelectedRecord, false, 0, true); // this listener is removed if xml@sendField="true"--see _set_sendField function
			this.addEventListener(MouseEvent.MOUSE_DOWN, GMXComponentListeners.clickDropdown, false, 0, true);
			this.addEventListener(DropdownEvent.OPEN, GMXComponentListeners.openDropdown, false, 0, true);
			IFieldStandardImpl.setFields(this, xml);
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			this.updateCollection(xml.children());
			_dirty = false; // only _dirty on subsequent collection updates
			
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
				if (xml.@value != undefined) { this.field.value = xml.@value.toString(); }
			}
			if (recordCollection != null) {
				if (xml.@default != undefined) { _recordCollection.addSelectedRuid(xml.@default.toString()); }
				this.invalidateProperties();
			}			
			this.invalidateProperties();
		}
		
		//---- standard Flex ComboBox properties / styles: ----
		public function _set_editable(val:String):void { this.editable = GMXComponentBuilder.parseBoolean(val); }
		public function _set_imeMode(val:String):void { this.imeMode = val; }
		public function _set_restrict(val:String):void { this.restrict = val; }
		public function _set_rowCount(val:String):void { this.rowCount = parseInt(val); }
		public function _set_alternatingItemColors(val:String):void { this.setStyle("alternatingItemColors", GMXComponentBuilder.parseColorArray(val)); }
		public function _set_arrowButtonWidth(val:String):void { this.setStyle("arrowButtonWidth", parseFloat(val)); }
		public function _set_borderColor(val:String):void { this.setStyle("borderColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_borderThickness(val:String):void { this.setStyle("borderThickness", parseFloat(val)); }
		public function _set_closeDuration(val:String):void { this.setStyle("closeDuration", parseFloat(val)); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_cornerRadius(val:String):void { this.setStyle("cornerRadius", parseFloat(val)); }
		public function _set_disabledColor(val:String):void { this.setStyle("disabledColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_disabledIconColor(val:String):void { this.setStyle("disabledIconColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_dropdownBorderColor(val:String):void { this.setStyle("dropdownBorderColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_dropdownStyleName(val:String):void { this.setStyle("dropdownStyleName", val); }
		public function _set_fillAlphas(val:String):void { this.setStyle("fillAlphas", GMXComponentBuilder.parseNumberArray(val)); }
		public function _set_fillColors(val:String):void { this.setStyle("fillColors", GMXComponentBuilder.parseColorArray(val)); }
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
		public function _set_highlightAlphas(val:String):void { this.setStyle("highlightAlphas", GMXComponentBuilder.parseNumberArray(val)); }
		public function _set_iconColor(val:String):void { this.setStyle("iconColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_leading(val:String):void { this.setStyle("leading", parseFloat(val)); }
		public function _set_openDuration(val:String):void { this.setStyle("openDuration", parseFloat(val)); }
		public function _set_paddingTop(val:String):void { this.setStyle("paddingTop", parseFloat(val)); }
		public function _set_paddingBottom(val:String):void { this.setStyle("paddingBottom", parseFloat(val)); }
		public function _set_paddingLeft(val:String):void { this.setStyle("paddingLeft", parseFloat(val)); }
		public function _set_paddingRight(val:String):void { this.setStyle("paddingRight", parseFloat(val)); }
		public function _set_selectionDuration(val:String):void { this.setStyle("selectionDuration", parseFloat(val)); }
		public function _set_textAlign(val:String):void { this.setStyle("textAlign", val); }
		public function _set_textDecoration(val:String):void { this.setStyle("textDecoration", val); }
		public function _set_textIndent(val:String):void { this.setStyle("textIndent", parseFloat(val)); }
		public function _set_textRollOverColor(val:String):void { this.setStyle("textRollOverColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_textSelectedColor(val:String):void { this.setStyle("textSelectedColor", GMXComponentBuilder.parseColor(val)); }
		public function _set_sendField(val:String):void {
			if (val == "true") {
				this.addEventListener(Event.CHANGE, GMXComponentListeners.closeDropdown, false, 0, true);
				this.removeEventListener(Event.CHANGE, sendSelectedRecord);
			} else if (val == "both") {
				this.addEventListener(Event.CHANGE, GMXComponentListeners.closeDropdown, false, 0, true);
				//this.addEventListener(Event.CHANGE, sendSelectedRecord, false, 0, true); -- this already added in build function as default
			}
		}
		public function _set_sendMessage(val:String):void { this.sendMessage = GMXComponentBuilder.parseBoolean(val); }
		public function _set_fid(val:String):void {	this.fid = val; }
		public function _set_referenceItemIndex(val:String):void {} // handles in build function
		public function _set_value(val:String):void {} // handles in build function
		public function _set_cuid(val:String):void {} // handles in build function
		public function _set_ruid(val:String):void {} // handles in build function
		public function _set_default(val:String):void {}	 // handles in build function
		
		
		public function updateCollection(xmlList:XMLList):void {
			if (_recordCollection == null) {
				Alert.show("WARNING: attempted to update combobox dataprovider on a ComboBox without a cuid (NON-FUNCTIONAL). Next time, add a cuid to the ComboBox in the layout message!!!");
				return;
			}
			var ruidList:Array = new Array();
			for (var i:int = 0; i < xmlList.length(); i++) {
				//trace("DATAPROVIDER COMBOBOX CHILD: " + xmlList[i] + " localName: " + (xmlList[i].localName()));
				var newRuid:String = xmlList[i].localName();
				var newLayout:String;
				if (xmlList[i].@layout != undefined) {
					newLayout = xmlList[i].@layout.toString();
				}
				if (_recordCollection.contains(newRuid)) { continue; }
				var newRecord:Record = GMXDictionaries.getRuid(newRuid);
				if (newRecord == null) {
					newRecord = new Record(newRuid);
				}
				if (newLayout != null) { newRecord.layout = newLayout; }
				GMXDictionaries.pushCurrentRecord(newRecord);
				var newField:Field = newRecord.fields["label"];
				if (newField == null) {
					newField = new Field("label");
					newRecord.addField(newField);
				}
				newField.value = xmlList[i];
				GMXDictionaries.popCurrentRecord();
				var ruidVO:RuidVO = new RuidVO();
				ruidVO.ruid = newRuid;
				ruidVO.select = "last";
				ruidList.push(ruidVO);
			}
			_recordCollection.processRuidList(ruidList);
			this.dataProvider = xmlList;
		}
		
		protected function sendSelectedRecord(event:Event):void {	
			if (_sendMessage == false) { return; }
			var len:int = this.dataProvider.length;
			for (var i:int = 0; i < len; i++) {
				// pull the ruid out of the dataProvider (an XMLList) to find the record that was selected
				//trace("dataProvider[i].localName() = " + dataProvider[i].localName() + "    this.selectedItem = " + this.selectedItem);
				if (dataProvider[i] == this.selectedItem) {
					var selectedRuid:String = dataProvider[i].localName();
					var selectedRecord:Record = GMXDictionaries.getRuid(selectedRuid); // dataProvider[i].localName() contains the ruid
					//if (_recordCollection != null) { _recordCollection.addSelectedRuid(selectedRuid); }
					if (this.field != null) { this.field.value = this.selectedLabel; }
					selectedRecord.sendMessage();
					
					return;
				}
			}
		}		
		// updateDropDownWidth & onChange were borrowed from from http://cookbooks.adobe.com/index.cfm?event=showdetails&postId=3962
		protected function updateDropDownWidth():void{
			this.dropdownWidth=calculatePreferredSizeFromData(this.dataProvider.length).width + 20;
		}
		
		override protected function commitProperties():void {
			if (_recordCollection != null) {
				// NOTE: updateDataProvider(Collection.COMBO_BOX) returns an XMLListCollection
				// with 1 element: the XMLList used by the ComboBoxes updateDataProvider function
				dataProvider = (_recordCollection.updateDataProvider(Collection.COMBO_BOX).source);
				if (this.field != null) {
					this.componentValue = this.field.value;
				}				
				this.invalidateDisplayList();
			}
			this.updateDropDownWidth();
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (textInput != null) {
				this.textInput.width = this.width - this.height / GMXMain.SCALE ;
				this.textInput.x = -Size.MM;
				// have to do this because if comboBox is scaled down through a parent's scale, the
				// textInput gets cut off way earlier than it needs to
			}
		}
//====== BEGIN IField implementation =========================================================
		public function get componentValue():String { 
			if (_referenceItemIndex) {
				return this.selectedIndex + "";
			} else return "" + this.selectedItem;
		}
		public function set componentValue(val:String):void {
			if (val == componentValue) { return; }
			try {
				if (_recordCollection != null) { _recordCollection.addSelectedRuidByValue(val); }
				if (_referenceItemIndex) {
					this.selectedIndex = parseInt(val);
				} else {
					this.selectedItem = val;
				}
			} catch (e:Error) {
				trace("Warning: comboBox problem: " + e.message);
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
//========= BEGIN ICollection Implementation ==============================================
		protected var _recordCollection:Collection;
		public function get recordCollection():Collection { return this._recordCollection; }
		public function set recordCollection(col:Collection):void {
			if (col == null) { _recordCollection = null; return; }
			_recordCollection = col;
			_recordCollection.addComponentRequiringUpdate(this);
		}
		public function get cuid():String { return _recordCollection == null ? null : _recordCollection.cuid; }
		public function set cuid(val:String):void {
			var col:Collection = GMXDictionaries.getCuid(val);
			if (col == null) {
				this.recordCollection = new Collection(val);
			} else { 
				this.recordCollection = col;
			}
			this.invalidateProperties();
		}
		protected var _dirty:Boolean = false;
		public function get dirty():Boolean { return _dirty; }
		public function set dirty(val:Boolean):void {
			_dirty = val;
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			if (recordCollection != null) {
				recordCollection.removeComponentRequiringUpdate(this);
				_recordCollection = null;
			}
			_record = null;
			if (_field == null) { return; }
			
			_field.removeComponentRequiringUpdate(this);
			_field = null;
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}