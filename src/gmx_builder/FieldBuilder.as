package gmx_builder 
{
	import records.Field;
	import records.Record;
	import flash.events.Event;
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.TextInput;
	/**
	 * ...
	 * @author 
	 */
	public class FieldBuilder extends HBox
	{
		private var fieldCombo:ComboBox;
		private var valueTextInput:TextInput;
		private var _ruid:String = null;

		public function get value():Vector.<String> {
			var output:Vector.<String> = new Vector.<String>();
			output.push(fieldCombo.text);
			output.push(valueTextInput.text);
			return output;
		}
		public function FieldBuilder() 
		{
			super();
			var label:Label;
			var comboBox:ComboBox;
			
			label = new Label();
			label.text = "fid: ";
			this.addChild(label);
			
			fieldCombo = new ComboBox();
			fieldCombo.width = 100;
			fieldCombo.editable = true;
			this.addChild(fieldCombo);
			fieldCombo.addEventListener(Event.CHANGE, fidChange)
			
			label = new Label();
			label.text = "value: ";
			this.addChild(label);
			
			valueTextInput = new TextInput();
			this.addChild(valueTextInput);
		}
		
		public function resetDataProvider(fieldList:ArrayCollection, ruid:String):void {
			fieldCombo.dataProvider = fieldList;
			_ruid = ruid;
			
			fidChange();
		}
		
		private function fidChange(event:Event = null):void {
			var record:Record = GMXDictionaries.getRuid(_ruid);
			if (record == null) { return; }
			
			var field:Field = record.getField(fieldCombo.text);
			if (field == null) { 
				valueTextInput.text = "";
				return; 
			}
			
			valueTextInput.text =  field.value;
		}
		
		public function set fid(val:String):void {
			fieldCombo.selectedItem = val;
			fieldCombo.text = val;
			fidChange();
		}
	}

}