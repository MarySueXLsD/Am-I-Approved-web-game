package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

enum ConversationDisplayKind
{
	Time;
	Dialogue;
	Empty;
	Blank;
}

typedef ConversationDisplayLine =
{
	kind:ConversationDisplayKind,
	text:String,
}

class MonitorConversationRecorderPanel extends FlxGroup
{
	static inline var SCROLL_W = 18;
	static inline var BTN_H = 16;

	public var scrollIndex(default, set) = 0;

	var panelBg:FlxSprite;
	var textLayer:FlxGroup;
	var lineTexts:Array<FlxText> = [];
	var scrollLayer:FlxGroup;
	var scrollColumn:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var scrollUpBtn:FlxSprite;
	var scrollDownBtn:FlxSprite;

	var areaX:Float = 0;
	var areaY:Float = 0;
	var areaW:Float = 0;
	var areaH:Float = 0;
	var contentW:Float = 0;
	var scrollX:Float = 0;
	var textPad = 8;
	var fontSize = 12;
	var timeSize = 11;
	var dialogueSize = 12;
	var displayLines:Array<ConversationDisplayLine> = [];
	var lineHeights:Array<Float> = [];
	var totalContentH = 0.0;
	var viewportH = 0.0;
	var thumbDragging = false;
	var dragGrabY = 0.0;
	var thumbH = 12;
	var trackY = 0.0;
	var trackH = 0.0;
	var lastThumbH = -1;
	var panelDirty = true;
	var measureText:FlxText;

	public function new()
	{
		super();

		panelBg = new FlxSprite();
		textLayer = new FlxGroup();
		scrollLayer = new FlxGroup();
		scrollColumn = new FlxSprite();
		scrollTrack = new FlxSprite();
		scrollThumb = new FlxSprite();
		scrollUpBtn = new FlxSprite();
		scrollDownBtn = new FlxSprite();
		measureText = new FlxText(0, 0, 100, "");
		measureText.visible = false;

		add(panelBg);
		add(textLayer);
		add(scrollLayer);
		scrollLayer.add(scrollColumn);
		scrollLayer.add(scrollTrack);
		scrollLayer.add(scrollUpBtn);
		scrollLayer.add(scrollDownBtn);
		scrollLayer.add(scrollThumb);

		visible = false;
	}

	public function setEntries(entries:Array<ConversationLogEntry>):Void
	{
		displayLines = buildDisplayLines(entries);
		panelDirty = true;
		rebuildLineHeights();
	}

	public function scrollToEnd():Void
	{
		scrollIndex = maxScrollIndex();
		refreshText();
	}

	public function setBounds(x:Float, y:Float, w:Float, h:Float, textSize:Int):Void
	{
		var dimChanged = Math.abs(areaW - w) > 0.5
			|| Math.abs(areaH - h) > 0.5
			|| fontSize != textSize;

		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;
		fontSize = textSize;
		timeSize = Std.int(Math.max(10, fontSize - 1));
		dialogueSize = fontSize;
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;
		textPad = Std.int(Math.max(8, w * 0.03));
		viewportH = h - textPad * 2;
		rebuildLineHeights();

		if (dimChanged)
		{
			panelDirty = true;
			layoutScrollbar();
			refresh();
		}
		else
		{
			drawPanel();
			repositionScrollbar();
			refreshText();
		}

		visible = true;
	}

	public function reposition(x:Float, y:Float, w:Float, h:Float):Void
	{
		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;
		viewportH = h - textPad * 2;
		rebuildLineHeights();
		drawPanel();
		repositionScrollbar();
		refreshText();
	}

	public function hide():Void
	{
		endDrag();
		visible = false;
		panelBg.visible = false;
		for (t in lineTexts)
			t.visible = false;
		scrollColumn.visible = false;
		scrollTrack.visible = false;
		scrollUpBtn.visible = false;
		scrollDownBtn.visible = false;
		scrollThumb.visible = false;
	}

