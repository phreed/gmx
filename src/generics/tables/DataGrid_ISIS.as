/*
 *      Copyright (c) Vanderbilt University, 2006-2009
 *      ALL RIGHTS RESERVED, UNLESS OTHERWISE STATED
 *
 *      Developed under contract for Future Combat Systems (FCS)
 *      by the Institute for Software Integrated Systems, Vanderbilt Univ.
 *
 *      Export Controlled:  Not Releasable to a Foreign Person or
 *      Representative of a Foreign Interest
 *
 *      GOVERNMENT PURPOSE RIGHTS:
 *      The Government is granted Government Purpose Rights to this
 *      Data or Software.  Use, duplication, or disclosure is subject
 *      to the restrictions as stated in Agreement DAAE07-03-9-F001
 *      between The Boeing Company and the Government.
 *
 *      Vanderbilt University disclaims all warranties with regard to this
 *      software, including all implied warranties of merchantability
 *      and fitness.  In no event shall Vanderbilt University be liable for
 *      any special, indirect or consequential damages or any damages
 *      whatsoever resulting from loss of use, data or profits, whether
 *      in an action of contract, negligence or other tortious action,
 *      arising out of or in connection with the use or performance of
 *      this software.
 * 
 */
package generics.tables
{
	import interfaces.ICollection;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Collection;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.events.ScrollEvent;
	
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.FlexSprite;
	import mx.events.DataGridEvent;
	import mx.events.ListEvent;
	import generics.tables.*;

	public class DataGrid_ISIS extends DataGrid implements ICollection, IField 
	{
		protected var _sendMessage:Boolean = true;
		public function get sendMessage():Boolean { return _sendMessage; }
		public function set sendMessage(val:Boolean):void { _sendMessage = val; }
		
		private var _type:int = STANDARD; // changes to TREE if there is a tree / taskOrg DataGridColumn
		public static const STANDARD:int = 0;
		public static const TREE:int = 1;	
		public static const RUID_DELIMITER:String = "##";
		
		private var _rowCountSpecified:Boolean = false;
		private var _lastFieldValue:String = "";
		protected var _referenceItemIndex:Boolean = false;
		public function get referenceItemIndex():Boolean { return _referenceItemIndex; }
		
		public function get listRendererArray():Array {
			return listItems;	
		}
		
		public function DataGrid_ISIS()
		{
			super();
			this.dataProvider = new XMLListCollection();
			this.addEventListener(ListEvent.CHANGE, change, false, 0, true);
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			
			var recordAdded:Boolean = false;
			if (xml.@referenceItemIndex.toString() == "true") { _referenceItemIndex = true; }
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.pushCurrentRecord(this.record);
				recordAdded = true;
			}
			var dataGrid:DataGrid_ISIS = this;
			var columns:Array = new Array();
			
			for each (var dataGridColumnXML:XML in xml.columns.DataGridColumn) {
				var dataGridColumn:DataGridColumn;
				if (dataGridColumnXML.@type != undefined) {
					var columnType:String = dataGridColumnXML.@type.toString();
					
					// WARNING: DO NOT USE A SWITCH STATEMENT HERE -- there can be a strange "Verify Error" in Flash
					// when you have switch statements within for each loops 
					if (columnType == "tree") { 
						var isis:DataGridTreeColumn = new DataGridTreeColumn();
						isis.fid = dataGridColumnXML.@fid.toString();
						if (dataGridColumnXML.@fontSize != undefined) {
							isis.fontSize = dataGridColumnXML.@fontSize.toString();
						}
						if (dataGridColumnXML.@buttonSize != undefined) {
							isis.buttonSize = dataGridColumnXML.@buttonSize.toString();
						}
						dataGridColumn = isis;
						dataGrid.addEventListener(ExpandTreeEvent.RESIZE, GMXComponentListeners.expandTableTree, false, 0, true);
						this._type = TREE;
					} else if (columnType == "checkBox") { 
						var checkBoxColumn:DataGridCheckBoxColumn = new DataGridCheckBoxColumn(); 
						checkBoxColumn.fid = dataGridColumnXML.@fid.toString();
						if (dataGridColumnXML.@enabled != undefined) { checkBoxColumn.enabled = GMXComponentBuilder.parseBoolean(dataGridColumnXML.@enabled.toString()); }
						dataGridColumn = checkBoxColumn;
						//dataGrid.addEventListener(ListEvent.CHANGE, GMXComponentListeners.dataGridChange, false, 0, true);							
					} else if (columnType == "icon") {
						var iconColumn:DataGridIconColumn = new DataGridIconColumn();
						iconColumn.fid = dataGridColumnXML.@fid.toString();
						dataGridColumn = iconColumn;							
					} else dataGridColumn = new DataGridColumn(dataGridColumnXML.@headerText.toString());
				} else {
					dataGridColumn = new DataGridColumn(dataGridColumnXML.@headerText.toString());
				}
				dataGridColumn.headerText = dataGridColumnXML.@headerText.toString();
				dataGridColumn.dataField = dataGridColumnXML.@fid.toString();
				dataGridColumn.headerWordWrap = true;
								
				dataGridColumn.setStyle("fontfamily", "Verdana");
				if (dataGridColumnXML.@fontSize != undefined) {
					dataGridColumn.setStyle("fontSize", Number(dataGridColumnXML.@fontSize));
				}
				if (dataGridColumnXML.@wordWrap != undefined) {
					dataGridColumn.wordWrap = dataGridColumnXML.@wordWrap.toString() == "true" ? true : false;
				}
				if (dataGridColumnXML.@fontWeight != undefined) {
					dataGridColumn.setStyle("fontWeight", dataGridColumnXML.@fontWeight.toString());
				}
				if (dataGridColumnXML.@color != undefined) {
					dataGridColumn.setStyle("color", parseInt(String(dataGridColumnXML.@color),16));
				}
				if (dataGridColumnXML.@width != undefined) {
					// stupid bug where if you have horizontalScrollPolicy on auto or off, that it won't let you set width
					//--> see http://junleashed.wordpress.com/2008/07/10/flex-datagridcolumn-width-management/
					dataGridColumn.setStyle("horizontalScrollPolicy", "on");
					dataGridColumn.width = Number(dataGridColumnXML.@width) * GMXMain.SCALE;
					dataGridColumn.setStyle("horizontalScrollPolicy", "off");
				}
				if (dataGridColumnXML.@horizontalScrollPolicy != undefined) {
					dataGridColumn.setStyle("horizontalScrollPolicy", dataGridColumnXML.@horizontalScrollPolicy.toString());
				} else { dataGridColumn.setStyle("horizontalScrollPolicy", "off"); }
				if (dataGridColumnXML.@minWidth != undefined) {
					dataGridColumn.minWidth = GMXComponentBuilder.parseMM(dataGridColumnXML.@minWidth.toString());
				}
				if (dataGridColumnXML.@editable != undefined) {
					dataGridColumn.editable = GMXComponentBuilder.parseBoolean(dataGridColumnXML.@editable.toString());
					//trace("dataGridColumn.editable: " + dataGridColumn.editable);
				}
				columns.push(dataGridColumn);
			}
			
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			dataGrid.columns = columns;
			dataGrid.addEventListener(DataGridEvent.ITEM_FOCUS_OUT, GMXComponentListeners.dataGridEditEnd);
			if (xml.@cuid != undefined) {
				this.cuid = xml.@cuid.toString();
			} //else Alert.show("WARNING: Incoming layout message contains a DataGrid without a cuid... the DataGrid WILL NOT BE FUNCTIONAL!");
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
		}
		public function _set_sendMessage(val:String):void { this._sendMessage = GMXComponentBuilder.parseBoolean(val); }
		public function _set_editable(val:String):void { this.editable = GMXComponentBuilder.parseBoolean(val); }
		public function _set_sortableColumns(val:String):void { this.sortableColumns = GMXComponentBuilder.parseBoolean(val); }
		public function _set_headerHeight(val:String):void { this.headerHeight = GMXComponentBuilder.parseMM(val);  }
		public function _set_fontSize(val:String):void { this.setStyle("fontSize", parseFloat(val)); }
		public function _set_fontWeight(val:String):void { this.setStyle("fontWeight", val); }
		public function _set_fontFamily(val:String):void { this.setStyle("fontFamily", val); }
		public function _set_color(val:String):void { this.setStyle("color", GMXComponentBuilder.parseColor(val)); }
		public function _set_resizableColumns(val:String):void { this.resizableColumns = GMXComponentBuilder.parseBoolean(val); }
		public function _set_draggableColumns(val:String):void { this.draggableColumns = GMXComponentBuilder.parseBoolean(val); }
		public function _set_showHeaders(val:String):void { this.showHeaders = GMXComponentBuilder.parseBoolean(val); }
		public function _set_verticalGridLines(val:String):void { this.setStyle("verticalGridLines", GMXComponentBuilder.parseBoolean(val)); }
		public function _set_selectable(val:String):void { this.selectable = GMXComponentBuilder.parseBoolean(val); }		
		public function _set_variableRowHeight(val:String):void { this.variableRowHeight = GMXComponentBuilder.parseBoolean(val); }
		public function _set_wordWrap(val:String):void { this.wordWrap = GMXComponentBuilder.parseBoolean(val); }
		public function _set_allowMultipleSelection(val:String):void { this.allowMultipleSelection = GMXComponentBuilder.parseBoolean(val); }
		public function _set_rowCount(val:String):void {
			this.rowCount = parseInt(val);
			_rowCountSpecified = true;
		}
		public function _set_referenceItemIndex(val:String):void { _referenceItemIndex = GMXComponentBuilder.parseBoolean(val); }
		
		public function _set_messageOnSelect(val:String):void {
			if (val == "true") {
				this.addEventListener(ListEvent.CHANGE, GMXComponentListeners.dataGridChange, false, 0, true);
			} else {
				this.removeEventListener(ListEvent.CHANGE, GMXComponentListeners.dataGridChange);
			}
		}
		public function _set_cuid(val:String):void { } // handled in build function
		public function _set_fid(val:String):void { this.fid = val; }
		public function _set_ruid(val:String):void { } // handled in build function
		
		public function fieldChange(event:ListEvent):void {
			if (this.field == null) { return; }
			
			try {
				var newFieldValue:String = "";
				for (var i:int = 0; i < this.selectedIndices.length; i++) {
					var item:XML = dataProvider.getItemAt(this.selectedIndices[i]) as XML;
					var selectedRuid:String = _referenceItemIndex ? selectedIndices[i] + "" : item.@ruid.toString();
					if (newFieldValue != "") { newFieldValue += RUID_DELIMITER; }
					newFieldValue += selectedRuid;
				}
				this.field.value = newFieldValue;
			} catch (e:Error) {
				trace("ERROR: dataGridChange--event.rowIndex=" + event.rowIndex + " is out of bounds!");
				return;
			}
			if (_sendMessage) {
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, this.field));
			}
		}
		

		override protected function createChildren():void {
			super.createChildren();
			this.invalidateDisplayList();
			//this.header.filters = [new DropShadowFilter(ArtworkFilters.SHADOW_DIST, 225.0, Color.BUTTON_3D_SHADOW, 1, 5, 5, 1, 1, true),
			//					   new DropShadowFilter(ArtworkFilters.SHADOW_DIST, 45.0, Color.BUTTON_3D_GLARE, 1, 5, 5, 1, 1, true)];
			this.headerHeight = GMXComponentBuilder.HEADER_HEIGHT;
			this.drawSeparators();
		}
		
		private function change(event:ListEvent):void {
			//this.invalidateDisplayList(); // make sure all selected objects are selected
			//xtrace("DataGrid_ISIS change!");
			if (event.rowIndex >= this.dataProvider.length) { return; }
			var item:XML = this.dataProvider.getItemAt(event.rowIndex) as XML;
			if (item.@ruid != undefined) {
				var ruid:String = item.@ruid.toString();
			} else {
				trace("WARNING: expected a ruid in the DataGrid dataprovider (DataGrid_ISIS change function)");
			}
			if (ruid != null && _recordCollection != null) {
				_recordCollection.addSelectedRuid(ruid); // currently Single select. need to allow multiselect
			}
		}
		
		/*public function updateDisplay():void {
			this.commitProperties();
			this.updateDisplayList(this.unscaledWidth, this.unscaledHeight)
		}*/
		
		public function addSelectedRuid(ruid:String):void {
			if (_recordCollection == null) { trace("WARNING: DataGrid_ISIS attempted addSelectedRuid(" + ruid + ") but this datagrid has no colleciton!"); return; }
			
			_recordCollection.addSelectedRuid(ruid);
		}
		
		private function verticalScrollBarChange(event:ScrollEvent):void {
			//trace("datagrid scroll verticalScrollPosition: " + this.verticalScrollPosition);
			//trace("event scroll position: " + event.position);
			if (_recordCollection == null) { return; }
			
			_recordCollection.scrollPosition = this.verticalScrollPosition;
		}
		private function mouseWheel(event:MouseEvent):void {
			if (_recordCollection == null) { return; }
			
			_recordCollection.scrollPosition = this.verticalScrollPosition;
		}
		
		override protected function commitProperties():void {
			//xtrace("DATAGRID COMMIT PROPERTIES REACHED!! dirty=" + _dirty);
			if (_field != null && _field.value != _lastFieldValue) {					
				_lastFieldValue = _field.value;
				componentValue = _lastFieldValue;
			}
			if (_recordCollection == null || _dirty == false) {
				super.commitProperties();
				return;
			}
			//xtrace("datagrid type: " + _type);
			/*if (this.selectedItem != null) { 
				var previousSelectedRuid:String = this.selectedItem.@ruid; 
			}*/
			if (_recordCollection.selectedRuids.length != 0) {
				var previousSelectedRuid:String = _recordCollection.selectedRuids[0];
			}
			//var editingPosition:Object = editedItemPosition;
			//editingPosition.rowIndex...
			//editingPosition.columnIndex...
			
			//xtrace("PREVIOUSLY SELECTED: " + previousSelectedRuid);
			this.dataProvider = _type == STANDARD ? _recordCollection.updateDataProvider(Collection.DATA_GRID) : _recordCollection.updateDataProvider(Collection.TREE_DATA_GRID);
			if (previousSelectedRuid != null) {
				for (var i:int = 0; i < dataProvider.length; i++) {
					if (dataProvider[i].@ruid == previousSelectedRuid) {
						this.selectedIndex = i;
						//trace("found selected Item index: " + i);
						break;
					}
				}
			}
			// WHAT IS THIS HERE FOR?
			if (!_rowCountSpecified) { this.rowCount = dataProvider.length; }
			
			//trace("verticalScrollPosition before super.commit: " + this.verticalScrollPosition);
			//trace("selectedItem before super.commit: " + this.selectedItem);
			super.commitProperties();
			//trace("verticalScrollPosition after super.commit: " + this.verticalScrollPosition);
			//trace("selectedItem after super.commit: " + this.selectedItem);
			_dirty = false;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			//trace("UPDATE DISPLAY: this.verticalScrollBar != null: " + (this.verticalScrollBar != null));
			//trace("UPDATE DISPLAY: this.verticalScrollBar != null: " + (this.verticalScrollBar != null));
			if (this.verticalScrollBar != null) {
				this.verticalScrollBar.addEventListener(ScrollEvent.SCROLL, verticalScrollBarChange);
				this.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
			}
			if (_recordCollection != null) {
				this.verticalScrollPosition = _recordCollection.scrollPosition;
			}
			//trace("SCROLLPOSITION: " + (this.verticalScrollPosition = _recordCollection.scrollPosition));
			//this.FIX THIS  AND THE RUIDs on expand
			//if (_recordCollection != null) { _recordCollection.scrollPosition = this.verticalScrollPosition; 
			//	trace("scrollposition: " + this.verticalScrollPosition);
			//}
			//trace("verticalScrollPosition before super.update: " + this.verticalScrollPosition);
			//trace("selectedItem before super.update: " + this.selectedItem);
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			
			//trace("verticalScrollPosition after super.update: " + this.verticalScrollPosition);
			//trace("selectedItem after super.update: " + this.selectedItem);
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
		private var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			for (var i:int = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) {
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			if (_recordCollection == null) { return; }
			recordCollection.removeComponentRequiringUpdate(this);
			_recordCollection = null;
			//this.dataProvider.removeAll();
			//this.dataProvider = null;
			//trace("disintegrate");
		}
		public function setAttributes(attributes:Attributes):void {
			// need to implement it so that datagrid can be enabled /disabled even though it doesn't have its own field
			return;
		}
//========= END ISelfBuilding Implementation ==============================================

//====== BEGIN IField implementation =========================================================
		public function get componentValue():String { 
			if (_referenceItemIndex) {
				return this.selectedIndex + "";
			} else {
				return ""; // I NEED TO FIX THIS
			}
		}
		public function set componentValue(val:String):void {
			var splitRuids:Array = val.split(RUID_DELIMITER);
			var i:int, j:int;
			var splitIndices:Array = new Array();
			if (_referenceItemIndex) {
				for (i = 0;  i < splitRuids.length; i++) {
					splitIndices.push(parseInt(splitRuids[i]));
				}
			} else {
				var provider:XMLListCollection = this.dataProvider as XMLListCollection;
				for (i = 0; i < splitRuids.length; i++) {
					for (j = 0; j < provider.length; j++) {
						var xml:XML = provider[j] as XML;
						if (xml.@ruid != undefined && xml.@ruid.toString() == splitRuids[i]) {
							splitIndices.push(j);
						}
					}
				}
			}
			this.selectedIndices = splitIndices;
		}
		protected var _field:Field;
		public function get field():Field { return _field; }
		public function set field(newField:Field):void {
			_field = newField;
		}
		public function get fid():String { if (_field == null) return null; else return _field.fid; }
		public function set fid(val:String):void {
			if (GMXDictionaries.getCurrentRecord() == null) { return; }
			IFieldStandardImpl.setFid(this, val);
			this.addEventListener(ListEvent.CHANGE, fieldChange, false, 0, true);
		}
		
		protected var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			IFieldStandardImpl.setRuid(this, val);
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set layout(val:String):void {
			IFieldStandardImpl.setLayout(val);
		}
//====== END IField implementation =========================================================
	}
}