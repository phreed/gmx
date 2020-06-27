package gmx_builder.drawing_tool 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	/**
	 * ...
	 * @author 
	 */
	public class GraphicLine extends GraphicObject
	{
		private var _points:Vector.<Point> = new Vector.<Point>();
		
		public function addPoint(point:Point):void {
			_points.push(point);
			_showing = true;
		}
		public function getLastPointCopy():Point {
			if (_points.length == 0) return null;
			return _points[_points.length - 1].clone();
		}
		
		public function removePoint(point:Point):void {
			for (var i:int = 0; i < _points.length; i++) {
				if (point.equals(_points[i])) {
					_points.splice(i, 1);
					_lineStyles.splice(i, 1);
					if (_points.length == 0) {
						_showing = false;
						try {
							//this.parent.removeChild(this);
							// treat the next lineDown as firstLineDown in case
							// the user is still in line mode
							ActionScriptGraphicsGenerator.firstLineDown = true;
						} catch (e:Error) {
							// this isn't the nicest way to do this, but what the hey
						}
					}
					this.invalidateDisplayList();
					return;
				}
			}
		}
		private var _lineStyles:Vector.<GraphicLineStyle> = new Vector.<GraphicLineStyle>();
		public function addLineStyle(style:GraphicLineStyle):void {
			_lineStyles.push(style);
		}
		override public function setLineStyle(val:GraphicLineStyle):void {
			// set all the linestyles to be the same
			for (var i:int = 0; i < _lineStyles.length; i++) {
				_lineStyles[i] = val;
			}
		}
		override public function getLineStyle():GraphicLineStyle {
			if (_lineStyles.length == 0) { return new GraphicLineStyle(1.0, 0, 1.0); }
			return _lineStyles[_lineStyles.length - 1];
		}
		
		public function GraphicLine(newUid:String) {
			super(newUid);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var g:Graphics = this.graphics;
			g.clear();
			if (_points.length == 0) { return; }
			
			var i:int;
			g.moveTo(_points[0].x, _points[0].y);
			for (i = 1; i < _points.length; i++) {
				g.lineStyle(_lineStyles[i].thickness, _lineStyles[i].color, _lineStyles[i].alpha);
				g.lineTo(_points[i].x, _points[i].y);
			}
			if (_fillColor != -1) { g.beginFill(_fillColor, _fillAlpha); }
			
			g.moveTo(_points[0].x, _points[0].y);
			for (i = 1; i < _points.length; i++) {
				g.lineStyle(GraphicObject.CLICKABLE_LINE_THICKNESS, 0xffffff, 0.1);
				g.lineTo(_points[i].x, _points[i].y);
			}
			
			g.endFill();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		override public function translate(dx:Number, dy:Number):void {
			for (var i:int = 0; i < _points.length; i++) {
				_points[i].x += dx;
				_points[i].y += dy;
			}
			this.invalidateDisplayList();
		}
		
		override public function dumpActionScript():String {
			if (!_showing || _points.length == 1) { return ""; }
			var output:String = "";
			
			
			var diff:Point = ActionScriptGraphicsGenerator.instance.canvasOriginPoint;
			if (_fillColor != -1) { output += "g.beginFill(0x" + _fillColor.toString(16) + ", " + _fillAlpha + ");\n" }
			output += "g.lineStyle(" + _lineStyles[0].thickness + ", 0x" + _lineStyles[0].color.toString(16) + ", " + _lineStyles[0].alpha + ");\n";
			output += "g.moveTo(" + (_points[0].x - diff.x) + ", " + (_points[0].y - diff.x) + ");\n";
			for (var i:int = 1; i < _lineStyles.length; i++) {
				if (_lineStyles[i - 1].thickness  != _lineStyles[i].thickness ||
					_lineStyles[i - 1].color  != _lineStyles[i].color ||
					_lineStyles[i - 1].alpha  != _lineStyles[i].alpha) {
						output += "g.lineStyle(" + _lineStyles[i].thickness + ", 0x" + _lineStyles[i].color.toString(16) + ", " + _lineStyles[i].alpha + ");\n";
				}
				output += "g.lineTo(" + (_points[i].x - diff.x) + ", " + (_points[i].y - diff.x) + ");\n";
			}
			if (_fillColor != -1) {
				output += "g.endFill();\n\n";
			}
			return output;
		}
		
		override public function dumpSVG():String {
			if (!_showing || _points.length == 1) { return ""; }
			var output:String = "";
			var diff:Point = ActionScriptGraphicsGenerator.instance.canvasOriginPoint;
			var r:int = (_lineStyles[0].color & 0xff0000) / 0x10000;
			var g:int = (_lineStyles[0].color & 0x00ff00) / 0x100;
			var b:int = _lineStyles[0].color & 0x0000ff;
			var alpha:Number = _lineStyles[0].alpha;
			output += '<path style="stroke-linejoin:round;stroke-linecap:round;stroke-width:' + _lineStyles[0].thickness;
			output +=  ';stroke:rgb(' + r + ',' + g + ',' + b + ')'
			output +=  ';stroke-opacity:' + alpha;
			if (_fillColor != -1) {
				r = (_fillColor & 0xff0000) / 0x10000;
				g = (_fillColor & 0x00ff00) / 0x100;
				b = _fillColor & 0x0000ff;
				output += ';fill:rgb('+r+','+g+','+b+');fill-opacity:' + _fillAlpha;
			} else {
				output += ';fill:none';
			}
			output += '" d="M' + (_points[0].x - diff.x) + ' ' + (_points[0].y - diff.y);
			for (var i:int = 1; i < _points.length; i++) {
				output += ' ' + (_points[i].x - diff.x) + ' ' + (_points[i].y - diff.y);
			}
			output += '"/>\n'; // end with a ' z/>' if you want to close the loop
			return output;
		}
	}
}