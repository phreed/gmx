package compat;

import hxd.App;
import hxd.Window;
import h2d.Scene;
import h2d.Text;
import h2d.Graphics;
import h2d.Object;

/**
 * Simplified Main class that avoids problematic Heaps.io APIs
 * Compatible with Haxe 5.0.0-preview.1 by avoiding Flow and other breaking APIs
 */
class SimpleMain extends App {

    public static var instance:SimpleMain;
    private var mainContainer:Object;
    private var background:Graphics;
    private var titleText:Text;
    private var initialized:Bool = false;

    override function init() {
        instance = this;

        // Initialize Heaps.io engine
        engine.backgroundColor = 0xFFFFFF; // White background

        // Set up window properties
        Window.getInstance().title = "GMX Application (Compatibility Mode)";

        // Create main container (simple Object instead of Flow)
        mainContainer = new Object(s2d);

        // Create background
        background = new Graphics(mainContainer);
        background.beginFill(0xFFFFFF);
        background.drawRect(0, 0, 800, 600);
        background.endFill();

        // Create title text
        titleText = new Text(hxd.res.DefaultFont.get(), mainContainer);
        titleText.text = "GMX Application - Compatibility Mode";
        titleText.textColor = 0x000000;
        titleText.x = 20;
        titleText.y = 20;

        // Add some basic UI elements
        createBasicUI();

        // Set initial size
        onResize();

        initialized = true;

        trace("GMX Application (Compatibility Mode) initialized successfully");
    }

    private function createBasicUI():Void {
        // Create a simple status text
        var statusText = new Text(hxd.res.DefaultFont.get(), mainContainer);
        statusText.text = "Status: Running in compatibility mode with Haxe 5.0.0-preview.1";
        statusText.textColor = 0x666666;
        statusText.x = 20;
        statusText.y = 50;

        // Create a simple instruction text
        var instructionText = new Text(hxd.res.DefaultFont.get(), mainContainer);
        instructionText.text = "This is a simplified version that avoids problematic Heaps.io APIs.";
        instructionText.textColor = 0x333333;
        instructionText.x = 20;
        instructionText.y = 80;

        // Create version info
        var versionText = new Text(hxd.res.DefaultFont.get(), mainContainer);
        versionText.text = "Haxe Version: 5.0.0-preview.1";
        versionText.textColor = 0x0066CC;
        versionText.x = 20;
        versionText.y = 110;

        // Add a simple colored rectangle as a visual element
        var colorRect = new Graphics(mainContainer);
        colorRect.beginFill(0x4CAF50);
        colorRect.drawRect(20, 140, 200, 50);
        colorRect.endFill();

        var rectText = new Text(hxd.res.DefaultFont.get(), mainContainer);
        rectText.text = "Compatibility Layer Active";
        rectText.textColor = 0xFFFFFF;
        rectText.x = 30;
        rectText.y = 155;
    }

    override function onResize() {
        if (!initialized) return;

        var windowWidth = Window.getInstance().width;
        var windowHeight = Window.getInstance().height;

        // Ensure minimum size
        if (windowWidth < 800) windowWidth = 800;
        if (windowHeight < 600) windowHeight = 600;

        // Resize background
        if (background != null) {
            background.clear();
            background.beginFill(0xFFFFFF);
            background.drawRect(0, 0, windowWidth, windowHeight);
            background.endFill();
        }
    }

    override function update(dt:Float) {
        // Simple update loop without complex dependencies
        // Can add basic game logic here
    }

    /**
     * Entry point
     */
    static function main() {
        // Initialize and start the application
        new SimpleMain();
    }
}
