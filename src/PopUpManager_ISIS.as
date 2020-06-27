package
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import mx.containers.Canvas;
	
	import mx.core.UIComponent;

	public class PopUpManager_ISIS extends Canvas
	{		
		public function PopUpManager_ISIS()
		{
			super();
		}
		
		public function addPopUp(object:DisplayObject):void {
			this.addChild(object);
		}
		
		public function removePopUp(popUp:DisplayObject):void {
			try {
				this.removeChild(popUp);
			} catch(e:Error) {
				//trace("PopUp error: " + e.message);
			}
		}
		
		public function globalCoordinateTransform(object:UIComponent):Point {
			var xy:Point = object.contentToGlobal(new Point(0,0));
			return GMXMain.PopUps.globalToContent(xy);
		}
	}
}