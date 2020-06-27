package gmx_builder
{
	import interfaces.ISelfBuilding;
	
	/**
	 * ...
	 * @author 
	 */
	public class ComponentTreeIndexPair 
	{
		public var selfBuilding:ISelfBuilding;
		public var indexInXMLTree:String;
		
		public function ComponentTreeIndexPair(selfBuilding:ISelfBuilding = null, indexInXMLTree:String = null) {
			this.selfBuilding = selfBuilding;
			this.indexInXMLTree = indexInXMLTree;
		}
		
		public function disintegrate():void {
			selfBuilding = null;
		}
	}
}