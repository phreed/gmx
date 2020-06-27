package gmx_builder
{
	import flash.display.Graphics;
	import generics.HBox_X;
	import generics.VBox_X;
	import generics.Canvas_X;
	import GMX.Data.RecordVO;
	import GMX.Data.FieldVO;
	
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.controls.textClasses.TextRange;
	import mx.controls.TextInput;
	import mx.core.Container;
	import mx.core.DragSource;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.managers.DragManager;
	
	/**
	 * This class handles GMX edit mode.  The best general description for this class is probably in the Help text--to see it
	 * just run GMX, click somewhere within the flash window that pops up so it gains focus (after closing any Alerts that may
	 * pop up), and then press Ctrl + Shift + E.  Then either press F1 or click the HELP button in the top right corner.
	 * 
	 * GMXMain contains a "currentCompleteLayoutXML" variable which contains all the complete XML layout tree.  This class contains
	 * a "currentXML" variable which serves the same purpose, except within the scope of GMXBuilder (and edit mode).  Changes to this
	 * XML can be made either in the xmlTextArea, by clicking component button in the ComponentToolBox, or by editing specific
	 * properties using the AttributeEditToolBox (the properties available to each component are specified in the ClassDefinitions.xml).
	 * 
	 * The changes made cause the changed part of the XML tree (starting at the nearest xml node with a luid that was encountered while
	 * climbing up the tree from the node that was changed) to be updated, and the layout is rebuilt from that point, much like when
	 * a layout message targetting that luid was received.
	 * 
	 * This class also has a save mode (Ctrl + Shift + S), which sends the updated XML to the layout manager in a record with ruid="LM_REPLACE", such
	 * that the layout manager can update the corresponding layout file.
	 * 
	 * @author Alan Nelson
	 * @see ComponentToolBox
	 * @see AttributeEditToolBox
	 */
	public class GMXBuilder extends HBox implements IField
	{
		private const FULL_SCREEN_RESIZE:Boolean = true;
		
		public static const COMPONENT_DEFAULT_WIDTH:Number = 800;
		public static const COMPONENT_DEFAULT_HEIGHT:Number = 600;
		
		public static const RESIZE_BAR_WIDTH:Number = 6;
		public static const COMPONENT_TOOLBAR_WIDTH:Number = 150;
		public static const MINIMUM_SECTION_WIDTH:Number = 20;
		
		public static const TEXT_FORMAT_BRACKET:TextFormat = new TextFormat("Courier New", 10, "0x008800");
		public static const TEXT_FORMAT_QUOTE:TextFormat = new TextFormat("Courier New", 10, "0xff0000");
		public static const TEXT_FORMAT_DEFAULT:TextFormat = new TextFormat("Courier New", 10, "0x000000");
		
		public static var addGMXBuilderListeners:Boolean = false;
		
		public static const DRAG_VERSION:Boolean = true; // need to have the Builder add special listeners
		
		private var _backgroundColorValue:int = -1;
		public function set backgroundColorValue(val:int):void {
			_backgroundColorValue = val;
		}
		private var _fieldValue:String = "";
		
		private static var _currentXML:XML;
		public static function get currentXML():XML { return _currentXML; }
		private static var _formerXML:XML = new XML(<topNode></topNode>);
		public static function get formerXML():XML { return _formerXML; }
		public static function set formerXML(xml:XML):void { _formerXML = xml; }
		private static var _selectedObject:ISelfBuilding;
		private static var _formerParent:ISelfBuilding = null; // used for navigating between siblings
		public static var gmxBuilderInstance:GMXBuilder;
		private static var _selectedXML:XML;
		public static function get selectedXML():XML { return _selectedXML; }
		private static var _childrenComponentIndexPairs:Vector.<ComponentTreeIndexPair> = new Vector.<ComponentTreeIndexPair>;
		private static var _selectedIndexInXMLTree:String;
		
		public static var buildArea:VBox_X = new VBox_X();
		public static var buildCanvas:Canvas_X = new Canvas_X(); // used for drag version
		private static var coordinateLabel:Label = new Label();
		private static var textVBox:VBox = new VBox();
		private static var attributeEditToolBox:AttributeEditToolBox = new AttributeEditToolBox();
		private static var componentToolBox:ComponentToolBox;
		
		private static var xmlTextArea:TextArea = new TextArea();
		private static var testArea:TextArea = new TextArea();
		private var updateLayoutButton:Button = new Button();
		
		private var textAreaAndBuildAreaResizer:UIComponent = new UIComponent();
		private var buildAreaAndAttributeEditorResizer:UIComponent = new UIComponent();
		
		public static var saveMode:Boolean = false;
		
		//[Embed(source="./GMXHelpText.html",mimeType="application/octet-stream")]
		//public static var GMXHelpText:Class;
		
		public function GMXBuilder() 
		{
			super();
			textAreaAndBuildAreaResizer.width = RESIZE_BAR_WIDTH;
			buildAreaAndAttributeEditorResizer.width = RESIZE_BAR_WIDTH;
			// set the default relative widths of the textArea, buildArea, and AttributeEditor area
			// --> see the "set width" function
			_sectionRelativeWidths.push(0.3);
			_sectionRelativeWidths.push(0.4); 
			_sectionRelativeWidths.push(0.3); // [0.3, 0.4, 0.3];
			textAreaAndBuildAreaResizer.addEventListener(MouseEvent.MOUSE_DOWN, textAreaAndBuildAreaResizerDown);
			buildAreaAndAttributeEditorResizer.addEventListener(MouseEvent.MOUSE_DOWN, buildAreaAndAttributeEditorResizerDown);
			
			if (GMXMain.stage != null) { GMXMain.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyCommand); }
			if (FULL_SCREEN_RESIZE) { GMXMain.instance.addEventListener(Event.RESIZE, resized); }
			componentToolBox = new ComponentToolBox();
			gmxBuilderInstance = this;
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			this.verticalScrollPolicy = ScrollPolicy.OFF;
			this.clipContent = true;
			textVBox.horizontalScrollPolicy = ScrollPolicy.OFF;
			textVBox.verticalScrollPolicy = ScrollPolicy.OFF;
			textVBox.clipContent = true;

			buildArea.horizontalScrollPolicy = ScrollPolicy.ON;
			buildArea.verticalScrollPolicy = ScrollPolicy.ON;
			buildArea.addEventListener(Event.SCROLL, scrolled);
						
			buildCanvas.horizontalScrollPolicy = ScrollPolicy.ON;
			buildCanvas.verticalScrollPolicy = ScrollPolicy.ON;
			buildCanvas.addEventListener(Event.SCROLL, scrolled);
			
			GMXMain.PopUps.addChild(coordinateLabel);
			coordinateLabel.width = 100;
			coordinateLabel.height = 15;
			coordinateLabel.setStyle("color", 0xff0000);
			coordinateLabel.setStyle("textAlign", "center");
			coordinateLabel.opaqueBackground = 0x000000;
			coordinateLabel.selectable = false;
			coordinateLabel.mouseEnabled = false;
			coordinateLabel.mouseChildren = false;
			coordinateLabel.visible = false;
			
			this.addChild(textVBox);
			this.addChild(textAreaAndBuildAreaResizer);
			if (DRAG_VERSION) { this.addChild(buildCanvas);	}
			else { this.addChild(buildArea); }			
			this.addChild(buildAreaAndAttributeEditorResizer);
			this.addChild(attributeEditToolBox);
			this.addChild(componentToolBox);
			
			updateLayoutButton.height = 20;
			updateLayoutButton.label = "....UPDATE LAYOUT....";
			updateLayoutButton.addEventListener(MouseEvent.CLICK, updateButtonPressed);
			//if (XMLDisplay.getXMLDisplay().visible == false) {
				textVBox.addChild(updateLayoutButton);
				textVBox.addChild(xmlTextArea);
			//textVBox.addChild(testArea);
			//testArea.htmlText = '<FONT FACE="Courier New" SIZE="11" COLOR="#000000">&lt;Canvas ruid=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"SAMPLE"</FONT> backgroundColor=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"cccccc"</FONT> percentWidth=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"100"</FONT> percentHeight=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"100"</FONT>/&gt;</FONT>';
			//testArea.htmlText = '<FONT FACE="Courier New" SIZE="11" COLOR="#000000">&lt;VBox luid=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"do not change (will be replaced with mainLuid)"</FONT> ruid=<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">"mainRuid"</FONT>/&gt;</FONT>'
			//} else {
			//	textVBox.addChild(XMLDisplay.getXMLDisplay());
			//}
			
			xmlTextArea.setStyle("fontSize", 10);
			xmlTextArea.setStyle("fontFamily", "Courier New");
			xmlTextArea.verticalScrollPolicy = ScrollPolicy.ON;
			xmlTextArea.wordWrap = true;
			xmlTextArea.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, insertTab, true);
			xmlTextArea.addEventListener(Event.CHANGE, addedText);
			xmlTextArea.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, true);
			this.width = GMXMain.instance.width; //COMPONENT_DEFAULT_WIDTH;
			this.height = GMXMain.instance.height; //  COMPONENT_DEFAULT_HEIGHT;
		}
		
		[Embed(source="../GMXHelpText.html",mimeType="application/octet-stream")]
		public static var GMXHelpText:Class;
		/**
		 * Replaces the children of buildArea or buildCanvas (depending on the DRAG_VERSION flag) with a single TextArea containing help information.
		 * Pressing the UPDATE LAYOUT button or otherwise updating the layout removes this TextArea and builds the layout based on the text in the
		 * xmlTextArea (if the UPDATE LAYOUT button is pressed) or by layout XML that is otherwise received (e.g. through a layout message).
		 */	 
		public static function showHelp():void {
			var textArea:TextArea = new TextArea();
			textArea.editable = false;
			textArea.percentWidth = 100;
			textArea.percentHeight = 100;
			textArea.setStyle("fontSize", 10);
			textArea.verticalScrollPolicy = "on";
			textArea.htmlText = new GMXHelpText();
			disintegrateChildren();
			if (DRAG_VERSION) {
				buildCanvas.addChild(textArea);
			} else {
				buildArea.addChild(textArea);
			}
		}
		
		private function keyCommand(event:KeyboardEvent):void {
			var i:int;
			var j:int;
			switch(event.keyCode) {
				case Keyboard.ESCAPE: GMXMain.builderHighlightPopUp.graphics.clear(); selectedObject = null; this.setFocus(); break;
				case Keyboard.F1: this.setFocus(); showHelp(); break;
				case Keyboard.DELETE:
					if (event.ctrlKey && event.shiftKey) {
						if (_selectedObject == null || _selectedXML == null || _selectedXML.parent() == null) { break; }
						this.setFocus();
						var xmlChildren:XMLList = _selectedXML.parent().children();
						for (i = 0; i < xmlChildren.length(); i++) {
							//trace(xmlChildren[i]);
							if (xmlChildren[i] == _selectedXML) {
								delete xmlChildren[i];
								trace("ORIGNAL: " + _selectedIndexInXMLTree);
								var splitIndex:Array = _selectedIndexInXMLTree.split(",");
								var newIndex:String = null;
								var lastIndex:int = parseInt(splitIndex[splitIndex.length - 1]);
								if (lastIndex > 0) { // go to the upper sibling
									newIndex = splitIndex[0];
									for (j = 1; j < splitIndex.length - 1; j++) {
										newIndex += "," + splitIndex[j];
									}
									newIndex += "," + (lastIndex - 1);
									trace("UPPER SIBLING: " + newIndex);
								} else if (splitIndex.length > 0) { // go to the parent
									newIndex = splitIndex[0];
									for (j = 1; j < splitIndex.length - 1; j++) {
										newIndex += "," + splitIndex[j];
									}
									trace("PARENT: " + newIndex);
								}
								selectedObject = null;
								selectedIndexInXMLTree = null;
								
								if (newIndex != null) { //trace("HAHAH");  XMLDisplay.getXMLDisplay().selectXML(newIndex); XMLDisplay.getXMLDisplay().invalidateDisplayList(); }
									for (j = 0; j < _childrenComponentIndexPairs.length; j++) {
										if (_childrenComponentIndexPairs[j].indexInXMLTree == newIndex) {
											selectedObject = _childrenComponentIndexPairs[j].selfBuilding;
										}
									}
									selectedIndexInXMLTree = newIndex;
								}
								appendedXMLUpdate();
								return;
							}
						}
					}
					break;
			}
			if (!event.ctrlKey) { return; }
			
			if (_selectedObject == null) { return; }
			// if _selectedObject exists, then one of the following hotkeys may select a parent or child of that object
			switch(String.fromCharCode(event.charCode)) {
				case "p": // select that object's parent
					this.setFocus();
					// find the nearest ISelfBuilding parent and select that
					var componentParent:ISelfBuilding = getNearestSelfBuildingParent(_selectedObject);
					if (componentParent == null) { return; }
					// some components have an extra level (for example a VBox_X) inside of them that is not in the XML
					// so we need to catch those (by looking at whether they have the listener) and go down another level
					// ... 2 layers just in case
					if (!componentParent.hasEventListener(MouseEvent.CLICK)) {
						componentParent = getNearestSelfBuildingParent(componentParent);
						if (componentParent == null) { return; }
						if (!componentParent.hasEventListener(MouseEvent.CLICK)) {
							componentParent = getNearestSelfBuildingParent(componentParent);
							if (componentParent == null) { return; }
						}
					}
					selectedObject = componentParent;
					
					_formerParent = getNearestSelfBuildingParent(componentParent);
					break;
				case ".": // select that object's first child
					this.setFocus();
					var firstComponentChild:ISelfBuilding = getFirstSelfBuildingChild(_selectedObject);
					if (firstComponentChild == null) { return; }
					// some components have an extra level (for example a VBox_X) inside of them that is not in the XML
					// so we need to catch those (by looking at whether they have the listener) and go down another level
					// ... 2 layers just in case
					if (!firstComponentChild.hasEventListener(MouseEvent.CLICK)) {
						firstComponentChild = getFirstSelfBuildingChild(firstComponentChild);
						if (firstComponentChild == null) { return; }
						if (!firstComponentChild.hasEventListener(MouseEvent.CLICK)) {
							firstComponentChild = getFirstSelfBuildingChild(firstComponentChild);
							if (firstComponentChild == null) { return; }
						}
					}
					_formerParent = _selectedObject;
					selectedObject = firstComponentChild;			
					break;
				case ";": // select that object's next child
					this.setFocus();
					//trace("FORMER PARENT: " + _formerParent);
					if (_formerParent == null) { return; }
					var nextComponentChild:ISelfBuilding = getNextSelfBuildingChild(_selectedObject);
					if (nextComponentChild == null) { return; }
					selectedObject = nextComponentChild;
					break;
				case "l": // select that object's prev child
					this.setFocus();
					if (_formerParent == null) { return; }
					var prevComponentChild:ISelfBuilding = getPrevSelfBuildingChild(_selectedObject);
					if (prevComponentChild == null) { return; }
					selectedObject = prevComponentChild;
					break;
				case "'": // open up the xml view
					this.setFocus();
					var xmlDisplay:XMLDisplay = XMLDisplay.getXMLDisplay();
					xmlDisplay.visible = !xmlDisplay.visible;					
					break;
			}
		}
		private static function getNearestSelfBuildingParent(component:ISelfBuilding):ISelfBuilding {
			if (component == null) { return null; }
			var componentParent:DisplayObjectContainer = component.parent;
			if (componentParent == buildCanvas || componentParent == buildArea) { return null; } // the very top has been reached already
			if (componentParent is ISelfBuilding) { return componentParent as ISelfBuilding; }
			while (componentParent != null) {
				if (componentParent == buildCanvas || componentParent == buildArea) { return null; }
				if (componentParent is ISelfBuilding) { return componentParent as ISelfBuilding; }
				componentParent = componentParent.parent;
			}
			return null;
		}
		private static function getFirstSelfBuildingChild(component:ISelfBuilding):ISelfBuilding {
			for (var i:int = 0; i < component.numChildren; i++) {
				var child:ISelfBuilding = component.getChildAt(i) as ISelfBuilding;
				if (child != null) { return child; }
			}
			return null;
		}
		private static function getNextSelfBuildingChild(component:ISelfBuilding):ISelfBuilding {
			var childFound:Boolean ;
			for (var i:int = 0; i < _formerParent.numChildren; i++) {
				var child:ISelfBuilding = _formerParent.getChildAt(i) as ISelfBuilding;
				if (childFound && child != null && child.hasEventListener(MouseEvent.CLICK)) { return child; }
				if (child == component) { childFound = true; }
			}
			return null;
		}
		private static function getPrevSelfBuildingChild(component:ISelfBuilding):ISelfBuilding {
			var lastFoundSelfBuilding:ISelfBuilding; 
			for (var i:int = 0; i < _formerParent.numChildren; i++) {
				var child:ISelfBuilding = _formerParent.getChildAt(i) as ISelfBuilding;
				if (child == component) { 
					return lastFoundSelfBuilding;
				}
				if (child != null && child.hasEventListener(MouseEvent.CLICK)) { lastFoundSelfBuilding = child; }
			}
			return null;
		}
		
		override public function set height(val:Number):void {
			if (componentToolBox != null) { componentToolBox.height = val; }
			if (attributeEditToolBox != null) { attributeEditToolBox.height = val; }
			if (textVBox != null) { textVBox.height = val; }
			if (buildArea != null) { buildArea.height = val;  }
			if (buildCanvas != null) { buildCanvas.height = val;  }
			if (xmlTextArea != null) { xmlTextArea.height = (updateLayoutButton == null) ? val - 20 : val - updateLayoutButton.height;  }
			super.height = val;
			textAreaAndBuildAreaResizer.height = val;
			buildAreaAndAttributeEditorResizer.height = val;
		}
		
		private var _sectionRelativeWidths:Vector.<Number> = new Vector.<Number>();
		override public function set width(val:Number):void {
			
			//NEED TO FIX THIS STUFF
			if (componentToolBox != null) { componentToolBox.width = COMPONENT_TOOLBAR_WIDTH; }
			var widthLeftOver:Number = val - COMPONENT_TOOLBAR_WIDTH - 2 * RESIZE_BAR_WIDTH;
			if (textVBox != null) { textVBox.width = widthLeftOver * _sectionRelativeWidths[0]; }
			if (xmlTextArea != null) { xmlTextArea.width = widthLeftOver * _sectionRelativeWidths[0]; }
			if (updateLayoutButton != null) { updateLayoutButton.width = widthLeftOver * _sectionRelativeWidths[0]; }
			
			if (buildArea != null) { buildArea.width = widthLeftOver * _sectionRelativeWidths[1];  }
			if (buildCanvas != null) { buildCanvas.width = widthLeftOver * _sectionRelativeWidths[1];  }
			
			if (attributeEditToolBox != null) { attributeEditToolBox.width = widthLeftOver * _sectionRelativeWidths[2]; }  
			//NEED TO INVALIDATE DISPLAY LIST AND HAVE IT RESIZE EDIT BOXES--probably after the resize is complete
			
			super.width = val;
		}
		/**
		 * Used to size up GMXBuilder to fit the entire application whenever the application is resized
		 * @param	event
		 */
		private function resized(event:Event):void {
			if (GMXMain.application == null) { return; }
			this.width = GMXMain.instance.width;
			this.height = GMXMain.instance.height;
		}
		
		private var _referenceXForResizing:Number;
		private function textAreaAndBuildAreaResizerDown(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			GMXMain.instance.stage.addEventListener(MouseEvent.MOUSE_MOVE, textAreaAndBuildAreaResizerMove);
			GMXMain.instance.stage.addEventListener(MouseEvent.MOUSE_UP, resizerMouseUp);
			_referenceXForResizing = mouseX;
		}
		private function textAreaAndBuildAreaResizerMove(event:MouseEvent):void {
			var deltaX:Number = mouseX - _referenceXForResizing;
			var totalSharedRelativeWidth:Number = _sectionRelativeWidths[0] + _sectionRelativeWidths[1];
			var totalSharedWidth:Number = textVBox.width + (DRAG_VERSION ? buildCanvas.width : buildArea.width);
			var fractionalDifference:Number = deltaX / totalSharedWidth;
			_sectionRelativeWidths[0] += fractionalDifference;
			_sectionRelativeWidths[1] -= fractionalDifference;
			if (_sectionRelativeWidths[0] > (totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth)) {
				_sectionRelativeWidths[0] = totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth;
				_sectionRelativeWidths[1] = MINIMUM_SECTION_WIDTH/totalSharedWidth;
			} else if (_sectionRelativeWidths[1] > (totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth)) {
				_sectionRelativeWidths[1] = totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth;
				_sectionRelativeWidths[0] = MINIMUM_SECTION_WIDTH/totalSharedWidth;
			}
			_referenceXForResizing = mouseX;
			this.width = this.width; // see the set width function (widths are assigned using the _sectionRelativeWidths vector
			this.invalidateDisplayList();
		}
		private function buildAreaAndAttributeEditorResizerDown(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			GMXMain.instance.stage.addEventListener(MouseEvent.MOUSE_MOVE, buildAreaAndAttributeEditorResizerMove);
			GMXMain.instance.stage.addEventListener(MouseEvent.MOUSE_UP, resizerMouseUp);
			_referenceXForResizing = mouseX;
		}
		private function buildAreaAndAttributeEditorResizerMove(event:MouseEvent):void {
			var deltaX:Number = mouseX - _referenceXForResizing;
			var totalSharedRelativeWidth:Number = _sectionRelativeWidths[1] + _sectionRelativeWidths[2];
			var totalSharedWidth:Number = attributeEditToolBox.width + (DRAG_VERSION ? buildCanvas.width : buildArea.width);
			var fractionalDifference:Number = deltaX / totalSharedWidth;
			_sectionRelativeWidths[1] += fractionalDifference;
			_sectionRelativeWidths[2] -= fractionalDifference;
			if (_sectionRelativeWidths[1] > (totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth)) {
				_sectionRelativeWidths[1] = totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth;
				_sectionRelativeWidths[2] = MINIMUM_SECTION_WIDTH/totalSharedWidth;
			} else if (_sectionRelativeWidths[2] > (totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth)) {
				_sectionRelativeWidths[2] = totalSharedRelativeWidth - MINIMUM_SECTION_WIDTH/totalSharedWidth;
				_sectionRelativeWidths[1] = MINIMUM_SECTION_WIDTH/totalSharedWidth;
			}
			_referenceXForResizing = mouseX;
			this.width = this.width; // see the set width function (widths are assigned using the _sectionRelativeWidths vector
			this.invalidateDisplayList();
		}
		private function resizerMouseUp(event:MouseEvent):void {
			GMXMain.instance.stage.removeEventListener(MouseEvent.MOUSE_MOVE, textAreaAndBuildAreaResizerMove);
			GMXMain.instance.stage.removeEventListener(MouseEvent.MOUSE_UP, resizerMouseUp);
			GMXMain.instance.stage.removeEventListener(MouseEvent.MOUSE_MOVE, buildAreaAndAttributeEditorResizerMove);
		}

		
		private function updateButtonPressed(event:MouseEvent):void {
			try {
				_formerXML = _currentXML.copy();
				//trace("========= xmlTextArea.text: " + xmlTextArea.text + " ================================");
				_currentXML = new XML("<topNode>" + xmlTextArea.text + "</topNode>");
			} catch (e:Error) {
				Alert.show("GMXBuilder updateButtonPressed XML Error: " + e.message);
				return;
			}
			if (this.field != null) { 
				this.field.value = xmlTextArea.text;
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
			}
			
			rebuild();
			this.invalidateDisplayList();
		}
		
		private function clearChildrenComponentIndexPairs():void {
			while (_childrenComponentIndexPairs.length != 0) {
				_childrenComponentIndexPairs[_childrenComponentIndexPairs.length - 1].disintegrate();
				_childrenComponentIndexPairs.pop();
			}
		}
		/**
		 * @inheritDoc 
		 **/
		public function build(xml:XML):void {
			if (xml == null) { return; }
			var recordAdded:Boolean = false; 
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.recordStack.push(this.record);
				recordAdded = true;
			}
			if (xml.@fid != undefined) {
				this.fid = xml.@fid.toString();
			}
			_currentXML = xml;
			setXmlTextAreaText(xmlToStringWithTabs(xml.children()));
			if (this.field != null) { this.field.value = xmlTextArea.htmlText; }
			GMXComponentBuilder.setStandardValues(xml, this);
			// for some reason there appears to be a race condition that makes it so that the components are invisible (although clickable???) so use callLater
			callLater(updateButtonPressed, [null]);
			if (recordAdded) {
				GMXDictionaries.recordStack.pop();
			}
		}
		
		public function rebuildSpecificLuid(luid:String, xml:XML):void {		
			// JUST SO YOU KNOW:  this function is pretty convoluted... it involves a lot of deleting elements from arrays and
			// moving things around so they are in the right order.  This makes it kind of hard to figure out, so I've tried to
			// make it clear as possible with a lot of comments.  There's probably a better way to do this, but I'm not sure how 
			// else to approach this without restructuring a lot of other stuff...
			
			var i:int;
			// we do NOT call clearChildrenComponentIndexPairs() here like we do in rebuild() because only the components
			// in the changed XML are added into _childrenComponentIndexPairs through the ComponentBuilder.processXML function...
			// if we did clear _childrenComponentIndexPairs, then there would be a serious mismatch b/w the components
			// and their xml indeces since not all components would be added to _childrenComponentIndexPairs (i.e. processXML
			// would only be called on the subset of XML that changed!)
			var luidComponent:ISelfBuilding = GMXDictionaries.getLuid(luid);
			if (luidComponent == null) {
				Alert.show("GMXBuilder rebuildSpecificLuid ERROR: there was no component with luid=" + luid);
				rebuild();
				return;
			}
			if (!(luidComponent is Container)) {
				Alert.show("GMXBuilder rebuildSpecificLuid ERROR: component at luid of " + luid + " was not a container!");
				rebuild();
				return;
			}
			
			// making addGMXBuilderListeners true causes all the components built using processXML
			// to have the clickedChild listener (which makes them selectable for edit mode)  added to it.  
			// It also calls "addComponent", which pushes a ComponentTreeIndexPair with the component (but not the index yet).
			GMXBuilder.addGMXBuilderListeners = true;
			luidComponent.disintegrate();
			var luidComponentAsContainer:Container = luidComponent as Container;
			luidComponentAsContainer.removeAllChildren();
			
			var luidComponentXMLIndex:String = ""; 
			// get the xml index so we can identify which children to remove... e.g. if luidComponent
			// had the index of 0,0,1 then all it's children would start with the substring 0,0,1
			var luidComponentArrayIndex:int = 0;
			for (i = 0; i < _childrenComponentIndexPairs.length; i++) {
				if (_childrenComponentIndexPairs[i].selfBuilding == luidComponent) {
					luidComponentXMLIndex = _childrenComponentIndexPairs[i].indexInXMLTree;
					luidComponentArrayIndex = i;
					break;
				}
			}
			if (luidComponentXMLIndex == "" || luidComponentXMLIndex == null) {
				Alert.show("GMXBuilder rebuildSpecificLuid ERROR: component with luid=" + luid + " did not have a corresponding luidComponentIndex!");
				rebuild();
				return;
			}
			
			//-Because "addComponent" is called from within the ComponentBuilder.processXML function (which is called within the build function),
			// and addComponent pushes a new ComponentTreeIndexPair onto _childrenComponentIndexPairs, we need to find the
			// the index corresponding to the luidComponent, remove all of its child indeces from _childrenComponentIndexPairs, and
			// call the build function (which pushes the components onto _childrenComponentIndexPairs)...  NOTE that this involves rearranging
			// everything in _childrenComponentIndexPairs as follows:
			//	1) remove all child components of luidComponent (based on matching indexInXMLTree substring) from _childrenComponentIndexPairs
			//  2) pulling out and saving all the ComponentIndexPairs that are after luidComponent in the _childrenComponentIndexPairs array and
			//		were not children of luidComponent (which are now not in the array since they were deleted in step 1).  The idea here is that
			//		those components to save were not changed in any way, and since we aren't rebuilding them, we don't want to deal with getting new
			//		pointers to them when that's really not necessary.
			//  3) call the build function which, because the GMXComponentBuilder.addGMXBuilderListeners = true here, adds new ComponentIndexPairs
			//		for all the new child components in the updated luidComponent XML.
			//	4) generateTreeIndeces is called to get all index values for all the components in the xml
			//  5) iterate over _childrenComponentIndexPairs and set _childrenComponentIndexPairs[i].indexInXMLTree = indexArray[i]
			// 		This works because all the shifting around we did will definitely have all the ComponentIndexPairs in the right order
			
			var substringLength:int = luidComponentXMLIndex.length;
			var componentIndexPairsToSave:Vector.<ComponentTreeIndexPair> = new Vector.<ComponentTreeIndexPair>();
			var numXMLSpritesToRemove:int = 0;
			for (i = luidComponentArrayIndex + 1; i < _childrenComponentIndexPairs.length; i++) {
				// remove all "child" xml components from the stack
				if (_childrenComponentIndexPairs[i].indexInXMLTree.substring(0, substringLength) == luidComponentXMLIndex) {
					_childrenComponentIndexPairs[i].selfBuilding.removeEventListener(MouseEvent.MOUSE_DOWN, GMXBuilder.mouseDownOnChild);
					_childrenComponentIndexPairs[i].selfBuilding.disintegrate();
					_childrenComponentIndexPairs[i].selfBuilding = null;
					
					_childrenComponentIndexPairs.splice(i, 1);
					i--;
					numXMLSpritesToRemove++;
				} else {
					break;
				}
			}
			while(_childrenComponentIndexPairs.length != luidComponentArrayIndex + 1) {
				// pull off all the componentIndexPairs that we want to save (that aren't children of the luidComponent)
				componentIndexPairsToSave.push(_childrenComponentIndexPairs.pop());
			}
			luidComponent.build(xml);
			GMXBuilder.addGMXBuilderListeners = false;
			while (componentIndexPairsToSave.length != 0) {
				addComponentIndexPair(componentIndexPairsToSave.pop());
			}
			
			// now find use the xml tree to find the indeces in the tree belonging to ALL components in the display list
			var indexArray:Vector.<String> = new Vector.<String>;
			var foundSelectedObject:Boolean = false;
			
			XMLDisplay.getXMLDisplay().clearXmlSprites();
			generateTreeIndeces(indexArray, _currentXML.children(), "");
			
			///   IGNORE THESE COMMENTS b/c we are doing generateTreeIndeces on the whole _currentXML, which rebuilds ALL XmlSprites
			// generateTreeIndeces function adds to XMLDisplay.xmlSprites (the tree browser for all the components)
			//... so we need to go in and remove the components that were removed (i.e. children of luidComponent)
			// and then move the components that were just added to the end of the xmlSprites vector to the
			// proper location (right after luidComponent's xmlSprite)
			//XMLDisplay.spliceXmlSprites(luidComponentArrayIndex + 1, numXMLSpritesToRemove);
			//XMLDisplay.moveXMLSprites(XMLDisplay.numXMLSprites - indexArray.length, indexArray.length, luidComponentArrayIndex + 1);
			
			trace("Total Memory: " + System.totalMemory / 1000000.0 + " MB"); 
			
			try {
				for (i = luidComponentArrayIndex + 1; i < indexArray.length; i++) {
					_childrenComponentIndexPairs[i].indexInXMLTree = indexArray[i];
				}
				// now need to go through ALL the _childrenComponentIndexPairs to check for the selected one
				// since the selected one may not have been in the small subset of XML that was changed (and
				// therefore the selected object won't be in indexArray)
				for (i = 0; i < _childrenComponentIndexPairs.length; i++) {
					if (_selectedIndexInXMLTree == _childrenComponentIndexPairs[i].indexInXMLTree) { 
						selectedObject = _childrenComponentIndexPairs[i].selfBuilding; 
						foundSelectedObject = true;
					}
				}
				if (!foundSelectedObject) { selectedObject = null;  }
				XMLDisplay.getXMLDisplay().resetIntermediateFocus();
				XMLDisplay.getXMLDisplay().invalidateDisplayList();
			} catch (e:Error) { 
				Alert.show("WARNING: Had a problem matching components to their corresponding XML.  This means that" +
							" a component was put somewhere it shouldn't belong (e.g. as a child of a ComboBox).  The" +
							" XML will not be built on the screen, although it will remain in the TextBox.  Fix the" +
							" problem and press 'UPDATE LAYOUT' again.");
				if (_currentXML == _formerXML) { 
					Alert.show("Unexpected error--current XML and former XML both in error state!");
					return;
				}
				_currentXML = _formerXML;
				rebuild();
			}
			callLater(redrawHighlight);
		}
		
		private function rebuild():void {
			disintegrateChildren();
			if (DRAG_VERSION) { buildCanvas.removeAllChildren();  }
			else { buildArea.removeAllChildren(); }
			clearChildrenComponentIndexPairs();
			//trace("rebuild: _currentXML: " + _currentXML);
			
			// making addGMXBuilderListeners true causes all the components built using processXML
			// to have the clickedChild listener added to it.  It also calls "addComponent", which
			// adds a ComponentTreeIndexPair with the component (not the index yet).
			GMXBuilder.addGMXBuilderListeners = true;
			if (DRAG_VERSION) { GMXComponentBuilder.processXML(buildCanvas, _currentXML); }
			else { GMXComponentBuilder.processXML(buildArea, _currentXML); }
			
			GMXBuilder.addGMXBuilderListeners = false;
			// now find use the xml tree to find the indeces in the tree belonging to each component
			// that was just added
			var indexArray:Vector.<String> = new Vector.<String>;
			var foundSelectedObject:Boolean = false;
			
			XMLDisplay.getXMLDisplay().clearXmlSprites();
			generateTreeIndeces(indexArray, _currentXML.children(), ""); // indexArray is populated by the generateTreeIndeces function
			trace("Total Memory: " + System.totalMemory / 1000000.0 + " MB"); 
			
			try {
				for (var i:int = 0; i < indexArray.length; i++) {
					_childrenComponentIndexPairs[i].indexInXMLTree = indexArray[i];
					//trace("_selectedIndexInXMLTree: " + _selectedIndexInXMLTree + "   indexArray[i]: " +indexArray[i]);
					if (_selectedIndexInXMLTree == indexArray[i]) { 
						selectedObject = _childrenComponentIndexPairs[i].selfBuilding; 
						foundSelectedObject = true;
					}
				}
				if (!foundSelectedObject) { selectedObject = null;  }
				XMLDisplay.getXMLDisplay().resetIntermediateFocus();
				XMLDisplay.getXMLDisplay().invalidateDisplayList();
				
			} catch (e:Error) { 
				Alert.show("WARNING: Had a problem matching components to their corresponding XML.  This means that" +
							" a component was put somewhere it shouldn't belong (e.g. as a child of a ComboBox).  The" +
							" XML will not be built on the screen, although it will remain in the TextBox.  Fix the" +
							" problem and press 'UPDATE LAYOUT' again.");
				if (_currentXML == _formerXML) { 
					Alert.show("Unexpected error--current XML and former XML both in error state!");
					return;
				}
				_currentXML = _formerXML;
				rebuild();
			}
			callLater(redrawHighlight);
		}
