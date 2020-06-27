package generics
{
	import generics.Button_X;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import constants.Size;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author 
	 */
	public class ResizingBox_X extends UIComponent implements ISelfBuilding
	{
		private var _vBox:VBox_X = new VBox_X();
		private var _expandButton:Button_X = new Button_X();
		private var _expanded:Boolean = false;
		public function get expanded():Boolean { return _expanded; }
		public function set expanded(val:Boolean):void { _expanded = val; }
		
		private var _collapsedHeight:Number = 20;
		private var _expandedHeight:Number = 50;
		
		private var _expandIconID:String = "expandTree";
		private var _collapseIconID:String = "collapseTree";
		private var _type:String = "left";
		
		public function ResizingBox_X()
		{
			super();
			_vBox.clipContent = true;
		}
		
		public function build(xml:XML):void {
			this.addChild(_vBox);
			if (xml.@expandedHeight != undefined) {
				this._expandedHeight = GMXComponentBuilder.parseMM(xml.@expandedHeight.toString());
			}
			if (xml.@collapsedHeight != undefined) {
				this._collapsedHeight = GMXComponentBuilder.parseMM(xml.@collapsedHeight.toString());
			}
			if (xml.@expanded != undefined) {
				this.expanded = xml.@expanded.toString() == "true" ? true : false;
			}
			
			GMXComponentBuilder.setStandardValues(xml, this);
			this.addChild(_expandButton);
			if (xml.@type != undefined) {
				_type = xml.@type.toString();
				if (_type == "right") {
					_expandIconID = "maximize";
					_collapseIconID = "restore";
				}
			}
			if (xml.@collapseIcon != undefined) {
				_collapseIconID = xml.@collapsedIcon;
			}
			if (xml.@expandIcon != undefined) {
				_expandIconID = xml.@expandIcon;
			}
			if (_expanded) {
				_vBox.height = height = _expandedHeight;
				_expandButton.changeIcon(_collapseIconID);
			} else {
				_vBox.height = height = _collapsedHeight;
				_expandButton.changeIcon(_expandIconID);
			}
			
			_expandButton.addEventListener(MouseEvent.CLICK, buttonClicked);
			_expandButton.x = Size.MM;
			_expandButton.y = Size.MM;
			_expandButton.width = 8 * Size.MM;  // default
			_expandButton.height = 8 * Size.MM; // default
			if (xml.@buttonSize != undefined) {
				var buttonSize:String = xml.@buttonSize.toString();
				_expandButton.width = _expandButton.height = GMXComponentBuilder.parseMM(buttonSize); 
				if (_expandButton.icon != null) { 
					_expandButton.icon.width = _expandButton.icon.height = _expandButton.width - Size.MM;
					_expandButton.icon.x = _expandButton.icon.y = Size.MM / 2;
				}
			}
			_vBox.build(xml);
		}
		
		private function buttonClicked(event:MouseEvent):void {
			if (_expanded) {
				height = _vBox.height = _collapsedHeight;
				_expandButton.changeIcon(_expandIconID);
			} else {
				height = _vBox.height = _expandedHeight;
				_expandButton.changeIcon(_collapseIconID);
			}
			_expanded = !_expanded;
			this.dispatchEvent(new ResizingBoxEvent(ResizingBoxEvent.BOX_RESIZE));
		}
		
		override protected function createChildren():void {
			super.createChildren();
		}
		
		override protected function measure():void {
			super.measure();
			this.measuredHeight = _vBox.height;
			this.measuredWidth = _vBox.width;
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
		}
		
		override public function invalidateDisplayList():void {
			super.invalidateDisplayList();
			/*for (var i:int = 0; i < this.numChildren; i++) {
				if (this.getChildAt(i) is IUIComponent) {
					var comp:UIComponent = this.getChildAt(i) as UIComponent;
					comp.invalidateDisplayList();
				}
			}*/
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			//for (var i:int = 0; i < _vBox.numChildren; i++) {
			//	var child:UIComponent = _vBox.getChildAt(i) as UIComponent;
			//	if (child == null) { continue; }
			//}
			//trace("resizing box updateDisplayList reached");
			_vBox.width = this.width;
			_vBox.height = this.height;
			if (_type == "right") {
				_expandButton.x = this.width - Size.MM - _expandButton.width;
			} else {
				_expandButton.x = Size.MM;
			}
			_vBox.resizeFlexibles();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			_vBox.disintegrate();
		}
		public function setAttributes(attributes:Attributes):void {

		}
//========= END ISelfBuilding Implementation ==============================================
	}
}