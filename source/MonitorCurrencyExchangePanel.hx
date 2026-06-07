package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

typedef CurrencyMarket =
{
	code:String,
	name:String,
	center:Float,
	microPos:Float,
	microValue:Int,
	tickTimer:Float,
	tickInterval:Float,
}

class MonitorCurrencyExchangePanel extends FlxGroup
{
	static inline var SCROLL_W = 18;
	static inline var BTN_H = 16;
	static inline var ROW_GAP = 8;
	static inline var MICRO_TICKER = 0xFF7DFFB3;
	static inline var MICRO_FLASH = 0xFFB8FFD4;
	static inline var BAND_LOW = 0.2;
	static inline var BAND_HIGH = 0.8;
	static inline var MICRO_MIN = 200;
	static inline var MICRO_MAX = 799;

	public var scrollIndex(default, set) = 0;

	var markets:Array<CurrencyMarket> = [];
	var panelBg:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var rowLayer:FlxGroup;
	var scrollLayer:FlxGroup;
	var scrollColumn:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var scrollUpBtn:FlxSprite;
	var scrollDownBtn:FlxSprite;
	var rowCodes:Array<FlxText> = [];
	var rowNames:Array<FlxText> = [];
	var rowRateLabels:Array<FlxText> = [];
	var rowRateValues:Array<FlxText> = [];
	var rowRateMicros:Array<FlxText> = [];
	var rowRateCodes:Array<FlxText> = [];
	var rateValueX:Array<Float> = [];
	var rateMicroX:Array<Float> = [];
	var rateCodeX:Array<Float> = [];
	var microFlash:Array<Float> = [];
	var measureText:FlxText;

	var areaX:Float = 0;
	var areaY:Float = 0;
	var areaW:Float = 0;
	var areaH:Float = 0;
	var fontSize = 12;
	var lastPanelW = -1.0;
	var lastPanelH = -1.0;

	var pad = 8;
	var contentW = 0;
	var leftX = 0.0;
	var scrollX = 0.0;
	var listTop = 0.0;
	var listBottom = 0.0;
	var viewportH = 0.0;
	var rowH = 0.0;
	var totalContentH = 0.0;
	var codeSize = 12;
	var nameSize = 11;
	var rateLabelSize = 11;
	var rateValueSize = 15;
	var rateMicroSize = 12;
	var rateCodeSize = 11;
	var headerLineH = 0.0;
	var rateLineH = 0.0;
	var codeColW = 0;
	var rateLabelColW = 0;
	var rateMicroColW = 0;
	var rateCodeColW = 0;
	var thumbDragging = false;
	var dragGrabY = 0.0;
	var thumbH = 12;
	var trackY = 0.0;
	var trackH = 0.0;
	var lastThumbH = -1;

	public function new()
	{
		super();
		markets = buildMarkets();

		panelBg = new FlxSprite();
		titleText = makeText("", MonitorScreenUi.GREEN_BRIGHT, "center");
		subtitleText = makeText("", MonitorScreenUi.GREEN_DIM, "center");
		measureText = makeText("", MonitorScreenUi.GREEN, "left");
		measureText.visible = false;
		rowLayer = new FlxGroup();
		scrollLayer = new FlxGroup();
		scrollColumn = new FlxSprite();
		scrollTrack = new FlxSprite();
		scrollThumb = new FlxSprite();
		scrollUpBtn = new FlxSprite();
		scrollDownBtn = new FlxSprite();

		add(panelBg);
		add(titleText);
		add(subtitleText);
		add(rowLayer);
		add(scrollLayer);
		scrollLayer.add(scrollColumn);
		scrollLayer.add(scrollTrack);
		scrollLayer.add(scrollUpBtn);
		scrollLayer.add(scrollDownBtn);
		scrollLayer.add(scrollThumb);

		for (i in 0...markets.length)
		{
			rowCodes.push(makeText("", MonitorScreenUi.GREEN_BRIGHT, "left"));
			rowNames.push(makeText("", MonitorScreenUi.GREEN_DIM, "left"));
			rowRateLabels.push(makeText("", MonitorScreenUi.GREEN_DIM, "left"));
			rowRateValues.push(makeText("", MonitorScreenUi.GREEN_BRIGHT, "left"));
			rowRateMicros.push(makeText("", MICRO_TICKER, "left"));
			rowRateCodes.push(makeText("", MonitorScreenUi.GREEN, "left"));
			rateValueX.push(0);
			rateMicroX.push(0);
			rateCodeX.push(0);
			microFlash.push(0);

			rowLayer.add(rowCodes[i]);
			rowLayer.add(rowNames[i]);
			rowLayer.add(rowRateLabels[i]);
			rowLayer.add(rowRateValues[i]);
			rowLayer.add(rowRateMicros[i]);
			rowLayer.add(rowRateCodes[i]);
		}

		visible = false;
	}

