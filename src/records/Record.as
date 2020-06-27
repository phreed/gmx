package records 
{
	import generics.Button_X;
	import flash.utils.Dictionary;
	import GMX.Data.FieldVO;
	import GMX.Data.RecordVO;
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import records.RecordRef;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author 
	 */
	public class Record
	{
		public function Record(ruid:String = null) {
			this.ruid = ruid;
		}
		
		
//============ BEGIN RecordRef functions ======================================================================		
		protected var _recordRefs:Vector.<RecordRef> = new Vector.<RecordRef>;
		public function get recordRefs():Vector.<RecordRef> { return _recordRefs; }
		public function set recordRefs(val:Vector.<RecordRef>):void { _recordRefs = val; }
		public function addRecordRef(newRecordRef:RecordRef):void {
			if (newRecordRef == null || containsRecordRef(newRecordRef) == true) { return; }
			
			newRecordRef.record = this;
			_recordRefs.push(newRecordRef);
		}
		public function removeRecordRef(toBeRemoved:RecordRef):Boolean {
			for (var i:int = 0; i < _recordRefs.length; i++) {
				if (_recordRefs[i] == toBeRemoved) {
					// this is called from within the RecordRef class: disconnect function
					_recordRefs[i].record = null;
					_recordRefs.splice(i, 1);
					return true;
				}
			}
			return false;
		}
		public function containsRecordRef(recordRef:RecordRef):Boolean {
			for (var i:int = 0; i < _recordRefs.length; i++) {
				if (_recordRefs[i] == recordRef) {
					return true;
				}
			}
			return false;
		}
		public function getRecordRefByCollection(parentCollection:Collection):RecordRef {
			for (var i:int = 0; i < _recordRefs.length; i++) {
				if (_recordRefs[i].parentCollection == parentCollection) {
					return _recordRefs[i];
				}
			}
			return null;
		}
//============ END RecordRef functions ======================================================================
		
		public function processFieldList(fieldList:Array /*FieldVO*/):void {
			GMXDictionaries.pushCurrentRecord(this);
			var i:int;
			for (i = 0; i < fieldList.length; i++) {
				var fieldVO:FieldVO = fieldList[i] as FieldVO;
				if (fieldVO == null ) { 
					Alert.show("WARNING: ISISRecord message attempted to add a null FieldVO!");
					continue;
				}
				if (fieldVO.fid == null) {
					Alert.show("WARNING: ISISRecord message attempted to add a FieldVO without a fid!");
					continue;
				}
				var msgField:Field = _fields[fieldVO.fid] as Field;
				if (msgField == null) {
					msgField = new Field(fieldVO.fid);
					_fields[fieldVO.fid] = msgField;
				}
				msgField.value = fieldVO.value;
				//trace("recordUpdate: ruid=" + _ruid + " fid=" + fieldVO.fid + "  value=" + fieldVO.value);
			}
			GMXDictionaries.popCurrentRecord();
			for (i = 0; i < _recordRefs.length; i++) {
				if (_recordRefs[i].parentCollection != null) {
					_recordRefs[i].parentCollection.promptComponentUpdates();
				}
			}
		}
		
		
		protected var _ruid:String;
		public function get ruid():String { return _ruid; }
		public function set ruid(val:String):void { 
			_ruid = val;
			if (_ruid != null) {
				GMXDictionaries.addRuid(_ruid, this);
			}
		}
		
		protected var _layout:String;
		public function get layout():String { return _layout; }
		public function set layout(val:String):void { 
			_layout = val;
		}
		
		protected var _fields:Dictionary = new Dictionary();
		public function get fields():Dictionary { return _fields; }
		public function addField(field:Field):void {
			_fields[field.fid] = field;
		}
		
		public function getField(key:String):Field {
			return _fields[key] as Field;
		}
		
		public function recordDump():String {
			var output:String = "\nruid: " + _ruid;
			for each (var field:Field in _fields) {
				output += "\n\tfid: " + field.fid + "   val: " + field.value;
			}
			/*if (_records.length > 0) {
				output += "\n===COLLECTION RECORD====\nruid: " + _ruid;
				for each (var record:Record in _records) {
					output += "\n\t" + record.recordDump();
				}
				output += "\n===================================\n";
			}*/
			return output + "\n";
		}
		
		public function fromDataProviderXML(xml:XML):void {
			for each (var prop:XML in xml.children()) {
				var tableField:Field = _fields[prop.localName().toString()];
				if (tableField == null) {
					continue;
				}
				tableField.value = prop.text().toString();
			}
		}
		
		public function toDataProviderXML():XML {
			var xml:XML = new XML("<TableRecord ruid=\"" + _ruid + "\"></TableRecord>");
			for each (var field:Field in _fields) {
				var fieldXML:XML = new XML("<" + field.fid + ">" + field.value + "</" + field.fid + ">");
				xml.appendChild(fieldXML);
			}
			return xml;
		}
		
		public static function dataEdit(event:RecordEvent, record:Record):void {
			event.stopPropagation();
			if (record == null) {
				trace("WARNING: tried to send a message to service with a null FormRecord!");
				return;
			}
			var changedField:Field = event != null ? event.field as Field : null;
			record.sendMessage(changedField);
		}
		
		public function sendMessage(changedField:Field = null):void {
			var vo:RecordVO = new RecordVO;
			vo.ruid = this._ruid;
			vo.layout = this._layout;
			for each (var field:Field in _fields) {
				if (field.attributes.send == Attributes.SEND_NEVER) { continue; }
				else if (field.attributes.send == Attributes.SEND_CHANGE && field != changedField) { continue; }
				
				var fieldVO:FieldVO = new FieldVO();
				fieldVO.value = field.value;
				fieldVO.fid = field.fid;
				vo.fieldList.push(fieldVO);
			}
			GMXMain.do_ISISDataEdit([vo]);
		}
		
		// CURRENTLY NOT IMPLEMENTED, but the idea here is that we might want to have different socket connections
		// subscribe to certain ruids such that that record is only sent to that socket connection when it changes (ISISDataEdit).
		// Currently, the Record is sent to all connected sockets.
		protected var _subscribedList:Vector.<String>;
		public function get subscribedList():Vector.<String> { return _subscribedList; }
	}
}