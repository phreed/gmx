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
// AttributeVO.as: Auto generated 
// Source: "Y:\W Drive\SoldierAssessment_09\SBSA2_Model" :: /DataTypes/GMX/Data/Attribute
// $Rev$: $Date$

package GMX.Data
{
    
	public class AttributeVO
	{
		//Imported VOs
		
		
	
		// Data Members
		
		private var _ruid:String;
		private var _fid:String;
		private var _send:String;
		private var _actionState:String;
		private var _permissions:String;
		
		
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
		
		// Set _send Function
		public function set send(data:String):void
		{
			
			_send = data;
		}
		// Get _send Functions
		public function get send():String
		{
			return _send;
		}
		
		// Set _actionState Function
		public function set actionState(data:String):void
		{
			
			_actionState = data;
		}
		// Get _actionState Functions
		public function get actionState():String
		{
			return _actionState;
		}
		
		// Set _permissions Function
		public function set permissions(data:String):void
		{
			
			_permissions = data;
		}
		// Get _permissions Functions
		public function get permissions():String
		{
			return _permissions;
		}
		
	
		public function fromXML(data:XML):void
		{
			
			
			_ruid = data.ruid;
			
			_fid = data.fid;
			
			_send = data.send;
			
			_actionState = data.actionState;
			
			_permissions = data.permissions;

			
		}

		public function toXML(data:XML):void
		{
			
			
			if (_ruid != null) 
				data.ruid = _ruid;
			
			
			
			if (_fid != null) 
				data.fid = _fid;
			
			
			
			if (_send != null) 
				data.send = _send;
			
			
			
			if (_actionState != null) 
				data.actionState = _actionState;
			
			
			
			if (_permissions != null) 
				data.permissions = _permissions;
			
			
			
			
			
		}
	}
}