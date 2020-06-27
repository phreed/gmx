package gmx_builder
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import mx.core.Container;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	/**
	 * This class is a novel "tree-browser" that uses a projection (ask Fred Eisele for the details) in order to ensure that the entire tree
	 * is always visible while making the "focused elements" spaced such that they do not overlap each other at all and are perfectly discernable.
	 * This helps the user to always see the Context in which they are operating in within the entire tree structure while still distinguishing
	 * components of interest within that tree.
	 * @author  Alan Nelson
	 */
	public class XMLDisplay extends Container
	{
		public static const MOVEMENT_STEPS:Number = 20.0;
		private static const H:Number = 20;
		private static const W:Number = 30;
		private static const A:Number = Math.atan(W / H);
		private static const CANVAS_WIDTH:Number = 300;
		private static const CANVAS_HEIGHT:Number = 550;
		
		private var _highlightSprite:FlexSprite;
		private var xmlSprites:Vector.<XMLSprite> = new Vector.<XMLSprite> ();
		public static function spliceXmlSprites(start:int, count:int):void {
			xmlDisplayInstance.xmlSprites.splice(start, count);
			xmlDisplayInstance._childrenDirty = true;
			xmlDisplayInstance.invalidateDisplayList();
		}
		public static function moveXMLSprites(start:int, count:int, newIndex:int):void {
			var elementsToMove:Vector.<XMLSprite> = xmlDisplayInstance.xmlSprites.splice(start, count);
			var elementsAfterNewIndex:Vector.<XMLSprite> = new Vector.<XMLSprite> ();
			var i:int;
			while (xmlDisplayInstance.xmlSprites.length != newIndex) {
				elementsAfterNewIndex.push(xmlDisplayInstance.xmlSprites.pop());
			}
			for (i = 0; i < elementsToMove.length; i++) {
				xmlDisplayInstance.xmlSprites.push(elementsToMove[i]);
			}
			while (elementsAfterNewIndex.length != 0) {
				xmlDisplayInstance.xmlSprites.push(elementsAfterNewIndex.pop());
			}
			xmlDisplayInstance._childrenDirty = true;
			xmlDisplayInstance.invalidateDisplayList();
		}
		public static function get numXMLSprites():int {
			return xmlDisplayInstance.xmlSprites.length;
		}
		
		
		public static var xmlDisplayInstance:XMLDisplay;
		
		private var _canvas:UIComponent;
		
		private var _childrenDirty:Boolean = false;
		
		public function XMLDisplay() 
		{
			super();
			this.visible = false;
			GMXMain.PopUps.addChild(this);
			//this.alpha = 0.5;
			this.setStyle("backgroundColor", 0xffffff);
			this.graphics.beginFill(0xffffff); 
			this.graphics.drawRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT); // 10 pixels so its in the middle of the selected textfield
			this.graphics.beginFill(0xffff00);
			this.graphics.drawRect(0, CANVAS_HEIGHT / 2 - 10, CANVAS_WIDTH, 20);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		
		public static function getXMLDisplay():XMLDisplay {
			if (xmlDisplayInstance == null) { xmlDisplayInstance = new XMLDisplay(); }
			
			return xmlDisplayInstance;
		}		
		
		private var _referencePoint:Point = new Point();
		private function mouseDown(event:MouseEvent):void {
			if (event.ctrlKey) {
				event.stopPropagation();
				_referencePoint.x = mouseX;
				_referencePoint.y = mouseY;
				GMXMain.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			}
		}
		
		private function mouseMove(event:MouseEvent):void {
			this.x += mouseX - _referencePoint.x;
			this.y += mouseY - _referencePoint.y;
		}
		
		private function mouseUp(event:MouseEvent):void {
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		public function clearXmlSprites():void {
			while (xmlSprites.length != 0) {
				xmlSprites.pop();
			}
			_childrenDirty = true;
			this.invalidateDisplayList();
		}
		
		public function addXmlSprite(index:String, xml:XML):void {
			xmlSprites.push(new XMLSprite(xml, index));
			//trace("ADDED xml sprite " + xml.localName());
			_childrenDirty = true;
			this.invalidateDisplayList();
		}
		private var _formerFocus:Point = new Point();
		private var _intermediateFocus:Point = new Point(); // used to animate the focus
		private var _newFocus:Point = new Point();
		private var _movementVector:Point = new Point();
		public function selectXML(index:String):void {
			for (var i:int = 0; i < xmlSprites.length; i++) {
				if (xmlSprites[i].index == index) {
					// center the focus on that sprite
					_formerFocus = _newFocus; // switch over so that there is a smooth transition in 
											  // case it was already in motion					
					_newFocus = xmlSprites[i].infinitePlaneCoordinates;
					_newFocus.y = i * XMLSprite.Y_DIVISION;
					_movementVector = _newFocus.subtract(_formerFocus);
					invalidateDisplayList();
					return;
				}
			}
			trace("WARNING: XMLDisplay did not find XMLSprite at index=" + index);
		}
		
		public function resetIntermediateFocus():void {
			_intermediateFocus.y = _intermediateFocus.y - .01;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			_canvas = new UIComponent();
			this.addChild(_canvas);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var i:int;
			var j:int;
			if (_childrenDirty) {
				while (_canvas.numChildren != 0) { _canvas.removeChildAt(0); }
				for (i = 0; i < xmlSprites.length; i++) {
					_canvas.addChild(xmlSprites[i]);
				}
				_childrenDirty = false;
			}
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			//trace("_intermediateFocus: " + _intermediateFocus.toString() + "    _newFocus: " + _newFocus.toString());
			if (_newFocus.equals(_intermediateFocus)) {
				_formerFocus = _newFocus;
			} else {
				_intermediateFocus.x = _intermediateFocus.x + _movementVector.x / MOVEMENT_STEPS;
				var movementY:Number = _movementVector.y / MOVEMENT_STEPS;
				if (Math.abs(movementY) < 0.3) { movementY = movementY > 0 ? 0.3 : -0.3; }
				_intermediateFocus.y = _intermediateFocus.y + movementY;
				//trace("b/w former & intermediate: " + Point.distance(_formerFocus, _intermediateFocus) + "  b/w former & new: " + Point.distance(_formerFocus, _newFocus));
				//trace("intermediate: " + _intermediateFocus.toString() + "   new: " + _newFocus.toString());
				if (Math.abs(_intermediateFocus.y-_formerFocus.y) >= Math.abs(_newFocus.y-_formerFocus.y)) {
				//	trace("FARTHER");
					_intermediateFocus.x = _newFocus.x;
					_intermediateFocus.y = _newFocus.y;
				}
				// now redraw everything with that intermediate focus
				var prevX:int = 0; // used to draw the tree "branch"
				var prevYs:Array = new Array();
				var prevSprites:Array = new Array(); // used to keep track of the sprit above's position
				var prevSprite:XMLSprite;
				var prevY:Number = 0;
				
				var g:Graphics;
				for (i = 0; i < xmlSprites.length; i++) {
					var deltaY:Number = Math.abs(i * XMLSprite.Y_DIVISION - _intermediateFocus.y);
					var B:Number = Math.atan(deltaY / H);
					
					var C:Number = Math.PI - A - B;
					var a:Number = H * Math.sin(A) / Math.sin(C);
					var testCase:Number = i * XMLSprite.Y_DIVISION - _intermediateFocus.y;
					//xmlSprites[i].y = 10 * ((xmlSprites[i].infinitePlaneCoordinates.y - _intermediateFocus.y < 0) ? - a * Math.sin(B) : a * Math.sin(B));
					if (testCase < 0) {
						xmlSprites[i].y = -10 + CANVAS_HEIGHT / 2 - XMLSprite.SCALER * a * Math.sin(B) ;//((xmlSprites[i].infinitePlaneCoordinates.y - _intermediateFocus.y < 0) ? - a * Math.sin(B) : a * Math.sin(B));
					} else {
						xmlSprites[i].y = -10 + CANVAS_HEIGHT / 2 + XMLSprite.SCALER * a * Math.sin(B);
					}
					//==== NOW DRAW THE TREE LINES =================
					if (prevX < xmlSprites[i].levelX) { // down to a child 
						prevYs.push(xmlSprites[i].y);
						prevSprites.push(prevSprite);
					} else if (prevX > xmlSprites[i].levelX) { // 
						for (j = 0; j < prevX - xmlSprites[i].levelX; j++) {
							prevYs.pop();
							prevSprites.pop();
						}
					} else {
						//prevYs[prevYs.length - 1] = xmlSprites[i].y;
					}
					prevX = xmlSprites[i].levelX;
					
					g = xmlSprites[i].graphics;
					g.clear();
					
					if (prevSprites.length != 0) {
						var verticalLineDistance:Number = xmlSprites[i].y - (prevSprites[prevSprites.length - 1].y + 10); // 15 to account for text height
						//trace("prevSprites.top().y: " + prevSprites[prevSprites.length - 1].y + "    xmlSprites[i].y: " + xmlSprites[i].y);
						if (verticalLineDistance > 0) {
							g.lineStyle(1, 0, 1);
							g.moveTo( -2, 10);
							g.lineTo( - XMLSprite.X_DIVISION / 2, 10);
							g.lineTo( - XMLSprite.X_DIVISION / 2, - verticalLineDistance + 5 );
						}
					}
					//prevY = xmlSprites[i].y;
					prevSprite = xmlSprites[i];
				}
				callLater(invalidateDisplayList);
			}
		}
	}
}