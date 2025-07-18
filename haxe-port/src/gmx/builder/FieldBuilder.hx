package gmx.builder;

import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import h2d.TextInput;
import hxd.Event;
import gmx.data.FieldVO;

/**
 * FieldBuilder - Creates and manages visual form components
 * Converts FieldVO data objects into interactive UI elements
 */
class FieldBuilder extends Object {

    private var container:Flow;
    private var components:Array<FormComponent>;
    private var nextComponentY:Float = 10;
    private var componentSpacing:Float = 30;

    // Event callbacks
    public var onFieldCreated:FieldVO->Void;
    public var onFieldChanged:FieldVO->Void;
    public var onComponentSelected:FormComponent->Void;

    public function new(parent:Object) {
        super(parent);
        components = new Array<FormComponent>();
        initialize();
    }

    private function initialize():Void {
        container = new Flow(this);
        container.layout = Vertical;
        container.verticalSpacing = 5;
        container.padding = 10;

        // Create workspace background
        var bg = new Graphics(this);
        bg.beginFill(0xFFFFFF);
        bg.lineStyle(1, 0xDDDDDD);
        bg.drawRect(0, 0, 480, 380);
        bg.endFill();
    }

    /**
     * Create a text field component
     */
    public function createTextField(field:FieldVO):FormComponent {
        var textField = new TextFieldComponent(container, field);
        addComponent(textField);
        return textField;
    }

    /**
     * Create a button component
     */
    public function createButton(field:FieldVO):FormComponent {
        var button = new ButtonComponent(container, field);
        addComponent(button);
        return button;
    }

    /**
     * Create a label component
     */
    public function createLabel(field:FieldVO):FormComponent {
        var label = new LabelComponent(container, field);
        addComponent(label);
        return label;
    }

    /**
     * Create a combo box component
     */
    public function createComboBox(field:FieldVO):FormComponent {
        var comboBox = new ComboBoxComponent(container, field);
        addComponent(comboBox);
        return comboBox;
    }

    /**
     * Create a checkbox component
     */
    public function createCheckBox(field:FieldVO):FormComponent {
        var checkBox = new CheckBoxComponent(container, field);
        addComponent(checkBox);
        return checkBox;
    }

    /**
     * Create a radio button component
     */
    public function createRadioButton(field:FieldVO):FormComponent {
        var radioButton = new RadioButtonComponent(container, field);
        addComponent(radioButton);
        return radioButton;
    }

    private function addComponent(component:FormComponent):Void {
        components.push(component);
        component.y = nextComponentY;
        nextComponentY += componentSpacing;

        component.onFieldChanged = function(field:FieldVO) {
            if (onFieldChanged != null) {
                onFieldChanged(field);
            }
        };

        component.onSelected = function() {
            if (onComponentSelected != null) {
                onComponentSelected(component);
            }
        };
    }

    /**
     * Clear all components
     */
    public function clear():Void {
        for (component in components) {
            component.dispose();
        }
        components = new Array<FormComponent>();
        nextComponentY = 10;
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        for (component in components) {
            component.update(dt);
        }
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        clear();
        remove();
    }
}

/**
 * Base class for form components
 */
class FormComponent extends Object {

    public var field:FieldVO;
    public var onFieldChanged:FieldVO->Void;
    public var onSelected:Void->Void;

    protected var background:Graphics;
    protected var interactive:Interactive;
    protected var isSelected:Bool = false;

    public function new(parent:Object, field:FieldVO) {
        super(parent);
        this.field = field;
        initialize();
    }

    protected function initialize():Void {
        // Override in subclasses
    }

    protected function createBackground(width:Float, height:Float, color:Int = 0xF0F0F0):Void {
        background = new Graphics(this);
        background.beginFill(color);
        background.lineStyle(1, 0xCCCCCC);
        background.drawRect(0, 0, width, height);
        background.endFill();

        interactive = new Interactive(width, height, this);
        interactive.onClick = function(event:Event) {
            select();
        };
    }

    public function select():Void {
        isSelected = true;
        updateVisualState();
        if (onSelected != null) {
            onSelected();
        }
    }

    public function deselect():Void {
        isSelected = false;
        updateVisualState();
    }

    protected function updateVisualState():Void {
        if (background != null) {
            background.clear();
            var color = isSelected ? 0xE0E0FF : 0xF0F0F0;
            var borderColor = isSelected ? 0x0000FF : 0xCCCCCC;
            background.beginFill(color);
            background.lineStyle(1, borderColor);
            background.drawRect(0, 0, background.getBounds().width, background.getBounds().height);
            background.endFill();
        }
    }

    protected function notifyFieldChanged():Void {
        if (onFieldChanged != null) {
            onFieldChanged(field);
        }
    }

    public function update(dt:Float):Void {
        // Override in subclasses if needed
    }

    public function dispose():Void {
        remove();
    }
}

/**
 * Text field component
 */
class TextFieldComponent extends FormComponent {

    private var textInput:TextInput;
    private var label:Text;

    override protected function initialize():Void {
        createBackground(200, 40);

        // Create label
        label = new Text(hxd.res.DefaultFont.get(), this);
        label.text = field.fid + ":";
        label.textColor = 0x000000;
        label.x = 5;
        label.y = 5;

        // Create text input
        var inputBg = new Graphics(this);
        inputBg.beginFill(0xFFFFFF);
        inputBg.lineStyle(1, 0x999999);
        inputBg.drawRect(80, 8, 110, 20);
        inputBg.endFill();

        textInput = new TextInput(hxd.res.DefaultFont.get(), inputBg);
        textInput.text = field.value != null ? field.value : "";
        textInput.textColor = 0x000000;
        textInput.x = 5;
        textInput.y = 2;

        textInput.onChange = function() {
            field.value = textInput.text;
            notifyFieldChanged();
        };
    }
}

