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
	import constants.Font;
	import constants.Size;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	import flash.display.GraphicsPathWinding;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.FontStyle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import mx.controls.Alert;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	/*
	 * The Dial_X class will be able to take in multiple direction values in degrees
	 * These will be displayed on either a single circle dial or a Double Co-Centric circle dial
	 * In addition the dial will be able to be fixed or rotating
	 * The dial will also be able to display important zones in between the Co-Centric circles
	 */
	public class Dial_X extends UIComponent_ISIS implements IMultiField
	{			
		override public function get fieldNames():Array { return ["currentdir", "commandeddir", "okzonelowerlimit", "okzoneupperlimit", 
													"critzonelowerlimit", "critzoneupperlimit",	"nonappzonelowerlimit",	"nonappzoneupperlimit",
													"track", "units", "planneddir"]; }
		override public function get defaultValues():Array { return ["0", "0", "0", "0",
													"0", "0", "0", "0",
													"0", "0", "0"]; }
		// Setting base width/height to be 200x200, able to be set in XML
		public static const DEFAULT_COMP_HEIGHT:Number = 200;
		public static const DEFAULT_COMP_WIDTH:Number = 200;
		
		public static const RED:uint = 0xEE0000;
		public static const GREEN:uint = 0x00CC00;
		
		// The standard rotation will be 270 Deg to make a standard unit circle with 0 Deg at 12:00 (like a CLOCK)
		// This rotation standard will be changed to make the current arrow stay at 12:00 in fixed mode (other accomodate it)
		private var _rot:Number = 270;
		
		private var _type:String = FIXED;
		private function get type():String { return _type; }
		private function set type(val:String):void {  
			_type = val;
		}
		
		// Default inner radius difference will be 10 pixels
		private var _innerRadDeltaPres:Boolean = true;
		private var _innerRadDeltaValue:Number = 10; 
		
		public var currentdir:Field;
		private var _currentDirValue:Number = 0.0;
		private var _currentDirDirty:Boolean = false;
		
		public var commandeddir:Field;
		private var _commandedDirValue:Number = NaN;
		private var _commandedDirDirty:Boolean = false;
		
		// By initializing some numbers as NaN instead of 0.0 a Boolean will not need to be provided in XML data
		// It will be assumed that by assigning a value for a field will mean that it is needed to be present.
		// With the _innerRad field it will be easier to identify with an extra boolean value
		// If it is assigned and then needs to go away -- assign its value back to NaN (not a number)
		// 0 Will always be treated with significance
		
		public var planneddir:Field;
		private var _plannedDirValue:Number = NaN;
		private var _plannedDirDirty:Boolean = false;
		
		// The Lower Bound for a given zone MUST be lower than it's corresponding Upper Zone Value couterpart
		// The first index of a lower bound will only be paired with the corresponding upper bound index
		// The number of bounds designated in a lower zone must match the corresponding number of bounds in an upper zone
		// Arrays will be created through strings "5|10|15|25|..." using "|" as the delimiter.
		public var okzonelowerlimit:Field; 
		private var _okZoneLowerLimitValues:Array = new Array(); 
		private var _okZoneLowerLimitDirty:Boolean = false;
		
		// The Zone Display will not work correctly if the upper bound is made to be lower than the lower bound
		// Conversely the lower bound should not be higher than the upper bound 
		public var okzoneupperlimit:Field;
		private var _okZoneUpperLimitValues:Array = new Array(); 
		private var _okZoneUpperLimitDirty:Boolean = false;
		
		public var critzonelowerlimit:Field;
		private var _critZoneLowerLimitValues:Array = new Array();
		private var _critZoneLowerLimitDirty:Boolean = false;
		
		public var critzoneupperlimit:Field;
		private var _critZoneUpperLimitValues:Array = new Array();
		private var _critZoneUpperLimitDirty:Boolean = false;
		
		// Non-App Zones will cover any other zone already pre-designated
		public var nonappzonelowerlimit:Field;
		private var _nonAppZoneLowerLimitValues:Array = new Array();
		private var _nonAppZoneLowerLimitDirty:Boolean = false;
		
		public var nonappzoneupperlimit:Field;
		private var _nonAppZoneUpperLimitValues:Array = new Array();
		private var _nonAppZoneUpperLimitDirty:Boolean = false;
		
		public var track:Field;
		private var _trackValue:String = "";
		private var _trackDirty:Boolean = false;
		
		public var units:Field;
		private var _unitsValue:String = "Degrees"; // Parentheses will be added to units' label and will not be necessary in the XML string value
		private var _unitsDirty:Boolean = false;
		
		private var _dimensionsDirty:Boolean = false; //This allows the default dimensions 200x200 to be reconfigured flexibly
		
		public static const FIXED:String = "fixed";
		public static const ROTATING:String = "rotating";
		
		public function Dial_X()
		{
			super();
			this.width = DEFAULT_COMP_WIDTH;
			this.height = DEFAULT_COMP_HEIGHT;
		}
		
		override public function set width(val:Number):void {
			_dimensionsDirty = true;
			super.width = val;
			invalidateDisplayList();
		}
		
		override public function set height(val:Number):void {
			_dimensionsDirty = true;
			super.height = val;
			invalidateDisplayList();
		}
		
		override protected function createChildren():void {
			// *****These children are added in such a way that the Zone are create before the other components, to prevent layering issues ****
			this.addChild(_inZoneSprite);
			this.addChild(_okZonesSprite);
			this.addChild(_critZonesSprite);
			this.addChild(_nonAppZonesSprite);
			this.addChild(_outerCircleSprite);
			this.addChild(_innerCircleSprite);
			this.addChild(_commandedBugSprite);
			this.addChild(_dialLabels);
			this.addChild(_currentDirArrow);
			this.addChild(_plannedDirArrowSprite);
			this.addChild(_centerSprite);
			_dimensionsDirty = true;
			super.createChildren();
		}
		
		override protected function measure():void {
			super.measure();
		}
		
		override protected function commitProperties():void 
		{
			var val:Number;
			var nameVal:String; // used to compare strings for the Title and Units labels
			switch(this.type) {
				case FIXED: _rot = 270; break;
				case ROTATING: _rot = 270 - _currentDirValue; break;
				default: 
				_rot = 270;
			}
			
			// When it parses a string value in the parseFloat method it should give val a value of NaN if it tries to parse a string
			// That is not a number
			if (currentdir != null) {
				val = parseFloat(currentdir.value);
				if (_currentDirValue != val) {
					_currentDirDirty = true;
					_currentDirValue = val;
				}
			}
			if (commandeddir != null) {
				val = parseFloat(commandeddir.value);
				if (_commandedDirValue != val) {
					_commandedDirDirty = true;
					_commandedDirValue = val;
				}
			}
			if (planneddir != null) {
				val = parseFloat(planneddir.value);
				if (_plannedDirValue != val) {
					_plannedDirDirty = true;
					_plannedDirValue = val;
				}
			}
			
			// The Title and the Units will already have string values and will not need any parsing
			if (track != null) {
				nameVal = (track.value);
				if (_trackValue != nameVal) {
					_trackDirty = true;
					_trackValue = nameVal;
				}
			}
			if (units != null) {
				nameVal = (units.value);
				if (_unitsValue != nameVal) {
					_unitsDirty = true;
					_unitsValue = nameVal;
				}
			}
			
			// Arrays will be used to contain substrings for the zone regions allowing not limitations other than
			// the number of lower bounds must equal the number of upper bounds (per each zone ok, crit, prior, nonApp)
			// Refer to splitter function 
		    if (okzonelowerlimit != null) {
				_okZoneLowerLimitDirty = splitter(okzonelowerlimit.value,_okZoneLowerLimitValues,"|");
			 }
			if (okzoneupperlimit != null) {
				_okZoneUpperLimitDirty = splitter(okzoneupperlimit.value,_okZoneUpperLimitValues,"|");
			}
			if (critzonelowerlimit != null) {
				_critZoneLowerLimitDirty = splitter(critzonelowerlimit.value,_critZoneLowerLimitValues,"|");
			}
			if (critzoneupperlimit != null) {
				_critZoneUpperLimitDirty = splitter(critzoneupperlimit.value,_critZoneUpperLimitValues,"|");
			}
			if (nonappzonelowerlimit != null) {
				_nonAppZoneLowerLimitDirty = splitter(nonappzonelowerlimit.value,_nonAppZoneLowerLimitValues,"|");
			}
			if (nonappzoneupperlimit != null) {
				_nonAppZoneUpperLimitDirty = splitter(nonappzoneupperlimit.value,_nonAppZoneUpperLimitValues,"|");
			}
			
			//Considers any of these dirties to invalidate (could separate into multiple different graphics)
			if (_currentDirDirty || _commandedDirDirty || _plannedDirDirty 
			|| _okZoneLowerLimitDirty || _okZoneUpperLimitDirty || _critZoneLowerLimitDirty || _critZoneUpperLimitDirty 
			|| _nonAppZoneLowerLimitDirty || _nonAppZoneUpperLimitDirty	|| _trackDirty || _unitsDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		// Sprite Variables and TextFields used in order to contain the images used to display the dial
		private var angleTextSprite:Array = [new Sprite, new Sprite, new Sprite, new Sprite, new Sprite, new Sprite
			,new Sprite, new Sprite];
		private var angleTextField:Array = [new TextField(), new TextField(), new TextField(), new TextField(), new TextField(), new TextField()
			,new TextField(), new TextField()];
		
		private var _outerCircleSprite:FlexSprite = new FlexSprite();
		private var _innerCircleSprite:FlexSprite = new FlexSprite();
		private var _dialLabels:FlexSprite = new FlexSprite();
		private var _currentDirArrow:FlexSprite = new FlexSprite();
		private var _commandedBugSprite:FlexSprite = new FlexSprite();
		private var _plannedDirArrowSprite:FlexSprite = new FlexSprite();
		private var _okZonesSprite:FlexSprite = new FlexSprite();
		private var _critZonesSprite:FlexSprite = new FlexSprite();
		private var _nonAppZonesSprite:FlexSprite = new FlexSprite();
		private var _inZoneSprite:FlexSprite = new FlexSprite();
		private var _centerSprite:FlexSprite = new FlexSprite();
		private var _dialTitle:TextField = new TextField();
		private var _dialUnits:TextField = new TextField();
		private var _angleHold:Number = new Number;
		
		private const DEG_TO_RAD:Number = Math.PI / 180;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var outerCircleGraphics:Graphics = _outerCircleSprite.graphics;
			var innerCircleGraphics:Graphics = _innerCircleSprite.graphics;
			var currentDirArrowGraphics:Graphics = _currentDirArrow.graphics;
			var commandedGraphics:Graphics = _commandedBugSprite.graphics;
			var plannedDirArrowGraphics:Graphics = _plannedDirArrowSprite.graphics;
			var inZoneSpriteGraphics:Graphics = _inZoneSprite.graphics;
			var centerGraphics:Graphics = _centerSprite.graphics;
			var rad:Number = this.height * .35; // leave space for the labels
			var radInner:Number = 0;
			var i:int = 0;
			
			// Sets the innerRadius value
			if (_innerRadDeltaValue > 0) {
				_innerRadDeltaPres = true;
			}
			else {
				_innerRadDeltaPres = false;
			}
			if (_innerRadDeltaPres) {
				radInner = rad - _innerRadDeltaValue;
			}
			else {
				radInner = rad;
			}
			
			// Sets the type and the rotational angle
			switch(this.type) {
				case FIXED: _rot = 270; break;
				case ROTATING: _rot = 270 - _currentDirValue; break;
				default: 
					_rot = 270;
					Alert.show("WARNING: Dial_X set type had an unexpected string: " + this.type);}
			
			// This first sprite is going to contain the standard creation of the background
			// This will include the co-centric circles, the Dial's name and units involved
			// and the tick marks in addition to the labeling of said tick marks
			if(_dimensionsDirty || _trackDirty || _unitsDirty){
				if (_dimensionsDirty) {
					outerCircleGraphics.clear();
					_outerCircleSprite.x = width / 2;
					_outerCircleSprite.y = height / 2;
					innerCircleGraphics.clear();
					_innerCircleSprite.x = width / 2;
					_innerCircleSprite.y = height / 2;
					
					// This section will create the Rings of the 2 co-centric circles
					outerCircleGraphics.lineStyle(1, 0);
					outerCircleGraphics.drawCircle(0,0,rad);
					innerCircleGraphics.lineStyle(1, 0);
					innerCircleGraphics.drawCircle(0, 0, radInner);
				
					// This section will create the dash marks
					for (i=0; i<72; i++) {
						outerCircleGraphics.moveTo(rad*Math.cos(5*i*DEG_TO_RAD),rad*Math.sin(5*i*DEG_TO_RAD));
						outerCircleGraphics.lineTo((rad+1*Size.MM)*Math.cos(5*i*DEG_TO_RAD),(rad+1*Size.MM)*Math.sin(5*i*DEG_TO_RAD));
					}
					// Major dashes every 15 deg
					outerCircleGraphics.lineStyle(2, 0);
					for (i=0; i<=24; i++) {
						outerCircleGraphics.moveTo(rad*Math.cos(15*i*DEG_TO_RAD),rad*Math.sin(15*i*DEG_TO_RAD));
						outerCircleGraphics.lineTo((rad+2*Size.MM)*Math.cos(15*i*DEG_TO_RAD),(rad+2*Size.MM)*Math.sin(15*i*DEG_TO_RAD));
					}
					
					// This section will create the numbers surrounding the dial
					// Increments will be every 45 degrees 
					// Currently the user may not redefine the increments on these tick marks
					for (i = 0; i < 8; i++) { // Needs ratios based off the radius, not pixels
						angleTextField[i].embedFonts = true;
						angleTextField[i].text = 45 * (i+1) + "";
						angleTextField[i].setTextFormat(Font.SMALL_FONT);
						angleTextField[i].height = angleTextField[i].textHeight + 4;
						angleTextField[i].width = angleTextField[i].textWidth + 4;
						var rotationAlign:Number = 0;
						if (this.type == "fixed") {rotationAlign=270;}
						angleTextSprite[i].addChild(angleTextField[i]);
						angleTextSprite[i].x = (rad+6*Size.MM) * Math.cos((rotationAlign+45 * (i+1)) * DEG_TO_RAD);
						angleTextSprite[i].y = (rad+6*Size.MM) * Math.sin((rotationAlign+45 * (i+1)) * DEG_TO_RAD);
						angleTextField[i].x = -angleTextField[i].width/2;
						angleTextField[i].y = -angleTextField[i].height/2;
						_outerCircleSprite.addChildAt(angleTextSprite[i],i);
					}
				}
				
				// This section will add the Track/Dial Title and the units corresponding
				// Title is centered above the center, large, bolded
				// Units label is centered below in ()
				_dialLabels.graphics.clear();	
				_dialLabels.x = width / 2;
				_dialLabels.y = height / 2;
				_dialLabels.addChild(_dialTitle); // These 2 TextFields will belong to sprite3
				_dialLabels.addChild(_dialUnits); 
				_dialTitle.text = _trackValue;
				_dialTitle.setTextFormat(Font.LARGE_FONT);
				_dialTitle.x = -.5*_dialTitle.textWidth;
				_dialTitle.y = -1.25 * _dialTitle.textHeight;
				_dialTitle.width = _dialTitle.textWidth + 4;
				_dialTitle.height = _dialTitle.textHeight + 4;
				_dialUnits.text = "(" + _unitsValue + ")";
				_dialUnits.setTextFormat(Font.SMALL_FONT_GENERIC);
				_dialUnits.x = -.5*_dialUnits.textWidth;
				_dialUnits.y = 0;
				_dialUnits.width = _dialUnits.textWidth + 4;
				_dialUnits.height = _dialUnits.textHeight + 4;
				_trackDirty = false; 
				_unitsDirty = false;
			}
				
			//This section will create the crit/priority zone fill which will need to be added after the ZONES
			// These Sprites make more sense to come before the planned/custom values (i.e. the black circles should be on top of the zones)
			if (_dimensionsDirty|| _currentDirDirty || _okZoneLowerLimitDirty  || _okZoneUpperLimitDirty || _critZoneLowerLimitDirty || _critZoneUpperLimitDirty 
				|| _nonAppZoneLowerLimitDirty || _nonAppZoneUpperLimitDirty) {
				
				// This section creates the Black Current Direction Arrow (Actual Value) as its own sprite
				if (_dimensionsDirty || _currentDirDirty) { 
					currentDirArrowGraphics.clear();
					_currentDirArrow.x = width / 2;
					_currentDirArrow.y = height / 2;
					centerGraphics.clear();
					_centerSprite.x = width / 2;
					_centerSprite.y = height / 2;
					currentDirArrowGraphics.lineStyle(2, 0);
					currentDirArrowGraphics.beginFill(0);
					currentDirArrowGraphics.moveTo(0, 0);
					currentDirArrowGraphics.lineTo((radInner - 5 * Size.MM) * Math.cos(_currentDirValue * DEG_TO_RAD), (radInner - 5 * Size.MM) * Math.sin(_currentDirValue * DEG_TO_RAD));
					currentDirArrowGraphics.lineStyle(1, 0);
					centerGraphics.lineStyle(1, 0);
					centerGraphics.beginFill(0xFFFFFF);
					centerGraphics.drawCircle(0,0,1*Size.MM);
					currentDirArrowGraphics.endFill();
					currentDirArrowGraphics.beginFill(0xFFFFFF);
					currentDirArrowGraphics.moveTo((radInner-5*Size.MM)*Math.cos((_currentDirValue)*DEG_TO_RAD),(radInner-5*Size.MM)*Math.sin((_currentDirValue)*DEG_TO_RAD));
					currentDirArrowGraphics.lineTo((radInner-5*Size.MM)*Math.cos((_currentDirValue-5)*DEG_TO_RAD),(radInner-5*Size.MM)*Math.sin((_currentDirValue-5)*DEG_TO_RAD));
					currentDirArrowGraphics.lineTo(radInner*Math.cos(_currentDirValue*DEG_TO_RAD),radInner*Math.sin(_currentDirValue*DEG_TO_RAD));
					currentDirArrowGraphics.lineTo((radInner-5*Size.MM)*Math.cos((_currentDirValue+5)*DEG_TO_RAD),(radInner-5*Size.MM)*Math.sin((_currentDirValue+5)*DEG_TO_RAD));
					currentDirArrowGraphics.lineTo((radInner-5*Size.MM)*Math.cos(_currentDirValue*DEG_TO_RAD),(radInner-5*Size.MM)*Math.sin(_currentDirValue*DEG_TO_RAD));
					currentDirArrowGraphics.endFill();
					_currentDirArrow.rotation = (_rot);
					
					if (this.type == "rotating") {
						_outerCircleSprite.rotation = (_rot);
						_innerCircleSprite.rotation = (_rot);
						for(i = 0; i < angleTextSprite.length; i++) {
							angleTextSprite[i].rotation = -_rot;	
						}
						_okZonesSprite.rotation = _rot;
						_critZonesSprite.rotation = _rot;
						_nonAppZonesSprite.rotation = _rot;
						_commandedBugSprite.rotation = _rot; 
						_plannedDirArrowSprite.rotation = _rot;
					}
					_currentDirDirty = false;
				}
				inZoneSpriteGraphics.clear();
				_inZoneSprite.x = width / 2;
				_inZoneSprite.y = height / 2;
				
				// Crit zone indication
				for (i=0; i<_critZoneLowerLimitValues.length;i++) {
					if ((_currentDirValue>=_critZoneLowerLimitValues[i])&&(_currentDirValue<=_critZoneUpperLimitValues[i])) {
						inZoneSpriteGraphics.beginFill(RED,.8);
						Graphics_ISIS.drawArcZ(radInner,0,_currentDirValue,_inZoneSprite,true);
						inZoneSpriteGraphics.endFill();
						_inZoneSprite.rotation = (_rot);
					}
				}
				
				// This section will create the ok Zones on the dial
				if ((_dimensionsDirty || _okZoneLowerLimitDirty || _okZoneUpperLimitDirty) && _innerRadDeltaPres){
					drawZone(_okZoneLowerLimitValues,_okZoneUpperLimitValues,radInner,rad,GREEN,_okZonesSprite);
					_okZoneLowerLimitDirty = false;
					_okZoneUpperLimitDirty = false;
				}
				
				// This section will create the critical Zones on the dial
				if ((_dimensionsDirty || _critZoneLowerLimitDirty || _critZoneUpperLimitDirty) && _innerRadDeltaPres) {
					drawZone(_critZoneLowerLimitValues,_critZoneUpperLimitValues,radInner,rad,RED,_critZonesSprite);
					_critZoneLowerLimitDirty = false;
					_critZoneUpperLimitDirty = false;
				}
				
				// This section will create the non-App Zones on the dial
				if ((_dimensionsDirty || _nonAppZoneLowerLimitDirty || _nonAppZoneUpperLimitDirty) && _innerRadDeltaPres) {
					drawZone(_nonAppZoneLowerLimitValues,_nonAppZoneUpperLimitValues,radInner,rad,0xAAAAAA,_nonAppZonesSprite);
					_nonAppZoneLowerLimitDirty = false;
					_nonAppZoneUpperLimitDirty = false;
				}
			}
			 
				// This section creates the teal commanded bug, which is displayed on the outside of the dial
				if (_dimensionsDirty || _commandedDirDirty) {
					commandedGraphics.clear();
					_commandedBugSprite.x = this.width / 2;
					_commandedBugSprite.y = this.height / 2;
					if (!isNaN(_commandedDirValue)) {
						commandedGraphics.lineStyle(1, 0);
						commandedGraphics.beginFill(0x0000EE);
						commandedGraphics.moveTo(5 * Math.cos((_commandedDirValue - 90) * DEG_TO_RAD), 5 * Math.sin((_commandedDirValue - 90) * DEG_TO_RAD));
						commandedGraphics.lineTo(5 * Math.cos((_commandedDirValue + 90) * DEG_TO_RAD), 5 * Math.sin((_commandedDirValue + 90) * DEG_TO_RAD));
						commandedGraphics.lineTo((radInner - 10) * Math.cos((_commandedDirValue + 5) * DEG_TO_RAD), (radInner - 10) * Math.sin((_commandedDirValue + 5) * DEG_TO_RAD));
						commandedGraphics.lineTo((radInner -10) * Math.cos((_commandedDirValue + 10) * DEG_TO_RAD), (radInner -10) * Math.sin((_commandedDirValue + 10) * DEG_TO_RAD));
						commandedGraphics.lineTo(rad * Math.cos(_commandedDirValue * DEG_TO_RAD), rad * Math.sin(_commandedDirValue * DEG_TO_RAD));
						commandedGraphics.lineTo((radInner -10) * Math.cos((_commandedDirValue - 10) * DEG_TO_RAD), (radInner -10) * Math.sin((_commandedDirValue - 10) * DEG_TO_RAD));
						commandedGraphics.lineTo((radInner - 10) * Math.cos((_commandedDirValue - 5) * DEG_TO_RAD), (radInner - 10) * Math.sin((_commandedDirValue - 5) * DEG_TO_RAD));
						commandedGraphics.lineTo(5 * Math.cos((_commandedDirValue - 90) * DEG_TO_RAD), 5 * Math.sin((_commandedDirValue - 90) * DEG_TO_RAD));
						commandedGraphics.endFill();
					}
					_commandedBugSprite.rotation = _rot;
					_commandedDirDirty = false;
				}
				
				// This section creates the planned direction arrow in between the radii (only appears when the radiusDelta is present)
				if ((_dimensionsDirty || _plannedDirDirty) && _innerRadDeltaPres) {
					plannedDirArrowGraphics.clear();
					_plannedDirArrowSprite.x = width / 2;
					_plannedDirArrowSprite.y = height / 2;
					if (!isNaN(_plannedDirValue)) {
						plannedDirArrowGraphics.lineStyle(2, 0);
						plannedDirArrowGraphics.beginFill(0xFFFFFF);
						plannedDirArrowGraphics.moveTo(radInner*Math.cos(_plannedDirValue*DEG_TO_RAD),radInner*Math.sin(_plannedDirValue*DEG_TO_RAD));
						plannedDirArrowGraphics.lineTo(rad*Math.cos((_plannedDirValue-3)*DEG_TO_RAD),rad*Math.sin((_plannedDirValue-3)*DEG_TO_RAD));
						plannedDirArrowGraphics.lineTo(rad*Math.cos((_plannedDirValue+3)*DEG_TO_RAD),rad*Math.sin((_plannedDirValue+3)*DEG_TO_RAD));
						plannedDirArrowGraphics.lineTo(radInner*Math.cos(_plannedDirValue*DEG_TO_RAD),radInner*Math.sin(_plannedDirValue*DEG_TO_RAD));
						_plannedDirArrowSprite.rotation = (_rot); 
					}
					_plannedDirDirty = false;
				}
				
				// Each dirty is set to false in such a way as to avoid unnecessary re-drawings
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		/**
		 * This function will create a colored zone in between the inner and outer radius.
		 * This zone should be able to exist in multiple places on the same dial.
		 * The lengths of the two arrays must match or else an alert will be thrown.
		 * The corresponding indexes lowerLimit[0] and upperLimit[0] will represent
		 * one individual zone...etc. [RANGE IS IN DEGREES]
		*/
		private function drawZone(lowerZoneVals:Array, upperZoneVals:Array, innerRadValue:Number,
			outerRadValue:Number, zoneColor:uint, spriteInvolved:Sprite):void {
			spriteInvolved.graphics.clear();
			spriteInvolved.x = width / 2;
			spriteInvolved.y = height / 2;
			spriteInvolved.graphics.lineStyle(1,0);
			innerRadValue = innerRadValue+1;
			outerRadValue = outerRadValue-1;
			if (lowerZoneVals.length != upperZoneVals.length) {
				Alert.show("ARRAY RANGE FOR UPPER AND LOWER ZONE BOUNDS IN DIAL_X DO NOT MATCH");
				return;
			}
			spriteInvolved.graphics.lineStyle(1,zoneColor,.5);
			for ( var z:int=0; z<lowerZoneVals.length; z++) {
				if (lowerZoneVals[z]!=upperZoneVals[z]){
					spriteInvolved.graphics.beginFill(zoneColor);
					spriteInvolved.graphics.moveTo(innerRadValue*Math.cos(lowerZoneVals[z]*DEG_TO_RAD),
						innerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
					spriteInvolved.graphics.lineTo(outerRadValue*Math.cos(lowerZoneVals[z]*DEG_TO_RAD),
						outerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
					Graphics_ISIS.drawArcZ(outerRadValue,lowerZoneVals[z],upperZoneVals[z],spriteInvolved,false);
					spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(upperZoneVals[z]*DEG_TO_RAD),
						innerRadValue*Math.sin(upperZoneVals[z]*DEG_TO_RAD));
					for (var ex:Number = upperZoneVals[z]-1.0; ex>=lowerZoneVals[z]; ex--) {
						spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(ex*DEG_TO_RAD),innerRadValue*Math.sin(ex*DEG_TO_RAD));
					}
					if (z != lowerZoneVals[z]) {
						spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(lowerZoneVals[z] * DEG_TO_RAD), innerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
					}		
					spriteInvolved.graphics.endFill();
					spriteInvolved.rotation = (_rot);
				}
			}	
		}
		/** The splitter function accepts the XML string used for the zones and places the data into 
		 * an array separating out the numbers with a defined delimiter.
		 * Gives back a boolean which is true if the values are different than they were before.
		*/
		public function splitter(string:String, arrayUsed:Array, delimString:String):Boolean {
			var split:Array = string.split(delimString);
			var dirty:Boolean = false;
			for (var i:int = 0; i<split.length; i++) {
				var val:Number = parseFloat(split[i]);
				if(arrayUsed[i] != val) {
					dirty = true;
					arrayUsed[i] = val;
				}
			}
			if (split.length < arrayUsed.length) {
				arrayUsed.splice(split.length,arrayUsed.length-split.length);
			}
			return dirty;
		}
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//   <Dial_X ruid="dialRuid" type="rotating" innerRadDeltaValue="10">
		//	<field fid="currentdir" name="currentDir"/>
		//	<field fid="commandedDir" name="commandedDir"/>
		//	<field fid="plannedDir" name="plannedDir"/>
		//	<field fid="okZoneLowerLimit" name="okZoneLowerLimit"/>
		//	<field fid="okZoneUpperLimit" name="okZoneUpperLimit"/>
		//	<field fid="priorityZoneLowerLimit" name="priorityZoneLowerLimit"/>
		//	<field fid="priorityZoneUpperLimit" name="priorityZoneUpperLimit"/>
		//	<field fid="critZoneLowerLimit" name="critZoneLowerLimit"/>
		//	<field fid="critZoneUpperLimit" name="critZoneUpperLimit"/>
		//	<field fid="track" name="track" value="Temperature"/>
		//	<field fid="units" name="units" value="Kelvin"/>
		// </Dial_X>
		// since Dial_X is a "MultiField" implementation, you could give the Dial a ruid, like this:
		//			<Dial ruid="dialRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			if (xml.@innerRadDeltaValue != undefined) {
				_innerRadDeltaValue = GMXComponentBuilder.parseMM(xml.@innerRadDeltaValue.toString());
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			if (xml.@type != undefined) {
				this.type = xml.@type.toString();
			}
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}