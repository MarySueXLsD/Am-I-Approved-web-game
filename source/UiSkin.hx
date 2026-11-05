package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * Shared UI look: worn walnut, aged brass trim and warm paper, drawn as rounded pixel panels with a hard drop shadow.
 */
class UiSkin
{
	public static inline var INK = 0xFF241E18;
	public static inline var PANEL = 0xFF3A322A;
	public static inline var PANEL_DEEP = 0xFF1F1A15;
	/** Translucent panel fill for popups. */
	public static inline var PANEL_GLASS = 0xEE2A241E;
	public static inline var ACCENT = 0xFF6E5A44;
	public static inline var STEEL = 0xFFB8AE9F;
	public static inline var CREAM = 0xFFEFEAE0;
	public static inline var PAPER = 0xFFDDD6C8;
	public static inline var TRIM = 0xFFC4A77D;
	public static inline var TRIM_DARK = 0xFF7A6448;
	public static inline var STAMP_RED = 0xFFB8332B;
	public static inline var MUTED = 0xFF8C8377;
	/** Light text on dark panels. */
	public static inline var TEXT = 0xFFF0EBE2;
	/** Titles and values on dark panels. */
	public static inline var TITLE = 0xFFE3CFA8;
	public static inline var BUTTON = 0xFF54483A;
	public static inline var BUTTON_HOVER = 0xFF6F5F4C;
	/** Tint for hovered light buttons. */
	public static inline var HOVER_TINT = 0xFFE6D6BC;
	/** Outline behind text on dark panels and stamps. */
	public static inline var OUTLINE = 0xFF1F1A15;
	public static inline var SHADOW = 0x77000000;

	public static inline var SHADOW_OFFSET = 3;
	public static inline var TAIL_W = 6;

	/**
	 * Draws a rounded, outlined panel with a top highlight, a darker bottom lip and a drop shadow.
	 * The sprite ends up (w + shadow) x (h + shadow) pixels; the panel itself sits at 0,0.
	 */
	public static function panel(spr:FlxSprite, w:Int, h:Int, fill:Int, outline:Int, ?radius:Int = 4, ?border:Int = 2,
			?shadow:Int = SHADOW_OFFSET):Void
	{
		w = Std.int(Math.max(radius * 2 + 4, w));
		h = Std.int(Math.max(radius * 2 + 4, h));
		spr.makeGraphic(w + shadow, h + shadow, FlxColor.TRANSPARENT, true);
		var bmd = spr.pixels;
		paintPanel(bmd, 0, 0, w, h, fill, outline, radius, border, shadow);
		spr.dirty = true;
	}

	/** Speech bubble: a panel with a small tail on the left edge, pointing back at the speaker. */
	public static function bubble(spr:FlxSprite, w:Int, h:Int, fill:Int, outline:Int, tailLeft:Bool):Void
	{
		var tail = tailLeft ? TAIL_W : 0;
		var shadow = 2;
		w = Std.int(Math.max(16, w));
		h = Std.int(Math.max(16, h));
		spr.makeGraphic(w + tail + shadow, h + shadow, FlxColor.TRANSPARENT, true);
		var bmd = spr.pixels;
		paintPanel(bmd, tail, 0, w, h, fill, outline, 4, 2, shadow);

		if (tailLeft)
		{
			// Stepped pixel triangle poking out of the lower-left side; the fill runs into the
			// panel border so the tail reads as part of the bubble.
			var cy = Std.int(Math.max(8, h - 14));
			for (k in 0...TAIL_W + 2)
			{
				var half = Std.int(k * 0.6 + 0.5) + 1;
				bmd.fillRect(new Rectangle(k, cy - half, 1, half * 2 + 1), outline);
			}
			for (k in 1...TAIL_W + 3)
			{
				var half = Std.int((k - 1) * 0.6 + 0.5);
				bmd.fillRect(new Rectangle(k, cy - half, 1, half * 2 + 1), fill);
			}
		}
		spr.dirty = true;
	}

	static function paintPanel(bmd:BitmapData, x:Int, y:Int, w:Int, h:Int, fill:Int, outline:Int, radius:Int, border:Int, shadow:Int):Void
	{
		if (shadow > 0)
			roundRect(bmd, x + shadow, y + shadow, w, h, radius, SHADOW);
		roundRect(bmd, x, y, w, h, radius, outline);
		var inner = Std.int(Math.max(0, radius - border + 1));
		roundRect(bmd, x + border, y + border, w - border * 2, h - border * 2, inner, fill);

		// Bevel: a light line under the top edge and a darker lip along the bottom.
		var light:FlxColor = FlxColor.fromInt(fill).getLightened(0.35);
		var dark:FlxColor = FlxColor.fromInt(fill).getDarkened(0.18);
		var lipH = Std.int(Math.max(2, Math.min(4, h * 0.08)));
		bmd.fillRect(new Rectangle(x + border + inner, y + border, w - (border + inner) * 2, 1), light);
		bmd.fillRect(new Rectangle(x + border + inner, y + h - border - lipH, w - (border + inner) * 2, lipH), dark);
	}

	/** Pixel-stepped rounded rectangle. */
	public static function roundRect(bmd:BitmapData, x:Int, y:Int, w:Int, h:Int, r:Int, color:Int):Void
	{
		if (w <= 0 || h <= 0)
			return;
		r = Std.int(Math.min(r, Math.min(w, h) * 0.5));
		if (r <= 0)
		{
			bmd.fillRect(new Rectangle(x, y, w, h), color);
			return;
		}

		bmd.fillRect(new Rectangle(x, y + r, w, h - r * 2), color);
		for (k in 0...r)
		{
			var d = r - k;
			var inset = Std.int(r - Math.sqrt(r * r - d * d) + 0.5);
			bmd.fillRect(new Rectangle(x + inset, y + k, w - inset * 2, 1), color);
			bmd.fillRect(new Rectangle(x + inset, y + h - 1 - k, w - inset * 2, 1), color);
		}
	}

	/** Vertical two-tone gradient strip, used for menu backdrops. */
	public static function gradient(spr:FlxSprite, w:Int, h:Int, top:Int, bottom:Int):Void
	{
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		var bmd = spr.pixels;
		var steps = Std.int(Math.max(1, h / 4));
		for (i in 0...steps)
		{
			var t = i / Math.max(1, steps - 1);
			var c = FlxColor.interpolate(FlxColor.fromInt(top), FlxColor.fromInt(bottom), t);
			bmd.fillRect(new Rectangle(0, i * 4, w, 4), c);
		}
		spr.dirty = true;
	}
}
