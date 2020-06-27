package generics 
{
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import generics.Icon_X;
	import interfaces.UIComponent_ISIS;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	
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
	/**
	 * TurnRateIndicator_X is designed to only take in one field (the rate of turn). The component itself is drawn onto a bitmap,
	 * so it is recommended to stick with the default dimensions or to add the icon to the layout message itself.
	 */
	public class TurnRateIndicator_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["turnrate"]; }
		override public function get defaultValues():Array { return ["0"]; }
		// Setting base width/height to be 100x100 for now; may be changed later if need be (if it is, need to refit the icon // ideally just add icon in layout)
		public static const DEFAULT_COMP_HEIGHT:Number = 100;
		public static const DEFAULT_COMP_WIDTH:Number = 100;
		
		public var turnrate:Field;
		private var _turnRateValue:Number = 0.0;
		private var _turnRateDirty:Boolean = false;
		
		private var _turnRateIcon:Icon_X = new Icon_X();
		private var _arrow:FlexSprite = new FlexSprite();
		private var _dimensionsDirty:Boolean = false;
		
		private const BLUE:uint = 0x0066CC;
		private const DEG_TO_RAD:Number = Math.PI / 180;
		
		public function TurnRateIndicator_X() 
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
			this.addChild(_turnRateIcon);
			this.addChild(_arrow);
			super.createChildren();
			_dimensionsDirty = true;
		}
		override protected function measure():void {
			super.measure();
		}
		
		override protected function commitProperties():void 
		{
			var val:Number;
			if (turnrate != null) {
				val = parseFloat(turnrate.value);
				if (_turnRateValue != val) {
					_turnRateDirty = true;
					_turnRateValue = val;
				}
			}
			if (_turnRateDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var arrowGraphics:Graphics = _arrow.graphics;
			var rad:Number = this.width / 2;
			
			// Creates an arrow over the bitmap to indicate the turn rate
			if (_dimensionsDirty || _turnRateDirty) {
				arrowGraphics.clear();
				_arrow.x = this.width / 2;
				_arrow.y = this.height / 2;
				arrowGraphics.lineStyle(1, 0);
				arrowGraphics.moveTo(0, 0);
				arrowGraphics.beginFill(BLUE);
				arrowGraphics.lineTo(2.2 * Math.cos((_turnRateValue - 90) * DEG_TO_RAD), 2.2 * Math.sin((_turnRateValue - 90) * DEG_TO_RAD));
				arrowGraphics.lineTo(2.2 * Math.cos((_turnRateValue + 90) * DEG_TO_RAD), 2.2 * Math.sin((_turnRateValue + 90) * DEG_TO_RAD));
				arrowGraphics.lineTo((rad - 10) * Math.cos((_turnRateValue + 5) * DEG_TO_RAD), (rad - 10) * Math.sin((_turnRateValue + 5) * DEG_TO_RAD));
				arrowGraphics.lineTo((rad - 10) * Math.cos((_turnRateValue + 10) * DEG_TO_RAD), (rad - 10) * Math.sin((_turnRateValue + 10) * DEG_TO_RAD));
				arrowGraphics.lineTo((rad - 3) * Math.cos(_turnRateValue * DEG_TO_RAD), (rad - 3) * Math.sin(_turnRateValue * DEG_TO_RAD));
				arrowGraphics.lineTo((rad - 10) * Math.cos((_turnRateValue - 10) * DEG_TO_RAD), (rad - 10) * Math.sin((_turnRateValue - 10) * DEG_TO_RAD));
				arrowGraphics.lineTo((rad - 10) * Math.cos((_turnRateValue - 5) * DEG_TO_RAD), (rad - 10) * Math.sin((_turnRateValue - 5) * DEG_TO_RAD));
				arrowGraphics.lineTo(2.2 * Math.cos((_turnRateValue - 90) * DEG_TO_RAD), 2.2 * Math.sin((_turnRateValue - 90) * DEG_TO_RAD));
				arrowGraphics.endFill();
				arrowGraphics.beginFill(0xAAAAAA);
				arrowGraphics.drawCircle(0, 0, 2);
				arrowGraphics.endFill();
				_arrow.rotation = 270;
				_turnRateDirty = false;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//	<TurnRateIndicator_X ruid="turnRuid">
		//		<field fid="turnRate" name="turnRate"/>
		//	</TurnRateIndicator_X>
		// since TurnRateIndicator_X is a "MultiField" implementation, you could give the indicator a ruid, like this:
		//			<TurnRateIndicator_X ruid="turnRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			// Icon adds a bitmap picture of a turn rate indicator, if default size is not needed, then remove the embedded XML here
			// and add it into the layout message.
			var iconXML:XML = new XML('<Icon_X icon="turnRate" width="' + this.width + '" height="' + this.height + '"/>'); // Centers the icon under the center of the center of the arrow, needs a small offset x="-13.4" y="-15" 
			//    ^^^^^^^^^^^^^^^^    May be Added in the Layout Message Instead     ^^^^^^^^^^^^^^^^^^^^
			_turnRateIcon.build(iconXML);
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}