//=================================================================================================================
//================= BEGIN Selection Functions =======================================================================
		public static function clickedChild(event:MouseEvent):void {
			if (event.shiftKey) { return; } // assumed that they would like to drag the object, so don't select it
			
			var selfBuilding:ISelfBuilding = event.currentTarget as ISelfBuilding;
			selectedObject = selfBuilding;
			if (selfBuilding != null) { _formerParent = getNearestSelfBuildingParent(selfBuilding); } // used for hotkey navigation between parent and children
			event.stopPropagation();
		}
		
		private static function set selectedIndexInXMLTree(val:String):void {
			_selectedIndexInXMLTree = val;
			if (val == null) { return; }
			XMLDisplay.xmlDisplayInstance.selectXML(_selectedIndexInXMLTree);
		}
		
		public static function set selectedObjectByIndex(val:String):void {
			for (var i:int = 0; i < _childrenComponentIndexPairs.length; i++) {
				if (val == _childrenComponentIndexPairs[i].indexInXMLTree) {
					selectedObject = _childrenComponentIndexPairs[i].selfBuilding;
				}
			}
		}
		public static function get selectedObject():ISelfBuilding { return _selectedObject; }
		public static function set selectedObject(selfBuilding:ISelfBuilding):void {
			if (_selectedObject == selfBuilding) { return; }
			
			if (_selectedObject != null) { _selectedObject.filters = []; }
			if (selfBuilding == null) { 
				// toolBox will be empty
				_selectedObject = null; 
				componentToolBox.enableButtonsBasedOnSelectedObjectType(null); 
				attributeEditToolBox.createToolBox(null); 
				return; 
			} 
			
			_selectedObject = selfBuilding;
			
			_selectedObject.filters = [new GlowFilter(0xffff00, 1, 10, 10, 3, 1)];
			redrawHighlight();
			var i:int;
			_selectedXML = xmlFinder(_currentXML, null, _selectedObject, true);
			attributeEditToolBox.createToolBox(GMXComponentProperties.getComponentPropertiesFromClassName(_selectedObject.className));
			//componentToolBox.enableButtonsBasedOnSelectedObjectType(_selectedObject);
			componentToolBox.enableButtonBasedOnSelectedXML(_selectedXML);
		}
		/**
		 * Finds the node based on a comma separated index pointing to it (e.g. index "0,4,2" would
		 * point to the third child of the fifth child of the first child of the root of the XML tree)
		 * @param	parentXML
		 * @param	indexInXML
		 * @return	the XML node referred to by the index or null if it cannot be found
		 */
		public static function xmlFinder(parentXML:XML, indexInXML:String = null, object:ISelfBuilding = null, markSelectedIndex:Boolean = true ):XML {
			if (indexInXML == null && object == null) { return null; }
			
			var i:int;
			if (indexInXML == null) {
				for (i = 0; i < _childrenComponentIndexPairs.length; i++) {
					if (_childrenComponentIndexPairs[i].selfBuilding == object) {
						indexInXML = _childrenComponentIndexPairs[i].indexInXMLTree;
						if (markSelectedIndex) { selectedIndexInXMLTree = indexInXML; }
						break;
					}
				}
			}
			// if indexInXML is still null, then the component might be a VBox_X inside of a resizingBox, for example
			
			
			var childIndex:int;
			var children:XMLList = parentXML.children();
			for (i = 0; i < indexInXML.length; i++) {
				if (indexInXML.charAt(i) == ",") {
					childIndex = parseInt(indexInXML.substring(0, i));
					try {
						return xmlFinder(children[childIndex], indexInXML.substring(i + 1));
					} catch(e:Error) {
						Alert.show("GMXBuilder xmlFinder error: " + e.message);
						return null;
					}
				}
			}
			// reached the end of the string--no more commas... therefore indexInXML has only an index left
			childIndex = parseInt(indexInXML);
			try {
				return children[childIndex];
			} catch(e:Error) {
				Alert.show("GMXBuilder xmlFinder error: " + e.message);
				return null;
			}
			return null;
		}
