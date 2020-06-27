package gmx_builder
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import GMX.Data.FieldVO;
	import GMX.Data.RecordVO;
	import GMX.Data.FieldVO;
	import GMX.Data.RecordVO;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	/**
	 * This is the pop-up that appears when the "Send Record" button is pressed in GMX edit mode.  It could use a makeover... it's kind of 
	 * clunky, but the idea is that it automatically populates a combobox with all available ruids and also allows for typing in new ones
	 * @author Alan Nelson
	 */
	public class RecordSender extends VBox
	{
		private var _fieldList:ArrayCollection = new ArrayCollection();
		private var _exitButton:Button = new Button();
		private var _sendButton:Button = new Button();
		private var _ruidComboBox:ComboBox = new ComboBox();
		private var _numberOfFieldsTextInput:TextInput = new TextInput();
		private var _numberOfFields:int = 1;
		private var _fields:Vector.<FieldBuilder> = new Vector.<FieldBuilder>;
		
		private var _latestRuid:String = "";
		
		public function RecordSender() 
		{
			super();
			
		}
		
		override protected function createChildren():void {
			super.createChildren();
			var hBox:HBox;
			var label:Label;
			_ruidComboBox.addEventListener(Event.CHANGE, ruidChange);
			this.addEventListener(MouseEvent.MOUSE_DOWN, dragDown);
			this.width = 450;
			this.height = GMXMain.instance.height - 200;
			this.setStyle("backgroundColor", 0xbbbbbb);
			this.setStyle("borderStyle", "solid");
			this.setStyle("borderColor", 0x000000);
			this.setStyle("borderThickness", 3);
			_sendButton.label = "...SEND...";
			_sendButton.addEventListener(MouseEvent.CLICK, sendClick);
			_exitButton.label = "EXIT";
			_exitButton.addEventListener(MouseEvent.CLICK, exitClick);
			hBox = new HBox();
			hBox.setStyle("horizontalGap", 10);
			hBox.setStyle("paddingLeft", 10);
			hBox.setStyle("paddingBottom", 10);
			hBox.setStyle("paddingTop", 10);
			hBox.addChild(_sendButton);
			hBox.addChild(_exitButton);
			this.addChild(hBox);
			this.verticalScrollPolicy = "on";
			_ruidComboBox.editable = true;
			_ruidComboBox.dataProvider = GMXDictionaries.getRuidList();
			hBox = new HBox();
			label = new Label();
			label.text = "ruid:";
			hBox.addChild(label);
			hBox.addChild(_ruidComboBox);
			this.addChild(hBox);
			
			hBox = new HBox();
			label = new Label();
			label.text = "Number of Fields:";
			hBox.addChild(label);
			hBox.addChild(_numberOfFieldsTextInput);
			
			_numberOfFieldsTextInput.text = _numberOfFields + ""; // default
			_numberOfFieldsTextInput.addEventListener(FlexEvent.ENTER, enterNumberOfFields);
			_numberOfFieldsTextInput.addEventListener(FocusEvent.FOCUS_OUT, enterNumberOfFields);
			this.addChild(hBox);
		}
		
		private function refreshSort():void {
			var sort:Sort = new Sort();
			sort.fields = [new SortField(null, true)];
			_fieldList.sort = sort;
			_fieldList.refresh();
		}
		public function resetDataProviders():void {
			_fieldList = GMXDictionaries.getFidList(_latestRuid);
			refreshSort();
			_numberOfFieldsTextInput.text = _fieldList.length + "";
			enterNumberOfFields(null);
			//need to make this getFidList!
			_ruidComboBox.dataProvider = GMXDictionaries.getRuidList();
			for (var i:int = 0; i < _fields.length; i++) {
				_fields[i].resetDataProvider(_fieldList, _ruidComboBox.text);
				_fields[i].fid = _fieldList[i];
			}
			_ruidComboBox.selectedItem = _latestRuid;
			_ruidComboBox.text = _latestRuid;
		}
		
		private function ruidChange(event:Event):void {
			_latestRuid = _ruidComboBox.text;
			if (_ruidComboBox.text == "") { 
				_fieldList.removeAll();
				return;
			}
			_fieldList = GMXDictionaries.getFidList(_ruidComboBox.text);
			refreshSort();
			_numberOfFieldsTextInput.text = _fieldList.length + "";
			enterNumberOfFields(null);
			for (var i:int = 0; i < _fields.length; i++) {
				_fields[i].resetDataProvider(_fieldList, _ruidComboBox.text);
				_fields[i].fid = _fieldList[i];
			}
		}
		
		private function sendClick(event:MouseEvent):void {
			var recordVO:RecordVO = new RecordVO();
			if (_ruidComboBox.text == "") {
				GMXMain.PopUps.removeChild(this); 
				return;
			}
			recordVO.ruid = _ruidComboBox.text;
			var a_RecordList:Array = [recordVO];
			for (var i:int = 0; i < _fields.length; i++) {
				var fieldArray:Vector.<String> = _fields[i].value;
				var fieldVO:FieldVO = new FieldVO();
				fieldVO.fid = fieldArray.shift();
				if (fieldVO.fid == "") { continue; }
				fieldVO.value = fieldArray.shift();
				recordVO.fieldList.push(fieldVO);
			}
			
			GMXMain.instance.ISISRecord(a_RecordList/*recordVO*/);
			
			GMXMain.PopUps.removeChild(this);
		}
		
		private function exitClick(event:MouseEvent):void {
			GMXMain.PopUps.removeChild(this);
		}
		
		private function enterNumberOfFields(event:Event):void {
			var newNumber:int = parseInt(_numberOfFieldsTextInput.text);
			if (isNaN(newNumber) || newNumber < 0) { _numberOfFieldsTextInput.text = _numberOfFields + ""; return; }
			
			_numberOfFields = newNumber;
			while (_fields.length < newNumber) {
				var fieldBuilder:FieldBuilder = new FieldBuilder();
				fieldBuilder.resetDataProvider(_fieldList, _ruidComboBox.text);
				_fields.push(fieldBuilder);
				this.addChild(fieldBuilder);
			}
			while (_fields.length > newNumber) {
				this.removeChild(_fields[_fields.length - 1]);
				_fields.pop();
			}
		}
		private var _dragging:Boolean = false;
		private var _referencePoint:Point = new Point();
		private function dragDown(event:MouseEvent):void {
			if (!event.shiftKey) { return; }
			
			_dragging = true;
			_referencePoint.x = this.mouseX;
			_referencePoint.y = this.mouseY;
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_MOVE, dragMove);
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_UP, dragUp);
		}
		
		private function dragMove(event:MouseEvent):void {
			this.x = GMXMain.stage.mouseX - _referencePoint.x;
			this.y = GMXMain.stage.mouseY - _referencePoint.y;
		}
		
		private function dragUp(event:MouseEvent):void {
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragMove);
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragUp);
		}
	}
}