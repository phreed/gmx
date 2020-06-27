package interfaces
{
	import mx.core.IFlexDisplayObject;
	import records.Attributes;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import mx.core.IUIComponent;
	
	/**
	 * All GMX components must implement ISelfBuilding or a sub-interface of it (e.g. IField or IMultiField) because
	 * they must all be able to (1) build themselves based on XML in layout messages (see build function) and (2) disconnect itself from the data 
	 * fields / records / collections that correspond to them such that they can be garbage collected (see disintegrate function).  Additional
	 * functionality is found in being able to set Attributes for these components through ISISAttributes messages, although these Attributes
	 * can only target those components with a single field.  Furthermore, GMX components must be able to be set "flexible" for resizing purposes
	 * (see resizeFlexibles function in VBox_X and HBox_X as well as ResizingBoxContainer)
	 */
	public interface ISelfBuilding extends IUIComponent, IFlexDisplayObject
	{
		/**
		 * All components implementing ISelfBuilding must be able to build themselves based on XML that describes it.  This function
		 * is generally called from within the GMXComponentBuilder.processXML function.  Furthermore, if the component
		 * is a container, its build function will likely also call GMXComponentBuilder.processXML(this, buildXML), which then goes
		 * on to build child components based on the children XML nodes (who likewise implement ISelfBuilding).
		 * 
		 * @param	buildXML	The xml that the component uses to build itself
		 * @see GMXComponentBuilder.processXML
		 */
		function build(buildXML:XML):void;
		/**
		 * If the component has fields, records, or collections, this function must remove all references to itself from those
		 * fields, records, or collections so that the component will be garbage collected, and if the component has children, this
		 * function has its children call disintegrate as well (recursive).
		 */
		function disintegrate():void;
		/**
		 * Generally, components implement this function by calling a function in IFieldStandardImpl
		 * @see interfaces.IFieldStandardImpl#setAttributes
		 * @param attributes	The attributes to be applied to the ISelfBuilding component.
		 */
		function setAttributes(attributes:Attributes):void;
		
		/**
		 * flexible components are resized based on the remaining space in a fixed height and/or width parent container "X" (vertically or horizontally) and
		 * the number of flexible components in that container.  The remaining space is split evenly between all flexible
		 * components in that container.  It is particularly important for ResizingBoxContainer and ResizingBox objects, where
		 * a button click in the ResizingBox results in it changing size and requiring the parent container "X" to adjust its children accordingly.
		 */
		function get flexible():Boolean;
		function set flexible(val:Boolean):void;
		
		
		// for some ridiculous reason IUIComponent and IFlexDisplayObject don't have these functions in them?
		function invalidateProperties():void;
		function invalidateDisplayList():void;
		function get numChildren():int;
		function getChildAt(index:int):DisplayObject;
		function get className():String;
	}
}