//================= END Selection Functions =======================================================================
//=================================================================================================================
		private function generateTreeIndeces(indexArray:Vector.<String>, xmlChildren:XMLList, indexInXMLTree:String):void {
			var newIndexInXMLTree:String;
			if (indexInXMLTree.length != 0) { indexInXMLTree += ","; }
			for (var i:int = 0; i < xmlChildren.length(); i++) {
				newIndexInXMLTree = indexInXMLTree + i;
				if (GMXComponentProperties.hasComponent(xmlChildren[i].localName()) == true) {
					indexArray.push(newIndexInXMLTree);
					XMLDisplay.getXMLDisplay().addXmlSprite(newIndexInXMLTree, xmlChildren[i]); 
				}
				generateTreeIndeces(indexArray, xmlChildren[i].children(), newIndexInXMLTree);
			}
		}
		
		// this function is called from within the GMXComponentBuilder.processXML function as the components are being made
		public static function addComponent(selfBuilding:ISelfBuilding):void {
			_childrenComponentIndexPairs.push(new ComponentTreeIndexPair(selfBuilding));
		}
		private static function addComponentIndexPair(pair:ComponentTreeIndexPair):void {
			_childrenComponentIndexPairs.push(pair);
		}

		
//=================================================================================================================		
//================= BEGIN Mouse Drag functions ====================================================================
		private static var moved:Boolean = false;
		private static var mouseDown:Boolean = false;
		private static var draggedChild:ISelfBuilding = null;
		private static var initialClickPointOnChild:Point;
		private static var originalComponentPosition:Point;
		public static function mouseDownOnChild(event:MouseEvent):void {
			event.stopPropagation();
			if (!event.shiftKey) { return; }
			mouseDown = true;
			
			draggedChild = event.currentTarget as ISelfBuilding;
			initialClickPointOnChild = new Point(draggedChild.mouseX, draggedChild.mouseY);
			originalComponentPosition = new Point(draggedChild.x, draggedChild.y);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveWithChild, false, 0, true);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpWithChild, false, 0, true);
			coordinateLabel.text = originalComponentPosition.x + ", " + originalComponentPosition.y;
			coordinateLabel.visible = true;
		}
		public static function mouseMoveWithChild(event:MouseEvent):void {
			if (draggedChild.parent == null) { return; }
			
			if (!event.shiftKey) {
				draggedChild.x = originalComponentPosition.x;
				draggedChild.y = originalComponentPosition.y;
				coordinateLabel.visible = false;
				GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveWithChild);
				GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpWithChild);
				moved = false;
				return;
			}
			
			//if (!moved && Point.distance(initialClickPoint, new Point(GMXMain.stage.mouseX, GMXMain.stage.mouseY)) > 2) {
				moved = true;
			//}
			if (moved) {
				draggedChild.x = draggedChild.parent.mouseX - initialClickPointOnChild.x;
				draggedChild.y = draggedChild.parent.mouseY - initialClickPointOnChild.y;
			}
			coordinateLabel.text = draggedChild.x + ", " + draggedChild.y;
		}
		public static function mouseUpWithChild(event:MouseEvent):void {
			var i:int;
			mouseDown = false;
			coordinateLabel.visible = false;
			if (!moved) { return; }
			moved = false;
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveWithChild);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpWithChild);
			/*if (!event.ctrlKey) {
				draggedChild.x = originalComponentPosition.x;
				draggedChild.y = originalComponentPosition.y;
				return;
			}*/
			
			var draggedXML:XML = xmlFinder(_currentXML, null, draggedChild);
			if (draggedXML != null) {
				if (draggedChild.parent is VBox || draggedChild.parent is HBox) {
					var alignedBoxParent:UIComponent = draggedChild.parent as UIComponent;
					var draggedChildIndex:int = -1;
					var child:ISelfBuilding;
					var newChildIndex:int = -1;
					// only do the for loop if there are more than 1 children
					if (alignedBoxParent.numChildren > 1) 
					for (i = 0; i < alignedBoxParent.numChildren; i++) {
						child = alignedBoxParent.getChildAt(i) as ISelfBuilding;
						if (child == null) { continue; }
						
						if (alignedBoxParent is HBox) {
							if (newChildIndex == -1 && draggedChild.x < child.x) { 
								newChildIndex = i; // displace this child
							}
						} else if (alignedBoxParent is VBox) {
							if (newChildIndex == -1 && draggedChild.y < child.y) { 
								newChildIndex = i; // displace this child
							}
						}
						if (child == draggedChild) {
							draggedChildIndex = i;
						}
					}
					//trace("newChildIndex: " + newChildIndex + "    draggedChildIndex: " + draggedChildIndex);
					if (newChildIndex == draggedChildIndex) {
						// no change, but put it back to it's original x y by rebuilding with appendedXMLUpdate below
					} else {
						var parentXML:XML = draggedXML.parent();
						if (parentXML == null) { Alert.show("PARENT XML NULL THIS CAN'T BE HAPPENING!!!"); }
						if (newChildIndex == -1) { // last child
							delete parentXML.children()[draggedChildIndex];
							parentXML.insertChildAfter(parentXML.children()[parentXML.children().length() - 1], draggedXML);
						} else {
							if (newChildIndex > draggedChildIndex) { 
								newChildIndex -= 1; 
							}						
							delete parentXML.children()[draggedChildIndex];
							parentXML.insertChildBefore(parentXML.children()[newChildIndex], draggedXML);
						}
					}
					appendedXMLUpdate(); 
				} else {
					_formerXML = _currentXML.copy();
					draggedXML.@x = Math.round(draggedChild.x);
					draggedXML.@y = Math.round(draggedChild.y);
					appendedXMLUpdate();
				}
			}
			draggedChild = null;
			return;
		}