	public function setBounds(x:Float, y:Float, w:Float, h:Float, textSize:Int):Void
	{
		fontSize = textSize;
		scrollIndex = 0;
		resetMarkets();
		visible = true;
		setArea(x, y, w, h, true);
	}

	public function reposition(x:Float, y:Float, w:Float, h:Float):Void
	{
		var resized = Math.abs(areaW - w) > 0.5 || Math.abs(areaH - h) > 0.5;
		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;

		if (resized)
		{
			setArea(x, y, w, h, true);
			return;
		}

		leftX = areaX + pad;
		scrollX = areaX + areaW - pad - SCROLL_W;
		panelBg.setPosition(areaX, areaY);
		layoutHeader();
		listTop = subtitleText.y + subtitleText.height + pad;
		listBottom = areaY + areaH - pad;
		repositionScrollbar();
		refreshRows();
	}

	public function hide():Void
	{
		endDrag();
		visible = false;
		panelBg.visible = false;
		titleText.visible = false;
		subtitleText.visible = false;
		hideAllRows();
		hideScrollbar();
	}

	public function updateTick(elapsed:Float):Void
	{
		if (!visible)
			return;

		for (i in 0...markets.length)
		{
			if (microFlash[i] > 0)
			{
				microFlash[i] -= elapsed;
				if (microFlash[i] <= 0)
					rowRateMicros[i].color = MICRO_TICKER;
			}
		}

		for (i in 0...markets.length)
		{
			var m = markets[i];
			m.tickTimer -= elapsed;
			if (m.tickTimer > 0)
				continue;

			m.tickTimer = m.tickInterval * (0.85 + Math.random() * 0.3);
			stepMarket(m);
			applyMarketRowMicro(i, true);
		}
	}

	public function scrollBy(delta:Int):Void
	{
		if (delta == 0)
			return;

		var old = scrollIndex;
		scrollIndex += delta;
		clampScroll();
		if (scrollIndex != old)
			refreshRows();
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
			refreshRows();
		else
			updateScrollbar();
	}

	public function endDrag():Void
	{
		thumbDragging = false;
	}

	static function buildMarkets():Array<CurrencyMarket>
	{
		return [
			makeMarket("VAL", "Kingdom of Valdoria", 0.27, 2.1),
			makeMarket("KTH", "Kethran Federation", 68.42, 3.1),
			makeMarket("MRD", "Meridian Commonwealth", 34.17, 3.9),
			makeMarket("OST", "Ostmark Concordat", 157.83, 5.25)
		];
	}

	static function makeMarket(code:String, name:String, center:Float, tickInterval:Float):CurrencyMarket
	{
		return {
			code: code,
			name: name,
			center: center,
			microPos: 0.45 + Math.random() * 0.1,
			microValue: MICRO_MIN + Std.int(Math.random() * (MICRO_MAX - MICRO_MIN)),
			tickTimer: Math.random() * tickInterval,
			tickInterval: tickInterval
		};
	}

