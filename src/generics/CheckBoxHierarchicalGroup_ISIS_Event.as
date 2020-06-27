package generics
{
	import flash.events.Event;

	public class CheckBoxHierarchicalGroup_ISIS_Event extends Event
	{		
		public static const CHECK_BOX_GROUP_CHANGE:String = "checkBoxGroupChange";
		
		public function CheckBoxHierarchicalGroup_ISIS_Event(type:String, bubbles:Boolean=true, cancelable:Boolean=true)
		{
			super(type, bubbles, cancelable);
		}
	}
}