/**
 * Button component
 */
class ButtonComponent extends FormComponent {

    private var buttonText:Text;
    private var buttonBg:Graphics;

    override protected function initialize():Void {
        createBackground(120, 30);

        buttonBg = new Graphics(this);
        buttonBg.beginFill(0xE0E0E0);
        buttonBg.lineStyle(1, 0x808080);
        buttonBg.drawRect(10, 5, 100, 20);
        buttonBg.endFill();

        buttonText = new Text(hxd.res.DefaultFont.get(), buttonBg);
        buttonText.text = field.value != null ? field.value : "Button";
        buttonText.textColor = 0x000000;
        buttonText.x = 30;
        buttonText.y = 3;

        var buttonInteractive = new Interactive(100, 20, buttonBg);
        buttonInteractive.onClick = function(event:Event) {
            trace('Button clicked: ${field.fid}');
        };
    }
}

/**
 * Label component
 */
class LabelComponent extends FormComponent {

    private var labelText:Text;

    override protected function initialize():Void {
        createBackground(150, 25);

        labelText = new Text(hxd.res.DefaultFont.get(), this);
        labelText.text = field.value != null ? field.value : "Label";
        labelText.textColor = 0x000000;
        labelText.x = 5;
        labelText.y = 5;
    }
}

/**
 * Combo box component
 */
class ComboBoxComponent extends FormComponent {

    private var selectedText:Text;
    private var dropdownButton:Graphics;
    private var options:Array<String>;

    override protected function initialize():Void {
        createBackground(150, 25);

        // Parse options from field value
        if (field.value != null && field.value.length > 0) {
            options = field.value.split(",");
        } else {
            options = ["Option 1", "Option 2", "Option 3"];
        }

        // Create dropdown background
        var dropdownBg = new Graphics(this);
        dropdownBg.beginFill(0xFFFFFF);
        dropdownBg.lineStyle(1, 0x999999);
        dropdownBg.drawRect(5, 5, 120, 15);
        dropdownBg.endFill();

        selectedText = new Text(hxd.res.DefaultFont.get(), dropdownBg);
        selectedText.text = options.length > 0 ? options[0] : "";
        selectedText.textColor = 0x000000;
        selectedText.x = 3;
        selectedText.y = 1;

        // Create dropdown arrow
        dropdownButton = new Graphics(this);
        dropdownButton.beginFill(0xE0E0E0);
        dropdownButton.lineStyle(1, 0x999999);
        dropdownButton.drawRect(125, 5, 15, 15);
        dropdownButton.endFill();

        var dropdownInteractive = new Interactive(15, 15, dropdownButton);
        dropdownInteractive.onClick = function(event:Event) {
            // TODO: Show dropdown menu
            trace('Dropdown clicked');
        };
    }
}

/**
 * Checkbox component
 */
class CheckBoxComponent extends FormComponent {

    private var checkboxGraphics:Graphics;
    private var checkboxLabel:Text;
    private var isChecked:Bool = false;

    override protected function initialize():Void {
        createBackground(120, 25);

        isChecked = field.value == "true";

        checkboxGraphics = new Graphics(this);
        updateCheckboxGraphics();

        checkboxLabel = new Text(hxd.res.DefaultFont.get(), this);
        checkboxLabel.text = field.fid;
        checkboxLabel.textColor = 0x000000;
        checkboxLabel.x = 25;
        checkboxLabel.y = 5;

        var checkboxInteractive = new Interactive(16, 16, checkboxGraphics);
        checkboxInteractive.onClick = function(event:Event) {
            isChecked = !isChecked;
            field.value = isChecked ? "true" : "false";
            updateCheckboxGraphics();
            notifyFieldChanged();
        };
    }

    private function updateCheckboxGraphics():Void {
        checkboxGraphics.clear();
        checkboxGraphics.beginFill(0xFFFFFF);
        checkboxGraphics.lineStyle(1, 0x666666);
        checkboxGraphics.drawRect(5, 5, 16, 16);
        checkboxGraphics.endFill();

        if (isChecked) {
            checkboxGraphics.lineStyle(2, 0x006600);
            checkboxGraphics.moveTo(8, 13);
            checkboxGraphics.lineTo(12, 17);
            checkboxGraphics.lineTo(18, 9);
        }
    }
}

/**
 * Radio button component
 */
class RadioButtonComponent extends FormComponent {

    private var radioGraphics:Graphics;
    private var radioLabel:Text;
    private var isSelected:Bool = false;

    override protected function initialize():Void {
        createBackground(120, 25);

        isSelected = field.value == "true";

        radioGraphics = new Graphics(this);
        updateRadioGraphics();

        radioLabel = new Text(hxd.res.DefaultFont.get(), this);
        radioLabel.text = field.fid;
        radioLabel.textColor = 0x000000;
        radioLabel.x = 25;
        radioLabel.y = 5;

        var radioInteractive = new Interactive(16, 16, radioGraphics);
        radioInteractive.onClick = function(event:Event) {
            isSelected = true;
            field.value = "true";
            updateRadioGraphics();
            notifyFieldChanged();
        };
    }

    private function updateRadioGraphics():Void {
        radioGraphics.clear();
        radioGraphics.beginFill(0xFFFFFF);
        radioGraphics.lineStyle(1, 0x666666);
        radioGraphics.drawCircle(13, 13, 8);
        radioGraphics.endFill();

        if (isSelected) {
            radioGraphics.beginFill(0x006600);
            radioGraphics.drawCircle(13, 13, 4);
            radioGraphics.endFill();
        }
    }
}
