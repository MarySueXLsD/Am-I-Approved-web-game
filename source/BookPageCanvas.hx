package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/** Typesets one handbook page into a bitmap: an official header band, then ruled tables, steps and stamped notes. */
class BookPageCanvas
{
	static inline var INK = 0xFF2A2218;
	static inline var FADED_INK = 0xFF5A4C38;
	static inline var RULE = 0x668A7860;
	static inline var BAND = 0xFF5A2A20;
	static inline var BAND_TEXT = 0xFFF0E6CC;
	static inline var NOTE_RED = 0xFFA63A2E;
	static inline var NOTE_FILL = 0x33A63A2E;
	static inline var FORMULA_FILL = 0x33FFFFFF;
	// The pixel font is crisp at 8, and small type is what fits a whole procedure on one page.
	static inline var BODY_SIZE = 8;
	static inline var GAP = 6;

	/** Height of the title band, so other text can be laid out beneath it. */
	public static inline var HEADER_H = 26;

	static var cache:Map<String, FlxGraphic> = new Map();
	static var typesetter:FlxText;

	public static function render(pageNum:Int, w:Int, h:Int):Null<FlxGraphic>
	{
		var page = BookIntroPages.getPage(pageNum);
		if (page == null)
			return null;

		var key = '$pageNum:$w:$h';
		var cached = cache.get(key);
		if (cached != null)
			return cached;

		var bmd = new BitmapData(w, h, true, 0x00000000);
		bmd.fillRect(new Rectangle(0, 0, w, HEADER_H - 7), BAND);
		bmd.fillRect(new Rectangle(0, HEADER_H - 5, w, 1), BAND);
		drawText(bmd, page.title.toUpperCase(), 5, 2, w - 10, 12, BAND_TEXT, true);

		var y = HEADER_H;
		for (block in page.blocks)
		{
			switch (block)
			{
				case Para(text):
					y += drawText(bmd, text, 0, y, w, BODY_SIZE, INK) + GAP;
				case Label(text):
					y += drawText(bmd, text, 0, y, w, BODY_SIZE, FADED_INK, true) + 1;
				case Rows(rows):
					y = drawRows(bmd, rows, y, w) + GAP;
				case Steps(steps):
					y = drawSteps(bmd, steps, y, w) + GAP;
				case Checks(items):
					y = drawChecks(bmd, items, y, w) + GAP;
				case Chips(chips):
					y = drawChips(bmd, chips, y, w) + GAP;
				case Tools(tools):
					y = drawTools(bmd, tools, y, w) + GAP;
				case Formula(lines):
					y = drawFormula(bmd, lines, y, w) + GAP;
				case Note(text):
					drawNote(bmd, text, w, h);
			}
		}

		// Persistent: a sprite moving off a page must not free it, the player will flip back.
		var graphic = FlxGraphic.fromBitmapData(bmd, false, 'book_page_$key');
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		cache.set(key, graphic);
		return graphic;
	}

	/** Stamps wrapped text onto the page and returns the height it used. */
	static function drawText(bmd:BitmapData, text:String, x:Int, y:Int, w:Int, size:Int, color:Int, ?bold:Bool = false, ?align:String = "left"):Int
	{
		if (typesetter == null)
			typesetter = new FlxText(0, 0, 10, "");

		typesetter.fieldWidth = w;
		typesetter.wordWrap = true;
		typesetter.text = text;
		typesetter.setFormat(null, size, color, align);
		typesetter.bold = bold;
		typesetter.drawFrame(true);
		var src = typesetter.pixels;
		bmd.copyPixels(src, src.rect, new Point(x, y - 2), null, null, true);
		return Std.int(typesetter.textField.textHeight);
	}

	static function drawRows(bmd:BitmapData, rows:Array<Array<String>>, y:Int, w:Int):Int
	{
		var labelW = Std.int(w * 0.36);
		for (row in rows)
		{
			var labelH = drawText(bmd, row[0], 0, y + 1, labelW, BODY_SIZE, FADED_INK, true);
			var valueH = drawText(bmd, row[1], labelW + 2, y + 1, w - labelW - 2, BODY_SIZE, INK);
			y += Std.int(Math.max(labelH, valueH)) + 3;
			bmd.fillRect(new Rectangle(0, y, w, 1), RULE);
			y += 2;
		}
		return y;
	}

