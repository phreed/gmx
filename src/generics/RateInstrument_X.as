package generics 
{
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
	public class RateInstrument_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["actual"]; }
		override public function get defaultValues():Array { return ["0"]; }
		// This may be changed flexibly to be whatever size is needed
		public static const DEFAULT_COMP_HEIGHT:Number = 150; 
		public static const DEFAULT_COMP_WIDTH:Number = 150;  
		
		public var actual:Field; 
		private var _actualValue:Number = 0.0; 
		private var _actualDirty:Boolean = false;
		
		private var _dimensionsDirty:Boolean = false;
		
		private var _circleSprite:FlexSprite = new FlexSprite();
		private var _arrowSprite:FlexSprite = new FlexSprite();
		private var _dialIcon:Icon_X = new Icon_X();
		
		public function RateInstrument_X() 
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
			this.addChild(_dialIcon);
			this.addChild(_arrowSprite);
			this.addChild(_circleSprite);
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
			if (_actualDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var circleGraphics:Graphics = _circleSprite.graphics;
			var arrowGraphics:Graphics = _arrowSprite.graphics;
			var SPEED_TO_RAD:Number = 178 / 8 * (Math.PI / 180); // To fit the SVG
			var rad:Number = this.width * .42; // Going to be smaller than half the width
			var angleOffset:Number = Math.PI / 50; 
			var angleUsed:Number = 0;
			var tipOffset:Number = (5 / 150) * this.width;
			
			if (_dimensionsDirty) {
				circleGraphics.clear();
				_circleSprite.x = this.width / 2;
				_circleSprite.y = this.height / 2;
				circleGraphics.lineStyle(1, 0);
				circleGraphics.beginFill(0x666666);
				circleGraphics.drawCircle(0, 0, 3);
				circleGraphics.endFill();
			}
			if (_dimensionsDirty || _actualDirty) {
				arrowGraphics.clear();
				_arrowSprite.x = this.width / 2;
				_arrowSprite.y = this.height / 2;
				arrowGraphics.lineStyle(1, 0);
				arrowGraphics.beginFill(0xff0000);
				angleUsed = _actualValue;
				if (_actualValue > 8) {
					angleUsed = 8; // Can't bust the components limit (between -8 and 8 thousand feet / min)
				}
				if (_actualValue < -8) {
					angleUsed = -8; // Can't bust the components limit (between -8 and 8 thousand feet / min)
				}
				arrowGraphics.moveTo(0, 0);
				arrowGraphics.lineTo((rad - tipOffset) * Math.cos(angleUsed * SPEED_TO_RAD - angleOffset), (rad - tipOffset) * Math.sin(angleUsed * SPEED_TO_RAD - angleOffset));
				arrowGraphics.lineTo(rad * Math.cos(angleUsed * SPEED_TO_RAD), rad * Math.sin(angleUsed * SPEED_TO_RAD));
				arrowGraphics.lineTo((rad - tipOffset) * Math.cos(angleUsed * SPEED_TO_RAD + angleOffset), (rad - tipOffset) * Math.sin(angleUsed * SPEED_TO_RAD + angleOffset));
				arrowGraphics.lineTo(0, 0);
				arrowGraphics.endFill();
				_arrowSprite.rotation = 180;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//			  <RateInstrument_X ruid="vertRuid">
		//				<field fid="actual" name="actual"/>
		//			  </RateInstrument_X>
		// since RateInstrument_X is a "MultiField" implementation, you could give the RateInstrument a ruid, like this:
		//			<RateInstrument_X ruid="instrumentBarRuid1" ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			var iconXML:XML = new XML('<Icon_X icon="verticalSpeed2" width="' + this.width + '" height="' + this.height + '"/>'); 
			_dialIcon.build(iconXML);
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}