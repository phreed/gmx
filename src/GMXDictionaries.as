package
{
	import com.adobe.crypto.MD5;
	import flash.display.DisplayObjectContainer;
	import flash.net.FileReference;
	import interfaces.ISelfBuilding;
	import records.Collection;
	import records.Field;
	import records.Record;
	import records.Record;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.UIComponent;
	
	import flash.utils.Dictionary;
	
	public class GMXDictionaries
	{
		private static var _messages:Vector.<String> = new Vector.<String>();
		
		private static var _ruidDict:Dictionary = new Dictionary(true);
		private static var _luidDict:Dictionary = new Dictionary(true);
		//private static var _luidXMLDict:Dictionary = new Dictionary(true);
		private static var _cuidDict:Dictionary = new Dictionary(true);
		private static var _luidXMLHashValsDict:Dictionary = new Dictionary(true);
		private static var _luidXMLCurrentHashValsDict:Dictionary = new Dictionary(true);
		private static var _tempComponentToStateRetainerDict:Dictionary = new Dictionary(true);
		
		private static var _ruidDictDirty:Boolean = false;
		private static var _luidDictDirty:Boolean = false;
		//private static var _luidXMLDictDirty:Boolean = false;
		private static var _cuidDictDirty:Boolean = false;
		
		public static var _ruidList:ArrayCollection = new ArrayCollection();
		public static var _cuidList:ArrayCollection = new ArrayCollection();
		
		static public function init():void {
			_ruidDict = new Dictionary(true);
			_luidDict = new Dictionary(true);
			_cuidDict = new Dictionary(true);
			//_luidXMLDict = new Dictionary(true);
		}
		
		static public function get ruidDict():Dictionary { return _ruidDict; }
		
		static public function addRuid(key:String, object:Record):void {
			if (_ruidDict[key] == object) { return; }
			
			_ruidDictDirty = true;
			_ruidDict[key] = object;
		}
		static public function getRuid(key:String):Record {
			return _ruidDict[key] as Record;
		}
		static public function removeRuid(key:String):void {
			_ruidDict[key] = null;
			_ruidDictDirty = true;
		}
		static public function getRuidList():ArrayCollection {
			if (_ruidDictDirty) {
				var ruids:ArrayCollection = new ArrayCollection();
				ruids.addItem("");
				for each (var record:Record in _ruidDict) {
					ruids.addItem(record.ruid);
				}
				var sort:Sort = new Sort();
				sort.fields = [new SortField(null, true)];
				ruids.sort = sort;
				
				_ruidList = ruids;
				_ruidDictDirty = false;
				ruids.refresh();
			}
		
			return _ruidList;
		}
		static public function getFidList(ruid:String):ArrayCollection {
			var record:Record = _ruidDict[ruid];
			if (record == null) { return new ArrayCollection(); }
			
			var output:ArrayCollection = new ArrayCollection();
			
			for each (var field:Field in record.fields) {
				output.addItem(field.fid);
			}
			return output;
		}
		
		static public function get luidDict():Dictionary { return _luidDict; }
		
		static public function addLuid(luid:String, component:ISelfBuilding, xml:XML = null):void {
			_luidDict[luid] = component;
			// can't do any extra layout state retention without the hash of the xml string for comparison...
			if (xml == null) { return; } 
			
			// So... this is what happens here:
			//  - calculate the hash value for the xml string coming in.
			//  - check the _luidXMLHashValsDict[luid]: stored at that luid will an Object "hashCodesForThatLuid" (which is another HashMap)
			//  - if it does not contain an Object, a new Object is created
			//  - the hash value calculated above is used to get a ExtraLayoutStateRetainer through "hashCodesForThatLuid[xmlHashCode]"
			//      - if nothing is there, it means that this particular XML has not been used to build the component with the luid.
			//          in this case, a new ExtraLayoutStateRetainer object is put there
			//  - the ExtraLayoutStateRetainer object is placed in the "_tempComponentToStateRetainerDict" dictionary, using the ISelfBuilding component itself
			//    as the lookup key.  The reason?  This "addLuid" function is called while a component is being built and b4 its children are built, and it is only after it and 
			//    all its child components are processed that we can run the "applyExistingExtraLayoutStateToComponent" function on it, and so we
			//    want a lookup that takes the component itself as the key and gives the ExtraLayoutStateRetainer that contains the information
			//    necessary to update that component such that in GMXComponentBuilder, we can easily call "applyExistingExtraLayoutStateToComponent" after
			//    building the component.  See the how the "applyExistingExtraLayoutStateToComponent" function uses "_tempComponentToStateRetainerDict".
			//  - Note that the state of the layout component is saved into the ExtraLayoutStateRetainer right before a layout message replaces that component 
			//    (see GMXMain.ISISLayout function where it calls the ExtraLayoutStateRetainer.savePreviousState function).
			//  - This addLuid function only creates ExtraLayoutStateRetainer containers when they don't exist...  It does not save any
			//    state (obviously, since no state--e.g. scroll bar position--has been set by the user since the layout message was just received)
			
			var pattern:RegExp = / +xmlns:.+=".+"/;
			// remove the namespace b/c sometimes it reaches GMX and sometimes it doesn't
			var xmlString:String = xml.toString().replace(pattern, "");
			pattern = / +>/; //get rid of spaces before the closing bracket
			xmlString = xmlString.replace(pattern, ">");
			
			var xmlHashCode:String = com.adobe.crypto.MD5.hash(xmlString);
			var layoutStateRetainer:ExtraLayoutStateRetainer;
			
			var hashCodesForThatLuid:Object = _luidXMLHashValsDict[luid];
			if (hashCodesForThatLuid == null) { 
				// In this case, that luid has never been encountered before, so a HashMap is added in the _luidXMLCurrentHashValsDict HashMap
				_luidXMLCurrentHashValsDict[luid] = xmlHashCode;
				hashCodesForThatLuid = new Object();
				layoutStateRetainer = new ExtraLayoutStateRetainer();
				hashCodesForThatLuid[xmlHashCode] = layoutStateRetainer;
				_luidXMLHashValsDict[luid] = hashCodesForThatLuid;
			} else if ((layoutStateRetainer = hashCodesForThatLuid[xmlHashCode]) == null) {
				// that luid has been encountered, but this hashcode (from the xml string) has not been encountered before
				layoutStateRetainer = new ExtraLayoutStateRetainer();
				hashCodesForThatLuid[xmlHashCode] = layoutStateRetainer;
			} else {
				// that luid has been encountered and there is already an ExtraLayoutStateRetainer at its hash code location.
			}
			_tempComponentToStateRetainerDict[component] = layoutStateRetainer;
		}
		static public function getLuid(key:String):ISelfBuilding {
			return _luidDict[key];
		}
		static public function removeLuid(key:String):void {
			_luidDict[key] = null;
		}
		static public function removeTempComponentToStateRetainerEntry(component:DisplayObjectContainer):void {
			if (_tempComponentToStateRetainerDict[component] != null) { _tempComponentToStateRetainerDict[component] = null; }
		}
		static public function applyExistingExtraLayoutStateToComponent(component:ISelfBuilding):void {
			var layoutStateRetainer:ExtraLayoutStateRetainer = _tempComponentToStateRetainerDict[component] as ExtraLayoutStateRetainer;
			if (layoutStateRetainer == null) { return; }
			layoutStateRetainer.revertComponentToPreviousState(component as UIComponent);
		}
		static public function getCurrentLayoutStateForComponent(component:ISelfBuilding):ExtraLayoutStateRetainer {
			
			return _tempComponentToStateRetainerDict[component] as ExtraLayoutStateRetainer;
		}

		
		
		/*
		static public function get luidXMLDict():Dictionary { return _luidXMLDict; }
		
		static public function addLuidXML(key:String, object:XML):void {
			_luidXMLDict[key] = object;
		}
		static public function getLuidXML(key:String):XML {
			return _luidXMLDict[key];
		}
		static public function removeLuidXML(key:String):void {
			_luidXMLDict[key] = null;
		}
		*/
		
		static public function get cuidDict():Dictionary { return _cuidDict; }
		
		static public function addCuid(key:String, object:Collection):void {
			if (_cuidDict[key] == object) { return; }
			
			_cuidDict[key] = object;
			_cuidDictDirty = true;
		}
		static public function getCuid(key:String):Collection {
			return _cuidDict[key] as Collection;
		}
		static public function removeCuid(key:String):void {
			_cuidDict[key] = null;
			_cuidDictDirty = true;
		}
		
		static public function getCuidList():ArrayCollection {
			if (_cuidDictDirty) {
				var cuids:ArrayCollection = new ArrayCollection;
				cuids.addItem("");
				for each (var collection:Collection in _cuidDict) {
					cuids.addItem(collection.cuid);
				}
				_cuidList = cuids;
				_cuidDictDirty = false;
			}
		
			return _cuidList;
		}
		
		static private var _recordStack:Vector.<Record> = new Vector.<Record>();
		static public function get recordStack():Vector.<Record> { return _recordStack; }
		
		static public function pushCurrentRecord(rec:Record):void {
			_recordStack.push(rec);
		}
		static public function popCurrentRecord():void {
			_recordStack.pop();
		}
		static public function getCurrentRecord():Record {
			if (_recordStack.length == 0) return null;
			
			return _recordStack[_recordStack.length - 1];
		}
		
		
		static public function addMessage(msg:String):void {
			_messages.push(msg);
		}
		static public function saveMessagesToFile():void {
			var output:String = "";
			for (var i:int = 0; i < _messages.length; i++) {
				if (i > 0) {
					output += "\n";
					output += "%%\n";
					output += "\n";
					output += "\n";
				}
				output += _messages[i] + "\n";
			}
			var file:FileReference = new FileReference();
			file.save(output, "GMFMessageLog.txt");
		}
	}
}