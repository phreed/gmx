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
 *
 *
 */

// -*-as-*-
// CollectionVO.as: Auto generated 
// Source: "Y:\W Drive\SoldierAssessment_09\SBSA2_Model" :: /DataTypes/GMX/Data/Collection
// $Rev$: $Date$

package GMX.Data
{
    
	public class CollectionVO
	{
		//Imported VOs
		
		import GMX.Data.RuidVO;
		
		
	
		// Data Members
		
		private var _cuid:String;
		private var _ruidList:Array = [];
		
		
		// Set _cuid Function
		public function set cuid(data:String):void
		{
			
			_cuid = data;
		}
		// Get _cuid Functions
		public function get cuid():String
		{
			return _cuid;
		}
		
		// Set _ruidList Function
		public function set ruidList(data:Array):void
		{
			
			_ruidList = data;
		}
		// Get _ruidList Functions
		public function get ruidList():Array
		{
			return _ruidList;
		}
		
	
		public function fromXML(data:XML):void
		{
			
			
			_cuid = data.cuid;

			 
			
			var RuidList:XMLList = data.ruidList.Ruid;
			for each (var RuidNode:XML in RuidList)
			{
				//trace ("Ruid XML: " + RuidNode);				
				
				var a_Ruid:RuidVO = new RuidVO;
				a_Ruid.fromXML(RuidNode);
				_ruidList.push(a_Ruid);
				
			}
		}

		public function toXML(data:XML):void
		{
			
			
			if (_cuid != null) 
				data.cuid = _cuid;
			
			
			
			
			 
			
			data.appendChild(<ruidList/>);
			if( ruidList != null ){
			for (var i:int=0; i<_ruidList.length; i++)
			{
				
				var RuidXML:XML = <Ruid/>;
				_ruidList[i].toXML(RuidXML);
				data.ruidList.appendChild(RuidXML);
				
			}
			}
			
		}
	}
}