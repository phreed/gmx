package generics
{
	import generics.ToggleButtonGroup_ISIS_Event;
	import flash.events.MouseEvent;
	import generics.Button_X;
	import interfaces.IField;
	import generics.ComponentCreationEvent;
	/**
	 * ...
	 * @author 
	 */
	public class ToggleButton_X extends Button_X implements IField
	{
		public function ToggleButton_X() 
		{
			super();
			this.toggle = true;
			this.addEventListener(MouseEvent.CLICK, clickedDispatchToggleButtonEvent);
		}
		
		private function clickedDispatchToggleButtonEvent(event:MouseEvent):void {
			this.dispatchEvent(new ToggleButtonGroup_ISIS_Event(ToggleButtonGroup_ISIS_Event.TOGGLE_BUTTON_CHANGE, this));
		}
	
		override public function set selected(val:Boolean):void {
			//trace("selected: " + val);
			super.selected = val;
			if (_field != null) { _field.value = val + ""; }
		}
		
		
		override public function build(xml:XML):void {
			super.build(xml);
			this.dispatchEvent(new ComponentCreationEvent(ComponentCreationEvent.CREATED, this, true, true));
		}
	}
}