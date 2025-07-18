package gmx.data;

/**
 * Attribute Value Object - converted from ActionScript to Haxe
 * Represents an attribute with RUID, field ID, send flag, action state, and permissions
 */
class AttributeVO {

    // Data Members
    private var _ruid:String;
    private var _fid:String;
    private var _send:String;
    private var _actionState:String;
    private var _permissions:String;

    public function new() {
        // Constructor
    }

    // Getter/Setter for ruid
    public var ruid(get, set):String;

    private function get_ruid():String {
        return _ruid;
    }

    private function set_ruid(data:String):String {
        _ruid = data;
        return _ruid;
    }

    // Getter/Setter for fid
    public var fid(get, set):String;

    private function get_fid():String {
        return _fid;
    }

    private function set_fid(data:String):String {
        _fid = data;
        return _fid;
    }

    // Getter/Setter for send
    public var send(get, set):String;

    private function get_send():String {
        return _send;
    }

    private function set_send(data:String):String {
        _send = data;
        return _send;
    }

    // Getter/Setter for actionState
    public var actionState(get, set):String;

    private function get_actionState():String {
        return _actionState;
    }

    private function set_actionState(data:String):String {
        _actionState = data;
        return _actionState;
    }

    // Getter/Setter for permissions
    public var permissions(get, set):String;

    private function get_permissions():String {
        return _permissions;
    }

    private function set_permissions(data:String):String {
        _permissions = data;
        return _permissions;
    }

    /**
     * Populate this object from XML data
     */
    public function fromXML(data:Xml):Void {
        // Read attributes
        if (data.exists("ruid")) {
            _ruid = data.get("ruid");
        }

        if (data.exists("fid")) {
            _fid = data.get("fid");
        }

        if (data.exists("send")) {
            _send = data.get("send");
        }

        if (data.exists("actionState")) {
            _actionState = data.get("actionState");
        }

        if (data.exists("permissions")) {
            _permissions = data.get("permissions");
        }

        // Also check for element content
        for (element in data.elements()) {
            switch (element.nodeName) {
                case "ruid":
                    _ruid = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "fid":
                    _fid = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "send":
                    _send = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "actionState":
                    _actionState = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "permissions":
                    _permissions = element.firstChild() != null ? element.firstChild().nodeValue : "";
            }
        }
    }

    /**
     * Export this object to XML
     */
    public function toXML(data:Xml):Void {
        if (_ruid != null) {
            data.set("ruid", _ruid);
        }

        if (_fid != null) {
            data.set("fid", _fid);
        }

        if (_send != null) {
            data.set("send", _send);
        }

        if (_actionState != null) {
            data.set("actionState", _actionState);
        }

        if (_permissions != null) {
            data.set("permissions", _permissions);
        }
    }

    /**
     * Create XML representation of this attribute
     */
    public function createXML():Xml {
        var xml = Xml.createElement("Attribute");
        toXML(xml);
        return xml;
    }

    /**
     * Check if this attribute has permission for a specific action
     */
    public function hasPermission(action:String):Bool {
        if (_permissions == null) return false;
        return _permissions.indexOf(action) >= 0;
    }

    /**
     * Check if send flag is enabled
     */
    public function canSend():Bool {
        return _send == "true" || _send == "1";
    }

    /**
     * String representation for debugging
     */
    public function toString():String {
        return 'AttributeVO(ruid: $_ruid, fid: $_fid, send: $_send, actionState: $_actionState, permissions: $_permissions)';
    }
}
