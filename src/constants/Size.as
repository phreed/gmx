package constants 
{
	import flash.system.Capabilities;
	
	public class Size {
		  /**
        *  For the standard screen size and resolution.
        * How many pixels per cm.
        */
		//public static const MM:Number = MM_BASE * 0.5 * ( Capabilities.screenResolutionX / 1440.0 + Capabilities.screenResolutionY / 900.0 );
		public static const MM:Number = 2.75;  // 17" 1440x900 monitor px/mm
        //public static const MM:Number = 1440.0/365.0;  // 17" 1440x900 monitor px/mm
		// public static const MM:Number = 1440.0/365.0;  // 19" 1440x900 monitor px/mm
		public static const PT:Number = 0.35 * MM;
		
		/**
		 * Line thicknesses as provided by the lineStyle method are in pixels.
		 */
		// some standard sizes
        public static const SYMBOL_THICK:Number = 2*MM;    
        public static const GRAPH_GRID_LINE:Number = 1.0*MM;
        
        public static var GENERAL_TEXT_SCALE:Number = 1.0*MM;  // General Visual Accuity Index (GVAI)       
        public static const HINT_LEADER:Number = 20.0*MM // How big the initial leader should be
        
		// for tactical graphics
        public static const LABEL_SCALE_FIXED:Number = 0.25;  
        public static const LABEL_SCALE_VARIABLE:Number = 1.5;
	}
}
