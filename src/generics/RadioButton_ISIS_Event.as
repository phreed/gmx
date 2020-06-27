package generics
{
	import flash.events.Event;

	public class RadioButton_ISIS_Event extends Event
	{
		public static const RADIO_BUTTON_CLICK:String = "radioButtonClick";
		public var button:RadioButton_X;
		
		
		public function RadioButton_ISIS_Event(type:String, button:RadioButton_X, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.button = button;
		}
		
	}
}