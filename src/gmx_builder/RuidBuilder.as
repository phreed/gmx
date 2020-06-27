package gmx_builder 
{
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	/**
	 * ...
	 * @author 
	 */
	public class RuidBuilder extends HBox
	{
		private var ruidCombo:ComboBox;
		private var refCombo:ComboBox;
		private var selectCombo:ComboBox;
		
		public function get value():Vector.<String> {
			var output:Vector.<String> = new Vector.<String>();
			output.push(ruidCombo.text);
			output.push(refCombo.text);
			output.push(selectCombo.text);
			return output;
		}
		public function RuidBuilder() 
		{
			super();
			var label:Label;
			var comboBox:ComboBox;
			
			label = new Label();
			label.text = "ruid: ";
			this.addChild(label);
			
			ruidCombo = new ComboBox();
			ruidCombo.dataProvider = GMXDictionaries.getRuidList();
			ruidCombo.editable = true;
			this.addChild(ruidCombo);
			
			label = new Label();
			label.text = "ref: ";
			this.addChild(label);
			
			refCombo = new ComboBox();
			refCombo.dataProvider = GMXDictionaries.getRuidList();
			refCombo.editable = true;
			this.addChild(refCombo);
			
			label = new Label();
			label.text = "select: ";
			this.addChild(label);
			
			selectCombo = new ComboBox();
			selectCombo.toolTip = "after	 Sibling Selector	 Required	 Optional	 Make Ruid a sibling of Ref immediately after Ref. If Ref is NULL, make Ruid the last child of Root.\n" +
								"before	 Sibling Selector	 Required	 Optional	 Make Ruid a sibling of Ref immediately before Ref. If Ref is NULL, make Ruid the first child of Root.\n" +
								"first	 Sibling Selector	 Required	 Optional	 Make Ruid a sibling a Ref at the front of its list. If Ref is NULL, make Ruid the first child of Root.\n" +
								"last	 Sibling Selector	 Required	 Optional	 Make Ruid a sibling of Ref at the end of its list. If Ref is NULL, make Ruid is the last child of Root.\n" +
								"child	 Tree Selector	 Required	 Optional	 Make Ruid a child of Ref. Ruid's children are Ref's former children. If Ref is NULL, assume Ref is Root.\n" +
								"parent	 Tree Selector	 Required	 Required	 Make Ruid a parent of Ref. Ref's former parent is Ruid's parent.\n" +
								"clear	 Removal Selector	 Prohibited	 Optional	 Remove all of Ref's children but not Ref itself. If Ref is NULL, assume Ref is Root.\n" +
								"del	 Removal Selector	 Prohibited	 Required	 Remove Ref and its children.';";
			selectCombo.dataProvider = new ArrayCollection(["last", "child", "after", "before", "first", "parent", "clear", "del"]);
			this.addChild(selectCombo);
		}
		
		public function resetDataProvider():void {
			refCombo.dataProvider = ruidCombo.dataProvider = GMXDictionaries.getRuidList();
		}
	}

}