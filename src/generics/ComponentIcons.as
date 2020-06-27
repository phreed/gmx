package generics
{
	import mx.controls.Alert;
	import mx.core.SpriteAsset;
		
	public class ComponentIcons
	{		
		[Embed(source="/assets/spinBoxDownArrow.svg")]
		public static const spinboxdownarrow:Class;
		
		[Embed(source="/assets/spinBoxUpArrow.svg")]
		public static const spinboxuparrow:Class;
		[Embed(source = "/assets/turnRate.svg")]
		public static const turnrate:Class;
		
		[Embed(source="/assets/skull.svg")]
		public static const skull:Class;
		[Embed(source="/assets/skull2.svg")]
		public static const skull2:Class;
		[Embed(source="/assets/skull3.svg")]
		public static const skull3:Class;
		[Embed(source="/assets/skull4.svg")]
		public static const skull4:Class;
		[Embed(source="/assets/skull5.svg")]
		public static const skull5:Class;
		
		public static function pickImage(icon:String):SpriteAsset {			
			var svgAsset:SpriteAsset;
			if (icon == null) { return null; }
			icon = icon.toLowerCase();
			try {
				svgAsset = new ComponentIcons[icon]() as SpriteAsset;
			} catch (e:Error) {
				trace("ComponentIcons: icon =" + icon + " did not map to any available embedded images");
				svgAsset = null;
			}
			
			return svgAsset;
		}
		
	}
}