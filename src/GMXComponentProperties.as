package
{
	import flash.utils.Timer;
	import generics.CheckBoxHierarchicalGroup_X;
	import generics.RadioButton_X;
	import generics.RadioButtonGroup_X;
	
	import generics.*;
	import generics.tables.*;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	
	
	/**
	 * ...
	 * @author 
	 */
	public class GMXComponentProperties 
	{
		// use the embedded file and not an externally loaded one.  This prevents the race condition and
		// also makes it easier to distribute ... 
		[Embed(source="./ClassDefinitions.xml",mimeType="application/octet-stream")]
		public static var ClassDefinitionsFile:Class;
		public static var classDefinitionXML:XML;
		
		public static function componentIsContainer(componentLabel:String):Boolean {
			// in the ClassDefinitions.xml file, each class should have a "container" attribute that has a value of either true or false: 
			// e.g. a non-container Class: <Button_ISIS package="fcs.components.fcs.button" label="Button" container="false" group="Input"> ...
			// e.g. a container Class: <ToggleButtonGroup_ISIS package="fcs.components.fcs.buttongroup" label="ToggleButtonGroup" container="true" group="Input"> ...
			//   this is used by the ComponentToolBox (which contains buttons that add new instances of these components) to enable the buttons or
			//   disable the buttons depending on whether a Container is selected or not.  Components cannot be added as children to container="false"
			//   components.
			var xml:XML = componentLabelToXMLLookup[componentLabel];
			if (xml == null || xml.@container == undefined) { return false; }
			if (xml.@container.toString() == "true") { return true; }
			else return false;
		}
		// componentLabelToXMLLookup, classNameToXMLLookup, & componentLabelToClassLookup are dictionaries that enable the easy accessing
		// of the XML for each component found within ClassDefinitions.xml.  For example
		//	componentLabelToXMLLookup["Label"] or classNameToXMLLookup["Label_ISIS"] would both yield 
		// <Label_ISIS package="fcs.components.fcs.display" label="Label" container="false" group="Display">
		//     ... (All XML here that is inside the Label_ISIS XML in ClassDefinitions.xml) ...
		// </Label_ISIS>
		private static var componentLabelToXMLLookup:Dictionary = new Dictionary();
		private static var classNameToXMLLookup:Dictionary = new Dictionary();
		public static function hasComponent(componentLabel:String):Boolean { return componentLabelToXMLLookup[componentLabel] != null; }
		public static function getComponentPropertiesFromClassName(componentClassName:String):XML { return classNameToXMLLookup[componentClassName] as XML; }
		
		// Classifications are based on the "group" attribute for the components in the ClassDefinitions.xml
		//
		// componentClassifications contain the keys (classifications) that are in the componentClassificationLookup
		// while componentClassificationLookup contains Arrays of component labels that fit into each classification
		// -->for example, componentClassifications might contain ["Input", "Display", "Layout"].  This array is built in the order
		//     that these "groups" are encountered within the ClassDefinitions.xml file (see buildDictionariesFromComponentXML function)
		//    (e.g. <Button_ISIS package="fcs.components.fcs.button" label="Button" container="false" group="Input"> is in the "Input" classification)
		// In the componentClassificationLookup, the key "Input" would yield something like ["Button", "TextInput", TextArea", "CheckBox", ...]--i.e. whatever
		//    components are assigned to that group in the ClassDefinitions.xml file.
		public static var componentClassifications:ArrayCollection = new ArrayCollection();
		private static var componentClassificationLookup:Dictionary = new Dictionary();
		public static function getComponentsFromClassification(classification:String):Vector.<String> {
			//trace("getComponentsFromClassification @ classification=" + classification + ": " + componentClassificationLookup[classification]);
			return componentClassificationLookup[classification];
		}
		
		// componentLabelToClassLookup takes uses the "label" attribute within the ClassDefinitions.xml's component nodes to
		// look up the class name of that component
		// e.g. <Label_ISIS package="fcs.components.fcs.display" label="Label" container="false" group="Display"> has the
		//    attribute label="Label".  Therefore, componentLabelToClassLookup["Label"] would return "Label_ISIS"
		private static var componentLabelToClassLookup:Dictionary = new Dictionary();
		public static function getClassFromComponentLabel(componentLabel:String):Class { return componentLabelToClassLookup[componentLabel] as Class; }
		
		
		private static function buildDictionariesFromComponentXML(xmlFromFile:XML):void {
			classDefinitionXML = xmlFromFile;
			var i:int;
			var xmlChildren:XMLList = classDefinitionXML.children();
			var numXMLChildren:int = xmlChildren.length();
			for (i = 0; i < numXMLChildren; i++) {
				classNameToXMLLookup[xmlChildren[i].localName()] = xmlChildren[i];
				if (xmlChildren[i].@label == undefined) {
					Alert.show("ERROR: GMXComponentProperties xml from file had a child without the required 'label' attribute!  the xml was: " + xmlChildren[i].toString());
				} else {
					var labelString:String = xmlChildren[i].@label.toString();
					try {
						componentLabelToClassLookup[labelString] = getDefinitionByName(xmlChildren[i]["@package"].toString() + "." + xmlChildren[i].localName()) as Class;
					} catch (e:Error) {
						Alert.show("The Class named '" + xmlChildren[i].localName() + "' (from ClassDefinitions.xml) was not found.  Either it does not" +
									" exist in the package '" + xmlChildren[i]["@package"].toString() + "', or you have not added that class to the" +
									" GMXComponentProperties 'MAKE_SURE_ALL_CLASSES_ARE_COMPILED' function!");
					}
					componentLabelToXMLLookup[labelString] = xmlChildren[i];
					componentList.push(labelString);
					
					// add to componentClassifications so the ComponentToolBox can create buttons in the right groups
					var group:String = xmlChildren[i].@group.toString();
					if (group == "") { group = "Display"; } // default value
					if (!componentClassifications.contains(group)) { 
						componentClassifications.addItem(group);
					}
					if (componentClassificationLookup[group] == null) { componentClassificationLookup[group] = new Vector.<String>(); }
					componentClassificationLookup[group].push(labelString);
				}
			}
		}
		
		public static function buildDictionariesFromFile(fileName:String = "ClassDefinitions.xml"):void {
			var fileString:String = new ClassDefinitionsFile();
			if (fileString == "" || fileString == null) {
				Alert.show("ERROR: GMX WILL NOT WORK because nothing came from the embedded ClassDefinitions.xml file!");
				return;
			}
			try {
				var xmlFromFile:XML = new XML(fileString);
			} catch (e:Error) {
				var errorMessage:String = "ERROR: GMX WILL NOT WORK because of a GMXComponentProperties ClassDefinitions.xml parse error: " + e.message;
				errorMessage += "\nIf the above error message doesn't help, open the ClassDefinitions.xml file with a web browser.";
				Alert.show(errorMessage);
				return;
			}
			buildDictionariesFromComponentXML(xmlFromFile);
		}
		
		public static const standardComponentPropertyVector:Array = [
			new XML(<luid>String</luid>),
			new XML(<layout>String</layout>),
			new XML(<height>Number</height>),
			new XML(<width>Number</width>),
			new XML(<x>Number Does not work in HBoxes and VBoxes</x>),
			new XML(<y>Number Does not work in HBoxes and VBoxes</y>),
			new XML(<alpha>Number b/w 0.0 and 1.0</alpha>),
			new XML(<visible>Boolean</visible>),
			new XML(<flexible>Boolean</flexible>),
			new XML(<enabled>Boolean</enabled>),
			new XML(<toolTip>String</toolTip>),
			new XML(<preserve>Boolean</preserve>),
			new XML(<static>Boolean</static>),
			new XML(<percentWidth>Number</percentWidth>),
			new XML(<percentHeight>Number</percentHeight>)
		];
		
		public static const standardContainerPropertyVector:Array = [
			new XML(<padding>Number applies to paddingLeft, Right, Top, & Bottom (you can still set them individually)</padding>),
			new XML(<paddingLeft>Number</paddingLeft>),
			new XML(<paddingRight>Number</paddingRight>),
			new XML(<paddingTop>Number</paddingTop>),
			new XML(<paddingBottom>Number</paddingBottom>),
			new XML(<borderColor>String ... in hexadecimal format (e.g. 'ff0000' for red)</borderColor>),
			new XML(<borderSides>String default='top left right bottom' ... any combination of 'top' 'left' 'bottom' 'right' in any order (e.g. 'top bottom' for just top & bottom)</borderSides>),
			new XML(<borderStyle>String default='inset' ... [none|solid|inset|outset]</borderStyle>),
			new XML(<borderThickness>Number default='1'</borderThickness>),
			new XML(<horizontalScrollPolicy>String [on|off|auto]</horizontalScrollPolicy>),
			new XML(<verticalScrollPolicy>String [on|off|auto]</verticalScrollPolicy>)
		];
		
		public static function getSampleXMLFromComponentLabel(componentId:String):XML {
			// this function is used to add default properties to components that require some default values in order to be
			// more accessible / minimally functional (e.g. an HBox w/o any properties is invisible in GMX and cannot be selected--to make it visible,
			// we set a default width, height, and backgroundColor.  Also, a combobox is not functional without a cuid).
			var componentXML:XML = componentLabelToXMLLookup[componentId];
			if (componentXML == null) { Alert.show("ERROR: GMXComponentProperties: componentID=" + componentId +
													" is not a valid label!  Check the ClassDefinitions.xml file and make" +
													" sure a corresponding component Class exists in the GMXComponentProperties.MAKE_SURE_ALL_CLASSES_ARE_COMPILED function!");
				return new XML(<null/>);
			}
			var xmlChildren:XMLList = componentXML.children();
			var numXMLChildren:int = xmlChildren.length();
			for (var i:int = 0; i < numXMLChildren; i++) {
				if (xmlChildren[i].localName().toLowerCase() == "samplexml") {
					xmlChildren = xmlChildren[i].children();
					if (xmlChildren.length() > 1) {
						Alert.show("WARNING: GMXComponentProperties: componentID=" + componentId +
							" has SampleXML with more than 1 child node!  Check the ClassDefinitions.xml file and make" +
							" sure a SampleXML with EXACTLY 1 node exists for the component with label=" + componentId);
						return new XML(<null/>);
					} else if (xmlChildren.length() == 0) {
						Alert.show("ERROR: GMXComponentProperties: componentID=" + componentId +
							" has SampleXML with more no child node!  Check the ClassDefinitions.xml file and make" +
							" sure a SampleXML with EXACTLY 1 node exists for the component with label=" + componentId);
						return new XML(<null/>);
					}
					return xmlChildren[0].copy();
				}
			}
			// if there is no "SampleXML" XML node for that class in the ClassDefinitions.xml file, just make a new XML node with the Label as the localName
			return new XML("<" + componentXML.@label.toString() + "/>");
		}
		
		public static var componentList:Array = new Array();
		
		public static function MAKE_SURE_ALL_CLASSES_ARE_COMPILED():void {
			// make sure it never actually instantiates all these classes, but when it compiles it includes all these classes
			if (1 == 2) { 
				new FileBrowser();
				new List_X();
				new DataGrid_ISIS();
				new RadioButton_X();
				new RadioButtonGroup_X();
				
				//=============== GENERIC COMPONENTS ========================================
				new Button_X();
				new CheckBox_X();
				new Calendar_X();
				new ColorPicker_X();
				new ComboBox_X();
				new ComboBoxSingleField_X();
				new Compass_X();
				new Dial_X();
				new HBox_X();
				new Icon_X();
				new InfoTag_X();
				new Joystick_X();
				new Label_X();
				new LabelEnum_X();
				new MaxStatus_X();
				new MenuButton_X();
				new ResizingBox_X();
				new ResizingBoxContainer_X();
				new ShapeShifter();
				new SliderDisplay_X();
				new SpinBox_X();	
				new TextArea_X();
				new TextInput_X();
				new TextAreaCumulative_X();
				new TurnRateIndicator_X();
				new VBox_X();
				new MaxStatus_X();
				new VoltageIndicator_X();
				new CustomGrid();
				new Calendar_X();
				new RateInstrument_X();
				new VoltageIndicator_X();		
				new Volume_X();
				new ShapeShifter();
				new CustomGrid();
				new Spacer_X();
				new Video_X();
				new VRule_X();
				new HRule_X();
				new ToggleButton_X();
				new ToggleButtonGroup_X();
				new SendButton_X();
				new PushButton_X();
				new ImageViewer_X();
				new CheckBoxHierarchicalGroup_X();
			}
		}
	}
}