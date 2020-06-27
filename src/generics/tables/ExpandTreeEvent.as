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
package generics.tables
{
	import flash.events.Event;

	public class ExpandTreeEvent extends Event
	{
		private var _showChildren:Boolean;
		public function get showChildren():Boolean { return _showChildren; }
		public function set showChildren(val:Boolean):void {
			_showChildren = val;
		}
		private var _ruid:String;
		public function get ruid():String { return _ruid; }
		public function set ruid(val:String):void {
			_ruid = val;
		}	
		//public static const EXPAND:String = "expand";
		public static const RESIZE:String = "expandOrCollapseTreeItem";
		
		public function ExpandTreeEvent(ruid:String, showChildren:Boolean, type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this._showChildren = showChildren;
			this._ruid = ruid;
		}
	}
}