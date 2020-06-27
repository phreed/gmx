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
// RuidVO.as: Auto generated 
// Source: "Y:\W Drive\SoldierAssessment_09\SBSA2_Model" :: /DataTypes/GMX/Data/Ruid
// $Rev$: $Date$

package GMX.Data
{
    
	public class RuidVO
	{
		//Imported VOs
		
		
	
		// Data Members
		
		private var _ruid:String;
		private var _ref:String;
		private var _select:String;
		
		
		// Set _ruid Function
		public function set ruid(data:String):void
		{
			
			_ruid = data;
		}
		// Get _ruid Functions
		public function get ruid():String
		{
			return _ruid;
		}
		
		// Set _ref Function
		public function set ref(data:String):void
		{
			
			_ref = data;
		}
		// Get _ref Functions
		public function get ref():String
		{
			return _ref;
		}
		
		// Set _select Function
		public function set select(data:String):void
		{
			
			_select = data;
		}
		// Get _select Functions
		public function get select():String
		{
			return _select;
		}
		
	
		public function fromXML(data:XML):void
		{
			
			
			_ruid = data.ruid;
			
			_ref = data.ref;
			
			_select = data.select;

			
		}

		public function toXML(data:XML):void
		{
			
			
			if (_ruid != null) 
				data.ruid = _ruid;
			
			
			
			if (_ref != null) 
				data.ref = _ref;
			
			
			
			if (_select != null) 
				data.select = _select;
			
			
			
			
			
		}
	}
}