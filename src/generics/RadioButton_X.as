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
	import generics.ComponentCreationEvent;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import records.RecordRef;
	import records.Record;
	import constants.ArtworkFilters;
	import constants.Size;
	import GMX.Data.RuidVO;
	import mx.controls.Alert;
	import mx.core.FlexSprite;
	import constants.*;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Label;
	import mx.core.UIComponent;

	public class RadioButton_X extends UIComponent implements IField  {
		// radio button states according to WMI_Specification_Core
		public static const INACTIVE_UP:String = "inactiveUp";
		public static const INACTIVE_DOWN:String = "inactiveDown";
		public static const INACTIVE_DISABLED:String = "inactiveDisabled";
		public static const ACTIVE_UP:String = "activeUp";
		public static const ACTIVE_DOWN:String = "activeDown";
		public static const ACTIVE_DISABLED:String = "activeDisabled";
		public static const DRAFT:String = "draft";
		public static const FOCUS_ON:String = "focusOn";
		public static const EMBEDDED_HELP:String = "embeddedHelp";
		public static const RADIUS:Number = 2*Size.MM;
		
		// all of the sprites that will be instantiated as necessary when switchState is called
		private var _buttonSkin:UIComponent = new UIComponent(); // serves as the Parent & UIComponent wrapper for all the different sprite states
		private var _label:Label;
		
		private var _phase:String; // indicates the current state
		public function get phase():String { return _phase; }
		public function set phase(val:String):void { if (switchState(val) == true) { _phase = val; } }
				
		private var _selected:Boolean = false;
		public function get selected():Boolean { return _selected; }
		public function set selected(val:Boolean):void {
			if (_selected == val) { return; }
			_selected = val;
			if (_selected) {
				enabled ? phase = ACTIVE_UP : phase = ACTIVE_DISABLED;
			} else {
				enabled ? phase = INACTIVE_UP : phase = INACTIVE_DISABLED;
			}
		}
		private var _focusOn:Boolean = false;
		public function get focusOn():Boolean { return _focusOn; }
		public function set focusOn(val:Boolean):void {
			_focusOn = val;
		}
		public function get label():String {
			return _label.text;
		}
		public function set label(val:String):void {
			_label.text = val;
			//trace("+==RAD BUTTON label===+");
			//trace("_label.width: " + _label.width);
			//trace("_label.height: " + _label.height);
			//trace("_label.text: " + _label.text);
			//trace("NEW VALUE: " + val);
			//trace("+==END RAD BUTTON label===+");
			invalidateSize();
			invalidateDisplayList();
		}
		private var _dataGridComponent:Boolean = false;
		public function get dataGridComponent():Boolean { return _dataGridComponent; }
		public function set dataGridComponent(val:Boolean):void {
			_dataGridComponent = val;
		}
		// UI component already has an "enabled" property--override it so as to switch to the right state
		override public function set enabled(value:Boolean):void {
			if (enabled == value) { return; }
			
			super.enabled = value;
			this.mouseEnabled = value;
			if (value == true) {
				if (_selected) {
					phase = ACTIVE_UP;
				} else phase = INACTIVE_UP;
			} else {
				if (_selected) {
					phase = ACTIVE_DISABLED;
				} else phase = INACTIVE_DISABLED;
			}
			
		}
		public function get componentValue():String { 
			return label;
		}
		public function set componentValue(val:String):void {
			this.label = val;
			this.invalidateSize();
			this.invalidateDisplayList();
		}
		
		public function RadioButton_X(recordRef:RecordRef = null) {
			super();
			//trace("+========================= RADIO BUTTON CONSTRUCTOR ================================+");
			_label = new Label();
			_label.text = " ";
			_label.x = 9 * Size.MM;
			_label.invalidateSize();
			_label.selectable = false;
			_label.mouseEnabled = false;
			if (recordRef != null) {
				this.record = recordRef.record;
				for each (var field:Field in this.record.fields) {
					// use the 1st field value as the label
					_field = field;
					this.label = field.value;
				//	field.addComponentRequiringUpdate(this);
					break;
				}
			}
		}
		
		public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.pushCurrentRecord(this.record);
				recordAdded = true;
			} //else { Alert.show("WARNING: attempted to add a RadioButton without a ruid.  A ruid & a fid are required (and a value if a label is desired)"); return; }
			if (xml.@fid != undefined) {
				if (this.record == null) {  }
				this.fid = xml.@fid.toString();
				_field.value = xml.@value != undefined ? xml.@value.toString() :
									xml.@label != undefined ? xml.@label.toString() :
									xml.@label1 != undefined ? xml.@label1.toString() :
									xml.@text != undefined ? xml.@text.toString() : 
									field.value; // set it equal to itself
				if (_field.value == null) {
					_field.value = "";
				}
			} //else { Alert.show("WARNING: attempted to add a RadioButton without a fid.  A ruid & a fid are required (and a value if a label is desired)"); return; }
			
			if (xml.@label != undefined) {
				this.label = xml.@label.toString();
			}
			
			if (xml.@layout != undefined) {
				IFieldStandardImpl.setLayout(xml.@layout.toString());
			}
			GMXComponentBuilder.setStandardValues(xml, this);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			invalidateSize();
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		
		
		//====================================================================================================================================
		//=== override createChildren, commitProperties, measure,  and updateDisplayList to get correct UIComponent instantiation & operation
		//=========================================================================================================================
		override protected function createChildren():void {
			super.createChildren();
			//trace("radiobutton createChildren()");
			_buttonSkin = new UIComponent();
			this.addChild(_buttonSkin);
			this.addChild(_label);
			
			//_buttonSkin.mouseEnabled = false;
			var MM:Number = Size.MM;
			_buttonSkin.x = MM;
			_buttonSkin.y = MM;
			this.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			//this.addEventListener(MouseEvent.MOUSE_UP, mouseClick);
			
			if (selected) {
				enabled ? _phase = ACTIVE_UP : _phase = ACTIVE_DISABLED; 
			} else {
				enabled ? _phase = INACTIVE_UP : _phase = INACTIVE_DISABLED;
			}
			phase = phase;
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
			this.dispatchEvent(new ComponentCreationEvent(ComponentCreationEvent.CREATED, this));
		}
		
		override protected function commitProperties():void {
			if (field != null) { this.label = field.value; }
			super.commitProperties();
		}
		
		//=== NOTE: measure is very important for proper placement in Containers (like HBoxes and what-not) ====
		override protected function measure():void {
			super.measure();
			var MM:Number = Size.MM;
			// _label.textWidth is now updated so as to provide info into how big to make the label
			if (!isNaN(_label.textWidth) && !isNaN(_label.textHeight)) {
				_label.width = _label.textWidth + 3 * MM;
				_label.height = _label.textHeight + 3 * MM;
			}
			//trace("+==RAD BUTTON MEASURE===+");
			//trace("this button: " + this);
			//trace("_label.width: " + _label.width);
			//trace("_label.height: " + _label.height);
			//trace("_label.text: " + _label.text);
			//trace("field: " + _field);
			//trace("+==END RAD BUTTON MEASURE===+");
			this.measuredHeight = _buttonSkin.height > _label.height ? _buttonSkin.height: _label.height;
			this.measuredWidth = _buttonSkin.width + _label.width + 6 * MM;
			// draw a transparent rectangle for this component to catch click / over events
			var g:Graphics = this.graphics;
       		g.clear();
       		g.beginFill(0,0);
       		g.drawRect(0.0, 0.0, this.measuredWidth, this.measuredHeight);
       		g.endFill();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
       		super.updateDisplayList(unscaledWidth, unscaledHeight);
       		if (_focusOn) {
				this.filters = [ArtworkFilters.FOCUS_HALO];
			} else this.filters = [];
		}
		
		//================================================================================================================
		//==== event handlers for those components that change state depending upon mouse interaction ====================
		private function rollOver(event:MouseEvent):void {
			if (!enabled) { return; }
			_focusOn = true;
			if (_mouseDown) {
				if (_selected) {
				phase = ACTIVE_DOWN;
				} else phase = INACTIVE_DOWN;
			}
			invalidateDisplayList();
		}
		private function rollOut(event:MouseEvent):void {
			if (!enabled) { return; }
			if (_phase == ACTIVE_DOWN) {
				phase = ACTIVE_UP;
			} else if (_phase == INACTIVE_DOWN) {
				phase = INACTIVE_UP;
			}
			_focusOn = false;
			invalidateDisplayList();
		}
		private var _mouseDown:Boolean = false;
		private function mouseDown(event:MouseEvent):void {
			if (!enabled) { return; }
			_mouseDown = true;
			if (_selected) {
				phase = ACTIVE_DOWN;
			} else phase = INACTIVE_DOWN;
			this.addEventListener(MouseEvent.MOUSE_UP, mouseClick, false, 0, true); 
			stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave, false, 0, true);
		}
		
		private function mouseLeave(event:Event):void { // mouse up outside of the application
			_mouseDown = false;
			if (stage != null) { stage.removeEventListener(Event.MOUSE_LEAVE, mouseLeave);
				//stage.removeEventListener(MouseEvent.MOUSE_UP, mouseClick);
			}
		}
		
		public function mouseClick(event:MouseEvent):void {
			_mouseDown = false;
			if (!enabled) { return; }
			if (stage != null) { this.removeEventListener(MouseEvent.MOUSE_UP, mouseClick) };
			if (event.currentTarget == this && _dataGridComponent == false) {
				// IF NOT UNSELECTABLE
				if (_selected == true) { return; }
				selected = true;
				/* IF UNSELECTABLE
				selected = !_selected; // setter function switches state 
				*/
				this.dispatchEvent(new RadioButton_ISIS_Event(RadioButton_ISIS_Event.RADIO_BUTTON_CLICK, this, true, true));
				if (this._record != null) { this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true)); }
			}
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
		private var _inactiveUp:FlexSprite;
		private var _inactiveDown:FlexSprite;
		private var _inactiveDisabled:FlexSprite;
		private var _activeUp:FlexSprite;
		private var _activeDown:FlexSprite;
		private var _activeDisabled:FlexSprite;
		
		
		public function switchState(newState:String):Boolean {			
			for (var i:int = 0; i < _buttonSkin.numChildren; i++) {
				_buttonSkin.getChildAt(i).visible = false; // make all children invisible (the sprites that have been necessary & thus instantiated)
			}
			switch(newState) {
				case RadioButton_X.INACTIVE_UP: 
					_inactiveUp == null ? _inactiveUp = addNewState(newState)
										: _inactiveUp.visible = true;
					_buttonSkin.addChild(_inactiveUp);
					break;
				case RadioButton_X.INACTIVE_DOWN:
					_inactiveDown == null ? _inactiveDown = addNewState(newState)
										  : _inactiveDown.visible = true;	
					_buttonSkin.addChild(_inactiveDown);
					break;
				case RadioButton_X.INACTIVE_DISABLED:
					_inactiveDisabled == null ? _inactiveDisabled = addNewState(newState)
										  : _inactiveDisabled.visible = true;
					_buttonSkin.addChild(_activeUp);
					break;			
				case RadioButton_X.ACTIVE_UP:
					_activeUp == null ? _activeUp = addNewState(newState)
										  : _activeUp.visible = true;
					_buttonSkin.addChild(_activeUp);
					break;
				case RadioButton_X.ACTIVE_DOWN:
					_activeDown == null ? _activeDown = addNewState(newState)
										  : _activeDown.visible = true;
					_buttonSkin.addChild(_activeDown);
					break;
				case RadioButton_X.ACTIVE_DISABLED:
					_activeDisabled == null ? _activeDisabled = addNewState(newState)
										  : _activeDisabled.visible = true;		
					_buttonSkin.addChild(_activeDisabled);
					break;
				default:
					return false;
			}
			invalidateDisplayList();
			return true;
		}
		
		public function addNewState(state:String):FlexSprite {
			var MM:Number = Size.MM;
			var g:Graphics;
			var w:Number = RADIUS * 2;
			var h:Number = RADIUS * 2;
			
			var sprite:FlexSprite = new FlexSprite;
			g = sprite.graphics;
			sprite.mouseEnabled = false;
			switch(state) {
				case RadioButton_X.INACTIVE_UP:
					g.lineStyle(Line.THIN, 0x333333);
					g.beginFill(0xEBE6DE);
					g.drawCircle(w / 2, h / 2, RadioButton_X.RADIUS);
					break;
				case RadioButton_X.INACTIVE_DOWN:
					g.beginFill(0x999999);
					g.drawCircle(w / 2, h / 2, RadioButton_X.RADIUS);
					break;
				case RadioButton_X.INACTIVE_DISABLED:
					g.endFill();
					g.lineStyle(Line.THIN, 0xcccccc);
					g.drawCircle(w/2,h/2,RadioButton_X.RADIUS);		
					break;			
				case RadioButton_X.ACTIVE_UP:
					g.lineStyle(Line.THIN, 0x333333);
					g.beginFill(0xEBE6DE);
					g.drawCircle(w/2,h/2,RadioButton_X.RADIUS);
					drawDot(g);
					break;
				case RadioButton_X.ACTIVE_DOWN:
					g.lineStyle(Line.THIN, 0x333333);
					g.beginFill(0x999999);
					g.drawCircle(w/2,h/2,RadioButton_X.RADIUS);
					drawDot(g);
					break;
				case RadioButton_X.ACTIVE_DISABLED:
					g.endFill();
					g.lineStyle(Line.THIN, 0xcccccc);
					g.drawCircle(w/2,h/2,RadioButton_X.RADIUS);
					drawDot(g);			
					break;
			}
			sprite.visible = true;
			return sprite;
		}
		
		// helper function for drawing the check in the checkbox (for the ACTIVE states)
		private function drawDot(g:Graphics):void {
			var w:Number = RADIUS * 2;
			var h:Number = RADIUS * 2;
			g.beginFill(0x444444);
			g.drawCircle(w/2, h/2, RadioButton_X.RADIUS/3);
		}
	}
}