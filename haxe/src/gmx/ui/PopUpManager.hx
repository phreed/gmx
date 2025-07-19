package gmx.ui;

import h2d.Scene;
import h2d.Object;
import h2d.Graphics;
import h2d.Interactive;
import h2d.Text;
import h2d.Flow;
import hxd.Event;

/**
 * PopUpManager - Heaps.io replacement for Flash PopUpManager
 * Manages modal dialogs and popup windows in the GMX application
 */
class PopUpManager extends Object {

    private var scene:Scene;
    private var popups:Array<PopUpWindow>;
    private var modalOverlay:Graphics;
    private var isModalActive:Bool = false;

    public function new(scene:Scene) {
        super(scene);
        this.scene = scene;
        this.popups = new Array<PopUpWindow>();

        // Create modal overlay (initially hidden)
        modalOverlay = new Graphics(this);
        modalOverlay.visible = false;
        modalOverlay.alpha = 0.5;
    }

    /**
     * Show a popup window
     */
    public function addPopUp(popup:PopUpWindow, modal:Bool = false, ?centerOnStage:Bool = true):Void {
        if (popup == null) return;

        // Add to scene
        addChild(popup);
        popups.push(popup);

        // Center the popup if requested
        if (centerOnStage) {
            centerPopUp(popup);
        }

        // Handle modal behavior
        if (modal) {
            showModalOverlay();
            popup.isModal = true;
        }

        // Bring popup to front
        popup.toFront();

        // Set up close handlers
        popup.onClose = function() {
            removePopUp(popup);
        };
    }

    /**
     * Remove a popup window
     */
    public function removePopUp(popup:PopUpWindow):Void {
        if (popup == null) return;

        // Remove from array
        var index = popups.indexOf(popup);
        if (index >= 0) {
            popups.splice(index, 1);
        }

        // Remove from display
        removeChild(popup);

        // Hide modal overlay if no modal popups remain
        if (popup.isModal) {
            var hasModalPopups = false;
            for (p in popups) {
                if (p.isModal) {
                    hasModalPopups = true;
                    break;
                }
            }
            if (!hasModalPopups) {
                hideModalOverlay();
            }
        }

        // Clean up popup
        popup.dispose();
    }

    /**
     * Remove all popups
     */
    public function removeAllPopUps():Void {
        while (popups.length > 0) {
            removePopUp(popups[0]);
        }
    }

    /**
     * Center a popup on the stage
     */
    public function centerPopUp(popup:PopUpWindow):Void {
        if (popup == null || scene == null) return;

        var stageWidth = scene.width;
        var stageHeight = scene.height;

        popup.x = (stageWidth - popup.getWidth()) / 2;
        popup.y = (stageHeight - popup.getHeight()) / 2;

        // Ensure popup is within bounds
        if (popup.x < 0) popup.x = 0;
        if (popup.y < 0) popup.y = 0;
    }

    /**
     * Show modal overlay
     */
    private function showModalOverlay():Void {
        if (isModalActive) return;

        isModalActive = true;
        modalOverlay.visible = true;

        // Resize overlay to cover entire scene
        modalOverlay.clear();
        modalOverlay.beginFill(0x000000, 0.5);
        modalOverlay.drawRect(0, 0, scene.width, scene.height);
        modalOverlay.endFill();

        // Add click handler to prevent interaction with background
        var interactive = new Interactive(scene.width, scene.height, modalOverlay);
        interactive.onClick = function(event:Event) {
            event.cancel = true;
        };
    }

    /**
     * Hide modal overlay
     */
    private function hideModalOverlay():Void {
        isModalActive = false;
        modalOverlay.visible = false;
        modalOverlay.clear();
    }

    /**
     * Get popup by name/id
     */
    public function getPopUp(name:String):PopUpWindow {
        for (popup in popups) {
            if (popup.name == name) {
                return popup;
            }
        }
        return null;
    }

    /**
     * Check if any modal popup is active
     */
    public function isModal():Bool {
        return isModalActive;
    }

    /**
     * Update method called each frame
     */
    public function update(dt:Float):Void {
        // Update all active popups
        for (popup in popups) {
            popup.update(dt);
        }

        // Update modal overlay size if scene size changed
        if (isModalActive) {
            var currentWidth = modalOverlay.getBounds().width;
            var currentHeight = modalOverlay.getBounds().height;

            if (currentWidth != scene.width || currentHeight != scene.height) {
                modalOverlay.clear();
                modalOverlay.beginFill(0x000000, 0.5);
                modalOverlay.drawRect(0, 0, scene.width, scene.height);
                modalOverlay.endFill();
            }
        }
    }

    /**
     * Clean up resources
     */
    public function dispose():Void {
        removeAllPopUps();

        if (modalOverlay != null) {
            modalOverlay.remove();
            modalOverlay = null;
        }

        popups = null;
        remove();
    }

    /**
     * Create a simple alert dialog
     */
    public function createAlert(title:String, message:String, ?onClose:Void->Void):PopUpWindow {
        var alert = new AlertDialog(title, message);
        if (onClose != null) {
            alert.onClose = onClose;
        }
        addPopUp(alert, true, true);
        return alert;
    }

    /**
     * Create a confirmation dialog
     */
    public function createConfirm(title:String, message:String, onConfirm:Void->Void, ?onCancel:Void->Void):PopUpWindow {
        var confirm = new ConfirmDialog(title, message, onConfirm, onCancel);
        addPopUp(confirm, true, true);
        return confirm;
    }
}

