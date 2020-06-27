package generics 
{
	import interfaces.IFieldStandardImpl;
	import interfaces.UIComponent_ISIS;
	import records.Attributes;
	import generics.Icon_X;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import mx.controls.Button;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	import flash.display.GraphicsPathWinding;
	import flash.display.Sprite;
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
	 * Compass_X works like a standard compass in the sense that it displays the cardinal directions and tracks magnetic north.
	 * Magnetic north is the only field that this component needs to take in.
	 * Problems will arise if default dimensions are not used due to the way the bitmap is added, so add the 
	 * icon of the compass bitmap directly to the layout message and remove it in the CreateChildren() function if it becomes an issue.
	 */ 
	public class Compass_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["magnorth"]; }
		override public function get defaultValues():Array { return ["0"]; }
		
		private var _compass:Icon_X = new Icon_X();
		
		public var magnorth:Field;
		private var _magNorthDir:Number = 0.0;
		private var _magNorthDirty:Boolean = false;
		
		private var _arrowSprite:FlexSprite = new FlexSprite();
		
		private var _dimensionsDirty:Boolean = false;
		private const DEG_TO_RAD:Number = Math.PI / 180;
		
		// Setting base width/height to be 150x150 for now; may be changed later if need be
		public static const DEFAULT_COMP_HEIGHT:Number = 150;
		public static const DEFAULT_COMP_WIDTH:Number = 150;
		
		public function Compass_X() 
		{
			super();
			this.width = DEFAULT_COMP_WIDTH;
			this.height = DEFAULT_COMP_HEIGHT;
		}
		
		override public function set width(val:Number):void { // If Width is set in XML, be sure to change the XML for the icon for the compass bitmpas
			_dimensionsDirty = true;
			if (_compass != null) {
				_compass.width = this.width;
			}
			super.width = val;
			invalidateDisplayList();
		}
		
		override public function set height(val:Number):void { // If Height is set in XML, be sure to change the XML for the icon for the compass bitmpas
			_dimensionsDirty = true;
			if (_compass != null) {
				_compass.height = this.height;
			}
			super.height = val;
			invalidateDisplayList();                           
		}
		
		/* 
		 * AN option is to remove the XML is this document and just have it contained within the layout message by itself.
		 * As it is, the XML here just makes the layout much easier to write when the height/width stay as their default values.
		 */
		override protected function commitProperties():void 
		{
			var val:Number;
			if (magnorth != null) {
				val = parseFloat(magnorth.value);
				if (val != _magNorthDir) {
					_magNorthDirty = true;
					_magNorthDir = val;
				}
			}
			if (_magNorthDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var arrowSpriteGraphics:Graphics = _arrowSprite.graphics;
			var rad:Number = this.width / 2 * .8; // Not quite the entire width / height over 2 due to text space
			
			// Creates the Magnetic North indication arrow which displays where it is in reference to the other cardinal directions
			// 0 is considered to be north, east is 90 deg, south 180 etc.
			if (_dimensionsDirty || _magNorthDirty) {
				arrowSpriteGraphics.clear();
				_arrowSprite.x = this.width / 2;
				_arrowSprite.y = this.height / 2;
				arrowSpriteGraphics.lineStyle(1, 0);
				arrowSpriteGraphics.beginFill(0xFF0000);
				arrowSpriteGraphics.moveTo(0, 0);
				arrowSpriteGraphics.lineTo(2 * Math.cos((_magNorthDir - 90) * DEG_TO_RAD), 2 * Math.sin((_magNorthDir - 90) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo(2 * Math.cos((_magNorthDir + 90) * DEG_TO_RAD), 2 * Math.sin((_magNorthDir + 90) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo((rad - 10) * Math.cos((_magNorthDir + 5) * DEG_TO_RAD), (rad - 10) * Math.sin((_magNorthDir + 5) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo((rad - 10) * Math.cos((_magNorthDir + 10) * DEG_TO_RAD), (rad - 10) * Math.sin((_magNorthDir + 10) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo(rad * Math.cos(_magNorthDir * DEG_TO_RAD), rad * Math.sin(_magNorthDir * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo((rad - 10) * Math.cos((_magNorthDir - 10) * DEG_TO_RAD), (rad - 10) * Math.sin((_magNorthDir - 10) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo((rad - 10) * Math.cos((_magNorthDir - 5) * DEG_TO_RAD), (rad - 10) * Math.sin((_magNorthDir - 5) * DEG_TO_RAD));
				arrowSpriteGraphics.lineTo(2 * Math.cos((_magNorthDir - 90) * DEG_TO_RAD), 2 * Math.sin((_magNorthDir - 90) * DEG_TO_RAD));
				arrowSpriteGraphics.endFill();
				arrowSpriteGraphics.beginFill(0xffffff);
				arrowSpriteGraphics.drawCircle(0, 0, 3);
				arrowSpriteGraphics.endFill();
				_arrowSprite.rotation = 270;
				_magNorthDirty = false;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			this.addChild(_compass);
			this.addChild(_arrowSprite);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		// <Compass_X ruid="compassRuid">
		//	<field fid="magNorth" name="magNorth"/>
		// </Compass_X>
		// since Compass_X is a "MultiField" implementation, you could give the compass a ruid, like this:
		//			<Compass_X ruid="compassRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			var iconXML:XML = new XML('<Icon_X icon="compass" width="' + this.width + '" height="' + this.height + '"/>'); 
			_compass.build(iconXML);
			GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}