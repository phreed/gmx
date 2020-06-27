package records
{
	import interfaces.ICollection;
	import GMX.Data.RuidVO;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import records.RecordRef;
	
	public class Collection {
		public static const TREE_DATA_GRID:int = -1;
		public static const DATA_GRID:int = 0;
		public static const COMBO_BOX:int = 1;
		public static const RADIO_BUTTONS:int = 2;
				
		public function Collection(newCuid:String = null) {
			this.cuid = newCuid;
		}
		
		protected var _componentsRequiringUpdate:Vector.<ICollection> = new Vector.<ICollection>;
		public function get componentsRequiringUpdate():Vector.<ICollection> { return _componentsRequiringUpdate; }
		public function set componentsRequiringUpdate(val:Vector.<ICollection>):void { _componentsRequiringUpdate = val; }
		public function addComponentRequiringUpdate(comp:ICollection):void {
			_componentsRequiringUpdate.push(comp);
		}
		public function removeComponentRequiringUpdate(comp:ICollection):Boolean {
			for (var i:int = 0; i < _componentsRequiringUpdate.length; i++) {
				if (_componentsRequiringUpdate[i] == comp) {
					_componentsRequiringUpdate.splice(i, 1);
					return true;
				}
			}
			return false;
		}
		
		public var _scrollPosition:int = 0;
		public function get scrollPosition():int { return _scrollPosition; }
		public function set scrollPosition(val:int):void { 
			_scrollPosition = val;
		}
		
		protected var _selectedRuids:Vector.<String> = new Vector.<String>;
		public function get selectedRuids():Vector.<String> { return _selectedRuids; }
		public function set selectedRuids(val:Vector.<String>):void { _selectedRuids = val; }
		public function isSelected(ruid:String):Boolean {
			for (var i:int = 0; i < selectedRuids.length; i++) { if (selectedRuids[i] == ruid) { return true; } }
			return false;
		}
		public function removeSelectedRuid(ruid:String):Boolean {
			for (var i:int = 0; i < selectedRuids.length; i++) {
				if (selectedRuids[i] == ruid) {
					selectedRuids.splice(i, 1);
					return true;
				}
			}
			return false;
		}
		public function addSelectedRuid(ruid:String, multiSelect:Boolean = false):void {
			if (!multiSelect) { while (_selectedRuids.length != 0) { _selectedRuids.pop(); } }
			if (!isSelected(ruid)) {
				_selectedRuids.push(ruid);
			} else { trace("WARNING: tried addSelectedRuid in Collection, but it's already selected!"); }
		}
		public function setSelectedRuids(newSelectedRuids:Vector.<String>):void {
			_selectedRuids = newSelectedRuids;
		}
		// addSelectedRuidByValue really only for something like a ComboBox that might need to lookup a selected ruid through
		// the componentValue (which is the String displayed in the actual component).
		public function addSelectedRuidByValue(val:String, fid:String = null):void {
			for (var i:int = 0; i < _recordRef.numChildren; i++) {
				var rec:Record = _recordRef.getChildRecordAt(i).record;
				var field:Field;
				if (rec == null) { continue; }
				if (fid == null) {
					for (var j:int = 0; j < _recordRef.numChildren; j++) {
						for each (field in rec.fields) {
							if (field != null && field.value == val) {
								//trace("Found record ruid=" + rec.ruid + " with fid=" + fid + " val=" + val);
								addSelectedRuid(rec.ruid);
							}
						}
					}
					continue;
				}
				// if the fid parameter is not null--we might use this for better performance if we have standardized fid's (e.g. combobox usually has fid="label")
				field = rec.getField(fid);
				if (field == null) { continue; }
				if (field.value == val) {
					//trace("Found record ruid=" + rec.ruid + " with fid=" + fid + " val=" + val);
					addSelectedRuid(rec.ruid);
				}
			}
		}
		
		
		protected var _cuid:String;
		public function get cuid():String { return _cuid; }
		public function set cuid(val:String):void { 
			_cuid = val;
			if (_cuid != null) {
				GMXDictionaries.addCuid(_cuid, this);
			}
		}
		
		public function promptComponentUpdates():void {
			for (var j:int = 0; j < _componentsRequiringUpdate.length; j++) {
				//trace("Collection COMPONENT UPDATE #" + j);
				_componentsRequiringUpdate[j].dirty = true;
				_componentsRequiringUpdate[j].invalidateProperties();
			}
		}
		
		protected var _recordRef:RecordRef = new RecordRef(null);
		public function get recordRef():RecordRef { return _recordRef; }
		/*public function get parent():Record { return _recordRef.parent }
		public function set parent(val:Record):void { _recordRef.parent = val; }
		public function get siblings():Vector.<Record> { return _recordRef.siblings; }
		public function set siblings(val:Vector.<Record>):void { _recordRef.siblings = val;  }
		public function addSiblingLastRecord(record:Record):void { _recordRef.addSiblingLastRecord(record); }
		public function addSiblingBeforeRecord(newRec:Record):void { _recordRef.addSiblingBeforeRecord(newRec); }
		public function addSiblingAfterRecord(newRec:Record):void { _recordRef.addSiblingAfterRecord(newRec);}
		public function addSiblingFirstRecord(newRec:Record):void { _recordRef.addSiblingFirstRecord(newRec);}
		public function removeSiblingRecord(record:Record):Boolean { return _recordRef.removeSiblingRecord(record); }
		public function getSiblingRecordAt(index:int):Record { return _recordRef.getSiblingRecordAt(index); }		
		public function get children():Vector.<Record> { return _recordRef.children; }
		public function set children(val:Vector.<Record>):void { _recordRef.children = val; }
		public function addChildRecord(record:Record):void { _recordRef.addChildRecord(record); }
		public function removeChildRecord(record:Record):Boolean { return _recordRef.removeChildRecord(record); }
		public function getChildRecordAt(index:int):Record { return _recordRef.getChildRecordAt(index); }
		public function disconnect():void { _recordRef.disconnect(); }
		public function splice():void { _recordRef.splice(); } // connect children up to the parent*/
		public function get numChildren():int {
			return _recordRef.numChildren;
		}
		public function contains(ruid:String):Boolean {
			return _recordRef.containsChildRuid(ruid);
		}
		
		public function getNewOrOldRecord(ruid:String):Record {
			var rec:Record = GMXDictionaries.getRuid(ruid);
			if (rec == null) {
				rec = new Record(ruid);
			}
			return rec;
		}
				
		public function processRuidList(ruidList:Array):void {
			// NEED TO IMPLEMENT!
			var i:int;
			var j:int;
			var newOrOldRecordRef:RecordRef;
			var targetRecordRef:RecordRef;
			var targetRecord:Record;
			for (i = 0; i < ruidList.length; i++) {
				var ruidVO:RuidVO = ruidList[i] as RuidVO;
				if (ruidVO.ruid == null || ruidVO.ruid == "") {
					//trace("ruidVO.ruid is null!!!!!!");
					// only clear and delete are allowed
					if (ruidVO.select != null) {
						if (ruidVO.ref != null) {
							targetRecord = GMXDictionaries.getRuid(ruidVO.ref);
							if (targetRecord == null) { 
								//Alert.show("WARNING: Attempted a '" + ruidVO.select + "' select with a ref='" + ruidVO.ref +"' in Collection message.  That ref does not point to an existing records ruid!"); 
								// Not sure if we want to do this, but now it creates a new record if it doesn't exist already
								targetRecord = new Record(ruidVO.ref);
							}
							targetRecordRef = targetRecord.getRecordRefByCollection(this);
							switch(ruidVO.select.toLowerCase()) {
								case "clear": // clear the entire collection of children.. // SHOULD IT DELETE THEM FROM THE DICTIOARY?
									while (_recordRef.children.length != 0) {
										_recordRef.children[0].disconnect();
									}
									break;
								case "delete": // kill? 
									Alert.show("WARNING: Attempted a 'delete' select without a ref (meaning the collection) in Collection message.  This does not work.");
									break;
							}
						} else {
							switch(ruidVO.select.toLowerCase()) {
								case "clear":
									// SHOULD IT DELETE THEM FROM THE DICTIONARY?
									while (targetRecordRef.numChildren != 0) {
										targetRecordRef.children[0].disconnect();
									}
									break;
								case "delete":
									// SHOULD IT DELETE THEM FROM THE DICTIONARY?
									targetRecordRef.disconnect();
									break;
							}
						}
					}
					continue;
				}
				var newOrOldRecord:Record = getNewOrOldRecord(ruidVO.ruid);
				newOrOldRecordRef = newOrOldRecord.getRecordRefByCollection(this);
				if (newOrOldRecordRef == null) {
					newOrOldRecordRef = new RecordRef();
					newOrOldRecordRef.parentCollection = this;
					newOrOldRecord.addRecordRef(newOrOldRecordRef);
				}
				//trace("ruidVO.ref: '" + ruidVO.ref + "'")
				if (ruidVO.ref == null || ruidVO.ref == "") {
					switch(ruidVO.select.toLowerCase()) {
						case "first": // put as first child of the collection
							newOrOldRecordRef.deparent(); // deparent it in case it is somewhere else in the collection
							_recordRef.addChildRecord(newOrOldRecordRef, 0);
							break;
						case "last": // put as last child of the collection
						case "child":
							newOrOldRecordRef.deparent();
							_recordRef.addChildRecord(newOrOldRecordRef, _recordRef.numChildren);
							break;
						case "clear": // clear the entire collection of children.. // SHOULD IT DELETE THEM FROM THE DICTIOARY?
							while (_recordRef.children.length != 0) {
								_recordRef.children[0].disconnect();
							}
							break;
						case "delete": // kill? 
							Alert.show("WARNING: Attempted a 'delete' select without a ref (meaning the collection) in Collection message.  This does not work.");
							break;
						case "splice":
						case "after":
						case "before":
						case "parent":
							Alert.show("WARNING: Attempt a '" + ruidVO.select +"' select without a ref (meaning on the collection) in Collection message.  This select option is not allowed without a ref'd ruid.");
							break;
						default:
							Alert.show("WARNING: Collection message with ruidVO ruid='" + ruidVO.ruid +"' has unexpected select='" + ruidVO.select +"'.  "
										+ "Allowed select values are ['before', 'after', 'first', 'last', 'parent', 'child', 'clear', 'delete', 'splice']");
					}
				} else {
					targetRecord = GMXDictionaries.getRuid(ruidVO.ref);
					if (targetRecord == null) { 
						//Alert.show("WARNING: Attempted a '" + ruidVO.select + "' select with a ref='" + ruidVO.ref +"' in Collection message.  That ref does not point to an existing records ruid!"); 
						// Not sure if we want to do this, but now it creates a new record if it doesn't exist already
						targetRecord = new Record(ruidVO.ref);
					}
					targetRecordRef = targetRecord.getRecordRefByCollection(this);
					if (targetRecordRef == null) {
						targetRecordRef = new RecordRef();
						targetRecordRef.parentCollection = this;
						targetRecord.addRecordRef(targetRecordRef);
					}
					
					/*if (targetRecord.parentCollection != this) {
						Alert.show("WARNING: While processing ISISCollection message: Attempting to add a Record to a collection using ruid='" + ruidVO.ruid + "' ref='" + ruidVO.ref + "' select='" + ruidVO.select + "', "
								 + "but the cuid='" + this.cuid + "' does not match the collection to which the ref='" + ruidVO.ref + "' belongs!  This could cause a problem "
								 + "with updating the proper component's display!");
					}*/
					switch(ruidVO.select.toLowerCase()) {
						// before and after: add as sibling before or after
						case "before":
							targetRecordRef.addSiblingBeforeRecord(newOrOldRecordRef);
							break;
						case "after":
							targetRecordRef.addSiblingAfterRecord(newOrOldRecordRef);
							break;
						case "first":
							targetRecordRef.addSiblingFirstRecord(newOrOldRecordRef);
							break;
						case "last":
							targetRecordRef.addSiblingLastRecord(newOrOldRecordRef);
							break;
						case "parent":
							newOrOldRecordRef.addChildRecord(targetRecordRef);
							break;
						case "child":
							targetRecordRef.addChildRecord(newOrOldRecordRef);
							break;
						case "clear":
							// SHOULD IT DELETE THEM FROM THE DICTIONARY?
							while (targetRecordRef.numChildren != 0) {
								targetRecordRef.children[0].disconnect();
							}
							break;
						case "delete":
							// SHOULD IT DELETE THEM FROM THE DICTIONARY?
							targetRecordRef.disconnect();
							break;
						case "splice":
							// NEED TO ENSURE THIS WORKS CORRECTLY!
							targetRecordRef.splice();
							break;
						default:
							Alert.show("WARNING: Collection message with ruidVO ruid='" + ruidVO.ruid +"' has unexpected select='" + ruidVO.select +"'"
										+ ". allowed select values are ['before', 'after', 'first', 'last', 'parent', 'child', 'clear', 'delete', 'splice']");
					}
				}
			}
			promptComponentUpdates();
		}
		
		private function addNode(record:Record, dataProvider:XMLListCollection, level:int, tree:Boolean = false ):void {
			var xml:XML = record.toDataProviderXML();
			xml.appendChild(new XML(<levelInTreeDataGrid>{level}</levelInTreeDataGrid>));
			var pertinentRecordRef:RecordRef = record.getRecordRefByCollection(this);
			if (pertinentRecordRef == null) {
				Alert.show("WARNING: Collection.addNode did not find a RecordRef that pointed to the collection cuid=" + _cuid + " in the record ruid=" + record.ruid);
				return;
			}
			if (pertinentRecordRef.numChildren == 0 || tree == false) {
				dataProvider.addItem(xml);
				return;
			}
			// add special XML nodes to indicate to a DataGrid that it has a tree column and to display it correctly
			xml.appendChild(new XML(<showExpandButton>true</showExpandButton>));
			xml.appendChild(new XML(<showChildren>{pertinentRecordRef.showChildren}</showChildren>));
			xml.appendChild(new XML(<ruidForExpand>{record.ruid}</ruidForExpand>));
			dataProvider.addItem(xml);
			if (pertinentRecordRef.showChildren == false) {
				return;
			}
			
			for (var i:int = 0; i < pertinentRecordRef.numChildren; i++) {
				addNode(pertinentRecordRef.children[i].record, dataProvider, level + 1, true);
			}
		}
		
		private function addComboBoxEntry(record:Record, dataProvider:XMLListCollection):void {
			var newList:XMLList;
			//var newNode:XML;
			//trace("====> addComboBoxEntry dataProvider: " + dataProvider);
			for each (var field:Field in record.fields) {
				// only take the 1st field
				newList = new XMLList(<{record.ruid}>{field.value}</{record.ruid}>);
				if (record.layout != null) { newList.@layout = record.layout; }
				//newList = (newNode);
				break;
			}
			//trace("addComboBoxEntry newList:" + newList);
			if (newList == null) { // no field to populate it with
				newList = new XMLList(<{record.ruid}></{record.ruid}>);
			}
			if (record.layout != null) { newList.@layout = record.layout; }
			dataProvider.addItem(newList);
			//trace("addComboBoxEntry new dataProvider:" + dataProvider);
		}
		
		public function updateDataProvider(type:int):XMLListCollection {
			var dataProvider:XMLListCollection = new XMLListCollection();
			var numRecordChildren:int = recordRef.children.length;
			var i:int;
			//trace("updateCollection type: " + type);
			switch(type) {
				case TREE_DATA_GRID:
					//trace("TREE_DATA_GRID reached");
					for (i = 0; i < numRecordChildren; i++) {
						addNode(recordRef.children[i].record, dataProvider, 0, true);
					}
					//trace("NEW PROVIDER: " + dataProvider);
					break;
				case DATA_GRID:
					//trace("DATA_GRID reached");
					for (i = 0; i < numRecordChildren; i++) {
						addNode(recordRef.children[i].record, dataProvider, 0, false);
					}
					break;
				case COMBO_BOX:
					for (i = 0; i < numRecordChildren; i++) {
						//trace("record = " + recordRef.children[i].record + "  record.ruid=" + recordRef.children[i].record.ruid);
						addComboBoxEntry(recordRef.children[i].record, dataProvider);
					}
					//trace("COMBO_BOX DATAPROVIDER: " + dataProvider);
					break;
			}
			return dataProvider;
		}
		
		public function toString():String {
			var output:String = "Collection cuid='"+cuid+"':\n" + recordRef.toString();
			return output;
		}
	}
}