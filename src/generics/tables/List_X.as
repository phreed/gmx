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
	import flash.events.FocusEvent;
	import flash.geom.Vector3D;
	import interfaces.ICollection;
	import interfaces.IField;
	import interfaces.IFieldStandardImpl;
	import interfaces.ISelfBuilding;
	import mx.collections.ArrayCollection;
	import mx.events.FlexEvent;
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

	public class List_X extends DataGrid implements IField
	{
		private var _rowCountSpecified:Boolean = false;
		private var _fieldValue:String = "";
		private var _dataFieldName:String = null;
		
		public function get listRendererArray():Array {
			return listItems;	
		}
		
		private var _selectionSprite:FlexSprite;
		private var _rollOverSprite:FlexSprite; 
		public function List_X()
		{
			super();
			this.dataProvider = new XMLListCollection();
			this.addEventListener(ListEvent.CHANGE, change, false, 0, true);
			this.addEventListener(ListEvent.ITEM_ROLL_OVER, itemOver, false, 0, true);
			this.addEventListener(ListEvent.ITEM_ROLL_OUT, itemOut, false, 0, true);
		}
		
		public function build(xml:XML):void { 
			if (xml == null) { return; }
			var i:int;
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
			}
			var columns:Array = new Array();
			for each (var dataGridColumnXML:XML in xml.DataGridColumn) {
				var dataGridColumn:DataGridColumn;
				if (dataGridColumnXML.@type != undefined) {
					var columnType:String = dataGridColumnXML.@type.toString();
					if (columnType == "icon") {
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
				if (dataGridColumnXML.@fontSize != undefined) { dataGridColumn.setStyle("fontSize", Number(dataGridColumnXML.@fontSize)); }
				if (dataGridColumnXML.@wordWrap != undefined) { dataGridColumn.wordWrap = dataGridColumnXML.@wordWrap.toString() == "true" ? true : false; }
				if (dataGridColumnXML.@fontWeight != undefined) { dataGridColumn.setStyle("fontWeight", dataGridColumnXML.@fontWeight.toString()); }
				if (dataGridColumnXML.@color != undefined) { dataGridColumn.setStyle("color", parseInt(String(dataGridColumnXML.@color),16)); }
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
				if (dataGridColumnXML.@minWidth != undefined) {	dataGridColumn.minWidth = GMXComponentBuilder.parseMM(dataGridColumnXML.@minWidth.toString()); }
				if (dataGridColumnXML.@editable != undefined) { dataGridColumn.editable = GMXComponentBuilder.parseBoolean(dataGridColumnXML.@editable.toString()); }
				columns.push(dataGridColumn);
			}
			if (xml.@editable != undefined) { this.editable = xml.@editable.toString() == "true" ? true : false; }
			GMXComponentBuilder.setStandardValues(xml, this);
			if (columns.length == 0) {
				Alert.show("ERROR: List_ISIS was expecting at least 1 column!");
			} else {
				dataGridColumn = columns[0]; // use the first column
				_dataFieldName = dataGridColumn.dataField;
				if (xml.@dataProvider != undefined) {
					var splitStrings:Array = GMXComponentBuilder.parseStringArray(xml.@dataProvider.toString());
					var dataProviderArray:ArrayCollection = new ArrayCollection();
					for (i = 0; i < splitStrings.length; i++) {
						var obj:Object = new Object();
						obj[_dataFieldName] = splitStrings[i];
						dataProviderArray.addItem(obj);
					}
					this.dataProvider = dataProviderArray;
				} else {
					Alert.show("ERROR: List_ISIS was expecting a dataProvider attribute!");
				}
			}
			// have to set dataprovider before setting the fid
			if (xml.@fid != undefined) {
				this.fid = xml.@fid.toString();
			}
			
			if (xml.@sortableColumns != undefined) { this.sortableColumns = xml.@sortableColumns.toString() == "true" ? true : false; }
			if (xml.@fontSize != undefined) { this.setStyle("fontSize", Number(xml.@fontSize)); }
			if (xml.@fontWeight != undefined) { this.setStyle("fontWeight", xml.@fontWeight.toString()); }
			if (xml.@fontFamily != undefined) { this.setStyle("fontFamily", xml.@fontFamily.toString()); }
			if (xml.@color != undefined) { this.setStyle("color", parseInt(String(xml.@color),16)); }
			if (xml.@resizableColumns != undefined) { this.resizableColumns = xml.@resizableColumns.toString() == "true" ? true : false; }
			if (xml.@draggableColumns != undefined) { this.draggableColumns = xml.@draggableColumns.toString() == "true" ? true : false; }
			if (xml.@showHeaders != undefined) { this.showHeaders = xml.@showHeaders.toString() == "true" ? true : false; }
			if (xml.@verticalGridLines != undefined) { this.setStyle("verticalGridLines", xml.@verticalGridLines.toString() == "true" ? true : false); }
			if (xml.@selectable != undefined) { this.selectable = xml.@selectable.toString() == "true" ? true : false; }
			if (xml.@rowCount != undefined) { this.rowCount = parseInt(xml.@rowCount.toString()); _rowCountSpecified = true; }
			if (xml.@variableRowHeight != undefined) { this.variableRowHeight = xml.@variableRowHeight.toString() == "true" ? true : false;	}
			if (xml.@wordWrap != undefined) { this.wordWrap = xml.@wordWrap.toString() == "true" ? true : false; }
			if (xml.@messageOnSelect != undefined) {
				if (xml.@messageOnSelect.toString() == "true" ? true : false) {
					this.addEventListener(ListEvent.CHANGE, GMXComponentListeners.dataGridChange, false, 0, true);
				} else { 
					this.removeEventListener(ListEvent.CHANGE, GMXComponentListeners.dataGridChange);
				}
			}
			this.columns = columns;
			if (recordAdded) { GMXDictionaries.popCurrentRecord(); }
			if (field != null) { 
				if (xml.@attributes != undefined) { this.field.attributes.updateAttributesFromLayout(xml.@attributes.toString()); }
			}
			this.addEventListener(DataGridEvent.ITEM_FOCUS_OUT, GMXComponentListeners.dataGridEditEnd);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			//this.header.filters = [new DropShadowFilter(ArtworkFilters.SHADOW_DIST, 225.0, Color.BUTTON_3D_SHADOW, 1, 5, 5, 1, 1, true),
			//					   new DropShadowFilter(ArtworkFilters.SHADOW_DIST, 45.0, Color.BUTTON_3D_GLARE, 1, 5, 5, 1, 1, true)];
			this.headerHeight = GMXComponentBuilder.HEADER_HEIGHT;
			this.drawSeparators();
		}
		
		private function change(event:ListEvent):void {
			var dataProviderArray:ArrayCollection = this.dataProvider as ArrayCollection;
			var selectedRow:Object = dataProviderArray[event.rowIndex];
			_fieldValue = selectedRow[_dataFieldName];
			if (_field != null) { 
				_field.value = _fieldValue;
				var recordEvent:RecordEvent = new RecordEvent(RecordEvent.SELECT_FIELD, _field, true, true);
				this.dispatchEvent(recordEvent);
			}			
		}
		
		private function itemOver(event:ListEvent):void {
			
		}
		
		private function itemOut(event:ListEvent):void {
			
		}
		
		override protected function commitProperties():void {
			if (_field != null && _field.value != _fieldValue) { 
				this.componentValue = field.value;
			}
			super.commitProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		public function set componentValue(val:String):void {
			_fieldValue = val;
			var dataProviderArray:ArrayCollection = this.dataProvider as ArrayCollection;
			var itemIndex:int = -1;
			for (var i:int = 0; i < dataProviderArray.length; i++) {
				if (dataProviderArray.getItemAt(i)[_dataFieldName] == _fieldValue) {
					itemIndex = i;
					break;
				}
			}
			if (itemIndex != -1) { this.selectedIndex = itemIndex; }
		}
		public function get componentValue():String {
			var dataProviderArray:ArrayCollection = this.dataProvider as ArrayCollection;
			var row:Object = dataProviderArray.getItemIndex(selectedIndex);
			if (row == null) { return null; }
			return row[_dataFieldName];
		}
		
//====== BEGIN IField implementation =========================================================
		protected var _field:Field;
		public function get field():Field { return _field; }
		public function set field(newField:Field):void {
			_field = newField;
		}
		public function get fid():String { if (_field == null) return null; else return _field.fid; }
		public function set fid(val:String):void {
			if (GMXDictionaries.getCurrentRecord() == null) { return; }
			IFieldStandardImpl.setFid(this, val);
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
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			_record = null;
			if (field == null) { return; }
			
			_field.removeComponentRequiringUpdate(this);
			_field = null;
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}