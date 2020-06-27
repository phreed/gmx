package generics
{
	import flash.events.Event;
	/**
	 * ...
	 * @author 
	 */
	public class ToggleButtonGroup_ISIS_Event extends Event
	{
		public static const TOGGLE_BUTTON_CREATED:String = "toggleButtonCreated";
		public static const TOGGLE_BUTTON_CHANGE:String = "toggleGroupChange";
		
		public var toggleButton:ToggleButton_X;
		
		public function ToggleButtonGroup_ISIS_Event(type:String, toggleButton:ToggleButton_X, bubbles:Boolean=true, cancelable:Boolean=true)
		{
			super(type, bubbles, cancelable);
			this.toggleButton = toggleButton;
		}
	}
}