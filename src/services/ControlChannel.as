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

package services
{
	import __AS3__.vec.Vector;
	import flash.events.MouseEvent;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	
	import flash.errors.IOError;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.XMLSocket;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	
	/**
	 * ...
	 * @author 
	 */
	public class ControlChannel 
	{		
		public static var socket:XMLSocket = new XMLSocket; 
		private var _host:String = GMXMain.DEFAULT_CONTROL_CHANNEL_HOST;
		private var _port:uint = GMXMain.DEFAULT_CONTROL_CHANNEL_PORT;
		
		private static var _popUp:VBox = new VBox();
		private static var _hostTextInput:TextInput = new TextInput();
		private static var _portTextInput:TextInput = new TextInput();
		private static var _connectButton:Button = new Button();
		private static var _offlineButton:Button = new Button();
		private static var _popUpMessageTextArea:TextArea = new TextArea();
		
		
		public static var date:Date = new Date();
		public static var echoUpload:Boolean = false;
		public static var echoDownload:Boolean = false;
		
		public static var timer:Timer = new Timer(20, 1);
		public static var polling:Boolean = false;
		public static var layoutDirty:Boolean = false;
		public static var grainSize:Number = 2.0;
		public static var avgRoundTripTime:Number = 0.0;
		public static var avgUpdateTime:Number = 0.0;
		public static var throughputSize:int = 0;
		public static var block:Boolean = false;
		public static var autoUpdate:Boolean = false;
		public static var numUpdates:int = 0;
		public static var startTime:int = 0;
		public static var stopTime:int = 0;
		public static var connectionSubscription:Boolean = false;
		
		public static var requestBeginTime:int = 0;
		private var profile:Object = new Object;
		public static var connectionChangeTime:String = "0:0:0:0";
		private static var _connectionIsUp:Boolean = false;
		
		public function ControlChannel() {
			// the popUp is used to allow the user to attempt to reconnect to a specified host and port
			// if connection is not initially established or lost.
			_popUp = new VBox();
			_popUp.setStyle("horizontalAlign", "center");
			_popUp.setStyle("borderStyle", "solid");
			_popUp.setStyle("borderThickness", 2);
			_popUp.setStyle("borderColor", 0);
			_popUp.setStyle("backgroundColor", 0xcccccc)
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(Event.CONNECT, connectedHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.addEventListener(DataEvent.DATA, socketDataHandler);
			timer.addEventListener(TimerEvent.TIMER, time, false, 0, true);
			profile.throughputSize = 0;
			profile.avgRoundTripTime = 0;
			profile.grainSize = 0.0;
			profile.avgUpdateTime = 0;
			profile.numUpdates = 0;
			_popUp.width = 220;
			_popUp.height = 300;
			_popUp.setStyle("horizontalAlign", "center");
			_popUpMessageTextArea.width = 200;
			_popUpMessageTextArea.height = 200;
			_popUpMessageTextArea.wordWrap = true;
			_popUpMessageTextArea.verticalScrollPolicy = "auto";
			_popUp.addChild(_popUpMessageTextArea);
			_popUpMessageTextArea.editable = false;
			_popUpMessageTextArea.setStyle("backgroundColor", 0xcccccc);
			
			var hBox:HBox;
			var label:Label;
			
			hBox = new HBox();
			label = new Label();
			label.text = "host:";
			label.width = 100;
			label.setStyle("textAlign", "right");
			_hostTextInput.width = 100;
			hBox.addChild(label);
			hBox.addChild(_hostTextInput);
			_popUp.addChild(hBox);
			
			hBox = new HBox();
			label = new Label();
			label.text = "port:";
			label.width = 100;
			label.setStyle("textAlign", "right");
			_portTextInput.width = 100;
			hBox.addChild(label);
			hBox.addChild(_portTextInput);
			_popUp.addChild(hBox);
			
			hBox = new HBox();
			hBox.setStyle("paddingTop", 20);
			_connectButton.label = "Connect";
			_offlineButton.label = "Work Off-line";
			hBox.setStyle("horizontalGap", 20);
			hBox.addChild(_connectButton);
			hBox.addChild(_offlineButton);
			_popUp.addChild(hBox);
			_popUp.visible = false;
			GMXMain.PopUps.addChild(_popUp);
			
			_connectButton.addEventListener(MouseEvent.CLICK, connectClick);
			_offlineButton.addEventListener(MouseEvent.CLICK, offlineClick);
			_portTextInput.restrict = "0123456789";
		}
		
		private function offlineClick(event:MouseEvent):void {
			_popUp.visible = false;
		}
		private function connectClick(event:MouseEvent):void {
			var checkPort:int = parseInt(_portTextInput.text);
			if (isNaN(checkPort)) {
				Alert.show("Port was not a number!  Try again!");
				return;
			}
			port = checkPort;
			host = _hostTextInput.text;
			this.connect();
			_popUp.visible = false;
		}
		
		public function setHostAndPortFromFlashVars():void {
			port = uint( mx.core.Application.application.parameters.port );
			if( _port == 0 ){
				_port = GMXMain.DEFAULT_CONTROL_CHANNEL_PORT;	//default to 12345 for test harness if no port specified
			}
			
			host = mx.core.Application.application.parameters.host;
			if( _host ){
				//socket.host = _host;  //use specified host if provided, otherwise, use SocketConnection default
			} else {
				_host = GMXMain.DEFAULT_CONTROL_CHANNEL_HOST;
			}
		}
		
		public function set port( p:uint ):void{
			_port = p;
		}

		public function set host( ip:String ):void{
			_host = ip;
		}
		
		private function connectedHandler(event:Event):void {
			trace("control channel connect handler reached: connected = " + socket.connected);
			GMXMain.do_ISISRefresh("reset");
		}
		
		public function send( data:Object ):void {
			try {
				socket.send(data);
			}catch(e:IOError){
				trace( e );
			}
		}
		
		private function showAlert(alertText:String):void {
			_popUpMessageTextArea.text = alertText;
			_popUp.x = GMXMain.application.width / 2 - _popUp.width / 2;
			_popUp.y = GMXMain.application.height / 2 - _popUp.height / 2;
			_popUp.visible = true;
			_hostTextInput.text = _host;
			_portTextInput.text = _port + "";
			GMXMain.PopUps.addChild(_popUp);
		}
				
		private function closeHandler(event:Event):void {
			trace("closeHandler: " + event);
			/*Alert.show("Connection to Control Channel Interrupted (port="+ _port +")!  Press 'Yes' to attempt reconnect. NOTE: If you select 'No', the only way to " + 
					"reconnect is to click somewhere on this swf (so it is the active window) and type 'gmeisfunctrlmode'.  To change the port, edit the .html file's FlashVars port parameter. ", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);
			*/
			showAlert("Connection to Control Channel Interrupted (port="+ _port +")!  Press 'Connect' to attempt reconnect. NOTE: If you select 'Work Off-line', the only way to " + 
					"reconnect is to click somewhere on this swf (so it is the active window) and type 'gmeisfunctrlmode'.  To change the startup port, edit the .html file's FlashVars port parameter, " +
					"or change it in the text boxes below.");
		}
		/*
		private function alertClick(event:CloseEvent):void {
            if (event.detail==Alert.YES)
				this.connect();
        }
		*/
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("ioErrorHandler: " + event);
			/*Alert.show("Connection to Control Channel (port="+ _port +") Not established!  Press 'Yes' to attempt reconnect. NOTE: If you select 'No', the only way to " + 
					"reconnect is to click somewhere on this swf (so it is the active window) and type 'gmeisfunctrlmode'", "Connection Lost", Alert.NONMODAL + Alert.YES + Alert.NO,
						 null, alertClick);*/
			showAlert("Connection to Control Channel (port="+ _port +") Not established!  Press 'Connect' to attempt reconnect. NOTE: If you select 'Work Off-line', the only way to " + 
					"reconnect is to click somewhere on this swf (so it is the active window) and type 'gmeisfunctrlmode'.  To change the startup port, edit the .html file's FlashVars port parameter, " +
					"or change it in the text boxes below.");
		}
				
		private function progressHandler(event:ProgressEvent):void {
			trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}
		
		private const _swfpat:RegExp = new RegExp("(file:.+/)\\w+\\.swf", "ix");
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			var url:String
			try {
				var app:Application = mx.core.Application.application as Application;
				url = unescape(app.url);
			} catch (e:Error) {
				url = "(wherever the directory from which you are running this swf is)";
			}
			// var app:Application = FlexGlobals.topLevelApplication; Flex 4.0
			
			var match:Array = _swfpat.exec(url);
			var root_url:String = match[1] as String;
			
			/*
			Alert.show('You do not have the appropriate security level.\n'
        			+'You need '+Security.LOCAL_TRUSTED+' but have '+ Security.sandboxType+'\n'
        			+'This can be enabled by using either the "Settings Manager" \n'
        			+ 'or updating "FlashPlayerTrust/warmap.cfg.\n'
	        		+ 'win32 : C:\\WINDOWS\\system32\\Macromed\\Flash\\FlashPlayerTrust\\widmaster.cfg \n'
	        		+ 'linux : /etc/adobe/FlashPlayerTrust/widmaster.cfg\n'
	        		+ 'warmap.cfg should contain...\n\n'
	        		+ root_url+'\n\n');
			*/
			
			Alert.show('You either don\'t have a port listening at host="' + _host + '" port="' + _port + '" or you don\'t have the appropriate security level to set up a socket connection from Flash!\n'
			+'\tYou can change the host & port that GMX initially tries to connect to by:\n'
			+'  1) open the .html file (which you should be running this through) in a text editor\n'
			+'  2) search for the "FlashVars" parameter--you should find port and host arguments there that you can change.\n'
			+'\tYou can change the security settings by:\n'
			+'\tLINUX: '
			+'  1) add the "' + root_url + '" directory to /etc/adobe/FlashPlayerTrust/widmaster.cfg \n'
			+'\tWINDOWS: '
			+'  1) right clicking anywhere in the swf and selecting "Global Settings" & SKIP step 2... if "Global Settings" isn\'t there, select "Settings" (older flash player version) and DO step 2\n'
			+'  2) (If you did not press "Global Settings", a little window pops up) Click "Advanced..."\n'
			+'  3) a browser should pop up with the Adobe Flash Player Help Settings Manager.  Click "Global Security Settings Panel" (on the left).\n'
			+'  4) in the Global Securety Settings panel, click the "Edit locations..." drop down and select "Add location..."\n'
			+'  5) click the "Browse for folder" button and choose the folder containing this .swf file\n'
			+'  6) re-run this application.  If that doesn\'t work, e-mail anelson@isis.vanderbilt.edu explaining the problem\n'
			+'OR, in WIN32 only:\n'
			+'  1) add the "' + root_url + '" directory to C:\\WINDOWS\\system32\\Macromed\\Flash\\FlashPlayerTrust\\widmaster.cfg \n'
			);
	        // Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
		}
		
		public function connect():void{
			if( !socket.connected ) {
				socket.connect( _host, _port );
			}
		}
		
		private function socketDataHandler(event:DataEvent):void {
			try {
				var msg:String = String(event.data); //data will always be XML
				if (GMXMain.debugReceive && GMXMain.testing == true) { trace("======ControlChannel MESSAGE RECEIVED=======\n" + msg + "\n===== END RECEIVED ========"); }
			} catch(e:Error) {
				Alert.show("WARNING: Incoming string message was not processed correctly: " + e.message);
				return;
			}
			if (event.data == "|S|C|") { return; } // legacy from the map...
			
			var whiteSpaceCheck:String = msg.substring(0,1);
			while (whiteSpaceCheck == " " || whiteSpaceCheck == "\t" || whiteSpaceCheck == "\n" || whiteSpaceCheck == "\r") {
				msg = msg.substring(1);
				whiteSpaceCheck = msg.substring(0,1);
			}
			if (whiteSpaceCheck == "<") {
				SocketController.dispatcher.dispatchEvent(event);
				// it is assumed to be xml--don't have to keep going
				return;
			}
						
			if (msg == null) { trace("msg has no payload"); return; }

			var param_set:Vector.<String> = GMXMain.splitter(msg);
			var param:String;
			if (param_set.length < 1) { trace("msg has no action"); return; }
			trace("msg:"+msg);
			var action:String = param_set.shift();
			try {
				switch (action) {
					case "SC": _handleSocketConnection(param_set); break;					
					case "M": _handleModeChange(param_set); break; 
					case "S": _handleStatusMessage(param_set); break; 
					case "Q": _handleProfileRequest(param_set); break; 
					//case "E": _handleEchoToggle(param_set); break; 
					default: trace("action "+action+" not defined in: "+msg);
				} 
			} catch (ex:Error) {
				trace("error: "+ex.message);
			} 
		}
		
		public function processCommand(msg:String):Boolean { // returns false if the command was not recognized so that it is forwarded to the ControlChannel using ISISRefresh
			var param_set:Vector.<String> = GMXMain.splitter(msg);
			var param:String;
			if (param_set.length < 1) { trace("msg has no action"); return false; }
			trace("msg:"+msg);
			var action:String = param_set.shift();
			try {
				switch (action) {
					case "SC": _handleSocketConnection(param_set); break;					
					case "M": _handleModeChange(param_set); break; 
					case "S": _handleStatusMessage(param_set); break; 
					case "Q": _handleProfileRequest(param_set); break; 
					//case "E": _handleEchoToggle(param_set); break; 
					default: trace("action " + action + " not defined in: " + msg);
						return false;
				} 
			} catch (ex:Error) {
				Alert.show("Incoming message: " + msg + " caused the error: " + ex.message);
				return false;
			}
			return true;
		}

		private function _handleSocketConnection(param_set:Vector.<String>):void {
			if (param_set[0] == null || param_set[1] == null) { 
				Alert("WARNING: Socket connection message received not in the form '|SC|:P:12345|:H:localhost|:ID:socketid1'");	
				return; 
			}
			var newPort:int = -1;
			var newHost:String = null;
			var newID:String = null;
			for (var i:int = 0; i < 3; i++) {
				var params:Vector.<String> = GMXMain.splitter(param_set[i]);
				switch(params.shift()) {
					case "P":
						newPort = parseInt(params.shift());
						break;
					case "H":
						newHost = params.shift();
						break;
					case "ID":
						newID = params.shift();
						break;
				}
			}
			if (newPort == -1 || newHost == null || newID == null) {
				Alert("WARNING: Socket connection message not in the correct form of '|SC|:P:12345|:H:localhost|:ID:socketid1'");
				return;
			} 
			SocketController.addSocket(newPort, newHost, newID);
		}
		
/**By default no messages are sent on the command channel.
The mode (or other boolean variables) must be set on/true/enable before any message is sent.
Binary variables are set using the 'M' grammar with a set of values*/
		private function _handleModeChange(param_set:Vector.<String>):void {
			//|M|+|:P:2.0
			//|M|+|:E:d
			//|M|-|:E:u
			//|M|+|:E:d:u
			var params:Vector.<String>;
			switch(param_set.shift()) {
				case "+":
					params = GMXMain.splitter(param_set.shift());
					switch(params.shift()) {
						case "P":
							grainSize = parseFloat(params.shift());
							throughputSize = 0;
							avgRoundTripTime = 0;
							timer.delay = Math.round(1000.0 * grainSize);
							timer.reset();
							timer.start();
							requestBeginTime = getTimer();
							polling = true;
							numUpdates = 0;
							if (params.length != 0) {
								if (params.shift() == "A") {
									autoUpdate = true;
								} else autoUpdate = false;
							}  else autoUpdate = false;
							break;
						case "E":
							for (var i:int = 0; i < params.length; i++) {
								if (params[i] == "u") { echoUpload = true }
								else if (params[i] == "d") { echoDownload = true }
								else { Alert.show("Unexpected echo indicator: " + params[i] + "... expected 'u' or 'd'"); }
							}
							break;
						case "S":
							for (i = 0; i < params.length; i++) {
								if (params[i] == "conn") { connectionSubscription = true }
								else { Alert.show("Unexpected status indicator: " + params[i] + "... expected 'u' or 'd'"); }
							}
							break;
					}
					break;
				case "-":
					params = GMXMain.splitter(param_set.shift());
					switch(params.shift()) {
						case "P":
							polling = false;
							timer.stop();
							autoUpdate = false;
							break;
						case "E":
							for (i = 0; i < params.length; i++) {
								if (params[i] == "u") { echoUpload = false }
								else if (params[i] == "d") { echoDownload = false }
								else { Alert.show("Unexpected echo indicator: " + params[i] + "... expected 'u' or 'd'"); }
							}
							break;
						case "S":
							for (i = 0; i < params.length; i++) {
								if (params[i] == "conn") { connectionSubscription = false }
								else { Alert.show("Unexpected status indicator: " + params[i] + "... expected 'u' or 'd'"); }
							}
							break;
					}
					break;
			}
		}
		
		public static function set connectionStatus(connectionIsUp:Boolean):void {
			_connectionIsUp = connectionIsUp;
			connectionChangeTime = date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds() + "." + (Math.round(date.getMilliseconds() / 10));
			var updatedStatus:String = "|S|";
			updatedStatus += connectionIsUp ? "ec|" : "lc|";
			updatedStatus += "@T@" + connectionChangeTime;
			if (connectionSubscription) {
				socket.send(updatedStatus);
			}
		}
		/**The connection messages indicated whether the connection went up/down and when (no date just HH:MM:SS.ss)*/
		private function _handleStatusMessage(param_set:Vector.<String>):void {
//|M|+|:S:conn //These set the mode of the client which sends the messages when the state changes.
				//The server doesn't ask for them outside of setting the start/stop mode.
//|S|lc|@T@12:23:45.67
//|S|ec|@T@12:23:56.34
			
		}
/**The 'Q' message requests the current profile information.*/
		private function _handleProfileRequest(param_set:Vector.<String>):void {
			// |Q|RT|TP
			var msg:String = "|P";
			for (var i:uint = 0; i < param_set.length; i++) {
				switch(param_set[i]) {//"|P|=RT=" + _avgRoundTripTime + "|=T=" + _measurementGrainSize + "|=TP=" + _throughputSize;
					case "RT":
						msg += "|=RT=" + profile.avgRoundTripTime;
						break;
					case "T":
						msg += "|=T=" + profile.grainSize;
						break;
					case "TP":
						msg += "|=TP=" + profile.throughputSize;
						break;
					case "UP":
						msg += "|=UP=" + profile.numUpdates;
						break;
					case "UT":
						msg += "|=UT=" + profile.avgUpdateTime;
						break;
					default: Alert.show("WARNING: can't resolve '" + param_set[i] + "' to a correct profile request");
				}
			}
			try {
				socket.send(msg);
				trace("Profile Sent: " + msg);
			} catch (e:Error) {
				trace("send error: " + e.message);
			}
		}	
		
		public static function sendEcho(msg:XML,isUploadEcho:Boolean):void {
			//|E|d|<message>  d or u (download or upload
			var msg_string:String = "|E|";
			msg_string += isUploadEcho ? "u|" : "d|";
			msg_string += msg.toString();
			try {
				socket.send(msg_string);
			} catch (e:Error) {
				trace("WARNING: Control Channel send error: " + e.message);
			}
		}
		
		public static function send(msg:XML):void {
			try {
				socket.send(msg);
				
			} catch (e:Error) {
				trace("WARNING: Control Channel send error: " + e.message);
			}
		}
		
		private function time(event:TimerEvent):void {
			//trace("time: " + (grainSize - timeDifference/1000.0) );
			var timeDifference:int = getTimer() - requestBeginTime;
			if (grainSize - timeDifference/1000.0 < 0) { 
				//sendProfileInformation(avgRoundTripTime, timeDifference/1000.0, throughputSize);
				profile.grainSize = timeDifference / 1000.0;
				profile.avgRoundTripTime = avgRoundTripTime;
				profile.throughputSize = throughputSize;
				profile.avgUpdateTime = avgUpdateTime;
				profile.numUpdates = numUpdates;
				if (autoUpdate) {
					var param_set:Vector.<String> = new Vector.<String>;
					param_set.push("RT","T","TP","UP","UT");
					_handleProfileRequest(param_set);
				}
				throughputSize = 0;
				avgRoundTripTime = 0;
				avgUpdateTime = 0;
				timer.reset();
				timer.start();
				requestBeginTime = getTimer();
				numUpdates = 0;
			}
		}
		/**
	    * |X|:y|=z=123
	    * In general a command on objects with named properties
   */

		/**
The 'P' message is the response from the client reporting the RT, average round trip time, T, the measurement grain size, and TP, the message throughput size over the period. 
*/
		/*public function sendProfileInformation(_avgRoundTripTime:Number, _measurementGrainSize:Number, _throughputSize:int):void {
			var msg:String = "|P|=RT=" + _avgRoundTripTime + "|=T=" + _measurementGrainSize + "|=TP=" + _throughputSize;
			trace(msg);
			try {
				socket.send(msg);
			} catch (e:Error) {
				trace("send error: " + e.message);
			}
		}*/
	}
}