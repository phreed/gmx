package generics
{
	import flash.events.Event;
	
	import mx.core.UIComponent;

	public class ComponentCreationEvent extends Event
	{
		public var component:UIComponent;
		
		public static const CREATED:String = "createdComp";
		
		// this event is dispatched for certain components who need to keep track of children that may not be immediate children in the
		// display list.  For example, a CheckBoxHierarchicalGroup needs to have pointers to child check boxes, even though that checkbox
		// may be in a HBox & VBox a couple of levels down in the display list after the "build" from XML function is called.
		public function ComponentCreationEvent(type:String, component:UIComponent, bubbles:Boolean=true, cancelable:Boolean=true)
		{
			super(type, bubbles, cancelable);
			this.component = component;
		}
	}
}