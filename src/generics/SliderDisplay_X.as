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
	import mx.containers.utilityClasses.Flex;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	import flash.display.GraphicsPathWinding;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import mx.controls.Alert;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	/*
	 * SliderDisplay_X takes in only one field, and that field is the actual percentage displayed
	 * on the slider. The color of the bar may be accessed through the XML attribute @barColor
	 */ 
	public class SliderDisplay_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["actual"]; }
		override public function get defaultValues():Array { return ["0"]; }
		// Default dimensions will be x but may be changed if necessary
		public static const DEFAULT_COMP_HEIGHT:Number = 50;
		public static const DEFAULT_COMP_WIDTH:Number = 10;
		
		private var BAR_FILL:uint = 0xE4E4E4; // Default color is silver: Set different color in layout barColor="ff0000" (red for example)
		
		public var actual:Field;
		private var _actualValue:Number = 0.0; 
		private var _actualDirty:Boolean = false;
		
		private var _outline:FlexSprite = new FlexSprite();
		private var _mainSprite:FlexSprite = new FlexSprite();
		private var _indicator:FlexSprite = new FlexSprite();
		
		private var _dimensionsDirty:Boolean = false;
		
		public function SliderDisplay_X() 
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
			// here in the createChildren function, add all the code that draws the component, as well as the fields that are created.
			this.addChild(_mainSprite);
			this.addChild(_indicator); // Indicator added first to avoid stacking issues
			this.addChild(_outline);
			_dimensionsDirty = true;
			super.createChildren();
		}
		
		override protected function measure():void {
			super.measure();
		}
		
		override protected function commitProperties():void {
			var val:Number;
			if (actual != null) {
				val = parseFloat(actual.value);
				if (_actualValue != val) {
					_actualDirty = true;
					_actualValue = val;
				}
			}
			if (_actualDirty) {
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var mainSpriteGraphics:Graphics = _mainSprite.graphics;
			var indicatorGraphics:Graphics = _indicator.graphics;
			var outlineGraphics:Graphics = _outline.graphics;
			var PERCENT_TO_BAR:Number = this.height / 100;
			var trueValue:Number = 100 - _actualValue; // Allows the bar to fill from bottom to top as opposed to top to bottom
			var LEFT:Number = 0;
			var RIGHT:Number = this.width;
			var TOP:Number = 0;
			var BOTTOM:Number = this.height;
			var largeIndPiece:Number = (3 / 50) * this.height; //    |\___/|    Mid bar is the small indicator pieces
			var smallIndPiece:Number = (1 / 100) * this.height;//    | ___ |    Corners are the large indicator pieces
			                                                   //    |/   \|
			if (_dimensionsDirty) {
				outlineGraphics.clear();
				_outline.x = LEFT;
				_outline.y = TOP;
				// Creates the outline
				outlineGraphics.lineStyle(1, 0);
				outlineGraphics.moveTo(LEFT, TOP);
				outlineGraphics.lineTo(RIGHT, TOP);
				outlineGraphics.lineTo(RIGHT, BOTTOM);
				outlineGraphics.lineTo(LEFT, BOTTOM);
				outlineGraphics.lineTo(LEFT, TOP);
			}
			if (_dimensionsDirty || _actualDirty) {
				// Creates the indicator and a bar fill
				mainSpriteGraphics.clear();
				_mainSprite.x = LEFT;
				_mainSprite.y = TOP;
				indicatorGraphics.clear();
				_indicator.x = LEFT;
				_indicator.y = TOP;
				// Bar Fill
				mainSpriteGraphics.lineStyle(1, BAR_FILL);
				mainSpriteGraphics.beginFill(BAR_FILL);
				mainSpriteGraphics.moveTo(RIGHT, BOTTOM);
				mainSpriteGraphics.lineTo(LEFT, BOTTOM);
				mainSpriteGraphics.lineTo(LEFT, PERCENT_TO_BAR * trueValue);
				mainSpriteGraphics.lineTo(RIGHT, PERCENT_TO_BAR * trueValue);
				mainSpriteGraphics.lineTo(RIGHT, BOTTOM);
				// Current level indicator - BLACK
				indicatorGraphics.lineStyle(1, 0);
				indicatorGraphics.beginFill(0);
				indicatorGraphics.moveTo(LEFT, PERCENT_TO_BAR * trueValue - largeIndPiece);
				indicatorGraphics.lineTo(RIGHT / 3, PERCENT_TO_BAR * trueValue - smallIndPiece);
				indicatorGraphics.lineTo(2 * RIGHT / 3, PERCENT_TO_BAR * trueValue - smallIndPiece);
				indicatorGraphics.lineTo(RIGHT, PERCENT_TO_BAR * trueValue - largeIndPiece);
				indicatorGraphics.lineTo(RIGHT, PERCENT_TO_BAR * trueValue + largeIndPiece);
				indicatorGraphics.lineTo(2 * RIGHT / 3, PERCENT_TO_BAR * trueValue + smallIndPiece);
				indicatorGraphics.lineTo(RIGHT / 3, PERCENT_TO_BAR * trueValue + smallIndPiece);
				indicatorGraphics.lineTo(LEFT, PERCENT_TO_BAR * trueValue + largeIndPiece);
				indicatorGraphics.lineTo(LEFT, PERCENT_TO_BAR * trueValue - largeIndPiece);
				indicatorGraphics.endFill();
				_actualDirty = false;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);	
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//			  <SliderDisplay_X ruid="slideRuid1" barColor="00BBDD">
		//				<field fid="actual" name="actual"/>
		//			  </SliderDisplay_X>
		// since SliderDisplay_X is a "MultiField" implementation, you could give the SliderDisplay a ruid, like this:
		//			<SliderDisplay_X ruid="slideRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}