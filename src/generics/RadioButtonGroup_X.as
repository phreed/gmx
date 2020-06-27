/*
 *      Copyright (c) Vanderbilt University, 2006-2009
 *      ALL RIGHTS RESERVED, UNLESS OTHERWISE STATED
 *
 *      Developed under contract for Future Combat Systems (FCS)
 *      by the Institute for Software Integrated Systems, Vanderbilt Univ.
 *
 *      Export Controlled:  Not Releasable to a Foreign Person or
 *      Representative of a Foreign Interest
 *
 *      GOVERNMENT PURPOSE RIGHTS:
 *      The Government is granted Government Purpose Rights to this
 *      Data or Software.  Use, duplication, or disclosure is subject
 *      to the restrictions as stated in Agreement DAAE07-03-9-F001
 *      between The Boeing Company and the Government.
 *
 *      Vanderbilt University disclaims all warranties with regard to this
 *      software, including all implied warranties of merchantability
 *      and fitness.  In no event shall Vanderbilt University be liable for
 *      any special, indirect or consequential damages or any damages
 *      whatsoever resulting from loss of use, data or profits, whether
 *      in an action of contract, negligence or other tortious action,
 *      arising out of or in connection with the use or performance of
 *      this software.
 * 
 */
package generics
{
	import __AS3__.vec.Vector;
	import generics.ComponentCreationEvent;
	import generics.VBox_X;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.RecordRef;
	import mx.collections.XMLListCollection;
	
	import interfaces.IField;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import constants.Size;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;

	public class RadioButtonGroup_X extends UIComponent implements IField
	{
		protected var _referenceItemIndex:Boolean = false;
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		protected var _sendField:String = "true";
		public function get sendField():String { return _sendField; }
		public function set sendField(val:String):void { _sendField = val; }
		
		public function RadioButtonGroup_X()
		{
			super();
		}
		
		private var _currentSelection:RadioButton_X;
		private var _options:Vector.<RadioButton_X> = new Vector.<RadioButton_X>;
		private var _vBox:VBox_X;
		
		private static const PADDING:Number = 0.0;
		private static const VERTICAL_GAP:Number = 0.0;
		
		override protected function createChildren():void {
			super.createChildren();
			var MM:Number = Size.MM;
			//trace("group createChildren()");
			_vBox = new VBox_X();
			this.addChild(_vBox);
			_vBox.setStyle("paddingLeft", PADDING);
			_vBox.setStyle("paddingTop", PADDING);
			_vBox.setStyle("paddingBottom", PADDING);
			_vBox.setStyle("paddingRight", PADDING);
			_vBox.setStyle("verticalGap", VERTICAL_GAP);
			this.addEventListener(RadioButton_ISIS_Event.RADIO_BUTTON_CLICK, radioClick);
			this.addEventListener(ComponentCreationEvent.CREATED, radioCreate);
		}
		
		private function radioCreate(event:ComponentCreationEvent):void {
			if (event.component is RadioButton_X) {
				event.stopPropagation();
				_options.push(event.component as RadioButton_X);
			}
		}
		
		override protected function measure():void {
			super.measure();
			var maxWidth:Number = 0.0;
			var maxHeight:Number = 2 * PADDING;
			for (var i:int = 0; i < _vBox.numChildren; i++) {
				var comp:UIComponent = _vBox.getChildAt(i) as UIComponent;
				maxWidth = comp.measuredWidth > maxWidth ? comp.measuredWidth : maxWidth;
				maxHeight += comp.measuredHeight + VERTICAL_GAP;
			}
			_vBox.height = maxHeight;
			_vBox.width = maxWidth + 2 * PADDING;
		
			this.measuredHeight = _vBox.height;
			this.measuredWidth = _vBox.width;
		}
		
		override protected function commitProperties():void {
			//trace("RADIOBUTTON COMMIT PROPERTIES REACHED!!");
			//trace("_field: " + _field + (_field != null ? "   _field.value: " + _field.value : "" ) + "   this.componentValue: " + this.componentValue); 			
			if (_field != null && _field.value != this.componentValue) { this.componentValue = _field.value; }
			//if (_field != null) { this.componentValue = _field.value; }
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.pushCurrentRecord(this.record);
				recordAdded = true;
			}
			if (xml.@referenceItemIndex != undefined) { _referenceItemIndex = GMXComponentBuilder.parseBoolean(xml.@referenceItemIndex.toString()); }
			if (xml.@sendField.toString() == "true") {
				//this.addEventListener(Event.CHANGE, GMXComponentListeners.closeDropdown, false, 0, true);
				_sendField = xml.@sendField.toString();
			}
			if (xml.@sendMessage.toString() == "false") {
				this.sendMessage = false;
			}
			IFieldStandardImpl.setFields(this, xml);
			GMXComponentBuilder.setStandardValues(xml, this);
			GMXComponentBuilder.processXML(_vBox, xml);
			
			if (xml.@fid != undefined) { this.fid = xml.@fid.toString(); }
			_vBox.invalidateSize();
			_vBox.invalidateDisplayList();
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
			this.invalidateProperties();
		}
		
		private function radioClick(event:RadioButton_ISIS_Event):void {
			event.stopPropagation();
			//if (event.button.selected) { return; }
			for (var i:int = 0; i < _options.length; i++) {
				if (_options[i] == event.button) {
					// _options[i].selected = true // already is true;
					
					/* IF UNSELECTABLE
					if (_selectedItem == event.button.label) {
						// button was already selected--> unselect it
						selectedItem = null;
						if (_field != null) {
							// set field value to nothing or index of -1
							if (_referenceItemIndex) { _field.value = -1 + ""; }
							else { _field.value = ""; }
						}
						continue;
					}
					*/

					selectedItem = event.button.label;
					selectedIndex = i;
					
					if (_field != null) { 
						_referenceItemIndex ? _field.value = "" + _selectedIndex : _field.value = _selectedItem;
						if (_sendField == "true") {
							this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
						}
					}
				} else {
					if (_options[i].selected == true) { _options[i].selected = false; }
				}
			}
		}
		
		public function get selectedItem():String { return _selectedItem; }
		private var _selectedItem:String = "";
		public function set selectedItem(val:String):void {
			//trace("===> set selectedItem: " + val + "   _options.length: " + _options.length);
			//try { throw new Error("HAHAHAH"); } catch (e:Error) { trace("set selected item: " + e.getStackTrace());	}
			if (selectedItem == val) { return; }
			
			_selectedItem = val;
			for (var i:int = 0; i < _options.length; i++) {
				//trace("=======>_options[i].label: " + _options[i].label);
				if (_options[i].label == _selectedItem) {
					//trace("==========>FOUND SELECTED ITEM");
					_options[i].selected = true;
				} else {
					if (_options[i].selected == true) { _options[i].selected = false; }
				}
			}
		}
		private var _selectedIndex:int = -1;
		public function get selectedIndex():int { return _selectedIndex; }
		public function set selectedIndex(val:int):void {
			//trace("set selectedIndex: " + val);
			if (_selectedIndex == val) { return;  }
			
			_selectedIndex = val;			
			for (var i:int = 0; i < _options.length; i++) {
				if (i == _selectedIndex) {
					_options[i].selected = true;
					//this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, this.field, true, true));
				} else {
					if (_options[i].selected == true) { _options[i].selected = false; }
				}
			}
		}
//====== BEGIN IField implementation =========================================================
		public function get componentValue():String {
			//trace("get componentValue: " + this.selectedItem);
			if (_referenceItemIndex) {
				return this.selectedIndex + "";
			} else return "" + this.selectedItem;
		}
		public function set componentValue(val:String):void {
			//trace("set componentValue: val: " + val + "   prev val: " + componentValue);
			//if (val == componentValue) { return; }
			try {
				if (_referenceItemIndex) {
					this.selectedIndex = parseInt(val);
				} else {
					this.selectedItem = val;
				}
			} catch (e:Error) {
				trace("Warning: RadioButton problem: " + e.message);
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
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			for (var i:int = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) {
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			_record = null;
			if (_field == null) { return; }
			
			_field.removeComponentRequiringUpdate(this);
			_field = null;
		}
		public function setAttributes(attributes:Attributes):void {

		}
//========= END ISelfBuilding Implementation ==============================================
	}
}