package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

/** Small hand-drawn icons, stored as text so they need no image files. Every icon is 12x12 cells. */
class PixelIcons
{
	public static inline var SIZE = 12;

	static final PALETTE:Map<String, Int> = [
		"#" => 0xFF1F1A15, // outline
		"w" => 0xFFEAF0F6, // white
		"c" => 0xFFF0E8DA, // pale face / lens
		"s" => 0xFFF2D2A9, // skin
		"b" => 0xFFC4A77D, // aged brass
		"g" => 0xFF5FD068, // green
		"y" => 0xFFF2C94C, // gold
		"Y" => 0xFFB98A1E, // dark gold
		"r" => 0xFFE24A4A, // red
		"o" => 0xFFE08A3A, // orange
		"p" => 0xFFE8788A, // pink
		"t" => 0xFFB8AE9F, // warm grey
	];

	static final ICONS:Map<String, Array<String>> = [
		"client" => [
			"....####....",
			"...#ssss#...",
			"...#ssss#...",
			"...#ssss#...",
			"....####....",
			"...######...",
			"..#bbbbbb#..",
			".#bbbbbbbb#.",
			".#bbbbbbbb#.",
			".#bbbbbbbb#.",
			".##########.",
			"............"
		],
		"approved" => [
			"............",
			"..........gg",
			".........ggg",
			"........ggg.",
			".......ggg..",
			"gg....ggg...",
			"ggg..ggg....",
			".ggggggg....",
			"..ggggg.....",
			"...ggg......",
			"....g.......",
			"............"
		],
		"coin" => [
			"....####....",
			"..##yyyy##..",
			".#yyyYYyyy#.",
			".#yyYyyYyy#.",
			"#yyyYyyyyyy#",
			"#yyyYyyyyyy#",
			"#yyyYyyyyyy#",
			"#yyyYyyYyyy#",
			".#yyyYYyyy#.",
			".#yyyyyyyy#.",
			"..##yyyy##..",
			"....####...."
		],
		"decline" => [
			"....rrrr....",
			"..rrrrrrrr..",
			".rrr....rrr.",
			".rrrr....rr.",
			"rr.rrr....rr",
			"rr..rrr...rr",
			"rr...rrr..rr",
			"rr....rrr.rr",
			".rr....rrrr.",
			".rrr....rrr.",
			"..rrrrrrrr..",
			"....rrrr...."
		],
		"fraud" => [
			"...wwww.....",
			"..wccccw....",
			".wccccccw...",
			".wccccccw...",
			".wccccccw...",
			".wccccccw...",
			"..wccccw....",
			"...wwwwtt...",
			".......ttt..",
			"........ttt.",
			".........ttt",
			"..........tt"
		],
		"record" => [
			"..........pp",
			".........ppp",
			"........yypp",
			".......yyyy.",
			"......yyyy..",
			".....yyyy...",
			"....yyyy....",
			"...yyyy.....",
			"..syyy......",
			"..sss.......",
			".wws........",
			".w.........."
		],
		"bounced" => [
			".....oo.....",
			".....oo.....",
			"....oooo....",
			"....o##o....",
			"...oo##oo...",
			"...oo##oo...",
			"..ooo##ooo..",
			"..ooo##ooo..",
			".oooooooooo.",
			".oooo##oooo.",
			"oooooooooooo",
			"oooooooooooo"
		],
		"clock" => [
			"...######...",
			"..#cccccc#..",
			".#cccc#ccc#.",
			"#ccccc#cccc#",
			"#ccccc#cccc#",
			"#ccccc#cccc#",
			"#ccccc###cc#",
			"#cccccccccc#",
			"#cccccccccc#",
			".#cccccccc#.",
			"..#cccccc#..",
			"...######..."
		],
	];

	/** Paints an icon into a transparent graphic, each cell `scale` pixels wide. */
	public static function make(spr:FlxSprite, name:String, scale:Int):Void
	{
		spr.makeGraphic(SIZE * scale, SIZE * scale, FlxColor.TRANSPARENT, true);
		var rows = ICONS.get(name);
		if (rows == null)
			return;
		for (y in 0...rows.length)
		{
			var row = rows[y];
			for (x in 0...row.length)
			{
				var c = PALETTE.get(row.charAt(x));
				if (c != null)
					spr.pixels.fillRect(new Rectangle(x * scale, y * scale, scale, scale), c);
			}
		}
		spr.dirty = true;
	}
}
