﻿/*     Copyright (c) 2005-2009 SA Technologies, Inc. All rights reserved.
 *     ****
 *     Export Controlled:  Not Releasable to a Foreign Person or
 *     Representative of a Foreign Interest
 *     ****
 *     Developed under contract for Future Combat Systems (FCS).
 *     FCS Competition Sensitive. Not to be disclosed to unauthorized persons
 *     ****
 *     DISTRIBUTION STATEMENT D: Distribution authorized to the Department of
 *     Defense and U.S. DOD contractors only for Administrative or 
 *     Operational use (29 October 2003). Other requests for this software 
 *     shall be referred to Program Manager Future Combat Systems (Brigade 
 *     Combat Team), ATTN: PM FCS (BCT) Security Office, ATTN: SFAE-FCS-I / 
 *     MS 515, 6501 East 11 Mile Road, Warren, MI 48397-5000
 *     ****
 *     WARNING - This software contains technical data whose export may be 
 *     restricted by the Arms Export Control Act (Title 22, U.S.C., Sec 2751, 
 *     et seq.) or the Export Administration Act of 1979, as amended
 *     (Title 50, U.S.C., App. 2401 et seq.). Violations of these export laws 
 *     are subject to severe criminal penalties. Disseminate in accordance 
 *     with provisions of DoD Directive 5230.25.
 ********************************************************************

 */

package  services{
	
	/** 
	 * All EventMaps will implement this interface.
	 * **/
	public interface IEventMap {
		function init():void;
		function getStronglyTypedArgs(fnName:String, args:Array):Array;
		function getXMLArgs(fnName:String, args:Array):XML;
		
	}
}