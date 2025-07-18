package gmx.builder;

import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import h2d.TextInput;
import hxd.Event;
import gmx.data.FieldVO;
import gmx.data.AttributeVO;

/**
 * AttributeEditToolBox - Property editor for selected components
 * Allows editing of field properties, attributes, and styling
 */
class AttributeEditToolBox extends Object {

    private var container:Flow;
    private var currentField:FieldVO;
    private var currentAttribute:AttributeVO;

    // UI Elements
    private var titleText:Text;
    private var fidInput:TextInput;
    private var valueInput:TextInput;
    private var sendCheckbox:Interactive;
    private var sendCheckboxGraphics:Graphics;
    private var sendChecked:Bool = false;
    private var actionStateInput:TextInput;
    private var permissionsInput:TextInput;

    // Event callbacks
    public var onAttributeChanged:AttributeVO->Void;
    public var onFieldChanged:FieldVO->Void;

    public function new(parent:Object) {
        super(parent);
        initialize();
    }

    private function initialize():Void {
        container = new Flow(this);
        container.layout = Vertical;
        container.verticalSpacing = 8;
        container.padding = 5;

        // Create background
        var bg = new Graphics(this);
        bg.beginFill(0xF8F8F8);
        bg.lineStyle(1, 0xCCCCCC);
        bg.drawRect(0, 0, 200, 400);
        bg.endFill();

        // Add title
        titleText = new Text(hxd.res.DefaultFont.get(), container);
        titleText.text = "Properties";
        titleText.textColor = 0x000000;

        createPropertyEditors();
    }

    private function createPropertyEditors():Void {
        // Field ID editor
        addLabel("Field ID:");
        fidInput = createTextInput("", function(value:String) {
            if (currentField != null) {
                currentField.fid = value;
                notifyFieldChanged();
            }
        });

        // Value editor
        addLabel("Value:");
        valueInput = createTextInput("", function(value:String) {
            if (currentField != null) {
                currentField.value = value;
                notifyFieldChanged();
            }
        });

        // Send checkbox
        addLabel("Send to Server:");
        createSendCheckbox();

        // Action State editor
        addLabel("Action State:");
        actionStateInput = createTextInput("", function(value:String) {
            if (currentAttribute != null) {
                currentAttribute.actionState = value;
                notifyAttributeChanged();
            }
        });

        // Permissions editor
        addLabel("Permissions:");
        permissionsInput = createTextInput("", function(value:String) {
            if (currentAttribute != null) {
                currentAttribute.permissions = value;
                notifyAttributeChanged();
            }
        });
    }

    private function addLabel(text:String):Void {
        var label = new Text(hxd.res.DefaultFont.get(), container);
        label.text = text;
        label.textColor = 0x333333;
        label.y += 5;
    }

    private function createTextInput(defaultValue:String, onChange:String->Void):TextInput {
        var inputBg = new Graphics(container);
        inputBg.beginFill(0xFFFFFF);
        inputBg.lineStyle(1, 0x999999);
        inputBg.drawRect(0, 0, 180, 20);
        inputBg.endFill();

        var input = new TextInput(hxd.res.DefaultFont.get(), inputBg);
        input.text = defaultValue;
        input.textColor = 0x000000;
        input.backgroundColor = 0xFFFFFF;
        input.borderColor = 0x999999;
        input.borderHeight = 1;
        input.borderWidth = 1;

        // Set up change handler
        input.onChange = function() {
            if (onChange != null) {
                onChange(input.text);
            }
        };

        return input;
    }

