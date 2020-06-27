package
{
	import constants.Line;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	import flash.display.GraphicsPathWinding;
	import flash.display.Sprite;
	
	import mx.controls.Alert;

	public class Graphics_ISIS
	{
		private static const DEG_TO_RAD:Number = Math.PI/180;
		public function Graphics_ISIS()
		{
		}
		/**
		 * This function will create a colored zone in between the inner and outer radius.
		 * This zone should be able to exist in multiple places on the same range inbetween two co-centric circles.
		 * The lengths of the two arrays must match or else an alert will be thrown.
		 * The corresponding indexes lowerLimit[0] and upperLimit[0] will represent
		 * one individual zone...etc. [RANGE IS IN DEGREES]
		 */
		public static function drawZone(spriteX:Number, spriteY:Number, lowerZoneVals:Array, upperZoneVals:Array, innerRadValue:Number,
								  outerRadValue:Number, zoneColor:uint, spriteInvolved:Sprite):void {
			var DEG_TO_RAD:Number = Math.PI/180;
			spriteInvolved.graphics.clear();
			spriteInvolved.x= spriteX;
			spriteInvolved.y = spriteY;
			spriteInvolved.graphics.lineStyle(Line.THIN,0);
			innerRadValue = innerRadValue+1; 
			outerRadValue = outerRadValue-1;
			if (lowerZoneVals.length != upperZoneVals.length) {
				Alert.show("ARRAY RANGE FOR UPPER AND LOWER ZONE BOUNDS DO NOT MATCH");
				return;
			}
			spriteInvolved.graphics.lineStyle(1,zoneColor,.5);
			for ( var z:int=0; z<lowerZoneVals.length; z++) {
				spriteInvolved.graphics.beginFill(zoneColor);
				spriteInvolved.graphics.moveTo(innerRadValue*Math.cos(lowerZoneVals[z]*DEG_TO_RAD),
					innerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
				spriteInvolved.graphics.lineTo(outerRadValue*Math.cos(lowerZoneVals[z]*DEG_TO_RAD),
					outerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
				Graphics_ISIS.drawArcZ(outerRadValue,lowerZoneVals[z],upperZoneVals[z],spriteInvolved,false);
				spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(upperZoneVals[z]*DEG_TO_RAD),
					innerRadValue*Math.sin(upperZoneVals[z]*DEG_TO_RAD));
				for (var ex:Number = upperZoneVals[z]-1.0; ex>=lowerZoneVals[z]; ex--) {
					spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(ex*DEG_TO_RAD),innerRadValue*Math.sin(ex*DEG_TO_RAD));
				}
				if (z != lowerZoneVals[z]) {
					spriteInvolved.graphics.lineTo(innerRadValue*Math.cos(lowerZoneVals[z] * DEG_TO_RAD), innerRadValue*Math.sin(lowerZoneVals[z]*DEG_TO_RAD));
				}		
				spriteInvolved.graphics.endFill();
			}	
		}
		
		/**
		 * An approximate drawing of an Arc using multiple small line segments.
		 * Start and end angles are in degrees.
		 * Orientation is standard flash (opposite of algebraic angles).
		 * If it's a PiePiece it will create the initial line and the closing line as well. C(0,0).
		 */
		public static function drawArcZ(rad:Number,startAngle:Number,endAngle:Number,spriteUsed:Sprite,piePce:Boolean=false):void {
			var g:Graphics = spriteUsed.graphics;
			if (piePce) {
				g.moveTo(0,0);
				g.lineTo(rad*Math.cos(startAngle * DEG_TO_RAD), rad*Math.sin(startAngle*DEG_TO_RAD));
			} else {
				g.moveTo(rad*Math.cos(startAngle * DEG_TO_RAD), rad*Math.sin(startAngle*DEG_TO_RAD));
			}
			for (var z:Number = startAngle + 1.0; z<=endAngle;z++) {
				spriteUsed.graphics.lineTo(rad*Math.cos(z*DEG_TO_RAD),rad*Math.sin(z*DEG_TO_RAD));
			}
			if (z == endAngle) {
				if (piePce) { g.lineTo(0,0); }
				return;
			}
			g.lineTo(rad*Math.cos(endAngle * DEG_TO_RAD), rad*Math.sin(endAngle*DEG_TO_RAD));
			if (piePce) { g.lineTo(0,0); }
		}
		
		/**
         * An approximate drawing of a circle using eight quadratic b-splines.
         * start and end are in radians.
         * The pen gets left at the center of the arc.
         */
		public static function drawArc(x:Number, y:Number, radius:Number, start:Number, end:Number, sprite:Sprite, piePiece:Boolean = false):void
		{
			var pi2:Number = 2*Math.PI;
			while(start >= pi2) { start -= pi2 }
			while(start < 0) { start += pi2 }
			while(end >= pi2) { end -= pi2 }
			while(end < 0) { end += pi2 } 
			
			var cmds:Vector.<int> = new Vector.<int>;
			var data:Vector.<Number> = new Vector.<Number>;
			
			var start_octant:uint = start * 4/Math.PI;
			var end_octant:uint = end * 4/Math.PI;
			
			var mid_90:Number = Math.SQRT1_2*radius;
			var sq2m1:Number = radius * (Math.SQRT2 - 1.0);
			if (piePiece) { 
				cmds.push(GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO); 
				data.push(x, y, x+radius*Math.cos(start),y-radius*Math.sin(start));
			}
			// draw first
			cmds.push(GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.CURVE_TO, GraphicsPathCommand.CURVE_TO);
			data.push(x+radius*Math.cos(start),y-radius*Math.sin(start));
			var phi:Number = Math.PI/4*(start_octant+1);  // angle of the start of the next octant
			var angleA:Number = 1/4*(phi-start); // angle to one tangent intersect
			var angleMid:Number = 2*angleA; // angle to center of the arc
			var h1_2:Number = radius/Math.cos(angleA); // hypotenuse to both control points
			
			var controlX1:Number = h1_2*Math.cos(start+angleA) + x;
			var controlY1:Number = -h1_2*Math.sin(start+angleA) + y;
			var xMid:Number = radius*Math.cos(start+angleMid) + x;
			var yMid:Number = -radius*Math.sin(start+angleMid) + y;
			var controlX2:Number = h1_2*Math.cos(phi-angleA) + x;
			var controlY2:Number = -h1_2*Math.sin(phi-angleA) + y;
			
			switch(start_octant) {
				case 0: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x + mid_90, y - mid_90); break;
				case 1: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x, y - radius); break;
				case 2: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x - mid_90, y - mid_90); break;
				case 3: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x - radius, y); break;
				case 4: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x - mid_90, y + mid_90); break;
				case 5: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x , y + radius); break;
				case 6: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x + mid_90, y + mid_90); break;
				case 7: data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x + radius, y); break;
			}
			// draw intermediates
			var limit:uint = (start < end) ? end_octant : (8 + end_octant);
			for (var ix:uint = start_octant+1; ix < limit; ++ix) 
			{
				var octant:uint = (ix > 7) ? (ix - 8) : ix;
				cmds.push(GraphicsPathCommand.CURVE_TO);
				switch(octant) {
					case 0: data.push(x + radius, y - sq2m1, x + mid_90, y - mid_90); continue;
					case 1: data.push(x + sq2m1, y - radius, x , y - radius); continue;
					case 2: data.push(x - sq2m1, y - radius, x - mid_90, y - mid_90); continue;
					case 3: data.push(x - radius, y - sq2m1, x - radius, y); continue;
					case 4: data.push(x - radius, y + sq2m1, x - mid_90, y + mid_90); continue;
					case 5: data.push(x - sq2m1, y + radius, x , y + radius); continue;
					case 6: data.push(x + sq2m1, y + radius, x + mid_90, y + mid_90); continue;
					case 7: data.push(x + radius, y + sq2m1, x + radius, y); continue;
				}
			}
			// draw last
			cmds.push(GraphicsPathCommand.CURVE_TO, GraphicsPathCommand.CURVE_TO);
			phi = Math.PI/4*(end_octant);  // angle of the start of the next octant
			angleA = 1/4*(end-phi); // angle to one tangent intersect
			angleMid = 2*angleA; // angle to center of the arc
			h1_2 = radius/Math.cos(angleA); // hypotenuse to both control points
			
			controlX1 = h1_2*Math.cos(phi+angleA) + x;
			controlY1 = -h1_2*Math.sin(phi+angleA) + y;
			xMid = radius*Math.cos(phi+angleMid) + x;
			yMid = -radius*Math.sin(phi+angleMid) + y;
			controlX2 = h1_2*Math.cos(end-angleA) + x;
			controlY2 = -h1_2*Math.sin(end-angleA) + y;
			data.push(controlX1, controlY1, xMid, yMid, controlX2, controlY2, x+radius*Math.cos(end),y-radius*Math.sin(end));
			
			if (piePiece) { 
				cmds.push(GraphicsPathCommand.LINE_TO); 
				data.push(x, y);
			}
			sprite.graphics.drawPath(cmds, data, GraphicsPathWinding.EVEN_ODD);
		}
	}
}