	public function scrollBy(delta:Int):Void
	{
		if (delta == 0)
			return;

		var old = scrollIndex;
		scrollIndex += delta;
		clampScroll();
		if (scrollIndex != old)
			refreshText();
	}

	public function handleWheel(wheel:Float):Void
	{
		if (wheel == 0)
			return;
		scrollBy(wheel > 0 ? -1 : 1);
	}

	public function isInPanelArea(mx:Float, my:Float):Bool
	{
		return mx >= areaX && mx < areaX + areaW && my >= areaY && my < areaY + areaH;
	}

	public function handleClick(mx:Float, my:Float):Bool
	{
		if (!isScrollable() || !isOnScrollColumn(mx, my))
			return false;

		if (isOnScrollUpBtn(mx, my))
		{
			scrollBy(-1);
			return true;
		}
		if (isOnScrollDownBtn(mx, my))
		{
			scrollBy(1);
			return true;
		}
		if (tryStartThumbDrag(mx, my))
			return true;
		if (jumpScrollOnTrack(mx, my))
			return true;

		return true;
	}

	public function updateDrag(mx:Float, my:Float):Void
	{
		if (!thumbDragging)
			return;

		var maxScroll = maxScrollIndex();
		if (maxScroll == 0)
			return;

		var travel = trackH - thumbH;
		if (travel <= 0)
			return;

		var targetY = my - dragGrabY;
		var rel = (targetY - trackY) / travel;
		rel = FlxMath.bound(rel, 0, 1);

		var old = scrollIndex;
		scrollIndex = Std.int(Math.round(rel * maxScroll));
		clampScroll();
		if (scrollIndex != old)
			refreshText();
		else
			updateScrollbar();
	}

	public function endDrag():Void
	{
		thumbDragging = false;
	}

	function buildDisplayLines(entries:Array<ConversationLogEntry>):Array<ConversationDisplayLine>
	{
		var lines:Array<ConversationDisplayLine> = [];
		if (entries.length == 0)
		{
			lines.push({kind: Empty, text: "No recorded lines yet."});
			return lines;
		}

		for (i in 0...entries.length)
		{
			var entry = entries[i];
			lines.push({kind: Time, text: entry.time});
			lines.push({kind: Dialogue, text: entry.speaker + ": " + entry.message});
			if (i < entries.length - 1)
				lines.push({kind: Blank, text: ""});
		}

		return lines;
	}

	function rebuildLineHeights():Void
	{
		lineHeights = [];
		totalContentH = 0;
		var textW = Std.int(Math.max(40, contentW - textPad * 2));
		for (entry in displayLines)
		{
			var h = entryHeight(entry, textW);
			lineHeights.push(h);
			totalContentH += h;
		}
		clampScroll();
	}

	function entryHeight(entry:ConversationDisplayLine, textW:Int):Float
	{
		return switch (entry.kind)
		{
			case Time: timeSize + 2;
			case Dialogue: measureDialogueHeight(entry.text, textW);
			case Empty: dialogueSize + 6;
			case Blank: Math.max(6, dialogueSize * 0.45);
		}
	}

	function measureDialogueHeight(text:String, textW:Int):Float
	{
		measureText.text = text;
		measureText.setFormat(null, dialogueSize, MonitorScreenUi.GREEN, "left");
		measureText.fieldWidth = textW;
		measureText.wordWrap = true;
		measureText.scale.set(1, 1);
		var glyphH = measureText.textField.textHeight;
		return Math.max(dialogueSize + 2, glyphH + 4);
	}

	function heightFromIndex(start:Int):Float
	{
		var h = 0.0;
		for (i in start...displayLines.length)
			h += lineHeights[i];
		return h;
	}

	function refresh():Void
	{
		if (panelDirty || !panelBg.visible)
		{
			drawPanel();
			panelDirty = false;
		}
		layoutScrollbar();
		refreshText();
	}