	function resetMarkets():Void
	{
		markets = buildMarkets();
		for (m in markets)
		{
			m.microPos = 0.45 + Math.random() * 0.1;
			m.microValue = microTarget(m.microPos);
			m.tickTimer = Math.random() * m.tickInterval;
		}
	}

	function stepMarket(m:CurrencyMarket):Void
	{
		var pull = (0.5 - m.microPos) * 0.05;
		m.microPos += pull + (Math.random() - 0.5) * 0.025;
		m.microPos = FlxMath.bound(m.microPos, BAND_LOW, BAND_HIGH);

		var target = microTarget(m.microPos);
		var step = Std.int((target - m.microValue) * 0.12 + (Math.random() - 0.5) * 12);
		m.microValue = Std.int(FlxMath.bound(m.microValue + step, MICRO_MIN, MICRO_MAX));
	}

	function microTarget(pos:Float):Int
	{
		var rel = (pos - BAND_LOW) / (BAND_HIGH - BAND_LOW);
		rel = FlxMath.bound(rel, 0, 1);
		return MICRO_MIN + Std.int((MICRO_MAX - MICRO_MIN) * rel);
	}

	function setArea(x:Float, y:Float, w:Float, h:Float, relayout:Bool):Void
	{
		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;

		if (relayout || lastPanelW != w || lastPanelH != h)
		{
			lastPanelW = w;
			lastPanelH = h;
			drawPanel();
			layoutContent();
		}
		else
			panelBg.setPosition(areaX, areaY);
	}

	function layoutContent():Void
	{
		pad = Std.int(Math.max(8, areaW * 0.04));
		contentW = Std.int(areaW - pad * 2 - SCROLL_W - 4);
		leftX = areaX + pad;
		scrollX = areaX + areaW - pad - SCROLL_W;

		codeSize = fontSize;
		nameSize = Std.int(Math.max(9, fontSize - 1));
		rateLabelSize = Std.int(Math.max(9, fontSize - 1));
		rateValueSize = fontSize + Std.int(Math.max(3, fontSize * 0.32));
		rateMicroSize = fontSize + 1;
		rateCodeSize = fontSize;
		headerLineH = codeSize + 4;
		rateLineH = rateValueSize + 4;
		rowH = headerLineH + rateLineH + ROW_GAP;
		totalContentH = contentHeightFromIndex(0);

		codeColW = Std.int(textWidth("OST", codeSize) + 8);
		rateLabelColW = Std.int(textWidth("1 LOR = ", rateLabelSize) + 4);
		rateMicroColW = Std.int(textWidth("999", rateMicroSize) + 4);
		rateCodeColW = Std.int(textWidth("OST", rateCodeSize) + 8);

		layoutHeader();
		listTop = subtitleText.y + subtitleText.height + pad;
		listBottom = areaY + areaH - pad;
		viewportH = listBottom - listTop;
		if (viewportH < 1)
			viewportH = 1;

		clampScroll();
		for (i in 0...markets.length)
			layoutRow(i);

		repositionScrollbar();
		refreshRows();
	}

	function layoutHeader():Void
	{
		var innerFullW = Std.int(areaW - pad * 2);
		var titleSize = codeSize + 2;

		setText(titleText, "CURRENCY EXCHANGE", titleSize, MonitorScreenUi.GREEN_BRIGHT, "center", innerFullW);
		setText(subtitleText, "Live spot rates · 1 LOR buys", nameSize, MonitorScreenUi.GREEN_DIM, "center", innerFullW);

		titleText.setPosition(leftX, areaY + pad);
		titleText.visible = true;
		subtitleText.setPosition(leftX, titleText.y + titleText.height + 4);
		subtitleText.visible = true;
	}

	function layoutRow(i:Int):Void
	{
		var m = markets[i];
		var nameColW = Std.int(Math.max(40, contentW - codeColW));

		setText(rowCodes[i], m.code, codeSize, MonitorScreenUi.GREEN_BRIGHT, "left", 0);
		setText(rowNames[i], m.name, nameSize, MonitorScreenUi.GREEN_DIM, "left", nameColW);
		setText(rowRateLabels[i], "1 LOR = ", rateLabelSize, MonitorScreenUi.GREEN_DIM, "left", 0);
		applyMarketRow(i, false);
	}