    private function createSendCheckbox():Void {
        var checkboxContainer = new Flow(container);
        checkboxContainer.layout = Horizontal;
        checkboxContainer.horizontalSpacing = 5;

        // Checkbox graphics
        sendCheckboxGraphics = new Graphics(checkboxContainer);
        updateCheckboxGraphics();

        // Checkbox label
        var checkboxLabel = new Text(hxd.res.DefaultFont.get(), checkboxContainer);
        checkboxLabel.text = "Enabled";
        checkboxLabel.textColor = 0x000000;
        checkboxLabel.y = 2;

        // Interactive area
        var interactive = new Interactive(20, 16, sendCheckboxGraphics);
        interactive.onClick = function(event:Event) {
            sendChecked = !sendChecked;
            updateCheckboxGraphics();

            if (currentAttribute != null) {
                currentAttribute.send = sendChecked ? "true" : "false";
                notifyAttributeChanged();
            }
        };
    }

    private function updateCheckboxGraphics():Void {
        sendCheckboxGraphics.clear();
        sendCheckboxGraphics.beginFill(0xFFFFFF);
        sendCheckboxGraphics.lineStyle(1, 0x666666);
        sendCheckboxGraphics.drawRect(0, 0, 16, 16);
        sendCheckboxGraphics.endFill();

        if (sendChecked) {
            sendCheckboxGraphics.lineStyle(2, 0x006600);
            sendCheckboxGraphics.moveTo(3, 8);
            sendCheckboxGraphics.lineTo(7, 12);
            sendCheckboxGraphics.lineTo(13, 4);
        }
    }

    /**
     * Set the current field being edited
     */
    public function setCurrentField(field:FieldVO):Void {
        currentField = field;

        if (field != null) {
            fidInput.text = field.fid != null ? field.fid : "";
            valueInput.text = field.value != null ? field.value : "";

            // Create or update associated attribute
            if (currentAttribute == null) {
                currentAttribute = new AttributeVO();
                currentAttribute.fid = field.fid;
                currentAttribute.send = "false";
                currentAttribute.actionState = "";
                currentAttribute.permissions = "";
            }

            sendChecked = currentAttribute.send == "true";
            updateCheckboxGraphics();

            actionStateInput.text = currentAttribute.actionState != null ? currentAttribute.actionState : "";
            permissionsInput.text = currentAttribute.permissions != null ? currentAttribute.permissions : "";
        } else {
            clearInputs();
        }
    }

    /**
     * Set the current attribute being edited
     */
    public function setCurrentAttribute(attribute:AttributeVO):Void {
        currentAttribute = attribute;

        if (attribute != null) {
            sendChecked = attribute.send == "true";
            updateCheckboxGraphics();

            actionStateInput.text = attribute.actionState != null ? attribute.actionState : "";
            permissionsInput.text = attribute.permissions != null ? attribute.permissions : "";
        }
    }

    /**
     * Clear the selection and reset inputs
     */
    public function clearSelection():Void {
        currentField = null;
        currentAttribute = null;
        clearInputs();
    }

    private function clearInputs():Void {
        fidInput.text = "";
        valueInput.text = "";
        actionStateInput.text = "";
        permissionsInput.text = "";
        sendChecked = false;
        updateCheckboxGraphics();
    }

    private function notifyFieldChanged():Void {
        if (onFieldChanged != null && currentField != null) {
            onFieldChanged(currentField);
        }
    }

    private function notifyAttributeChanged():Void {
        if (onAttributeChanged != null && currentAttribute != null) {
            onAttributeChanged(currentAttribute);
        }
    }

    /**
     * Get the current field
     */
    public function getCurrentField():FieldVO {
        return currentField;
    }

    /**
     * Get the current attribute
     */
    public function getCurrentAttribute():AttributeVO {
        return currentAttribute;
    }

    /**
     * Validate current input values
     */
    public function validateInputs():Bool {
        if (currentField != null) {
            // Basic validation - field ID should not be empty
            if (currentField.fid == null || currentField.fid.length == 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * Apply changes to the current field/attribute
     */
    public function applyChanges():Void {
        if (validateInputs()) {
            notifyFieldChanged();
            notifyAttributeChanged();
        }
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        currentField = null;
        currentAttribute = null;
        remove();
    }
}