	function refreshText():Void
	{
		var textW = Std.int(contentW - textPad * 2);
		var drawY = areaY + textPad;
		var slot = 0;

		for (i in scrollIndex...displayLines.length)
		{
			var entry = displayLines[i];
			var lh = lineHeights[i];
			if (drawY + lh > areaY + textPad + viewportH && slot > 0)
				break;

			var t = ensureLineText(slot);
			t.text = entry.text;
			t.fieldWidth = textW;
			t.wordWrap = entry.kind == Dialogue;
			t.scale.set(1, 1);
			t.setPosition(areaX + textPad, drawY);

			switch (entry.kind)
			{
				case Time:
					t.setFormat(null, timeSize, MonitorScreenUi.GREEN_DIM, "left");
					t.visible = true;
				case Dialogue:
					t.setFormat(null, dialogueSize, MonitorScreenUi.GREEN, "left");
					t.visible = true;
				case Empty:
					t.setFormat(null, dialogueSize, MonitorScreenUi.GREEN_DIM, "left");
					t.visible = true;
				case Blank:
					t.visible = false;
			}

			drawY += lh;
			slot++;
		}

		for (i in slot...lineTexts.length)
			lineTexts[i].visible = false;

		updateScrollbar();
	}

	function ensureLineText(slot:Int):FlxText
	{
		while (lineTexts.length <= slot)
		{
			var t = new FlxText(0, 0, 100, "");
			lineTexts.push(t);
			textLayer.add(t);
		}
		return lineTexts[slot];
	}

	function drawPanel():Void
	{
		var panelW = Std.int(areaW);
		var panelH = Std.int(areaH);
		panelBg.setPosition(areaX, areaY);
		panelBg.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(panelBg, panelW, panelH, MonitorScreenUi.GREEN, 2);
		panelBg.updateHitbox();
		panelBg.visible = true;
	}

	function layoutScrollbar():Void
	{
		repositionScrollbar();
	}

	function repositionScrollbar():Void
	{
		scrollX = areaX + contentW + 4;
		trackY = areaY + BTN_H;
		trackH = areaH - BTN_H * 2;
		drawScrollColumn();
		scrollUpBtn.setPosition(scrollX, areaY);
		scrollTrack.setPosition(scrollX + 1, trackY);
		scrollDownBtn.setPosition(scrollX, areaY + areaH - BTN_H);
		updateScrollbar();
	}

	function drawScrollColumn():Void
	{
		var colH = Std.int(areaH);
		scrollColumn.setPosition(scrollX, areaY);
		scrollColumn.makeGraphic(SCROLL_W, colH, 0xFF0A120E, true);
		drawRectBorder(scrollColumn, SCROLL_W, colH, MonitorScreenUi.GREEN_DIM, 1);
		scrollColumn.updateHitbox();
		scrollColumn.visible = displayLines.length > 0;

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.visible = displayLines.length > 0;
		scrollUpBtn.visible = displayLines.length > 0;
		scrollDownBtn.visible = displayLines.length > 0;
	}

	function updateScrollbar():Void
	{
		trackY = areaY + BTN_H;
		trackH = areaH - BTN_H * 2;

		if (displayLines.length == 0)
		{
			scrollColumn.visible = false;
			scrollTrack.visible = false;
			scrollUpBtn.visible = false;
			scrollDownBtn.visible = false;
			scrollThumb.visible = false;
			return;
		}

		scrollColumn.visible = true;
		scrollTrack.visible = true;
		scrollUpBtn.visible = true;
		scrollDownBtn.visible = true;

		if (!isScrollable())
		{
			scrollThumb.visible = false;
			return;
		}

		var maxScroll = maxScrollIndex();
		thumbH = Std.int(Math.max(14, trackH * viewportH / totalContentH));
		var travel = trackH - thumbH;
		var thumbY = trackY + travel * (scrollIndex / maxScroll);

		scrollThumb.visible = true;
		if (thumbH != lastThumbH)
		{
			lastThumbH = thumbH;
			scrollThumb.makeGraphic(SCROLL_W - 6, thumbH, MonitorScreenUi.GREEN, true);
			drawRectBorder(scrollThumb, SCROLL_W - 6, thumbH, MonitorScreenUi.GREEN_BRIGHT, 1);
			scrollThumb.updateHitbox();
		}
		scrollThumb.setPosition(scrollX + 3, thumbY);
	}

