package constants 
{
	import flash.filters.GlowFilter;
	import flash.filters.DropShadowFilter;
	
	/**
	 * ...
	 * @author 
	 */
	public class ArtworkFilters 
	{
		public static const SHADOW_DIST:Number = 1;
		
		public static const TOP_LEFT_COMPONENT_GLARE:DropShadowFilter = 
			new DropShadowFilter(SHADOW_DIST, 45.0, 0xefefef, 1, 5, 5, 1, 1, true);
		public static const TOP_LEFT_COMPONENT_ACTIVE_SHADOW:DropShadowFilter = 
			new DropShadowFilter(SHADOW_DIST, 45.0, 0x999999, 1, 5, 5, 1, 1, true);
		public static const TOP_LEFT_COMPONENT_SHADOW:DropShadowFilter = 
			new DropShadowFilter(SHADOW_DIST, 45.0, 0x666666, 1, 5, 5, 1, 1, true);
		public static const BOTTOM_RIGHT_COMPONENT_SHADOW:DropShadowFilter = 
			new DropShadowFilter(SHADOW_DIST, 225.0, 0x666666, 1, 5, 5, 1, 1, true);
		public static const BOTTOM_RIGHT_COMPONENT_GLARE:DropShadowFilter = 
			new DropShadowFilter(SHADOW_DIST, 225.0, 0xcccccc, 1, 5, 5, 1, 1, true);
		public static const FOCUS_HALO:GlowFilter = 
			new GlowFilter(0xccccff, 1, 6.0, 6.0, 2.5, 1);
	}
	
}