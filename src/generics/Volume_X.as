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
	import flash.events.Event;
	import flash.events.MouseEvent;
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
	 * @author Zach
	 */
	/*
	 * Creates a volume display that takes in one field, the actual volume out of 100%
	 * */
	public class Volume_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["actual"]; }
		override public function get defaultValues():Array { return ["0"]; }
		
		public static const DEFAULT_COMP_HEIGHT:Number = 20;
		public static const DEFAULT_COMP_WIDTH:Number = 35;
		
		public var actual:Field; 
		private var actualValue:Number = 0.0; 
		private var actualDirty:Boolean = false;
		private function get volume():Field { return actual; }
		
		private var _dimensionsDirty:Boolean = false; // Helps redraw the figure if the dimensions change
		
		private var _mainSprite:FlexSprite = new FlexSprite();
		private var _volSprite:FlexSprite = new FlexSprite();
		
		public function Volume_X() 
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
			this.addChild(_volSprite);
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
				if (actualValue != val) {
					actualDirty = true;
					actualValue = val;
				}
			}
			
			if (actualDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var mainSpriteGraphics:Graphics = _mainSprite.graphics;
			var volumeGraphics:Graphics = _volSprite.graphics;
			
			// Creates the volume symbol
			if (_dimensionsDirty) {
				mainSpriteGraphics.clear();
				_mainSprite.x = 0;
				_mainSprite.y = 0;
				mainSpriteGraphics.lineStyle(1, 0);
				mainSpriteGraphics.beginFill(0xFFFFFF);
				mainSpriteGraphics.moveTo(4, (1 / 3) * this.height);
				mainSpriteGraphics.lineTo(10, (1 / 3) * this.height);
				mainSpriteGraphics.lineTo(15, (1 / 5) * this.height);
				mainSpriteGraphics.lineTo(15, (4 / 5) * this.height);
				mainSpriteGraphics.lineTo(10, (2 / 3) * this.height);
				mainSpriteGraphics.lineTo(4, (2 / 3) * this.height);
				mainSpriteGraphics.lineTo(4, (1 / 3) * this.height);
				mainSpriteGraphics.endFill();
			}
			// Creates the volume value indicator(s)
			if (_dimensionsDirty || actualDirty) {
				volumeGraphics.clear();
				_volSprite.x = 0;
				_volSprite.y = 0;
				// Mute symbol added if there is no volume
				if (actualValue <= 0) {
					volumeGraphics.lineStyle(2, 0xff0000);
					volumeGraphics.drawCircle(9.5, this.height / 2, (1 / 3) * this.height);
					volumeGraphics.moveTo(5, (3 / 4) * this.height);
					volumeGraphics.lineTo(14, (1 / 3) * this.height);
				}
				// Creates one curved bar
				if (actualValue > 0) {
					volumeGraphics.lineStyle(2, 0xffffff);
					volumeGraphics.moveTo(17, (1 / 3) * this.height);
					volumeGraphics.curveTo( 20, .5 * this.height, 17, (2 / 3) * this.height);
				}
				// Creates a second curved bar
				if (actualValue > 33) {
					volumeGraphics.moveTo(23, (1 / 4) * this.height);
					volumeGraphics.curveTo(26, .5 * this.height, 23, (3 / 4) * this.height);
				}
				// Creates a third curved bar
				if (actualValue > 66) {
					volumeGraphics.moveTo(29, (1 / 5) * this.height);
					volumeGraphics.curveTo(32, .5 * this.height, 29, (4 / 5) * this.height);
				}
				actualDirty = false;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);	
		}
	// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//			  <Volume_X ruid="slideRuid">
		//				<field fid="volume" name="volume"/>
		//			  </Volume_X>
		// since Volume_X is a "MultiField" implementation, you could give the volume indicator a ruid, like this:
		//			<Volume_X ruid="slideRuid1"> ...
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