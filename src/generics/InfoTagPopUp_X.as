package generics
{
	import generics.Button_X;
	import generics.VBox_X;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import constants.Size;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.core.UIComponent;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.containers.Form;
	import mx.controls.Alert;

	public class InfoTagPopUp_X extends VBox_X
	{ 
		private var _parentInfoTag:InfoTag_X;
		private var _groupM:int = 1; 
		private var _groupN:int = 1;
		private var _positionY:int = 0;
		private var _positionX:int = 0;
		private var _sideN:int = 1;
		private var _upN:int = 0;
		private var _downN:int = 0;
		private var tagColor:uint = 0x00BCC3;
		
		public function InfoTagPopUp_X(parentInfoTag:InfoTag_X)
		{
			super();
			_parentInfoTag = parentInfoTag;
			this.width = 35 * Size.MM;
			this.height = 20 * Size.MM;
		}
     
		override public function build(xml:XML):void {
			if (xml == null) { return; }
			
			var MM:Number = Size.MM;
			if (xml.@padding == undefined) {
				// set it to 3 as a default
				xml.@padding = 3;
			}
			if (xml.@heightType != undefined) {
				switch(xml.@heightType.toString().toLowerCase()) {
					case "standard":
						this.height = 20 * MM;
						break;
					case "small":
						this.height = 10 * MM;
						break;
					case "tall":
						this.height = 40 * MM;
						break;
				}
			}
			if (xml.@widthType != undefined) {
				switch(xml.@heightType.toString().toLowerCase()) {
					case "standard":
						this.width = 35 * MM;
						break;
					case "short":
						this.width = 20 * MM;
						break;
					case "long":
						this.width = 60 * MM;
						break;
				}
			}
			if (xml.@tagColor != undefined) {
				tagColor = GMXComponentBuilder.parseColor(xml.@tagColor.toString());
			}
			super.build(xml);
			this.invalidateDisplayList();
		}
		
		override public function dataEdit(event:RecordEvent):void {
			// only send everything if the parent button has been activated
			if (this.record == null) {
				// have the parent containers catch the event
				event.stopPropagation();
				_parentInfoTag.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, event.field, true, true));	
			} else {
				// send it from this component
				Record.dataEdit(event, this.record);
			}
			if (event.field == null) { return;  }
			
			for (var i:int = 0; i < event.field.componentsRequiringUpdate.length; i++) {
				if (event.field.componentsRequiringUpdate[i] is Button_X) { 
					//turn it off
					_parentInfoTag.removePopUp();
					return;
				} 
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		}
		
		override protected function measure():void {
			super.measure();
		}
		
		public static const RIGHT_ABOVE:int = 0;
		public static const LEFT_ABOVE:int = 1;
		public static const LEFT_BELOW:int = 2;
		public static const RIGHT_BELOW:int = 3;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			if (_parentInfoTag == null) { super.updateDisplayList(unscaledWidth, unscaledHeight); return; }
			var popUpPosition:Point = GMXMain.PopUps.globalCoordinateTransform(_parentInfoTag);
			if (_parentInfoTag.parent != null) {
				this.x = popUpPosition.x + _parentInfoTag.parent.width / 2;
				this.y = popUpPosition.y + _parentInfoTag.parent.height / 2;
			} else {
				this.x = popUpPosition.x;
				this.y = popUpPosition.y;
			}
			
			var MM:Number = Size.MM;
			var rounding:Number = 0;
			// SOMETHING IS WRONG HERE!
			var topLevelComponent:UIComponent = GMXMain.instance;
			topLevelComponent = topLevelComponent.getChildAt(0) as UIComponent;
			var orientation:int;
			if (popUpPosition.x > topLevelComponent.width / 2) {
				// position on left side
				if (popUpPosition.y > topLevelComponent.height / 2) {
					orientation = LEFT_ABOVE;
				} else {
					orientation = LEFT_BELOW;
				}
			} else {
				// position on right side
				if (popUpPosition.y > topLevelComponent.height / 2) {
					orientation = RIGHT_ABOVE;
				} else {
					orientation = RIGHT_BELOW;
				}
			}
			
			// Change bubble out from the center of the menu button if necessary
			var g:Graphics = this.graphics;
			g.clear();
			g.lineStyle(1, 0); 
			g.beginFill(tagColor); 
			switch (orientation) {
				case RIGHT_ABOVE:
					this.x -= 5 * MM;
					this.y -= 8 * MM + this.height;
					g.moveTo(5 * MM, 8 * MM + this.height);
					g.lineTo(10 * MM, this.height);
					g.lineTo(rounding, this.height);
					g.curveTo(0, this.height, 0, this.height - rounding);
					g.lineTo(0, rounding);
					g.curveTo(0, 0, rounding, 0);
					g.lineTo(this.width - rounding, 0);
					g.curveTo(this.width, 0, this.width, rounding);
					g.lineTo(this.width, this.height - rounding);
					g.curveTo(this.width, this.height, this.width-rounding, this.height);
					g.lineTo(16 * MM, this.height);
					g.lineTo(5 * MM, 8 * MM + this.height);
					break;
				case LEFT_ABOVE:
					this.x -= this.width - 5 * MM;
					this.y -= 8 * MM + this.height;
					g.moveTo(width - 5 * MM, 8 * MM + height);
					g.lineTo(width - 10 * MM, height);
					g.lineTo(width - rounding, height);
					g.curveTo(width, height, width, height-rounding);
					g.lineTo(width, rounding);
					g.curveTo(width, 0, width-rounding, 0);
					g.lineTo(rounding, 0);
					g.curveTo(0, 0, 0, rounding);
					g.lineTo(0, height-rounding);
					g.curveTo(0, height, rounding, height);
					g.lineTo(this.width - 16 * MM, height);
					g.lineTo(this.width - 5 * MM, 8 * MM + this.height);
					break;
				case LEFT_BELOW:
					this.x -= this.width - 5 * MM;
					this.y += 8 * MM;
					g.moveTo(width - 5 * MM, -8 * MM);
					g.lineTo(width - 10 * MM, 0);
					g.lineTo(width - rounding, 0);
					g.curveTo(width, 0, width, rounding);
					g.lineTo(width, height-rounding);
					g.curveTo(width, height, width-rounding, height);
					g.lineTo(rounding, height);
					g.curveTo(0, height, 0, height-rounding);
					g.lineTo(0, rounding);
					g.curveTo(0, 0, rounding, 0);
					g.lineTo(this.width - 16 * MM, 0);
					g.lineTo(width - 5 * MM, -8 * MM);
					break;
				case RIGHT_BELOW:
					this.x -= 5 * MM;
					this.y += 8 * MM;
					g.moveTo(5 * MM, -8 * MM);
					g.lineTo(10 * MM, 0);
					g.lineTo(rounding, 0);
					g.curveTo(0, 0, 0, rounding);
					g.lineTo(0, height - rounding);
					g.curveTo(0, height, rounding, height);
					g.lineTo(this.width - rounding, height);
					g.curveTo(this.width, height, this.width, height - rounding);
					g.lineTo(this.width, rounding);
					g.curveTo(this.width, 0, this.width-rounding, 0);
					g.lineTo(16 * MM, 0);
					g.lineTo(5 * MM, -8 * MM);
					break;
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}