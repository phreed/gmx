package generics
{
	import interfaces.ISelfBuilding;
	import records.Attributes;
	
	import mx.controls.Spacer;
	
	public class Spacer_X extends Spacer implements ISelfBuilding
	{
		public function Spacer_X()
		{
			super();
		}
		
		public function build(spacerXML:XML):void {
			if (spacerXML == null) { return; }
			
			GMXComponentBuilder.setStandardValues(spacerXML, this);
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			return;
		}
		public function setAttributes(attributes:Attributes):void {
			return;
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}