//================= END Mouse Drag functions ======================================================================
//=================================================================================================================
//================= BEGIN XML update functions ====================================================================
		private static function replaceFileContainingChildrenXMLNodesWithIncludes(xml:XML):void {
			// the incoming xml should be a copy of the original XML so that the replacing does not destroy anything
			var i:int;
			if (xml.@luid != undefined) {
				//xml.setLocalName("include");
				var originalLuid:String = xml.@luid.toString();
				for (i = originalLuid.length - 1; i > 0; i--) {
					if (originalLuid.charAt(i) == ":") { 
						// take the first one, e.g. if the layout-manager generated luid
						// is :T:A|:A1:B, then it would stop at B
						xml.@luid = originalLuid.substring(i + 1);
						break;
					}
				}
			}
			if (xml.@href != undefined) {
				xml.setLocalName("include");
				/*var namespaces:Array = xml.namespaceDeclarations();
				for (i = 0; i < namespaces.length(); i++) {
					var ns:Namespace = namespaces[i];
					if (ns.uri == "
				}*/
				var ns:Namespace = xml.namespace("LM"); // it should have this namespace declaration in it
				xml.setNamespace(ns);
				delete xml.*; // delete all the children
				return;
			}
			
			
			var xmlChildren:XMLList = xml.children();
			for (i = 0; i < xmlChildren.length(); i++) {
				replaceFileContainingChildrenXMLNodesWithIncludes(xmlChildren[i]);
			}
		}
		/**
		 * <p>This function is called after any component's XML has been updated, and serves to (1) find the nearest
		 * ancestor node containing a luid so that the new XML can be loaded starting from that level instead of
		 * replacing the entire layout starting at luid="mainLuid" and (2) if the user is in "save" mode, send a
		 * message to the layout manager to update the corresponding layout file.</p>
		 * 
		 * <p>The function crawls up the layout XML towards the root node
		 * starting at the selected component's XML, and finds the nearest ancestor node "Y" containing the "href" attribute because
		 * those nodes correspond to a container component that has been built (along with its child components) from an 
		 * entire file sent by the layout manager.  Note that these container components necessarily have a luid as well 
		 * such that they can be targetted for replacement by an ISISLayout message from the layout manager.</p>
		 *
		 * <p>Having found the ancestor node "Y" with the href attribute (which also has a luid), the layout is rebuilt starting at that
		 * point (i.e. the XML with the top node having the href that includes the user's changes is processed pretty much as if
		 * a layout message was received with the new XML targetting that top node component.</p>
		 * 
		 * <p>If in save mode, the new XML is sent to the layout manager in a record with a special ruid="LM_REPLACE".  The layout manager
		 * looks up the href in the manifest and replaces the corresponding file's contents with the new XML.  Note that layout 
		 * XML files with sub parts that can be replaced by the layout manager have "include" statements, which indicate components 
		 * that have a luid and an href and that are populated
		 * from a separate XML file (generally for the purpose of swapping the layout XML for that component only using layout
		 * messages).  Therefore, the XML tree is also traversed toward the leaves, and all nodes containing an href that are descendents
		 * of ancestor node "Y" have all their child nodes stripped off, and its name is replaced with "LM:include", although
		 * they keep all their attributes (we are talking about a copy of the main layout XML that is to be sent
		 * to the layout manager, not the current layout XML used by GMX): e.g. [VBox href="fileX" luid="luidX" height="10"][Button/][VBox] would be replaced
		 * with [LM:include href="fileX" luid="luidX" height="10"/] (square brackets used instead of angled brackets due to asdoc conflict).
		 * Note that when the layout manager prepares a layout message, it always a replaces include nodes with a container component node (e.g. a VBox by default)
		 * that inherits all the attributes in the include node.  The XML file pointed to by the include node's href is then appended as a child
		 * (or children) of that container node.  i.e. by the time GMX gets the layout messages there are NEVER any include nodes.</p>
		 * 
		 * <p>Note that the XML that built component "X" was edited and it HAS an href, the only part of this function that changes is 
		 * for the save mode process:  the XML is traversed toward the root past the selected component "X"'s XML in order to find The nearest ancestor href such 
		 * that the changes made to component "X" can be applied to the LM:include that corresponds to it.</p>
		 * 
		 * <p>If the luid="mainLuid" component is the one that is edited by the user, no changes to any layout files are made b/c this top-level container
		 * is not contained in any files--it is created and sent by the layout manager.  This means the top level component is ALWAYS going to be a VBox with no 
		 * attributes except luid="mainLuid" and the href being whatever initial href was specified in the manifest.csv file used by the layout manager (assuming
		 * the layout is indeed being populated by the layout manager).  The user can change this in edit mode, but it will not be retained by the layout manager.</p>
		 */
		public static function appendedXMLUpdate():void {
			var i:int;
			var specificLuidToUpdate:String = null;
			if (_selectedXML != null) {
				var xmlContainingHref:XML = _selectedXML;
				var firstNodeHasHref:Boolean = true; 
				while (xmlContainingHref != null) {
					if (xmlContainingHref.@href == undefined) {
						// keep climbing the tree until a parent with an href attribute is found...
						// This parent is one that has a file that can be edited
						firstNodeHasHref = false;  
						xmlContainingHref = xmlContainingHref.parent();
						continue;  
					}
					
					// NOW THAT WE REACHED THIS POINT (i.e. we have found a parent containing the attribute @href):
					// make a copy of the XML, replace all it's children that have the @href attribute 
					// with corresponding include statements, and send the XML on to the layout manager to update the corresponding file
					
					// BUT FIRST -- figure the specific luid that changed so GMX Builder doesn't have to refresh everything.
					if (xmlContainingHref.@luid != undefined) { 
						specificLuidToUpdate = xmlContainingHref.@luid.toString();
						gmxBuilderInstance.rebuildSpecificLuid(specificLuidToUpdate, xmlContainingHref);
					}
					// DON'T CONTINUE IF NOT IN SAVE MODE!!!!
					if (!saveMode) { break; }
					//trace("BEFORE replacing includes: " + xmlContainingHref.toString());
					/*
					var nameSpaceDeclarations:Array = xmlContainingHref.namespaceDeclarations();
					trace("DECLARATIONS: " + nameSpaceDeclarations);
					for (i = 0; i < nameSpaceDeclarations.length; i++) {
						trace("DECLARATION!!!: " +nameSpaceDeclarations[i]);
						xmlContainingHref.addNamespace(nameSpaceDeclarations[i]);
					}
					*/
					if (firstNodeHasHref) {
						while (xmlContainingHref.parent().localName() != "topNode") {
							xmlContainingHref = xmlContainingHref.parent();
							if (xmlContainingHref.@href != undefined) { break; }
						}
					}
					xmlContainingHref = xmlContainingHref.copy();
					for (i = 0; i < xmlContainingHref.children().length(); i++) {
						replaceFileContainingChildrenXMLNodesWithIncludes(xmlContainingHref.children()[i]);
					}
					trace("AFTER replacing includes: " + xmlContainingHref.toString());
					//now send it
					var recordVO:RecordVO = new RecordVO();
					recordVO.ruid = "LM_REPLACE";
					var fieldVO:FieldVO = new FieldVO();
					fieldVO.fid = "LM_REPLACE";
					fieldVO.value = "<![CDATA[" + xmlContainingHref.toString() + "]]>";
					recordVO.fieldList = [fieldVO];
					GMXMain.do_ISISDataEdit([recordVO]);
					break;
				}
			}
			
			//trace("appendedXMLUpdate: _selectedXML: " + (_selectedXML != null ? _selectedXML.localName() : "") );
			var newText:String = xmlToStringWithTabs(_currentXML.children()); 
			try {
				if (gmxBuilderInstance.field != null) { 
					gmxBuilderInstance.field.value = newText;
					gmxBuilderInstance.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
				}
				gmxBuilderInstance.setXmlTextAreaText(newText);
			} catch (e:Error) {
				Alert.show("GMXBuilder updateButtonPressed XML Error: " + e.message);
				return;
			}
			if (specificLuidToUpdate == null) {
				// rebuild everything
				gmxBuilderInstance.rebuild();
			} // else we have already rebuilt it only starting at that luid -- see above
			
			gmxBuilderInstance.invalidateDisplayList();
		}
