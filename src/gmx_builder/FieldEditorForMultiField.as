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
	import mx.collections.XMLListCollection;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	/**
	 * ...
	 * @author 
	 */
	public class FieldEditorForMultiField extends VBox
	{
		private static const NUM_COLUMNS:int = 4;
		
		private var dataGrid:DataGrid;
		
		private var _latestRuid:String = "";
		
		public function FieldEditorForMultiField()
		{
			super();
			this.width = 400;
			this.height = 300;
			this.addEventListener(MouseEvent.MOUSE_DOWN, dragDown);

			this.setStyle("backgroundColor", 0xff0000);
			var titleBar:HBox = new HBox();
			titleBar.percentWidth = 100;
			titleBar.setStyle("verticalAlign", "middle");
			titleBar.setStyle("borderStyle", "solid");
			titleBar.setStyle("borderThickness", 1.0);
			titleBar.setStyle("borderColor", 0x000000);
			titleBar.setStyle("horizontalGap", 5.0);
			titleBar.height = 30;
			this.addChild(titleBar);
			titleBar.setStyle("horizontalGap", 10);
			
			var button:Button = new Button();
			button.label = "Create Entry";
			button.addEventListener(MouseEvent.CLICK, addEntry);
			titleBar.addChild(button);
			
			button= new Button();
			button.label = "Update XML";
			button.addEventListener(MouseEvent.CLICK, updateXML);
			titleBar.addChild(button);
			
			button= new Button();
			button.label = "Exit";
			button.addEventListener(MouseEvent.CLICK, exit);
			titleBar.addChild(button);
			
			dataGrid = new DataGrid();
			dataGrid.height = 270;
			dataGrid.percentWidth = 100;
			dataGrid.editable = true;
			var column:DataGridColumn;
			var columns:Array = new Array();
			for (var i:int = 0; i < NUM_COLUMNS; i++) {
				switch(i) {
					case 0: column = new DataGridColumn("fid"); column.dataField = "fid"; break;
					case 1: column = new DataGridColumn("name"); column.dataField = "name"; break;
					case 2: column = new DataGridColumn("value (optional)"); column.dataField = "value"; break;
					case 3: column = new DataGridColumn("ruid (optional)"); column.dataField = "ruid"; break;
				}
				column.headerWordWrap = true;
				
				columns.push(column);
			}
			dataGrid.columns = columns;
			this.addChild(dataGrid);
		}
		
		public function updateDataProvider(selectedXML:XML):void {
			if (selectedXML == null) { dataGrid.dataProvider = new ArrayCollection([]); return;  }
			var provider:ArrayCollection = new ArrayCollection();
			for each (var fieldXML:XML in selectedXML.field) {
				var entry:Object = new Object();
				if (fieldXML.@fid != undefined) { entry["fid"] = fieldXML.@fid.toString(); } else { entry["fid"] = ""; }
				if (fieldXML.@name != undefined) { entry["name"] = fieldXML.@name.toString(); } else { entry["name"] = ""; }
				if (fieldXML.@value != undefined) { entry["value"] = fieldXML.@value.toString(); } else { entry["value"] = ""; }
				if (fieldXML.@ruid != undefined) { entry["ruid"] = fieldXML.@ruid.toString(); } else { entry["ruid"] = ""; }
				provider.addItem(entry);
			}
			dataGrid.dataProvider = provider;
		}
		
		
		private function addEntry(event:MouseEvent):void {
			var provider:ArrayCollection = dataGrid.dataProvider as ArrayCollection;
			var entry:Object = new Object();
			entry["fid"] = entry["name"] = entry["value"] = entry["ruid"] = "";
			provider.addItem(entry);
		}
		
		private function updateXML(event:MouseEvent):void {
			if (GMXBuilder.selectedXML == null) { Alert.show("No object is selected... you must select an object to apply these fields to!"); return; }
			delete GMXBuilder.selectedXML.field;
			var provider:ArrayCollection = dataGrid.dataProvider as ArrayCollection;
			for (var i:int = 0; i < provider.length; i++) {
				var newField:XML = new XML(<field/>);
				var obj:Object = provider.getItemAt(i) as Object;
				
				if (obj["fid"] == null || obj["fid"] == "") { continue; }
				
				newField.@fid = obj["fid"];
				if (obj["name"] != null && obj["name"] != "") { newField.@name = obj["name"]; }
				if (obj["value"] != null && obj["value"] != "") { newField.@value = obj["value"]; }
				if (obj["ruid"] != null && obj["ruid"] != "") { newField.@ruid = obj["ruid"]; }
				
				GMXBuilder.selectedXML.appendChild(newField);
			}
			GMXBuilder.appendedXMLUpdate();
		}
		
		private function exit(event:MouseEvent):void {
			GMXMain.PopUps.removeChild(this);
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