	static function drawSteps(bmd:BitmapData, steps:Array<Array<String>>, y:Int, w:Int):Int
	{
		var indent = 18;
		for (i in 0...steps.length)
		{
			UiSkin.roundRect(bmd, 0, y, 14, 14, 7, BAND);
			drawText(bmd, Std.string(i + 1), 0, y + 3, 14, BODY_SIZE, BAND_TEXT, true, "center");
			var head = drawText(bmd, steps[i][0].toUpperCase(), indent, y, w - indent, BODY_SIZE, BAND, true);
			var body = drawText(bmd, steps[i][1], indent, y + head, w - indent, BODY_SIZE, INK);
			y += head + body + 4;
		}
		return y;
	}

	static function drawChecks(bmd:BitmapData, items:Array<String>, y:Int, w:Int):Int
	{
		var indent = 14;
		for (item in items)
		{
			bmd.fillRect(new Rectangle(1, y + 1, 9, 9), INK);
			bmd.fillRect(new Rectangle(2, y + 2, 7, 7), 0xFFE0D4B4);
			y += drawText(bmd, item, indent, y, w - indent, BODY_SIZE, INK) + 5;
		}
		return y;
	}

	static function drawChips(bmd:BitmapData, chips:Array<{color:Int, label:String, text:String}>, y:Int, w:Int):Int
	{
		for (chip in chips)
		{
			bmd.fillRect(new Rectangle(0, y + 1, w, 13), chip.color);
			drawText(bmd, chip.label, 3, y + 2, w - 6, BODY_SIZE, BAND_TEXT, true);
			y += 15;
			y += drawText(bmd, chip.text, 3, y, w - 6, BODY_SIZE, INK) + 2;
		}
		return y;
	}

	static function drawTools(bmd:BitmapData, tools:Array<Array<String>>, y:Int, w:Int):Int
	{
		var iconBox = 28;
		var indent = iconBox + 5;
		for (tool in tools)
		{
			drawIcon(bmd, tool[0], 0, y, iconBox);
			var head = drawText(bmd, tool[1], indent, y, w - indent, BODY_SIZE, BAND, true);
			var body = drawText(bmd, tool[2], indent, y + head, w - indent, BODY_SIZE, INK);
			y += Std.int(Math.max(iconBox, head + body)) + 3;
			bmd.fillRect(new Rectangle(0, y, w, 1), RULE);
			y += 3;
		}
		return y;
	}

	static function drawIcon(bmd:BitmapData, path:String, x:Int, y:Int, box:Int):Void
	{
		var src = FlxG.bitmap.add(path).bitmap;
		var s = Math.min(box / src.width, box / src.height);
		var m = new Matrix();
		m.scale(s, s);
		m.translate(x + (box - src.width * s) * 0.5, y + (box - src.height * s) * 0.5);
		bmd.draw(src, m, null, null, null, true);
	}

	static function drawFormula(bmd:BitmapData, lines:Array<String>, y:Int, w:Int):Int
	{
		var boxH = lines.length * 14 + 8;
		bmd.fillRect(new Rectangle(0, y, w, boxH), FORMULA_FILL);
		bmd.fillRect(new Rectangle(0, y, 3, boxH), BAND);
		var ly = y + 4;
		for (i in 0...lines.length)
		{
			drawText(bmd, lines[i], 8, ly + 1, w - 10, BODY_SIZE, i == 0 ? BAND : INK, i == 0);
			ly += 14;
		}
		return y + boxH;
	}

	static function drawNote(bmd:BitmapData, text:String, w:Int, pageH:Int):Void
	{
		var pad = 4;
		// Typeset once off the page to learn the height, since the note is anchored to the bottom.
		var scratch = new BitmapData(w, pageH, true, 0x00000000);
		var textH = drawText(scratch, text, 0, 0, w - pad * 2 - 2, BODY_SIZE, NOTE_RED, true);
		scratch.dispose();

		var boxH = textH + pad * 2;
		var top = pageH - boxH - 1;
		bmd.fillRect(new Rectangle(0, top, w, boxH), NOTE_FILL);
		for (r in [
			new Rectangle(0, top, w, 1),
			new Rectangle(0, top + boxH - 1, w, 1),
			new Rectangle(0, top, 1, boxH),
			new Rectangle(w - 1, top, 1, boxH)
		])
			bmd.fillRect(r, NOTE_RED);
		drawText(bmd, text, pad + 1, top + pad, w - pad * 2 - 2, BODY_SIZE, NOTE_RED, true);
	}
}