	function applyMarketRow(i:Int, flash:Bool):Void
	{
		var m = markets[i];
		var mainStr = formatCenterMain(m.center);

		setText(rowRateValues[i], mainStr, rateValueSize, MonitorScreenUi.GREEN_BRIGHT, "left", contentW);
		rateValueX[i] = rateLabelColW;
		rateMicroX[i] = rateValueX[i] + textWidth(mainStr, rateValueSize);
		rateCodeX[i] = rateMicroX[i] + rateMicroColW;

		setText(rowRateCodes[i], m.code, rateCodeSize, MonitorScreenUi.GREEN, "left", 0);
		applyMarketRowMicro(i, flash);
	}

	function applyMarketRowMicro(i:Int, flash:Bool):Void
	{
		var m = markets[i];
		var microStr = formatMicroValue(m.microValue);

		setText(rowRateMicros[i], microStr, rateMicroSize, flash ? MICRO_FLASH : MICRO_TICKER, "left", 0);
		rateCodeX[i] = rateMicroX[i] + textWidth(microStr, rateMicroSize);

		var maxCodeX = contentW - rateCodeColW;
		if (rateCodeX[i] > maxCodeX)
			rateCodeX[i] = maxCodeX;

		if (flash)
			microFlash[i] = 0.12;
	}

	function refreshRows():Void
	{
		for (i in 0...markets.length)
		{
			if (i < scrollIndex)
			{
				hideRow(i);
				continue;
			}

			var rowY = listTop + (i - scrollIndex) * rowH;
			if (rowY + headerLineH + rateLineH > listBottom + 0.5)
			{
				hideRow(i);
				continue;
			}

			positionRow(i, rowY);
		}

		updateScrollbar();
	}

	function positionRow(i:Int, rowY:Float):Void
	{
		var headerY = rowY;
		var rateY = rowY + headerLineH;

		rowCodes[i].setPosition(leftX, headerY);
		rowCodes[i].visible = true;

		rowNames[i].setPosition(leftX + codeColW, headerY + (codeSize - nameSize) * 0.5);
		rowNames[i].visible = true;

		rowRateLabels[i].setPosition(leftX, rateY + (rateValueSize - rateLabelSize) * 0.5);
		rowRateLabels[i].visible = true;

		rowRateValues[i].setPosition(leftX + rateValueX[i], rateY);
		rowRateValues[i].visible = true;

		rowRateMicros[i].setPosition(leftX + rateMicroX[i], rateY + rateValueSize - rateMicroSize - 2);
		rowRateMicros[i].visible = true;

		rowRateCodes[i].setPosition(leftX + rateCodeX[i], rateY + (rateValueSize - rateCodeSize) * 0.5);
		rowRateCodes[i].visible = true;
	}

	function hideRow(i:Int):Void
	{
		rowCodes[i].visible = false;
		rowNames[i].visible = false;
		rowRateLabels[i].visible = false;
		rowRateValues[i].visible = false;
		rowRateMicros[i].visible = false;
		rowRateCodes[i].visible = false;
	}

	function hideAllRows():Void
	{
		for (i in 0...markets.length)
			hideRow(i);
	}

	function formatCenterMain(center:Float):String
	{
		var fixed = Std.int(Math.round(center * 100 + 0.0001));
		var whole = Std.int(Math.floor(fixed / 100));
		var frac = fixed % 100;
		var fracStr = frac < 10 ? "0" + frac : Std.string(frac);
		return whole + "." + fracStr;
	}

	function formatMicroValue(micro:Int):String
	{
		var v = Std.int(FlxMath.bound(micro, 0, 999));
		var s = Std.string(v);
		while (s.length < 3)
			s = "0" + s;
		return s;
	}

