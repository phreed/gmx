package gmx.builder;

import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import h2d.TextInput;
import hxd.Event;
import hxd.Key;

/**
 * XMLDisplay - Shows generated XML output with syntax highlighting
 * Provides read-only view of the current record/collection XML
 */
class XMLDisplay extends Object {

    private var container:Flow;
    private var background:Graphics;
    private var titleText:Text;
    private var xmlTextArea:XMLTextArea;
    private var scrollContainer:Flow;
    private var copyButton:Interactive;
    private var copyButtonBg:Graphics;
    private var copyButtonText:Text;

    // Display properties
    private var _width:Float = 250;
    private var _height:Float = 400;
    private var currentXML:Xml;

    // Colors for syntax highlighting
    static inline var COLOR_ELEMENT:Int = 0x0000FF;
    static inline var COLOR_ATTRIBUTE:Int = 0xFF0000;
    static inline var COLOR_TEXT:Int = 0x000000;
    static inline var COLOR_COMMENT:Int = 0x008000;

    public function new(parent:Object) {
        super(parent);
        initialize();
    }

    private function initialize():Void {
        // Create main container
        container = new Flow(this);
        container.layout = Vertical;
        container.verticalSpacing = 5;
        container.padding = 5;

        // Create background
        background = new Graphics(this);
        drawBackground();

        // Create title bar
        createTitleBar();

        // Create XML text area
        createXMLTextArea();

        // Create copy button
        createCopyButton();
    }

    private function drawBackground():Void {
        background.clear();
        background.beginFill(0xF8F8F8);
        background.lineStyle(1, 0xCCCCCC);
        background.drawRect(0, 0, _width, _height);
        background.endFill();
    }

    private function createTitleBar():Void {
        var titleContainer = new Flow(container);
        titleContainer.layout = Horizontal;
        titleContainer.horizontalSpacing = 5;
        titleContainer.maxWidth = Std.int(_width - 10);

        titleText = new Text(hxd.res.DefaultFont.get(), titleContainer);
        titleText.text = "XML Output";
        titleText.textColor = 0x000000;
    }

    private function createXMLTextArea():Void {
        // Create scroll container
        scrollContainer = new Flow(container);
        scrollContainer.layout = Vertical;
        scrollContainer.maxWidth = Std.int(_width - 15);
        scrollContainer.maxHeight = Std.int(_height - 80);

        // Create text area background
        var textAreaBg = new Graphics(scrollContainer);
        textAreaBg.beginFill(0xFFFFFF);
        textAreaBg.lineStyle(1, 0x999999);
        textAreaBg.drawRect(0, 0, _width - 20, _height - 85);
        textAreaBg.endFill();

        // Create XML text area
        xmlTextArea = new XMLTextArea(scrollContainer, _width - 25, _height - 90);
    }

    private function createCopyButton():Void {
        var buttonContainer = new Flow(container);
        buttonContainer.layout = Horizontal;
        buttonContainer.horizontalSpacing = 5;

        copyButtonBg = new Graphics(buttonContainer);
        copyButtonBg.beginFill(0xE0E0E0);
        copyButtonBg.lineStyle(1, 0x808080);
        copyButtonBg.drawRect(0, 0, 60, 20);
        copyButtonBg.endFill();

        copyButtonText = new Text(hxd.res.DefaultFont.get(), copyButtonBg);
        copyButtonText.text = "Copy";
        copyButtonText.textColor = 0x000000;
        copyButtonText.x = 18;
        copyButtonText.y = 3;

        copyButton = new Interactive(60, 20, copyButtonBg);
        copyButton.onClick = function(event:Event) {
            copyToClipboard();
        };

        copyButton.onOver = function(event:Event) {
            copyButtonBg.clear();
            copyButtonBg.beginFill(0xD0D0FF);
            copyButtonBg.lineStyle(1, 0x808080);
            copyButtonBg.drawRect(0, 0, 60, 20);
            copyButtonBg.endFill();
        };

        copyButton.onOut = function(event:Event) {
            copyButtonBg.clear();
            copyButtonBg.beginFill(0xE0E0E0);
            copyButtonBg.lineStyle(1, 0x808080);
            copyButtonBg.drawRect(0, 0, 60, 20);
            copyButtonBg.endFill();
        };
    }

