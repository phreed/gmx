package interfaces
{
	import records.Attributes;
	import records.Field;
	import records.RecordEvent;
	import records.Record;
	
	import flash.events.Event;
	
	public interface IField extends ISelfBuilding
	{
		function get field():Field;
		function set field(field:Field):void;
		function get fid():String;
		function set fid(val:String):void;
		function get componentValue():String; // returns the Component's value.. e.g. { return comboBox.selectedItem; }
		function set componentValue(val:String):void; // set's the Component's value... e.g. { comboBox.selectedItem = val; }
		
		function get record():Record;
		function set record(rec:Record):void;
		//function set fields(xml:XML):void; // implementation requires the component to map the field ID's ("fid") to the right "name"
		function get ruid():String;
		function set ruid(val:String):void;
		function dataEdit(event:RecordEvent):void;
		function set layout(val:String):void;
		//function set actionState(val:int):void;
		//function get enabled():Boolean;
		//function set enabled(val:Boolean):void;
		//override function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void;
		//override function dispatchEvent(event:Event):Boolean;
	}
}