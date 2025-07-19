package gmx.builder;

import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import h2d.Bitmap;
import h2d.Tile;
import hxd.Event;
import hxd.Key;
import gmx.data.*;
import gmx.ui.PopUpManager;
import gmx.services.ControlChannel;

/**
 * GMXBuilder - Main builder component for the GMX application
 * Converted from ActionScript to Haxe using Heaps.io framework
 * Manages the visual component building and editing interface
 */
class GMXBuilder extends Object {

    // Layout containers
    private var mainContainer:Flow;
    private var toolboxContainer:Flow;
    private var workspaceContainer:Flow;
    private var statusContainer:Flow;

    // Components
    private var componentToolBox:ComponentToolBox;
    private var attributeEditToolBox:AttributeEditToolBox;
    private var fieldBuilder:FieldBuilder;
    private var xmlDisplay:XMLDisplay;

    // Application references
    private var popUpManager:PopUpManager;
    private var controlChannel:ControlChannel;

    // Current data state
    private var currentRecord:RecordVO;
    private var currentCollection:CollectionVO;
    private var fieldList:Array<FieldVO>;
    private var selectedComponents:Array<Object>;

    // Visual properties
    private var _width:Float = 800;
    private var _height:Float = 600;
    private var backgroundColor:Int = 0xF0F0F0;

    // Event handlers
    private var onComponentSelected:Object->Void;
    private var onFieldChanged:FieldVO->Void;

    public function new(parent:Object) {
        super(parent);

        fieldList = new Array<FieldVO>();
        selectedComponents = new Array<Object>();

        initialize();
    }

    /**
     * Initialize the builder interface
     */
    private function initialize():Void {
        // Create main container with vertical layout
        mainContainer = new Flow(this);
        mainContainer.layout = Vertical;
        mainContainer.horizontalSpacing = 0;
        mainContainer.verticalSpacing = 5;
        mainContainer.padding = 5;

        // Create background
        var background = new Graphics(this);
        background.beginFill(backgroundColor);
        background.drawRect(0, 0, _width, _height);
        background.endFill();

        // Initialize UI components
        createToolbox();
        createWorkspace();
        createStatusBar();

        // Set up event handlers
        setupEventHandlers();

        trace("GMXBuilder initialized");
    }

    /**
     * Create the component toolbox
     */
    private function createToolbox():Void {
        toolboxContainer = new Flow(mainContainer);
        toolboxContainer.layout = Horizontal;
        toolboxContainer.horizontalSpacing = 10;
        toolboxContainer.maxWidth = Std.int(_width - 10);
        toolboxContainer.minHeight = 120;

        // Component toolbox for UI elements
        componentToolBox = new ComponentToolBox(toolboxContainer);
        componentToolBox.onComponentSelected = function(componentType:String) {
            handleComponentSelection(componentType);
        };

        // Attribute edit toolbox
        attributeEditToolBox = new AttributeEditToolBox(toolboxContainer);
        attributeEditToolBox.onAttributeChanged = function(attribute:AttributeVO) {
            handleAttributeChange(attribute);
        };
    }

    /**
     * Create the main workspace area
     */
    private function createWorkspace():Void {
        workspaceContainer = new Flow(mainContainer);
        workspaceContainer.layout = Horizontal;
        workspaceContainer.horizontalSpacing = 10;
        workspaceContainer.maxWidth = Std.int(_width - 10);
        workspaceContainer.minHeight = 400;

        // Create workspace background
        var workspaceBg = new Graphics(workspaceContainer);
        workspaceBg.beginFill(0xFFFFFF);
        workspaceBg.lineStyle(1, 0xCCCCCC);
        workspaceBg.drawRect(0, 0, 500, 400);
        workspaceBg.endFill();

        // Field builder for form elements
        fieldBuilder = new FieldBuilder(workspaceContainer);
        fieldBuilder.onFieldCreated = function(field:FieldVO) {
            addField(field);
        };

        // XML display panel
        xmlDisplay = new XMLDisplay(workspaceContainer);
        xmlDisplay.setSize(250, 400);
    }

    /**
     * Create the status bar
     */
    private function createStatusBar():Void {
        statusContainer = new Flow(mainContainer);
        statusContainer.layout = Horizontal;
        statusContainer.horizontalSpacing = 10;
        statusContainer.maxWidth = Std.int(_width - 10);
        statusContainer.minHeight = 30;

        var statusBg = new Graphics(statusContainer);
        statusBg.beginFill(0xE0E0E0);
        statusBg.drawRect(0, 0, _width - 10, 25);
        statusBg.endFill();

        var statusText = new Text(hxd.res.DefaultFont.get(), statusContainer);
        statusText.text = "Ready";
        statusText.textColor = 0x000000;
        statusText.y = 5;
        statusText.x = 10;
    }

    /**
     * Set up event handlers
     */
    private function setupEventHandlers():Void {
        // Add keyboard shortcuts
        var interactive = new Interactive(_width, _height, this);
        interactive.onKeyDown = function(event:Event) {
            handleKeyDown(event);
        };

        // Mouse interaction for component selection
        interactive.onClick = function(event:Event) {
            handleWorkspaceClick(event);
        };
    }

