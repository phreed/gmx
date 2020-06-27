package generics 
{
	import generics.ResizingBoxEvent;
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	
	import mx.containers.VBox;
	import mx.controls.Alert;
	/**
	 * ...
	 * @author Zach Fleetwood
	 */
	public class VBox_X extends VBox implements IMultiField
	{				
		protected var _backgroundColorValue:int = -1;
		public function set backgroundColorValue(val:int):void {
			_backgroundColorValue = val;
		}
		
		public function VBox_X() 
		{
			super();
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			
			if (xml.@horizontalAlign != undefined) { this.setStyle("horizontalAlign", xml.@horizontalAlign.toString()); }
			if (xml.@backgroundColor != undefined) { this.backgroundColorValue = parseInt(String(xml.@backgroundColor),16); }
						
			var recordAdded:Boolean = false; 
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.recordStack.push(this.record);
				recordAdded = true;
			}
			GMXComponentBuilder.setStandardValues(xml, this);
			if (xml.@type != undefined) {
				switch(xml.@type.toString()) {
					case "buttonGroup":
						this.setStyle("verticalGap", Size.MM);
						break;
				}
			}
			if (xml.@verticalGap != undefined) {
				this.setStyle("verticalGap", GMXComponentBuilder.parseMM(xml.@verticalGap.toString()));
			}
			GMXComponentBuilder.processXML(this, xml);
			if (recordAdded) {
				GMXDictionaries.recordStack.pop();
			}
		}
		
		public var heightDirty:Boolean = false;
		override public function set height(val:Number):void {
			super.height = val;
			heightDirty = true;
		}
		
		override protected function measure():void {
			super.measure();
			dispatchEvent(new ResizingBoxEvent(ResizingBoxEvent.BOX_RESIZE));
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			if (_backgroundColorValue != -1) {
				this.graphics.clear();
				this.graphics.beginFill(_backgroundColorValue);
				
				if (!isNaN(this.width) && !isNaN(this.height)) {
					this.graphics.drawRect(0,0,this.width,this.height);
				}
			}
			if (_flexible == true && heightDirty) {
				resizeFlexibles();
				heightDirty = false;
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		public function resizeFlexibles():void {
			// update the children
			//trace("update flexible VBOX");
			var i:int;
			var inflexibleComponentTotalHeight:Number = 0;
			var selfBuilding:ISelfBuilding;
			//var inflexibleSelfBuildingComponents:Vector.<ISelfBuilding> = new Vector.<ISelfBuilding>();
			var flexibleSelfBuildingComponents:Vector.<ISelfBuilding> = new Vector.<ISelfBuilding>();
			var verticalGap:Number = this.getStyle("verticalGap");
			var totalPaddingTopBottom:Number = this.getStyle("paddingTop") + this.getStyle("paddingBottom");
			for (i = 0; i < numChildren; i++) {
				inflexibleComponentTotalHeight += verticalGap;
				if (this.getChildAt(i) is ISelfBuilding) {
					selfBuilding = this.getChildAt(i) as ISelfBuilding;
					if (!selfBuilding.flexible) {
						inflexibleComponentTotalHeight += selfBuilding.height;
					} else {
						flexibleSelfBuildingComponents.push(selfBuilding);
					}
				}
			}
			inflexibleComponentTotalHeight += totalPaddingTopBottom;
			var heightLeft:Number = this.height - inflexibleComponentTotalHeight;
			if (heightLeft < 0) { 
				//Alert.show("WARNING: ResizingBoxContainer does not have enough room by " + heightLeft + " pixels!");
				heightLeft = 0;
			}
			var heightPerFlexibleComponent:Number = heightLeft / flexibleSelfBuildingComponents.length;
			
			for (i = 0; i < flexibleSelfBuildingComponents.length; i++) {
				flexibleSelfBuildingComponents[i].height = heightPerFlexibleComponent;
			}
		}
		
//========= BEGIN IMultiField Implementation ==============================================
		protected var _record:Record;
		public function get record():Record { return this._record; }
		public function set record(rec:Record):void {
			_record = rec;
			this.addEventListener(RecordEvent.SELECT_FIELD, dataEdit);
		} 
		public function get ruid():String { return _record == null ? null : _record.ruid; }
		public function set ruid(val:String):void {
			var rec:Record = GMXDictionaries.getRuid(val);
			if (rec == null) {
				this.record = new Record(val);
			} else { 
				this.record = rec;
			}
		}
		public function dataEdit(event:RecordEvent):void {
			Record.dataEdit(event, _record);
		}
		public function set fields(xml:XML):void
		{
			for each (var fieldXML:XML in xml.field) {
				var fieldName:String = fieldXML.@name.toString();
				if (fieldXML.@fid == undefined) {
					Alert.show("WARNING: field doesn't have a fid.");
					continue;
				}
				var fieldId:String = fieldXML.@fid.toString();
				
				var fieldValue:String = null;
				if (fieldXML.@value == undefined) {
					fieldValue = "";
				} else fieldValue = fieldXML.@value.toString();
				
				var rec:Record = GMXDictionaries.getCurrentRecord() as Record;
				if (rec == null) { // record does not yet exist... can't add
					Alert.show("WARNING: Not a Record on the RecordStack!!!  Type found: " + GMXDictionaries.getCurrentRecord());
					return;
				} 
				var newField:Field = rec.getField(fieldId) as Field;
				if (newField == null) { 
					newField = new Field(fieldId);
				}
				switch (fieldName) {
					// no special names
					default:
						// in case it does not match an expected "name" property (and hence does not map to any components that
						// belong to this component, the field is still added and can store & report values
						newField.value = (fieldValue != null) ? fieldValue : "";
				} // if it doesn't match these, it will stay the way it was
			}
		}	
//========= BEGIN ISelfBuilding Implementation ============================================
		protected var _flexible:Boolean = false;
		public function get flexible():Boolean { return _flexible; }
		public function set flexible(val:Boolean):void { _flexible = val; }
		public function disintegrate():void {
			for (var i:int = 0; i < numChildren; i++) {
				if (this.getChildAt(i) is ISelfBuilding) {
					var childSelfBuilding:ISelfBuilding = this.getChildAt(i) as ISelfBuilding;
					childSelfBuilding.disintegrate();
				}
			}
			_record = null;
		}
		public function setAttributes(attributes:Attributes):void {
			IFieldStandardImpl.setAttributes(this, attributes);
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}