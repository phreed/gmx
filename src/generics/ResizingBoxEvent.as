package generics
{
	import flash.events.Event;
	/**
	 * ...
	 * @author 
	 */
	public class ResizingBoxEvent extends Event
	{
		public static const BOX_RESIZE:String = "box_resize"; 
		
		public function ResizingBoxEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = true)
		{
			super(type, bubbles, cancelable);
		}
	}
}