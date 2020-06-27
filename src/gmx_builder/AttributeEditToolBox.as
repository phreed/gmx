package gmx_builder
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	/**
	 * ...
	 * @author 
	 */
	public class AttributeEditToolBox extends VBox {
		
		private var _textInputs:Vector.<TextInput> = new Vector.<TextInput>; // provide some retention of selected TextInput and what-not
		private var _comboBoxes:Vector.<ComboBox> = new Vector.<ComboBox>; // provide some retention of selected TextInput and what-not
		private var _checkBoxes:Vector.<CheckBox> = new Vector.<CheckBox>;
		
		private const maxTextInputs:int = 100;
		
		public function AttributeEditToolBox() {
			this.horizontalScrollPolicy = ScrollPolicy.ON; 
			this.verticalScrollPolicy = ScrollPolicy.ON;
			this.setStyle("backgroundColor", 0xcccccc);
			
			for (var i:int; i < maxTextInputs; i++) {
				_textInputs.push(new TextInput());
				_comboBoxes.push(new ComboBox());
				_checkBoxes.push(new CheckBox());
			}
		}		
		//================= BEGIN ToolBox Functions =======================================================================
// ==> The toolbox contains TextInputs (or other Input components) for every editable attribute available to the specific selected component type.
// 		These attributes are specified in the ClassDefinitions.xml file.  When an object is selected, its XML 
//		is used to populate these TextInputs.

		/**
		 * Expects the XML whose 1st element is the identifier (not class name) used by GMXMain e.g. "TextInput", not "TextInput_ISIS"
		 * (see gmx_builder.GMXComponentProperties.as)
		 * ... the rest of the elements are strings of the form 
		 *     propertyName:toolTip
		 * e.g. one of these for a Button would be
		 *     size:String [large|small|mini|(etc.)] 
		 * The toolTip is used to guide the user and can contain any string.  Furthermore, the components used for that
		 * property in the tool box are determined by what is in the toolTip section.
		 * 	1) if the first work in the toolTip is "Boolean" then a CheckBox component is used for that property
		 *  2) if anywhere in the toolTip there is "[X|Y|Z|...]" where X, Y, Z, ... are any strings, then a ComboBox is
		 * 		used with all the options found between the [] characters and delimited by the | character.
		 * all other properties have a TextInput component associated with them.
		 * @param	componentXML NOTE!!!! this COMES FROM ClassDefinitions.xml
		 */
		public function createToolBox(componentXML:XML):void {
			var i:int;
			while (this.numChildren != 0) { 
				this.removeChildAt(0);
			}
			
			if (componentXML == null || GMXBuilder.selectedXML == null) { return; }
			componentXML = componentXML.copy();
			for (i = 0; i < GMXComponentProperties.standardComponentPropertyVector.length; i++) {
				componentXML.appendChild(GMXComponentProperties.standardComponentPropertyVector[i]);
			}
			if (componentXML.@container.toString() == "true") {
				for (i = 0; i < GMXComponentProperties.standardContainerPropertyVector.length; i++) {
					componentXML.appendChild(GMXComponentProperties.standardContainerPropertyVector[i]);
				}
			}
			var xmlProperties:XMLList = componentXML.children();
			var numProperties:int = xmlProperties.length();
			
			var propertyName:String;
			var propertyToolTip:String;
			
			var componentLabel:Label = new Label();
			componentLabel.text = componentXML.localName();
			componentLabel.width = 200;
			componentLabel.height = 30;
			componentLabel.setStyle("fontSize", 14);
			componentLabel.setStyle("fontWeight", "bold");
			this.addChild(componentLabel);
			//trace("propertyVector: " + propertyVector);
			for (i = 0; i < numProperties; i++) {
				// property tooltip is delimited by a single ":" ... before the ":" is the property name, after is the tooltip
				propertyName = xmlProperties[i].localName();
				propertyToolTip = xmlProperties[i].toString();
				if (propertyName.toLowerCase() == "samplexml") { continue; }
				
				var hBox:HBox = new HBox();
				var label:Label = new Label();
				var comboBoxArray:Array = null;
				var editableComponent:UIComponent;
				var defaultValue:String = null; // NEED TO IMPLEMENT THIS (for example, if default visible="true", it should have a checkmark there)
												// might even want to color the default value components different
				if (propertyToolTip.substring(0, 7) == "Boolean") { // make a checkbox instead of a TextInput
					var checkBox:CheckBox = _checkBoxes[i];					
					checkBox.selected = GMXBuilder.selectedXML["@" + propertyName] == "true" ? true : false;
					checkBox.addEventListener(MouseEvent.CLICK, checkBoxClick, false, 0 , true);
					editableComponent = checkBox;
				} else if ((comboBoxArray = checkForArray(propertyToolTip)) != null ) {
					comboBoxArray.unshift(" "); // blank option used to remove the property from the generated XML code
					var comboBox:ComboBox = _comboBoxes[i];
					comboBox.setStyle("fontSize", 9);
					comboBox.dataProvider = new ArrayCollection(comboBoxArray);
					comboBox.addEventListener(Event.CHANGE, comboBoxChange, false, 0, true);
					comboBox.editable = true;
					comboBox.selectedItem = GMXBuilder.selectedXML["@" + propertyName].toString();
					editableComponent = comboBox;
				} else {
					var textInput:TextInput = _textInputs[i];
					textInput.setStyle("fontSize", 9);
					textInput.text = GMXBuilder.selectedXML["@" + propertyName];
					textInput.addEventListener(FocusEvent.FOCUS_IN, toolBoxTextFocusIn, false, 0, true);
					textInput.addEventListener(FlexEvent.ENTER, toolBoxTextEnter, false, 0, true);
					textInput.addEventListener(FocusEvent.FOCUS_OUT, toolBoxTextEnter, false, 0, true);
					editableComponent = textInput;
				}
				
				editableComponent.width = this.width / 2 - 20;
				editableComponent.height = 21;
				editableComponent.id = propertyName;
				editableComponent.toolTip = propertyToolTip;
				label.mouseEnabled = true;
				label.selectable = true;
				label.width = this.width / 2;
				label.height = 21;
				label.text = propertyName + " : ";
				label.setStyle("fontSize", 9);
				label.setStyle("textAlign", "right");
				hBox.addChild(label);
				hBox.addChild(editableComponent);
				this.addChild(hBox);
			}
		}
		/**
		 * Used to parse up the values in an array for the tooltip and combobox (see createToolBox function)
		 * @param	string
		 * @param	arrayStartChar
		 * @param	arrayEndChar
		 * @param	delimiter
		 * @return	Array containing Strings delimited by the delimiter parameter
		 */
		private function checkForArray(string:String, arrayStartChar:String = "[", arrayEndChar:String = "]", delimiter:String="|"):Array {
			//trace("checkForArray string: " + string);
			var startIndex:int = -1;
			var endIndex:int = -1;
			for (var i:int = 0; i < string.length; i++) { 
				if (string.charAt(i) == arrayStartChar) {
					//trace("FOUND start char: " + arrayStartChar + "  it was " + string.charAt(i));
					if (startIndex != -1) { // index has been set before: Error!
						Alert.show("WARNING: GMXBuilder checkForArray failure:  Found more than one '" + arrayStartChar + "' char!");
						return null;
					}
					startIndex = i + 1;
				} else if (string.charAt(i) == arrayEndChar) {
					//trace("FOUND end char: " + arrayEndChar + "  it was " + string.charAt(i));
					if (endIndex != -1) { // index has been set before: Error!
						Alert.show("WARNING: GMXBuilder checkForArray failure:  Found more than one '" + arrayEndChar + "' char!");
						return null;
					}
					endIndex = i;
				}
			}
			if (startIndex == -1 || endIndex == -1) {
				return null;
			}
			return string.substring(startIndex, endIndex).split(delimiter);
		}
		
		private function comboBoxChange(event:Event):void { 
			var comboBox:ComboBox = event.target as ComboBox;
			if (comboBox.selectedLabel == " ") {
				delete GMXBuilder.selectedXML["@" + comboBox.id];
			} else {
				GMXBuilder.selectedXML["@" + comboBox.id] = comboBox.selectedLabel + "";
			}
			GMXBuilder.appendedXMLUpdate();
		}
		
		private function checkBoxClick(event:MouseEvent):void {
			var checkBox:CheckBox = event.target as CheckBox;
			if (event.ctrlKey || event.altKey || event.shiftKey) {
				delete GMXBuilder.selectedXML["@" + checkBox.id];
			} else {
				GMXBuilder.selectedXML["@" + checkBox.id] = checkBox.selected + "";
			}
			GMXBuilder.appendedXMLUpdate();
		}
		private var _originalText:String = "";
		private function toolBoxTextFocusIn(event:Event):void {
			var textInput:TextInput = event.currentTarget as TextInput;
			_originalText = textInput.text;
		}
		
		private function toolBoxTextEnter(event:Event):void {
			var textInput:TextInput = event.currentTarget as TextInput;
			if (textInput.text == _originalText) { return; }
			_originalText = textInput.text;
			//trace("TEXT BOX ENTER: " + textInput.id);
			if (textInput.text == "") { delete GMXBuilder.selectedXML["@" + textInput.id]; }
			else { GMXBuilder.selectedXML["@" + textInput.id] = textInput.text; }
			GMXBuilder.appendedXMLUpdate();
		}
//================= END ToolBox Functions =========================================================================
	}
}