package generics
{
	import generics.Canvas_X;
	import generics.VBox_X;
	import interfaces.IField;
	import interfaces.UIComponent_ISIS;
	import flash.filters.GlowFilter;
	import generics.CheckBox_X;
	import generics.ComponentCreationEvent;
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import generics.CheckBox_X;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import constants.Size;
	import mx.controls.CheckBox;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.core.UIComponent;

	/**
	 * ...
	 * @author 
	 */
	public class CheckBoxHierarchicalGroup_X extends UIComponent_ISIS implements IMultiField, IField
	{		
		override public function get fieldNames():Array { return []; }
		override public function get defaultValues():Array { return []; }
		private static const DEFAULT_COMPONENT_HEIGHT:Number = 24 * Size.MM;
		private static const DEFAULT_COMPONENT_WIDTH:Number = 24 * Size.MM;
		
		private var _dimensionsDirty:Boolean = false;
		private var _checkBoxes:Vector.<CheckBox_X> = new Vector.<CheckBox_X>();
		private var _parentCheckBox:CheckBox_X = new CheckBox_X();
		private var _vBox:VBox_X = new VBox_X();
		
		public function CheckBoxHierarchicalGroup_X() {
			super();
			this.addEventListener(ComponentCreationEvent.CREATED, componentCreated, false, 0, true);
			this.addEventListener(CheckBoxHierarchicalGroup_ISIS_Event.CHECK_BOX_GROUP_CHANGE, groupChange, false, 0 , true);
			this.addChild(_parentCheckBox);
			this.addChild(_vBox);
			this.height = 6 * Size.MM;
			_vBox.x = 6 * Size.MM;
			_vBox.setStyle("verticalGap", 2 * Size.MM);
		}
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				recordAdded = true;
				GMXDictionaries.pushCurrentRecord(this._record);
				delete xml.@ruid;
			}
			this.fields = xml;
			if (xml.@fid != undefined) { this.fid = xml.@fid.toString(); }
			if (xml.@text != undefined) { _parentCheckBox.label = xml.@text.toString(); }
			if (xml.@glowColor != undefined) { _parentCheckBox.FOCUS_HALO = new GlowFilter(GMXComponentBuilder.parseColor(xml.@glowColor.toString()), 1, 6.0, 6.0, 2.5, 1) }
			if (xml.@flexibleWidth != undefined) { _parentCheckBox.flexibleWidth = GMXComponentBuilder.parseBoolean(xml.@flexibleWidth.toString()); }
			//if (xml.@overColor != undefined) { this.overColor = GMXComponentBuilder.parseColor(xml.@overColor.toString());	}
			//if (xml.@overAlpha != undefined) { _highlightSprite.alpha = Number(xml.@overAlpha); }
			if (xml.@label != undefined) { _parentCheckBox.label = xml.@label.toString(); }
			if (xml.@buttonSize != undefined) { _parentCheckBox.buttonSize = GMXComponentBuilder.parseMM(xml.@buttonSize.toString()); }			
			if (xml.@layout != undefined) { IFieldStandardImpl.setLayout(xml.@layout.toString()); }
			if (xml.@sendMessage != undefined) { _parentCheckBox.sendMessage = GMXComponentBuilder.parseBoolean(xml.@sendMessage.toString()); }
			if (xml.@fontSize != undefined) { _parentCheckBox.labelComponent.setStyle("fontSize", parseFloat(xml.@fontSize)); }
			GMXComponentBuilder.setStandardValues(xml, this);
			var tempWidth:String = xml.@width.toString();
			var tempHeight:String = xml.@height.toString();
			var tempLayout:String = xml.@layout.toString();
			delete xml.@width;
			delete xml.@height;
			delete xml.@layout;
			GMXComponentBuilder.processXML(_vBox, xml);
			if (tempWidth != "") xml.@width = tempWidth;
			if (tempHeight != "") xml.@height = tempHeight;
			if (tempLayout != "") xml.@layout = tempLayout;
						
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			updateParentValue();
			this.invalidateProperties();
		}
		
		private function componentCreated(event:ComponentCreationEvent):void {
			//event.stopPropagation();
			var checkBox:CheckBox_X = event.component as CheckBox_X;
			if (checkBox == null || checkBox == _parentCheckBox) { return; }
			
			for (var i:int = 0; i < _checkBoxes.length; i++) {
				if (_checkBoxes[i] == checkBox) { return; }
			}
			_checkBoxes.push(checkBox);
			updateParentValue();
		}
		private var _forceSyncWithParent:Boolean = false;
		private function groupChange(event:CheckBoxHierarchicalGroup_ISIS_Event):void {
			var i:int;
			var requireSendingMessage:Boolean = false;
			if (event.target == _parentCheckBox || _forceSyncWithParent == true) {
				for (i = 0; i < _checkBoxes.length; i++) {
					if (_checkBoxes[i].componentValue != _parentCheckBox.componentValue ) {
						_checkBoxes[i].componentValue = _parentCheckBox.componentValue;
						if (_checkBoxes[i].field != null) { 
							_checkBoxes[i].field.value = _parentCheckBox.componentValue; 
							requireSendingMessage = true;
						}
					}
					if (_checkBoxes[i].record != null) { _checkBoxes[i].dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true)); }
				}
				if (_parentCheckBox.componentValue == "false") { _selectedValue = "None"; }
				else { _selectedValue = "All"; }
			} else { updateParentValue(); }
			if (requireSendingMessage) {
				if (_field != null) { _field.value = _selectedValue; }
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD));
			}
		}
		private var _selectedValue:String = "None";
		
		private function updateParentValue():void {
			var numChecked:int = 0;
			var originalValue:String = _selectedValue;
			for (var i:int = 0; i < _checkBoxes.length; i++) {
				// count the number of checked checkboxes to determine what the "parent" checkbox should show (true, partial, or false)
				if (_checkBoxes[i].componentValue == "true") { numChecked++; _selectedValue = _checkBoxes[i].label; }
			}
			if (numChecked == _checkBoxes.length) { _parentCheckBox.componentValue = "true"; _selectedValue = "All"; }
			else if (numChecked == 0) { _parentCheckBox.componentValue = "false"; _selectedValue = "None"; }
			else { _parentCheckBox.componentValue = "partial"; if (numChecked > 1) { _selectedValue = "Multiple"; } }
			/*if (originalValue != _parentCheckBox.componentValue && _parentCheckBox.field != null) {
				_parentCheckBox.field.value = _parentCheckBox.componentValue;
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
			}*/
			if (originalValue != _selectedValue && this.field != null) {
				this.field.value = _selectedValue;
				this.dispatchEvent(new RecordEvent(RecordEvent.SELECT_FIELD, null, true, true));
			}
		}
		
		override public function set enabled(val:Boolean):void {
			super.enabled = val;
		}
		override public function set width(val:Number):void {
			_dimensionsDirty = true;
			_parentCheckBox.width = val;
			_vBox.width = val;
			super.width = val;
		}
		override public function set height(val:Number):void {
			_dimensionsDirty = true;
			if (val > _parentCheckBox.height) {
				_vBox.height = val - _parentCheckBox.height;
			} else {
				_vBox.height = 0;
			}	
			super.height = val;
		}
		override protected function createChildren():void {
			super.createChildren();
		}
		override protected function measure():void {
			super.measure();
		}
		override protected function commitProperties():void {
			super.commitProperties();
		}		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {			
			if (_dimensionsDirty) {
				
			}
			_vBox.x = 6 * Size.MM;
			_vBox.y = _parentCheckBox.height + 2 * Size.MM;
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
//====== BEGIN IField implementation =========================================================
		public function set componentValue(val:String):void {
			this._selectedValue = val;
			var event:CheckBoxHierarchicalGroup_ISIS_Event = new CheckBoxHierarchicalGroup_ISIS_Event(CheckBoxHierarchicalGroup_ISIS_Event.CHECK_BOX_GROUP_CHANGE);
			if (val == "None") {
				_parentCheckBox.componentValue = "false";
				_forceSyncWithParent = true;
				groupChange(event);
			} else if (val == "All") {
				_parentCheckBox.componentValue = "true";
				_forceSyncWithParent = true;
				groupChange(event);
			}
		}
		public function get componentValue():String {
			return _selectedValue;
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
		}
//====== END IField implementation =========================================================
	}
}
