package gmx.builder;

import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import hxd.Event;

/**
 * ComponentToolBox - UI component selection toolbox
 * Provides buttons for different UI components that can be added to forms
 */
class ComponentToolBox extends Object {

    private var container:Flow;
    private var components:Array<ComponentButton>;

    public var onComponentSelected:String->Void;

    public function new(parent:Object) {
        super(parent);
        components = new Array<ComponentButton>();
        initialize();
    }

    private function initialize():Void {
        container = new Flow(this);
        container.layout = Vertical;
        container.verticalSpacing = 5;
        container.padding = 5;

        // Create background
        var bg = new Graphics(this);
        bg.beginFill(0xE8E8E8);
        bg.lineStyle(1, 0xCCCCCC);
        bg.drawRect(0, 0, 120, 400);
        bg.endFill();

        // Add title
        var title = new Text(hxd.res.DefaultFont.get(), container);
        title.text = "Components";
        title.textColor = 0x000000;

        // Add component buttons
        addComponentButton("TextField", "Text Field");
        addComponentButton("Button", "Button");
        addComponentButton("Label", "Label");
        addComponentButton("ComboBox", "Combo Box");
        addComponentButton("CheckBox", "Check Box");
        addComponentButton("RadioButton", "Radio Button");
    }

    private function addComponentButton(type:String, label:String):Void {
        var button = new ComponentButton(container, type, label);
        button.onClick = function() {
            if (onComponentSelected != null) {
                onComponentSelected(type);
            }
        };
        components.push(button);
    }

    public function dispose():Void {
        for (component in components) {
            component.dispose();
        }
        components = null;
        remove();
    }
}

class ComponentButton extends Object {

    private var background:Graphics;
    private var text:Text;
    private var interactive:Interactive;
    private var componentType:String;

    public var onClick:Void->Void;

    public function new(parent:Object, type:String, label:String) {
        super(parent);
        this.componentType = type;

        // Create button background
        background = new Graphics(this);
        background.beginFill(0xF0F0F0);
        background.lineStyle(1, 0x808080);
        background.drawRect(0, 0, 100, 25);
        background.endFill();

        // Create text
        text = new Text(hxd.res.DefaultFont.get(), this);
        text.text = label;
        text.textColor = 0x000000;
        text.x = 5;
        text.y = 5;

        // Create interactive area
        interactive = new Interactive(100, 25, this);
        interactive.onClick = function(event:Event) {
            if (onClick != null) {
                onClick();
            }
        };

        interactive.onOver = function(event:Event) {
            background.clear();
            background.beginFill(0xE0E0FF);
            background.lineStyle(1, 0x808080);
            background.drawRect(0, 0, 100, 25);
            background.endFill();
        };

        interactive.onOut = function(event:Event) {
            background.clear();
            background.beginFill(0xF0F0F0);
            background.lineStyle(1, 0x808080);
            background.drawRect(0, 0, 100, 25);
            background.endFill();
        };
    }

    public function dispose():Void {
        remove();
    }
}