//================= END XML update functions ======================================================================
//=================================================================================================================
//=================================================================================================================		
//====== BEGIN IField implementation ==============================================================================
		public function get componentValue():String { 
			return _fieldValue;
		}
		public function set componentValue(val:String):void {
			return;
		}
		protected var _field:Field;
		public function get field():Field { return _field; }
		public function set field(newField:Field):void {
			_field = newField;
		}
		public function get fid():String { if (_field == null) return null; else return _field.fid; }
		public function set fid(val:String):void {
			if (GMXDictionaries.getCurrentRecord() == null) { return; }
			IFieldStandardImpl.setFid(this, val);
		}
		
		protected var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			IFieldStandardImpl.setRuid(this, val);
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set layout(val:String):void {
			IFieldStandardImpl.setLayout(val);
		}
//====== END IField implementation ================================================================================
//========= BEGIN ISelfBuilding Implementation ====================================================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			//_record = null;
			disintegrateChildren();
			//if (field == null) { return; }
			
			//_field.removeComponentRequiringUpdate(this);
			//_field = null;
		}
		public static function disintegrateChildren():void {
			var container:Container = DRAG_VERSION ? buildCanvas : buildArea;
			//trace("GMXMain BUILDER disintegrateChildren");
			for (var i:int = 0; i < container.numChildren; i++) {
				var childSelfBuilding:ISelfBuilding = container.getChildAt(i) as ISelfBuilding;
				if (childSelfBuilding == null) { continue; }
				//trace("GMXMain BUILDER disintegrateChild: " + childSelfBuilding);
				childSelfBuilding.disintegrate();
			}
			container.removeAllChildren();
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ======================================================================
//=================================================================================================================
//================= BEGIN XML TextArea Functions ==================================================================
		public function setXmlTextAreaText(val:String):void {
			var i:int;
			var tempString:String = "";
			var startIndex:int = val.length;
			var endIndex:int = val.length;
			for (i = val.length - 1; i >= 0; i--) {
				if (val.charAt(i) == ">") { startIndex = i + 1;  tempString = "&gt;" + val.substring(startIndex, endIndex) + tempString; endIndex = i; }
				else if (val.charAt(i) == "<") { startIndex = i + 1; tempString = "&lt;" + val.substring(startIndex, endIndex) + tempString; endIndex = i; }
				else if (val.charAt(i) == "\r" || val.charAt(i) == "\n") { startIndex = i + 1; tempString = "<br/>" + val.substring(startIndex, endIndex) + tempString; endIndex = i; }
			}
			tempString = val.substring(0, endIndex) + tempString;
			val = '<FONT FACE="Courier New" SIZE="11" COLOR="#000000">' + markupHtml(tempString) + '</FONT>';
			
			xmlTextArea.htmlText = val;
			
			while (_quoteIndexes.length > 0) { _quoteIndexes.pop(); }
			var textLength:int = xmlTextArea.htmlText.length;
			for (i = 0; i < textLength; i++) {
				if (xmlTextArea.htmlText.charAt(i) == '"') {
					_quoteIndexes.push(i);
				}
			}
		}
		
		/**
		 * Catches the tab so the text box does not lose focus, but rather it inserts a tab
		 * @param	event
		 */
		public function insertTab(event:FocusEvent):void {
			event.stopImmediatePropagation();
			event.preventDefault();
			var textField:TextField = getTextFieldFromTextArea(xmlTextArea);
			textField.replaceSelectedText("\t");
		}
		
		/**
		 * This converts an XMLList to a string with tabs instead of two spaces (actionscript's xml toString() function
		 * places 2 spaces for each level)
		 * @param	xmlList
		 * @return
		 */
		public static function xmlToStringWithTabs(xmlList:XMLList):String {
			var output:String = xmlList.toString();
			
			if (xmlList.length() == 1 && xmlList[0].children().length() == 0) {
				// For whatever reason, in this particular case, the XML.toString() function returns nothing, so I need to manually create the string
				// that represents the XML
				output = "<" + xmlList[0].localName();
				var attributes:XMLList = xmlList[0].attributes();
				for each (var attributeXML:XML in attributes) {
					output += ' ' + attributeXML.localName() + '="' + attributeXML + '"';
				}
				output += "/>";
				//trace("output: " + output);
			} else {
				var myPattern:RegExp = /  /g;
				output = output.replace(myPattern, "\t");
			}
			return output;
		}
		private function getTextFieldFromTextArea(textArea:TextArea):TextField {
			for (var i:int = 0; i < textArea.numChildren; i++) {
				var child:TextField = textArea.getChildAt(i) as TextField;
				if (child != null) {
					return child;
				}
			}
			return null;
		}
		
		/**
		 * This function converts a plain string into an HTML string with font formatting
		 * @param	val
		 * @return the html string with extra formatting
		 */
		private function markupHtml(val:String):String {
			var inQuote:Boolean = false;
			var startIndex:int = 0;
			var char:String;
			var newHTMLText:String = "";
			var fontOpeningTag:String = '<FONT FACE="Courier New" SIZE="11" COLOR="#FF0000">';
			var fontClosingTag:String = '</FONT>';
			
			//textField.setTextFormat(TEXT_FORMAT_DEFAULT);
			for (var i:int = 0; i < val.length; i++) {
				char = val.charAt(i);
				switch (char) {
					case '"':
						//trace("found one!");
						if (inQuote) {
							//endIndex = i + 1;
							newHTMLText += val.substring(startIndex, i + 1) + fontClosingTag;
							startIndex = i + 1;
							inQuote = false;
							//textField.setTextFormat(TEXT_FORMAT_QUOTE, startIndex, endIndex);
						} else {
							newHTMLText += val.substring(startIndex, i) + fontOpeningTag;
							startIndex = i;
							inQuote = true;
						}
						break;
					//case "<":
					//case ">":
					//case "/":
					//	if (!inQuote && (i + 1 <= textField.text.length)) { textField.setTextFormat(TEXT_FORMAT_BRACKET, i, i + 1); }
					//	break;					
				}
			}
			newHTMLText += val.substring(startIndex);
			if (inQuote) { // no end quote! this not good XML
				//textField.setTextFormat(TEXT_FORMAT_QUOTE, startIndex, textField.text.length);
				newHTMLText += fontClosingTag;
			}
			//trace("MARKUP COMPLETE newHTMLText: " + newHTMLText);
			//xmlTextArea.htmlText = newHTMLText;
			return newHTMLText;
		}
		
		
		private var undoStack:Vector.<String> = new Vector.<String>;
		private var undoIndex:int = 0;
		
		private var _enterPressed:Boolean = false;
		private var _prevBeginIndex:int = 0;
		private var _prevEndIndex:int = 0;
		private var _prevSelectedText:String;
		private var _latestCharPressed:String = " ";
		private var _latestKeyCodePressed:int = 0;
		private var _needMarkup:Boolean = false;
		private var _quoteIndexes:Vector.<int> = new Vector.<int>();
		
		// _pasted currently not being used... might want to do something with it some day
		private var _pasted:Boolean = false;
		
		private function markNewTextUsingExisting(beginIndex:int, endIndex:int):void {
			//trace("BEGIN INDEX: " + beginIndex);
			var textRange:TextRange = new TextRange(xmlTextArea, false, beginIndex - 1, beginIndex); //get the character just before
			var newColor:int = 0;
			if (textRange.text.charAt(0) == '"') {
				if (beginIndex == 1) { // you know it's a starting quote--new text should be red
					newColor = 0xff0000;
				} else { // need to check what the text before the quote was to determine if it is a start quote or end quote
					var previousTextRange:TextRange = new TextRange(xmlTextArea, false, beginIndex - 2, beginIndex - 1);
					if (previousTextRange.color == 0x000000) { // user typed in front of a starting quote--new text should be red
						newColor = 0xff0000;
					} else { // user typed in front of a ending quote--new text should be black
						newColor = 0x000000;
					}					
				}
			} else {
				newColor = 0 + textRange.color;
			}
			textRange = new TextRange(xmlTextArea, false, beginIndex, endIndex);
			textRange.color = newColor;
			textRange.fontSize = 11;
			textRange.fontFamily = "Courier New";
		}
		
		private function containsQuote(string:String):Boolean {
			for (var i:int = 0; i < string.length; i++) {
				if (string.charAt(i) == '"') {
					return true;
				}
			}
			return false;
		}
		
		public function addedText(event:Event):void {
			var newBeginIndex:int = xmlTextArea.selectionBeginIndex;
			var newEndIndex:int = xmlTextArea.selectionEndIndex;
			var textRange:TextRange;
			var i:int;
			
			if (_enterPressed) {
				// find out how many tabs were in the previous line
				var numTabs:int = 0;
				for (i = newBeginIndex - 2; i >= 0; i--) {
					var char:String = xmlTextArea.text.charAt(i);
					//trace(char);
					if (char == "\r" || char == "\n") {
						break;
					} else if (char == "\t") {
						numTabs++;
					}
				}
				var textField:TextField = getTextFieldFromTextArea(xmlTextArea);
				for (i = 0; i < numTabs; i++) {
					textField.replaceSelectedText("\t");
				}
				_enterPressed = false;
			}
			
			if (containsQuote(_prevSelectedText) || _needMarkup) {
				callLater(setXmlTextAreaText, [xmlTextArea.text]);
				_needMarkup = false;
				return;
			}
			
			if (_latestCharPressed == '"') { 
				setXmlTextAreaText(xmlTextArea.text);
			} else if (_prevBeginIndex > 0) {
				if (newBeginIndex - _prevBeginIndex > 1) { // pasted more than one character
					var pastedText:String = xmlTextArea.text.substring(_prevBeginIndex, newBeginIndex);
					var foundDoubleQuote:Boolean = false;
					if (containsQuote(pastedText)) {
						// if there's a double quote in the pasted stuff, redo all quotation color formatting
						foundDoubleQuote = true;
						callLater(setXmlTextAreaText, [xmlTextArea.text]);
					}
					if (!foundDoubleQuote) {
						// if there is NOT a double quote in the pasted stuff, make the pasted stuff be the same color as what came before
						markNewTextUsingExisting(_prevBeginIndex, newBeginIndex);
					}
				} else if (newBeginIndex - _prevBeginIndex == 1) { // one character added
					markNewTextUsingExisting(_prevBeginIndex, newBeginIndex);
				} else { 
					// do nothing
				}
			}
		}
		
		/**
		 * keyDown stores information regarding where the selector was before changes were made (so addedText function knows
		 * what to do) as well as takes care of cases where
		 * (1) ctrl key status is important
		 * (2) the text before changing must be analyzed (e.g. in the case of a BACKSPACE)
		 * 
		 * by the time the addedText function is reached, the text in the TextArea has already changed
		 * @param	event
		 */
		protected function keyDown(event:KeyboardEvent):void {
			_enterPressed = false;
			_latestCharPressed = String.fromCharCode(event.charCode);
			_prevBeginIndex = xmlTextArea.selectionBeginIndex;
			_prevEndIndex = xmlTextArea.selectionEndIndex;
			_prevSelectedText = xmlTextArea.text.substring(_prevBeginIndex, _prevEndIndex);
			_latestKeyCodePressed = event.keyCode;
			if (_prevSelectedText.length == 0) switch (_latestKeyCodePressed) {
				case Keyboard.DELETE:
					if (event.ctrlKey && event.shiftKey && _selectedObject != null) {
						
					} else if (xmlTextArea.text.length > _prevBeginIndex && xmlTextArea.text.charAt(_prevBeginIndex) == '"') {
						// flag that markup is required (see addedText function) since 
						_needMarkup = true;
					}
					break;
				case Keyboard.BACKSPACE:
					if (_prevBeginIndex > 0 && xmlTextArea.text.charAt(_prevBeginIndex - 1) == '"') {
						// flag that markup is required (see addedText function) since 
						_needMarkup = true;
					}
					break;
				case Keyboard.ENTER:
				//	trace("FOUND ENTER");
					if (event.shiftKey || event.ctrlKey) {
						updateButtonPressed(null);
					} else {_enterPressed = true; }					
					break;
			}
			return;
		}
//================= END XML TextArea Functions ====================================================================
//=================================================================================================================




		public static function enterEditMode():void {
			var currentMainLuid:ISelfBuilding = GMXDictionaries.getLuid("mainLuid");
			currentMainLuid.disintegrate();
			GMXMain.instance.removeAllChildren();
			var mainLuid:VBox_X = new VBox_X();
			GMXMain.instance.addChild(mainLuid);
			mainLuid.id = "mainLuid"
			mainLuid.setStyle("paddingLeft", 0);
			mainLuid.setStyle("paddingRight", 0);
			mainLuid.setStyle("paddingTop", 0);
			mainLuid.setStyle("paddingBottom", 0);
			mainLuid.setStyle("verticalGap", 0);
			mainLuid.record = new Record("mainRuid");
			GMXDictionaries.addLuid(mainLuid.id, mainLuid);
			//GMXDictionaries.addLuidXML(mainLuid.id, currentCompleteLayoutXML.children()[0]);
			GMXBuilder.gmxBuilderInstance.disintegrate();
			var topLevelNode:XML = GMXMain.currentCompleteLayoutXML.children()[0];
			//var formerLuid:String = topLevelNode.@luid.toString();
			//topLevelNode.@luid = "do not change (will be replaced with mainLuid)";
			GMXBuilder.gmxBuilderInstance.build(GMXMain.currentCompleteLayoutXML);
			//topLevelNode.@luid = formerLuid;
			mainLuid.addChild(GMXBuilder.gmxBuilderInstance);
		}
		
		public static function exitEditMode():Boolean {
			// use what is in the GMXBuilder's currentXML to build the screen... add the luid="mainLuid" to the top level node
			var currentXMLChildren:XMLList = currentXML.children();
			if (currentXMLChildren.length() > 1) {
				Alert.show("Cannot exit edit mode!  Your XML has more than 1 root node!");
				return false;
			} else if (currentXMLChildren.length() == 0) {
				Alert.show("Cannot exit edit mode!  Your XML has no root node!");
				return false;
			} else if (currentXMLChildren[0].@luid != "mainLuid") {
				Alert.show("Cannot exit edit mode!  Your XML's root node does not have luid=\"mainLuid\" (it is currently luid=\""+currentXMLChildren[0].@luid.toString()+"\"). Without that, the layout would not be displayed!!");
				return false;
			}
			
			
			GMXMain.builderHighlightPopUp.graphics.clear();
			
			GMXBuilder.gmxBuilderInstance.disintegrate();
			XMLDisplay.getXMLDisplay().visible = false;
			
			var layoutString:String = currentXMLChildren[0].toXMLString(); // includes start tag if it has no children
			GMXMain.instance.removeAllChildren();
			var mainLuid:VBox_X = new VBox_X();
			GMXMain.instance.addChild(mainLuid);
			mainLuid.id = "mainLuid"
			mainLuid.setStyle("paddingLeft", 0);
			mainLuid.setStyle("paddingRight", 0);
			mainLuid.setStyle("paddingTop", 0);
			mainLuid.setStyle("paddingBottom", 0);
			mainLuid.setStyle("verticalGap", 0);
			mainLuid.record = new Record("mainRuid");
			GMXDictionaries.addLuid(mainLuid.id, mainLuid);
			GMXMain.ISISLayout(layoutString);
			if (GMXBuilder.buildArea != null) { GMXBuilder.buildArea.removeAllChildren(); }
			if (GMXBuilder.buildCanvas != null) { GMXBuilder.buildCanvas.removeAllChildren(); }
			GMXMain.builderHighlightPopUp.graphics.clear();
			return true;
		}
		
		private function scrolled(event:Event):void {
			callLater(redrawHighlight);
		}
		
		override protected function commitProperties():void {
			if (this.field != null && this.field.value != xmlTextArea.htmlText) { 
				trace("GMXBuilder commit properties:  xmlTextArea text updated from field");
				setXmlTextAreaText(this.field.value);
				updateButtonPressed(null);
				invalidateDisplayList();
			}
			super.commitProperties();
		}
		
		override protected function createChildren():void {
			super.createChildren();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			var g:Graphics;
			g = textAreaAndBuildAreaResizer.graphics;
			g.clear();
			g.lineStyle(1, 0x666666);
			g.beginFill(0);
			g.drawRect(0, 0, textAreaAndBuildAreaResizer.width, textAreaAndBuildAreaResizer.height);
			g = buildAreaAndAttributeEditorResizer.graphics;
			g.clear();
			g.lineStyle(1, 0x666666);
			g.beginFill(0);
			g.drawRect(0, 0, buildAreaAndAttributeEditorResizer.width, buildAreaAndAttributeEditorResizer.height);
			
			if (_backgroundColorValue != -1) {
				this.graphics.clear();
				this.graphics.beginFill(_backgroundColorValue);
				
				if (!isNaN(this.width) && !isNaN(this.height)) {
					this.graphics.drawRect(0,0,this.width,this.height);
				}
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			redrawHighlight();
		}
				public static function redrawHighlight():void {
			GMXMain.builderHighlightPopUp.graphics.clear();
			if (_selectedObject == null) { return; }
			
			var g:Graphics = GMXMain.builderHighlightPopUp.graphics;
			g.clear();
			var builderHighlightPosition:Point = _selectedObject.localToGlobal(new Point(0, 0));
			g.lineStyle(3.0, 0xffff00, 0.8);
			g.drawRect(builderHighlightPosition.x, builderHighlightPosition.y, _selectedObject.width, _selectedObject.height);
		}
		
		public static function possibleDragOntoXMLSprite(event:MouseEvent):void {
			if (XMLSprite.draggingXMLSpriteIndex == null) { return; }
			
			var thisSprite:XMLSprite = event.target as XMLSprite;
			if (XMLSprite.draggingXMLSpriteIndex == thisSprite.index.substring(0, XMLSprite.draggingXMLSpriteIndex.length)) {
				Alert.show("WARNING: Cannot add an ancestor as a child of one of its descendents!  No change has been made.");
				GMXBuilder.appendedXMLUpdate();
				return;
			}
			
			// find the xml belonging to the dragged object
			var draggedSpriteXML:XML = GMXBuilder.xmlFinder(GMXBuilder.currentXML, XMLSprite.draggingXMLSpriteIndex, null, false);
			var thisSpriteXML:XML = GMXBuilder.xmlFinder(GMXBuilder.currentXML, thisSprite.index, null, false);
			var draggedSpriteSiblings:XMLList = draggedSpriteXML.parent().children();
			for (var i:int = 0; i < draggedSpriteSiblings.length(); i++) {
				if (draggedSpriteSiblings[i] == draggedSpriteXML) {
					delete draggedSpriteXML.parent().children()[i];
					break;
				}
			}
			
			GMXBuilder.appendedXMLUpdate();
			GMXBuilder.selectedObjectByIndex = thisSprite.index;
			thisSpriteXML.appendChild(draggedSpriteXML);
			GMXBuilder.appendedXMLUpdate();
		}
	}
}