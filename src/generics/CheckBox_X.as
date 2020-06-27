package generics
{
	import generics.ComponentCreationEvent;
	import generics.CheckBoxHierarchicalGroup_ISIS_Event;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.ArtworkFilters;
	import constants.Size;
	import flash.filters.GlowFilter;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextLineMetrics;
	
	import mx.controls.Alert;
	import mx.controls.Label;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;

	public class CheckBox_X extends UIComponent implements IField
	{
		public var FOCUS_HALO:GlowFilter = new GlowFilter(0xccccff, 1, 6.0, 6.0, 2.5, 1);
		
		public static const DEFAULT_COMPONENT_HEIGHT:Number = 6 * Size.MM;
		public static const DEFAULT_COMPONENT_WIDTH:Number = 20 * Size.MM;
		
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		protected var _flexibleWidth:Boolean = true;
		public function get flexibleWidth():Boolean { return _flexibleWidth; }
		public function set flexibleWidth(val:Boolean):void { _flexibleWidth = val; }
		
		protected var _buttonSize:Number = NaN;
		public function get buttonSize():Number { return _buttonSize; }
		public function set buttonSize(val:Number):void { 
			_buttonSize = val;
			_label.x = val;
			this.resetSprites(_phase);
		}
		protected var _overColor:uint = 0x9999ff;
		public function get overColor():uint { return _overColor; }
		public function set overColor(val:uint):void { 
			_overColor = val;
			redrawOverColor();
		}
		
		protected function redrawOverColor():void {
			var g:Graphics = _highlightSprite.graphics;
			g.clear();
			g.beginFill(_overColor);
			if (isNaN(_buttonSize)) {
				g.drawRect(0, 0, this.height, this.height);
			} else {
				g.drawRect(0, 0, _buttonSize, _buttonSize);
			}
		}
		
		public function get componentValue():String { 
			if (this.selected) {
				return "true";
			} else if (_partial) {
				return "partial";
			} else return "false";
		}
		public function set componentValue(val:String):void {
			if (val == componentValue) { return; }
			switch(val) {
				case "true":
					this.selected = true;
					this.partial = false;
					break;
				case "partial":
					this.selected = false;
					this.partial = true;
					break;				
				case "false":
					this.selected = false;
					this.partial = false;
					break;
			}
			//if (parent is CheckBoxHierarchicalGroup_ISIS || (parent = null && parent.parent is CheckBoxHierarchicalGroup_ISIS)) {
				//var parentGroup:CheckBoxHierarchicalGroup_ISIS = parent is CheckBoxHierarchicalGroup_ISIS ? parent as CheckBoxHierarchicalGroup_ISIS
				//																						  : parent.parent as CheckBoxHierarchicalGroup_ISIS;
				
				//parentGroup.dataEdit(null); // update the parent accordingly
			//}
		}
		
		public function CheckBox_X()
		{
			_phase = INACTIVE_UP;
			this.height = DEFAULT_COMPONENT_HEIGHT;
			this.width = DEFAULT_COMPONENT_WIDTH;
			this.addEventListener(MouseEvent.CLICK, clicked, false, 0, true);
			super();
		}
		
		private function clicked(event:MouseEvent):void {
			this.dispatchEvent(new CheckBoxHierarchicalGroup_ISIS_Event(CheckBoxHierarchicalGroup_ISIS_Event.CHECK_BOX_GROUP_CHANGE));
		}
		
		public function resetSprites(currentState:String):void {
			_inactiveDisabled = null;
			_inactiveUp = null;
			_inactiveDown = null;
			_activeDisabled = null;
			_activeDown = null;
			_activeUp = null;
			_partialDisabled = null;
			_partialDown = null;
			_partialUp = null;
			while (_button.numChildren != 0) {
				_button.removeChildAt(0);
			}
			switchState(currentState);
		}
		
		override public function set width(val:Number):void {
			super.width = val;
		}
		override public function set height(val:Number):void {
			super.height = val;
			if (!isNaN(buttonSize)) { return; }
			
			_label.x = val;
			redrawOverColor();
			resetSprites(_phase);
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
			this.dispatchEvent(new ComponentCreationEvent(ComponentCreationEvent.CREATED, this, true, true));
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
				if (xml.@value != undefined) { this.field.value = xml.@value.toString(); }
			}
		}		

		public function _set_fontSize(val:String):void { _label.setStyle("fontSize", parseFloat(val)); }
		public function _set_fid(val:String):void { this.fid = val;	}		
		public function _set_glowColor(val:String):void { FOCUS_HALO = new GlowFilter(GMXComponentBuilder.parseColor(val), 1, 6.0, 6.0, 2.5, 1);  }
		public function _set_flexibleWidth(val:String):void { this.flexibleWidth = GMXComponentBuilder.parseBoolean(val); }
		public function _set_overColor(val:String):void { this.overColor = GMXComponentBuilder.parseColor(val); }
		public function _set_overAlpha(val:String):void { _highlightSprite.alpha = parseFloat(val); }
		public function _set_buttonSize(val:String):void { buttonSize = GMXComponentBuilder.parseMM(val); }
		public function _set_sendMessage(val:String):void { _sendMessage = GMXComponentBuilder.parseBoolean(val); }
		public function _set_text(val:String):void { _set_label(val); }
		public function _set_label(val:String):void {
			this.label = val;
			_label.invalidateProperties();
			_label.invalidateSize();
		}
		public function _set_attributes(val:String):void { } // taken care of in the build function
		public function _set_value(val:String):void { } // taken care of in the build function
		public function _set_ruid(val:String):void { } // taken care of in the build function

		//============================================================================================
		//=== Getters & Setters for various flags / properties (updated the state using "switchState" where needed)
		protected var _selected:Boolean = false;
		public function get selected():Boolean { return _selected; }
		public function set selected(val:Boolean):void {
			_selected = val;
			if (_selected) {
				enabled ? switchState(ACTIVE_UP) : switchState(ACTIVE_DISABLED);
			} else if (_partial) {
				enabled ? switchState(PARTIAL_UP) : switchState(PARTIAL_DISABLED);
			} else {
				enabled ? switchState(INACTIVE_UP) : switchState(INACTIVE_DISABLED);
			}			
		}
		protected var _partial:Boolean = false;
		public function get partial():Boolean { return _partial; }
		public function set partial(val:Boolean):void {
			_partial = val;
			if (_partial) {
				enabled ? switchState(PARTIAL_UP) : switchState(PARTIAL_DISABLED);
			} else if (_selected) {
				enabled ? switchState(ACTIVE_UP) : switchState(ACTIVE_DISABLED);
			}  else {
				enabled ? switchState(INACTIVE_UP) : switchState(INACTIVE_DISABLED);
			}			
		}
		protected var _focusOn:Boolean = false;
		public function get focusOn():Boolean { return _focusOn; }
		public function set focusOn(val:Boolean):void {
			_focusOn = val;
		}
		
		public function get label():String {
			return _label.text;
		}
		public function set label(val:String):void {
			_label.text = val;
			_label.invalidateSize();
			_label.invalidateDisplayList();
		}
		protected var _dataGridComponent:Boolean = false;
		public function get dataGridComponent():Boolean { return _dataGridComponent; }
		public function set dataGridComponent(val:Boolean):void {
			_dataGridComponent = val;
		}
		// UI component already has an "enabled" property--override it so as to switch to the right state
		override public function set enabled(value:Boolean):void {
			super.enabled = value;
			this.mouseEnabled = value;
			if (value == false) {
				if (_selected) {
					switchState(ACTIVE_DISABLED);
				} else if (_partial) {
					switchState(PARTIAL_DISABLED);
				} else switchState(INACTIVE_DISABLED);
			} else {
				if (_selected) {
					switchState(ACTIVE_UP);
				} else if (_partial) {
					switchState(PARTIAL_UP);
				} else switchState(INACTIVE_UP);
			}
		}
		//====================================================================================================================================
		//=== override createChildren, commitProperties, measure,  and updateDisplayList to get correct UIComponent instantiation & operation
		//=========================================================================================================================
		override protected function createChildren():void {
			super.createChildren();
			this.addChild(_button);
			this.addChild(_label);
			_label.invalidateSize();
			_label.truncateToFit = false;
			_label.selectable = false;
			_label.mouseEnabled = false;
			_button.mouseEnabled = false;
			_highlightSprite.mouseEnabled = false;
			_highlightSprite.alpha = 0.4;
			this.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, rollOut);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			//this.addEventListener(MouseEvent.MOUSE_UP, mouseClick);
			if (selected) {
				enabled ? _phase = ACTIVE_UP : _phase = ACTIVE_DISABLED; 
			} else if (partial) {
				enabled ? _phase = PARTIAL_UP : _phase = PARTIAL_DISABLED; 
			} else {
				enabled ? _phase = INACTIVE_UP : _phase = INACTIVE_DISABLED;
			}
			this.width = DEFAULT_COMPONENT_WIDTH;
			this.height = DEFAULT_COMPONENT_HEIGHT;
			this.dispatchEvent(new ComponentCreationEvent(ComponentCreationEvent.CREATED, this));
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		override protected function commitProperties():void {
			if (_field != null && this.componentValue != _field.value) { this.componentValue = _field.value; }
			super.commitProperties()
		}
		
		//=== NOTE: measure is very important for proper placement in Containers (like HBoxes and what-not) ====
		override protected function measure():void {
			super.measure();
			/*var MM:Number = Size.MM;
			// _label.textWidth is now updated so as to provide info into how big to make the label
			if (!isNaN(_label.textWidth) && !isNaN(_label.textHeight)) {
				_label.width = _label.textWidth + 3 * MM;
				_label.height = _label.textHeight + 3 * MM;
			}
			//this.measuredHeight = _button.height > _label.height ? _button.height: _label.height;
			this.measuredHeight = DEFAULT_COMPONENT_HEIGHT;
			this.measuredWidth = _button.width + _label.width + 6 * MM;

			// draw a transparent rectangle for this component to catch click / over events
			var g:Graphics = this.graphics;
       		g.clear();
       		g.beginFill(0,0);
       		g.drawRect(0.0, 0.0, this.measuredWidth, this.measuredHeight);
       		g.endFill();*/
		}
		private var _flexibleWidthVal:Number = 0;
		private var _flexibleHeightVal:Number = 0;
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
       		// apply extra filters depending on which flags are set      		
			if (_focusOn) {
				this.filters = [FOCUS_HALO];
				_highlightSprite.visible = true;
				this.addChild(_highlightSprite);
			} else {
				this.filters = [];
				_highlightSprite.visible = false;
			}
			_label.height = _label.textHeight + 4;
			if (!isNaN(_buttonSize)) {
				if (_label.height > this.height) {
					if (_flexibleHeightVal != _label.height) {
						// because UIComponent's set height / set width function invalidates the display list again, it causes an infinite loop
						// so we want to have a way to skip the "this.height = ..." part
						_flexibleHeightVal = _label.height;
						this.height = _label.height;
					}	
				}
			}
			
			if (_flexibleWidth == true) {
				_label.width = _label.textWidth + 4;
				if (_flexibleWidthVal != _label.width) {
					_flexibleWidthVal = _label.width;
					this.width = isNaN(_buttonSize) ? _label.width + this.height : _label.width + _buttonSize; // new width includes button's width (which = the height) and label width
				}
			} else { 
				if (isNaN(_buttonSize)) { _label.width = this.width - this.height; }
				else { _label.width = this.width - _buttonSize; }
			}
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// check box states according to WMI_Specification_Core
		public static const INACTIVE_UP:String = "inactiveUp";
		public static const INACTIVE_DOWN:String = "inactiveDown";
		public static const INACTIVE_DISABLED:String = "inactiveDisabled";
		public static const ACTIVE_UP:String = "activeUp";
		public static const ACTIVE_DOWN:String = "activeDown";
		public static const ACTIVE_DISABLED:String = "activeDisabled";
		public static const PARTIAL_UP:String = "partialUp";
		public static const PARTIAL_DOWN:String = "partialDown";
		public static const PARTIAL_DISABLED:String = "partialDisabled";
		
		public static const RECT_ROUNDING_RADIUS:Number = 5.0;
		
		protected var _phase:String; // indicates the current state
		
		// all of the sprites that will be instantiated as necessary when switchState is called
		protected var _button:UIComponent = new UIComponent(); // serves as the Parent & UIComponent wrapper for all the different sprite states 
		protected var _highlightSprite:FlexSprite = new FlexSprite();
		protected var _inactiveUp:FlexSprite;
		protected var _inactiveDown:FlexSprite;
		protected var _inactiveDisabled:FlexSprite;
		protected var _activeUp:FlexSprite;
		protected var _activeDown:FlexSprite;
		protected var _activeDisabled:FlexSprite;
		protected var _partialUp:FlexSprite;
		protected var _partialDown:FlexSprite;
		protected var _partialDisabled:FlexSprite;
		protected var _partialBox:FlexSprite;
		protected var _label:Label = new Label();
		public function get labelComponent():Label { return _label; }
		
		protected function switchState(newState:String):void {
			_phase = newState;
			if (_button == null) { return; } // createChildren hasn't been called yet, can't switchStates yet
			for (var i:int = 0; i < _button.numChildren; i++) {
				_button.getChildAt(i).visible = false; // make all children invisible (the sprites that have been necessary & thus instantiated)
			}
			var MM:Number = Size.MM;
			var g:Graphics;
			var w:Number = isNaN(_buttonSize) ? this.height : _buttonSize; // makes a square for the checkbox
			var h:Number = w;
			switch(newState) {
				case INACTIVE_UP:
					if (_inactiveUp == null) { // if null, it's not instantiated yet so we need to draw it & add it as a child 
						_inactiveUp = new FlexSprite();
						g = _inactiveUp.graphics;
						g.lineStyle(1.0, 0x333333);
						g.beginFill(0xEBE6DE);
						g.drawRect(0.0, 0.0, w, h);
						_inactiveUp.filters = [ArtworkFilters.BOTTOM_RIGHT_COMPONENT_SHADOW,
											   ArtworkFilters.TOP_LEFT_COMPONENT_GLARE];
						_inactiveUp.mouseEnabled = false;
						_button.addChild(_inactiveUp); 
					}
					_inactiveUp.visible = true; // always make the new state's sprite be visible
					break;
				case INACTIVE_DOWN:
					if (_inactiveDown == null) {
						_inactiveDown = new FlexSprite();
						g = _inactiveDown.graphics;
						g.beginFill(0x999999);
						g.drawRect(0.0, 0.0, w, h);
						_inactiveDown.filters = [ArtworkFilters.TOP_LEFT_COMPONENT_SHADOW,
											 ArtworkFilters.BOTTOM_RIGHT_COMPONENT_GLARE];
						_inactiveDown.mouseEnabled = false;
						_button.addChild(_inactiveDown);
					}
					_inactiveDown.visible = true;
					break;
				case INACTIVE_DISABLED:
					if (_inactiveDisabled == null) {
						_inactiveDisabled = new FlexSprite();
						g = _inactiveDisabled.graphics;
						g.endFill();
						g.lineStyle(1.0, 0x999999);
						g.drawRoundRectComplex(0.0, 0.0, w, h, RECT_ROUNDING_RADIUS, RECT_ROUNDING_RADIUS, RECT_ROUNDING_RADIUS, RECT_ROUNDING_RADIUS);
						_inactiveDisabled.mouseEnabled = false;
						_button.addChild(_inactiveDisabled);
					}
					_inactiveDisabled.visible = true;			
					break;
				case PARTIAL_UP:
					if (_partialUp == null) {
						_partialUp = new FlexSprite();
						g = _partialUp.graphics;
						g.lineStyle(1.0, 0x333333);
						g.beginFill(0xEBE6DE);
						g.drawRect(0.0, 0.0, w, h);
						_partialUp.filters = [ArtworkFilters.BOTTOM_RIGHT_COMPONENT_SHADOW,
											   ArtworkFilters.TOP_LEFT_COMPONENT_GLARE];
						g.endFill();
						g.beginFill(0);
						g.drawCircle(2.25*MM, 2.25*MM, 1.5*MM);
						g.endFill();
						_partialUp.mouseEnabled = false;
						_button.addChild(_partialUp);
					}
					_partialUp.visible = true;
					break;
				case PARTIAL_DOWN:
					if (_partialDown == null) {
						_partialDown = new FlexSprite();
						g = _partialDown.graphics;
						g.beginFill(0x999999);
						g.drawRect(0.0, 0.0, w, h);
						_partialDown.filters = [ArtworkFilters.TOP_LEFT_COMPONENT_SHADOW,
											 ArtworkFilters.BOTTOM_RIGHT_COMPONENT_GLARE];
						g.endFill();
						g.beginFill(0);
						g.drawCircle(2.25*MM, 2.25*MM, 1.5*MM);
						g.endFill();
						_partialDown.mouseEnabled = false;
						_button.addChild(_partialDown);
					}
					_partialDown.visible = true;
					break;
				case PARTIAL_DISABLED:
					if (_partialDisabled == null) {
						_partialDisabled = new FlexSprite();
						g = _partialDisabled.graphics;
						g.endFill();
						g.lineStyle(1.0, 0x999999);
						g.drawRect(0.0, 0.0, w, h);
						g.endFill();
						g.beginFill(0);
						g.drawCircle(2.25*MM, 2.25*MM, 1.5*MM);
						g.endFill();
						_partialDisabled.mouseEnabled = false;
						_button.addChild(_partialDisabled);
					}
					_partialDisabled.visible = true;			
					break;				
				case ACTIVE_UP:
					if (_activeUp == null) {
						_activeUp = new FlexSprite();
						g = _activeUp.graphics;
						g.lineStyle(1.0, 0x333333);
						g.beginFill(0xEBE6DE);
						g.drawRect(0.0, 0.0, w, h);
						_activeUp.filters = [ArtworkFilters.BOTTOM_RIGHT_COMPONENT_SHADOW];
						_activeUp.mouseEnabled = false;
						drawCheck(g);
						_button.addChild(_activeUp);
					}
					_activeUp.visible = true;
					break;
				case ACTIVE_DOWN:
					if (_activeDown == null) {
						_activeDown = new FlexSprite();
						g = _activeDown.graphics;
						g.lineStyle(1.0, 0x333333);
						g.beginFill(0x999999);
						g.drawRect(0.0, 0.0, w, h);
						_activeDown.filters = [ArtworkFilters.TOP_LEFT_COMPONENT_ACTIVE_SHADOW];
						_activeDown.mouseEnabled = false;
						drawCheck(g);
						_button.addChild(_activeDown);
					}
					_activeDown.visible = true;
					break;
				case ACTIVE_DISABLED:
					if (_activeDisabled == null) {
						_activeDisabled = new FlexSprite();
						g = _activeDisabled.graphics;
						g.endFill();
						g.lineStyle(1.0, 0x999999);
						//g.beginFill(0xFFFFFF);
						g.drawRect(0.0, 0.0, w, h);
						_activeDisabled.mouseEnabled = false;
						drawCheck(g);					
						_button.addChild(_activeDisabled);
					}
					_activeDisabled.visible = true;					
					break;
			}
			invalidateDisplayList();
		}
		// helper function for drawing the check in the checkbox (for the ACTIVE states)
		protected function drawCheck(g:Graphics):void {
			var MM:Number = Size.MM;
			var w:Number = isNaN(_buttonSize) ? this.height : _buttonSize; // makes a square for the checkbox
			var h:Number = w;
			g.endFill();
			g.lineStyle(2, 0);
			g.moveTo(h / 4, h / 3);
			g.lineTo(.375 * h, .5 * h);
			g.lineStyle(3, 0);
			g.lineTo(h / 2, .75 * h);
			g.lineTo(.667 * h, h / 2);
			g.lineStyle(2, 0);
			g.lineTo(5 * h / 6, h / 6);
			g.lineStyle(1, 0);
			g.lineTo(h, 0);
		}
		
		//================================================================================================================
		//==== event handlers for those components that change state depending upon mouse interaction ====================
		protected function rollOver(event:MouseEvent):void {
			if (!enabled) { return; }
			_focusOn = true;
			if (_mouseDown) {
				if (_selected) {
				switchState(ACTIVE_DOWN);
				} else if (_partial) {
					switchState(PARTIAL_DOWN);
				} else switchState(INACTIVE_DOWN);
			}
			invalidateDisplayList();
		}
		protected function rollOut(event:MouseEvent):void {
			if (!enabled) { return; }
			if (_phase == ACTIVE_DOWN) {
				switchState(ACTIVE_UP);
			} else if (_phase == INACTIVE_DOWN) {
				switchState(INACTIVE_UP);
			} else if (_phase == PARTIAL_DOWN) {
				switchState(PARTIAL_UP);
			}
			_focusOn = false;
			invalidateDisplayList();
		}
		protected var _mouseDown:Boolean = false;
		protected function mouseDown(event:MouseEvent):void {
			if (!enabled) { return; }
			_mouseDown = true;
			if (_selected) {
				switchState(ACTIVE_DOWN);
			} else if (_partial) {
				switchState(PARTIAL_DOWN);
			} else switchState(INACTIVE_DOWN);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, thisMouseUp); 
			GMXMain.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave, false, 0, true);
		}
		
		protected function mouseLeave(event:Event):void { // mouse up outside of the application
			_mouseDown = false;
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp)
			//stage.removeEventListener(MouseEvent.MOUSE_UP, mouseClick);
		}
		
		protected function thisMouseUp(event:MouseEvent):void {
			_mouseDown = false;
			//event.stopPropagation();
			this.removeEventListener(MouseEvent.MOUSE_UP, thisMouseUp);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (!enabled) { return; }
			if (_dataGridComponent == false) {
				if (_partial) { selected = false; partial = false; }
				else { selected = !_selected; } // setter function switches state 
			}
		}
		
		public function mouseUp(event:MouseEvent):void {
			_mouseDown = false;
			this.removeEventListener(MouseEvent.MOUSE_UP, thisMouseUp);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
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
			switch(this.field.value) { // note: update value must be set before fieldString's component is set
				case "true":
					this.selected = true;
					this.partial = false;
					break;
				case "partial":
					this.selected = false;
					this.partial = true;
					break;
				case "false":
				default:
					this.selected = false;
					this.partial = false;
					this.field.value = "false";
					break;
			}
			this.addEventListener(MouseEvent.CLICK, GMXComponentListeners.checkBoxClick);
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