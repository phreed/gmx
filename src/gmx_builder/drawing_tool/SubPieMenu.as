package gmx_builder.drawing_tool 
{
	import flash.events.Event;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author 
	 */
	public class SubPieMenu extends UIComponent {
		private var _numDivisions:int = 6; // default
		public function set numDivisions(val:int):void { _numDivisions = val; }
		private var _commands:Vector.<String> = new Vector.<String>(); // the commands being run in response to a selected division
		public function set commands(newCommands:Vector.<String>) { _commands = newCommands; }
		private var _backDivision:int = 0; // offset of the "back" division which goes back to the main pie menu
		// example(4 divisions): if the user hovered the mouse over the bracketed division, the
		//  					subPieMenu would disappear and control would revert to the pie menu
		//      backDivision = 0:
		//            2 | 3
		//           --   --
		//            1 |[0]
		
		//      backDivision = 2:
		//           [2]| 3
		//           --   --
		//            1 | 0
		
		public function SubPieMenu(backDivision:int, numDivisions:int, commands:Vector.<String>) {
			_backDivision = _backDivision;
			_numDivisions = _numDivisions
			
		}
			
		public function entering(event:Event):void {
			if (!this.visible) { this.visible = true; }
			if (this.alpha < 1.0) {
				this.alpha += 0.05;
			} else {
				this.alpha = 1.0;
				this.removeEventListener(Event.ENTER_FRAME, entering);
			}
		}
		
		public function fading(event:Event):void {
			if (this.alpha > 0) {
				this.alpha -= 0.05;
			} else {
				this.alpha = 0.0;
				this.visible = false;
				this.removeEventListener(Event.ENTER_FRAME, fading);
			}
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
	}
	
}