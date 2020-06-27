package generics
{
	import interfaces.IField;
	import flash.events.MouseEvent;
	import mx.events.FlexEvent;
	/**
	 * ...
	 * @author 
	 */
	public class PushButton_X extends Button_X implements IField
	{
		
		public function PushButton_X() 
		{
			super();
			this.autoRepeat = true;
			this.setStyle("repeatDelay", 35);
		}
		
		override public function build(xml:XML):void {
			super.build(xml);
			if (_field == null) { return; }
			
			if (_sendButton) {
				this.removeEventListener(MouseEvent.CLICK, sendButtonClick);
				this.addEventListener(FlexEvent.BUTTON_DOWN, sendButtonClick, false, 0, true);
			} else {
				this.removeEventListener(MouseEvent.CLICK, GMXComponentListeners.buttonClick);
				this.addEventListener(FlexEvent.BUTTON_DOWN, GMXComponentListeners.buttonClick, false, 0, true);
			}
			
			if (xml.@repeatDelay != undefined) { // default 35 ms
				this.setStyle("repeatDelay", Number(xml.@repeatDelay));
			}
			if (xml.@repeatInterval != undefined) { // default 35 ms
				this.setStyle("repeatInterval", Number(xml.@repeatInterval));
			}
		}
	}

}