    /**
     * Set the XML to display
     */
    public function setXML(xml:Xml):Void {
        currentXML = xml;
        if (xmlTextArea != null) {
            var formattedXML = formatXML(xml);
            xmlTextArea.setText(formattedXML);
        }
    }

    /**
     * Format XML with proper indentation
     */
    private function formatXML(xml:Xml):String {
        if (xml == null) return "";

        return formatXMLNode(xml, 0);
    }

    private function formatXMLNode(node:Xml, indent:Int):String {
        var result = "";
        var indentStr = StringTools.rpad("", " ", indent * 2);

        switch (node.nodeType) {
            case Element:
                result += indentStr + "<" + node.nodeName;

                // Add attributes
                for (attr in node.attributes()) {
                    result += ' $attr="${node.get(attr)}"';
                }

                // Check if element has children
                var hasChildren = false;
                var hasTextContent = false;
                var textContent = "";

                for (child in node) {
                    if (child.nodeType == Element) {
                        hasChildren = true;
                    } else if (child.nodeType == PCData || child.nodeType == CData) {
                        hasTextContent = true;
                        textContent += StringTools.trim(child.nodeValue);
                    }
                }

                if (hasChildren || hasTextContent) {
                    result += ">";

                    if (hasTextContent && !hasChildren) {
                        // Simple text content
                        result += textContent + "</" + node.nodeName + ">\n";
                    } else {
                        result += "\n";

                        // Add children
                        for (child in node) {
                            if (child.nodeType == Element) {
                                result += formatXMLNode(child, indent + 1);
                            } else if (child.nodeType == PCData || child.nodeType == CData) {
                                var content = StringTools.trim(child.nodeValue);
                                if (content.length > 0) {
                                    result += indentStr + "  " + content + "\n";
                                }
                            }
                        }

                        result += indentStr + "</" + node.nodeName + ">\n";
                    }
                } else {
                    // Self-closing tag
                    result += "/>\n";
                }

            case PCData, CData:
                var content = StringTools.trim(node.nodeValue);
                if (content.length > 0) {
                    result += indentStr + content + "\n";
                }

            case Comment:
                result += indentStr + "<!-- " + node.nodeValue + " -->\n";

            default:
                // Handle other node types if needed
        }

        return result;
    }

    /**
     * Copy XML to clipboard
     */
    private function copyToClipboard():Void {
        if (currentXML != null) {
            var xmlString = formatXML(currentXML);

            // For HashLink, we need to use system-specific clipboard access
            #if hl
            try {
                // Use system clipboard if available
                var clipboard = new sys.io.Process("clip", []);
                clipboard.stdin.writeString(xmlString);
                clipboard.stdin.close();
                clipboard.exitCode();
                trace("XML copied to clipboard");
            } catch (e:Dynamic) {
                trace("Could not copy to clipboard: " + e);
                // Fallback: just log the XML
                trace("XML content:\n" + xmlString);
            }
            #else
            trace("XML content:\n" + xmlString);
            #end
        }
    }

    /**
     * Set the size of the display
     */
    public function setSize(width:Float, height:Float):Void {
        _width = width;
        _height = height;

        drawBackground();

        if (scrollContainer != null) {
            scrollContainer.maxWidth = Std.int(_width - 15);
            scrollContainer.maxHeight = Std.int(_height - 80);
        }

        if (xmlTextArea != null) {
            xmlTextArea.setSize(_width - 25, _height - 90);
        }
    }

