package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import openfl.geom.Rectangle;

class MonitorClientList extends FlxGroup
{
	static inline var SCROLL_W = 18;
	static inline var BTN_H = 16;

	public var scrollIndex(default, set) = 0;

	var rows:Array<MonitorListRow> = [];
	var rowLayer:FlxGroup;
	var dividerLayer:FlxGroup;
	var labelLayer:FlxGroup;
	var scrollLayer:FlxGroup;
	var scrollColumn:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var scrollUpBtn:FlxSprite;
	var scrollDownBtn:FlxSprite;
	var listBg:FlxSprite;
	var listDivider:FlxSprite;

	var areaX:Float = 0;
	var areaY:Float = 0;
	var areaW:Float = 0;
	var areaH:Float = 0;
	var contentW:Float = 0;
	var scrollX:Float = 0;
	var rowHeight = 20;
	var fontSize = 12;
	var visibleCount = 1;
	var filtered:Array<Citizen> = [];
	var hoveredRow = -1;
	var lastRenderedScroll = -1;
	var lastRenderedCount = -1;
	var thumbDragging = false;
	var dragGrabY = 0.0;
	var thumbH = 12;
	var trackY = 0.0;
	var trackH = 0.0;
	var lastThumbH = -1;

	public function new()
	{
		super();

		rowLayer = new FlxGroup();
		dividerLayer = new FlxGroup();
		labelLayer = new FlxGroup();
		scrollLayer = new FlxGroup();
		add(rowLayer);
		add(dividerLayer);
		add(labelLayer);
		add(scrollLayer);

		listBg = new FlxSprite();
		listDivider = new FlxSprite();
		scrollColumn = new FlxSprite();
		scrollTrack = new FlxSprite();
		scrollThumb = new FlxSprite();
		scrollUpBtn = new FlxSprite();
		scrollDownBtn = new FlxSprite();

		rowLayer.add(listBg);
		dividerLayer.add(listDivider);
		scrollLayer.add(scrollColumn);
		scrollLayer.add(scrollTrack);
		scrollLayer.add(scrollUpBtn);
		scrollLayer.add(scrollDownBtn);
		scrollLayer.add(scrollThumb);

		visible = false;
	}

	public function getAreaBounds():TutorialGuideRect
	{
		return {x: areaX, y: areaY, w: contentW, h: areaH};
	}

	public function getRowBoundsForDataIndex(dataIndex:Int):Null<TutorialGuideRect>
	{
		for (row in rows)
		{
			if (!row.visible || row.dataIndex != dataIndex)
				continue;
			return {x: row.bg.x, y: row.bg.y, w: row.bg.width, h: row.bg.height};
		}
		return null;
	}

	public function findDataIndexForCitizen(citizen:Citizen):Int
	{
		for (i in 0...filtered.length)
		{
			if (filtered[i] == citizen)
				return i;
		}
		return -1;
	}

	public function setBounds(x:Float, y:Float, w:Float, h:Float, rowH:Int, textSize:Int):Void
	{
		var dimChanged = Math.abs(areaW - w) > 0.5
			|| Math.abs(areaH - h) > 0.5
			|| rowHeight != rowH
			|| fontSize != textSize;

		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;
		rowHeight = rowH;
		fontSize = textSize;
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;
		visibleCount = Std.int(Math.max(1, (h - 8) / rowHeight));

		listBg.setPosition(x, y);

		if (dimChanged)
		{
			drawListPanel();
			layoutScrollbar();
			ensureRowPool(visibleCount);
			markDirty();
			refresh();
		}
		else
		{
			drawListPanel();
			repositionScrollbar();
			refreshRowPositions();
		}

		visible = true;
	}