    /**
     * Handle keyboard shortcuts
     */
    private function handleKeyDown(event:Event):Void {
        switch (event.keyCode) {
            case Key.DELETE:
                deleteSelectedComponents();
            case Key.CTRL if (Key.isDown(Key.S)):
                saveCurrentWork();
            case Key.CTRL if (Key.isDown(Key.O)):
                openExistingWork();
            case Key.CTRL if (Key.isDown(Key.N)):
                createNewRecord();
            case Key.F5:
                refreshDisplay();
        }
    }

    /**
     * Handle workspace clicks for component selection
     */
    private function handleWorkspaceClick(event:Event):Void {
        // Determine what was clicked
        var clickedObject = getObjectUnderPoint(event.relX, event.relY);

        if (clickedObject != null) {
            selectComponent(clickedObject);
        } else {
            clearSelection();
        }
    }

    /**
     * Handle component selection from toolbox
     */
    private function handleComponentSelection(componentType:String):Void {
        trace('Component selected: $componentType');

        switch (componentType) {
            case "TextField":
                createTextField();
            case "Button":
                createButton();
            case "Label":
                createLabel();
            case "ComboBox":
                createComboBox();
            case "CheckBox":
                createCheckBox();
            case "RadioButton":
                createRadioButton();
            default:
                trace('Unknown component type: $componentType');
        }
    }

    /**
     * Handle attribute changes
     */
    private function handleAttributeChange(attribute:AttributeVO):Void {
        trace('Attribute changed: ${attribute.toString()}');

        // Update current record if exists
        if (currentRecord != null) {
            // Find and update corresponding field
            var field = currentRecord.getFieldById(attribute.fid);
            if (field != null) {
                // Update field properties based on attribute
                updateFieldFromAttribute(field, attribute);
                refreshXMLDisplay();
            }
        }
    }

    /**
     * Create a text field component
     */
    private function createTextField():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "";

        addField(field);

