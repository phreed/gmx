/*     Copyright (c) 2005-2009 SA Technologies, Inc. All rights reserved.
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
 
package services
{
import __AS3__.vec.Vector;

import records.Record;

import flash.display.Stage;
import flash.events.*;
import flash.utils.*;

import mx.controls.Alert;
import mx.core.Application;

import services.xml.*;
//import Main;
//import mx.core.Application;

[Event(name="data", type="flash.events.DataEvent.DATA")]

public class ServiceInterfaceImpl extends EventDispatcher
{
	private var eventMap:IEventMap;
	
	//Dummy variables so that each PDD's EventMap get loaded:
	include "ServiceInterfaceImpl_DummyVars.as";
	//END dummy vars
	
	private static var _instance:ServiceInterfaceImpl;

	private static var interfaceMap:Object = new Object(); //hashmap of our callback functions 
	
	private static var _hostName:String;
	private static var _port:uint;
	private static var socket:SocketController;
	private static var mainStage:Stage;
	
	private static const DEFAULT_PORT:uint = 12146;
	private static const DEFAULT_HOST:String = "localhost";
	
	public function ServiceInterfaceImpl( enforcer:SingletonEnforcer ){
		//socket = new SocketController();
		SocketController.init();
		SocketController.dispatcher.addEventListener( DataEvent.DATA, socketDataHandler);
	}//constructor
	
	
	public static function getInstance(passedStage:Stage):ServiceInterfaceImpl{
		mainStage = passedStage;
		if(_instance == null){
			_instance = new ServiceInterfaceImpl( new SingletonEnforcer() );
		}
		return _instance;
	}//getInstance()


	private function socketDataHandler(event:DataEvent):void{
		try {
			var xml:XML = new XML( event.data ); //data will always be XML
			if (GMXMain.testing) GMXDictionaries.addMessage( xml.toXMLString() );
		} catch (e:Error) {
			if (GMXMain.testing) GMXDictionaries.addMessage( event.data );
			Alert.show("WARNING: Incoming XML message was not processed correctly: " + e.message);
			return;
		}
		if (ControlChannel.echoDownload) {
			ControlChannel.sendEcho(xml, false);
		}
		if (event.data == "|S|C|") { return; }
		if (xml.name() == null) { 
			trace("WARNING: xml.name() is null for this message: " + xml);
			return;
		} 
		switch( xml.name().localName ){  //look at the root node element name
			case "invoke":
				/* XML will be of the form
				*  <invoke fn="functionName">
				*      <args>
				*         <arg>...</arg>
				*      </args>
				*  </invoke>
				*/
			
				if (ControlChannel.polling && !ControlChannel.block) {
					ControlChannel.startTime = getTimer();
					//trace("Start time: " + ControlChannel.startTime);
					ControlChannel.block = true;
				}
				var argList:XMLList = xml.args.arg;
				
				// convert the XMLList to an Array
				
				// BEGIN: FANCY EXPLANATION
				// the following snippet is a little weird because of the way XML is handled
				// XML is a primitive type in AS3, so using e4x above to get argList returns
				// an XMLList of <arg>value</arg> XML primitives
				// when looping through the list and assigning XMLList[i] to Array[i]
				// the array will get the XML primitive instead of just "value"
				// AS3 is smart enough to take the XML primitive and convert it to other types
				// when applying the arguments to a function, so var xml:XML = <arg>94</arg>;
				// can be applied as an argument to a function that expects an int and the function
				// will be passed the int 94
				// for an arg that actually has XML payload, the value when applied as XML is still the
				// whole XML primitive including the <arg></arg> tags
				//
				// below we use a regular expression /<arg>/ to look over the string representation of
				// the XML primitive to determine if it is infact XML
				// if it is, we extract just the first child which is the XML payload we expect
				// END: FANCY EXPLANATION
				
				var argArray:Array = new Array( argList.length() );
				for( var i:int=0; i < argList.length(); i++ ){
					if( /<arg>/.test( argList[i].toString() ) ){
						argArray[i] = argList[i].children()[0];
					}else{
						argArray[i] = argList[i];
					}
				}
										
				handleLocalCall( xml.@fn, argArray );  
				break;
			default:
				Alert.show("WARNING: Incoming XML message was not properly wrapped in invoke element");
		}		
	}//socketDataHandler()
	
	
	public function addCallback( fnName:String, fn:Function ):void{
		interfaceMap[fnName] = fn;		
		
	}//addCallback
	
	public function call( fnName:String, args:Array ):void{
		if (fnName == "bp_setPrimitiveSize"){
			//mx.core.Application.application.height = args[0];
			//mx.core.Application.application.width = args[1];
		}
	
		var invokeMsg:XML = <invoke fn={fnName}></invoke>;
		var argsList:XML = eventMap.getXMLArgs(fnName, args);	//serialize to XML

		invokeMsg.appendChild( argsList );
		/*try {
			// for subscription purposes
			var ruid:String = argsList.children().children()[0].ruid;
			var record:Record = GMXDictionaries.getRuid(ruid) as Record;
			var subscribedList:Vector.<String> = record.subscribedList;
		} catch(e:Error) {
			//trace("WARNING: could not find the ruid from the 3rd level of the following XML: '" + argsList + "'");
		}*/
							
		//SocketController.send( invokeMsg, subscribedList );
		//trace(invokeMsg);
		SocketController.send( invokeMsg, null );
				
		if (GMXMain.testing) { // control port assumed to handle Layout, Update, and Select (from UI) messages to and from service
			ControlChannel.send( invokeMsg );
		}
		if (ControlChannel.echoUpload) {
			ControlChannel.sendEcho(invokeMsg, true);
		}
	}//call()
	
	
	public function handleLocalCall( fnName:String, args:Array ):void{
		//trace( "ServiceInterfaceImpl localcall: " + args );
		
		if( interfaceMap.hasOwnProperty(fnName) ){
			var fn:Function = interfaceMap[fnName];
	 		var argArray:Array = eventMap.getStronglyTypedArgs(fnName, args);	//deserialize from XML
			fn.apply( this, argArray );
		}else{
			trace( "ERROR: function " + fnName + "(...) not found in API" );   
		}
		
	}//handleLocalCall()
	
	
	
	public function registerEventMap(mapInstance:String):void{
		var cls:Class = getDefinitionByName("services.xml." + mapInstance) as Class;
		eventMap = new cls();	
			
		handleLocalCall( "registerEventMapComplete", null );
	}//registerEventMap()
	
	
}//class
}//package


/**
 * class used to make ServiceInterface a Singleton class
 * @private
 */
class SingletonEnforcer{}