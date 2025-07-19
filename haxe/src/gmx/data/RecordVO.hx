package gmx.data;

/**
 * Record Value Object - converted from ActionScript to Haxe
 * Represents a record with RUID, field list, and layout information
 */
class RecordVO {

    // Data Members
    private var _ruid:String;
    private var _fieldList:Array<FieldVO>;
    private var _layout:String;

    public function new() {
        _fieldList = new Array<FieldVO>();
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

    // Getter/Setter for fieldList
    public var fieldList(get, set):Array<FieldVO>;

    private function get_fieldList():Array<FieldVO> {
        return _fieldList;
    }

    private function set_fieldList(data:Array<FieldVO>):Array<FieldVO> {
        _fieldList = data;
        return _fieldList;
    }

    // Getter/Setter for layout
    public var layout(get, set):String;

    private function get_layout():String {
        return _layout;
    }

    private function set_layout(data:String):String {
        _layout = data;
        return _layout;
    }

    /**
     * Populate this object from XML data
     */
    public function fromXML(data:Xml):Void {
        // Read attributes
        if (data.exists("ruid")) {
            _ruid = data.get("ruid");
        }

        if (data.exists("layout")) {
            _layout = data.get("layout");
        }

        // Parse child elements
        for (element in data.elements()) {
            switch (element.nodeName) {
                case "ruid":
                    _ruid = element.firstChild() != null ? element.firstChild().nodeValue : "";

                case "layout":
                    _layout = element.firstChild() != null ? element.firstChild().nodeValue : "";

                case "fieldList":
                    parseFieldList(element);
            }
        }
    }

    /**
     * Parse the fieldList XML element
     */
    private function parseFieldList(fieldListElement:Xml):Void {
        _fieldList = new Array<FieldVO>();

        for (fieldElement in fieldListElement.elements()) {
            if (fieldElement.nodeName == "Field") {
                var field:FieldVO = new FieldVO();
                field.fromXML(fieldElement);
                _fieldList.push(field);
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

        if (_layout != null) {
            data.set("layout", _layout);
        }

        // Create fieldList element
        if (_fieldList != null && _fieldList.length > 0) {
            var fieldListElement = Xml.createElement("fieldList");

            for (field in _fieldList) {
                var fieldXML = Xml.createElement("Field");
                field.toXML(fieldXML);
                fieldListElement.addChild(fieldXML);
            }

            data.addChild(fieldListElement);
        }
    }

    /**
     * Create XML representation of this record
     */
    public function createXML():Xml {
        var xml = Xml.createElement("Record");
        toXML(xml);
        return xml;
    }

    /**
     * Add a field to the field list
     */
    public function addField(field:FieldVO):Void {
        if (_fieldList == null) {
            _fieldList = new Array<FieldVO>();
        }
        _fieldList.push(field);
    }

    /**
     * Get field by ID
     */
    public function getFieldById(fid:String):FieldVO {
        if (_fieldList == null) return null;

        for (field in _fieldList) {
            if (field.fid == fid) {
                return field;
            }
        }
        return null;
    }

    /**
     * Remove field by ID
     */
    public function removeFieldById(fid:String):Bool {
        if (_fieldList == null) return false;

        for (i in 0..._fieldList.length) {
            if (_fieldList[i].fid == fid) {
                _fieldList.splice(i, 1);
                return true;
            }
        }
        return false;
    }

    /**
     * String representation for debugging
     */
    public function toString():String {
        var fieldCount = _fieldList != null ? _fieldList.length : 0;
        return 'RecordVO(ruid: $_ruid, layout: $_layout, fields: $fieldCount)';
    }
}
