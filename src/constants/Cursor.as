package constants
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import mx.core.BitmapAsset;
	
	import mx.managers.CursorManager;
		
	public class Cursor extends Object
	{
		private var _type:Class = null;
		private var _priority:int = 2;
		private var _x_offset:Number = 0;
		private var _y_offset:Number = 0;
		
		public function Cursor (type:Class, xoff:Number = 0, yoff:Number = 0, priority:int = 2)
		{
			this._type = type;
			this._priority = priority;
			this._x_offset = xoff;
			this._y_offset = yoff;
		}
		
		public function assign():int {
		   CursorManager.removeAllCursors();
		   return CursorManager.setCursor(_type, _priority, _x_offset, _y_offset);
		}
		
		public function push():int {
		   return CursorManager.setCursor(_type, _priority, _x_offset, _y_offset);
		}
		
		public function bitmap():Bitmap {
		   return new Bitmap(BitmapAsset(new this._type()).bitmapData);
		   // return CursorManager.setCursor(_type, _priority, _x_offset, _y_offset);
		}

	}
}
