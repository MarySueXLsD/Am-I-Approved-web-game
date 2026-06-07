package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

enum CreditLineKind
{
	Title;
	Role;
	Name;
	Blank;
}

typedef CreditLine =
{
	kind:CreditLineKind,
	text:String,
}

class MonitorCreditsPanel extends FlxGroup
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
	var titleSize = 18;
	var roleSize = 14;
	var nameSize = 12;
	var creditLines:Array<CreditLine> = [];
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

		add(panelBg);
		add(textLayer);
		add(scrollLayer);
		scrollLayer.add(scrollColumn);
		scrollLayer.add(scrollTrack);
		scrollLayer.add(scrollUpBtn);
		scrollLayer.add(scrollDownBtn);
		scrollLayer.add(scrollThumb);

		setDefaultCredits();
		visible = false;
	}

	public function setDefaultCredits():Void
	{
		setCredits([
			{kind: Title, text: "CoolMath Bank"},
			{kind: Blank, text: ""},
			{kind: Role, text: "GameDesigner / Programmer"},
			{kind: Name, text: "Viktar Syanau (MarySue)"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Artist"},
			{kind: Name, text: "TBD"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Composer / Audio Effects"},
			{kind: Name, text: "Bohdan Potomskyi (retipupu)"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Scenarist"},
			{kind: Name, text: "Serik - Al Farabiuly Yerasyl"},
			{kind: Blank, text: ""},
			{kind: Blank, text: ""},
			{kind: Role, text: "Special Thanks to"},
			{kind: Name, text: "Vadzim Trayeuski (HonieHomie)"},
			{kind: Name, text: "Muhammad Bakanaev (Senshi)"},
			{kind: Name, text: "Muzafar Bektas (horseatersson)"}
		]);
	}

	public function setCredits(entries:Array<CreditLine>):Void
	{
		creditLines = entries;
		scrollIndex = 0;
		panelDirty = true;
		rebuildLineHeights();
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
		updateFontSizes();
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

	function updateFontSizes():Void
	{
		nameSize = fontSize;
		roleSize = fontSize + Std.int(Math.max(2, fontSize * 0.22));
		titleSize = fontSize + Std.int(Math.max(5, fontSize * 0.55));
	}

	function rebuildLineHeights():Void
	{
		lineHeights = [];
		totalContentH = 0;
		for (entry in creditLines)
		{
			var h = entryHeight(entry);
			lineHeights.push(h);
			totalContentH += h;
		}
		clampScroll();
	}

	function entryHeight(entry:CreditLine):Float
	{
		return switch (entry.kind)
		{
			case Title: titleSize + 5;
			case Role: roleSize + 3;
			case Name: nameSize + 2;
			case Blank: Math.max(6, nameSize * 0.45);
		}
	}

	function entryTextSize(entry:CreditLine):Int
	{
		return switch (entry.kind)
		{
			case Title: titleSize;
			case Role: roleSize;
			case Name: nameSize;
			case Blank: nameSize;
		}
	}

	function entryColor(entry:CreditLine):Int
	{
		return switch (entry.kind)
		{
			case Title: MonitorScreenUi.GREEN_BRIGHT;
			default: MonitorScreenUi.GREEN;
		}
	}

	function heightFromIndex(start:Int):Float
	{
		var h = 0.0;
		for (i in start...creditLines.length)
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

		for (i in scrollIndex...creditLines.length)
		{
			var entry = creditLines[i];
			var lh = lineHeights[i];
			if (drawY + lh > areaY + textPad + viewportH && slot > 0)
				break;

			var t = ensureLineText(slot);
			if (entry.kind == Blank)
			{
				t.visible = false;
			}
			else
			{
				var size = entryTextSize(entry);
				t.text = entry.text;
				t.setFormat(null, size, entryColor(entry), "center");
				t.fieldWidth = textW;
				t.scale.set(1, 1);
				t.setPosition(areaX + textPad, drawY);
				t.visible = true;
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
		scrollColumn.visible = creditLines.length > 0;

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.visible = creditLines.length > 0;
		scrollUpBtn.visible = creditLines.length > 0;
		scrollDownBtn.visible = creditLines.length > 0;
	}

	function updateScrollbar():Void
	{
		trackY = areaY + BTN_H;
		trackH = areaH - BTN_H * 2;

		if (creditLines.length == 0)
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
		if (creditLines.length == 0)
			return 0;

		for (start in 0...creditLines.length)
		{
			if (heightFromIndex(start) <= viewportH + 0.5)
				return start;
		}

		return Std.int(Math.max(0, creditLines.length - 1));
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