    /**
     * Clear the display
     */
    public function clear():Void {
        currentXML = null;
        if (xmlTextArea != null) {
            xmlTextArea.setText("");
        }
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        if (xmlTextArea != null) {
            xmlTextArea.update(dt);
        }
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        if (xmlTextArea != null) {
            xmlTextArea.dispose();
        }
        remove();
    }
}

/**
 * Custom text area for displaying XML with basic syntax highlighting
 */
class XMLTextArea extends Object {

    private var background:Graphics;
    private var textLines:Array<Text>;
    private var scrollY:Float = 0;
    private var maxScrollY:Float = 0;
    private var lineHeight:Float = 14;
    private var _width:Float;
    private var _height:Float;
    private var interactive:Interactive;

    public function new(parent:Object, width:Float, height:Float) {
        super(parent);
        _width = width;
        _height = height;
        textLines = new Array<Text>();
        initialize();
    }

    private function initialize():Void {
        // Create background
        background = new Graphics(this);
        background.beginFill(0xFFFFFF);
        background.drawRect(0, 0, _width, _height);
        background.endFill();

        // Create interactive area for scrolling
        interactive = new Interactive(_width, _height, this);
        interactive.onWheel = function(event:Event) {
            scroll(event.wheelDelta * -20);
        };
    }

    /**
     * Set the text content
     */
    public function setText(text:String):Void {
        // Clear existing text lines
        for (line in textLines) {
            line.remove();
        }
        textLines = new Array<Text>();

        if (text == null || text.length == 0) {
            return;
        }

        // Split text into lines
        var lines = text.split("\n");
        var yPos:Float = 5;

        for (i in 0...lines.length) {
            var lineText = lines[i];
            if (lineText.length == 0) lineText = " "; // Ensure empty lines are visible

            var textObject = new Text(hxd.res.DefaultFont.get(), this);
            textObject.text = lineText;
            textObject.textColor = getLineColor(lineText);
            textObject.x = 5;
            textObject.y = yPos;
            textObject.maxWidth = Std.int(_width - 10);

            textLines.push(textObject);
            yPos += lineHeight;
        }

        // Calculate max scroll
        maxScrollY = Math.max(0, yPos - _height + 10);
        scrollY = 0;
        updateTextPositions();
    }

    /**
     * Get color for syntax highlighting
     */
    private function getLineColor(line:String):Int {
        var trimmed = StringTools.trim(line);

        if (trimmed.indexOf("<!--") >= 0) {
            return 0x008000; // Green for comments
        } else if (trimmed.indexOf("<") >= 0 && trimmed.indexOf(">") >= 0) {
            return 0x0000FF; // Blue for elements
        } else if (trimmed.indexOf("=") >= 0 && trimmed.indexOf('"') >= 0) {
            return 0xFF0000; // Red for attributes
        } else {
            return 0x000000; // Black for text
        }
    }

    /**
     * Scroll the text area
     */
    private function scroll(delta:Float):Void {
        scrollY += delta;
        scrollY = Math.max(0, Math.min(scrollY, maxScrollY));
        updateTextPositions();
    }

    /**
     * Update text positions based on scroll
     */
    private function updateTextPositions():Void {
        for (i in 0...textLines.length) {
            var textObject = textLines[i];
            textObject.y = 5 + (i * lineHeight) - scrollY;

            // Hide lines that are outside the visible area
            textObject.visible = (textObject.y >= -lineHeight && textObject.y <= _height);
        }
    }

    /**
     * Set the size of the text area
     */
    public function setSize(width:Float, height:Float):Void {
        _width = width;
        _height = height;

        background.clear();
        background.beginFill(0xFFFFFF);
        background.drawRect(0, 0, _width, _height);
        background.endFill();

        if (interactive != null) {
            interactive.width = _width;
            interactive.height = _height;
        }

        // Update text wrapping
        for (textObject in textLines) {
            textObject.maxWidth = Std.int(_width - 10);
        }

        updateTextPositions();
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        // Handle any animations or updates here
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        for (line in textLines) {
            line.remove();
        }
        textLines = null;
        remove();
    }
}