	function tryStartThumbDrag(mx:Float, my:Float):Bool
	{
		if (!scrollThumb.visible || !isOnScrollTrack(mx, my))
			return false;

		if (my < scrollThumb.y || my > scrollThumb.y + scrollThumb.height)
			return false;

		thumbDragging = true;
		dragGrabY = my - scrollThumb.y;
		return true;
	}

	function jumpScrollOnTrack(mx:Float, my:Float):Bool
	{
		if (!isScrollable() || !isOnScrollTrack(mx, my))
			return false;

		if (scrollThumb.visible && my >= scrollThumb.y && my <= scrollThumb.y + scrollThumb.height)
			return false;

		var maxScroll = maxScrollIndex();
		if (maxScroll == 0)
			return false;

		var travel = trackH - thumbH;
		if (travel <= 0)
			return false;

		var rel = (my - trackY - thumbH * 0.5) / travel;
		rel = FlxMath.bound(rel, 0, 1);

		var old = scrollIndex;
		scrollIndex = Std.int(Math.round(rel * maxScroll));
		clampScroll();
		if (scrollIndex != old)
			refreshText();
		else
			updateScrollbar();

		return true;
	}

	function set_scrollIndex(v:Int):Int
	{
		scrollIndex = v;
		return v;
	}

	function clampScroll():Void
	{
		scrollIndex = Std.int(FlxMath.bound(scrollIndex, 0, maxScrollIndex()));
	}

	function maxScrollIndex():Int
	{
		if (displayLines.length == 0)
			return 0;

		for (start in 0...displayLines.length)
		{
			if (heightFromIndex(start) <= viewportH + 0.5)
				return start;
		}

		return Std.int(Math.max(0, displayLines.length - 1));
	}

	function isScrollable():Bool
	{
		return totalContentH > viewportH + 0.5;
	}

	function isOnScrollColumn(mx:Float, my:Float):Bool
	{
		return mx >= scrollX && mx < scrollX + SCROLL_W && my >= areaY && my < areaY + areaH;
	}

	function isOnScrollUpBtn(mx:Float, my:Float):Bool
	{
		return mx >= scrollX && mx < scrollX + SCROLL_W && my >= areaY && my < areaY + BTN_H;
	}

	function isOnScrollDownBtn(mx:Float, my:Float):Bool
	{
		return my >= areaY + areaH - BTN_H && my < areaY + areaH && mx >= scrollX && mx < scrollX + SCROLL_W;
	}

	function isOnScrollTrack(mx:Float, my:Float):Bool
	{
		return mx >= scrollX && mx < scrollX + SCROLL_W && my >= trackY && my < trackY + trackH;
	}

	function drawTriangleBtn(btn:FlxSprite, w:Int, h:Int, up:Bool):Void
	{
		btn.makeGraphic(w, h, 0xFF0D1A12, true);
		drawRectBorder(btn, w, h, MonitorScreenUi.GREEN_DIM, 1);

		var cx = Std.int(w * 0.5);
		var cy = Std.int(h * 0.5);
		var color = MonitorScreenUi.GREEN;

		for (i in 0...6)
		{
			var half = up ? i : (5 - i);
			var y = up ? (cy - 1 + i) : (cy - 4 + i);
			if (half >= 0)
				btn.pixels.fillRect(new Rectangle(cx - half, y, half * 2 + 1, 1), color);
		}

		btn.dirty = true;
		btn.updateHitbox();
		btn.visible = true;
	}

	function drawRectBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}
}
