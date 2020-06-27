package generics
{
	import constants.Size;
	import generics.Button_X;
	import interfaces.IMultiField;
	import interfaces.ISelfBuilding;
	import records.RecordEvent;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import mx.core.FlexSprite;
	
	public class MenuButton_X extends Button_X
	{		
		private var _popUp:ISelfBuilding;
		public function set infoTag(val:ISelfBuilding):void {
			_popUp = val;
		}
		
		public function MenuButton_X() {
			super();
			this.toggle = true;
		}
		
		
		// Function that takes the xml and builds the component according to the properties of that XML.  Could have as many 
		// properties as necessary
		// 	An example of the "xml" coming in could be:
		//<MenuButton_X ruid="logOutButtonB">
		//  <InfoTag_X tagColor="00aacc">
		//	  <Label_X text="Logout ?"/>
		//		<HBox_X>
		//	      <Button_X fid="confirm" text="Yes"/>
		//		  <Button_X fid="cancel" text="No"/>
		//		</HBox_X>
		//	</InfoTag_X>
		//</MenuButton_X>  
		
		override public function build(xml:XML):void {
			var recordAdded:Boolean = false;
			super.build(xml);
			if (xml.@ruid != undefined) {
				GMXDictionaries.pushCurrentRecord(this.record);
				recordAdded = true;
			}
			GMXComponentBuilder.processXML(this, xml);
			if (recordAdded) {
				GMXDictionaries.popCurrentRecord();
			}
			this.invalidateProperties();
		}
		
		override public function disintegrate():void {
			super.disintegrate();
			if (_popUp != null) {
				_popUp.disintegrate();
			}
		}
	} 
} 