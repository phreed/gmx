package gmx_builder.drawing_tool 
{
	/**
	 * ...
	 * @author 
	 */
	public class CommandStack {
		public static const MAX_UNDOS:int = 2000;
		
		private var _commands:Vector.<String> = new Vector.<String>(MAX_UNDOS,true);
		private var _currentIndex:int = 0;
		private var _mostRecentCommand:int = 0;
		private var _lastAvailableCommand:int = 0; // last command thta can be reached using undo
		
		private var _actionScriptGraphicGenerator:ActionScriptGraphicsGenerator;
		
		public function CommandStack(actionScriptGraphicGenerator:ActionScriptGraphicsGenerator) {
			_actionScriptGraphicGenerator = actionScriptGraphicGenerator;
			_commands[0] = ActionScriptGraphicsGenerator.formatCommandId(ActionScriptGraphicsGenerator.START_SELECT_MODE);
		}
		
		public function addCommand(command:String):void {
			_currentIndex++;
			if (_currentIndex == MAX_UNDOS) { _currentIndex = 0; }
			if (_currentIndex == _lastAvailableCommand) { _lastAvailableCommand++; if (_lastAvailableCommand == MAX_UNDOS) _lastAvailableCommand = 0; }
			_commands[_currentIndex] = command;
			_mostRecentCommand = _currentIndex;
		}
		
		public function undoCommand():void {
			trace("UNDO: _currentIndex: " + _currentIndex + "    _lastAvailableCommand: " + _lastAvailableCommand);
			if (_currentIndex == _lastAvailableCommand) { return; }
			var currentCommandId:String = GMXMain.splitter(_commands[_currentIndex])[0];
			if (currentCommandId == ActionScriptGraphicsGenerator.START_SELECT_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.START_DRAW_RECT_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.START_DRAW_LINE_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.START_DRAW_CIRCLE_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.NEW_LINE_COLOR ||
				currentCommandId == ActionScriptGraphicsGenerator.NEW_FILL_COLOR) {
					if (_currentIndex > 0) {
						if (_commands[_currentIndex - 1] != undefined) {
							_currentIndex--;
						}
					} else { // currentIndex == 0
						if (_commands[MAX_UNDOS - 1] != undefined) { _currentIndex = MAX_UNDOS - 1; }
					}
					undoCommand(); // skip over the start / new commands
					return;
			}
			_actionScriptGraphicGenerator.executeInverseCommand(_commands[_currentIndex]);
			if (_currentIndex > 0) {
				if (_commands[_currentIndex - 1] != undefined) {
					_currentIndex--;
				}
			} else { // currentIndex == 0
				if (_commands[MAX_UNDOS - 1] != undefined) { _currentIndex = MAX_UNDOS - 1; }
			}
			if (currentCommandId == ActionScriptGraphicsGenerator.SELECT_OBJECT) {
					undoCommand(); // they always come in select, deselect pairs and must be undone together
			}
		}
		
		public function redoCommand():void {
			trace("REDO: _currentIndex: " + _currentIndex + "    _lastAvailableCommand: " + _lastAvailableCommand);
			if (_currentIndex == _mostRecentCommand) { return; }
			if (_currentIndex < MAX_UNDOS - 1) { 
				if (_currentIndex + 1 != _lastAvailableCommand && _commands[_currentIndex + 1] != undefined) {
					_currentIndex++;
				} else {
					return;
				}
			} else { // currentIndex == MAX_UNDOS - 1
				if (_lastAvailableCommand != 0 && _commands[0] != undefined) {
					_currentIndex = 0;
				} else {
					return;
				}
			}
			var currentCommandId:String = GMXMain.splitter(_commands[_currentIndex])[0];
			if (currentCommandId == ActionScriptGraphicsGenerator.END_SELECT_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.END_DRAW_RECT_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.END_DRAW_LINE_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.END_DRAW_CIRCLE_MODE ||
				currentCommandId == ActionScriptGraphicsGenerator.DROP_LINE_COLOR ||
				currentCommandId == ActionScriptGraphicsGenerator.DROP_FILL_COLOR) {
					redoCommand(); // skip over the end mode commands
					return;
			}
			_actionScriptGraphicGenerator.executeCommand(_commands[_currentIndex]);
			if (currentCommandId == ActionScriptGraphicsGenerator.DESELECT_OBJECT) {
					redoCommand(); // they always come in select, deselect pairs and must be undone together
			}
		}
	}
}