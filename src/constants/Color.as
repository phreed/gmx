// ActionScript file

package constants 
{	
	import mx.logging.ILogger;
	import mx.logging.Log;	
	
	public class Color {
		public static const ALPHA_20:uint = (0.2 * 0xFF000000) | 0x00FFFFFF;
		public static const ALPHA_40:uint = (0.4 * 0xFF000000) | 0x00FFFFFF;
		public static const ALPHA_50:uint = (0.5 * 0xFF000000) | 0x00FFFFFF;
		
		private static const WHITE:uint = 0xFFFFFFFF; 
		private static const BLACK:uint = 0xFF000000;
		private static const VERY_DARK_GRAY:uint = 0xFF666666;
		private static const DARK_GRAY:uint = 0xFF999999;
		private static const MEDIUM_GRAY:uint = 0xFFBBBBBB;
		private static const LIGHT_GRAY:uint = 0xFFCCCCCC;
		private static const OFF_WHITE:uint = 0xFFEFEFEF;
		private static const OFF_WHITE_BACKGROUND:uint = 0xFFEEEEEE;
		private static const TAUPE:uint = 0xFFC4BEAA;
		
		private static const VERY_DARK_BLUE:uint = 0xFF000099;		
		private static const SKY_BLUE:uint = 0xFFBFD8FA;		
		private static const NAVY_BLUE:uint = 0xFF003399;
		private static const DARK_BLUE:uint = 0xFF0480FB;
		private static const MIDNIGHT_BLUE:uint = 0xFF000066;
		private static const PALE_BLUE:uint = 0xFFCCF2FF;
        private static const CYSTAL_BLUE:uint = 0xFF80E0FF;
        private static const GUNMETAL_BLUE:uint = 0xFF336699;
        private static const PURPLE:uint = 0xFF663399;
		private static const CYAN:uint = 0xFF00FFFF;
		
		private static const GREEN:uint = 0xFF00CC00;
		private static const BAMBOO_GREEN:uint = 0xFFAAFFAA;
		private static const NEON_GREEN:uint = 0xFF00FF00;
		private static const PALE_GREEN:uint = 0xFFE1FFE1;
		private static const GREEN_BLUE:uint = 0xFF0093DD;
		private static const BRIGHT_GREEN:uint = 0xFF00CC33;
		
		private static const LIGHT_YELLOW:uint = 0xFFFFFF66; 	
		private static const YELLOW:uint = 0xFFFFFF00;
		private static const PALE_YELLOW:uint = 0xFFFFFFCC; 	
		private static const ORANGE:uint = 0xFFFF9900; 	
		
		private static const RED:uint = 0xFFFF0000; 
		private static const SALMON:uint = 0xFFFF8080;
		private static const PALE_SALMON:uint = 0xFFFFCCCC;
	    private static const MAGENTA:uint = 0xFFFF008C;
	    private static const CARMINE_RED:uint = 0xFFFF0033;
	    
	    private static const BLUE:uint = 0xFF0000FF; 
        private static const PLUM:uint = 0xFF990099;
        private static const PLUM_RED:uint = 0xFF800080;
        private static const LIGHT_ORCHID:uint = 0xFFE29FFF;
        
        private static const TERRACOTTA:uint = 0xFFCC9900;
        private static const SADDLE_BROWN:uint = 0xFF993300;
        private static const KHAKI:uint = 0xFFD2B06A;
        private static const SAFARI:uint = 0xFF806210;
        
        public static const AMBER:uint = 0xFFFFD13A; // both a color and a type

       
	 /**
     * See MilSpec 2525B/ch1 TABLE XIII. Default colors for symbology
     * DESCRIPTION                    PRINT    ICON                    FILL
     * Friend, Assumed Friend         Blue     Cyan(0, 255, 255)       Crystal Blue(128, 224, 255)
     * Unknown, Pending               Yellow   Yellow(255, 255, 0)     Light Yellow(255, 255, 128)
     * Neutral                        Green    Neon Green(0, 255, 0)   Bamboo Green(170, 255, 170)
     * Hostile, Suspect, Joker, Faker Red      Red(255, 0, 0)          Salmon(255, 128, 128)
     * METOC                          Purple   Plum Red(128, 0, 128)   Light Orchid(226, 159, 255)
     *                                Brown    Safari(128, 98, 16)     Khaki(210, 176, 106)
     * Boundaries, lines, areas, text, icons and frames
     *                                Black    Black(0, 0, 0)          Black(0, 0, 0)
     * White-filled icons             White    White(255, 255, 255)    Off-White (6% Grey)(239, 239, 239)
     */
       public static const SYSTEM_RECOMMENDED:uint = MAGENTA;
       public static const SYSTEM_PROJECTED:uint = PLUM;
       public static const ELEMENT_FOCUS:uint = TERRACOTTA & Color.ALPHA_50;
       
       public static const FRIENDLY_LINE:uint = NAVY_BLUE;
       public static const FRIENDLY_STROKE:uint = BLACK;
       public static const FRIENDLY_FILL:uint = CYSTAL_BLUE;
       public static const FRIENDLY_FILL_HIGHLIGHT:uint = DARK_BLUE;
       public static const FRIENDLY_FILL_LOWLIGHT:uint = PALE_BLUE;
       
       public static const ENEMY_LINE:uint = RED;
       public static const ENEMY_STROKE:uint = RED;
       public static const ENEMY_FILL:uint = SALMON;
       public static const ENEMY_FILL_HIGHLIGHT:uint = RED;
       public static const ENEMY_FILL_LOWLIGHT:uint = PALE_SALMON;
       
       public static const QUESTIONED_STROKE:uint = BRIGHT_GREEN;
       
       public static const NEUTRAL_LINE:uint = GREEN;
       public static const NEUTRAL_STROKE:uint = GREEN;
       public static const NEUTRAL_FILL:uint = BAMBOO_GREEN;
       public static const NEUTRAL_FILL_HIGHLIGHT:uint = NEON_GREEN;
       public static const NEUTRAL_FILL_LOWLIGHT:uint = PALE_GREEN;
       
       public static const UNKNOWN_LINE:uint = YELLOW;
       public static const UNKNOWN_STROKE:uint = YELLOW;
       public static const UNKNOWN_FILL:uint = LIGHT_YELLOW;
       public static const UNKNOWN_FILL_HIGHLIGHT:uint = YELLOW;
       public static const UNKNOWN_FILL_LOWLIGHT:uint = PALE_YELLOW;
       
       public static const METOC_1_FILL:uint = LIGHT_ORCHID;
       public static const METOC_1_ICON:uint = PLUM_RED;
       
       public static const METOC_2_FILL:uint = KHAKI;
       public static const METOC_2_ICON:uint = SAFARI;
       
       public static const METOC_3_ICON:uint = MAGENTA;
       
       public static const WHITE_FILLED_UNITS:uint = OFF_WHITE;
       public static const WHITE_FILLED_ICONS:uint = WHITE;
       public static const MAP_TEXT_COLOR:uint = WHITE;
       
       public static const BACKLIGHT:uint = OFF_WHITE;
       
       public static const ECHELON:uint = BLACK;
       public static const DEFAULT_LINE:uint = BLACK;
       
       public static const FREEDRAW_WORK:uint = RED;
       public static const FREEDRAW_DRAFT:uint = MIDNIGHT_BLUE;
       public static const FREEDRAW_NORMAL:uint = BLUE;
       public static const FREEDRAW_OUTLINE:uint = WHITE & Color.ALPHA_50;
       public static const FREEDRAW_SELECTED:uint = DARK_BLUE;
       public static const FREEDRAW_BACKDROP:uint = WHITE & Color.ALPHA_20;
       
       public static const INFO_TAG_BACKGROUND:uint = DARK_GRAY & Color.ALPHA_40;
       public static const INFO_TAG_LABEL_OUTLINE:uint = WHITE;
       
       public static const TRANSPARENT:uint = 0x00FFFFFF; 
       
       
       
        public static const FILL:int = 0;
        public static const ICON:int = 1;
             
        public static function affiliation(val:String, mode:int = ICON ):int 
        {
          switch (mode) {
            case ICON:
              switch (val) {
                case "P": return UNKNOWN_LINE; // PENDING
                case "U": return UNKNOWN_LINE; // UNKNOWN
                case "A": return FRIENDLY_LINE; // ASSUMED FRIEND
                case "F": return FRIENDLY_LINE; // FRIEND
                case "N": return NEUTRAL_LINE; // NEUTRAL
                case "S": return ENEMY_LINE; // SUSPECT
                case "H": return ENEMY_LINE; // HOSTILE
                case "G": return UNKNOWN_LINE; // EXERCISE PENDING
                case "W": return UNKNOWN_LINE; // EXERCISE UNKNOWN
                case "M": return FRIENDLY_LINE; // EXERCISE ASSUMED FRIEND
                case "D": return FRIENDLY_LINE; // EXERCISE FRIEND
                case "L": return NEUTRAL_LINE; // EXERCISE NEUTRAL
                case "J": return ENEMY_LINE; // JOKER
                case "K": return ENEMY_LINE; // FAKER
                default: return DEFAULT_LINE;
              }
            break;
            
            case FILL:
            default:
              switch (val) {
                case "P": return UNKNOWN_FILL; // PENDING
                case "U": return UNKNOWN_FILL; // UNKNOWN
                case "A": return FRIENDLY_FILL; // ASSUMED FRIEND
                case "F": return FRIENDLY_FILL; // FRIEND
                case "N": return NEUTRAL_FILL; // NEUTRAL
                case "S": return ENEMY_FILL; // SUSPECT
                case "H": return ENEMY_FILL; // HOSTILE
                case "G": return UNKNOWN_FILL; // EXERCISE PENDING
                case "W": return UNKNOWN_FILL; // EXERCISE UNKNOWN
                case "M": return FRIENDLY_FILL; // EXERCISE ASSUMED FRIEND
                case "D": return FRIENDLY_FILL; // EXERCISE FRIEND
                case "L": return NEUTRAL_FILL; // EXERCISE NEUTRAL
                case "J": return ENEMY_FILL; // JOKER
                case "K": return ENEMY_FILL; // FAKER
                case "white": return WHITE; // PLANNED SYMBOL
                default: return BACKLIGHT; // unfilled
              }
             }
             return BLACK; // BLACK
        }
        
        public static function get_alpha(fullColor:uint):Number {
        	// var _logger:ILogger = Log.getLogger("isis.fcs.wmis.color");
        	// _logger.debug("The Alpha is: " + ((fullColor & 0xFF000000) >>> 24)/255.0);
        	var alpha:uint = (fullColor & 0xFF000000) >>> 24;
        	if (alpha == 0) return 1.0;  // an alpha of 0 is certainly a mistake.
        	return alpha/255.0;
        }
		
		// various fill patterns
        
	}
}