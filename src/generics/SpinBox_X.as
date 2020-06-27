// STILL TO BE IMPLEMENTED:
// 1) restricting the number of digits
// 2) testing for valid TextInput values (between min and max)

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
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	
	import generics.Button_X;
	import generics.TextInput_X;
	
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	public class SpinBox_X extends UIComponent implements IField
	{
		public function get componentValue():String { 
			if (_textField != null) {
				return _textField.text;
			} else return null;
		}
		public function set componentValue(val:String):void {
			if (_textField != null) { _textField.text = val; }
		}
		/**
		 * Sample XML Message:
		 * 	<SpinBox ruid="spinner" fid="spinner" min="-10" division="2" max="10" width="100mm" height="100mm">
				<Button icon="spinBoxDownArrow" width="9mm" height="9mm"/>
				<TextInput width="12mm" height="9mm" type="numeric"/>
				<Button icon="spinBoxUpArrow" width="9mm" height="9mm"/>
			</SpinBox>
		 */
		public function SpinBox_X()
		{
			super();
		}
		
		private var _textField:TextInput_X;
		private var _downButton:Button_X;
		private var _upButton:Button_X;
		private var _division:Number = 1.0;
		public function get division():Number { return _division; }
		public function set division(val:Number):void { _division = val; }
		private var _max:Number = 100;
		public function get max():Number { return _max; }
		public function set max(val:Number):void {
			_max = val;
		}
		private var _min:Number = 0;
		public function get min():Number { return _min; }
		public function set min(val:Number):void {
			_min = val;
		}
		
		override protected function createChildren():void {			
			super.createChildren();
		}
		
		override protected function commitProperties():void {
			if (_textField != null && _field != null && _textField.text != _field.value) {
				_textField.text = _field.value;
			}
			this.width = _downButton.width + _upButton.width + _textField.width;
			_textField.x = _downButton.width;
			_upButton.x = this.width - _upButton.width;
			var tempHeight:Number = 0;
			for (var i:int = 0; i < this.numChildren; i++) {
				var testHeight:Number = this.getChildAt(i).height; 
				if (testHeight > tempHeight) { tempHeight = testHeight; }
			}
			this.height = tempHeight;			
			super.commitProperties();
		}
		
		override protected function measure():void {
			super.measure();
			
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);	 
		}
		
		private function upClick(event:MouseEvent):void {
			try {
				var newVal:Number = parseFloat(_textField.text) + _division;
				if (newVal > _max) { newVal = _max; }
				_textField.text = "" + newVal;
				this.field.value = _textField.text;
				var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, this.field, true, true);
				this.dispatchEvent(recordEvent);
			} catch (e:Error) {
				trace("Textfield error: " + e.message);
			}
		}
		private function downClick(event:MouseEvent):void {
			try {
				var newVal:Number = parseFloat(_textField.text) - _division;
				if (newVal < _min) { newVal = _min; }
				_textField.text = "" + newVal;
				this.field.value = _textField.text;
				var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, this.field, true, true);
				this.dispatchEvent(recordEvent);
			} catch (e:Error) {
				trace("Textfield error: " + e.message);
			}
		}
		private function textInputCallback(event:Event):void {
			var textInput:TextInput_X = event.currentTarget as TextInput_X;
			var newVal:Number = parseFloat(textInput.text);
			//if (isNaN )   NEED TO HANDLE THIS PROBLEM
			var textInputField:Field = textInput.field;
			this.field.value = textInput.text;
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, textInputField, true, true);
			textInput.dispatchEvent(recordEvent);
		}
		
		public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			IFieldStandardImpl.setFields(this, xml);
			if (xml.@division != undefined) {
				var val:Number = Number(xml.@division);
				if (!isNaN(val)) { _division = val; }
			}
			if (xml.@max != undefined) {
				val = Number(xml.@max);
				if (!isNaN(val)) { _max = val; }
			}
			if (xml.@min != undefined) {
				val = Number(xml.@min);
				if (!isNaN(val)) { _min = val; }
			}
			GMXComponentBuilder.setStandardValues(xml, this);
			GMXComponentBuilder.processXML(this, xml);
						
			for (var i:int = 0; i < this.numChildren; i++) {
				var component:UIComponent = this.getChildAt(i) as UIComponent;
				switch(i) {
					case 0:
						if (!(component is Button_X)) {	incorrectXMLAlert(); break; }
						_downButton = component as Button_X;
						_downButton.addEventListener(MouseEvent.CLICK, downClick, false, 0, true);
						break;
					case 1:
						if (!(component is TextInput_X)) { incorrectXMLAlert(); break; }
						_textField = component as TextInput_X;
						_textField.restrict = "-.0123456789";
						_textField.addEventListener(FlexEvent.ENTER, textInputCallback);
						_textField.addEventListener(FocusEvent.FOCUS_OUT, textInputCallback);
						break;
					case 2:
						if (!(component is Button_X)) {	incorrectXMLAlert(); break; }
						_upButton = component as Button_X;
						_upButton.addEventListener(MouseEvent.CLICK, upClick, false, 0, true);
						break;
				}
			}
			if (xml.@fid != undefined) {					
				this.fid = xml.@fid.toString();
			}
			if (xml.@value != undefined && this.field != null) {
				this.field.value = xml.@value.toString();
			}
			if (xml.@layout != undefined) {
				IFieldStandardImpl.setLayout(xml.@layout.toString());
			}
			if (recordAdded) { GMXDictionaries.popCurrentRecord();	}
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		
		private function incorrectXMLAlert():void {
			Alert.show("WARNING: SpinBox created with unexpected XML.  Expected XML has the form of <SpinBox>\n\t<Button/>\n\t<TextInput/>\n\t<Button/>\n</SpinBox>");
		}
//====== BEGIN IField implementation =========================================================
		private var _field:Field;
		public function get field():Field { return _field; }
		public function set field(newField:Field):void {
			_field = newField;
		}
		public function get fid():String { if (_field == null) return null; else return _field.fid; }
		public function set fid(val:String):void {
			if (GMXDictionaries.getCurrentRecord() == null) { return; }
			IFieldStandardImpl.setFid(this, val);
			if (this.field.value == "") { this.field.value = "0"; }
		}
		
		private var _record:Record;
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