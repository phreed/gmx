package interfaces
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import mx.core.FlexSprite;

	/**
	 * This class is for sprites (such as the CommandedBug) which which need to have a flexible origin (often for
	 * rotation purposes). This can be accomplished by nesting a Sprite in a Sprite, and this class basically
	 * takes care of this.  The purpose of this class is simply to make it easier to draw a sprite while having
	 * it act as if it was drawn using a different origin--one that can be set any time.
	 */
	public class StaticSprite extends FlexSprite
	{
		private var _sprite:FlexSprite = new FlexSprite();
		
		override public function set mouseEnabled(enabled:Boolean):void {
			super.mouseEnabled = enabled;
			_sprite.mouseEnabled = enabled;			
		}
		
		protected var _hotSpot:Point = new Point(0,0);
		public function get hotSpot():Point { return _hotSpot; }
		public function set hotSpot(point:Point):void { 
			var currentDeltaX:Number = _hotSpot.x;
			var currentDeltaY:Number = _hotSpot.y;
			_hotSpot = point;
			
			_sprite.x = _sprite.x - currentDeltaX + _hotSpot.x;
			_sprite.y = _sprite.y - currentDeltaY + _hotSpot.y;
		}
		
		override public function get graphics():Graphics {
			return _sprite.graphics;
		}
		
		override public function StaticSprite(newHotSpot:Point = null)
		{
			super();
			this.addChild(_sprite);
			if (newHotSpot != null) {
				this.hotSpot = newHotSpot;	
			}
		}
		
		static public function getInstance(newHotSpot:Point = null):StaticSprite {
			var staticSprite:StaticSprite = new StaticSprite(newHotSpot);
			return staticSprite;
		}
	}
}