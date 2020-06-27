package generics
{
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import interfaces.UIComponent_ISIS;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextLineMetrics;
	import mx.controls.Alert;
	import mx.controls.Label;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author 
	 */
	public class Joystick_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["xaxis", "yaxis"]; }
		override public function get defaultValues():Array { return ["0",     "0"]; }
		
		private static const DEFAULT_JOYSTICK_HEIGHT:Number = 75;
		private static const DEFAULT_JOYSTICK_WIDTH:Number = 75;
		private static const DEFAULT_RADIUS:Number = DEFAULT_JOYSTICK_WIDTH / 2;
		
		public function Joystick_X() 
		{
			super();
			this.width = DEFAULT_JOYSTICK_WIDTH;
			this.height = DEFAULT_JOYSTICK_HEIGHT;
			_joystick = new FlexSprite();
			_joystick.addEventListener(MouseEvent.MOUSE_DOWN, joystickDown);
			
			_up = new Label();
			_down = new Label();
			_left = new Label();
			_right = new Label();
			formatLabel(_up);
			formatLabel(_down);
			formatLabel(_left);
			formatLabel(_right);
			_up.text = "";
			_down.text = "";
			_left.text = "";
			_right.text = "";
			this.addChild(_joystick);
			_dimensionsDirty = true;
		}
		
		private function formatLabel(label:Label):void {
			label.setStyle("fontSize", 8);
			label.setStyle("textAlign", "center");
			label.mouseEnabled = false;
			label.mouseChildren = false;
			label.truncateToFit = false;
			label.height = 6 * Size.MM;
			this.addChild(label);
		}
		
		private function resizeLabel(label:Label, string:String):void {
			var metrics:TextLineMetrics = label.measureText(string);
			label.width = metrics.width + 3 * Size.MM;
			//label.height = metrics.height + 3 * Size.MM;
		}
		
		private var _stickColorOutside:int = 0x00bbbb;
		private var _stickColorInside:int = 0x000000;
		private var _baseColor:int = 0xffff00;
		private var _baseDisabledColor:int = 0xbbbbbb;
		
		private var _up:Label;
		private var _down:Label;
		private var _left:Label;
		private var _right:Label;
		private var _referencePoint:Point;
		private var _newPoint:Point;
		private function joystickDown(event:MouseEvent):void {
			if (xaxis == null && yaxis == null) { return; } // can't do anything with it if there are no fields
			
			_referencePoint = new Point(width/2, height/2);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, joystickMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, joystickUp, false, 0, true);
		}
		private function joystickMove(event:MouseEvent):void {
			_newPoint = new Point(this.mouseX, this.mouseY);
			//trace("newPoint: " + _newPoint + "    referencPoint: " + _referencePoint);
			var vector:Point = _newPoint.subtract(_referencePoint);
			var halfWidth:Number = width / 2;
			var halfHeight:Number = height / 2;
			var newXVal:String;
			var newYVal:String;
			var tempVal:Number;
			if (yaxis == null) { // xaxis must not be null or joystickDown wouldn't have run through
				tempVal = Math.round(100 * (_newPoint.x - halfWidth) / halfWidth);
				if (tempVal > 100) { tempVal = 100; }
				else if (tempVal < -100) { tempVal = -100; }
				newXVal = "" + tempVal;
				if (newXVal == xaxis.value) { return; }
				xaxis.value = newXVal;
			} else if (xaxis == null) { // yaxis must not be null
				tempVal = Math.round(100 * (_newPoint.y - halfHeight) / halfHeight);
				if (tempVal > 100) { tempVal = 100; }
				else if (tempVal < -100) { tempVal = -100; }
				newYVal = "" + tempVal;
				if (newYVal == yaxis.value) { return; }
				yaxis.value = newYVal;
			} else { // 2-axis joystick
				var distanceRatio:Number = vector.length / halfWidth;
				if (distanceRatio > 1) {
					vector.x = vector.x / distanceRatio;
					vector.y = vector.y / distanceRatio;
					_newPoint = _referencePoint.clone();
					_newPoint.offset(vector.x, vector.y);
				}
				newXVal = "" + Math.round(100 * (_newPoint.x - halfWidth) / halfWidth);
				newYVal = "" + Math.round(-100 * (_newPoint.y - halfWidth) / halfWidth);
				if (newXVal == xaxis.value && newYVal == yaxis.value) { return; }
				yaxis.value = newYVal;
				xaxis.value = newXVal;
			}
			this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
		}
		private function joystickUp(event:MouseEvent):void {
			if (xaxis != null) { xaxis.value = "0"; } // the fields call invalidateProperties on this Joystick
			if (yaxis != null) { yaxis.value = "0"; }
			this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, joystickMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, joystickUp);
		}
		
		override public function set enabled(val:Boolean):void {
			super.enabled = val;
			if (val == false) {
				this.mouseChildren = false;
				if (xaxis != null) { xaxis.value = "" + 0; this.invalidateProperties(); }
				if (yaxis != null) { yaxis.value = "" + 0; this.invalidateProperties(); }
			} else {
				this.mouseChildren = true;
			}
			this.invalidateDisplayList();
		}
		
		
		// children components
		private var _joystick:FlexSprite;
		public var xaxis:Field;
		public var yaxis:Field;
		
		override protected function createChildren():void {
			// here in the createChildren function, add all the code that draws the component, as well as the fields that are created.
			super.createChildren();
		}
		override protected function measure():void {
			super.measure();
		}
		
		private var _xAxisValue:Number = 0.0;
		private var _yAxisValue:Number = 0.0;
		private var _dimensionsDirty:Boolean = false;
		private var _joystickPositionDirty:Boolean = false;
		
		override protected function commitProperties():void {
			var val:Number;
			if (xaxis != null) { 
				val = parseFloat(xaxis.value);
				if (_xAxisValue != val) {
					_xAxisValue = val;
					_joystickPositionDirty = true;
				}
			}
			//trace("joystick commit properties");
			if (yaxis != null) {
				val = parseFloat(yaxis.value);
				if (_yAxisValue != val) {
					_yAxisValue = val;
					_joystickPositionDirty = true;
				}
			}
			this.invalidateDisplayList();
			super.commitProperties();
		}
		
		override public function set width(val:Number):void {
			_dimensionsDirty = true;
			super.width = val;
		}
		override public function set height(val:Number):void {
			_dimensionsDirty = true;
			super.height = val;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var g:Graphics;
			var halfWidth:Number = this.width / 2;
			var halfHeight:Number = this.height / 2;
			if (_joystickPositionDirty) {
				_joystickPositionDirty = false;
				_joystick.x = halfWidth + halfWidth * (_xAxisValue / 100.0);
				_joystick.y = halfHeight + halfHeight * ( -_yAxisValue / 100.0);
				if ((xaxis == null) && (yaxis != null)) { // Prevents the Vertical Bar from becomming inverted is [_xAsis:Field == null]
					_joystick.y = halfHeight + halfHeight * ( _yAxisValue / 100.0);
				}
			}
			if (_dimensionsDirty) {
				_dimensionsDirty = false;
				
				g = _joystick.graphics;
				g.clear();
				g.lineStyle(1, 0);
				g.beginFill(_stickColorOutside);
				if (xaxis != null && yaxis != null) {
					g.drawCircle(0, 0, this.width / 9);
					g.endFill();
					g.lineStyle(1, 0, .7);
					g.beginFill(_stickColorInside, .7);
					g.drawCircle(0, 0, this.width / 20);
					g.endFill();
				} else if (xaxis != null) { // horizontal joystick
					g.beginFill(_stickColorOutside);
					g.drawRoundRect( -3 * Size.MM, -this.height / 2 - 1.5 * Size.MM, 6 * Size.MM, this.height + 3 * Size.MM, 15, 15);
					//g.drawRect( -1.5 * Size.MM, -this.height / 2 - 1.5 * Size.MM, 3 * Size.MM, this.height + 3 * Size.MM);
				} else if (yaxis != null) { // vertical joystick
					g.beginFill(_stickColorOutside);
					g.drawRoundRect( -this.width / 2 - 1.5 * Size.MM, -3 * Size.MM, this.width + 3 * Size.MM, 6 * Size.MM, 15, 15);
					//g.drawRect(-this.width / 2 - 1.5 * Size.MM, -1.5 * Size.MM, this.width + 3 * Size.MM, 3 * Size.MM);
				}
				_joystick.x = width / 2;
				_joystick.y = height / 2;
				
				
				_up.x = _down.x = (this.width - _up.width) / 2;
				_left.x = 0;
				_right.x = this.width - _right.width;
				_up.y = 0;
				_down.y = this.height - _down.height;
				_right.y = _left.y = (this.height - _left.height) / 2;
			}
			
			g = this.graphics;
			g.clear();
			g.lineStyle(1.0, 0);
			this.enabled ? g.beginFill(_baseColor) : g.beginFill(_baseDisabledColor);
			if (xaxis != null && yaxis != null) {
				g.drawCircle(this.width / 2, this.height / 2, this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .75 * this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .75 * this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .5 * this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .5 * this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .25 * this.width / 2);
				g.drawCircle(this.width / 2, this.height / 2, .25 * this.width / 2);
				g.endFill();
			} else { // horizontal or vertical joystick
				g.drawRect(0, 0, this.width, this.height);
				g.endFill();
				g.lineStyle(0, _baseColor);
				g.beginFill(_baseColor);
				g.drawRect(.125*this.width, .125*this.height, .75 * this.width, .75 * this.height);
				g.endFill();
			}
			
			// Creates a reference to where the pointer comes from
			// Line to joystick, double line if a field is missing
			g.lineStyle(2 * this.width / 9, 0);
			if ((xaxis != null) && (yaxis != null)) {
				g.moveTo(halfWidth, halfHeight);
				g.lineTo(_joystick.x, _joystick.y);
			}
			if ((xaxis != null) && (yaxis == null)) {
				g.moveTo(halfWidth, .5 * halfHeight);
				g.lineTo(_joystick.x, _joystick.y - .5 * halfHeight);
				g.moveTo(halfWidth, 1.5 * halfHeight);
				g.lineTo(_joystick.x, _joystick.y + .5 * halfHeight);
			}
			if ((xaxis == null) && (yaxis != null)) {
				g.moveTo(.5 * halfWidth, halfHeight);
				g.lineTo(_joystick.x - .5 * halfWidth, _joystick.y);
				g.moveTo(1.5 * halfWidth, halfHeight);
				g.lineTo(_joystick.x + .5 * halfWidth, _joystick.y);
			}
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//			<Joystick ruid="joystick-ruid"/>
        //			   <field fid="xAxisFid" name="xAxis"/>
        //			   <field fid="yAxisFid" name="yAxis"/>
        //			</Joystick>
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			GMXComponentBuilder.processXML(this, xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
		
		public function _set_upText(val:String):void { _up.text = val; resizeLabel(_up, val); }
		public function _set_downText(val:String):void { _down.text = val; resizeLabel(_down, val); }
		public function _set_leftText(val:String):void { _left.text = val; resizeLabel(_left, val); }
		public function _set_rightText(val:String):void { _right.text = val; resizeLabel(_right,  val); }
		public function _set_stickColorOutside(val:String):void { _stickColorOutside = GMXComponentBuilder.parseColor(val); }
		public function _set_stickColorInside(val:String):void { _stickColorInside = GMXComponentBuilder.parseColor(val); }
		public function _set_baseColor(val:String):void { _baseColor = GMXComponentBuilder.parseColor(val); }
		public function _set_baseDisabledColor(val:String):void { _baseDisabledColor = GMXComponentBuilder.parseColor(val); }
		public function _set_ruid(val:String):void { } // implemented in build function
	}
}