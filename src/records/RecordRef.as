package records
{
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	/**
	 * ...
	 * @author 
	 */
	public class RecordRef 
	{
		protected var _parentCollection:Collection;
		public function get parentCollection():Collection { return _parentCollection; }
		public function set parentCollection(collection:Collection):void { _parentCollection = collection; }
				
		protected var _record:Record;
		public function get record():Record { return _record; }
		public function set record(newRecRef:Record):void { _record = newRecRef; }
		public function RecordRef(newRecRef:Record = null) {
			_record = newRecRef;
		}
		protected var _showChildren:Boolean = true; // only for tree-grids
		public function get showChildren():Boolean { return _showChildren; }
		public function set showChildren(val:Boolean):void {
			_showChildren = val;
			// NEED TO UPDATE PARENT DATA PROVIDER??
		}
		
		public function get ruid():String { if (_record == null) { return null; }  return _record.ruid; }
		
		protected var _parent:RecordRef;
		public function get parent():RecordRef { return _parent; }
		public function set parent(val:RecordRef):void { 
			//if (val == null) { Alert.show("Record ruid='" + (_record == null ? "null" : _record.ruid) + "' tried to add a null parent Record!"); return; }
			_parent = val;
		}
		public function refactorParent(newParent:RecordRef):void {
			if (newParent == null) { Alert.show("WARNING: attempted  'refactorParent' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			deparent();
			this._parent = newParent;
		}
		public function deparent():void {
			if (_parent == null) { return; }
			
			_parent.removeChildRecord(this);
			this._parent = null;
		}
		
		
		public function get siblings():Vector.<RecordRef> { 
			if (_parent == null) { Alert.show("WARNING: attempted 'get siblings' function on record w/o a parent!"); return null; }
			return _parent.children;
		}
		public function set siblings(val:Vector.<RecordRef>):void { 
			if (_parent == null) { Alert.show("WARNING: attempted 'set siblings' function on record w/o a parent!"); return; } 
			_parent.children = val;
		}
		public function addSiblingLastRecord(newRecRef:RecordRef):void {
			if (_parent == null) { Alert.show("WARNING: attempted 'addSiblingLastRecord' function on record w/o a parent!"); return; }
			if (newRecRef == null) { Alert.show("WARNING: attempted  'addSiblingLastRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			newRecRef.deparent();
			_parent.addChildRecord(newRecRef);
			newRecRef.parent = _parent;
		}
		public function addSiblingBeforeRecord(newRecRef:RecordRef):void {
			//trace("ATTEMPTING ADDSIBLINGBEFORE SIBLING ruid='"+ (newRecRef.record == null ? "null" : newRecRef.record.ruid) +"' to SIBLING ruid='" + (_record == null ? "null" : _record.ruid) + "' with PARENT ruid=" + (_parent == null ? "nullparent" : _parent.record == null ? "nullRuid" : _parent.record.ruid )  );
			if (_parent == null) { Alert.show("WARNING: attempted 'addSiblingBeforeRecord' function on record w/o a parent!"); return; } 
			if (newRecRef == null) { Alert.show("WARNING: attempted  'addSiblingBeforeRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			var numChildren:int = _parent.children.length;
			var newRecRefIsAnEarlierSibling:Boolean = false;
			for (var i:int = 0; i < numChildren; i++) {
				if (_parent.children[i] == newRecRef) { 
					newRecRefIsAnEarlierSibling = true;
					continue;
				}
				if (_parent.children[i] == this) {
					if (newRecRefIsAnEarlierSibling) { i--; }
					newRecRef.deparent();
					_parent.children.splice(i, 0, newRecRef);
					newRecRef.parent = _parent;
					return;
				}
			}
			Alert.show("WARNING: attempted 'addSiblingBeforeRecord' adding record ruid='" + newRecRef.record.ruid	+"' before record ruid='" + _record.ruid +"' but the ref ruid does not exist among the children!");
		}
		public function addSiblingAfterRecord(newRecRef:RecordRef):void {
			if (_parent == null) { Alert.show("WARNING: attempted 'addSiblingAfterRecord' function on record w/o a parent!"); return; }
			if (newRecRef == null) { Alert.show("WARNING: attempted  'addSiblingAfterRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			var numChildren:int = _parent.children.length;
			var newRecRefIsAnEarlierSibling:Boolean = false;
			for (var i:int = 0; i < numChildren; i++) {
				if (_parent.children[i] == newRecRef) {
					if (_parent.children[i] == newRecRef) { 
						newRecRefIsAnEarlierSibling = true;
						continue;
					}
				}
				if (_parent.children[i] == this) {
					if (newRecRefIsAnEarlierSibling) { i --; }
					newRecRef.deparent();
					_parent.children.splice(i + 1, 0, newRecRef);
					newRecRef.parent = _parent;
					return;
				}
			}
			Alert.show("WARNING: attempted 'addSiblingAfterRecord' adding record ruid='" + newRecRef.record.ruid	+"' before record ruid='" + _record.ruid +"' but the ref ruid does not exist among the children!");
		}
		public function addSiblingFirstRecord(newRecRef:RecordRef):void {
			if (_parent == null) { Alert.show("WARNING: attempted 'addSiblingFirstRecord' function on record w/o a parent!"); return; } 
			if (newRecRef == null) { Alert.show("WARNING: attempted  'addSiblingFirstRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			newRecRef.deparent();
			_parent.addChildRecord(newRecRef, 0);
			newRecRef.parent = _parent;
		}
		public function getSiblingRecordAt(index:int):RecordRef {
			if (_parent == null) { Alert.show("WARNING: attempted 'getSiblingRecordAt' function on record w/o a parent!"); return null; }
			return _parent.getSiblingRecordAt(index);
		}
		
		protected var _children:Vector.<RecordRef> = new Vector.<RecordRef>();
		public function get children():Vector.<RecordRef> { return _children; }
		public function set children(val:Vector.<RecordRef>):void { _children = val; }
		public function get numChildren():int { return _children.length; }
		public function addChildRecord(newRecRef:RecordRef, index:int = -1):void {
			if (newRecRef == null) { Alert.show("WARNING: attempted  'addChildRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return; }
			newRecRef.deparent();
			if (index == -1 || index == children.length) {
				_children.push(newRecRef);
			} else {
				_children.splice(index, 0, newRecRef);
			}
			newRecRef.parent = this;
			//trace("ADDED CHILD ruid='"+ (newRecRef.record == null ? "null" : newRecRef.record.ruid) +"' to PARENT ruid='" + (_record == null ? "null" : _record.ruid) );
		}
		public function removeChildRecord(newRecRef:RecordRef):Boolean {
			if (newRecRef == null) { Alert.show("WARNING: attempted  'removeChildRecord' function with a null 'newRecRef' argument!  Operation aborted!"); return false; }
			//try { trace("ATTEMPTING :  RECORD "+ newRecRef.record.ruid +" splicing from RECORD " + _record.ruid); } catch(e:Error) { trace("RECORD "+ newRecRef.record.ruid +" HAS BEEN Spliced from null"); }
			var len:int = _children.length;
			for (var i:int = 0; i < len; i++) {
				if (_children[i] == newRecRef) {
					_children.splice(i, 1);
					newRecRef.parent = null;
					//try { trace("RECORD "+ newRecRef.record.ruid +" HAS BEEN Spliced from RECORD " + _record.ruid); } catch(e:Error) { trace("RECORD "+ newRecRef.record.ruid +" HAS BEEN Spliced from null"); }
					return true;
				}
			}
			return false;
		}
		public function getChildRecordAt(index:int):RecordRef {
			return _children[index];
		}
		public function getChildIndex(childRecRef:RecordRef):int {
			for (var i:int = 0; i < _children.length; i++) {
				if (_children[i] == childRecRef) { return i; }
			}
			return -1;
		}
		
		public function disconnect():void {
			for (var i:int = 0; i < _children.length; i++) {
				_children[i].disconnect();
			}
			deparent();
			this.parentCollection = null;
			if (this.record != null) {
				this.record.removeRecordRef(this);
			}
		}
		
		public function splice():void {
			if (_parent == null) { 
				Alert.show("WARNING: Attempted to splice a Record with a null parent.  This may be due to the fact that the Collection's RecordRef's record is null.");
				return;
			}
			var replacementIndex:int = _parent.getChildIndex(this) + 1;
			while (_children.length != 0) {
				_parent.addChildRecord(_children[0], replacementIndex);
				replacementIndex++;
				//removeChildRecord(_children[i]);   addChildRecord already calls "deparent()" so we don't need to do it directly
			}
			deparent();
		}
		
		public function containsChild(newRecRef:RecordRef):Boolean {
			if (newRecRef == null) { Alert.show("WARNING: attempted  'containsChild' function with a null 'newRecRef' argument!  Operation aborted!"); return false; }
			for (var i:int = 0; i < _children.length; i++) {
				if (_children[i] == newRecRef) {
					return true;
				}
			}
			return false;
		}
		
		public function containsChildRuid(ruid:String):Boolean {
			for (var i:int = 0; i < _children.length; i++) {
				if (_children[i] != null && _children[i].ruid == ruid) {
					return true;
				}
			}
			return false;
		}
		
		public function toString(level:int = 0):String {
			var output:String = "";
			if (_record == null) {
				output += "RecordRef: null record"
			} else { output += "RecordRef: ruid='" + _record.ruid + "'" }
			var tabs:String = "";
			var i:int;
			for (i = 0; i < level; i++) {
				tabs += "\t"
			}
			for (i = 0; i < children.length; i++) {
				output += "\n\t" + children[i].toString(level + 1);
			}
			return output;
		}
	}
}