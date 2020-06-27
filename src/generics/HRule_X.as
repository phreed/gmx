package generics
{
	import interfaces.ISelfBuilding;
	import records.Attributes;
	
	import mx.controls.HRule;

	public class HRule_X extends HRule implements ISelfBuilding
	{
		public function HRule_X()
		{
			super();
		}
		
		public function build(hRuleXML:XML):void {
			if (hRuleXML == null) { return; }
			
			var hRule:HRule = this;
			hRule.percentWidth = 100;
			GMXComponentBuilder.setStandardValues(hRuleXML, hRule);
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