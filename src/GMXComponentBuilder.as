package
{
	import GMXComponentProperties;
	import interfaces.IField;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import records.Attributes;
	import records.Record;
	import constants.Size;
	import flash.events.MouseEvent;
	import generics.Button_X;
	import generics.CheckBox_X;
	import generics.Calendar_X;
	import generics.ComboBox_X;
	import generics.Compass_X;
	import generics.Dial_X;
	import generics.Icon_X;
	import generics.InfoTag_X;
	import generics.InfoTagPopUp_X;
	import generics.Joystick_X;
	import generics.MaxStatus_X;
	import generics.MenuButton_X;
	import generics.SliderDisplay_X;
	import generics.CustomGrid;
	import generics.ShapeShifter;
	import generics.Spacer_X;
	import generics.SpinBox_X;
	import generics.TextArea_X;
	import generics.TextInput_X;
	import generics.HBox_X;
	import generics.TurnRateIndicator_X;
	import generics.VBox_X;
	import generics.Label_X;
	import generics.LabelEnum_X;
	import generics.RateInstrument_X;
	import generics.VoltageIndicator_X;
	import generics.Volume_X;
	import generics.WindDirIndicator_X;
	import gmx_builder.GMXBuilder;
	import mx.containers.HBox;
	import mx.controls.Label;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.states.SetStyle;
	import mx.styles.CSSStyleDeclaration;
	
	import flash.display.DisplayObject;
	
	import mx.controls.Alert;
	import mx.core.Container;
	import mx.core.UIComponent;
	
	public class GMXComponentBuilder
	{
		public static const MAIN_WINDOW_WIDTH:Number = 700;
		public static const MAIN_WINDOW_HEIGHT:Number = 600;
		public static const HEADER_HEIGHT:Number = 40; // for panels & dataGrids
		
		
		public static function processXML(parentContainer:UIComponent, xml:XML):ISelfBuilding {
			var children:XMLList = xml.children();
			
			for (var i:int = 0; i < children.length(); i++) {
				var childXML:XML = children[i];
				var component:ISelfBuilding = null;
				//trace("----CHILD----:\n" + childXML + "\n------------");
				if (childXML.localName() == null) { Alert.show("WARNING: Unexpected unnamed element in the following XML will be ignored: " + childXML); continue; }
				if (childXML.@luid != undefined) {
					component = GMXDictionaries.getLuid(childXML.@luid) as ISelfBuilding;
					if (!GMXMain.staticComponents.contains(component)) {
						component = null;
					}
				}
				var componentLabel:String = childXML.localName().toString();
				if (componentLabel == "field") { continue; }
				
				var componentClass:Class = GMXComponentProperties.getClassFromComponentLabel(componentLabel);
				
				if (componentClass == null) {
					Alert.show("WARNING: the following XML tag '" + componentLabel + "'is not a recognized component identifier.  This came from the following xml: " + xml.toString());
					continue;	
				}
				if (component == null) { component = new componentClass() as ISelfBuilding; }
				
				parentContainer.addChild(component as DisplayObject);
				// WEIRD ERROR for some reason the map (probably something to do with the external swf) doesn't 
				// correctly inside of GMXBuilder, so don't add these listeneres to it
				if (GMXBuilder.addGMXBuilderListeners) { 					
					// this flag is turned on in GMXBuilder only, and turned off immediately after completing
					// the "processXML" call from within GMXBuilder.
					component.addEventListener(MouseEvent.CLICK, GMXBuilder.clickedChild, false, 0, true);
					GMXBuilder.addComponent(component);
					if (GMXBuilder.DRAG_VERSION) {
						component.addEventListener(MouseEvent.MOUSE_DOWN, GMXBuilder.mouseDownOnChild, false, 0 , true);
					}
				}
				component.build(childXML);
				GMXDictionaries.applyExistingExtraLayoutStateToComponent(component);
				//component.dispatchEvent(new ResizingBoxEvent(ResizingBoxEvent.BOX_RESIZE));
			}
			// Returns the LAST component (only really useful if there is only one node)
			return component;
		}
		
		public static function setPropertiesFromXML(component:UIComponent, xml:XML):void {
			var xmlAttributes:XMLList = xml.attributes();
			for (var i:int = 0; i < xmlAttributes.length(); i++) {
				var methodName:String = "_set_" + xmlAttributes[i].localName();
				// in java, you would have to use reflection to do this... but actionscript makes it easy...
				if (methodName in component) { component[methodName](xmlAttributes[i].toString()); }
				else if (methodName in GMXComponentBuilder) { GMXComponentBuilder[methodName](component, xmlAttributes[i].toString()); }
				else {
					Alert.show(component.className + " function '_set_" + xmlAttributes[i].localName() + " was not found!  Invalid attribute!");
				}
			}
			if (xml.@luid != undefined) {
				component.id = xml.@luid.toString(); GMXDictionaries.addLuid(component.id, component as ISelfBuilding, xml);
			}
		}
		// some attributes (ruid, fid, attributes) are taken care of within the build function (usually because order
		// matters--e.g. attributes need to be handled AFTER the fid (getting the field all set up) is processed), so empty
		// functions are placed here for those attributes... note that in the setPropertiesFromXML function, it checks
		// whether the component Class of interest has the _set_____ function before using the _set____ functions below,
		// so if a component Class has, for example, a _set_fid function, it basically "overrides" the functions below
		public static function _set_fid(component:UIComponent, val:String):void {  }
		public static function _set_ruid(component:UIComponent, val:String):void {  }
		public static function _set_attributes(component:UIComponent, val:String):void {  }
		
		
		// begin standard component attributes functions
		public static function _set_x(component:UIComponent, val:String):void { component.x = parseMM(val); }
		public static function _set_y(component:UIComponent, val:String):void { component.y = parseMM(val); }
		public static function _set_width(component:UIComponent, val:String):void { component.width = parseMM(val); }
		public static function _set_height(component:UIComponent, val:String):void { component.height = parseMM(val); }
		public static function _set_percentWidth(component:UIComponent, val:String):void { component.percentWidth = parseMM(val); }
		public static function _set_percentHeight(component:UIComponent, val:String):void { component.percentHeight = parseMM(val); }
		public static function _set_preserve(component:UIComponent, val:String):void { } // swap children over??
		
		public static function _set_static(component:UIComponent, val:String):void { if (parseBoolean(val) == true && !GMXMain.staticComponents.contains(component)) { GMXMain.staticComponents.addItem(component); } }
		public static function _set_toolTip(component:UIComponent, val:String):void { component.toolTip = val; }
		public static function _set_alpha(component:UIComponent, val:String):void { component.alpha = parseFloat(val); }
		public static function _set_visible(component:UIComponent, val:String):void { component.visible = parseBoolean(val); }
		public static function _set_flexible(component:UIComponent, val:String):void {
			var selfBuilding:ISelfBuilding = component as ISelfBuilding;
			if (selfBuilding != null) { selfBuilding.flexible = parseBoolean(val); }
		}
		//_set_luid is handled in the setPropertiesFromXML function itself (i'm not sure why i did this originally, but there must be some kind of timing problem
		//public static function _set_luid(component:UIComponent, val:String, xml:XML = null):void { component.id = val; GMXDictionaries.addLuid(component.id, component as ISelfBuilding); }
		public static function _set_luid(component:UIComponent, val:String, xml:XML = null):void { } 
		public static function _set_enabled(component:UIComponent, val:String):void {
			/* if (uiComponent is IField) {
				//trace("  component is IField");
				var fieldComponent:IField = uiComponent as IField;
				
				if (xml.@enabled.toString() == "false") {
					if (fieldComponent.field != null) {
						//trace("  false: attrbiutes permissions changed to PERMISSIONS_DISABLED");
						fieldComponent.field.attributes.permissions = Attributes.PERMISSIONS_DISABLED;
					} else fieldComponent.enabled = false;
				} else { // xml.@enabled.toString() == "true"
					if (fieldComponent.field != null) {
						//trace("  true: attrbiutes permissions changed to PERMISSIONS_RW");
						fieldComponent.field.attributes.permissions = Attributes.PERMISSIONS_RW;
					} else fieldComponent.enabled = true;
				}
			} */
			component.enabled = parseBoolean(val);
		}
		public static function _set_layout(component:UIComponent, val:String):void {
			var hasRecord:Boolean = false;
			if (component is IField) {
				var iField:IField = component as IField;
				if (iField.record == null) {
					Alert.show("WARNING: Attempted to add a layout to a component, but there is no ruid on that component!!! To avoid unexpected behavior, assigning "
						+  "a layout to a component REQUIRES that the component has it's own ruid!!!");
				} else { hasRecord = true; }
			} else if (component is IMultiField) {
				var iMultiField:IMultiField = component as IMultiField;
				if (iMultiField.record == null) {
					Alert.show("WARNING: Attempted to add a layout to a component, but there is no ruid on that component!!! To avoid unexpected behavior, assigning "
						+  "a layout to a component REQUIRES that the component has it's own ruid!!!");
				} else { hasRecord = true; }
			} else {
				Alert.show("WARNING: Attempted to add a layout to a component, but it is neither an IField or a ISelfBuilding component!  To avoid unexpected behavior, assigning "
						+  "a layout to a component REQUIRES that the component has it's own ruid!!!");
			}
			if (hasRecord) {
				var rec:Record = GMXDictionaries.getCurrentRecord();
				if (rec == null) { 
					Alert.show("WARNING: Attempted to call _set_layout on a record, but there is no record on the RecordStack!")
				} else {
					rec.layout = val;
				}
			}
		}
		// ============ BEGIN CONTAINER SPECIFIC ATTRIBUTES =================================================
		public static function _set_padding(component:UIComponent, val:String):void { 
			if (!(component is Container)) return;
			var padding:Number = parseMM(val);
			component.setStyle("paddingLeft", padding);
			component.setStyle("paddingRight", padding);
			component.setStyle("paddingBottom", padding);
			component.setStyle("paddingTop", padding);
		}
		public static function _set_paddingRight(component:UIComponent, val:String):void { if (component is Container) component.setStyle("paddingRight", parseMM(val)); }
		public static function _set_paddingLeft(component:UIComponent, val:String):void { if (component is Container) component.setStyle("paddingLeft", parseMM(val)); }
		public static function _set_paddingTop(component:UIComponent, val:String):void { if (component is Container) component.setStyle("paddingTop", parseMM(val)); }
		public static function _set_paddingBottom(component:UIComponent, val:String):void { if (component is Container) component.setStyle("paddingBottom", parseMM(val)); }
		public static function _set_backgroundAlpha(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundAlpha", parseFloat(val)); }
		public static function _set_backgroundAttachment(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundAttachment", val); }
		public static function _set_backgroundColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundColor", parseColor(val)); }
		public static function _set_backgroundImage(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundImage", "./assets/" + val); }
		public static function _set_backgroundDisabledColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundDisabledColor", parseColor(val)); }
		public static function _set_backgroundSize(component:UIComponent, val:String):void { if (component is Container) component.setStyle("backgroundSize", val); }
		public static function _set_barColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("barColor", parseColor(val)); }
		public static function _set_borderColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("borderColor", parseColor(val)); }
		public static function _set_borderSides(component:UIComponent, val:String):void { if (component is Container) component.setStyle("borderSides", val); }
		public static function _set_borderStyle(component:UIComponent, val:String):void { if (component is Container) component.setStyle("borderStyle", val); }
		public static function _set_borderThickness(component:UIComponent, val:String):void { if (component is Container) component.setStyle("borderThickness", parseFloat(val)); }
		public static function _set_color(component:UIComponent, val:String):void { if (component is Container) component.setStyle("color", parseColor(val)); }
		public static function _set_cornerRadius(component:UIComponent, val:String):void { if (component is Container) component.setStyle("cornerRadius", parseFloat(val)); }
		public static function _set_disabledColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("disabledColor", parseColor(val)); }
		public static function _set_disabledOverlayAlpha(component:UIComponent, val:String):void { if (component is Container) component.setStyle("disbledOverlayAlpha", parseFloat(val)); }
		public static function _set_dropShadowColor(component:UIComponent, val:String):void { if (component is Container) component.setStyle("dropShadowColor", parseColor(val)); }
		public static function _set_dropShadowEnabled(component:UIComponent, val:String):void { if (component is Container) component.setStyle("dropShadowEnabled", parseBoolean(val)); }
		public static function _set_fontAntiAliasType(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontAntiAliasType", val); }
		public static function _set_fontfamily(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontfamily", val); }
		public static function _set_fontGridFitType(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontGridFitType", val); }
		public static function _set_fontSharpness(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontSharpness", parseFloat(val)); }
		public static function _set_fontSize(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontSize", parseFloat(val)); }
		public static function _set_fontStyle(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontStyle", val); }
		public static function _set_fontThickness(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontThickness", parseFloat(val)); }
		public static function _set_fontWeight(component:UIComponent, val:String):void { if (component is Container) component.setStyle("fontWeight", val); }
		public static function _set_horizontalScrollBarStyleName(component:UIComponent, val:String):void { if (component is Container) component.setStyle("horizontalScrollBarStyleName", val); }
		public static function _set_shadowDirection(component:UIComponent, val:String):void { if (component is Container) component.setStyle("shadowDirection", val); }
		public static function _set_shadowDistance(component:UIComponent, val:String):void { if (component is Container) component.setStyle("shadowDistance", val); }
		public static function _set_textAlign(component:UIComponent, val:String):void { if (component is Container) component.setStyle("textAlign", val); }
		public static function _set_textDecoration(component:UIComponent, val:String):void { if (component is Container) component.setStyle("textDecoration", val); }
		public static function _set_textIndent(component:UIComponent, val:String):void { if (component is Container) component.setStyle("textIndent", parseFloat(val)); }
		public static function _set_verticalScrollBarStyleName(component:UIComponent, val:String):void { if (component is Container) component.setStyle("verticalScrollBarStyleName", val); }
		public static function _set_autoLayout(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.autoLayout = parseBoolean(val);
		}
		public static function _set_clipContent(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.clipContent = parseBoolean(val);
		}
		public static function _set_creationIndex(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.creationIndex = parseInt(val);
		}
		public static function _set_creationPolicy(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.creationPolicy = val;
		}
		public static function _set_horizontalLineScrollSize(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.horizontalLineScrollSize = parseFloat(val);
		}
		public static function _set_horizontalScrollPosition(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.horizontalScrollPosition = parseFloat(val);
		}
		public static function _set_horizontalPageScrollSize(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.horizontalLineScrollSize = parseFloat(val);
		}
		public static function _set_horizontalScrollPolicy(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.horizontalScrollPolicy = val;
		}		
		public static function _set_label(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.label = val;
		}
		public static function _set_verticalLineScrollSize(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.verticalLineScrollSize = parseFloat(val);
		}		
		public static function _set_verticalScrollPosition(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.verticalScrollPosition = parseFloat(val);
		}
		public static function _set_verticalPageScrollSize(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.verticalLineScrollSize = parseFloat(val);
		}
		public static function _set_verticalScrollPolicy(component:UIComponent, val:String):void { 
			var container:Container = component as Container; if (container == null) { return; } container.verticalScrollPolicy = val;
		}
		
		
		public static function setStandardValues(xml:XML, uiComponent:UIComponent = null):void {
			var container:Container = uiComponent as Container;
			var val:Number;
			if (container != null) {
				// edit generic container properties
				if (xml.@padding != undefined) {
					var padding:Number = parseMM(xml.@padding.toString());
					container.setStyle("paddingLeft", padding);
					container.setStyle("paddingRight", padding);
					container.setStyle("paddingBottom", padding);
					container.setStyle("paddingTop", padding);
				}
				// ****************************** Generic container properties and Styles ****************************************
				if (xml.@paddingRight != undefined) { container.setStyle("paddingRight", parseMM(xml.@paddingRight.toString())); }
				if (xml.@paddingLeft != undefined) { container.setStyle("paddingLeft", parseMM(xml.@paddingLeft.toString())); }
				if (xml.@paddingTop != undefined) { container.setStyle("paddingTop", parseMM(xml.@paddingTop.toString())); }
				if (xml.@paddingBottom != undefined) { container.setStyle("paddingBottom", parseMM(xml.@paddingBottom.toString())); }
				if (xml.@autoLayout != undefined) { if (xml.@autoLayout.toString() == "true") container.autoLayout = true; }
				if (xml.@clipContent != undefined) { if (xml.@clipContent.toString() == "true") container.clipContent = true; }
				if (xml.@creationIndex != undefined) { container.creationIndex = int(xml.@creationIndex); }
				if (xml.@creationPolicy != undefined) { container.creationPolicy = xml.@creationPolicy.toString(); }
				// defaultButton="No default"
				if (xml.@horizontalLineScrollSize != undefined) { container.horizontalLineScrollSize = Number(xml.@horizontalLineScrollSize); }
				if (xml.@horizontalPageScrollSize != undefined) { container.horizontalPageScrollSize = Number(xml.@horizontalPageScrollSize); }
				// horizontalScrollBar="null"
				if (xml.@horizontalScrollPolicy != undefined) { container.horizontalScrollPolicy = xml.@horizontalScrollPolicy.toString(); }
				if (xml.@horizontalScrollPosition != undefined) { container.horizontalScrollPosition = Number(xml.@horizontalScrollPosition); }
				// icon="undefined"
				if (xml.@label != undefined) { container.label = xml.@label.toString(); }
				if (xml.@verticalLineScrollSize != undefined) { container.verticalLineScrollSize = Number(xml.@verticalLineScrollSize); }
				if (xml.@verticalPageScrollSize != undefined) { container.verticalPageScrollSize = Number(xml.@verticalPageScrollSize); }
				// verticalScrollBar="null"
				if (xml.@verticalScrollPolicy != undefined) { container.verticalScrollPolicy = xml.@verticalScrollPolicy.toString(); }
				if (xml.@verticalScrollPosition != undefined) { container.verticalScrollPosition = Number(xml.@verticalScrollPosition); }
				if (xml.@backgroundAlpha != undefined) { container.setStyle("backgroundAlpha", Number(xml.@backgroundAlpha)); }
				if (xml.@backgroundAttachment != undefined) { container.setStyle("backgroundAttachment", xml.@backgroundAttachment.toString()); }
				if (xml.@backgroundColor != undefined) { container.setStyle("backgroundColor", parseColor(xml.@backgroundColor.toString())); }
				if (xml.@backgroundDisabledColor != undefined) { container.setStyle("backgroundDisabledColor", parseColor(xml.@backgroundDisabledColor.toString())); }
				// backgroundImage="undefined"
				if (xml.@backgroundSize != undefined) { container.setStyle("backgroundSize", xml.@backgroundSize.toString()); }
				if (xml.@barColor != undefined) { container.setStyle("barColor", parseColor(xml.@barColor.toString())); }
				if (xml.@borderColor != undefined) { container.setStyle("borderColor", parseColor(xml.@borderColor.toString())); }
				if (xml.@borderSides != undefined) { container.setStyle("borderSides", xml.@borderSides.toString()); }
				// borderSkin="mx.skins.halo.HaloBorder"
				if (xml.@borderStyle != undefined) { container.setStyle("borderStyle", xml.@borderStyle.toString()); }
				if (xml.@borderThickness != undefined) { container.setStyle("borderThickness", Number(xml.@borderThickness)); }
				if (xml.@color != undefined) { container.setStyle("color", parseColor(xml.@color.toString())); }
				if (xml.@cornerRadius != undefined) { container.setStyle("cornerRadius", Number(xml.@cornerRadius)); }
				if (xml.@disabledColor != undefined) { container.setStyle("disabledColor", parseColor(xml.@disabledColor.toString())); }
				if (xml.@disabledOverlayAlpha != undefined) { container.setStyle("disbledOverlayAlpha", Number(xml.@disbledOverlayAlpha)); }
				if (xml.@dropShadowColor != undefined) { container.setStyle("dropShadowColor", parseColor(xml.@dropShadowColor.toString())); }
				if (xml.@dropShadowEnabled != undefined) { container.setStyle("dropShadowEnabled", parseBoolean(xml.@dropShadowEnabled.toString())); }
				if (xml.@fontAntiAliasType != undefined) { container.setStyle("fontAntiAliasType", xml.@fontAntiAliasType.toString()); }
				if (xml.@fontfamily != undefined) { container.setStyle("fontfamily", xml.@fontfamily.toString()); }
				if (xml.@fontGridFitType != undefined) { container.setStyle("fontGridFitType", xml.@fontGridFitType.toString()); }
				if (xml.@fontSharpness != undefined) { container.setStyle("fontSharpness", Number(xml.@fontSharpness)); }
				if (xml.@fontSize != undefined) { container.setStyle("fontSize", Number(xml.@fontSize)); }
				if (xml.@fontStyle != undefined) { container.setStyle("fontStyle", xml.@fontStyle.toString()); }
				if (xml.@fontThickness != undefined) { container.setStyle("fontThickness", Number(xml.@fontThickness)); }
				if (xml.@fontWeight != undefined) { container.setStyle("fontWeight", xml.@fontWeight.toString()); }
				if (xml.@horizontalScrollBarStyleName != undefined) { container.setStyle("horizontalScrollBarStyleName", xml.@horizontalScrollBarStyleName.toString()); }
				if (xml.@shadowDirection != undefined) { container.setStyle("shadowDirection", xml.@shadowDirection.toString()); }
				if (xml.@shadowDistance != undefined) { container.setStyle("shadowDistance", xml.@shadowDistance.toString()); }
				if (xml.@textAlign != undefined) { container.setStyle("textAlign", xml.@textAlign.toString()); }
				if (xml.@textDecoration != undefined) { container.setStyle("textDecoration", xml.@textDecoration.toString()); }
				if (xml.@textIndent != undefined) { container.setStyle("textIndent", Number(xml.@textIndent)); }
				if (xml.@verticalScrollBarStyleName != undefined) { container.setStyle("verticalScrollBarStyleName", xml.@verticalScrollBarStyleName.toString()); }
			}
			// edit generic uiComponent properties
			if (xml.@percentWidth != undefined) {
				uiComponent.percentWidth = Number(xml.@percentWidth);
			}
			if (xml.@percentHeight != undefined) {
				uiComponent.percentHeight = Number(xml.@percentHeight);
			}
			if (xml.@preserve != undefined) {
				// swap children over??
			}
			if (xml.@luid != undefined) {
				uiComponent.id = xml.@luid.toString();
				GMXDictionaries.addLuid(uiComponent.id, uiComponent as ISelfBuilding, xml);
			}
			if (xml.@explicitHeight != undefined) {
				uiComponent.measuredHeight = uiComponent.explicitHeight = parseMM(xml.@explicitHeight.toString());
			}
			if (xml.@explicitWidth != undefined) {
				uiComponent.measuredWidth = uiComponent.explicitWidth = parseMM(xml.@explicitWidth.toString());
			}
			if (xml.@height != undefined) {
				uiComponent.measuredHeight = uiComponent.height = parseMM(xml.@height.toString());
			}
			if (xml.@width != undefined) {
				uiComponent.measuredWidth = uiComponent.width = parseMM(xml.@width.toString());
			}
			if (xml.@x != undefined) {
				uiComponent.x = parseMM(xml.@x.toString());
			}
			if (xml.@y != undefined) {
				uiComponent.y = parseMM(xml.@y.toString());
			}
			if (xml.@enabled != undefined) {
				//trace("enabled will be changed to : " + xml.@enabled.toString());
				if (uiComponent is IField) {
					//trace("  component is IField");
					var fieldComponent:IField = uiComponent as IField;
					if (xml.@enabled.toString() == "false") {
						if (fieldComponent.field != null) {
							//trace("  false: attrbiutes permissions changed to PERMISSIONS_DISABLED");
							fieldComponent.field.attributes.permissions = Attributes.PERMISSIONS_DISABLED;
						} else fieldComponent.enabled = false;
					} else { // xml.@enabled.toString() == "true"
						if (fieldComponent.field != null) {
							//trace("  true: attrbiutes permissions changed to PERMISSIONS_RW");
							fieldComponent.field.attributes.permissions = Attributes.PERMISSIONS_RW;
						} else fieldComponent.enabled = true;
					}
				} else {
					uiComponent.enabled = xml.@enabled.toString() == "false" ? false : true;
				}
			}
			if (xml.@toolTip != undefined) { 
				uiComponent.toolTip = xml.@toolTip.toString();
			}
			if (xml.@alpha != undefined) {
				uiComponent.alpha = Number(xml.@alpha);
			}
			if (xml.@visible != undefined) {
				uiComponent.visible = xml.@visible.toString() == "false" ? false : true;
			}
			if (xml.@flexible != undefined) {
				var selfBuilding:ISelfBuilding = uiComponent as ISelfBuilding;
				if (selfBuilding != null) { selfBuilding.flexible = xml.@flexible.toString() == "true" ? true : false; }
			}
			if (xml.@layout != undefined) {
				if (xml.@ruid == undefined) {  
					Alert.show("WARNING: Attempted to add a layout to a component, but there is no ruid on that component!!! To avoid unexpected behavior, assigning "
							+  "a layout to a component REQUIRES that the component has it's own ruid!!!");
				} else {
					var rec:Record = GMXDictionaries.getCurrentRecord();
					if (rec == null) { 
						Alert.show("WARNING: Attempted to add layout to a record, but there is no record on the RecordStack!  Incoming xml: " + xml.toString())
					} else {
						rec.layout = xml.@layout.toString();
					}
				}
			}
			if (xml.@static != undefined) {
				if (xml.@static.toString() == "true" && !GMXMain.staticComponents.contains(uiComponent)) {
					GMXMain.staticComponents.addItem(uiComponent);
				}
			}
		}
// ============================================================================================================================
// ============ BEGIN HELPER FUNCTIONS FOR PARSING STRINGS INTO OTHER TYPES OF DATA ===========================================
		static public function parseMM(val:String):Number {
			if (val.length > 2 && val.substring(val.length - 2, val.length) == "mm") {
				return parseFloat(val.substring(0, val.length - 2)) * Size.MM;
			} else return parseFloat(val);
		}
		
		static public function parseColor(val:String):int {
			return parseInt(val, 16);
		}
		static public function parseBoolean(val:String):Boolean {
			if (val == "true") return true;
			return false;
		}
		static public function parseNumberArray(val:String, delim:String = "|"):Array {
			var stringArray:Array = val.split(delim);
			var output:Array = new Array();
			for (var i:int = 0; i < stringArray.length; i++) {
				output.push(parseFloat(stringArray[i]));
			}
			return output;
		}
		static public function parseStringArray(val:String, delim:String = "|"):Array {
			var stringArray:Array = val.split(delim);
			var output:Array = new Array();
			for (var i:int = 0; i < stringArray.length; i++) {
				output.push(stringArray[i].toString());
			}
			return output;
		}
		static public function parseColorArray(val:String, delim:String = "|"):Array {
			var stringArray:Array = val.split(delim);
			var output:Array = new Array();
			for (var i:int = 0; i < stringArray.length; i++) {
				output.push(parseInt(stringArray[i], 16));
			}
			return output;
		}
		static public function parseBooleanArray(val:String, delim:String = "|"):Array {
			var stringArray:Array = val.split(delim);
			var output:Array = new Array();
			for (var i:int = 0; i < stringArray.length; i++) {
				if (stringArray[i] == "true") { output.push(true); }
				else { output.push(false); }
			}
			return output;
		}
		static public function parseIntArray(val:String, delim:String = "|"):Array {
			var stringArray:Array = val.split(delim);
			var output:Array = new Array();
			for (var i:int = 0; i < stringArray.length; i++) {
				output.push(parseInt(stringArray[i]));
			}
			return output;
		}
// ============ END HELPER FUNCTIONS FOR PARSING STRINGS INTO OTHER TYPES OF DATA =============================================
// ============================================================================================================================

	}
}