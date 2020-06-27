package records
{
	import GMX.Data.AttributeVO;
	import mx.controls.Alert;
	import services.ControlChannel;
	public class Attributes extends Object
	{
		protected var _field:Field;
		public function Attributes(field:Field)
		{
			super();
			_field = field;
		}
		
		protected var _dirty:Boolean = false;
		public function get dirty():Boolean { return _dirty; }
		public function set dirty(val:Boolean):void { _dirty = val; }
		
		public static const PERMISSIONS_RO:int = 0;
		public static const PERMISSIONS_DISABLED:int = 1;
		public static const PERMISSIONS_RW:int = 2;
		protected var _permissions:int = PERMISSIONS_RW;
		
		public static const SEND_CHANGE:int = 0;
		public static const SEND_ALWAYS:int = 1;
		public static const SEND_NEVER:int = 2;
		protected var _send:int = SEND_ALWAYS;
		
		public static const ACTION_STATE_WAITING:int = 0;
		public static const ACTION_STATE_FAILED:int = 1;
		public static const ACTION_STATE_OK:int = 2;
		public static const ACTION_STATE_ACTIVE:int = 3;
		protected var _actionState:int = ACTION_STATE_OK;
		
		public static const UPDATE_COMPONENTS_ON_CHANGE:int = 0;
		public static const UPDATE_COMPONENTS_ALWAYS:int = 1;
		protected var _updateComponentsCondition:int = UPDATE_COMPONENTS_ON_CHANGE;
		
		public function get send():int { return _send; }
		public function set send(val:int):void { 
			if (_send == val) { return; }
			_send = val;
			updateComponents();
		}
		
		public function get permissions():int { return _permissions; }
		public function set permissions(val:int):void { 
			if (_permissions == val) { return; }
			_permissions = val;
			updateComponents();
		}
		
		/*public function get highlight():int { 	return _highlight; }
		public function set highlight(val:int):void { 
			if (_field.component != null) {
				switch(val) {
					case HIGHLIGHT_EMBEDDED_HELP: break;
		            case HIGHLIGHT_RECOMMENDED: break;
		            case HIGHLIGHT_NORMAL: break;
				}
			}
			_highlight = val;
		}*/
		public function get actionState():int { return _actionState; }
		public function set actionState(val:int):void { 
			if (_actionState == val) { return; }
			_actionState = val;
			updateComponents();
		}
		
		public function get updateComponentsCondition():int { return _updateComponentsCondition; }
		public function set updateComponentsCondition(val:int):void { 
			if (_updateComponentsCondition == val) { return; }
			_updateComponentsCondition = val;
		}
		
		public function processAttributeVO(attributeVO:AttributeVO):void {
			if (attributeVO == null) { Alert.show("WARNING: Attributes attempted to process a null AttributeVO!"); return; }
			
			var newActionState:String = attributeVO.actionState;
			var newPermissions:String = attributeVO.permissions;
			var newSend:String = attributeVO.send;
			if (newActionState != null && newActionState != "") {
				switch(newActionState.toLowerCase()) {
					case "waiting": _actionState = ACTION_STATE_WAITING; break;
					case "failed": _actionState = ACTION_STATE_FAILED; break;
					case "ok": _actionState = ACTION_STATE_OK; break;
					case "active": _actionState = ACTION_STATE_ACTIVE; break;
					default: Alert.show("WARNING: incoming ISISAttributes message with invalid actionState='" + newActionState + "'.  "
										+ "Valid actionStates are (NOT CASE SENSITIVE) 'waiting', 'failed', 'ok', & 'active'");
				}
			}
			if (newSend != null && newSend != "") {
				switch(newSend.toLowerCase()) {
					case "always": _send = SEND_ALWAYS; break;
					case "changed": _send = SEND_CHANGE; break;
					case "never": _send = SEND_NEVER;  break;
					default: Alert.show("WARNING: incoming ISISAttributes message with invalid send='" + newSend + "'.  "
										+ "Valid send options are (NOT CASE SENSITIVE) 'always', 'changed', & 'never'");
				}	
			}
			if (newPermissions != null && newPermissions != "") {
				switch(newPermissions.toLowerCase()) {
					case "readonly": this.permissions = PERMISSIONS_RO; break;
					case "disabled": this.permissions = PERMISSIONS_DISABLED; break;
					case "readwrite": this.permissions = PERMISSIONS_RW; break;
					default: Alert.show("WARNING: incoming ISISAttributes message with invalid permission='" + newPermissions + "'.  "
										+ "Valid permissions are (NOT CASE SENSITIVE) 'readOnly', 'disabled', & 'readWrite'");
				}
			}
			updateComponents();
		}
		
		public function updateComponents():void {
			if (_field == null || _field.componentsRequiringUpdate.length == 0) { return; }
			
			for (var i:int = 0; i < _field.componentsRequiringUpdate.length; i++) {
				_field.componentsRequiringUpdate[i].setAttributes(this);
			}
			/*switch(_permissions) {
				case PERMISSIONS_DISABLED:
					setEnabled(false);
					break;
				case PERMISSIONS_RO:
				case PERMISSIONS_RW:
					setEnabled(true);
					break;
			}*/
			/*switch(_send) {
				case SEND_CHANGE: break;
				case SEND_ALWAYS: break;
				case SEND_NEVER: break;
			}*/

			/*switch(_actionState) {
				case ACTION_STATE_WAITING: break;
				case ACTION_STATE_FAILED: break;
				case ACTION_STATE_OK: break;
				case ACTION_STATE_ACTIVE: break;
			}*/
		}
		
		//private function setEnabled(val:Boolean):void {
		//	for (var i:int = 0; i < _field.componentsRequiringUpdate.length; i++) {
		//		_field.componentsRequiringUpdate[i] = val;
		//	}
		//}
		
		// expects a message of the form "|:send:never|:permissions:readWrite|:actionState:ok"
		public function updateAttributesFromLayout(arg:String):void {
			//trace("updateAttributesFromLayout: " + arg);
			var params:Vector.<String> = GMXMain.splitter(arg);
			var attributeVO:AttributeVO = new AttributeVO();
			while (params.length != 0) {
				var vals:Vector.<String>;
				vals = GMXMain.splitter(params.shift());
				switch (vals.shift()) {
					case "send":
						attributeVO.send = vals.shift();
						break;
					case "permissions":
						attributeVO.permissions = vals.shift();
						break;
					case "actionstate":
						attributeVO.actionState = vals.shift();
						break;
					default:
						var componentString:String = null;
						if (this._field != null) {
							componentString = "" + this._field.componentsRequiringUpdate;
						}
						Alert.show("WARNING: Layout message for component=" + componentString + " containing unexpected Attributes updateAttributesFromLayout=" + arg + ".  Expected "
								+ "'send', 'permissions', or 'actionState'!");
				}
			}
			processAttributeVO(attributeVO);
		}
	}
}