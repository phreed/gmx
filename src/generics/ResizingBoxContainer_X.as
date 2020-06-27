package generics
{
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import flash.display.DisplayObject;
	import mx.controls.Alert;
	import mx.events.ResizeEvent;
	
	/**
	 * ...
	 * @author 
	 */
	public class ResizingBoxContainer_X extends VBox_X
	{
		private var inflexibleSelfBuildingComponents:Vector.<ISelfBuilding> = new Vector.<ISelfBuilding>;
		private var flexibleSelfBuildingComponents:Vector.<ISelfBuilding> = new Vector.<ISelfBuilding>;
		
		public function ResizingBoxContainer_X() 
		{
			super();
			this.addEventListener(ResizingBoxEvent.BOX_RESIZE, resizeHandler);
			this.clipContent = true;
		}
		
		override public function build(xml:XML):void {
			super.build(xml);
			while (inflexibleSelfBuildingComponents.length > 0) { inflexibleSelfBuildingComponents.pop(); }
			while (flexibleSelfBuildingComponents.length > 0) { flexibleSelfBuildingComponents.pop(); }
			updateVectors();
			resizeHandler(null);
		}
		
		private function updateVectors():void {
			for (var i:int = 0; i < this.numChildren; i++) {
				var child:DisplayObject = this.getChildAt(i);
				if (child is ISelfBuilding) {
					var selfBuilding:ISelfBuilding = child as ISelfBuilding;
					if (selfBuilding.flexible == true) {
						flexibleSelfBuildingComponents.push(child);
					} else inflexibleSelfBuildingComponents.push(child);
					//trace("child.flexible == true: " + (selfBuilding.flexible == true));
				} else inflexibleSelfBuildingComponents.push(child);
			}
		}
	
		private function resizeHandler(event:ResizingBoxEvent):void {
			//trace("REACHED THE RESIZE HANDLER!!"); 
			if (event != null) { event.stopPropagation(); }
			//trace("!!!!!! RESIZE EVENT CAUGHT !!!!!!!!!!!!");
			this.invalidateProperties();
			this.invalidateDisplayList();
			
		}
				
		override public function removeChild(child:DisplayObject):DisplayObject {
			if (child is ISelfBuilding) {
				if (removeElements(inflexibleSelfBuildingComponents, child) == false) { 
					removeElements(flexibleSelfBuildingComponents, child);
				}
			} else {
				removeElements(inflexibleSelfBuildingComponents, child);
			}
			return super.removeChild(child);
		}
		
		private function removeElements(vector:Vector.<ISelfBuilding>, obj:Object):Boolean {
			for (var i:int = 0; i < vector.length; i++) {
				if (vector[i] == obj) {
					vector.splice(i, 1);
					return true;
				}
			}
			return false;
		}
		
		override protected function commitProperties():void {
			if (flexibleSelfBuildingComponents.length == 0) { return; }
			
			var selfBuilding:ISelfBuilding;
			var inflexibleComponentTotalHeight:Number = 0;
			for (var i:int = 0; i < inflexibleSelfBuildingComponents.length; i++) {
				inflexibleComponentTotalHeight += inflexibleSelfBuildingComponents[i].height;
				inflexibleSelfBuildingComponents[i].invalidateDisplayList();
			}
			
			var heightLeft:Number = this.height - inflexibleComponentTotalHeight;
			//trace("heightLeft: " + heightLeft);
			if (heightLeft < 0) { 
				Alert.show("WARNING: ResizingBoxContainer does not have enough room by " + heightLeft + " pixels!");
				heightLeft = 0;
			}
			var heightPerFlexibleComponent:Number = heightLeft / flexibleSelfBuildingComponents.length;
			
			for (i = 0; i < flexibleSelfBuildingComponents.length; i++) {
				flexibleSelfBuildingComponents[i].height = heightPerFlexibleComponent;
			}
			super.commitProperties();
			//trace("CONTAINER HEIGHT CHANGE: " + this.height);
		}
	}
}