	function textWidth(text:String, size:Int):Float
	{
		measureText.text = text;
		measureText.setFormat(null, size, MonitorScreenUi.GREEN, "left");
		measureText.fieldWidth = 0;
		measureText.wordWrap = false;
		measureText.scale.set(1, 1);
		return measureText.width;
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

	function repositionScrollbar():Void
	{
		trackY = listTop;
		trackH = listBottom - listTop;
		if (trackH < BTN_H * 2 + 4)
			trackH = BTN_H * 2 + 4;

		scrollColumn.setPosition(scrollX, listTop);
		scrollColumn.makeGraphic(SCROLL_W, Std.int(trackH), 0xFF0A120E, true);
		drawRectBorder(scrollColumn, SCROLL_W, Std.int(trackH), MonitorScreenUi.GREEN_DIM, 1);
		scrollColumn.updateHitbox();

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		scrollUpBtn.setPosition(scrollX, listTop);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH - BTN_H * 2));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.setPosition(scrollX + 1, listTop + BTN_H);

		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);
		scrollDownBtn.setPosition(scrollX, listTop + trackH - BTN_H);

		updateScrollbar();
	}

	function updateScrollbar():Void
	{
		if (!visible)
			return;

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
		thumbH = Std.int(Math.max(14, (trackH - BTN_H * 2) * viewportH / totalContentH));
		var travel = trackH - BTN_H * 2 - thumbH;
		var thumbY = listTop + BTN_H + travel * (scrollIndex / maxScroll);

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

	function hideScrollbar():Void
	{
		scrollColumn.visible = false;
		scrollTrack.visible = false;
		scrollUpBtn.visible = false;
		scrollDownBtn.visible = false;
		scrollThumb.visible = false;
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

		var travel = trackH - BTN_H * 2 - thumbH;
		if (travel <= 0)
			return false;

		var rel = (my - listTop - BTN_H - thumbH * 0.5) / travel;
		rel = FlxMath.bound(rel, 0, 1);

		var old = scrollIndex;
		scrollIndex = Std.int(Math.round(rel * maxScroll));
		clampScroll();
		if (scrollIndex != old)
			refreshRows();
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

	function contentHeightFromIndex(start:Int):Float
	{
		var count = markets.length - start;
		if (count <= 0)
			return 0;

		return (count - 1) * rowH + headerLineH + rateLineH;
	}

	function maxScrollIndex():Int
	{
		if (markets.length == 0)
			return 0;

		for (start in 0...markets.length)
		{
			if (contentHeightFromIndex(start) <= viewportH + 0.5)
				return start;
		}

		return Std.int(Math.max(0, markets.length - 1));
	}

	function isScrollable():Bool
	{
		return totalContentH > viewportH + 0.5;
	}

	function isOnScrollColumn(mx:Float, my:Float):Bool
	{
		return mx >= scrollX && mx < scrollX + SCROLL_W && my >= listTop && my < listBottom;
	}

	function isOnScrollUpBtn(mx:Float, my:Float):Bool
	{
		return isOnScrollColumn(mx, my) && my >= listTop && my < listTop + BTN_H;
	}

	function isOnScrollDownBtn(mx:Float, my:Float):Bool
	{
		return isOnScrollColumn(mx, my) && my >= listTop + trackH - BTN_H && my < listBottom;
	}

	function isOnScrollTrack(mx:Float, my:Float):Bool
	{
		return isOnScrollColumn(mx, my) && my >= listTop + BTN_H && my < listTop + trackH - BTN_H;
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

	function makeText(text:String, color:Int, align:String):FlxText
	{
		var t = new FlxText(0, 0, 0, text);
		t.setFormat(null, fontSize, color, align);
		t.wordWrap = false;
		return t;
	}

	function setText(t:FlxText, text:String, size:Int, color:Int, align:String, fieldWidth:Int):Void
	{
		t.text = text;
		t.setFormat(null, size, color, align);
		t.fieldWidth = fieldWidth > 0 ? fieldWidth : Std.int(textWidth(text, size));
		t.wordWrap = false;
		t.scale.set(1, 1);
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
