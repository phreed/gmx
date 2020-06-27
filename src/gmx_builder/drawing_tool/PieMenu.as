package gmx_builder.drawing_tool 
{
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author 
	 */
	public class PieMenu extends UIComponent {
		private var _subPieMenus:Vector.<SubPieMenu> = new Vector.<SubPieMenu>();
		
		public function PieMenu() {
			super();
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
	}
	
}