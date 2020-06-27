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
	import mx.core.FlexShape;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	/*
	* The Voltage Indicator takes in 2 fields, the current voltage and the critical voltage limit.
	* The inner circle is green when the voltage is below the critical and red when it is above.
	* The outer ring color and the units may be set as XML attributes (@ringColor // @units)
	*/
	public class VoltageIndicator_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["currentvolt", "critvoltlimit"]; }
		override public function get defaultValues():Array { return ["0",     	   "0"]; }
		// Setting base width/height to be 150x150 for now; may be changed later if need be
		public static const DEFAULT_COMP_HEIGHT:Number = 150;
		public static const DEFAULT_COMP_WIDTH:Number = 150;
		
		public var currentvolt:Field; // 4 digits should be the max displayed at any given time; switch units attribute if necessary
		private var _currentVoltValue:Number = 0.0;
		private var _currentVoltDirty:Boolean = false;
		
		public var critvoltlimit:Field;
		private var _critVoltLimitValue:Number = NaN;
		private var _critVoltLimitDirty:Boolean = false;
		
		private var _ringColor:uint = 0x0000AA; // Default is Dark Blue, able to be set through XML @ttribute
		public static const GREEN:uint = 0x00DD00;
		public static const RED:uint = 0xFF0000;
		public static const WHITE:uint = 0xEEEEEE;
		
		private var _voltUnits:String = "V"; // Units should not be a whole word; use (V, mV, uV, nV ... etc.)
		
		private var _dimensionsDirty:Boolean = false;
		
		public function VoltageIndicator_X() 
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
			this.addChild(_baseSprite);
			this.addChild(_statusSprite);
			this.addChild(_textBox);
			this.addChild(_voltText);
			super.createChildren();
			_dimensionsDirty = true;
		}
		override protected function measure():void {
			super.measure();
		}

		override protected function commitProperties():void 
		{
			var val:Number;
			var i:int = 0;
			
			if (currentvolt != null) {
				val = parseFloat(currentvolt.value);
				if (_currentVoltValue != val) {
					_currentVoltDirty = true;
					_currentVoltValue = val;
				}
			}
			
			if (critvoltlimit != null) {
				val = parseFloat(critvoltlimit.value);
				if (_critVoltLimitValue != val) {
					_critVoltLimitDirty = true;
					_critVoltLimitValue = val;
				}
			}
			
			//Considers any of these dirties to invalidate (could separate into multiple different graphics)
			if (_currentVoltDirty || _critVoltLimitDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		private var _baseSprite:FlexSprite = new FlexSprite();
		private var _statusSprite:FlexSprite = new FlexSprite();
		private var _textBox:FlexSprite = new FlexSprite();
		private var _voltText:TextField = new TextField();
	   
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var baseSpriteGraphics:Graphics = _baseSprite.graphics;
			var statusGraphics:Graphics = _statusSprite.graphics;
			var textBoxGraphics:Graphics = _textBox.graphics;
			var rad:Number = this.width / 2;
			var statusColor:uint = GREEN;
				
			// Creates the circle for the volt meter
			if (_dimensionsDirty) {
				baseSpriteGraphics.clear();
				_baseSprite.x = rad;
				_baseSprite.y = this.height / 2;
				baseSpriteGraphics.lineStyle(2, 0);
				baseSpriteGraphics.beginFill(_ringColor);
				baseSpriteGraphics.drawCircle(0, 0, rad);
				baseSpriteGraphics.endFill();
			}
				
			//This section will create the status circle to show whether the current voltage is harmful or not
			if (_dimensionsDirty|| _currentVoltDirty || _critVoltLimitDirty) {
				
				// This section creates the status circle
				if (_dimensionsDirty || _currentVoltDirty || _critVoltLimitDirty) {
					statusGraphics.clear();
					_statusSprite.x = rad;
					_statusSprite.y = this.height / 2;
					if (_currentVoltValue >= _critVoltLimitValue) {
						if (!isNaN(_critVoltLimitValue)){
						statusColor = RED;
						}
					}
					else {
						statusColor = GREEN;
					}
					statusGraphics.lineStyle(2, 0);
					statusGraphics.beginFill(statusColor);
					statusGraphics.drawCircle(0, 0, .8 * rad);
				}
			}
			// This section will create the text box + current voltage numbers/units
			if (_dimensionsDirty || _currentVoltDirty) {
				textBoxGraphics.clear();
				_textBox.x = rad;
				_textBox.y = this.height / 2;
				_voltText.embedFonts = true;
				_voltText.text = _currentVoltValue + _voltUnits;
				_voltText.setTextFormat(Font.LARGE_FONT_LEFT);
				_voltText.height = _voltText.textHeight; 
				_voltText.width = _voltText.textWidth + 4; // Adds padding
				_voltText.x = rad - _voltText.width/2;
				_voltText.y = this.height / 2 - _voltText.height/2;
				textBoxGraphics.lineStyle(2, 0);
				textBoxGraphics.beginFill(WHITE);
				textBoxGraphics.moveTo( -rad / 2, -this.height / 5);
				textBoxGraphics.lineTo( rad / 2, -this.height / 5);
				textBoxGraphics.lineTo( rad / 2, this.height / 5);
				textBoxGraphics.lineTo( -rad / 2, this.height / 5);
				textBoxGraphics.lineTo( -rad / 2, -this.height / 5);
				textBoxGraphics.endFill();
				}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//	<VoltageIndicator_X ruid="voltRuid" units="mV" ringColor="000000">
		//		<field fid="currentVolt" name="currentVolt"/>
		//		<field fid="critVoltLimit" name="critVoltLimit"/>
		//	</VoltageIndicator_X>
		// since VoltageIndicator_X is a "MultiField" implementation, you could give the meter a ruid, like this:
		//			<VoltageIndicator_X ruid="voltRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			if (xml.@units != undefined) {
				_voltUnits = xml.@units.toString();
			}
			if (xml.@ringColor != undefined) { // Hexadecimal, no "0x"
				_ringColor = GMXComponentBuilder.parseColor(xml.@ringColor.toString());
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