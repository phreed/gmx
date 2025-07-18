package gmx.data;

/**
 * Field Value Object - converted from ActionScript to Haxe
 * Represents a field with ID and value, with XML serialization support
 */
class FieldVO {

    // Data Members
    private var _fid:String;
    private var _value:String;

    public function new() {
        // Constructor
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

    // Getter/Setter for value
    public var value(get, set):String;

    private function get_value():String {
        return _value;
    }

    private function set_value(data:String):String {
        _value = data;
        return _value;
    }

    /**
     * Populate this object from XML data
     */
    public function fromXML(data:Xml):Void {
        if (data.exists("fid")) {
            _fid = data.get("fid");
        }

        if (data.exists("value")) {
            _value = data.get("value");
        }

        // Also check for element content
        for (element in data.elements()) {
            switch (element.nodeName) {
                case "fid":
                    _fid = element.firstChild() != null ? element.firstChild().nodeValue : "";
                case "value":
                    _value = element.firstChild() != null ? element.firstChild().nodeValue : "";
            }
        }
    }

    /**
     * Export this object to XML
     */
    public function toXML(data:Xml):Void {
        if (_fid != null) {
            data.set("fid", _fid);
        }

        if (_value != null) {
            data.set("value", _value);
        }
    }

    /**
     * Create XML representation of this field
     */
    public function createXML():Xml {
        var xml = Xml.createElement("Field");
        toXML(xml);
        return xml;
    }

    /**
     * String representation for debugging
     */
    public function toString():String {
        return 'FieldVO(fid: $_fid, value: $_value)';
    }
}
