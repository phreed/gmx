package gmx_builder.drawing_tool
{
	import constants.ArtworkFilters;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author 
	 */
	public class GraphicObject extends UIComponent
	{
		protected var _showing:Boolean = false;
		private function get showing():Boolean { return _showing; }
		
		public static const CLICKABLE_LINE_THICKNESS:Number = 30;
		
		private var _uid:String;
		public function get objectUid():String { return _uid; }
		public function select():void { this.filters = [ArtworkFilters.FOCUS_HALO]; }
		public function deselect():void { this.filters = []; }
		
		public function GraphicObject(newUid:String) {
			_uid = newUid;
		}
		
		protected var _fillColor:int = -1;
		public function get fillColor():int { return _fillColor; }
		public function set fillColor(val:int):void { _fillColor = val; }
		protected var _fillAlpha:Number = 1.0;
		public function get fillAlpha():Number { return _fillAlpha; }
		public function set fillAlpha(val:Number):void { _fillAlpha = val; }
		
		public function dumpActionScript():String {
			throw new Error("attempted to run abstract function dumpActionScript in Class GraphicObject");
		}
		
		public function dumpSVG():String {
			throw new Error("attempted to run abstract function dumpSVG in Class GraphicObject");
		}
		
		public function translate(dx:Number, dy:Number):void {
			throw new Error("attempted to run abstract function translate in Class GraphicObject");
		}
		
		public function setLineStyle(lineStyle:GraphicLineStyle):void {
			throw new Error("attempted to run abstract function setLineStyle in Class GraphicObject");
		}
		public function getLineStyle():GraphicLineStyle {
			throw new Error("attempted to run abstract function getLineStyle in Class GraphicObject");
		}
	}
	
}