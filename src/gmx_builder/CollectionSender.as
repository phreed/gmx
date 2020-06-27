package gmx_builder
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import GMX.Data.CollectionVO;
	import GMX.Data.RuidVO;
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
	 * This is the pop-up that appears when the "Send Collection" button is pressed in GMX edit mode.  It could use a makeover... it's kind of 
	 * clunky, but the idea is that it automatically populates a combobox with all available cuids and also allows for typing in new ones
	 * @author Alan Nelson
	 */
	public class CollectionSender extends VBox
	{
		private var _exitButton:Button = new Button();
		private var _sendButton:Button = new Button();
		private var _cuidComboBox:ComboBox = new ComboBox();
		private var _numberOfRuidsTextInput:TextInput = new TextInput();
		private var _numberOfRuids:int = 1;
		private var _ruids:Vector.<RuidBuilder> = new Vector.<RuidBuilder>;
		private var _latestCuid:String = "";
		
		public function CollectionSender() 
		{
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			var hBox:HBox;
			var label:Label;
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
			_cuidComboBox.editable = true;
			_cuidComboBox.dataProvider = GMXDictionaries.getCuidList();
			_cuidComboBox.addEventListener(Event.CHANGE, cuidChange);
			hBox = new HBox();
			label = new Label();
			label.text = "cuid:";
			hBox.addChild(label);
			hBox.addChild(_cuidComboBox);
			this.addChild(hBox);
			
			hBox = new HBox();
			label = new Label();
			label.text = "Number of Ruids:";
			hBox.addChild(label);
			hBox.addChild(_numberOfRuidsTextInput);
			
			_numberOfRuidsTextInput.text = _numberOfRuids + ""; // default
			_numberOfRuidsTextInput.addEventListener(FlexEvent.ENTER, enterNumberOfRuids);
			_numberOfRuidsTextInput.addEventListener(FocusEvent.FOCUS_OUT, enterNumberOfRuids);
			this.addChild(hBox);
		}
		
		public function cuidChange(event:Event = null):void {
			_latestCuid = _cuidComboBox.text;
		}
		
		public function resetDataProviders():void {
			_cuidComboBox.dataProvider = GMXDictionaries.getCuidList();
			for (var i:int = 0; i < _ruids.length; i++) {
				_ruids[i].resetDataProvider();
			}
			_cuidComboBox.selectedItem = _latestCuid;
			_cuidComboBox.text = _latestCuid;
		}
		
		private function sendClick(event:MouseEvent):void {
			var collectionVO:CollectionVO = new CollectionVO();
			if (_cuidComboBox.text == "") { 
				GMXMain.PopUps.removeChild(this); 
				return;
			}
			collectionVO.cuid = _cuidComboBox.text;
			var a_CollectionList:Array = [collectionVO];
			for (var i:int = 0; i < _ruids.length; i++) {
				var ruidValueArray:Vector.<String> = _ruids[i].value;
				var ruidVO:RuidVO = new RuidVO();
				ruidVO.ruid = ruidValueArray.shift();
				if (ruidVO.ruid == "") { continue; }
				ruidVO.ref = ruidValueArray.shift();
				ruidVO.select = ruidValueArray.shift();
				collectionVO.ruidList.push(ruidVO);
			}
			
			GMXMain.instance.ISISCollection(a_CollectionList/*CollectionVO*/);
			
			GMXMain.PopUps.removeChild(this);
		}
		
		private function exitClick(event:MouseEvent):void {
			GMXMain.PopUps.removeChild(this);
		}
		
		private function enterNumberOfRuids(event:Event):void {
			var newNumber:int = parseInt(_numberOfRuidsTextInput.text);
			if (isNaN(newNumber) || newNumber < 0) { _numberOfRuidsTextInput.text = _numberOfRuids + ""; return; }
			
			_numberOfRuids = newNumber;
			while (_ruids.length < newNumber) {
				var collectionSender:RuidBuilder = new RuidBuilder();
				_ruids.push(collectionSender);
				this.addChild(collectionSender);
			}
			while (_ruids.length > newNumber) {
				this.removeChild(_ruids[_ruids.length - 1]);
				_ruids.pop();
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