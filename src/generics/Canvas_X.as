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
package generics
{
	import interfaces.IFieldStandardImpl;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Field;
	import records.Record;
	import records.RecordEvent;
	import records.Record;
	import constants.Size;
	import mx.controls.Image;
	
	import mx.containers.Canvas;
	import mx.controls.Alert;
	
	public class Canvas_X extends Canvas implements IMultiField
	{				
		public function Canvas_X()
		{
			super();
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";
			this.clipContent = true;
		}
		
		public function build(xml:XML):void {
			if (xml == null) { return; }
			var recordAdded:Boolean = false; 
			if (xml.@ruid != undefined) {
				this.ruid = xml.@ruid.toString();
				GMXDictionaries.recordStack.push(this.record);
				recordAdded = true;
			}
			GMXComponentBuilder.setPropertiesFromXML(this, xml);
			GMXComponentBuilder.processXML(this, xml);
			if (recordAdded) {
				GMXDictionaries.recordStack.pop();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
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
		public function set fields(xml:XML):void {
			IFieldStandardImpl.setFields(this, xml, [], []);
		}	
//========= BEGIN ISelfBuilding Implementation ============================================
		private var _flexible:Boolean = false;
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
			return;
		}
//========= END ISelfBuilding Implementation ==============================================
	}
}