package gmx_builder.drawing_tool 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	/**
	 * ...
	 * @author 
	 */
	public class GraphicLineStyle
	{
		public var thickness:Number  = 1.0;
		public var color:uint = 0;
		public var alpha:Number = 1.0;
		
		public function GraphicLineStyle(thickness:Number, color:uint, alpha:Number) {
			this.thickness = thickness;
			this.color = color;
			this.alpha = alpha;
		}
		
		public static function equals(style1:GraphicLineStyle, style2:GraphicLineStyle):Boolean {
			if (style1.thickness == style2.thickness &&
				style1.color == style2.color &&
				style1.alpha == style2.alpha) {
					return true;
			}
			return false;
		}
	}
}