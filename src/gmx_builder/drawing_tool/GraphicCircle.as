package gmx_builder.drawing_tool 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	/**
	 * ...
	 * @author 
	 */
	public class GraphicCircle extends GraphicObject
	{
		private var _center:Point;
		public function set center(point:Point):void { _center = point; }
		private var _radius:Number = -1;
		public function set radius(val:Number):void { _radius = val; }
				
		private var _lineStyle:GraphicLineStyle;
		override public function setLineStyle(val:GraphicLineStyle):void {
			_lineStyle = val;
		}
		override public function getLineStyle():GraphicLineStyle {
			return _lineStyle;
		}
		
		public function GraphicCircle(newUid:String) {
			super(newUid);
		}
		public function clear():void {
			this.graphics.clear();
			_showing = false;
		}
		override public function translate(dx:Number, dy:Number):void {
			_center.x += dx;
			_center.y += dy;
			this.invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var g:Graphics = this.graphics;
			g.clear();
			if (_center == null || _radius == -1 || _lineStyle == null) { return; }
			_showing = true;
			g.lineStyle(GraphicObject.CLICKABLE_LINE_THICKNESS, 0xffffff, 0.1);
			g.drawCircle(_center.x, _center.y, _radius);
			
			if (_fillColor != -1) { g.beginFill(_fillColor, _fillAlpha); }
			g.lineStyle(_lineStyle.thickness, _lineStyle.color, _lineStyle.alpha);
			g.drawCircle(_center.x, _center.y, _radius);
			g.endFill();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		override public function dumpActionScript():String {
			if (!_showing) { return ""; }
			var output:String = "";
			var diff:Point = ActionScriptGraphicsGenerator.instance.canvasOriginPoint;
			if (_fillColor != -1) { output += "g.beginFill(0x" + _fillColor.toString(16) + ", " + _fillAlpha + ");\n" }
			output += "g.lineStyle(" + _lineStyle.thickness + ", 0x" + _lineStyle.color.toString(16) + ", " + _lineStyle.alpha + ");\n";
			output += "g.drawCircle(" + (_center.x - diff.x) + ", " + (_center.y - diff.y) + ", " + _radius + ");\n";	
			if (_fillColor != -1) {
				output += "g.endFill();\n\n";
			}
			return output;
		}
		
		override public function dumpSVG():String {
			if (!_showing) { return ""; }
			var output:String = "";
			var diff:Point = ActionScriptGraphicsGenerator.instance.canvasOriginPoint;
			var r:int = (_lineStyle.color & 0xff0000) / 0x10000;
			var g:int = (_lineStyle.color & 0x00ff00) / 0x100;
			var b:int = _lineStyle.color & 0x0000ff;
			output += '<circle style="stroke-linejoin:round;stroke-linecap:round;stroke-width:';
			output += _lineStyle.thickness + ';stroke:rgb(' + r + ',' + g + ',' + b + ')';
			output +=  ';stroke-opacity:' + _lineStyle.alpha;
			if (_fillColor != -1) {
				r = (_fillColor & 0xff0000) / 0x10000;
				g = (_fillColor & 0x00ff00) / 0x100;
				b = _fillColor & 0x0000ff;
				output += ';fill:rgb(' + r + ',' + g + ',' + b + ');fill-opacity:' + _fillAlpha;
			} else {
				output += ';fill:none';
			}
			//fill:rgb(200,100,50);stroke:rgb(0,0,100);' + 
			output += '" cx="' + (_center.x - diff.x) +'" cy="' + (_center.y - diff.y) +'" r="' + _radius +'"/>\n';
			return output;
		}
	}
}