        // Create visual representation
        var textField = fieldBuilder.createTextField(field);
        if (textField != null) {
            selectComponent(textField);
        }
    }

    /**
     * Create a button component
     */
    private function createButton():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "Button";

        addField(field);

        var button = fieldBuilder.createButton(field);
        if (button != null) {
            selectComponent(button);
        }
    }

    /**
     * Create a label component
     */
    private function createLabel():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "Label";

        addField(field);

        var label = fieldBuilder.createLabel(field);
        if (label != null) {
            selectComponent(label);
        }
    }

    /**
     * Create a combo box component
     */
    private function createComboBox():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "Option1,Option2,Option3";

        addField(field);

        var comboBox = fieldBuilder.createComboBox(field);
        if (comboBox != null) {
            selectComponent(comboBox);
        }
    }

    /**
     * Create a checkbox component
     */
    private function createCheckBox():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "false";

        addField(field);

        var checkBox = fieldBuilder.createCheckBox(field);
        if (checkBox != null) {
            selectComponent(checkBox);
        }
    }

    /**
     * Create a radio button component
     */
    private function createRadioButton():Void {
        var field = new FieldVO();
        field.fid = generateFieldId();
        field.value = "false";

        addField(field);

        var radioButton = fieldBuilder.createRadioButton(field);
        if (radioButton != null) {
            selectComponent(radioButton);
        }
    }

    /**
     * Add a field to the current record
     */
    private function addField(field:FieldVO):Void {
        if (currentRecord == null) {
            currentRecord = new RecordVO();
            currentRecord.ruid = generateRecordId();
            currentRecord.layout = "default";
        }

        currentRecord.addField(field);
        fieldList.push(field);

        refreshXMLDisplay();

        if (onFieldChanged != null) {
            onFieldChanged(field);
        }
    }

    /**
     * Select a component
     */
    private function selectComponent(component:Object):Void {
        clearSelection();
        selectedComponents.push(component);

        // Highlight selected component
        highlightComponent(component, true);

        // Update attribute editor
        if (attributeEditToolBox != null) {
            var field = getFieldForComponent(component);
            if (field != null) {
                attributeEditToolBox.setCurrentField(field);
            }
        }

        if (onComponentSelected != null) {
            onComponentSelected(component);
        }
    }

    /**
     * Clear component selection
     */
    private function clearSelection():Void {
        for (component in selectedComponents) {
            highlightComponent(component, false);
        }
        selectedComponents = new Array<Object>();

        if (attributeEditToolBox != null) {
            attributeEditToolBox.clearSelection();
        }
    }

    /**
     * Highlight a component
     */
    private function highlightComponent(component:Object, highlight:Bool):Void {
        // Add visual feedback for selection
        if (highlight) {
            // Draw selection border
            var bounds = component.getBounds();
            var selectionBorder = new Graphics(component);
            selectionBorder.lineStyle(2, 0xFF0000);
            selectionBorder.drawRect(-2, -2, bounds.width + 4, bounds.height + 4);
            selectionBorder.name = "selectionBorder";
        } else {
            // Remove selection border
            var border = component.getChildByName("selectionBorder");
            if (border != null) {
                border.remove();
            }
        }
    }

    /**
     * Delete selected components
     */
    private function deleteSelectedComponents():Void {
        for (component in selectedComponents) {
            var field = getFieldForComponent(component);
            if (field != null) {
                removeField(field);
            }
            component.remove();
        }

        clearSelection();
        refreshXMLDisplay();
    }

    /**
     * Remove a field from the current record
     */
    private function removeField(field:FieldVO):Void {
        if (currentRecord != null) {
            currentRecord.removeFieldById(field.fid);
        }

        var index = fieldList.indexOf(field);
        if (index >= 0) {
            fieldList.splice(index, 1);
        }
    }

    /**
     * Get field associated with a component
     */
    private function getFieldForComponent(component:Object):FieldVO {
        // Implementation would depend on how components are linked to fields
        // This is a placeholder
        return null;
    }

    /**
     * Update field from attribute
     */
    private function updateFieldFromAttribute(field:FieldVO, attribute:AttributeVO):Void {
        // Update field properties based on attribute settings
        // This would include validation, formatting, permissions, etc.
    }

    /**
     * Refresh the XML display
     */
    private function refreshXMLDisplay():Void {
        if (xmlDisplay != null && currentRecord != null) {
            var xml = currentRecord.createXML();
            xmlDisplay.setXML(xml);
        }
    }

    /**
     * Generate unique field ID
     */
    private function generateFieldId():String {
        return "field_" + Std.string(Date.now().getTime());
    }

    /**
     * Generate unique record ID
     */
    private function generateRecordId():String {
        return "record_" + Std.string(Date.now().getTime());
    }

    /**
     * Save current work
     */
    private function saveCurrentWork():Void {
        if (currentRecord != null) {
            var xml = currentRecord.createXML();
            // Implementation for saving to file or sending to server
            trace("Saving work: " + xml.toString());
        }
    }

    /**
     * Open existing work
     */
    private function openExistingWork():Void {
        // Implementation for loading from file or server
        trace("Opening existing work");
    }

    /**
     * Create new record
     */
    private function createNewRecord():Void {
        currentRecord = new RecordVO();
        currentRecord.ruid = generateRecordId();
        currentRecord.layout = "default";

        fieldList = new Array<FieldVO>();
        clearSelection();

        if (fieldBuilder != null) {
            fieldBuilder.clear();
        }

        refreshXMLDisplay();
        trace("Created new record");
    }

    /**
     * Refresh display
     */
    private function refreshDisplay():Void {
        refreshXMLDisplay();
        trace("Display refreshed");
    }

    /**
     * Get object under point
     */
    private function getObjectUnderPoint(x:Float, y:Float):Object {
        // Implementation for hit testing
        return null;
    }

    /**
     * Resize the builder
     */
    public function resize(width:Float, height:Float):Void {
        _width = width;
        _height = height;

        // Update container sizes
        if (mainContainer != null) {
            mainContainer.maxWidth = Std.int(_width - 10);
        }

        if (toolboxContainer != null) {
            toolboxContainer.maxWidth = Std.int(_width - 10);
        }

        if (workspaceContainer != null) {
            workspaceContainer.maxWidth = Std.int(_width - 10);
        }

        if (statusContainer != null) {
            statusContainer.maxWidth = Std.int(_width - 10);
        }
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        // Update child components
        if (fieldBuilder != null) {
            fieldBuilder.update(dt);
        }

        if (xmlDisplay != null) {
            xmlDisplay.update(dt);
        }
    }

    /**
     * Set popup manager reference
     */
    public function setPopUpManager(popUpManager:PopUpManager):Void {
        this.popUpManager = popUpManager;
    }

    /**
     * Set control channel reference
     */
    public function setControlChannel(controlChannel:ControlChannel):Void {
        this.controlChannel = controlChannel;
    }

    /**
     * Get current record
     */
    public function getCurrentRecord():RecordVO {
        return currentRecord;
    }

    /**
     * Set current record
     */
    public function setCurrentRecord(record:RecordVO):Void {
        currentRecord = record;

        if (record != null) {
            fieldList = record.fieldList != null ? record.fieldList.copy() : new Array<FieldVO>();
        } else {
            fieldList = new Array<FieldVO>();
        }

        refreshXMLDisplay();
    }

    /**
     * Get current collection
     */
    public function getCurrentCollection():CollectionVO {
        return currentCollection;
    }

    /**
     * Set current collection
     */
    public function setCurrentCollection(collection:CollectionVO):Void {
        currentCollection = collection;
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        clearSelection();

        if (componentToolBox != null) {
            componentToolBox.dispose();
        }

        if (attributeEditToolBox != null) {
            attributeEditToolBox.dispose();
        }

        if (fieldBuilder != null) {
            fieldBuilder.dispose();
        }

        if (xmlDisplay != null) {
            xmlDisplay.dispose();
        }

        remove();
    }
}
