package constants
{
	import flash.geom.Point;
	import isis.fcs.tactics.GPoint;
	
	public class Sketch
	{
		// the characteristic size of the bounding octagon for battle space objects
		public static const OCTAGON_LENGTH:uint = 40;
		
		// how many grid lines on the page (approximately)
        public static const GRAPH_GRID_LINE:uint = 10;
        
        // how far in the coordinate labels are placed
        public static const GRID_LABEL_OFFSET:Number = 0.05;
		
		// first anchor point (e.g. the tip of an arrow)
		public static const ORIGIN:Point = new Point(0.0, 0.0); 
		
		// the on screen offset of the tail of an arrow
		public static const TAIL:Point = new Point(200, 0);  
		
		// the distance along the axis and the distance from the axis of the side of an arrow
		public static const STARBOARD:Point = new Point(0.6, 0.4); 
		
		// the on screen offset of the width of a tactic (rectangle)
		public static const WIDTH:Point = new Point(200, 0);  
		public static const HEIGHT:Point = new Point(0, 200);  
		
	}
}