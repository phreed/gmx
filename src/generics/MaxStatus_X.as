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
	public class MaxStatus_X extends UIComponent_ISIS implements IMultiField 
	{			
		override public function get fieldNames():Array { return ["current", "maxcrit"]; }
		override public function get defaultValues():Array { return ["0","0"]; }
		
		// Setting base width/height to be 6x40MM for now; may be changed later if need be 
		// DEFAULT will set the gauge to be horizontal, the two dimension values will switch if the indicator is vertical
		// There is an XML Attribute /horizontalPos/ which may be set to false for a vertical MaxStatus Gauge
		public static const DEFAULT_COMP_HEIGHT:Number = 15;
		public static const DEFAULT_COMP_WIDTH:Number = 100;
		
		public var current:Field; // The actual level of the gauge; considered out of 100% so legitimate values range from 0-100
		private var _currentValue:Number = 0.0; // 0% is at the left for a horizontal gauge and at the bottom for a vertical gauge
		private var _currentDirty:Boolean = false;
		
		public var maxcrit:Field;
		private var _maxCritValue:Number = 0.0;
		private var _maxCritDirty:Boolean = false;
		
		private var _horizontalPos:Boolean = true; // XML attribute parsed as a boolean 
		private function set horizontalPos(val:Boolean):void {
			_horizontalPos = val;
			if (val == false) { // Makes this a vertical gauge with identical properties made from the dimensions as if it were horizontal then rotated
				this.width = DEFAULT_COMP_HEIGHT;
				this.height = DEFAULT_COMP_WIDTH;
			}
			else { 
				this.width = DEFAULT_COMP_WIDTH;
				this.height = DEFAULT_COMP_HEIGHT;
			}
		}
		private var _dimensionsDirty:Boolean = false;
		
		// Status changes when current value increases above crit values */ORDER/* GREEN-RED
		private static const OK:uint = 0x00FF00; // GREEN 
		private static const CRITICAL:uint = 0xFF0000; // RED
		
		// Sprite variables
		private var _rectOutline:FlexSprite = new FlexSprite();
		private var _maxCritSprite:FlexSprite = new FlexSprite();
		private var _currentLevelSprite:FlexSprite = new FlexSprite();
		
		public function MaxStatus_X()
		{
			super();
			this.horizontalPos = true;
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
			// sprites used to contain the component
			this.addChild(_currentLevelSprite);
			this.addChild(_maxCritSprite);
			this.addChild(_rectOutline);
			_dimensionsDirty = true;
			super.createChildren();
		}
		
		override protected function measure():void {
			super.measure();
		}
		
		override protected function commitProperties():void 
		{
			var val:Number;
			
			if (current != null) {
				val = parseFloat(current.value);
				if (_currentValue != val) {
					_currentDirty = true;
					_currentValue = val;
				}
			}
			if (maxcrit != null) {
				val = parseFloat(maxcrit.value);
				if (_maxCritValue != val) {
					_maxCritDirty = true;
					_maxCritValue = val;
				}
			}
			
			//Considers any of these dirties to invalidate (could separate into multiple different graphics)
			if (_currentDirty || _maxCritDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}	
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var rectOutlineGraphics:Graphics = _rectOutline.graphics;
			var maxCritSpriteGraphics:Graphics = _maxCritSprite.graphics;
			var currentLevelSpriteGraphics:Graphics = _currentLevelSprite.graphics;
			var rectHeight:Number = this.height;
			var rectWidth:Number = this.width;
			//   ____________
			//  |            |rectHeight
			//  |____________|                **** Width is always the longer of the two sides ****
			//    rectWidth
			var statusColor:uint = OK;
			var positionX:Number = 0;
			var positionY:Number = rectHeight/2;
			if (!_horizontalPos) { // If it is vertical then the rectangular dimensions are flipped, but drawn in the same fashion
				rectHeight = this.width;
				rectWidth = this.height;
				positionX = rectHeight / 2;
				positionY = rectWidth;
			}
			var PERCENT_TO_BAR:Number = rectWidth / 100; // Conversion which allows the proper percent to be displayed in terms of the proper bar (level) size
			
			// Outline of the rectangle - Which will be added on top of the other sprites to avoid layering issues
			if (_dimensionsDirty) {
				rectOutlineGraphics.clear();
				_rectOutline.x = positionX;
				_rectOutline.y = positionY;
				rectOutlineGraphics.lineStyle(2.0, 0);
				rectOutlineGraphics.moveTo(0, -rectHeight / 2);
				rectOutlineGraphics.lineTo(rectWidth, -rectHeight / 2);
				rectOutlineGraphics.lineTo(rectWidth, rectHeight / 2);
				rectOutlineGraphics.lineTo(0, rectHeight / 2);
				rectOutlineGraphics.lineTo(0, -rectHeight / 2);
				if (!_horizontalPos) { _rectOutline.rotation = 270; }
			}
			
			// Max Critical Limits are drawn here if needed. 
			// Max Critical Indicator *** RED ***
			if (_dimensionsDirty || _maxCritDirty) {
				maxCritSpriteGraphics.clear();
				if (maxcrit != null) {
					_maxCritSprite.x = positionX;
					_maxCritSprite.y = positionY;
					if (!isNaN(_maxCritValue)) {
						drawSignificantValue(CRITICAL, _maxCritValue, _maxCritSprite);
						if (!_horizontalPos) { _maxCritSprite.rotation = 270; }
					}
				}
				_maxCritDirty = false;
			}
			
			// Creates the bar that represents the current Status of the gauge; either OK or critical
			if (_dimensionsDirty || _currentDirty) {
				if (!isNaN(_currentValue)) {
					if ((_currentValue >= _maxCritValue) && (maxcrit != null)) { // Without checking the field, the bar may accidently appear red when no field is present
						statusColor = CRITICAL;
					}
					else { statusColor = OK; }
				 
					currentLevelSpriteGraphics.clear();
					_currentLevelSprite.x = positionX;
					_currentLevelSprite.y = positionY;
					currentLevelSpriteGraphics.lineStyle(1, 0, 0);
					currentLevelSpriteGraphics.moveTo(0, -rectHeight / 2);
					currentLevelSpriteGraphics.beginFill(statusColor);
					currentLevelSpriteGraphics.lineTo(_currentValue * PERCENT_TO_BAR, -rectHeight / 2);
					currentLevelSpriteGraphics.lineTo(_currentValue * PERCENT_TO_BAR, rectHeight / 2);
					currentLevelSpriteGraphics.lineTo(0, rectHeight / 2);
					currentLevelSpriteGraphics.lineTo(0, -rectHeight / 2);
					currentLevelSpriteGraphics.endFill();
					if (!_horizontalPos) { _currentLevelSprite.rotation = 270; }
				}
				_dimensionsDirty = false;
			}
		}
		/**
		 * Takes in the color of the line and what percentage (out of 100) it occurs at.
		 * Framed by red lines on both sides.
		 * */
		public function drawSignificantValue(color:uint, percentOnBar:Number, spriteUsed:FlexSprite):void {
			var rectHeight:Number = this.height;
			var rectWidth:Number = this.width;
			if (!_horizontalPos) {
				rectHeight = this.width;
				rectWidth = this.height;
			}
			var PERCENT_TO_BAR:Number = rectWidth / 100; // Conversion which allows the proper percent to be displayed in terms of the proper bar (level) size
			var paddingLeft:Number = percentOnBar*PERCENT_TO_BAR - 1; // A slight outline to allow the crit lines to be visible
			var paddingRight:Number = percentOnBar*PERCENT_TO_BAR + 1;
			spriteUsed.graphics.lineStyle(2, color);
			spriteUsed.graphics.moveTo(percentOnBar*PERCENT_TO_BAR, -rectHeight / 2 + 1); // Little less to avoid thick line bleed-through on borders
			spriteUsed.graphics.lineTo(percentOnBar*PERCENT_TO_BAR, rectHeight / 2 - 1);
			spriteUsed.graphics.lineStyle(1, color);
			spriteUsed.graphics.moveTo(paddingLeft, -rectHeight / 2);
			spriteUsed.graphics.lineTo(paddingLeft, rectHeight / 2);
			spriteUsed.graphics.moveTo(paddingRight, -rectHeight / 2);
			spriteUsed.graphics.lineTo(paddingRight, rectHeight / 2);
		}
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary (see ComponentBuilderStandard.as for examples)
		//<MaxStatus ruid="MaxRuid" horizontalPos="false">
		//	<field fid="current" name="current" value="65"/>
		//	<field fid="maxCrit" name="maxCrit" value="95"/>
		//</MaxStatus>
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
		
		public function _set_horizontalPos(val:String):void { this.horizontalPos = GMXComponentBuilder.parseBoolean(val); }
		public function _set_ruid(val:String):void { }
		
	}
}