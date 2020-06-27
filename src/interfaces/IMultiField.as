package interfaces
{
	import records.RecordEvent;
	import records.Record;
	
	public interface IMultiField extends ISelfBuilding
	{
		function get record():Record;
		function set record(rec:Record):void;
		function set fields(xml:XML):void; // implementation requires the component to map the field ID's ("fid") to the right "name"
		function get ruid():String;
		function set ruid(val:String):void;
		//function get enabled():Boolean;
		//function set enabled(val:Boolean):void;
		function dataEdit(event:RecordEvent):void;
	}
}