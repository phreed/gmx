package generics
{
	import generics.ToggleButton_X;
	import generics.Canvas_X;
	import generics.ComponentCreationEvent;
	public class ToggleButtonGroup_X extends Canvas_X
	{
		private var _toggleButtons:Vector.<ToggleButton_X> = new Vector.<ToggleButton_X>();
		
		public function ToggleButtonGroup_X() 
		{
			super();
			this.addEventListener(ComponentCreationEvent.CREATED, toggleButtonCreated);
			this.addEventListener(ToggleButtonGroup_ISIS_Event.TOGGLE_BUTTON_CHANGE, toggleButtonChange);
		}
		
		private function toggleButtonCreated(event:ComponentCreationEvent):void {
			if (event.component is ToggleButton_X) {
				_toggleButtons.push(event.component as ToggleButton_X);
				event.stopPropagation();
			}
		}
		
		private function toggleButtonChange(event:ToggleButtonGroup_ISIS_Event):void {
			//trace("TOGGLE CHANGE");
			event.stopPropagation();
			for (var i:int = 0; i < _toggleButtons.length; i++) {
				//trace(_toggleButtons[i] + "   " + event.toggleButton);
				if (_toggleButtons[i] != event.toggleButton) {
					// turn off all the other toggle buttons
					_toggleButtons[i].selected = false;
				}
			}
		}
		
		override public function disintegrate():void {
			super.disintegrate();
			while (_toggleButtons.length != 0) { _toggleButtons.pop(); }
		}
	}
}