package interfaces 
{
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import mx.core.UIComponent;
	
	/**
	 * ...
	 * @author 
	 */
	public class UIComponent_ISIS extends UIComponent implements IMultiField
	{
		public function get fieldNames():Array { throw new Error("UIComponent_ISIS get fieldNames function reached... this must be overriden by the child class! (" + this.className + ")"); }
		public function get defaultValues():Array { throw new Error("UIComponent_ISIS get defaultValues function reached... this must be overriden by the child class! (" + this.className + ")"); }
		
		public function UIComponent_ISIS() 
		{
			super();
		}
		
		public function build(xml:XML):void {
			throw new Error("UIComponent_ISIS build function reached... this must be overriden by the child class! (" + this.className + ")");
		}
//========= BEGIN IMultiField Implementation ==============================================
		protected var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			var rec:Record = GMXDictionaries.getRuid(val);
			if (rec == null) {
				this.record = new Record(val);
			} else { 
				this.record = rec;
			}
		}
		public function set layout(val:String):void {
			IFieldStandardImpl.setLayout(val);
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set fields(xml:XML):void {
			IFieldStandardImpl.setFields(this, xml, fieldNames, defaultValues);
		}
//========= END IMultiField Implementation ================================================
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			var i:int;
			for (i = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) {
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			if (fieldNames != null) for (i = 0; i < fieldNames.length; i++) {
				var field:Field = this[fieldNames[i]] as Field;
				if (field == null) { continue; }
				field.removeComponentRequiringUpdate(this); 
				this[fieldNames[i]] = null;
			}
			_record = null;
		}
		public function setAttributes(attributes:Attributes):void {
			// if all fields are disabled, then disable this component?  Not sure what to do with this
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}