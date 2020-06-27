package
{
	import generics.tables.DataGrid_ISIS;
	import generics.Icon_X;
	import generics.MenuButton_X;
	import interfaces.IField;
	import generics.tables.ExpandTreeEvent
	import mx.controls.ComboBox;
	import records.Field;
	import records.RecordEvent;
	import records.RecordRef;
	import records.Record;
	import flash.events.Event;
	import generics.Button_X;
	import generics.CheckBox_X;
	import generics.ComboBox_X;
	import generics.TextArea_X;
	import generics.TextInput_X;
	import mx.controls.DataGrid;
	
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.events.DataGridEvent;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	
	public class GMXComponentListeners {
		static public function buttonClick(event:Event):void {
			var button:Button_X = event.currentTarget as Button_X;
			if (button.enabled == false || button.field == null) { return; }
			if (button.toggle == false) { 
				// set it true temporarily--just until the message is sent
				button.field.value = "true";
			} else { button.field.value = button.componentValue; }
			var buttonField:Field = button.field;
			if (button.sendMessage == true) {
				var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, buttonField, true, true);
				button.dispatchEvent(recordEvent);
			}
			if (button.toggle == false || button is MenuButton_X) {
				// message has been sent, revert to false value
				button.field.value = "false";
			}
		}
		
		static public function iconClick(event:MouseEvent):void {
			var icon:Icon_X = event.currentTarget as Icon_X;
			if (icon.enabled == false || icon.field == null) { return; }
			// set it true temporarily--just until the message is sent
			icon.field.value = "true";
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true);
			icon.dispatchEvent(recordEvent);
			icon.field.value = "false";
		}
		/*static public function itemClick(event:ItemClickEvent):void {
			var radioButton:RadioButton = event.currentTarget as RadioButton;
			if (radioButton != null) {
				
			} else {
				
			}
			
			var button:ButtonISIS = event.currentTarget as ButtonISIS;
			var buttonField:FieldBoolean = button.field;
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, buttonField, true, true);
			button.dispatchEvent(recordEvent);
		}*/
		static public function closeDropdown(event:Event):void {
			var comboBox:ComboBox_X = event.currentTarget as ComboBox_X;
			if (comboBox.enabled == false || comboBox.field == null) { return; }
			comboBox.field.value = comboBox.componentValue;
			if (comboBox.recordCollection != null && comboBox.selectedLabel != null) {	
				comboBox.recordCollection.addSelectedRuidByValue(comboBox.selectedLabel);
			}
			if (comboBox.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, comboBox.field, true, true);
			comboBox.dispatchEvent(recordEvent);
		}
		static public function textInputCallback(event:FlexEvent):void {
			var textInput:TextInput_X = event.currentTarget as TextInput_X;
			if (textInput.enabled == false || textInput.field == null) { return; }
			textInput.field.value = textInput.componentValue;
			if (textInput.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, textInput.field, true, true);
			textInput.dispatchEvent(recordEvent);
		}
		
		static public function textInputFocusOutCallback(event:FocusEvent):void {
			var textInput:TextInput_X = event.currentTarget as TextInput_X;
			if (textInput.enabled == false || textInput.field == null) { return; }
			textInput.field.value = textInput.componentValue;
			if (textInput.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, textInput.field, true, true);
			textInput.dispatchEvent(recordEvent);
		}
		static public function textAreaCallback(event:FlexEvent):void {
			var textArea:TextArea_X = event.currentTarget as TextArea_X;
			if (textArea.enabled == false || textArea.field == null) { return; }
			textArea.field.value = textArea.componentValue;
			if (textArea.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, textArea.field, true, true);
			textArea.dispatchEvent(recordEvent);
		}
		static public function textAreaFocusOutCallback(event:FocusEvent):void {
			var textArea:TextArea_X = event.currentTarget as TextArea_X;
			if (textArea.enabled == false || textArea.field == null) { return; }
			textArea.field.value = textArea.componentValue;
			if (textArea.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, textArea.field, true, true);
			textArea.dispatchEvent(recordEvent);
		}
		static public function dataGridChange(event:ListEvent):void {
			var dataGrid:DataGrid_ISIS = event.currentTarget as DataGrid_ISIS;
			var provider:XMLListCollection = dataGrid.dataProvider as XMLListCollection;
			try {
				var item:XML = provider.getItemAt(event.rowIndex) as XML;
			} catch (e:Error) {
				trace("ERROR: dataGridChange--event.rowIndex=" + event.rowIndex + " is out of bounds!");
				return;
			}
			var tableRecord:Record = GMXDictionaries.getRuid(item.@ruid.toString());
			if (tableRecord == null) {
				Alert.show("WARNING: attempted to update a Table Record, but the record id '" + item.@ruid.toString() + "' did not match a TableRecord in the dictionary.");
				return;
			}
			tableRecord.sendMessage();
		}
		static public function dataGridEditEnd(event:DataGridEvent):void {
			var dataGrid:DataGrid_ISIS = event.currentTarget as DataGrid_ISIS;
			var provider:XMLListCollection = dataGrid.dataProvider as XMLListCollection;
			var item:XML = provider.getItemAt(event.rowIndex) as XML;
			var tableRecord:Record = GMXDictionaries.getRuid(item.@ruid.toString());
			if (tableRecord == null) {
				Alert.show("WARNING: attempted to update a Table Record, but the record id '" + item.@ruid.toString() + "' did not match a TableRecord in the dictionary.");
				return;
			}
			// update the record first, then send message
			tableRecord.fromDataProviderXML(item);
			updateOtherCollections(dataGrid, tableRecord);
			tableRecord.sendMessage();
		}
		private static function updateOtherCollections(dataGrid:DataGrid_ISIS, record:Record):void {
			for (var i:int = 0; i < record.recordRefs.length; i++) {
				if (record.recordRefs[i].parentCollection == dataGrid.recordCollection || record.recordRefs[i].parentCollection == null) { 
					continue;
				}
				// this record is in another collection and so that collection must be updated with the new changes
				record.recordRefs[i].parentCollection.promptComponentUpdates();
			}
		}
		static public function taskOrgChange(event:ListEvent):void {
			/*var dataGrid:DataGrid_ISIS = event.currentTarget as DataGrid_ISIS;
			var provider:XMLListCollection = dataGrid.dataProvider as XMLListCollection;
			var item:XML = provider.getItemAt(event.rowIndex) as XML;
			var ruid:String = item.@ruid.toString();
			for each (var xml:XML in provider) {
				GMXDictionaries.getRuid(xml.@ruid.toString()).interactionState = "unselected";
			} 
			var tableRecord:TableRecord = GMXDictionaries.getRuid(item.@ruid.toString()) as TableRecord;
			if (tableRecord == null) {
				Alert.show("WARNING: attempted to update a Table Record, but the record id '" + ruid + "' did not match a TableRecord in the dictionary.");
				return;
			}
			tableRecord.interactionState = "selected";
			tableRecord.sendMessage();
			for (var i:int = 0; i < provider.length; i++) {
				if (provider[i].@ruid != undefined) {
					//if (provider[i].@ruid.toString == ruid) {
						if (provider[i].interactionState != undefined) {
							provider[i].interactionState = GMXDictionaries.getRuid(provider[i].@ruid.toString()).interactionState;
						} else provider[i].appendChild(new XML( < interactionState > { GMXDictionaries.getRuid(ruid).interactionState }</interactionState>));
					//}				
				}
			}
			dataGrid.dataProvider = provider;
			//trace("============= PROVIDER ==========: " + dataGrid.dataProvider);
			//trace("datagrid change event");
			*/
		}
		static public function openDropdown(event:DropdownEvent):void {
			var comboBox:ComboBox = event.currentTarget as ComboBox;
			//comboBox.dropdown.scaleX = comboBox.dropdown.scaleY = GMXMain.SCALE; 
			if (comboBox.dropdown != null) {
				comboBox.dropdown.scaleX = comboBox.dropdown.scaleY = GMXMain.SCALE;
			} else {
				
			}
		}
		static public function clickDropdown(event:MouseEvent):void {
			var comboBox:ComboBox = event.currentTarget as ComboBox;
			comboBox.invalidateDisplayList();
			comboBox.dropdown.scaleX = comboBox.dropdown.scaleY = GMXMain.SCALE;			
		}
		static public function checkBoxClick(event:MouseEvent):void {
			var checkBox:CheckBox_X = event.currentTarget as CheckBox_X;
			if (checkBox.enabled == false || checkBox.field == null) { return; }
			
			checkBox.field.value = checkBox.componentValue;
			if (checkBox.sendMessage == false) { return; }
			var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, checkBox.field, true, true);
			checkBox.dispatchEvent(recordEvent);
		}
		
		static public function expandTableTree(event:ExpandTreeEvent):void {
			var record:Record = GMXDictionaries.getRuid(event.ruid) as Record;
			var dataGrid:DataGrid_ISIS = event.currentTarget as DataGrid_ISIS;
			if (record != null && dataGrid != null) {
				var pertinentRecordRef:RecordRef = record.getRecordRefByCollection(dataGrid.recordCollection);
				if (pertinentRecordRef != null) {
					pertinentRecordRef.showChildren = event.showChildren;
				}
			}
			if (dataGrid != null) {
				dataGrid.dirty = true;
			}
			event.currentTarget.invalidateProperties();
		}
	}
}