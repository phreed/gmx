package gmx.core;

import h2d.Scene;
import h2d.Object;
import h2d.Flow;
import h2d.Graphics;
import h2d.Text;
import h2d.Interactive;
import h2d.col.Point;
import hxd.Event;
import hxd.Window;
import gmx.ui.PopUpManager;
import gmx.services.ControlChannel;
import gmx.builder.GMXBuilder;

/**
 * Core GMX Application class - converted from GMXMain.as
 * Uses Heaps.io instead of Flex/Flash for cross-platform compatibility
 * Following the Northgard case study approach with HashLink deployment
 */
class GMXApplication extends Object {

    // Static references (equivalent to Flash static vars)
    public static var instance:GMXApplication;
    public static var popUps:PopUpManager;

    // Application properties
    private var _scale:Float = 1.0;
    private var _width:Float = 800;
    private var _height:Float = 600;

    // Core components
    private var scene:Scene;
    private var controlChannel:ControlChannel;
    private var gmxBuilder:GMXBuilder;
    private var background:Graphics;
    private var mainContainer:Flow;

    // Configuration constants
    public static inline var DEFAULT_CONTROL_CHANNEL_PORT:Int = 12141;
    public static inline var DEFAULT_CONTROL_CHANNEL_HOST:String = "localhost";

    // Debug flags
    public static var testing:Bool = true;
    public static var debugSend:Bool = false;

    public function new(scene:Scene) {
        super(scene);

        this.scene = scene;
        instance = this;

        initialize();
    }

    /**
     * Initialize the application components
     */
    private function initialize():Void {
        // Create background
        background = new Graphics(this);
        background.beginFill(0xFFFFFF); // White background
        background.drawRect(0, 0, _width, _height);
        background.endFill();

        // Create main container with flow layout (similar to Flex VBox/HBox)
        mainContainer = new Flow(this);
        mainContainer.layout = Vertical;
        mainContainer.horizontalSpacing = 0;
        mainContainer.verticalSpacing = 0;
        mainContainer.padding = 0;

        // Initialize popup manager
        popUps = new PopUpManager(scene);

        // Initialize control channel for network communication
        controlChannel = new ControlChannel();

        // Initialize the GMX builder component
        gmxBuilder = new GMXBuilder(mainContainer);

        // Set up event handlers
        setupEventHandlers();

        // Apply initial styling (equivalent to Flash/Flex styles)
        applyStyles();

        trace("GMXApplication initialized");
    }

    /**
     * Set up event handlers for user interaction
     */
    private function setupEventHandlers():Void {
        // Add interactive area for the whole application
        var interactive = new Interactive(_width, _height, this);
        // onResize property not available in this Heaps version
        // interactive.onResize = onInteractiveResize;

        // Handle window resize events
        Window.getInstance().addEventTarget(onWindowEvent);
    }

    /**
     * Handle window events
     */
    private function onWindowEvent(event:Event):Void {
        // Simplified event handling for compatibility
        var eventStr = Std.string(event.kind);
        if (eventStr == "EResize") {
            var window = Window.getInstance();
            resize(window.width, window.height);
        }
        // Handle other events as needed
    }

    /**
     * Handle interactive area resize
     */
    private function onInteractiveResize():Void {
        // Update interactive area size when application resizes
        if (getChildAt(getChildIndex(background) + 1) != null) {
            var interactive = cast(getChildAt(getChildIndex(background) + 1), Interactive);
            if (interactive != null) {
                interactive.width = _width;
                interactive.height = _height;
            }
        }
    }

    /**
     * Apply visual styles (equivalent to Flex CSS styles)
     */
    private function applyStyles():Void {
        // Set container properties to match original Flash styling
        mainContainer.paddingLeft = 0;
        mainContainer.paddingRight = 0;
        mainContainer.paddingTop = 0;
        mainContainer.paddingBottom = 0;

        // Enable scrolling equivalent
        mainContainer.enableInteractive = true;
        mainContainer.multiline = true;
    }

    /**
     * Resize the application
     */
    public function resize(width:Float, height:Float):Void {
        _width = width / _scale;
        _height = height / _scale;

        // Resize background
        background.clear();
        background.beginFill(0xFFFFFF);
        background.drawRect(0, 0, _width, _height);
        background.endFill();

        // Resize main container
        mainContainer.maxWidth = Std.int(_width);
        mainContainer.maxHeight = Std.int(_height);

        // Update GMX builder if it exists
        if (gmxBuilder != null) {
            gmxBuilder.resize(_width, _height);
        }

        // Update interactive area
        onInteractiveResize();
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        // Update control channel
        if (controlChannel != null) {
            controlChannel.update(dt);
        }

        // Update GMX builder
        if (gmxBuilder != null) {
            gmxBuilder.update(dt);
        }

        // Update popup manager
        if (popUps != null) {
            popUps.update(dt);
        }
    }

    /**
     * Connect to control channel
     */
    public function connectControlChannel():Void {
        if (controlChannel != null) {
            controlChannel.connect();
        }
    }

    /**
     * Get current scale
     */
    public function getScale():Float {
        return _scale;
    }

    /**
     * Set scale and update display
     */
    public function setAppScale(scale:Float):Void {
        if (scale <= 0) scale = 1.0;

        _scale = scale;
        this.scaleX = scale;
        this.scaleY = scale;

        // Trigger resize to recalculate dimensions
        var window = Window.getInstance();
        resize(window.width, window.height);
    }

    /**
     * Get application width
     */
    public function getWidth():Float {
        return _width;
    }

    /**
     * Get application height
     */
    public function getHeight():Float {
        return _height;
    }

    /**
     * Add a component to the main container
     */
    public function addComponent(component:Object):Void {
        mainContainer.addChild(component);
    }

    /**
     * Remove a component from the main container
     */
    public function removeComponent(component:Object):Void {
        mainContainer.removeChild(component);
    }

    /**
     * Get reference to the main container
     */
    public function getMainContainer():Flow {
        return mainContainer;
    }

    /**
     * Get reference to the popup manager
     */
    public function getPopUpManager():PopUpManager {
        return popUps;
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        if (controlChannel != null) {
            controlChannel.disconnect();
        }

        if (popUps != null) {
            popUps.dispose();
        }

        // Remove from scene
        remove();
    }
}