	function refreshRowPositions():Void
	{
		if (filtered.length == 0)
			return;

		var end = Std.int(Math.min(filtered.length, scrollIndex + visibleCount));
		var slot = 0;
		for (i in scrollIndex...end)
		{
			var row = rows[slot];
			var ry = areaY + 4 + slot * rowHeight;
			row.bg.setPosition(areaX + 2, ry);
			row.dataIndex = i;
			row.layout(areaX + 2, ry, contentW - 4, rowHeight, filtered[i], fontSize, i == hoveredRow);
			slot++;
		}
		updateScrollbar();
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

	public function setData(items:Array<Citizen>):Void
	{
		filtered = items;
		scrollIndex = 0;
		hoveredRow = -1;
		clampScroll();
		markDirty();
		refresh();
	}

	public function applyData(items:Array<Citizen>):Void
	{
		filtered = items;
		clampScroll();
		markDirty();
		refresh();
	}

	public function scrollBy(delta:Int):Void
	{
		if (delta == 0)
			return;
		var old = scrollIndex;
		scrollIndex += delta;
		clampScroll();
		if (scrollIndex != old)
			refresh();
	}

	public function handleWheel(wheel:Float):Void
	{
		if (wheel == 0)
			return;
		scrollBy(wheel > 0 ? -1 : 1);
	}

	public function isInListArea(mx:Float, my:Float):Bool
	{
		return mx >= areaX && mx < areaX + areaW && my >= areaY && my < areaY + areaH;
	}

	public function trySelectRow(mx:Float, my:Float):Int
	{
		if (!isInListArea(mx, my) || isOnScrollColumn(mx, my))
			return -1;

		for (row in rows)
		{
			if (!row.visible || row.dataIndex < 0)
				continue;
			if (row.overlaps(mx, my))
				return row.dataIndex;
		}
		return -1;
	}

	public function handleClick(mx:Float, my:Float):Bool
	{
		if (isScrollable() && isOnScrollColumn(mx, my))
		{
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

		if (trySelectRow(mx, my) >= 0)
			return true;

		return isInListArea(mx, my);
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
			refresh();
		else
			updateScrollbar();
	}

	public function endDrag():Void
	{
		thumbDragging = false;
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
			return true;

		var travel = trackH - thumbH;
		if (travel <= 0)
			return true;

		var rel = (my - trackY - thumbH * 0.5) / travel;
		rel = FlxMath.bound(rel, 0, 1);

		var old = scrollIndex;
		scrollIndex = Std.int(Math.round(rel * maxScroll));
		clampScroll();
		if (scrollIndex != old)
			refresh();
		else
			updateScrollbar();
		return true;
	}

	public function updateHover(mx:Float, my:Float):Void
	{
		var next = -1;
		for (row in rows)
		{
			if (!row.visible)
				continue;
			if (row.overlaps(mx, my))
			{
				next = row.dataIndex;
				break;
			}
		}

		if (next == hoveredRow)
			return;

		hoveredRow = next;
		refreshRowStyles();
	}

	function refreshRowStyles():Void
	{
		for (row in rows)
		{
			if (!row.visible || row.dataIndex < 0)
				continue;
			var hovered = row.dataIndex == hoveredRow;
			var citizen = filtered[row.dataIndex];
			row.layout(areaX + 2, row.bg.y, contentW - 4, rowHeight, citizen, fontSize, hovered);
		}
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
		return Std.int(Math.max(0, filtered.length - visibleCount));
	}

	function isScrollable():Bool
	{
		return filtered.length > visibleCount;
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

	function markDirty():Void
	{
		lastRenderedScroll = -1;
		lastRenderedCount = -1;
	}

	function refresh():Void
	{
		if (filtered.length == lastRenderedCount && scrollIndex == lastRenderedScroll)
		{
			refreshRowStyles();
			updateScrollbar();
			return;
		}

		lastRenderedCount = filtered.length;
		lastRenderedScroll = scrollIndex;

		if (filtered.length == 0)
		{
			for (row in rows)
				row.visible = false;
			showEmptyState();
			drawListPanel();
			updateScrollbar();
			return;
		}

		ensureRowPool(visibleCount);
		var end = Std.int(Math.min(filtered.length, scrollIndex + visibleCount));
		var slot = 0;
		for (i in scrollIndex...end)
		{
			var row = rows[slot];
			var ry = areaY + 4 + slot * rowHeight;
			row.dataIndex = i;
			row.layout(areaX + 2, ry, contentW - 4, rowHeight, filtered[i], fontSize, i == hoveredRow);
			row.visible = true;
			slot++;
		}

		for (i in slot...rows.length)
		{
			rows[i].dataIndex = -1;
			rows[i].visible = false;
		}

		drawListPanel();
		updateScrollbar();
	}

	function showEmptyState():Void
	{
		ensureRowPool(1);
		rows[0].dataIndex = -1;
		rows[0].layoutMessage(areaX + 2, areaY + 4, contentW - 4, rowHeight, "NO RECORDS FOUND", fontSize, true);
		rows[0].visible = true;
		listDivider.visible = false;
		for (i in 1...rows.length)
			rows[i].visible = false;
	}

	function drawListPanel():Void
	{
		var panelW = Std.int(contentW);
		var panelH = Std.int(areaH);
		listBg.setPosition(areaX, areaY);
		listBg.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(listBg, panelW, panelH, MonitorScreenUi.GREEN, 1);
		listBg.updateHitbox();
		listBg.visible = true;

		var rowX = areaX + 2;
		var rowW = contentW - 4;
		listDivider.setPosition(MonitorListRow.idColumnX(rowX, rowW, fontSize), areaY + 1);
		listDivider.makeGraphic(2, panelH - 2, MonitorScreenUi.GREEN_DIM, true);
		listDivider.alpha = 1;
		listDivider.updateHitbox();
		listDivider.visible = filtered.length > 0;
	}

	function ensureRowPool(count:Int):Void
	{
		while (rows.length < count)
		{
			var row = new MonitorListRow();
			rows.push(row);
			rowLayer.add(row.bg);
			labelLayer.add(row.nameLabel);
			labelLayer.add(row.idLabel);
		}
	}

	function layoutScrollbar():Void
	{
		repositionScrollbar();
	}

	function drawScrollColumn():Void
	{
		var colH = Std.int(areaH);
		scrollColumn.setPosition(scrollX, areaY);
		scrollColumn.makeGraphic(SCROLL_W, colH, 0xFF0A120E, true);
		drawRectBorder(scrollColumn, SCROLL_W, colH, MonitorScreenUi.GREEN_DIM, 1);
		scrollColumn.updateHitbox();
		scrollColumn.visible = filtered.length > 0;

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.visible = filtered.length > 0;
		scrollUpBtn.visible = filtered.length > 0;
		scrollDownBtn.visible = filtered.length > 0;
	}

	function updateScrollbar():Void
	{
		trackY = areaY + BTN_H;
		trackH = areaH - BTN_H * 2;

		if (filtered.length == 0)
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
		thumbH = Std.int(Math.max(14, trackH * visibleCount / filtered.length));
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

	public function hide():Void
	{
		endDrag();
		visible = false;
		for (row in rows)
			row.visible = false;
		scrollColumn.visible = false;
		scrollThumb.visible = false;
		scrollTrack.visible = false;
		scrollUpBtn.visible = false;
		scrollDownBtn.visible = false;
		listBg.visible = false;
		listDivider.visible = false;
		hoveredRow = -1;
	}
}
