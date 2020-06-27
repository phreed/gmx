// ActionScript file
package constants 
{
	
	import flash.text.FontStyle;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	
	public class Font {
		// http://www.webpagepublicity.com/free-fonts-v.html
		[Embed(source="/constants/Verdana.ttf",//source="../asset-src/fonts/Verdana.ttf", 
		       fontName="Verdana", 
		       mimeType="application/x-font-truetype")]
		static public const Verdana_FCS:Class;
			
		static public const SMALL:FontStyle = new FontStyle; // Verdana, 12 pt
		static public const SMALL_BOLD:FontStyle = new FontStyle; // Verdana, 12 pt, Bold
		static public const TITLE:FontStyle = new FontStyle; // Verdana, 14 pt
		static public const TYPE:String = "Verdana";
		static public const SIZE:uint = 12;
		
		static public const SMALL_FONT:TextFormat = new TextFormat(
		   Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.CENTER, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
		   
		static public const SMALL_FONT_GENERIC:TextFormat = new TextFormat(
		   null, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.CENTER, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);  
		   
		static public const SMALL_FONT_GENERIC_LEFT:TextFormat = new TextFormat(
		   null, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.LEFT, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);     
		
		static public const SMALL_FONT_LEFT:TextFormat = new TextFormat(
		   Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.LEFT, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);   
		   
		static public const LARGE_FONT:TextFormat = new TextFormat(
			Font.TYPE, // font:String = null, 
			14, // size:Object = null, 
			null, // color:Object = null, 
			FontStyle.BOLD, // bold:Object = null, 
			null, // italic:Object = null, 
			null, // underline:Object = null, 
			null, // url:String = null, 
			null, // target:String = null, 
			TextFormatAlign.CENTER, 
			null, // leftMargin:Object = null, 
			null, // rightMargin:Object = null, 
			null, // indent:Object = null, 
			null ); // leading:Object = null);
		
		static public const LARGE_FONT_LEFT:TextFormat = new TextFormat(
			Font.TYPE, // font:String = null, 
			14, // size:Object = null, 
			null, // color:Object = null, 
			FontStyle.BOLD, // bold:Object = null, 
			null, // italic:Object = null, 
			null, // underline:Object = null, 
			null, // url:String = null, 
			null, // target:String = null, 
			TextFormatAlign.LEFT, 
			null, // leftMargin:Object = null, 
			null, // rightMargin:Object = null, 
			null, // indent:Object = null, 
			null ); // leading:Object = null);
			
		static public const LARGE_FONT_GENERIC:TextFormat = new TextFormat(
		    null, // font:String = null, 
			14, // size:Object = null, 
			null, // color:Object = null, 
			FontStyle.BOLD, // bold:Object = null, 
			null, // italic:Object = null, 
			null, // underline:Object = null, 
			null, // url:String = null, 
			null, // target:String = null, 
			TextFormatAlign.CENTER, 
			null, // leftMargin:Object = null, 
			null, // rightMargin:Object = null, 
			null, // indent:Object = null, 
			null ); // leading:Object = null);	
           
        static public const SMALL_FONT_DISABLED:TextFormat = new TextFormat(
		   Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           0x777777, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.CENTER, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
            
		static public const GRAPH_GRID_LINE:TextFormat = new TextFormat(
           Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           0x111111, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.CENTER, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
           
      static public const FRAME_LEFT:TextFormat = new TextFormat(
           Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.JUSTIFY, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
           
      static public const FRAME_RIGHT:TextFormat = new TextFormat(
           Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           null, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.JUSTIFY, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
           
      static public const FRAME_CENTER:TextFormat = new TextFormat(
           Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           0x0, // color:Object = null, 
           null, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.JUSTIFY, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
      
	
	static public const MAP_TEXT:TextFormat = new TextFormat(
           Font.TYPE, // font:String = null, 
           Font.SIZE, // size:Object = null, 
           0xcccccc, // color:Object = null, 
           FontStyle.BOLD, // bold:Object = null, 
           null, // italic:Object = null, 
           null, // underline:Object = null, 
           null, // url:String = null, 
           null, // target:String = null, 
           TextFormatAlign.JUSTIFY, 
           null, // leftMargin:Object = null, 
           null, // rightMargin:Object = null, 
           null, // indent:Object = null, 
           null ); // leading:Object = null);
      
	}
}
