package generics
{
	import generics.InfoTagPopUp_X;
	import generics.MenuButton_X;
	import generics.Label_X;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.RecordEvent;
	import constants.Size;
	import mx.core.UIComponent;
	
	import flash.display.CapsStyle;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.FlexSprite;
	import mx.events.FlexMouseEvent;
	
	// Still need to implement:
	//   -make it so messages are sent whether it's active or not... This, however, must involves implementing a toggle-button approach
	//    to the message "active" and "inactive" instead of "true" and "false"
	public class InfoTag_X extends UIComponent implements ISelfBuilding
	{
		private var _popUp:InfoTagPopUp_X;
		private var _popUpShowing:Boolean = false;
		
		public function InfoTag_X() {
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			_popUp = new InfoTagPopUp_X(this);
			this.addChild(_popUp);
			this.removeChild(_popUp);
		}
		
		public function build(buttonXML:XML):void {
			_popUp.build(buttonXML); // uses the same XML
			if (parent is UIComponent == false) { return; }
			
			// based on what component is the parent, add relevant listeners to cause this info tag popup to appear
			var parentComponent:UIComponent = parent as UIComponent;
			if (parentComponent is MenuButton_X) { 
				parentComponent.addEventListener(MouseEvent.CLICK, parentClick, false, 0, true);
				parentComponent.addEventListener(MouseEvent.MOUSE_DOWN, parentDown, false, 0, true);
			}
			//else if (parent is ____) { }
		}
		
		protected function parentDown(event:MouseEvent):void {
			event.stopPropagation();
		}
		
		protected function parentClick(event:MouseEvent):void {
			if (_popUpShowing) {
				removePopUp();
			} else {
				addPopUp();
			}
			_popUp.invalidateDisplayList();
		}
		
		public function removePopUp():void {
			GMXMain.PopUps.removePopUp(_popUp);
			_popUpShowing = false;
			GMXMain.stage.removeEventListener(MouseEvent.MOUSE_DOWN, stageDown);
			var parentComponent:UIComponent = parent as UIComponent;
			if (parentComponent is MenuButton_X) { var menuButton:MenuButton_X = parentComponent as MenuButton_X; menuButton.selected = false; }
		}
		
		public function addPopUp():void {
			GMXMain.PopUps.addPopUp(_popUp);
			_popUpShowing = true;
			GMXMain.stage.addEventListener(MouseEvent.MOUSE_DOWN, stageDown, false, 0, true);
			_popUp.addEventListener(MouseEvent.MOUSE_DOWN, popUpDown, false, 0, true);
			var parentComponent:UIComponent = parent as UIComponent;
			if (parentComponent is MenuButton_X) { var menuButton:MenuButton_X = parentComponent as MenuButton_X; menuButton.selected = true; }
		}
	
		private function stageDown(event:MouseEvent):void {
			removePopUp();
			this.invalidateDisplayList();
		}
		
		private function popUpDown(event:MouseEvent):void {
			// stops it from getting to the stage
			event.stopPropagation();
		}
		
		override protected function commitProperties():void {	
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			_popUp.disintegrate();
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes); 
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}