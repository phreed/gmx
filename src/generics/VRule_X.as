package generics
{
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import mx.controls.VRule;
	
	import mx.controls.HRule;

	public class VRule_X extends VRule implements ISelfBuilding
	{
		public function VRule_X()
		{
			super();
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			
			this.percentWidth = 100;
			GMXComponentBuilder.setStandardValues(xml, this);
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			return;
		}
		public function setAttributes(attributes:Attributes):void {
		
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}