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
	 
	/*
	* This Component will act as an indication of where the wind is blowing; it will take in two fields
	* These fields will be: the track reference and the wind direction
	* A "N" North indicator will be displayed to show where north is (given by the track field)
	* And the wind direction will be based off of this location -- referencing North always as being at 0/360 Deg
	* As if using a standard dial. If the wind is blowing East it will be referenced 90 Deg from North etc... (And it doesn't HAVE to be wind)
	*/
	
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class WindDirIndicator_X extends UIComponent_ISIS implements IMultiField
	{
		override public function get fieldNames():Array { return ["winddir", "trackdir"]; }
		override public function get defaultValues():Array { return ["0",       "0"]; }
		// Setting base width/height to be 100x100 for now; may be changed later if need be
		public static const DEFAULT_COMP_HEIGHT:Number = 100;
		public static const DEFAULT_COMP_WIDTH:Number = 100;
		
		public var winddir:Field;
		private var _windDirValue:Number = 0.0; // Will be considered in reference to north 0 deg wind dir = north, 90 = east,etc.
		private var _windDirDirty:Boolean = false;
		
		public var trackdir:Field;
		private var _trackDirValue:Number = 0.0;
		private var _trackDirDirty:Boolean = false;
		
		private var arrowColor:uint = 0xBEE6FF;
		private var right1Color:uint = 0x0000ff;
		private var left1Color:uint = 0xffffff;
		private var right2Color:uint = 0x00ffff;
		private var left2Color:uint = 0xffffff;
		
		private var _arrowRotation:Number = 0.0;
		private var _textNorth:TextField = new TextField();
		
		private var _dimensionsDirty:Boolean = false; //This allows the default dimensions 84x84 to be reconfigured flexibly
		
		public static const DEG_TO_RAD:Number = Math.PI / 180;
		
		// sprite variables
		private var _sprite1:FlexSprite = new FlexSprite();
		private var _sprite2:FlexSprite = new FlexSprite();
		private var _arrow:FlexSprite = new FlexSprite();
		private var _star1:FlexSprite = new FlexSprite();
		private var _star2:FlexSprite = new FlexSprite();
	
		public function WindDirIndicator_X() 
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
			this.addChild(_star2);
			this.addChild(_star1);
			this.addChild(_sprite1);
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
			if (winddir != null) {
				val = parseFloat(winddir.value);
				if (_windDirValue != val) {
					_windDirDirty= true;
					_windDirValue = val;
				}
			}
			if (trackdir != null) {
				val = parseFloat(trackdir.value);
				if (_trackDirValue != val) {
					_trackDirDirty=true;
					_trackDirValue=val;
				}
			}
			//Considers any of these dirties to invalidate (could separate into multiple different graphics)
			if (_windDirDirty||_trackDirDirty)
			{
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var g1:Graphics = _sprite1.graphics;
			var g2:Graphics = _sprite2.graphics;
			var gA:Graphics = _arrow.graphics;
			var star1Graphics:Graphics = _star1.graphics;
			var star2Graphics:Graphics = _star2.graphics;
			var rad:Number = this.width / 2 - 7*Size.MM;
	      
			// Creates the star compass rose X2
			if (_dimensionsDirty) {
				star1Graphics.clear();
				_star1.x = this.width / 2;
				_star1.y = this.height / 2;
				drawStar(_star1.x, _star1.y, _star1, left1Color, right1Color);
				star2Graphics.clear();
				_star2.x = this.width / 2;
				_star2.y = this.height / 2;
				drawStar(_star2.x, _star2.y, _star2, left2Color, right2Color);
			}
			
			// Displays the N "North" location at all times at 0/360 Deg mark
			if (_dimensionsDirty||_trackDirDirty||_windDirDirty) {
				g1.clear();
				_sprite1.x = this.width / 2;
				_sprite1.y = this.height / 2;
				g2.clear();
				_sprite2.x = 0;
				_sprite2.y = -this.height/2;
				g2.lineStyle(1, 0);
				g2.beginFill(0xffffff);
				g2.drawCircle(0, 0, 7);
				g2.endFill();
				g2.lineStyle(1.75, 0);
				g2.moveTo( -3, 3);
				g2.lineTo( -3, -3);
				g2.lineTo(3, 3);
				g2.lineTo(3, -3);
				_sprite1.addChild(_sprite2);
				_sprite1.rotation = _trackDirValue;
			}
			
			// Creates the arrow based on ration/rad measurements to fit any size
			// Whole sprite is rotated when the wind direction changes
			if (_dimensionsDirty||_windDirDirty||_trackDirDirty) {
				gA.clear();
				_arrow.x = width/2;
				_arrow.y = height/2;
				gA.lineStyle(1,0);
				gA.beginFill(arrowColor);
				gA.moveTo(0, -this.height / 2);
				gA.lineTo( -this.width / 8, -this.height * .38);
				gA.lineTo( -this.width / 20, -this.height * .4);
				gA.lineTo( -this.width / 20, this.height * .45);
				gA.lineTo(0, this.height * .4);
				gA.lineTo( this.width / 20, this.height * .45);
				gA.lineTo( this.width / 20, -this.height * .4);
				gA.lineTo(this.width / 8, -this.height * .38);
				gA.lineTo(0, -this.height / 2);
				gA.endFill();
				_arrowRotation = _windDirValue+_trackDirValue;
				_arrow.rotation = _arrowRotation;
				_star1.rotation = _trackDirValue;
				_star2.rotation = 45 + _trackDirValue; // Put it behind the main star at an offset angle for NE/SE/NW/SW
				_trackDirDirty = false;
			}
			_dimensionsDirty = false;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		
		//************************* USEFUL FUNCTION ************************************************
		/**
		 * Creates a 4 sided star which has 8 pieces that may be split into different colors
		 * Use Multiple times and stack / rotate effectively to create nearly any type of compass template
		 */
		private function drawStar(xCo:Number, yCo:Number, sprite:FlexSprite, colorLight:uint, colorDark:uint):void {
			var inXFactor:Number = this.width * .1;
			var inYFactor:Number = this.height * .1;
			var lineSize:Number = 1.25;
			var g:Graphics = sprite.graphics;
			sprite.x = xCo;
			sprite.y = yCo;
			g.lineStyle(lineSize, 0);
			g.beginFill(colorDark);
			g.moveTo(0, 0);
			g.lineTo(0,0 - this.height / 2);
			g.lineTo(inXFactor, -inYFactor);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorLight);
			g.lineTo(inXFactor, -inYFactor);
			g.lineTo( this.width / 2, 0);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorDark);
			g.lineTo( this.width / 2, 0);
			g.lineTo(inXFactor, inYFactor);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorLight);
			g.lineTo(inXFactor, inYFactor);
			g.lineTo(0, this.height / 2);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorDark);
			g.lineTo(0, this.height / 2);
			g.lineTo( -inXFactor, inYFactor);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorLight);
			g.lineTo( -inXFactor, inYFactor);
			g.lineTo( -this.width / 2, 0);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorDark);
			g.lineTo( -this.width / 2, 0);
			g.lineTo( -inXFactor, -inYFactor);
			g.lineTo(0, 0);
			g.endFill();
			g.lineStyle(lineSize, 0);
			g.beginFill(colorLight);
			g.lineTo( -inXFactor, -inYFactor);
			g.lineTo(0, -this.height / 2);
			g.lineTo(0, 0);
			g.endFill();
		}
		//************************* USEFUL FUNCTION ************************************************
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//<WindDirIndicator_X ruid="windRuid">
		//	<field fid="windDir" name="windDir"/>
		//	<field fid="trackDir" name="trackDir"/>
		//  </WindDirIndicator>
		// since WindDirIndicator_X is a "MultiField" implementation, you could give the Dial a ruid, like this:
		//			<WindDirIndicator_X ruid="windRuid1"> ...
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			this.fields = xml;
			GMXComponentBuilder.setStandardValues(xml, this);
			if (xml.@topLeftColor != undefined) {
				left1Color = GMXComponentBuilder.parseColor(xml.@topLeftColor.toString());
			}
			if (xml.@topRightColor != undefined) {
				right1Color = GMXComponentBuilder.parseColor(xml.@topRightColor.toString());
			}
			if (xml.@botLeftColor != undefined) {
				left2Color = GMXComponentBuilder.parseColor(xml.@botLeftColor.toString());
			}
			if (xml.@botRightColor != undefined) {
				right2Color = GMXComponentBuilder.parseColor(xml.@botRightColor.toString());
			}
			if (xml.@windColor != undefined) {
				arrowColor = GMXComponentBuilder.parseColor(xml.@windColor.toString());
			}
		GMXComponentBuilder.processXML(this,xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
	}
}