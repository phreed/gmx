package gmx.data;

/**
 * Ruid Value Object - converted from ActionScript to Haxe
 * Represents a record unique identifier with reference and selection information
 */
class RuidVO {

    // Data Members
    private var _ruid:String;
    private var _ref:String;
    private var _select:String;

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

    // Getter/Setter for ref
    public var ref(get, set):String;

    private function get_ref():String {
        return _ref;
    }

    private function set_ref(data:String):String {
        _ref = data;
        return _ref;
    }

    // Getter/Setter for select
    public var select(get, set):String;

    private function get_select():String {
        return _select;
    }

    private function set_select(data:String):String {
        _select = data;
        return _select;
    }

    /**
     * Populate this object from XML data
     */
    public function fromXML(data:Xml):Void {
        // Read attributes
        if (data.exists("ruid")) {
            _ruid = data.get("ruid");
        }

        if (data.exists("ref")) {
            _ref = data.get("ref");
        }

        if (data.exists("select")) {
            _select = data.get("select");
        }

        // Also check for element content
        for (element in data.elements()) {
            switch (element.nodeName) {
                case "ruid":
                    _ruid = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "ref":
                    _ref = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "select":
                    _select = element.firstChild() != null ? element.firstChild().nodeValue : "";
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

        if (_ref != null) {
            data.set("ref", _ref);
        }

        if (_select != null) {
            data.set("select", _select);
        }
    }

    /**
     * Create XML representation of this ruid
     */
    public function createXML():Xml {
        var xml = Xml.createElement("Ruid");
        toXML(xml);
        return xml;
    }

    /**
     * String representation for debugging
     */
    public function toString():String {
        return 'RuidVO(ruid: $_ruid, ref: $_ref, select: $_select)';
    }
}
