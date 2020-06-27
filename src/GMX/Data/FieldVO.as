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
// FieldVO.as: Auto generated 
// Source: "Y:\W Drive\SoldierAssessment_09\SBSA2_Model" :: /DataTypes/GMX/Data/Field
// $Rev$: $Date$

package GMX.Data
{
    
	public class FieldVO
	{
		//Imported VOs
		
		
	
		// Data Members
		
		private var _fid:String;
		private var _value:String;
		
		
		// Set _fid Function
		public function set fid(data:String):void
		{
			
			_fid = data;
		}
		// Get _fid Functions
		public function get fid():String
		{
			return _fid;
		}
		
		// Set _value Function
		public function set value(data:String):void
		{
			
			_value = data;
		}
		// Get _value Functions
		public function get value():String
		{
			return _value;
		}
		
	
		public function fromXML(data:XML):void
		{
			
			
			_fid = data.fid;
			
			_value = data.value;

			
		}

		public function toXML(data:XML):void
		{
			
			
			if (_fid != null) 
				data.fid = _fid;
			
			
			
			if (_value != null) 
				data.value = _value;
			
			
			
			
			
		}
	}
}