/**
 * Base class for popup windows
 */
class PopUpWindow extends Object {

    public var isModal:Bool = false;
    public var onClose:Void->Void;

    private var background:Graphics;
    private var titleBar:Flow;
    private var contentArea:Flow;
    private var _width:Float = 300;
    private var _height:Float = 200;

    public function new(?parent:Object) {
        super(parent);
        initialize();
    }

    private function initialize():Void {
        // Create background
        background = new Graphics(this);
        drawBackground();

        // Create title bar
        titleBar = new Flow(this);
        titleBar.layout = Horizontal;
        titleBar.y = 5;
        titleBar.x = 5;

        // Create content area
        contentArea = new Flow(this);
        contentArea.layout = Vertical;
        contentArea.y = 30;
        contentArea.x = 5;
        contentArea.maxWidth = Std.int(_width - 10);
    }

    private function drawBackground():Void {
        background.clear();
        background.beginFill(0xF0F0F0);
        background.lineStyle(1, 0x808080);
        background.drawRect(0, 0, _width, _height);
        background.endFill();
    }

    public function setSize(width:Float, height:Float):Void {
        _width = width;
        _height = height;
        drawBackground();

        if (contentArea != null) {
            contentArea.maxWidth = Std.int(_width - 10);
        }
    }

    public function getWidth():Float {
        return _width;
    }

    public function getHeight():Float {
        return _height;
    }

    public function addContent(content:Object):Void {
        contentArea.addChild(content);
    }

    public function close():Void {
        if (onClose != null) {
            onClose();
        }
    }

    public function update(dt:Float):Void {
        // Override in subclasses
    }

    public function dispose():Void {
        remove();
    }
}

/**
 * Simple alert dialog
 */
class AlertDialog extends PopUpWindow {

    private var titleText:Text;
    private var messageText:Text;
    private var okButton:Interactive;

    public function new(title:String, message:String) {
        super();

        setSize(400, 150);

        // Create title
        titleText = new Text(hxd.res.DefaultFont.get(), titleBar);
        titleText.text = title;
        titleText.textColor = 0x000000;

        // Create message
        messageText = new Text(hxd.res.DefaultFont.get(), contentArea);
        messageText.text = message;
        messageText.textColor = 0x000000;
        messageText.maxWidth = 380;

        // Create OK button
        createOKButton();
    }

    private function createOKButton():Void {
        var buttonBg = new Graphics(contentArea);
        buttonBg.beginFill(0xE0E0E0);
        buttonBg.lineStyle(1, 0x808080);
        buttonBg.drawRect(0, 0, 80, 25);
        buttonBg.endFill();
        buttonBg.y = 20;

        var buttonText = new Text(hxd.res.DefaultFont.get(), buttonBg);
        buttonText.text = "OK";
        buttonText.textColor = 0x000000;
        buttonText.x = 30;
        buttonText.y = 5;

        okButton = new Interactive(80, 25, buttonBg);
        okButton.onClick = function(event:Event) {
            close();
        };
    }
}

/**
 * Confirmation dialog with Yes/No buttons
 */
class ConfirmDialog extends PopUpWindow {

    private var titleText:Text;
    private var messageText:Text;
    private var yesButton:Interactive;
    private var noButton:Interactive;
    private var onConfirm:Void->Void;
    private var onCancel:Void->Void;

    public function new(title:String, message:String, onConfirm:Void->Void, ?onCancel:Void->Void) {
        super();

        this.onConfirm = onConfirm;
        this.onCancel = onCancel;

        setSize(400, 180);

        // Create title
        titleText = new Text(hxd.res.DefaultFont.get(), titleBar);
        titleText.text = title;
        titleText.textColor = 0x000000;

        // Create message
        messageText = new Text(hxd.res.DefaultFont.get(), contentArea);
        messageText.text = message;
        messageText.textColor = 0x000000;
        messageText.maxWidth = 380;

        // Create buttons
        createButtons();
    }

    private function createButtons():Void {
        var buttonContainer = new Flow(contentArea);
        buttonContainer.layout = Horizontal;
        buttonContainer.horizontalSpacing = 10;
        buttonContainer.y = 20;

        // Yes button
        var yesBg = new Graphics(buttonContainer);
        yesBg.beginFill(0xE0E0E0);
        yesBg.lineStyle(1, 0x808080);
        yesBg.drawRect(0, 0, 80, 25);
        yesBg.endFill();

        var yesText = new Text(hxd.res.DefaultFont.get(), yesBg);
        yesText.text = "Yes";
        yesText.textColor = 0x000000;
        yesText.x = 28;
        yesText.y = 5;

        yesButton = new Interactive(80, 25, yesBg);
        yesButton.onClick = function(event:Event) {
            if (onConfirm != null) onConfirm();
            close();
        };

        // No button
        var noBg = new Graphics(buttonContainer);
        noBg.beginFill(0xE0E0E0);
        noBg.lineStyle(1, 0x808080);
        noBg.drawRect(0, 0, 80, 25);
        noBg.endFill();

        var noText = new Text(hxd.res.DefaultFont.get(), noBg);
        noText.text = "No";
        noText.textColor = 0x000000;
        noText.x = 30;
        noText.y = 5;

        noButton = new Interactive(80, 25, noBg);
        noButton.onClick = function(event:Event) {
            if (onCancel != null) onCancel();
            close();
        };
    }
}
