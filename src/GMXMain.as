package 
{
	import com.adobe.crypto.MD5;
	import generics.VBox_X;
	import GMXComponentProperties;
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.RadioButton;
	import mx.controls.TextArea;
	import mx.controls.listClasses.ListBase;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.managers.SystemManager;
	import mx.skins.Border;
	import mx.skins.halo.ButtonSkin;
	import mx.skins.halo.CheckBoxIcon;
	import mx.skins.halo.ComboBoxArrowSkin;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import GMX.Data.AttributeVO;
	import GMX.Data.CollectionVO;
	import GMX.Data.FieldVO;
	import GMX.Data.RecordVO;
	import gmx_builder.GMXBuilder;
	import mx.core.Application;
	import mx.events.ResizeEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	import mx.controls.Alert;
	
	import interfaces.ISelfBuilding;
	
	import records.Attributes;
	import records.Collection;
	import records.Field;
	import records.RecordDump;
	import records.Record;
	import constants.Size;			
	
	import services.ControlChannel;
	
	/**
	 * ...
	 * @author 
	 */
	public class GMXMain extends Canvas {
		public function GMXMain() {
			super();
			instance = this;
			this.setStyle("paddingLeft", 0);
			this.setStyle("paddingRight", 0);
			this.setStyle("paddingTop", 0);
			this.setStyle("paddingBottom", 0);
			//this.percentHeight = 100;
			//this.percentWidth = 100
			this.verticalScrollPolicy = "auto";
			this.horizontalScrollPolicy = "auto";
		}
		
		override public function set width(val:Number):void {
			if (application == null) { super.width = val; return; }
			
			super.width = val / application.scaleX;
		}
		override public function set height(val:Number):void {
			if (application == null) { super.height = val; return; }
			
			super.height = val / application.scaleY;
		}
		private var _controlChannel:ControlChannel;
		public function connectControlChannel():void {
			_controlChannel.connect();
		}
		
		public static const DEFAULT_CONTROL_CHANNEL_PORT:uint = 12141;
		public static const DEFAULT_CONTROL_CHANNEL_HOST:String = "localhost";
		public static var application:Application;
		// debugging flags
		public static var testing:Boolean = true;
		public static var debugSend:Boolean = false;
		public static var debugReceive:Boolean = false;
		public static var debugLayoutMessagesUsingGMXBuilder:Boolean = true;
		
		public static var instance:GMXMain;
		public static var stage:Stage;
		public static var PopUps:PopUpManager_ISIS = new PopUpManager_ISIS();
		public static var builderHighlightPopUp:UIComponent = new UIComponent();
		public static var timer:Timer = new Timer(100);
		
		public static var staticComponents:ArrayCollection = new ArrayCollection();
		
		public static function set SCALE(val:Number):void { Main.SCALE = val; }
		public static function get SCALE():Number { return Main.SCALE; }
		
		override protected function createChildren():void {
			super.createChildren();
			_controlChannel = new ControlChannel()
			GMXComponentProperties.MAKE_SURE_ALL_CLASSES_ARE_COMPILED();
			GMXComponentProperties.buildDictionariesFromFile();
			application = this.parent as Application;
			//application.addEventListener(ResizeEvent.RESIZE, resize);
			
			//var testXML:XML = new XML(<hi><hi1><haha1></haha1></hi1><hi2><haha2></haha2></hi2><hi3><haha3></haha3></hi3></hi>);
			//var testList:XMLList = testXML.children();
			//trace(testList[2].localName());
			
			GMXMain.stage = this.stage;
			GMXMain.timer.start();
			// create default Record
			var mainLuid:VBox_X = new VBox_X();
			this.addChild(mainLuid);
			mainLuid.id = "mainLuid"
			mainLuid.setStyle("paddingLeft", 0);
			mainLuid.setStyle("paddingRight", 0);
			mainLuid.setStyle("paddingTop", 0);
			mainLuid.setStyle("paddingBottom", 0);
			mainLuid.setStyle("verticalGap", 0);
			mainLuid.record = new Record("mainRuid");
			GMXDictionaries.addLuid(mainLuid.id, mainLuid);
			//GMXDictionaries.addLuidXML(mainLuid.id, currentCompleteLayoutXML.children()[0]);
			
			this.addEventListener("updateComplete", updateComplete);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			
			
			
			ServiceInterface.getInstance(this.stage);
			//== BEGIN GENERATED CODE ================
			// MESSAGES FROM THE SERVICE
			ServiceInterface.addCallback("ISISLayout", ISISLayout); 
			ServiceInterface.addCallback("ISISRecord", ISISRecord); 
			ServiceInterface.addCallback("ISISCollection", ISISCollection);
			ServiceInterface.addCallback("ISISAttributes", ISISAttributes);
			
			ServiceInterface.addCallback("registerEventMapComplete", registerEventMapComplete);                                                         
			ServiceInterface.registerEventMap("GMX_Connector_EventMap");
			//== END GENERATED CODE ================
			
			//if (!debugLayoutMessagesUsingGMXBuilder) {
			_controlChannel.setHostAndPortFromFlashVars();
				_controlChannel.connect();
			//}
			//var testStatus:ActionStateIndicator = new ActionStateIndicator();
			//testStatus.phase = Attributes.ACTION_STATE_WAITING;
			//PopUps.addChild(testStatus);
			PopUps.addChild(builderHighlightPopUp);
			builderHighlightPopUp.mouseEnabled = false;
			builderHighlightPopUp.mouseChildren = false;
			
			new GMXBuilder(); // create the single instance of gmxBuilder
			if (testing && debugLayoutMessagesUsingGMXBuilder) {
			//	mainLuid.addChild(GMXBuilder.gmxBuilderInstance);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		private function updateComplete(event:Event):void {
			if (!ControlChannel.polling || !ControlChannel.layoutDirty) { return; }
			
			ControlChannel.numUpdates++;
			if (ControlChannel.block) {
				ControlChannel.stopTime = getTimer();
				if (ControlChannel.throughputSize != 0) {
					ControlChannel.avgRoundTripTime = (ControlChannel.avgRoundTripTime * (ControlChannel.throughputSize - 1)
											 + ControlChannel.stopTime-ControlChannel.startTime) / ControlChannel.throughputSize;
				}
				if (ControlChannel.numUpdates != 0) {
					ControlChannel.avgUpdateTime = (ControlChannel.avgUpdateTime * (ControlChannel.numUpdates - 1)
													 + ControlChannel.stopTime-ControlChannel.startTime) / ControlChannel.numUpdates;
				}
				ControlChannel.block = false;
			}
			ControlChannel.layoutDirty = false;
		}
		
		
			
		/**
		 * Actions are processed following the entry of a magic word "gmeisfun"
		 * Once the magic word has been entered the next few characters are interpreted as a command.
		 * Intervening new line characters restart the action processing.
		 * Most commands cause the state to revert to normal mode. (help does not)
		 * 
		 */
		private var _action_string:String = "";
		private const _activation_string:String = "gmeisfun";
		private var _activation_level:uint = 0;
		private function _reset_action_status():void {
			_activation_level = 0;
			_action_string = "";
		}
		
		private static var editMode:Boolean = false;
		private function keyDown(event:KeyboardEvent):void {
			var character:String = String.fromCharCode(event.charCode);
			
			if (event.ctrlKey && event.shiftKey) {
				if (character.toLowerCase() == "e") { switchToEditMode(); return; }
				else if (character.toLowerCase() == "s") {
					GMXBuilder.saveMode = !GMXBuilder.saveMode
					var alertMessage:String = GMXBuilder.saveMode   ? "CAUTION: you ARE in SAVE mode. If you are connected to " +
																	  "the Layout Manager and edit a layout in EDIT mode, the " +
																	  "changes you make will be saved into the actual layout files. " +
																	  "It is HIGHLY recommended that you backup your layout files " +
																	  "before proceeding to edit any layouts!"
																	: "You ARE NOT in SAVE mode now.  Changes you make to the layouts " +
																	  "in edit mode will not affect any layout files.";
					Alert.show(alertMessage);
				}
			}
			
			
			if (event.ctrlKey) {
				switch(character) {
					case "-":
						if (GMXMain.SCALE > .15) { GMXMain.SCALE -= .1; }
						break;
					case "+":
						GMXMain.SCALE += 0.1;
						break;
					case "=":
						GMXMain.SCALE = 1;
						break;
				}
				return;
			}
			if (character == "\r" || character == "\n") {
				if (_action_string.length < 1) _activation_level = 0;
				_action_string = "";
				return;
			}
			if (_activation_level < _activation_string.length) {
				if (_activation_string.charAt(_activation_level) != character) {
					 _reset_action_status();
					 return;
				}
				++_activation_level;
					
				return;
			}
				
			_action_string += character.toLocaleLowerCase();
			if (_action_string.length > 20) {
				_reset_action_status();
				return;
			}
			
			switch (_action_string) {
			case "map":
				//Alert.show(CmdChannel.lastMapMessage);
				break;
			case "log":
				// saves all messages out into a log file
				// note that i
				GMXDictionaries.saveMessagesToFile();
				break;
			case "edit":
				switchToEditMode();
				_reset_action_status();
				break;
			case "recdump":
				var dump:String = "===== RECORD DUMP: =====\n";
				for each (var obj:Object in GMXDictionaries.ruidDict) {
					if (!(obj is Record)) continue;
					// TableRecords are dumped in the CollectionRecord dump
					// if (obj is TableRecord) continue;
					var record:Record = obj as Record;
					dump += record.recordDump();
				}
				var dumpPopup:RecordDump = PopUpManager.createPopUp(this, RecordDump, true) as RecordDump;
				PopUpManager.centerPopUp(dumpPopup);
				dumpPopup.setText(dump);
				_reset_action_status();
				break;
			case "ctrl": 
				_controlChannel.connect();
				_reset_action_status();
				break;
			case "trueres":
				GMXMain.SCALE = (Capabilities.screenResolutionX / 1440.0 + Capabilities.screenResolutionY / 900.0);
				_reset_action_status();
				break;
			case "truesize":
				GMXMain.SCALE = (Capabilities.screenResolutionX / 1440.0 + Capabilities.screenResolutionY / 900.0);
				_reset_action_status();
				break;
			case "h":
				var usage:String = "=== USAGE ===\n"
						+ "     help : this screen.\n"
						+ "  recdump : show all records stored in GMX.\n"
						+ "     ctrl : start socket connection dialog.\n"
						+ "  trueres : set the screen resolution to show proper number of pixels.\n"
						+ " truesize : set the screen resolution to show actual size.\n"
						+ "      log : export";
						
				var usagePopup:RecordDump = PopUpManager.createPopUp(this, RecordDump, true) as RecordDump;
				PopUpManager.centerPopUp(usagePopup);
				usagePopup.setText(usage);			
			}
		}
		
		public function switchToEditMode():void {
			//toggle
			editMode = !editMode;
			
			if (editMode) { // turned on editMode
				GMXBuilder.enterEditMode();
			} else { // turned off editMode
				if (GMXBuilder.exitEditMode() == false) {
					editMode = true;
				} else {
					this.setFocus();
				}
			}
		}
		
		public static function splitter(msg:String, delimit:String = null):Vector.<String>
		{
			if (msg.length < 1) return new Vector.<String>;
			if (delimit != null) return Vector.<String>(msg.split(delimit));
			
			var delimiter:String = msg.charAt(0);
			switch (delimiter) {
				case "|": break;
				case " ": break;
				case ",": break;
				case ":": break;
				case "=": break;
				case " ": break;
				case "^": break;
				default:
				   trace("presuming "+delimiter+" is the delimiter");
			} 
			return Vector.<String>(msg.substr(1).split(delimiter));
		}
		
		//== BEGIN GENERATED FUNCTIONS ===============
		import services.ServiceInterface;
		
		public function registerEventMapComplete():void
		{
			
		}
		//=== MESSAGE FROM SERVICE =========================
		
// ============= NEW MESSAGES =====================
		//
		public function ISISRecord(a_RecordList:Array /*RecordVO*/):void
		{
			for (var i:int = 0; i < a_RecordList.length; i++) {
				var recordVO:RecordVO = a_RecordList[i] as RecordVO;
				var record:Record = GMXDictionaries.getRuid(recordVO.ruid);
				if (record == null) {
					record = new Record(recordVO.ruid);
					GMXDictionaries.addRuid(recordVO.ruid, record);
				}
				
				if (recordVO.layout == null || record.layout == "") {
					// don't change anything
				} else if (recordVO.layout.substring(0,5) == "|null") {
					record.layout = null;
				} else { 
					record.layout = recordVO.layout;
				}
				// NEED TO FIGURE OUT WHETHER THE LAYOUT CHANGES!
				record.processFieldList(recordVO.fieldList);
			}
		}
		
		//
		public function ISISCollection(a_CollectionList:Array /*CollectionVO*/):void
		{
			//trace("ISISCOLLECTION: " + a_CollectionList);
			for (var i:int = 0; i < a_CollectionList.length; i++) {
				var collectionVO:CollectionVO = a_CollectionList[i] as CollectionVO;
				var collection:Collection = GMXDictionaries.getCuid(collectionVO.cuid);
				if (collection == null) {
					collection = new Collection(collectionVO.cuid);
					GMXDictionaries.addCuid(collectionVO.cuid, collection);
				}
				collection.processRuidList(collectionVO.ruidList);
			}
		}
		
		//
		public function ISISAttributes(a_AttributeList:Array /*AttributeVO*/):void
		{
			//trace("ISISAttributes called: " + a_AttributeList);
			for (var i:int = 0; i < a_AttributeList.length; i++) {
				var attributeVO:AttributeVO = a_AttributeList[i] as AttributeVO;
				if (attributeVO.ruid == "null" || attributeVO.ruid == "") {
					Alert.show("WARNING: Incoming ISISAttributes message had an empty ruid!");
					continue;
				}
				if (attributeVO.fid == "null" || attributeVO.fid == "") {
					Alert.show("WARNING: Incoming ISISAttributes message had an empty fid!");
					continue;
				}
				var record:Record = GMXDictionaries.getRuid(attributeVO.ruid);
				if (record == null) {
					record = new Record(attributeVO.ruid);
					GMXDictionaries.addRuid(attributeVO.ruid, record);
				}
				var field:Field = record.getField(attributeVO.fid);
				if (field == null) {
					GMXDictionaries.pushCurrentRecord(record);
					field = new Field(attributeVO.fid);
					GMXDictionaries.popCurrentRecord();
				}
				var attributes:Attributes = field.attributes;
				attributes.processAttributeVO(attributeVO);
			}
		}
		
		public static var currentCompleteLayoutXML:XML = new XML(<topNode><VBox luid="mainLuid" ruid="mainRuid"/></topNode>);
		
		private function replaceCurrentXMLNode(luid:String, newXMLNode:XML):void {
			var luidNode:XML = findLuidNodeInCurrentLayoutXML(currentCompleteLayoutXML, luid);
			if (luidNode == null) { trace("EXPECTED TO FIND THE LUID " + luid + " somewhere, but didn't!"); return; }
			//trace("old luid node: " + luidNode.toString());
			delete luidNode.*;
			delete luidNode.@ * ;
			var newXMLAttributes:XMLList = newXMLNode.attributes();
			for (var i:int = 0; i < newXMLAttributes.length(); i++) {
				luidNode["@" + newXMLAttributes[i].localName()] = newXMLAttributes[i].toString();
			}
			
			//NEED TO ADD ATTRIBUTES OVER, SET LOCALNAME, and SET CHILDREN!
			luidNode.setLocalName(newXMLNode.localName());
			var newChildren:XMLList = newXMLNode.children();
			luidNode.setChildren(newChildren);
			//trace("new luid node: " + luidNode.toString());
			//trace("new currentCompleteLayoutXML: " + currentCompleteLayoutXML.toString());
		}
		
		private function findLuidNodeInCurrentLayoutXML(currentNode:XML, luid:String):XML {
			var node:XML = null;
			var children:XMLList = currentNode.children();
			var numXMLChildren:int = children.length();
			for (var i:int = 0; i < numXMLChildren; i++) {
				if (children[i].@luid != undefined && children[i].@luid.toString() == luid) {
					//trace("FOUND SAME LUID: " + luid);
					return children[i];
				}
				// now check that node's children for the luid
				if ((node = findLuidNodeInCurrentLayoutXML(children[i], luid)) != null) {
					// found on one of the children
					return node;
				}
			}
			return null;
		}
		//
		public static function ISISLayout(a_Layout:String):void
		{
			try {
				var xml:XML = new XML(a_Layout);
			} catch(e:Error) {
				Alert.show("WARNING: Layout XML Message had an error: " + e.message);
				return;
			}
			if (xml.localName() != null) {
				//if (xml.localName().toString().toLowerCase()=="command") { Alert.show(xml.localName().toString().toLowerCase()); }
				switch(xml.localName().toString().toLowerCase()) {
					// if the top level node of the xml is <Command>, forward whatever is inside of it to everybody.
					case "command":
						trace("Forwarding message to Control channel: " + xml);
						// NEED TO HAVE THE MODELED ARGUMENT!
						if (GMXMain.instance._controlChannel.processCommand(xml.toString()) == false) {// checks if there is XML in the command... there shouldn't be any
							var recordVO:RecordVO = new RecordVO();
							recordVO.layout = xml.toString();
							do_ISISDataEdit([recordVO]);
						}
						return;
				}
			}
			
			var luid:String = xml.@luid.toString();
			var luidComponent:ISelfBuilding = GMXDictionaries.getLuid(luid);
			if (luidComponent == null) {
				Alert.show("WARNING: Attempted to add a layout to a non-existant luid='"+luid +"'... Note that if you want the top-level layout," + 
						" the luid is 'mainLuid' and the default ruid is 'mainRuid'... Layout message is: " + xml);
				return;
			}
			var luidComponentParent:UIComponent = luidComponent.parent as UIComponent;
			if (luidComponentParent == null) {
				Alert.show("ERROR: component at luid='"+ luid +"' does not have a parent!  This should be impossible!  Layout cannot be processed!")
				return;
			}
			var layoutState:ExtraLayoutStateRetainer = GMXDictionaries.getCurrentLayoutStateForComponent(luidComponent);
			if (layoutState == null) {
				trace("ERROR: NO LAYOUT STATE FOUND FOR component=" + luidComponent + " at luid=" + luid + "   this should be impossible!");
			} else {
				layoutState.savePreviousState(luidComponent as DisplayObjectContainer);
			}
			trace("NEW LAYOUT: " + luid);
			//trace("======================================================\n");
			//trace(xml);
			//trace("======================================================\n");
			
			if (editMode) {
				var currentXML:XML = GMXBuilder.currentXML;
				var currentXMLChildren:XMLList = currentXML.children();
				if (currentXMLChildren.length() > 1) {
					Alert.show("Shortcut or layout change occured when the XML in the text area had more than 1 root node!  Could not retain previous changes!");
				} else {
					currentXMLChildren[0].@luid = "mainLuid";
					currentCompleteLayoutXML = currentXML;
				}
			}
			GMXMain.instance.replaceCurrentXMLNode(luid, xml);
			if (editMode) {
				GMXBuilder.gmxBuilderInstance.rebuildSpecificLuid(luid, xml);
				GMXBuilder.gmxBuilderInstance.setXmlTextAreaText(GMXBuilder.xmlToStringWithTabs(currentCompleteLayoutXML.children()));
				/*trace("EDIT MODE BUSINESS");
				GMXBuilder.gmxBuilderInstance.disintegrate();
				//var topLevelNode:XML = currentCompleteLayoutXML.children()[0];
				//var formerLuid:String = topLevelNode.@luid.toString();
				//topLevelNode.@luid = "do not change (will be replaced with mainLuid)";
				//trace(currentCompleteLayoutXML);
				if (GMXBuilder.buildArea != null) { GMXBuilder.buildArea.removeAllChildren(); }
				if (GMXBuilder.buildCanvas != null) { GMXBuilder.buildCanvas.removeAllChildren(); }
				GMXBuilder.gmxBuilderInstance.build(currentCompleteLayoutXML);
				//topLevelNode.@luid = formerLuid;
				*/
				return;
			}
			var formerIndex:int = luidComponentParent.getChildIndex(luidComponent as DisplayObject);
			luidComponent.disintegrate();
			luidComponentParent.removeChild(luidComponent as DisplayObject);
			// replace old luidComponent with the new one
			//	-- need to add a level of XML because processXML uses the children nodes
			var tempNode:XML = new XML(<top/>);
			tempNode.appendChild(xml);
			luidComponent = GMXComponentBuilder.processXML(luidComponentParent, tempNode);
			if (luidComponent == null) {
				Alert.show("ERROR: incoming XML does not contain a valid component at the top level!  xml=" + xml.toString());
				return;
			}
			luidComponentParent.addChildAt(luidComponent as DisplayObject, formerIndex);
			
			//== for loading metrics ===============================
			if (ControlChannel.polling) {
				ControlChannel.throughputSize++;
				trace("Throughput size: " + ControlChannel.throughputSize);
				ControlChannel.layoutDirty = true;
			}
			trace("Total Memory: " + System.totalMemory / 1000000.0 + " MB");
		}
// =============== END NEW MESSAGES ===================		

// MESSAGES TO SERVICE =========================================================================
		public static function do_ISISDataEdit(a_RecordList:Array):void {
			ServiceInterface.call("ISISDataEdit", a_RecordList);
		}
		
		public static function do_ISISRefresh(a_Command:String):void {
			ServiceInterface.call("ISISRefresh", a_Command);
		}
	}
}