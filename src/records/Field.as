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
package records
{
	import interfaces.IField;
	import interfaces.ISelfBuilding;
	
	import mx.controls.Alert;

	public class Field
	{		
		protected var _value:String = null;
		public function get value():String { 
			return _value;
		}
		public function set value(val:String):void {
			if (_value == val && _attributes.updateComponentsCondition == Attributes.UPDATE_COMPONENTS_ON_CHANGE) { return; }
			_value = val;
			for (var i:int = 0; i < _componentsRequiringUpdate.length; i++) {
				_componentsRequiringUpdate[i].invalidateProperties();
			}	
		}
		protected var _fid:String;
		public function get fid():String { return _fid; }
		public function set fid(val:String):void { _fid = val; }
		
		protected var _componentsRequiringUpdate:Vector.<ISelfBuilding> = new Vector.<ISelfBuilding>;
		public function get componentsRequiringUpdate():Vector.<ISelfBuilding> { return _componentsRequiringUpdate; }
		public function set componentsRequiringUpdate(val:Vector.<ISelfBuilding>):void { _componentsRequiringUpdate = val; }
		public function addComponentRequiringUpdate(comp:ISelfBuilding):void {
			_componentsRequiringUpdate.push(comp);
		}
		public function removeComponentRequiringUpdate(comp:ISelfBuilding):Boolean {
			for (var i:int = 0; i < _componentsRequiringUpdate.length; i++) {
				if (_componentsRequiringUpdate[i] == comp) {
					_componentsRequiringUpdate.splice(i, 1);
					return true;
				}
			}
			return false;
		}
		
		protected var _attributes:Attributes;
		public function get attributes():Attributes { return _attributes; }
		
		public function Field(fid:String = null)
		{
			_attributes = new Attributes(this);
			_fid = fid;
			// add the field to the currentRecord on the stack if it is a hashrecord
			var record:Record = GMXDictionaries.getCurrentRecord();
			if (record != null) {
				record.addField(this);
			} else Alert.show("WARNING: attempted to add Field fid='"+ fid +"' to current record: " + GMXDictionaries.getCurrentRecord() + ", but this is not a Record!");
		}
	}
}