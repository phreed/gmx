package gmx_builder 
{
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import mx.core.FlexSprite;
	/**
	 * These are the TextFields that appear in the XMLDisplay
	 * @author Alan Nelson
	 */
	public class XMLSprite extends FlexSprite
	{
		public static var draggingXMLSpriteIndex:String = null;
		
		public static const SCALER:Number = 10; 
		public static const Y_DIVISION:Number = 2;
		public static const X_DIVISION:Number = 20;
		
		public static var spriteCount:int = 0;
		
		private var _textField:TextField = new TextField();
		private var _index:String;
		public function get index():String { return _index; }
		
		private var _levelX:int;
		public function get levelX():int { return _levelX; }
		
		private var _infinitePlaneCoordinates:Point = new Point();
		public function get infinitePlaneCoordinates():Point { return _infinitePlaneCoordinates; }
		public function set infinitePlaneCoordinates(val:Point):void {
			_infinitePlaneCoordinates = val;
		}
		
		public function XMLSprite(xml:XML, index:String)
		{
			super();
			this.addChild(_textField);
			_textField.text = xml.localName();
			_textField.width = 100;
			_textField.height = 100;
			_textField.mouseEnabled = false;
			//this.height = 20;
			//this.width = _textField.textWidth + 5;
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.addEventListener(MouseEvent.MOUSE_UP, GMXBuilder.possibleDragOntoXMLSprite, false, 0, true);
			this.addEventListener(MouseEvent.CLICK, clicked);
			this.addEventListener(MouseEvent.ROLL_OVER, mouseOver);
			this.addEventListener(MouseEvent.ROLL_OUT, mouseOut);
			//this.mouseEnabled = false;
			//this.mouseChildren = false;
			_index = index;
			var indexVals:Array = index.split(",");
			/*var levelY:int = 0;
			for (var i:int = 0; i < indexVals.length; i++) {
				levelY += (parseInt(indexVals[i]) + 1);
			}*/
			_levelX = indexVals.length - 1;
			
			//_infinitePlaneCoordinates.y = levelY * Y_DIVISION;
			_infinitePlaneCoordinates.x = _levelX * X_DIVISION;
			this.x = _levelX * X_DIVISION;
			//trace(_infinitePlaneCoordinates);
		}
		private var _mouseDown:Boolean = false;
		private function mouseDown(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			_mouseDown = true;
			draggingXMLSpriteIndex = this._index;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			//trace(this.x + " " + this.y);
		}
		private function mouseMove(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			this.x = parent.mouseX + 2;
			this.y = parent.mouseY + 2;
		}
		private function mouseUp(event:MouseEvent):void {
			_mouseDown = false;
			draggingXMLSpriteIndex = null; // note that possibleDragOntoThis will catch this event before it is false b/c mouseUp listener is on the stage
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (!event.shiftKey) { return; }
			
		}
				
		private function clicked(event:MouseEvent):void {
			if (_mouseDown || event.ctrlKey || event.shiftKey) { return; }
			GMXBuilder.selectedObjectByIndex = _index;
		}
		
		private function mouseOver(event:MouseEvent):void {
			this.filters = [new GlowFilter(0xffff00, 1, 10, 10, 4, 1)];
		}
		private function mouseOut(event:MouseEvent):void {
			this.filters = [];
		}
	}
}