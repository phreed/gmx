package gmx_builder.drawing_tool
{
	import fcs.components.CommandedBug;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ColorPicker;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	import mx.events.ColorPickerEvent;
	import mx.events.FlexEvent;
	import mx.managers.FocusManager;
	/**
	 * ...
	 * @author 
	 */
	public class ActionScriptGraphicsGenerator extends Canvas
	{
		public static var instance:ActionScriptGraphicsGenerator;
		
		private var _objectDictionary:Dictionary = new Dictionary();
		
		private var _canvas:UIComponent = new UIComponent();
		private var _canvasOriginMarker:UIComponent = new UIComponent();
		public function get canvasOriginPoint():Point { return new Point(_canvasOriginMarker.x, _canvasOriginMarker.y); }
		private var _tempGraphics:UIComponent = new UIComponent();
		private var _outputTextBox:TextArea = new TextArea();
		private var _toolBar:VBox = new VBox();
		
		private var _lineModeButton:Button = new Button();
		private var _circleModeButton:Button = new Button();
		private var _rectModeButton:Button = new Button();
		private var _lineColorPicker:ColorPicker = new ColorPicker();
		private var _lineThicknessBox:TextInput = new TextInput();
		private var _lineAlphaBox:TextInput = new TextInput();
		private var _fillColorPicker:ColorPicker = new ColorPicker();
		private var _fillAlphaBox:TextInput = new TextInput();
		private var _addFillButton:Button = new Button();
		private var _removeFillButton:Button = new Button();
		private var _setLineColorButton:Button = new Button();
		
		
		private var _selectedObject:GraphicObject;
		private var _currentMode:int = SELECT_MODE;
		
		private var _currentLineColor:String = "000000";
		private var _currentLineAlpha:String = "1.0";
		private var _currentLineThickness:String = "1.0";
		
		private var _currentFillColor:String = "000000";
		private var _currentFillAlpha:String = "1.0";
		
		private var _commandStack:CommandStack;
		
		private var _graphicObjects:ArrayCollection = new ArrayCollection();
		
		public static const SELECT_MODE:int = 0;
		public static const DRAW_LINE_MODE:int = 1;
		public static const DRAW_CIRCLE_MODE:int = 2;
		public static const DRAW_RECT_MODE:int = 3;
		
		// all the available commands
		public static const START_SELECT_MODE:String = "SSM";
		public static const END_SELECT_MODE:String = "ESM";
		public static const START_DRAW_LINE_MODE:String = "SDL";
		public static const END_DRAW_LINE_MODE:String = "EDL";
		public static const START_DRAW_CIRCLE_MODE:String = "SDC";
		public static const END_DRAW_CIRCLE_MODE:String = "EDC";
		public static const START_DRAW_RECT_MODE:String = "SDR";
		public static const END_DRAW_RECT_MODE:String = "EDR";
		
		public static const DROP_LINE_COLOR:String = "DLC";
		public static const NEW_LINE_COLOR:String = "NLC";
		public static const DROP_FILL_COLOR:String = "DFC";
		public static const NEW_FILL_COLOR:String = "NFC";
		
		public static const NEW_LINE:String = "NL";
		public static const DELETE_LINE:String = "DL";
		public static const NEW_CIRCLE:String = "NC";
		public static const DELETE_CIRCLE:String = "DC";
		public static const NEW_RECT:String = "NR";
		public static const DELETE_RECT:String = "DR";
		
		public static const DELETE_GRAPHIC_OBJECT:String = "DGO";
		public static const REATTACH_GRAPHIC_OBJECT:String = "RGO";
		
		public static const DESELECT_OBJECT:String = "DO";
		public static const SELECT_OBJECT:String = "SO";
		// after item is selected
		public static const ADD_FILL:String = "AF";
		public static const REMOVE_FILL:String = "RF";
		
		public static const SET_LINE_COLOR:String = "SLC";
		public static const RESET_LINE_COLOR:String = "RLC";
		
		public static const TRANSLATE_OBJECT:String = "TO";
		public static const UNTRANSLATE_OBJECT:String = "UTO";
		
		private var uidCounter:int = 0;
		public function newUid():String { return "uid" + uidCounter++; }
		
		public function ActionScriptGraphicsGenerator() {
			instance = this;
			this.setStyle("backgroundColor", 0xffffff);
			this.height = 600;
			this.width = 800;
			_commandStack = new CommandStack(this);
			
			var g:Graphics = _tempGraphics.graphics;
			
		}
		
		override protected function createChildren():void {
			super.createChildren();
			var g:Graphics;
			
			g = _canvasOriginMarker.graphics;
			g.lineStyle(1.0, 0, 1);
			g.beginFill(0xffffff, 0.4);
			g.drawCircle(0, 0, 3);
			
			_outputTextBox.width = 650;
			_outputTextBox.height = 100;
			_outputTextBox.verticalScrollPolicy = "auto";
			_outputTextBox.y = 500;
			_outputTextBox.editable = false;
			
			_canvasOriginMarker.addEventListener(MouseEvent.MOUSE_DOWN, originMouseDown);
			
			_toolBar.x = 650;
			_toolBar.width = 150;
			_toolBar.height = 600;
			_toolBar.setStyle("backgroundColor", 0xcccccc);
			_toolBar.setStyle("borderStyle", "solid");
			_toolBar.setStyle("borderThickness", 1);
			_toolBar.setStyle("borderColor", 0x000000);
			_toolBar.setStyle("paddingLeft", 5);
			_toolBar.setStyle("paddingTop", 5);
			_toolBar.setStyle("paddingRight", 5);
			_toolBar.setStyle("paddingBottom", 5);
			_toolBar.setStyle("horizontalAlign", "center");
			_toolBar.setStyle("verticalGap", 2);
			_toolBar.addEventListener(MouseEvent.MOUSE_DOWN, toolBarDown);
			_toolBar.horizontalScrollPolicy = "off";
			_toolBar.verticalScrollPolicy = "off";
						
			
			this.addChild(_canvas);
			this.addChild(_canvasOriginMarker);
			this.addChild(_outputTextBox);
			this.addChild(_toolBar);
			
			_lineModeButton.label = "Draw Line";
			_circleModeButton.label = "Draw Circle";
			_rectModeButton.label = "Draw Rect";
			_lineModeButton.toggle = true;
			_circleModeButton.toggle = true;
			_rectModeButton.toggle = true;
			_lineModeButton.addEventListener(MouseEvent.CLICK, lineModeClick);
			_circleModeButton.addEventListener(MouseEvent.CLICK, circleModeClick);
			_rectModeButton.addEventListener(MouseEvent.CLICK, rectModeClick);
			_addFillButton.addEventListener(MouseEvent.CLICK, addFillClick);
			_removeFillButton.addEventListener(MouseEvent.CLICK, removeFillClick);
			_setLineColorButton.addEventListener(MouseEvent.CLICK, setLineColorClick);
			_lineColorPicker.addEventListener(ColorPickerEvent.CHANGE, lineColorChange);
			_fillColorPicker.addEventListener(ColorPickerEvent.CHANGE, fillColorChange);
			_lineThicknessBox.addEventListener(FocusEvent.FOCUS_OUT, lineThicknessFocusOut);
			_lineThicknessBox.addEventListener(FlexEvent.ENTER, lineThicknessEnter);
			_lineAlphaBox.addEventListener(FocusEvent.FOCUS_OUT, lineAlphaFocusOut);
			_lineAlphaBox.addEventListener(FlexEvent.ENTER, lineAlphaEnter);
			_fillAlphaBox.addEventListener(FocusEvent.FOCUS_OUT, fillAlphaFocusOut);
			_fillAlphaBox.addEventListener(FlexEvent.ENTER, fillAlphaEnter);
			
			_addFillButton.label = "Add Fill";
			_removeFillButton.label = "Remove Fill";
			_setLineColorButton.label = "Set Linestyle";
			_toolBar.addChild(_lineModeButton);
			_toolBar.addChild(_circleModeButton);
			_toolBar.addChild(_rectModeButton);
			
			var toolHBox:HBox;
			var toolLabel:Label;
			toolLabel = new Label();
			toolHBox = new HBox();
			toolLabel.text = "Line Color:";
			toolHBox.addChild(toolLabel);
			toolHBox.addChild(_lineColorPicker);
			_toolBar.addChild(toolHBox);
			
			toolLabel = new Label();
			toolHBox = new HBox();
			toolLabel.text = "Line Thickness:";
			toolHBox.addChild(toolLabel);
			toolHBox.addChild(_lineThicknessBox);
			_lineThicknessBox.restrict = "0123456789.";
			_lineThicknessBox.maxChars = 4;
			_lineThicknessBox.text = "1.0";
			_toolBar.addChild(toolHBox);
			
			toolLabel = new Label();
			toolHBox = new HBox();
			toolLabel.text = "Line Alpha:";
			toolHBox.addChild(toolLabel);
			toolHBox.addChild(_lineAlphaBox);
			_lineAlphaBox.restrict = "0123456789.";
			_lineAlphaBox.maxChars = 4;
			_lineAlphaBox.toolTip = "0.00 - 1.00";
			_lineAlphaBox.text = "1.0";
			_toolBar.addChild(toolHBox);

			toolLabel = new Label();
			toolHBox = new HBox();
			toolLabel.text = "Fill Color:";
			toolHBox.addChild(toolLabel);
			toolHBox.addChild(_fillColorPicker);
			_toolBar.addChild(toolHBox);
			
			toolLabel = new Label();
			toolHBox = new HBox();
			toolLabel.text = "Fill Alpha:";
			toolHBox.addChild(toolLabel);
			toolHBox.addChild(_fillAlphaBox);
			_fillAlphaBox.restrict = "0123456789.";
			_fillAlphaBox.maxChars = 4;
			_fillAlphaBox.toolTip = "0.00 - 1.00";
			_fillAlphaBox.text = "1.0";
			_toolBar.addChild(toolHBox);
			
			
			_toolBar.addChild(_addFillButton);
			_toolBar.addChild(_removeFillButton);
			_toolBar.addChild(_setLineColorButton);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			this.addChild(_tempGraphics);
		}
		
		private function toolBarDown(event:MouseEvent):void {
			// don't let it get down to the canvas
			event.stopImmediatePropagation();
		}
		
		private function keyPressed(event:KeyboardEvent):void {
			if (!(event.target is UITextField)) {
				event.stopImmediatePropagation();
				this.setFocus();
			}
			
			var keyCode:int = event.keyCode;
			switch(keyCode) {
				case Keyboard.DELETE:
					if (_selectedObject == null) { return; }
					try {
						var selectedObjectIndex:int = _canvas.getChildIndex(_selectedObject);
						newCommand(formatCommandId(DELETE_GRAPHIC_OBJECT) + formatCommandParameter("id", _selectedObject.objectUid)
								+ formatCommandParameter("p", selectedObjectIndex + ""));
					} catch (e:Error) {
						trace("DELETE keyPressed error: " + e.message);
					}
					break;
				case Keyboard.ESCAPE:
					if (_selectedObject != null) {
						newCommand(formatCommandId(DESELECT_OBJECT) + formatCommandParameter("id", _selectedObject.objectUid));
					}
					if (_currentMode != SELECT_MODE) {
						addEndPreviousModeCommand();
						newCommand(formatCommandId(START_SELECT_MODE));
					}
					break;
				case Keyboard.ENTER:
					this.setFocus();				
					break;
				case Keyboard.LEFT: shiftGraphicObject(_selectedObject, -1, 0, event.shiftKey); break;
				case Keyboard.RIGHT: shiftGraphicObject(_selectedObject, 1, 0, event.shiftKey); break;
				case Keyboard.UP: shiftGraphicObject(_selectedObject, 0, -1, event.shiftKey); break;
				case Keyboard.DOWN: shiftGraphicObject(_selectedObject, 0, 1, event.shiftKey); break;
			}
			var char:String = String.fromCharCode(event.charCode);
			if (!event.ctrlKey) { return; }
			switch(char) {
				case "z": _commandStack.undoCommand(); event.stopImmediatePropagation(); this.setFocus(); break;
				case "y": _commandStack.redoCommand(); event.stopImmediatePropagation(); this.setFocus(); break;
				case "d": dumpActionScript(); event.stopImmediatePropagation(); this.setFocus(); break;
				case "s": dumpSVG(); event.stopImmediatePropagation(); this.setFocus(); break;
			}
		}
		
		private function originMouseDown(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			event.stopImmediatePropagation();
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, originMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, originMouseUp);
		}
		
		private function originMouseMove(event:MouseEvent):void {
			//_canvas.x = this.mouseX;
			//_canvas.y = this.mouseY;
			var displaceX:Number = this.mouseX - _canvasOriginMarker.x;
			var displaceY:Number = this.mouseY - _canvasOriginMarker.y;
			_canvasOriginMarker.x = this.mouseX;
			_canvasOriginMarker.y = this.mouseY;
			// displace all graphic points by this amount
			// NEED TO FIGURE THIS OUT SOME TIME... do we go through all the commands?
			//  maybe have a special "origin shift" command or something
		}
		
		private function originMouseUp(event:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, originMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, originMouseUp);
		}
		
		
		
