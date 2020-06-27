package generics
{
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.RecordEvent;
	import flash.events.MouseEvent;
	import mx.controls.Button;
	
	/**
	 * ...
	 * @author 
	 */
	public class SendButton_X extends Button implements ISelfBuilding
	{
		public function SendButton_X() {
			this.addEventListener(MouseEvent.CLICK, mouseClick);
			this.label = "Send";
		}
		
		private function mouseClick(event:MouseEvent):void {
			this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
		}
		
		public function build(xml:XML):void {
			GMXComponentBuilder.setStandardValues(xml, this);
			GMXComponentBuilder.processXML(this, xml);
		}
		public function set flexible(val:Boolean):void {
			return;
		}
		public function disintegrate():void {
			return;
		}
		public function get flexible():Boolean {
			return false;
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
	}
	
}