package  
{
	import flash.display.DisplayObjectContainer;
	import interfaces.ISelfBuilding;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author 
	 */
	public class ExtraLayoutStateRetainer
	{
		private var _hashVal:String;
		public function get hashVal():String { return _hashVal; }
		private var _layoutState:Vector.<String>;
		
		public function ExtraLayoutStateRetainer() {
			
		}
		// sample save command:
		// |position in the display list|vertical scroll position|horizontal scroll position
		// |:0:4|:v:1|:h:2
		private function processSaveCommand(component:DisplayObjectContainer, indexInXML:String):void {
			var topComponentStateString:String = getScrollString(component);
			if (topComponentStateString != "") {
				topComponentStateString = "|" + indexInXML + topComponentStateString;
				_layoutState.push(topComponentStateString);
			}
			
			// all components that are in the _tempComponentToStateRetainerDict that are being replaced (i.e. the topLevelComponent
			// that has the luid that is being replaced by the layout message AND all of its children that happen to have a luid and
			// therefore were added to the _tempComponentToStateRetainerDict (see addLuid function)) should be removed from 
			// _tempComponentToStateRetainerDict so as to avoid a memory leak with useless components being retained b/c of the
			// dictionary having them as the "key" for another object.. I think this is actually taken care of b/c I set weakKeys=true in
			// the Dictionary constructor, but just in case, I'm going to do this too (you can't be too careful):			
			GMXDictionaries.removeTempComponentToStateRetainerEntry(component);
			for (var i:int = 0; i < component.numChildren; i++) {
				var child:DisplayObjectContainer = component.getChildAt(i) as DisplayObjectContainer;
				if (child == null) { continue; }
				processSaveCommand(child, indexInXML + ":" + i);
			}
		}
		public function savePreviousState(component:DisplayObjectContainer):void {
			_layoutState = new Vector.<String>();
			processSaveCommand(component, ":0");
			/*
			trace("===> BEGIN SAVE PREVIOUS STATE RESULTS: " + component);
			for (var i:int = 0; i < _layoutState.length; i++) {
				trace(_layoutState[i]);
			}
			trace("===> END");
			*/
		}
		private function getScrollString(component:DisplayObjectContainer):String {
			var verticalScrollPosition:int = -1;
			var horizontalScrollPosition:int = -1;
			var output:String = "";
			if ("verticalScrollPosition" in component) {
				verticalScrollPosition = component["verticalScrollPosition"];
				if (verticalScrollPosition != 0) {
					output += "|:v:" + verticalScrollPosition;
				}
			}
			if ("horizontalScrollPosition" in component) {
				horizontalScrollPosition = component["horizontalScrollPosition"];
				if (horizontalScrollPosition != 0) {
					output += "|:h:" + horizontalScrollPosition;
				}
			}
			return output;
		}
		
		public function revertComponentToPreviousState(component:DisplayObjectContainer):void {
			if (_layoutState == null) { return; }
			//trace("revertComponentToPreviousState: _layoutState:" + _layoutState )
			
			for (var i:int = 0; i < _layoutState.length; i++) {
				var params:Vector.<String> = GMXMain.splitter(_layoutState[i]);
				//trace("prev layoutState: " + _layoutState[i]);
				// indexInDisplayList is always the first param:
				var indexInDisplayList:Vector.<String> = GMXMain.splitter(params[0]);
				var targetComponent:DisplayObjectContainer = getComponentInDisplayListFromIndex(component, indexInDisplayList);
				if (targetComponent == null) { trace("ERROR: target component in revertComponentToPreviousState was null!"); return; }
				//other params are either vertical or horizontal scroll bar positions
				for (var j:int = 1; j < params.length; j++) {
					var subparams:Vector.<String> = GMXMain.splitter(params[j]);
					switch(subparams[0]) {
						case "v":
							var verticalScrollPosition:int = parseInt(subparams[1]);
							if (!("verticalScrollPosition") in targetComponent) { 
								trace("ERROR: function revertComponentToPreviousState in ExtraLayoutStateRetainer did not have verticalScrollPosition property!");
							} else {
								targetComponent["verticalScrollPosition"] = verticalScrollPosition;
							}
							break;
						case "h":
							var horizontalScrollPosition:int = parseInt(subparams[1]);
							if (!("horizontalScrollPosition") in targetComponent) { 
								trace("ERROR: function revertComponentToPreviousState in ExtraLayoutStateRetainer did not have horizontalScrollPosition property!");
							} else {
								targetComponent["horizontalScrollPosition"] = horizontalScrollPosition;
							}
							break;
					}
				}
			}
		}
		
		private function getComponentInDisplayListFromIndex(topLevelComponent:DisplayObjectContainer, indexInDisplayList:Vector.<String>):DisplayObjectContainer {
			if (indexInDisplayList.length == 0) {
				trace("ERROR: getComponentInDisplayListFromIndex function in class ExtraLayoutStateRetainer: nothing in the indexInDisplayList vector!");
				return null;
			}
			try {
				var parentComponent:DisplayObjectContainer = topLevelComponent;
				// start and index = 1 b/c it's always a "0" in index 0, and that refers to the top level component
				for (var i:int = 1; i < indexInDisplayList.length; i++) {
					var childIndex:int = parseInt(indexInDisplayList[i]);
					parentComponent = parentComponent.getChildAt(childIndex) as DisplayObjectContainer;
				}
				return parentComponent;
			} catch (e:Error) {
				trace("ERROR: in function getComponentInDisplayListFromIndex in Class ExtraLayoutStateRetainer: " +e.message);
				trace("Note: this MAY be because the current implementation does not take into account those components that, " +
					"after the build function has been completed, can add child components (in a way that does not involve layout messages) " +
					"that have scroll bars.  The ExtraLayoutStateRetainer savePreviousState saves all the components in the display list under " +
					"the component in the argument, which means those scroll-bar-wielding components that were added to after the build function " +
					"was completed would be added into the LayoutState, and when that same component is rebuilt due to a layout message later, the " +
					"getComponentInDisplayListFromIndex function will yield this error because the indeces in the display list do not match up " +
					"on the brand new (just finished the build function) component.");
				
			}
			return null;
		}
	}

}