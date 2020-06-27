package generics
{
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.core.SpriteAsset;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	/**
	 * ...
	 * @author 
	 */
	public class Icon_X extends UIComponent implements IField
	{
		public function Icon_X()
		{
			super();
			addChild(_icon);
			_icon.mouseEnabled = false;
			_icon.mouseChildren = false;
			_icon.addEventListener(FlexEvent.UPDATE_COMPLETE, iconUpdateComplete);
		}
		protected var _selected:Boolean = false;
		
		protected var _widthIsExplicit:Boolean = false;
		protected var _heightIsExplicit:Boolean = false;
		
		protected var _iconID:String = "";
		protected var _icon:Image = new Image();		
		public function get icon():Image { return _icon; }
		public function set icon(val:Image):void { _icon = val; }
		public function changeIcon(newIconID:String):void {
			if (newIconID == null) { return; }
			var svgAsset:SpriteAsset;
			_iconID = newIconID;
			svgAsset = ComponentIcons.pickImage(newIconID);
			if (svgAsset == null) {
				var path:String = "./assets/" + newIconID;
				_icon.autoLoad = true;
				_icon.source = path;
			} else {
				_icon.source = svgAsset;
			}
			if (_widthIsExplicit) { _icon.width = this.width; }
			if (_heightIsExplicit) { _icon.height = this.height; }
			addChildAt(_icon,0);
			//trace("CHANGE ICON TO : " + newIconID);
		}
		protected var _states:Vector.<String>;
		protected var _currentIndex:int = 0;
		
		protected var _phase:String = "up";
		static public var UP:String = "up";
		static public var OVER:String = "over";
		static public var DOWN:String = "down";
		static public var SELECTED_DOWN:String = "selectedDown";
		static public var SELECTED_UP:String = "selectedUp";
		static public var SELECTED_OVER:String = "selectedOver";
		static public var DISABLED:String = "disabled";
		static public var SELECTED_DISABLED:String = "selectedDisabled";
		
		protected var _upSkin:String;
		protected var _overSkin:String;
		protected var _downSkin:String;
		protected var _selectedDownSkin:String;
		protected var _selectedUpSkin:String;
		protected var _selectedOverSkin:String;
		protected var _disabledSkin:String;
		protected var _selectedDisabledSkin:String;
		
		public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			if (xml.@fid != undefined) {
				this.fid = xml.@fid.toString();
			}
			if (xml.@width != undefined) { _widthIsExplicit = true; }
			if (xml.@height != undefined) { _heightIsExplicit = true; }
			GMXComponentBuilder.setStandardValues(xml, this);
			IFieldStandardImpl.setFields(this, xml);
			if (xml.@icon != undefined) {
				changeIcon(xml.@icon.toString());
			}
			if (xml.@sendMessage != undefined) {
				xml.@sendMessage.toString() == "true" ? this.addEventListener(MouseEvent.CLICK, GMXComponentListeners.iconClick, false, 0, true)
													  : this.removeEventListener(MouseEvent.CLICK, GMXComponentListeners.iconClick);
			}
			if (xml.@value != undefined && this.field != null) {
				this.field.value = xml.@value.toString();
			}
			if (xml.@states != undefined) {
				_states = new Vector.<String>();
				var states:Array = xml.@states.toString().split("|");
				if (states.length == 0) { 
					Alert.show("WARNING: icon states attribute set incorrectly: states='" + (xml.@states.toString()) + "'.  Expected something like '|iconID1|iconID2'");
				} else {
					for (var i:int = 0; i < states.length; i++) {
						_states.push(states[i]);
					}
					if (this.field == null) {
						Alert.show("WARNING: icon states attribute set on an Icon with no fid!  A fid is required to use Icon states!");
					} else {
						componentValue = this.field.value;
					}
				}
			}
			if (xml.@upSkin != undefined) {
				_upSkin = xml.@upSkin.toString();
				changeIcon(_upSkin);
			}
			if (xml.@overSkin != undefined) {
				_overSkin = xml.@overSkin.toString();
				this.addEventListener(MouseEvent.ROLL_OUT, rollOut);
				this.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			}
			if (xml.@downSkin != undefined) {
				_downSkin = xml.@downSkin.toString();
				this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			}
			if (xml.@selectedDownSkin != undefined) {
				_selectedDownSkin = xml.@selectedDownSkin.toString();
				this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			}
			if (xml.@selectedUpSkin != undefined) {
				_selectedUpSkin = xml.@selectedUpSkin.toString();
			}
			if (xml.@selectedOverSkin != undefined) {
				_selectedOverSkin = xml.@selectedOverSkin.toString();
				this.addEventListener(MouseEvent.ROLL_OUT, rollOut);
				this.addEventListener(MouseEvent.ROLL_OVER, rollOver);
			}
			if (xml.@disabledSkin != undefined) {
				_disabledSkin = xml.@disabledSkin.toString();
			}
			if (xml.@selectedDisabledSkin != undefined) {
				_selectedDisabledSkin = xml.@selectedDisabledSkin.toString();
			}
			if (xml.@layout != undefined) {
				IFieldStandardImpl.setLayout(xml.@layout.toString());
			}
			GMXComponentBuilder.processXML(this, xml);
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
				this.componentValue = _field.value;
			}
		}
		
		override public function set enabled(val:Boolean):void {
			if (val == false) {
				if (_selected) {
					if (_selectedDisabledSkin != null) {
						changeIcon(_selectedDisabledSkin);
						_phase = SELECTED_DISABLED;
					}
				} else {
					if (_disabledSkin != null) {
						changeIcon(_disabledSkin);
						_phase = DISABLED;
					}
				}
			} else {
				if (_selected) {
					if (_selectedUpSkin != null) {
						changeIcon(_selectedUpSkin);
						_phase = SELECTED_UP;
					}
				} else {
					if (_upSkin != null) {
						changeIcon(_upSkin);
						_phase = UP;
					}
				}
			}
			super.enabled = val;
		}
		
		//================================================================================================================
		//==== event handlers for those components that change state depending upon mouse interaction ====================
		protected function rollOver(event:MouseEvent):void {
			if (!enabled) { return; }
			if (_mouseDown) {
				if (_selected) {
					if (_selectedDownSkin != null ) { 
						changeIcon(_selectedDownSkin); 
						_phase = SELECTED_DOWN;
					}
				} else {
					if (_downSkin != null) { 
						changeIcon(_downSkin);
						_phase = DOWN;
					}
				}
			} else {
				if (_selected) {
					if (_selectedOverSkin != null ) { 
						changeIcon(_selectedOverSkin); 
						_phase = SELECTED_OVER;
					}
				} else {
					if (_overSkin != null) { 
						changeIcon(_overSkin);
						_phase = OVER;
					}
				}
			}
		}
		protected function rollOut(event:MouseEvent):void {
			if (!enabled) { return; }
			if (_selected) {
				if (_selectedUpSkin != null) { 
					changeIcon(_selectedUpSkin);
					_phase = SELECTED_UP;
				}
			} else {
				if (_upSkin != null) { 
					changeIcon(_upSkin);
					_phase = UP;
				}
			}
		}
		protected var _mouseDown:Boolean = false;
		protected function mouseDown(event:MouseEvent):void {
			if (!enabled) { return; }
			_mouseDown = true;
			if (_selected) {
				if (_selectedDownSkin != null ) { 
					changeIcon(_selectedDownSkin); 
					_phase = SELECTED_DOWN;
				}
			} else {
				if (_downSkin != null) {
					changeIcon(_downSkin); 
					_phase = DOWN;
				}
			} 
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			GMXMain.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave, false, 0, true);
		}
		
		protected function mouseLeave(event:Event):void { // mouse up outside of the application
			_mouseDown = false;
		if (stage != null) { stage.removeEventListener(Event.MOUSE_LEAVE, mouseLeave); }
			//stage.removeEventListener(MouseEvent.MOUSE_UP, mouseClick);
		}
		
		public function mouseUp(event:MouseEvent):void {
			_mouseDown = false;
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (!enabled) { return; }
			if (event.target == this) {
				if (_selected) {
					if (_selectedOverSkin != null ) { 
						changeIcon(_selectedOverSkin); 
						_phase = SELECTED_OVER;
					}
				} else {
					if (_overSkin != null) {
						changeIcon(_overSkin); 
						_phase = OVER;
					}
				} 
			} else {
				if (_selected) {
					if (_selectedUpSkin != null ) { 
						changeIcon(_selectedUpSkin); 
						_phase = SELECTED_UP;
					}
				} else {
					if (_overSkin != null) {
						changeIcon(_overSkin); 
						_phase = UP;
					}
				} 
			}
			
		}
		
		protected function iconUpdateComplete(event:FlexEvent):void {
			if (_icon.content == null) { return; }
			
			if (!_heightIsExplicit && !_widthIsExplicit) { 
				this.width = _icon.width = _icon.content.width;
				this.height = _icon.height = _icon.content.height;
				return;
			} 
			
			var scaleFactorX:Number;
			var scaleFactorY:Number;
			var scaledY:Number;
			var scaledX:Number;
			
			if (_heightIsExplicit && !_widthIsExplicit) { this.width = _icon.width = _icon.content.width; }
			if (_widthIsExplicit && !_heightIsExplicit) { this.height = _icon.height = _icon.content.height; }
			
			if (_icon.content is Bitmap) {
				scaleFactorX = this.width / _icon.content.width;
				scaleFactorY = this.height / _icon.content.height;
				// Flex already scales the bitmap down to the Image's size, but only in the limiting direction, so we need
				// to scale the other direction to fit in the left-over space.
				if (scaleFactorX < scaleFactorY) {
					// x direction is the limiting direction
					_icon.content.scaleX = 1;
					scaledY = _icon.content.height * scaleFactorX;
					_icon.content.scaleY = this.height / scaledY;
				} else {
					// y direction is the limiting direction
					_icon.content.scaleY = 1;
					scaledX = _icon.content.width * scaleFactorY;
					_icon.content.scaleX = this.width / scaledX;
				}
			} else {
				_icon.content.height = this.height;
				_icon.content.width = this.width;
			}
		}
		
		override protected function commitProperties():void {
			if (_field != null) {
				if (_field.value != componentValue) {
					componentValue = _field.value;
				}
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			//trace("updateDisplay List Icon");
			graphics.clear();
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, width, height);
			if (_icon != null && _icon.content != null && _icon.content is Bitmap == false) {
				_icon.content.height = this.height;
				_icon.content.width = this.width;
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		public function get componentValue():String { 
			return _currentIndex + "";
		}
		public function set componentValue(val:String):void {
			if (isNaN(parseInt(val))) { return; }
			if (_states == null || _states.length == 0) { return; }
			
			_currentIndex = parseInt(val);
			if (_currentIndex >= _states.length) {
				trace("WARNING: attempted to set Icon with ruid='" + ruid + "' fid='" + fid + "' to " + _currentIndex + ", but that index is out of bounds!");
				return;
			}
			changeIcon(_states[_currentIndex]);
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
			if (this.field.value == "") { this.field.value = "0"; }
			//trace(" ICON FIELD: " + this.field.value);
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