//=========================================================================================================================
//=========================================================================================================================
//================= BEGIN EVENT HANDLERS ==================================================================================
		// Note: the last mode that it was in
		// needs to be pushed onto the command stack--e.g. if
		// mode was changed from SDL (draw line mode) to SDR (draw rect mode)
		// then I would want to push an EDL message on (end draw line mode)
		// so that in the case of an undo, we know which mode to go back into
		private function lineModeClick(event:MouseEvent):void {
			addEndPreviousModeCommand(); // also takes care of case of _lineModeButton being de-selected
			if (_currentMode == DRAW_LINE_MODE) {  // it was deselected
				newCommand(formatCommandId(START_SELECT_MODE));
			} else { // it was selected
				newCommand(formatCommandId(START_DRAW_LINE_MODE));
			}
		}
		private function circleModeClick(event:MouseEvent):void {
			
			addEndPreviousModeCommand(); // also takes care of case of _rectModeButton being de-selected
			if (_currentMode == DRAW_CIRCLE_MODE) {  // it was deselected
				newCommand(formatCommandId(START_SELECT_MODE));
			} else { // it was selected
				newCommand(formatCommandId(START_DRAW_CIRCLE_MODE));
			}
		}
		private function rectModeClick(event:MouseEvent):void {
			addEndPreviousModeCommand(); // also takes care of case of _rectModeButton being de-selected
			if (_currentMode == DRAW_RECT_MODE) {  // it was deselected
				newCommand(formatCommandId(START_SELECT_MODE));
			} else { // it was selected
				newCommand(formatCommandId(START_DRAW_RECT_MODE));
			}
		}
		private function addCurrentLineColorCommand():void {
			var prevColorCommand:String = "";
			prevColorCommand += formatCommandId(DROP_LINE_COLOR);
			prevColorCommand += formatCommandParameter("t", _currentLineThickness);
			prevColorCommand += formatCommandParameter("c", _currentLineColor);
			prevColorCommand += formatCommandParameter("a", _currentLineAlpha);
			_commandStack.addCommand(prevColorCommand);
		}
		private function addCurrentFillColorCommand():void {
			var prevColorCommand:String = "";
			prevColorCommand += formatCommandId(DROP_FILL_COLOR);
			prevColorCommand += formatCommandParameter("c", _currentFillColor);
			prevColorCommand += formatCommandParameter("a", _currentFillAlpha);
			_commandStack.addCommand(prevColorCommand);
		}
		private function lineThicknessFocusOut(event:FocusEvent):void { lineThicknessEnter(null); }
		private function lineThicknessEnter(event:FlexEvent):void { 
			var newVal:Number = parseFloat(_lineThicknessBox.text);
			if (isNaN(newVal)) { _lineThicknessBox.text = _currentLineThickness + ""; return; }
			addCurrentLineColorCommand();
			var lineColorChangeCommand:String = "";
			lineColorChangeCommand += formatCommandId(NEW_LINE_COLOR);
			lineColorChangeCommand += formatCommandParameter("t", newVal + "");
			lineColorChangeCommand += formatCommandParameter("c", _currentLineColor + "");
			lineColorChangeCommand += formatCommandParameter("a", _currentLineAlpha + "");
			newCommand(lineColorChangeCommand);
		}
		private function lineAlphaFocusOut(event:FocusEvent):void { lineAlphaEnter(null);  }
		private function lineAlphaEnter(event:FlexEvent):void { 
			var newVal:Number = parseFloat(_lineAlphaBox.text);
			if (isNaN(newVal)) { _lineAlphaBox.text = _currentLineAlpha + ""; return; }
			if (newVal > 1) { newVal = 1; }
			var lineColorChangeCommand:String = "";
			addCurrentLineColorCommand();
			lineColorChangeCommand += formatCommandId(NEW_LINE_COLOR);
			lineColorChangeCommand += formatCommandParameter("t", _currentLineThickness + "");
			lineColorChangeCommand += formatCommandParameter("c", _currentLineColor + "");
			lineColorChangeCommand += formatCommandParameter("a", newVal + "");
			newCommand(lineColorChangeCommand);
		}
		private function fillAlphaFocusOut(event:FocusEvent):void { fillAlphaEnter(null); }
		private function fillAlphaEnter(event:FlexEvent):void { 
			var newVal:Number = parseFloat(_fillAlphaBox.text);
			if (isNaN(newVal)) { _fillAlphaBox.text = _currentFillAlpha + ""; return; }
			if (newVal > 1) { newVal = 1; }
			addCurrentLineColorCommand();
			var fillColorChangeCommand:String = "";
			fillColorChangeCommand += formatCommandId(NEW_FILL_COLOR);
			fillColorChangeCommand += formatCommandParameter("c", _currentFillColor + "");
			fillColorChangeCommand += formatCommandParameter("a", newVal + "");
			newCommand(fillColorChangeCommand);
		}
		private function addFillClick(event:MouseEvent):void {
			if (_selectedObject == null) { return; }
			var addFillCommand:String = formatCommandId(ADD_FILL);
			addFillCommand += formatCommandParameter("id", _selectedObject.objectUid);
			// the color and alpha of the object are retained just for retaining a record of what was in the object
			// in order to do undo / redo commands (uc = undo color, ua = undo alpha is used by REMOVE_FILL)
			addFillCommand += formatCommandParameter("uc", _selectedObject.fillColor.toString(16));
			addFillCommand += formatCommandParameter("ua", _selectedObject.fillAlpha + "");
			addFillCommand += formatCommandParameter("c", _currentFillColor);
			addFillCommand += formatCommandParameter("a", _currentFillAlpha);
			newCommand(addFillCommand);
		}
		private function removeFillClick(event:MouseEvent):void {
			if (_selectedObject == null) { return; }
			var removeFillCommand:String = formatCommandId(REMOVE_FILL);
			removeFillCommand += formatCommandParameter("id", _selectedObject.objectUid);
			// the color and alpha of the object are retained just for retaining a record of what was in the object
			// in order to do undo / redo commands (uc = undo color, ua = undo alpha is used by REMOVE_FILL)
			removeFillCommand += formatCommandParameter("uc", -1.0 + "");
			removeFillCommand += formatCommandParameter("ua", 1.0 + "");
			removeFillCommand += formatCommandParameter("c", _selectedObject.fillColor.toString(16));
			removeFillCommand += formatCommandParameter("a", _selectedObject.fillAlpha + "");
			newCommand(removeFillCommand);
		}
		private function setLineColorClick(event:MouseEvent):void {
			if (_selectedObject == null) { return; }
			var setLineColorCommand:String = "";
			setLineColorCommand += formatCommandId(SET_LINE_COLOR);
			setLineColorCommand += formatCommandParameter("id", _selectedObject.objectUid);
			setLineColorCommand += formatCommandParameter("c", _currentLineColor);
			setLineColorCommand += formatCommandParameter("a", _currentLineAlpha);
			setLineColorCommand += formatCommandParameter("t", _currentLineThickness);
			setLineColorCommand += formatCommandParameter("uc", _selectedObject.getLineStyle().color.toString(16) + "");
			setLineColorCommand += formatCommandParameter("ua", _selectedObject.getLineStyle().alpha + "");
			setLineColorCommand += formatCommandParameter("ut", _selectedObject.getLineStyle().thickness + "");
			newCommand(setLineColorCommand);
		}
		private function addEndPreviousModeCommand():void {
			if (_currentMode == SELECT_MODE && _selectedObject != null) {
				newCommand(formatCommandId(DESELECT_OBJECT) + formatCommandParameter("id", _selectedObject.objectUid));
			}
			switch (_currentMode) {
				case SELECT_MODE: newCommand(formatCommandId(END_SELECT_MODE)); break;
				case DRAW_LINE_MODE: newCommand(formatCommandId(END_DRAW_LINE_MODE)); break;
				case DRAW_CIRCLE_MODE: newCommand(formatCommandId(END_DRAW_CIRCLE_MODE)); break;				
				case DRAW_RECT_MODE: newCommand(formatCommandId(END_DRAW_RECT_MODE)); break;
			}
		}
		
		private function lineColorChange(event:ColorPickerEvent):void {
			addCurrentLineColorCommand();
			var lineColorChangeCommand:String = "";
			lineColorChangeCommand += formatCommandId(NEW_LINE_COLOR);
			lineColorChangeCommand += formatCommandParameter("t", _currentLineThickness);
			lineColorChangeCommand += formatCommandParameter("c", event.color.toString(16));
			lineColorChangeCommand += formatCommandParameter("a", _currentLineAlpha);
			newCommand(lineColorChangeCommand);
		}
		private function fillColorChange(event:ColorPickerEvent):void {
			addCurrentFillColorCommand();
			newCommand(formatCommandId(NEW_FILL_COLOR) + formatCommandParameter("c", event.color.toString(16)) + formatCommandParameter("a", _currentFillAlpha));
		}
		
		
		private var _listeningGraphics:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		private function changeToSelectMode():void {
			_currentMode = SELECT_MODE;
			_listeningGraphics = new Vector.<DisplayObject>();
			for (var i:int = 0; i < _canvas.numChildren; i++) {
				_listeningGraphics.push(_canvas.getChildAt(i));
				_canvas.getChildAt(i).addEventListener(MouseEvent.CLICK, selectClick);
			}
			if (_lineModeButton.selected) { _lineModeButton.selected = false; }
			if (_rectModeButton.selected) { _rectModeButton.selected = false; }
			if (_circleModeButton.selected) { _circleModeButton.selected = false; }
			// add listeners specific to this mode
		}
		private function changeToDrawLineMode():void {
			firstLineDown = true; // adds the "move to" command in there
			_currentMode = DRAW_LINE_MODE;
			_lineModeButton.selected = true;
			if (_circleModeButton.selected) { _circleModeButton.selected = false; }
			if (_rectModeButton.selected) { _rectModeButton.selected = false; }
			// add listeners specific to this mode
			this.addEventListener(MouseEvent.MOUSE_DOWN, drawLineDown);
		}
		private function changeToDrawCircleMode():void {
			_currentMode = DRAW_CIRCLE_MODE;
			_circleModeButton.selected = true;
			if (_lineModeButton.selected) { _lineModeButton.selected = false; }
			if (_rectModeButton.selected) { _rectModeButton.selected = false; }
			// add listeners specific to this mode
			this.addEventListener(MouseEvent.MOUSE_DOWN, drawCircleDown);
		}
		private function changeToDrawRectMode():void {
			_currentMode = DRAW_RECT_MODE;
			_rectModeButton.selected = true;
			if (_circleModeButton.selected) { _circleModeButton.selected = false; }
			if (_lineModeButton.selected) { _lineModeButton.selected = false; }
			// add listeners specific to this mode
			this.addEventListener(MouseEvent.MOUSE_DOWN, drawRectDown);
		}
		private function removeAllListeners():void {
			while (_listeningGraphics.length != 0) {
				_listeningGraphics.pop().removeEventListener(MouseEvent.CLICK, selectClick);
			}
			this.removeEventListener(MouseEvent.MOUSE_DOWN, drawLineDown);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, drawCircleDown);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, drawRectDown);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawRectMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawRectUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawLineMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawLineUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawCircleMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawCircleUp);
		}
		
		private function selectClick(event:MouseEvent):void {
			if (_selectedObject != null) {
				if (_selectedObject == event.target) { return; }
				newCommand(formatCommandId(DESELECT_OBJECT) + formatCommandParameter("id", _selectedObject.objectUid));
			}
			this.setFocus();
			var newSelectedObject:GraphicObject = event.target as GraphicObject;
			newCommand(formatCommandId(SELECT_OBJECT) + formatCommandParameter("id", newSelectedObject.objectUid));
		}
		
		public static var firstLineDown:Boolean = true;
		private var _mouseClickOrigin:Point;
		private var _mouseClickEnding:Point;
		private var _currentGraphicId:String;
		private function drawLineDown(event:MouseEvent):void {
			if (firstLineDown) {
				firstLineDown = false;
				var canvasPoint:Point = _canvas.globalToContent(this.contentToGlobal(new Point(mouseX, mouseY)));
				_currentGraphicId = newUid();
				newCommand(formatCommandId(NEW_LINE) + formatCommandParameter("id", _currentGraphicId) +
						formatCommandParameter("x", canvasPoint.x + "") + formatCommandParameter("y", canvasPoint.y + ""));
				_mouseClickOrigin = new Point(mouseX, mouseY);
			} else {
				_mouseClickOrigin = _mouseClickEnding;
			}
			stage.addEventListener(MouseEvent.MOUSE_MOVE, drawLineMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, drawLineUp);
			
		}
		
		private function drawLineMove(event:MouseEvent):void {
			var g:Graphics = _tempGraphics.graphics;
			g.clear();
			g.lineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor,16),parseFloat(_currentLineAlpha));
			g.moveTo(_mouseClickOrigin.x, _mouseClickOrigin.y);
			g.lineTo(mouseX, mouseY);
		}
		
		private function drawLineUp(event:MouseEvent):void {
			_tempGraphics.graphics.clear();
			_mouseClickEnding = new Point(mouseX, mouseY);
			var canvasPoint:Point = _canvas.globalToContent(this.contentToGlobal(new Point(mouseX, mouseY)));
			var newLineCommand:String = formatCommandId(NEW_LINE);
			newLineCommand += formatCommandParameter("id", _currentGraphicId);
			newLineCommand += formatCommandParameter("x", canvasPoint.x + "");
			newLineCommand += formatCommandParameter("y", canvasPoint.y + "");
			newCommand(newLineCommand);
			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawLineMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawLineUp);
		}
		
		private function drawCircleDown(event:MouseEvent):void {
			_currentGraphicId = newUid();
			_mouseClickOrigin = new Point(mouseX, mouseY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, drawCircleMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, drawCircleUp);
		}
		
		private function drawCircleMove(event:MouseEvent):void {
			var radius:Number = Point.distance(_mouseClickOrigin, new Point(mouseX, mouseY));
			var g:Graphics = _tempGraphics.graphics;
			g.clear();
			g.lineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor, 16), parseFloat(_currentLineAlpha));
			g.drawCircle(_mouseClickOrigin.x, _mouseClickOrigin.y, radius);
		}
		
		private function drawCircleUp(event:MouseEvent):void {
			_tempGraphics.graphics.clear();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawCircleMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawCircleUp);
			if (_mouseClickOrigin.equals(new Point(mouseX, mouseY))) { return; }
			var radius:Number = Math.round(Point.distance(_mouseClickOrigin, new Point(mouseX, mouseY)) * 10) / 10.0;
			var canvasPoint:Point = _canvas.globalToContent(this.contentToGlobal(_mouseClickOrigin));
			var newCircleCommand:String = formatCommandId(NEW_CIRCLE);
			newCircleCommand += formatCommandParameter("id", _currentGraphicId);
			newCircleCommand += formatCommandParameter("x", canvasPoint.x + "");
			newCircleCommand += formatCommandParameter("y", canvasPoint.y + "");
			newCircleCommand += formatCommandParameter("r", radius + "");
			newCommand(newCircleCommand);
		}
		
		private function drawRectDown(event:MouseEvent):void {
			_currentGraphicId = newUid();
			_mouseClickOrigin = new Point(mouseX, mouseY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, drawRectMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, drawRectUp);
		}
		
		private function drawRectMove(event:MouseEvent):void {
			var g:Graphics = _tempGraphics.graphics;
			g.clear();
			g.lineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor, 16), parseFloat(_currentLineAlpha));
			var rectOrigin:Point;
			if (mouseX < _mouseClickOrigin.x && mouseY < _mouseClickOrigin.y) {
				rectOrigin = new Point(mouseX, mouseY);
			} else if (mouseX < _mouseClickOrigin.x) {
				rectOrigin = new Point(mouseX, _mouseClickOrigin.y);
			} else if (mouseY < _mouseClickOrigin.y) {
				rectOrigin = new Point(_mouseClickOrigin.x, mouseY);
			} else {
				rectOrigin = _mouseClickOrigin;
			}
			var rectWidth:Number = Math.abs(mouseX - _mouseClickOrigin.x);
			var rectHeight:Number = Math.abs(mouseY - _mouseClickOrigin.y);
			g.drawRect(rectOrigin.x, rectOrigin.y, rectWidth, rectHeight);
		}
		
		private function drawRectUp(event:MouseEvent):void {
			_tempGraphics.graphics.clear();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawRectMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, drawRectUp);
			if (_mouseClickOrigin.equals(new Point(mouseX, mouseY))) { return; }
			var rectOrigin:Point;
			if (mouseX < _mouseClickOrigin.x && mouseY < _mouseClickOrigin.y) {
				rectOrigin = new Point(mouseX, mouseY);
			} else if (mouseX < _mouseClickOrigin.x) {
				rectOrigin = new Point(mouseX, _mouseClickOrigin.y);
			} else if (mouseY < _mouseClickOrigin.y) {
				rectOrigin = new Point(_mouseClickOrigin.x, mouseY);
			} else {
				rectOrigin = _mouseClickOrigin;
			}
			var rectWidth:Number = Math.abs(mouseX - _mouseClickOrigin.x);
			var rectHeight:Number = Math.abs(mouseY - _mouseClickOrigin.y);
			var canvasPoint:Point = _canvas.globalToContent(this.contentToGlobal(rectOrigin));
			var newRectCommand:String = formatCommandId(NEW_RECT);
			newRectCommand += formatCommandParameter("id", _currentGraphicId);
			newRectCommand += formatCommandParameter("x", canvasPoint.x + "");
			newRectCommand += formatCommandParameter("y", canvasPoint.y + "");
			newRectCommand += formatCommandParameter("w", rectWidth + "");
			newRectCommand += formatCommandParameter("h", rectHeight + "");
			newCommand(newRectCommand);
		}
