package gmx_builder 
{
	import interfaces.ISelfBuilding;
	import flash.display.Loader;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import services.SocketController;
	/**
	 * ...
	 * @author 
	 */
	public class ComponentToolBox extends VBox
	{
		public static var collectionSender:CollectionSender = new CollectionSender();
		public static var recordSender:RecordSender = new RecordSender();
		public static var fieldEditorForMultiField:FieldEditorForMultiField = new FieldEditorForMultiField();
		public static var fileLoaderTextInput:TextInput;
		public static var fileLoader:URLLoader = new URLLoader();
		
		private static var NUM_ALWAYS_ENABLED_CHILDREN:int = 9;
		
		public function ComponentToolBox() 
		{
			super();
			fileLoader.addEventListener(Event.COMPLETE, completeHandler);
			fileLoader.addEventListener(IOErrorEvent.IO_ERROR, ioError);
			this.setStyle("verticalGap", 0);
			this.setStyle("paddingLeft", 0);
			this.setStyle("paddingRight", 0);
			this.setStyle("paddingTop", 0);
			this.setStyle("paddingBottom", 0);
			buildToolBoxFromClassDefinitions();
		}
		
		public function buildToolBoxFromClassDefinitions():void {
			var button:Button;
			
			button = new Button();
			button.label = "==HELP(F1)==";
			button.setStyle("color", 0x990000);
			button.addEventListener(MouseEvent.CLICK, helpButton, false, 0, true);
			this.addChild(button);
			
			button = new Button();
			button.label = "...'SEND' Record...";
			button.setStyle("color", 0x000099);
			button.addEventListener(MouseEvent.CLICK, sendRecord, false, 0, true);
			this.addChild(button);
			
			button = new Button();
			button.label = "...'SEND' Collection...";
			button.setStyle("color", 0x000099);
			button.addEventListener(MouseEvent.CLICK, sendCollection, false, 0, true);
			this.addChild(button);
			
			var labelDivider:Label;
			labelDivider = new Label();
			labelDivider.text = "send file of";
			this.addChild(labelDivider);
			
			labelDivider = new Label();
			labelDivider.text = "delimited XML msg's";
			this.addChild(labelDivider);
			
			
			labelDivider = new Label();
			labelDivider.text = "  delimiter = \"%%\" :  ";
			this.addChild(labelDivider);
			
			fileLoaderTextInput = new TextInput();
			fileLoaderTextInput.toolTip = 'Sample File:\n<invoke fn="ISISRecord">\n\t...\n</invoke>\n%%\n<invoke fn="ISISCollection">\n\t...\n</invoke>\n\n\nType in file name and\nPress ENTER to "send" it.'
			this.addChild(fileLoaderTextInput);
			fileLoaderTextInput.addEventListener(FlexEvent.ENTER, sendFile);
			
			labelDivider = new Label();
			labelDivider.text = "=== Multi-Field ===";
			labelDivider.setStyle("fontWeight", "bold");
			this.addChild(labelDivider);
			
			button = new Button();
			button.label = button.id = "EDIT FIELDS";
			button.setStyle("color", 0x000099);
			button.addEventListener(MouseEvent.CLICK, addField, false, 0, true);
			this.addChild(button);
			
			for (var j:int = 0; j < GMXComponentProperties.componentClassifications.length; j++) {
				var componentList:Vector.<String> = GMXComponentProperties.getComponentsFromClassification(GMXComponentProperties.componentClassifications[j]);
				labelDivider = new Label();
				labelDivider.text = "=== " + GMXComponentProperties.componentClassifications[j] + " ===";
				labelDivider.setStyle("fontWeight", "bold");
				this.addChild(labelDivider);
				for (var i:int = 0; i < componentList.length; i++) {
					button = new Button();
					button.label = button.id = componentList[i];
					button.setStyle("disabledColor", 0x888888);
					//var componentXML:XML = new XML("<" + button.id + "></" + button.id + ">");
					//GMXComponentProperties.addDefaultXMLNodes(componentXML, button.id);
					//button.toolTip = componentXML.toString();
					button.height = 20;
					this.addChild(button);
					button.addEventListener(MouseEvent.CLICK, addButtonClicked);
				}
			}
		}
		
		private function addButtonClicked(event:MouseEvent):void {
			var targetButton:Button = event.currentTarget as Button;
			
			GMXBuilder.formerXML = GMXBuilder.currentXML.copy();
			var newXML:XML = GMXComponentProperties.getSampleXMLFromComponentLabel(targetButton.id);	
			if (GMXBuilder.selectedObject == null) {
				GMXBuilder.currentXML.appendChild(newXML);
			} else {
				GMXBuilder.selectedXML.appendChild(newXML);
			}
			GMXBuilder.appendedXMLUpdate();
		}
		
		public function getButton(buttonId:String):Button {
			for (var i:int = 0; i < numChildren; i++) {
				var button:Button = this.getChildAt(i) as Button;
				if (button == null) { continue; }
				if (button.id == buttonId) { return button; }
			}
			return null;
		}
		public function disabledAllButtons():void {
			for (var i:int = NUM_ALWAYS_ENABLED_CHILDREN; i < numChildren; i++) {
				var button:Button = this.getChildAt(i) as Button;
				if (button == null) { continue; }
				button.enabled = false;
			}
		}
		
		public function enableButtonsBasedOnSelectedObjectType(object:ISelfBuilding):void {
			//trace(" enableButtonsBasedOnSelectedObjectType");
			// THIS IS CURRENTLY NOT USED -- enableButtonBasedOnSelectedXML IS USED INSTEAD
			// first return to default state
			for (var i:int = 0; i < numChildren; i++) {
				var button:Button = this.getChildAt(i) as Button;
				if (button == null) { continue; }
				switch(button.id) {
					//case "RadioButton": button.enabled = false; break;
					default: button.enabled = true;
				}
			}
			// then enable buttons based on what is selected
			//if (object is RadioButtonGroup_X) { disabledAllButtons();  getButton("RadioButton").enabled = true; }			
		}
		
		public function enableButtonBasedOnSelectedXML(selectedXML:XML):void {
			if (selectedXML == null) {
				enableButtonsBasedOnSelectedObjectType(null);
				return;
			}
			var isContainer:Boolean = GMXComponentProperties.componentIsContainer(selectedXML.localName());
			for (var i:int = NUM_ALWAYS_ENABLED_CHILDREN; i < numChildren; i++) {
				var button:Button = this.getChildAt(i) as Button;
				if (button == null) { continue; }
				switch(button.id) {
					//case "RadioButton": button.enabled = false; break;
					default: button.enabled = isContainer;
				}
			}
		}
		
		override public function set width(val:Number):void {
			for (var i:int = 0; i < this.numChildren; i++) {
				this.getChildAt(i).width = val - 20;
			}
			super.width = val;
		}
		
		private function helpButton(event:MouseEvent):void {
			GMXBuilder.showHelp();
		}
		
		private function sendRecord(event:MouseEvent):void {
			GMXMain.PopUps.addChild(recordSender);
			recordSender.resetDataProviders();
			recordSender.x = (GMXMain.instance.width - recordSender.width) / 2;
			recordSender.y = (GMXMain.instance.height - recordSender.height) / 2;
			recordSender.invalidateDisplayList();
		}
		
		private function sendCollection(event:MouseEvent):void {
			GMXMain.PopUps.addChild(collectionSender);
			collectionSender.resetDataProviders();
			collectionSender.x = (GMXMain.instance.width - collectionSender.width) / 2;
			collectionSender.y = (GMXMain.instance.height - collectionSender.height) / 2;
			collectionSender.invalidateDisplayList();
		}
		
		private function addField(event:MouseEvent):void {
			if (fieldEditorForMultiField.parent == null) { 
				GMXMain.PopUps.addChild(fieldEditorForMultiField); 
				fieldEditorForMultiField.updateDataProvider(GMXBuilder.selectedXML); 
			} else { fieldEditorForMultiField.parent.removeChild(fieldEditorForMultiField); }
		}
		
		private function sendFile(event:FlexEvent):void {
			try {
				var url:URLRequest = new URLRequest("./" + fileLoaderTextInput.text);
				fileLoader.load(url);
			} catch (e:Error) {
				Alert.show("File load error: " + e.message);
			}			
		}
		
		private function completeHandler(event:Event):void {
			//trace("LOAD COMPLETE: file=" + fileLoader.data);
			var messageStrings:Array = fileLoader.data.toString().split("%%");
			for (var i:int = 0; i < messageStrings.length; i++) {
				var dataEvent:DataEvent = new DataEvent(DataEvent.DATA, false, false, messageStrings[i]);
				SocketController.dispatcher.dispatchEvent(dataEvent);
			}
		}
		private const _swfpat:RegExp = new RegExp("(file:.+/)\\w+\\.swf", "ix");
		private function ioError(event:IOErrorEvent):void {
			var app:Application = mx.core.Application.application as Application;
			var url:String = unescape(app.url);
			var match:Array = _swfpat.exec(url);
			var root_url:String = match[1] as String;
			Alert.show("File load error... most likely because the file specified is not in the same directory as this .swf!  You attempted to load a file at './" + fileLoaderTextInput.text + "'."
					+  "  Note that your classpath is: " + root_url);
		}
	}
}