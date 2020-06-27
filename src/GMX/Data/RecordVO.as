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
// RecordVO.as: Auto generated 
// Source: "Y:\W Drive\SoldierAssessment_09\SBSA2_Model" :: /DataTypes/GMX/Data/Record
// $Rev$: $Date$

package GMX.Data
{
    
	public class RecordVO
	{
		//Imported VOs
		
		import GMX.Data.FieldVO;
		
		
	
		// Data Members
		
		private var _ruid:String;
		private var _fieldList:Array = [];
		private var _layout:String;
		
		
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
		
		// Set _fieldList Function
		public function set fieldList(data:Array):void
		{
			
			_fieldList = data;
		}
		// Get _fieldList Functions
		public function get fieldList():Array
		{
			return _fieldList;
		}
		
		// Set _layout Function
		public function set layout(data:String):void
		{
			
			_layout = data;
		}
		// Get _layout Functions
		public function get layout():String
		{
			return _layout;
		}
		
	
		public function fromXML(data:XML):void
		{
			
			
			_ruid = data.ruid;
			
			_layout = data.layout;

			 
			
			var FieldList:XMLList = data.fieldList.Field;
			for each (var FieldNode:XML in FieldList)
			{
				//trace ("Field XML: " + FieldNode);				
				
				var a_Field:FieldVO = new FieldVO;
				a_Field.fromXML(FieldNode);
				_fieldList.push(a_Field);
				
			}
		}

		public function toXML(data:XML):void
		{
			
			
			if (_ruid != null) 
				data.ruid = _ruid;
			
			
			
			if (_layout != null) 
				data.layout = _layout;
			
			
			
			
			 
			
			data.appendChild(<fieldList/>);
			if( fieldList != null ){
			for (var i:int=0; i<_fieldList.length; i++)
			{
				
				var FieldXML:XML = <Field/>;
				_fieldList[i].toXML(FieldXML);
				data.fieldList.appendChild(FieldXML);
				
			}
			}
			
		}
	}
}