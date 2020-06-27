package interfaces 
{
	import records.Collection;
	/**
	 * ...
	 * @author 
	 */
	public interface ICollection extends ISelfBuilding
	{
		function get dirty():Boolean;
		function set dirty(val:Boolean):void;
		
		function get recordCollection():Collection;
		function set recordCollection(col:Collection):void;
		function get cuid():String;
		function set cuid(val:String):void;
	}
}