package;

import hxd.App;
import hxd.Window;
import h2d.Scene;
import h2d.Text;
import h2d.Graphics;
import h2d.Object;
import h2d.Flow;
import h2d.Bitmap;
import h2d.Tile;
import hxd.Res;
import gmx.core.GMXApplication;

/**
 * Main entry point for the GMX application
 * Converted from Adobe AIR/Flash to Haxe using Heaps.io framework
 * Following the Northgard case study approach for modern cross-platform deployment
 */
class Main extends App {

    public static var instance:Main;
    private var gmxApp:GMXApplication;
    private var initialized:Bool = false;

    override function init() {
        instance = this;

        // Initialize Heaps.io engine
        engine.backgroundColor = 0xFFFFFF; // White background like original

        // Set up window properties
        Window.getInstance().title = "GMX Application";

        // Initialize resource system
        #if hl
        Res.initEmbed();
        #else
        Res.initLocal();
        #end

        // Create main application instance
        gmxApp = new GMXApplication(s2d);

        // Set initial size (matching original 800x600)
        onResize();

        initialized = true;

        trace("GMX Application initialized successfully");
    }

    override function onResize() {
        if (!initialized) return;

        var windowWidth = Window.getInstance().width;
        var windowHeight = Window.getInstance().height;

        // Ensure minimum size
        if (windowWidth < 800) windowWidth = 800;
        if (windowHeight < 600) windowHeight = 600;

        // Resize the main application
        if (gmxApp != null) {
            gmxApp.resize(windowWidth, windowHeight);
        }
    }

    override function update(dt:Float) {
        if (gmxApp != null) {
            gmxApp.update(dt);
        }
    }

    /**
     * Static method to get the current scale (equivalent to Flash version)
     */
    public static function getScale():Float {
        if (instance != null && instance.gmxApp != null) {
            return instance.gmxApp.getScale();
        }
        return 1.0;
    }

    /**
     * Static method to set the scale (equivalent to Flash version)
     */
    public static function setScale(scale:Float):Void {
        if (instance != null && instance.gmxApp != null) {
            instance.gmxApp.setAppScale(scale);
        }
    }

    /**
     * Entry point
     */
    static function main() {
        // Initialize and start the application
        new Main();
    }
}
