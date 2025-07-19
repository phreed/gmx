package gmx.data;

/**
 * Collection Value Object - converted from ActionScript to Haxe
 * Represents a collection with CUID and list of RUIDs
 */
class CollectionVO {

    // Data Members
    private var _cuid:String;
    private var _ruidList:Array<RuidVO>;

    public function new() {
        _ruidList = new Array<RuidVO>();
    }

    // Getter/Setter for cuid
    public var cuid(get, set):String;

    private function get_cuid():String {
        return _cuid;
    }

    private function set_cuid(data:String):String {
        _cuid = data;
        return _cuid;
    }

    // Getter/Setter for ruidList
    public var ruidList(get, set):Array<RuidVO>;

    private function get_ruidList():Array<RuidVO> {
        return _ruidList;
    }

    private function set_ruidList(data:Array<RuidVO>):Array<RuidVO> {
        _ruidList = data;
        return _ruidList;
    }

    /**
     * Populate this object from XML data
     */
    public function fromXML(data:Xml):Void {
        // Read attributes
        if (data.exists("cuid")) {
            _cuid = data.get("cuid");
        }

        // Parse child elements
        for (element in data.elements()) {
            switch (element.nodeName) {
                case "cuid":
                    _cuid = element.firstChild() != null ? element.firstChild().nodeValue : "";

                case "ruidList":
                    parseRuidList(element);
            }
        }
    }

    /**
     * Parse the ruidList XML element
     */
    private function parseRuidList(ruidListElement:Xml):Void {
        _ruidList = new Array<RuidVO>();

        for (ruidElement in ruidListElement.elements()) {
            if (ruidElement.nodeName == "Ruid") {
                var ruid:RuidVO = new RuidVO();
                ruid.fromXML(ruidElement);
                _ruidList.push(ruid);
            }
        }
    }

    /**
     * Export this object to XML
     */
    public function toXML(data:Xml):Void {
        if (_cuid != null) {
            data.set("cuid", _cuid);
        }

        // Create ruidList element
        if (_ruidList != null && _ruidList.length > 0) {
            var ruidListElement = Xml.createElement("ruidList");

            for (ruid in _ruidList) {
                var ruidXML = Xml.createElement("Ruid");
                ruid.toXML(ruidXML);
                ruidListElement.addChild(ruidXML);
            }

            data.addChild(ruidListElement);
        }
    }

    /**
     * Create XML representation of this collection
     */
    public function createXML():Xml {
        var xml = Xml.createElement("Collection");
        toXML(xml);
        return xml;
    }

    /**
     * Add a RUID to the collection
     */
    public function addRuid(ruid:RuidVO):Void {
        if (_ruidList == null) {
            _ruidList = new Array<RuidVO>();
        }
        _ruidList.push(ruid);
    }

    /**
     * Get RUID by ID
     */
    public function getRuidById(ruidId:String):RuidVO {
        if (_ruidList == null) return null;

        for (ruid in _ruidList) {
            if (ruid.ruid == ruidId) {
                return ruid;
            }
        }
        return null;
    }

    /**
     * Remove RUID by ID
     */
    public function removeRuidById(ruidId:String):Bool {
        if (_ruidList == null) return false;

        for (i in 0..._ruidList.length) {
            if (_ruidList[i].ruid == ruidId) {
                _ruidList.splice(i, 1);
                return true;
            }
        }
        return false;
    }

    /**
     * Get all selected RUIDs
     */
    public function getSelectedRuids():Array<RuidVO> {
        var selected = new Array<RuidVO>();
        if (_ruidList == null) return selected;

        for (ruid in _ruidList) {
            if (ruid.select == "true" || ruid.select == "1") {
                selected.push(ruid);
            }
        }
        return selected;
    }

    /**
     * Clear all selections
     */
    public function clearSelections():Void {
        if (_ruidList == null) return;

        for (ruid in _ruidList) {
            ruid.select = "false";
        }
    }

    /**
     * String representation for debugging
     */
    public function toString():String {
        var ruidCount = _ruidList != null ? _ruidList.length : 0;
        return 'CollectionVO(cuid: $_cuid, ruids: $ruidCount)';
    }
}
