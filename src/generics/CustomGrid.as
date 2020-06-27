package generics
{
	import interfaces.ICollection;
	import interfaces.ISelfBuilding;
	import records.Collection;
	import mx.containers.VBox;
	
	/**
	 * ...
	 * @author 
	 */
	public class CustomGrid extends VBox_X implements ICollection
	{
		public function CustomGrid() {
			
		}
		
		private var _rows:Vector.<HBox_X> = new Vector.<HBox_X>();
		private var _columnIDs:Vector.<String> = new Vector.<String>();
		
		override public function build(dataGridXML:XML):void {
			if (dataGridXML == null) { return; }
			
			for each (var dataGridColumnXML:XML in dataGridXML.columns.CustomGridColumn) {
				if (dataGridColumnXML.@fid != undefined) {
					_columnIDs.push(dataGridColumnXML.@fid.toString());
				}
			}
			//GMXComponentBuilder.setStandardValues(dataGridXML, this);
			//xtrace("dataGridXML.@cuid: " + dataGridXML.@cuid + "   dataGridXML.@cuid != undefined: " + dataGridXML.@cuid != undefined);
			//xtrace("dataGridXML.@fontSize: " + dataGridXML.@fontSize+ "   dataGridXML.@fontSize != undefined: " + dataGridXML.@fontSize != undefined);
			if (dataGridXML.@cuid != undefined) {
				this.cuid = dataGridXML.@cuid.toString();
			}
			super.build(dataGridXML);
		}
		
		override protected function commitProperties():void {
			//xtrace("DATAGRID COMMIT PROPERTIES REACHED!! dirty=" + _dirty);
			if (_recordCollection == null || _dirty == false) {
				super.commitProperties();
				return;
			}
			
			
			//xtrace("datagrid type: " + _type);
			/*if (this.selectedItem != null) { 
				var previousSelectedRuid:String = this.selectedItem.@ruid; 
			}*/
			//if (_recordCollection.selectedRuids.length != 0) {
			//	var previousSelectedRuid:String = _recordCollection.selectedRuids[0];
			//}
			//var editingPosition:Object = editedItemPosition;
			//editingPosition.rowIndex...
			//editingPosition.columnIndex...
			
			//xtrace("PREVIOUSLY SELECTED: " + previousSelectedRuid);
			
			/*this.dataProvider = _type == STANDARD ? _recordCollection.updateDataProvider(Collection.DATA_GRID) : _recordCollection.updateDataProvider(Collection.TREE_DATA_GRID);
			if (previousSelectedRuid != null) {
				for (var i:int = 0; i < dataProvider.length; i++) {
					if (dataProvider[i].@ruid == previousSelectedRuid) {
						this.selectedIndex = i;
						//trace("found selected Item index: " + i);
						break;
					}
				}
			}*/
			//this.rowCount = dataProvider.length;
			//trace("verticalScrollPosition before super.commit: " + this.verticalScrollPosition);
			//trace("selectedItem before super.commit: " + this.selectedItem);
			super.commitProperties();
			//trace("verticalScrollPosition after super.commit: " + this.verticalScrollPosition);
			//trace("selectedItem after super.commit: " + this.selectedItem);
			_dirty = false;
		}
//========= BEGIN ICollection Implementation ==============================================
		private var _recordCollection:Collection;
		public function get recordCollection():Collection { return this._recordCollection; }
		public function set recordCollection(col:Collection):void {
			if (col == null) { _recordCollection = null; return; }
			_recordCollection = col;
			_recordCollection.addComponentRequiringUpdate(this);
		}
		public function get cuid():String { return _recordCollection == null ? null : _recordCollection.cuid; }
		public function set cuid(val:String):void {
			var col:Collection = GMXDictionaries.getCuid(val);
			if (col == null) {
				this.recordCollection = new Collection(val);
			} else { 
				this.recordCollection = col;
			}
			_dirty = true;
			this.invalidateProperties();
		}
		private var _dirty:Boolean = false;
		public function get dirty():Boolean { return _dirty; }
		public function set dirty(val:Boolean):void {
			_dirty = val;
			//trace("dirty set: " + _dirty);
		}
//========= BEGIN ISelfBuilding Implementation ============================================
		override public function disintegrate():void {
			for (var i:int = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) { 
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			recordCollection.removeComponentRequiringUpdate(this);
			_recordCollection = null;
			super.disintegrate();
			//this.dataProvider.removeAll();
			//this.dataProvider = null;
			//trace("disintegrate");
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}