package interfaces 
{
	import records.Attributes;
	import records.Field;
	import records.Record;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	/**
	 * ...
	 * @author 
	 */
	public class IFieldStandardImpl
	{
		public static function setAttributes(component:ISelfBuilding, attributes:Attributes):void {
			switch(attributes.permissions) {
				case Attributes.PERMISSIONS_DISABLED:
					component.enabled = false;
					break;
				case Attributes.PERMISSIONS_RO:
				case Attributes.PERMISSIONS_RW:
					component.enabled = true;
					break;
			}
			/* NOT IMPLEMENTED YET
			switch(attributes.send) {
				case Attributes.SEND_CHANGE: break;
				case Attributes.SEND_ALWAYS: break;
				case Attributes.SEND_NEVER: break;
			}
			switch(attributes.actionState) {
				case Attributes.ACTION_STATE_WAITING: break;
				case Attributes.ACTION_STATE_FAILED: break;
				case Attributes.ACTION_STATE_OK: break;
				case Attributes.ACTION_STATE_ACTIVE: break;
			}
			*/
		}
		//====== BEGIN IField implementation ========================================================
		public static function setFid(component:IField, newFid:String):void {
			var rec:Record = GMXDictionaries.getCurrentRecord();
			if (rec == null) { // record does not yet exist... can't add
				Alert.show("WARNING: Incoming layout message contains " + component + " (with a field) but no Record on which to attach it.");
			} else {
				var newField:Field = rec.getField(newFid);
				if (newField != null) { // the record already has the field
					// record already contains the field & data
					component.componentValue = newField.value;
				} else {
					// create a new field associated with the record
					newField = new Field(newFid);
					newField.value = "";
				}
				component.field = newField;
				component.setAttributes(newField.attributes);
				newField.addComponentRequiringUpdate(component);
			}
		}
		//====== END IField implementation ========================================================
		//====== BEGIN IField optional Record implementation ======================================
		public static function setRuid(component:IField, val:String):void {
			var rec:Record = GMXDictionaries.getRuid(val);
			if (rec == null) {
				component.record = new Record(val);
			} else { 
				component.record = rec;
			}
		}
		public static function setFields(component:ISelfBuilding, xml:XML, fieldNames:Array = null, defaultValues:Array = null):void //:Object
		{
			var lengthsMatch:Boolean = false;
			var namedFields:Object = new Object();
			if (fieldNames != null && defaultValues != null) { 
				if (defaultValues.length == fieldNames.length) lengthsMatch = true;
				else trace("WARNING: IFieldStandardImpl fieldNames and defaultValues lengths DO NOT match!  Component: " + component);
			}
			
			for each (var fieldXML:XML in xml.field) {
				var rec:Record = GMXDictionaries.getCurrentRecord() as Record;
				if (rec == null) { // record does not yet exist... can't add
					Alert.show("WARNING: Not a Record on the RecordStack!!!  Type found: " + GMXDictionaries.getCurrentRecord());
					return;
				}
				var fieldName:String = fieldXML.@name.toString().toLowerCase();
				if (fieldXML.@fid == undefined) {
					Alert.show("WARNING: field with name=" + fieldName + " doesn't have a fid. It won't be processed.");
					continue;
				}
				// check if theres a specific ruid that the field should be assigned to.
				// if there it doesn't exist yet, make a new one (in Record's set ruid 
				// function called from its constructor).
				if (fieldXML.@ruid != undefined) {
					var newRuid:String = fieldXML.@ruid.toString();
					rec = GMXDictionaries.getRuid(newRuid);
					if (rec == null) { rec = new Record(newRuid); }
				}
				
				var fieldId:String = fieldXML.@fid.toString();
				
				var newField:Field = rec.getField(fieldId) as Field;
				if (newField == null) { 
					newField = new Field(fieldId);
				}
				if (fieldXML.@value != undefined) {
					newField.value = fieldXML.@value.toString();
				}				
				if (fieldNames == null) {
					// there are no named fields so each attached field has no special meaning
					// to the component.  Add the field and move on to the next one.
					newField.addComponentRequiringUpdate(component);
					continue;
				}
				
				
				var matchFound:Boolean = false;
				for (var i:int = 0; i < fieldNames.length; i++) {
					if (fieldNames[i] == fieldName) {
						if (newField.value == null) { newField.value = defaultValues[i]; }
						if (fieldName in component) {
							component[fieldName] = newField;
							matchFound = true;
						} else {
							Alert.show("ERROR: in the fieldNames array of the " + component.className + " class, the name \"" + fieldName +
								"\" exists, but there is no declared field variable at that name! (i.e. in that class, there should " +
								"be the declaration \"public var " + fieldName +":Field;\" in there somewhere in that class).  Named fields " +
								"should generally affect a component's operation (e.g. an Attitude Indicator has a \"pitch\" field that affects " +
								"how it is drawn.  See GMX Developer Guide for more info.");
						}
						break;
					}
				}
				if (!matchFound || !lengthsMatch) {
					if (newField.value == null) { newField.value = ""; }
				}
				newField.addComponentRequiringUpdate(component);
			}
			//return namedFields;
		}
		
		public static function setLayout(val:String):void {
			var rec:Record = GMXDictionaries.getCurrentRecord();
			if (rec == null) { 
				Alert.show("WARNING: Attempted to add layout to a record, but there is no record on the RecordStack!  Incoming layout: " + val)
			} else {
				rec.layout = val;
			}
		}
//========= END IField Implementation =====================================================
	}
}