//================= END EVENT LISTENERS ===================================================================================
//=========================================================================================================================
//=========================================================================================================================
//=========================================================================================================================
//================= BEGIN COMMAND HANDLERS ================================================================================

		public function newCommand(command:String):void {
			_commandStack.addCommand(command);
			executeCommand(command);
		}
		
		public function executeCommand(command:String):Boolean {
			var param_set:Vector.<String> = GMXMain.splitter(command);
			if (param_set.length < 1) { trace("msg has no action"); return false; }
			trace("execute command: "+command);
			var action:String = param_set.shift();
			try {
				switch (action) {
					case DELETE_GRAPHIC_OBJECT: handleDeleteObject(parseCommandParameters(param_set)); break;
					case REATTACH_GRAPHIC_OBJECT: handleReattachObject(parseCommandParameters(param_set)); break;
					
					case START_SELECT_MODE: removeAllListeners(); changeToSelectMode();  break;
					case START_DRAW_LINE_MODE: removeAllListeners(); changeToDrawLineMode();  break;
					case START_DRAW_CIRCLE_MODE: removeAllListeners(); changeToDrawCircleMode(); break;
					case START_DRAW_RECT_MODE: removeAllListeners(); changeToDrawRectMode(); break;
					
					case END_DRAW_LINE_MODE:
					case END_SELECT_MODE:
					case END_DRAW_CIRCLE_MODE:
					case END_DRAW_RECT_MODE:
					case DROP_LINE_COLOR:
					case DROP_FILL_COLOR:
						break; // these are just for the command stack.  You should always be in a mode
							// the default being select mode.  You should always have a line color
							// or a fill color
					
					case NEW_LINE_COLOR: handleNewLineColor(parseCommandParameters(param_set)); break;
					case NEW_FILL_COLOR: handleNewFillColor(parseCommandParameters(param_set)); break;
					
					case NEW_LINE: handleNewLine(parseCommandParameters(param_set)); break;
					case DELETE_LINE: handleDeleteLine(parseCommandParameters(param_set)); break;
					case NEW_CIRCLE: handleNewCircle(parseCommandParameters(param_set)); break;
					case DELETE_CIRCLE: handleDeleteCircle(parseCommandParameters(param_set)); break;
					case NEW_RECT: handleNewRect(parseCommandParameters(param_set));  break;
					case DELETE_RECT: handleDeleteRect(parseCommandParameters(param_set));  break;
		
					case DESELECT_OBJECT: handleDeselectObject(parseCommandParameters(param_set)); break;
					case SELECT_OBJECT: handleSelectObject(parseCommandParameters(param_set)); break;
					case ADD_FILL: handleAddFill(parseCommandParameters(param_set)); break;
					case REMOVE_FILL: handleRemoveFill(parseCommandParameters(param_set)); break;
					case SET_LINE_COLOR: handleSetLineColor(parseCommandParameters(param_set)); break;
					case RESET_LINE_COLOR: handleResetLineColor(parseCommandParameters(param_set)); break;
					
					case TRANSLATE_OBJECT: handleTranslateObject(parseCommandParameters(param_set)); break;
					case UNTRANSLATE_OBJECT: handleUntranslateObject(parseCommandParameters(param_set)); break;
					
					default: trace("action " + action + " not defined in: " + command);
						return false;
				} 
			} catch (ex:Error) {
				Alert.show("Incoming message: " + command + " caused the error: " + ex.message);
				return false;
			}
			return true;
		}
		
		public function executeInverseCommand(command:String):Boolean {
			trace("execute inverse command: " + command);
			var param_set:Vector.<String> = GMXMain.splitter(command);
			if (param_set.length < 1) { trace("msg has no action"); return false; }
			var action:String = param_set.shift();
			// alter the command based on what it is
			try {
				switch (action) {
					case DELETE_GRAPHIC_OBJECT: command = command.replace(DELETE_GRAPHIC_OBJECT,REATTACH_GRAPHIC_OBJECT); break;
					case REATTACH_GRAPHIC_OBJECT: command = command.replace(REATTACH_GRAPHIC_OBJECT,DELETE_GRAPHIC_OBJECT); break;
					
					case START_SELECT_MODE: command = command.replace(START_SELECT_MODE,END_SELECT_MODE); break;
					case END_SELECT_MODE: command = command.replace(END_SELECT_MODE,START_SELECT_MODE); break;
					case START_DRAW_LINE_MODE: command = command.replace(START_DRAW_LINE_MODE,END_DRAW_LINE_MODE); break;
					case END_DRAW_LINE_MODE: command = command.replace(END_DRAW_LINE_MODE,START_DRAW_LINE_MODE); break;
					case START_DRAW_CIRCLE_MODE: command = command.replace(START_DRAW_CIRCLE_MODE,END_DRAW_CIRCLE_MODE); break;
					case END_DRAW_CIRCLE_MODE: command = command.replace(END_DRAW_CIRCLE_MODE,START_DRAW_CIRCLE_MODE); break;
					case START_DRAW_RECT_MODE: command = command.replace(START_DRAW_RECT_MODE,END_DRAW_RECT_MODE); break;
					case END_DRAW_RECT_MODE: command = command.replace(END_DRAW_RECT_MODE,START_DRAW_RECT_MODE); break;
					
					case DROP_LINE_COLOR: command = command.replace(DROP_LINE_COLOR,NEW_LINE_COLOR); break;
					case NEW_LINE_COLOR: command = command.replace(NEW_LINE_COLOR,DROP_LINE_COLOR); break;
					case DROP_FILL_COLOR: command = command.replace(DROP_FILL_COLOR,NEW_FILL_COLOR); break;
					case NEW_FILL_COLOR: command = command.replace(NEW_FILL_COLOR, DROP_FILL_COLOR); break;
					
					case NEW_LINE: command = command.replace(NEW_LINE,DELETE_LINE); break;
					case DELETE_LINE: command = command.replace(DELETE_LINE,NEW_LINE); break;
					case NEW_CIRCLE: command = command.replace(NEW_CIRCLE,DELETE_CIRCLE); break;
					case DELETE_CIRCLE: command = command.replace(DELETE_CIRCLE,NEW_CIRCLE); break;
					case NEW_RECT: command = command.replace(NEW_RECT,DELETE_RECT); break;
					case DELETE_RECT: command = command.replace(DELETE_RECT,NEW_RECT); break;
		
					case DESELECT_OBJECT: command = command.replace(DESELECT_OBJECT,SELECT_OBJECT); break;
					case SELECT_OBJECT: command = command.replace(SELECT_OBJECT,DESELECT_OBJECT); break;
					case ADD_FILL: command = command.replace(ADD_FILL,REMOVE_FILL); break;
					case REMOVE_FILL: command = command.replace(REMOVE_FILL, ADD_FILL); break;
					case SET_LINE_COLOR: command = command.replace(SET_LINE_COLOR, RESET_LINE_COLOR); break;
					case RESET_LINE_COLOR: command = command.replace(RESET_LINE_COLOR, SET_LINE_COLOR); break;
					
					case TRANSLATE_OBJECT: command = command.replace(TRANSLATE_OBJECT, UNTRANSLATE_OBJECT); break;
					case UNTRANSLATE_OBJECT: command = command.replace(UNTRANSLATE_OBJECT, TRANSLATE_OBJECT); break;
					
					default: trace("action " + action + " not defined in: " + command);
						return false;
				} 
			} catch (ex:Error) {
				Alert.show("Incoming message: " + command + " caused the error: " + ex.message);
				return false;
			}
			return executeCommand(command);
		}
		
		private function handleNewLine(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			var i:int;
			for (i = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewLine ERROR: id was not set correctly");
				return;
			}
			var line:GraphicLine = _objectDictionary[idVal];
			if (line == null) {
				// it's a new line
				line = new GraphicLine(idVal);
				_objectDictionary[idVal] = line;
				_canvas.addChild(line);
				_graphicObjects.addItem(line);
			}
			for (i = 0; i < _canvas.numChildren; i++) {
				// if it's not a child of the _canvas, add it as one
				if (_canvas.getChildAt(i) == line) break;
				if (i == _canvas.numChildren - 1) _canvas.addChild(line);
			}
			
			line.addPoint(new Point(xVal, yVal));
			line.addLineStyle(new GraphicLineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor, 16), parseFloat(_currentLineAlpha)));
			line.invalidateDisplayList();
		}
		private function handleDeleteLine(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewLine ERROR: id was not set correctly");
				return;
			}
			var line:GraphicLine = _objectDictionary[idVal];
			if (line == null) {
				Alert.show("ERROR: handleDeleteLine, line with id=" + idVal + " did not exist as a line in dictionary!");
				return;
			}
			line.removePoint(new Point(xVal, yVal));
			var lastPoint:Point = line.getLastPointCopy();
			if (lastPoint != null) {
				_mouseClickEnding = lastPoint;
			}
		}
		private function handleNewCircle(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			var rVal:Number;
			var i:int;
			for (i = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
					case "r": rVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewCircle ERROR: id was not set correctly");
				return;
			}
			var circle:GraphicCircle = _objectDictionary[idVal];
			if (circle == null) {
				// it's a new line
				circle = new GraphicCircle(idVal);
				_objectDictionary[idVal] = circle;
				_canvas.addChild(circle);
				_graphicObjects.addItem(circle);
			}
			for (i = 0; i < _canvas.numChildren; i++) {
				// if it's not a child of the _canvas, add it as one
				if (_canvas.getChildAt(i) == circle) break;
				if (i == _canvas.numChildren - 1) _canvas.addChild(circle);
			}
			
			circle.center = new Point(xVal, yVal);
			circle.radius = rVal;
			circle.setLineStyle(new GraphicLineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor, 16), parseFloat(_currentLineAlpha)));
			circle.invalidateDisplayList();
		}
		private function handleDeleteCircle(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			var rVal:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
					case "r": rVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewLine ERROR: id was not set correctly");
				return;
			}
			var circle:GraphicCircle = _objectDictionary[idVal];
			if (circle == null) {
				Alert.show("ERROR: handleDeleteCircle, line with id=" + idVal + " did not exist as a circle in dictionary!");
				return;
			}
			circle.clear();
		}
		private function handleNewRect(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			var wVal:Number;
			var hVal:Number;
			var i:int;
			for (i = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
					case "w": wVal = parseFloat(command_params[i].val); break;
					case "h": hVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewCircle ERROR: id was not set correctly");
				return;
			}
			var rect:GraphicRect = _objectDictionary[idVal];
			if (rect == null) {
				// it's a new line
				rect = new GraphicRect(idVal);
				_objectDictionary[idVal] = rect;
				_canvas.addChild(rect);
				_graphicObjects.addItem(rect);
			}
			for (i = 0; i < _canvas.numChildren; i++) {
				// if it's not a child of the _canvas, add it as one
				if (_canvas.getChildAt(i) == rect) break;
				if (i == _canvas.numChildren - 1) _canvas.addChild(rect);
			}
			
			rect.origin = new Point(xVal, yVal);
			rect.rectWidth = wVal;
			rect.rectHeight = hVal;
			rect.setLineStyle(new GraphicLineStyle(parseFloat(_currentLineThickness), parseInt(_currentLineColor, 16), parseFloat(_currentLineAlpha)));
			rect.invalidateDisplayList();
		}
		private function handleDeleteRect(command_params:Vector.<CommandParameter>):void {
			var idVal:String;
			var xVal:Number;
			var yVal:Number;
			var wVal:Number;
			var hVal:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id":idVal = command_params[i].val; break;
					case "x": xVal = parseFloat(command_params[i].val); break;
					case "y": yVal = parseFloat(command_params[i].val); break;
					case "w": wVal = parseFloat(command_params[i].val); break;
					case "h": hVal = parseFloat(command_params[i].val); break;
				}
			}
			if (idVal == null) {
				Alert.show("handleNewLine ERROR: id was not set correctly");
				return;
			}
			var rect:GraphicRect = _objectDictionary[idVal];
			if (rect == null) {
				Alert.show("ERROR: handleDeleteRect, line with id=" + idVal + " did not exist as a rect in dictionary!");
				return;
			}
			rect.clear();
		}
		
		private function handleNewLineColor(command_params:Vector.<CommandParameter>):void {
			var color:int = -1;
			var alpha:Number = 1.0;
			var thickness:Number = 1.0;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "c": color = GMXComponentBuilder.parseColor(command_params[i].val); break;
					case "a": alpha = parseFloat(command_params[i].val); break;
					case "t": thickness = parseFloat(command_params[i].val); break;
				}
			}
			if (color == -1 || alpha < 0.0 || alpha > 1.0) {
				Alert.show("handleNewFillColor ERROR: color was not set correctly or alpha was outside of 0.0-1.0!");
				return;
			}
			_currentLineThickness = thickness + "";
			_currentLineAlpha = alpha + "";
			_currentLineColor = color.toString(16);
			
			_lineAlphaBox.text = _currentLineAlpha;
			_lineThicknessBox.text = _currentLineThickness;
			_lineColorPicker.selectedColor = color;
		}
		
		private function handleNewFillColor(command_params:Vector.<CommandParameter>):void {
			var color:int = -1;
			var alpha:Number = 1.0;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "c": color = GMXComponentBuilder.parseColor(command_params[i].val); break;
					case "a": alpha = parseFloat(command_params[i].val); break;
				}
			}
			if (color == -1 || alpha < 0.0 || alpha > 1.0) {
				Alert.show("handleNewFillColor ERROR: color was not set correctly or alpha was outside of 0.0-1.0!");
				return;
			}
			_currentFillColor = color.toString(16);
			_currentFillAlpha = alpha + "";
			
			_fillAlphaBox.text = _currentFillAlpha;
			_fillColorPicker.selectedColor = color;
		}
		
		private function handleSelectObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					default: Alert.show("WARNING: Deselect object command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleSelectObject did not have an id");  return; }
			var newSelectedObject:GraphicObject = _objectDictionary[id];
			if (newSelectedObject == null) {
				Alert.show("WARNING: handleSelectObject id=" + id + " did not return a GraphicObject!");
				return;
			}
			// handled in DeselectObject
			//if (selectedObject != null) { _selectedObject.deselect(); }
			_selectedObject = newSelectedObject;
			newSelectedObject.select();
		}
		
		private function handleDeselectObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					default: Alert.show("WARNING: Deselect object command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleDeselectObject did not have an id");  return; }
			if (_selectedObject == _objectDictionary[id]) { _selectedObject.deselect(); _selectedObject = null; }
		}
		
		private function handleDeleteObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var position:int;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					case "p": position = parseInt(command_params[i].val); break;
					default: Alert.show("WARNING: handleDeleteObject command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleDeleteObject did not have an id");  return; }
			if (_selectedObject == _objectDictionary[id]) { 
				try {
					_graphicObjects.removeItemAt(position);
					_canvas.removeChildAt(position);
				} catch (e:Error) {
					trace("ERROR WITH DELETE: " + e.message + "\n" + e.getStackTrace());
				}
			} else {
				Alert.show("ERROR: handleDeleteObject id did not match selected object's id");
			}
		}
		
		private function handleReattachObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var position:int;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					case "p": position = parseInt(command_params[i].val); break;
					default: Alert.show("WARNING: handleReattachObject command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleReattachObject did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleReattachObject id did not return a Graphic object from the dictionary!");  return; }
			try {
				_graphicObjects.addItemAt(graphicObject, position);
				_canvas.addChildAt(graphicObject, position);
			} catch (e:Error) {
				trace("ERROR WITH DELETE: " + e.message + "\n" + e.getStackTrace());
			}
		}
		
		private function handleAddFill(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var color:int;
			var alpha:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					case "c": color = parseInt(command_params[i].val, 16); break;
					case "a": alpha = parseFloat(command_params[i].val); break;
					case "ua": break;
					case "uc": break;
					default: Alert.show("WARNING: handleAddFill command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleAddFill did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleAddFill id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.fillColor = color;
			graphicObject.fillAlpha = alpha;
			graphicObject.invalidateDisplayList();
		}
		
		private function handleRemoveFill(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var color:int;
			var alpha:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					// the color and alpha in this command are just for retaining a record of what was in the object
					// in order to do undo / redo commands
					case "id": id = command_params[i].val; break;
					case "uc": color = parseInt(command_params[i].val, 16); break;
					case "ua": alpha = parseFloat(command_params[i].val); break;
					case "a": break;
					case "c": break;
					default: Alert.show("WARNING: handleRemoveFill command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleRemoveFill did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleRemoveFill id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.fillColor = color;
			graphicObject.fillAlpha = alpha;
			graphicObject.invalidateDisplayList();
		}
		
		private function handleSetLineColor(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var color:int;
			var alpha:Number;
			var thickness:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					case "id": id = command_params[i].val; break;
					case "c": color = parseInt(command_params[i].val, 16); break;
					case "a": alpha = parseFloat(command_params[i].val); break;
					case "t": thickness = parseFloat(command_params[i].val); break;
					case "ua": break;
					case "uc": break;
					case "ut": break;
					default: Alert.show("WARNING: handleAddFill command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleAddFill did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleAddFill id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.setLineStyle(new GraphicLineStyle(thickness, color, alpha));
			graphicObject.invalidateDisplayList();
		}
		
		private function handleResetLineColor(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var color:int;
			var alpha:Number;
			var thickness:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					// the color and alpha in this command are just for retaining a record of what was in the object
					// in order to do undo / redo commands
					case "id": id = command_params[i].val; break;
					case "uc": color = parseInt(command_params[i].val, 16); break;
					case "ua": alpha = parseFloat(command_params[i].val); break;
					case "ut": thickness = parseFloat(command_params[i].val); break;
					case "a": break;
					case "c": break;
					case "t": break;
					default: Alert.show("WARNING: handleRemoveFill command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleRemoveFill did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleRemoveFill id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.setLineStyle(new GraphicLineStyle(thickness, color, alpha));
			graphicObject.invalidateDisplayList();
		}
		
		private function handleTranslateObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var dx:Number;
			var dy:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					// the color and alpha in this command are just for retaining a record of what was in the object
					// in order to do undo / redo commands
					case "id": id = command_params[i].val; break;
					case "dx": dx = parseFloat(command_params[i].val); break;
					case "dy": dy = parseFloat(command_params[i].val); break;
					case "udx": break; // used in untranslate object
					case "udy": break; // used in untranslate object
					default: Alert.show("WARNING: handleTranslateObject command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleTranslateObject did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleTranslateObject id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.translate(dx, dy);
		}
		
		private function handleUntranslateObject(command_params:Vector.<CommandParameter>):void {
			var id:String;
			var udx:Number;
			var udy:Number;
			for (var i:int = 0; i < command_params.length; i++) {
				switch(command_params[i].id) {
					// the color and alpha in this command are just for retaining a record of what was in the object
					// in order to do undo / redo commands
					case "id": id = command_params[i].val; break;
					case "udx": udx = parseFloat(command_params[i].val); break;
					case "udy": udy = parseFloat(command_params[i].val); break;
					case "dx": break; // used in translate object
					case "dy": break; // used in translate object
					default: Alert.show("WARNING: handleTranslateObject command had something other than an id: " + command_params[i].id);
				}
			}
			if (id == null) { Alert.show("WARNING: handleTranslateObject did not have an id");  return; }
			var graphicObject:GraphicObject = _objectDictionary[id];
			if (graphicObject == null) { Alert.show("ERROR: handleTranslateObject id did not return a Graphic object from the dictionary!");  return; }
			graphicObject.translate(udx, udy);
		}
		
		
		public static function formatCommandId(commandName:String):String {
			return "|" + commandName;
		}
		public static function formatCommandParameter(name:String, val:String):String {
			return "|:" + name + ":" + val;
		}
		
		private function parseCommandParameters(param_set:Vector.<String>):Vector.<CommandParameter> {
			var param_id:String;
			var param_val:String;
			var output:Vector.<CommandParameter> = new Vector.<CommandParameter>();
			while (param_set.length > 0) {
				var split_param:Vector.<String> = GMXMain.splitter(param_set.shift());
				if (split_param.length != 2) { 
					Alert.show("COMMAND PARAMETER DID NOT HAVE 2 ENTRIES (e.g. :x:[xVal]).  THIS SHOULD NEVER HAPPEN. split_param: " + split_param);
					return null;
				}
				param_id = split_param[0];
				param_val = split_param[1];
				output.push(new CommandParameter(param_id, param_val));
			}
			return output;
		}
//================= END COMMAND HANDLERS ==================================================================================
//=========================================================================================================================
//=========================================================================================================================
//=========================================================================================================================

		public function shiftGraphicObject(object:GraphicObject, dx:Number, dy:Number, largeStep:Boolean = false):void {
			if (object == null) { return; }
			if (largeStep) { dx = dx * 10; dy = dy * 10; }
			var translateCommand:String = formatCommandId(TRANSLATE_OBJECT);
			translateCommand += formatCommandParameter("id", object.objectUid);
			translateCommand += formatCommandParameter("udx", -dx + "");
			translateCommand += formatCommandParameter("udy", -dy + "");
			translateCommand += formatCommandParameter("dx", dx + "");
			translateCommand += formatCommandParameter("dy", dy + "");
			newCommand(translateCommand);
		}
		
		private function dumpActionScript():void {
			var outputText:String = "";
			for (var i:int = 0; i < _graphicObjects.length; i++) {
				outputText += _graphicObjects[i].dumpActionScript();
			}
			_outputTextBox.text = outputText;
		}
		
		private function dumpSVG():void {
			var outputText:String = "";
			outputText += '<?xml version="1.0"?>\n';
			outputText += '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"\n';
			outputText += '         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'
			outputText += '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n\n';
			for (var i:int = 0; i < _graphicObjects.length; i++) {
				outputText += _graphicObjects[i].dumpSVG();
			}
			outputText += '</svg>';
			_outputTextBox.text = outputText;
			var file:FileReference = new FileReference();
			file.save(outputText, "generated.svg");
		}
	}
}