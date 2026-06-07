package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

class MonitorClientDetail extends FlxGroup
{
	static inline var SCROLL_W = 18;
	static inline var BTN_H = 16;

	public var scrollIndex(default, set) = 0;

	var bgLayer:FlxGroup;
	var labelLayer:FlxGroup;
	var inputLayer:FlxGroup;
	var scrollLayer:FlxGroup;
	var panelBg:FlxSprite;
	var scrollColumn:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var scrollUpBtn:FlxSprite;
	var scrollDownBtn:FlxSprite;
	var confirmDialog:MonitorConfirmDialog;
	var entryRows:Array<MonitorDetailEntryRow> = [];
	var entries:Array<CitizenDetailEntry> = [];

	static inline var MAX_DD:Int = 6;

	var citizen:Citizen;
	var areaX:Float = 0;
	var areaY:Float = 0;
	var areaW:Float = 0;
	var areaH:Float = 0;
	var contentW:Float = 0;
	var scrollX:Float = 0;
	var rowHeight = 32;
	var fontSize = 12;
	var visibleCount = 1;
	var focusedPath:Null<String> = null;
	var thumbDragging = false;
	var dragGrabY = 0.0;
	var thumbH = 12;
	var trackY = 0.0;
	var trackH = 0.0;
	var lastThumbH = -1;
	var lastRenderedScroll = -1;
	var lastRenderedCount = -1;
	var panelDirty = true;
	var scrollDirty = true;
	var keyHandler:KeyboardEvent->Void;

	var ddBg:FlxSprite;
	var ddTxt:Array<FlxText>;
	var ddOpen:Bool = false;
	var ddPath:String = "";
	var ddChoices:Array<String> = [];
	var ddX:Float = 0;
	var ddY:Float = 0;
	var ddW:Float = 0;
	var ddItemH:Int = 0;
	var ddCurrentValue:String = "";

	public function new()
	{
		super();

		bgLayer = new FlxGroup();
		labelLayer = new FlxGroup();
		inputLayer = new FlxGroup();
		scrollLayer = new FlxGroup();
		panelBg = new FlxSprite();
		scrollColumn = new FlxSprite();
		scrollTrack = new FlxSprite();
		scrollThumb = new FlxSprite();
		scrollUpBtn = new FlxSprite();
		scrollDownBtn = new FlxSprite();

		panelBg.scrollFactor.set(0, 0);
		scrollColumn.scrollFactor.set(0, 0);
		scrollTrack.scrollFactor.set(0, 0);
		scrollThumb.scrollFactor.set(0, 0);
		scrollUpBtn.scrollFactor.set(0, 0);
		scrollDownBtn.scrollFactor.set(0, 0);

		bgLayer.add(panelBg);
		add(bgLayer);
		add(inputLayer);
		add(labelLayer);
		add(scrollLayer);
		scrollLayer.add(scrollColumn);
		scrollLayer.add(scrollTrack);
		scrollLayer.add(scrollUpBtn);
		scrollLayer.add(scrollDownBtn);
		scrollLayer.add(scrollThumb);

		ddBg = new FlxSprite();
		ddBg.scrollFactor.set(0, 0);
		ddBg.visible = false;
		add(ddBg);

		ddTxt = [];
		for (i in 0...MAX_DD)
		{
			var t = new FlxText(0, 0, 0, "");
			t.scrollFactor.set(0, 0);
			t.visible = false;
			add(t);
			ddTxt.push(t);
		}

		confirmDialog = new MonitorConfirmDialog();
		add(confirmDialog);

		keyHandler = onKeyDown;
		visible = false;
	}

	public function isModalOpen():Bool
	{
		return confirmDialog.isOpen();
	}

	public function suspendInput():Void
	{
		submitAndBlur();
		closeDropdown();
		if (!confirmDialog.isOpen())
			confirmDialog.close();
		endDrag();
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
		rowHeight = MonitorDetailEntryRow.rowHeight(fontSize);
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;
		visibleCount = MonitorDetailEntryRow.visibleRowCount(h, fontSize);

		if (dimChanged)
		{
			panelDirty = true;
			scrollDirty = true;
			markDirty();
		}

		applyLayout();
		visible = true;

		if (confirmDialog.isOpen())
			confirmDialog.syncBounds(areaX, areaY, areaW, areaH);
	}

	public function reposition(x:Float, y:Float, w:Float, h:Float):Void
	{
		var moved = Math.abs(areaX - x) > 0.5
			|| Math.abs(areaY - y) > 0.5
			|| Math.abs(areaW - w) > 0.5
			|| Math.abs(areaH - h) > 0.5;
		var sizeChanged = Math.abs(areaW - w) > 0.5 || Math.abs(areaH - h) > 0.5;

		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;
		panelBg.setPosition(areaX, areaY);

		if (sizeChanged)
		{
			panelDirty = true;
			scrollDirty = true;
			visibleCount = MonitorDetailEntryRow.visibleRowCount(h, fontSize);
		}

		if (moved)
			applyLayout();
		else if (citizen != null && entries.length > 0)
			repositionScrollbar();

		if (confirmDialog.isOpen())
			confirmDialog.syncBounds(areaX, areaY, areaW, areaH);
	}

	public function setCitizen(c:Citizen, ?resetScroll:Bool = true):Void
	{
		citizen = c;
		entries = CitizenRegistry.buildDetailEntries(c);
		closeDropdown();
		if (resetScroll)
		{
			scrollIndex = 0;
			blurField();
		}
		clampScroll();
		panelDirty = true;
		markDirty();
		refresh();
	}

	function applyLayout():Void
	{
		panelBg.setPosition(areaX, areaY);
		if (panelDirty || !panelBg.visible)
		{
			drawPanel();
			panelDirty = false;
		}

		if (scrollDirty)
		{
			layoutScrollbar();
			scrollDirty = false;
		}
		else
			repositionScrollbar();

		if (citizen != null && entries.length > 0)
			refreshRowPositions();
	}

	public function scrollBy(delta:Int):Void
	{
		if (delta == 0 || isModalOpen())
			return;
		closeDropdown();
		var old = scrollIndex;
		scrollIndex += delta;
		clampScroll();
		if (scrollIndex != old)
		{
			submitAndBlur();
			lastRenderedScroll = -1;
			refresh();
		}
	}

	public function handleWheel(wheel:Float):Void
	{
		if (wheel == 0 || isModalOpen())
			return;
		scrollBy(wheel > 0 ? -1 : 1);
	}

	public function isInPanelArea(mx:Float, my:Float):Bool
	{
		return mx >= areaX && mx < areaX + areaW && my >= areaY && my < areaY + areaH;
	}

	public function handleClick(mx:Float, my:Float):Bool
	{
		if (confirmDialog.isOpen())
			return confirmDialog.handleClick(mx, my);

		if (ddOpen)
		{
			if (isInDropdownArea(mx, my))
			{
				selectDropdownItem(mx, my);
				return true;
			}
			closeDropdown();
		}

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

		var clickedField = tryFocusField(mx, my);
		if (clickedField)
			return true;

		if (isInPanelArea(mx, my))
		{
			submitAndBlur();
			return true;
		}

		return false;
	}

	public function updateDrag(mx:Float, my:Float):Void
	{
		if (!thumbDragging || isModalOpen())
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
		{
			submitAndBlur();
			refresh();
		}
		else
			updateScrollbar();
	}

	public function endDrag():Void
	{
		thumbDragging = false;
	}

	public function showWarning(messageText:String, dismiss:Void->Void):Void
	{
		confirmDialog.showWarning(areaX, areaY, areaW, areaH, messageText, dismiss);
	}

	function tryFocusField(mx:Float, my:Float):Bool
	{
		var end = Std.int(Math.min(entries.length, scrollIndex + visibleCount));
		for (i in scrollIndex...end)
		{
			var slot = i - scrollIndex;
			var path = entryRows[slot].tryFocusPath(mx, my);
			if (path != null)
			{
				var fieldRow = entryRows[slot].getFieldRow(path);
				if (fieldRow != null && fieldRow.isDropdown())
				{
					openDropdown(fieldRow);
					return true;
				}
				focusFieldPath(path);
				return true;
			}
		}
		return false;
	}

	function focusFieldPath(path:String):Void
	{
		if (path == null || path.length == 0)
			return;

		if (focusedPath != null && focusedPath != path)
		{
			var oldRow = getFocusedFieldRow();
			if (oldRow != null && oldRow.hasChanges())
			{
				submitFieldEdit(oldRow);
				return;
			}
		}

		if (focusedPath != path)
		{
			focusedPath = path;
			attachKeyListener();
		}
		refreshRowPositions();
	}

	function blurField():Void
	{
		if (focusedPath == null)
			return;
		focusedPath = null;
		detachKeyListener();
		refreshRowPositions();
	}

	public function hasPendingEdit():Bool
	{
		if (focusedPath == null)
			return false;
		var row = getFocusedFieldRow();
		return row != null && row.hasChanges();
	}

	function submitAndBlur():Void
	{
		if (focusedPath == null)
			return;
		var row = getFocusedFieldRow();
		if (row != null && row.hasChanges())
		{
			submitFieldEdit(row);
			return;
		}
		blurField();
	}

	function getFocusedFieldRow():Null<MonitorDetailFieldRow>
	{
		if (focusedPath == null)
			return null;

		var end = Std.int(Math.min(entries.length, scrollIndex + visibleCount));
		for (i in scrollIndex...end)
		{
			var row = entryRows[i - scrollIndex].getFieldRow(focusedPath);
			if (row != null)
				return row;
		}
		return null;
	}

	function attachKeyListener():Void
	{
		var stage = Lib.current.stage;
		if (stage == null)
			return;
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false, 0, true);
	}

	function detachKeyListener():Void
	{
		var stage = Lib.current.stage;
		if (stage == null)
			return;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!visible)
			return;

		if (confirmDialog.isOpen())
		{
			if (confirmDialog.handleKey(e.keyCode))
				e.stopImmediatePropagation();
			return;
		}

		if (focusedPath == null || citizen == null)
			return;

		var row = getFocusedFieldRow();
		if (row == null || !row.visible)
			return;

		if (e.keyCode == Keyboard.ENTER)
		{
			e.stopImmediatePropagation();
			submitFieldEdit(row);
			return;
		}

		if (e.keyCode == Keyboard.ESCAPE)
		{
			e.stopImmediatePropagation();
			row.revertDraft();
			blurField();
			return;
		}

		if (e.keyCode == Keyboard.BACKSPACE)
		{
			var draft = row.getDraft();
			if (draft.length > 0)
				row.setDraft(draft.substr(0, draft.length - 1));
		}
		else if (e.charCode > 32)
		{
			var ch = String.fromCharCode(e.charCode);
			if (row.digitsOnly)
			{
				if (!MonitorDetailFieldRow.acceptsNumericChar(e.charCode, row.getDraft(), row.allowDecimal))
				{
					e.stopImmediatePropagation();
					return;
				}
			}
			else if (row.dateField)
			{
				var code = e.charCode;
				var isDigit = code >= 48 && code <= 57;
				var isHyphen = code == 45;
				if (!isDigit && !isHyphen)
				{
					e.stopImmediatePropagation();
					return;
				}
				if (row.getDraft().length >= 10)
				{
					e.stopImmediatePropagation();
					return;
				}
			}
			var newDraft = row.getDraft() + Std.string(ch);
			if (!row.textFits(newDraft))
			{
				e.stopImmediatePropagation();
				return;
			}
			row.setDraft(newDraft);
		}
		else
			return;

		e.stopImmediatePropagation();
		refreshRowPositions();
	}

	function submitFieldEdit(row:MonitorDetailFieldRow):Void
	{
		if (!row.hasChanges())
		{
			blurField();
			return;
		}

		var label = CitizenRegistry.fieldLabel(entries, row.path);
		var oldVal = row.getSaved();
		var newVal = row.getDraft();

		if (row.digitsOnly && newVal.length > 0 && !MonitorDetailFieldRow.isValidNumericDraft(newVal, row.allowDecimal))
		{
			detachKeyListener();
			confirmDialog.showWarning(areaX, areaY, areaW, areaH,
				"Sorry! Our complex AI\nalgorithms detected that\nyou provided wrong values in this input.", function()
			{
				row.revertDraft();
				blurField();
				refreshRowPositions();
			});
			return;
		}

		if (row.path == "address.postalCode" && newVal.length > 0)
		{
			if (newVal.length < 5 || newVal.length > 7)
			{
				detachKeyListener();
				confirmDialog.showWarning(areaX, areaY, areaW, areaH,
					"Sorry! Our advanced AI\n noticed that\nthis postal code\ndoesn't look real.", function()
				{
					row.revertDraft();
					blurField();
					refreshRowPositions();
				});
				return;
			}
		}

		if (row.path == "yearsAtAddress" && newVal.length > 0)
		{
			var years = Std.parseInt(newVal);
			if (years != null && years >= 100)
			{
				detachKeyListener();
				confirmDialog.showWarning(areaX, areaY, areaW, areaH,
					"Sorry! Our complex AI\nuhh, thing..., noticed that\nthis value can't be\npossible.", function()
				{
					row.revertDraft();
					blurField();
					refreshRowPositions();
				});
				return;
			}
		}

		if (row.dateField && !CitizenRegistry.isValidDateFormat(newVal))
		{
			detachKeyListener();
			confirmDialog.showWarning(areaX, areaY, areaW, areaH,
				"Sorry! It seems like what\nyou entered is not \nreally a date, hmm \nit must be yyyy-mm-dd.", function()
			{
				row.revertDraft();
				blurField();
				refreshRowPositions();
			});
			return;
		}

		detachKeyListener();

		confirmDialog.show(areaX, areaY, areaW, areaH, label, oldVal, newVal, function()
		{
			CitizenRegistry.setFieldValue(citizen, row.path, newVal);
			row.commitDraft();
			blurField();
			refreshRowPositions();
		}, function()
		{
			row.revertDraft();
			blurField();
			refreshRowPositions();
		});
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
		{
			blurField();
			refresh();
		}
		else
			updateScrollbar();
		return true;
	}

	function refreshRowPositions():Void
	{
		if (entries.length == 0 || citizen == null)
			return;

		ensureRowPool(visibleCount);
		var end = Std.int(Math.min(entries.length, scrollIndex + visibleCount));
		var slot = 0;
		var fieldW = contentW - 12;
		var focus = focusedPath != null ? focusedPath : "";
		for (i in scrollIndex...end)
		{
			var entry = entries[i];
			var row = entryRows[slot];
			switch (entry)
			{
				case Single(field):
					row.setupSingle(field, CitizenRegistry.getFieldValue(citizen, field.path));
				case Pair(left, right):
					row.setupPair(left, CitizenRegistry.getFieldValue(citizen, left.path), right,
						CitizenRegistry.getFieldValue(citizen, right.path));
			}
			var ry = areaY + 4 + slot * rowHeight;
			row.layout(areaX + 6, ry, fieldW, fontSize, focus);
			row.visible = true;
			slot++;
		}

		for (i in slot...entryRows.length)
			entryRows[i].visible = false;

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
		return Std.int(Math.max(0, entries.length - visibleCount));
	}

	function isScrollable():Bool
	{
		return entries.length > visibleCount;
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
		if (entries.length == lastRenderedCount && scrollIndex == lastRenderedScroll)
		{
			refreshRowPositions();
			return;
		}

		lastRenderedCount = entries.length;
		lastRenderedScroll = scrollIndex;

		if (entries.length == 0)
		{
			ensureRowPool(1);
			entryRows[0].setupSingle({path: "", label: "", value: ""}, "");
			entryRows[0].layout(areaX + 6, areaY + 4, contentW - 12, fontSize, "");
			entryRows[0].visible = true;
			for (i in 1...entryRows.length)
				entryRows[i].visible = false;
			if (panelDirty || !panelBg.visible)
			{
				drawPanel();
				panelDirty = false;
			}
			updateScrollbar();
			return;
		}

		if (panelDirty || !panelBg.visible)
		{
			drawPanel();
			panelDirty = false;
		}
		if (scrollDirty)
		{
			layoutScrollbar();
			scrollDirty = false;
		}

		refreshRowPositions();
	}

	function ensureRowPool(count:Int):Void
	{
		while (entryRows.length < count)
		{
			var row = new MonitorDetailEntryRow();
			entryRows.push(row);
			row.addToDisplay(labelLayer, inputLayer);
		}
	}

	function drawPanel():Void
	{
		var panelW = Std.int(contentW);
		var panelH = Std.int(areaH);
		panelBg.setPosition(areaX, areaY);
		panelBg.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(panelBg, panelW, panelH, MonitorScreenUi.GREEN, 1);
		panelBg.updateHitbox();
		panelBg.visible = true;
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
		scrollColumn.visible = entries.length > 0;

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.visible = entries.length > 0;
		scrollUpBtn.visible = entries.length > 0;
		scrollDownBtn.visible = entries.length > 0;
	}

	function updateScrollbar():Void
	{
		trackY = areaY + BTN_H;
		trackH = areaH - BTN_H * 2;

		if (entries.length == 0)
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
		thumbH = Std.int(Math.max(14, trackH * visibleCount / entries.length));
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

	function openDropdown(row:MonitorDetailFieldRow):Void
	{
		if (ddOpen)
			closeDropdown();

		blurField();

		ddOpen = true;
		ddPath = row.path;
		ddChoices = row.getChoices();
		ddCurrentValue = row.getSaved();
		ddItemH = fontSize + 6;

		ddX = row.box.x;
		ddY = row.box.y + row.box.height;
		ddW = row.box.width;

		var totalH = ddChoices.length * ddItemH + 2;

		if (ddY + totalH > areaY + areaH)
			ddY = row.box.y - totalH;

		var bgW = Std.int(ddW);
		var bgH = Std.int(totalH);
		ddBg.makeGraphic(bgW, bgH, 0xFF0A120E, true);
		drawRectBorder(ddBg, bgW, bgH, MonitorScreenUi.GREEN, 1);
		ddBg.setPosition(ddX, ddY);
		ddBg.visible = true;

		for (i in 0...MAX_DD)
		{
			if (i < ddChoices.length)
			{
				var t = ddTxt[i];
				var isSelected = ddChoices[i] == ddCurrentValue;
				t.text = ddChoices[i];
				t.setFormat(null, fontSize, isSelected ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN, "left");
				t.fieldWidth = Std.int(ddW - 8);
				t.scale.set(1, 1);
				t.setPosition(ddX + 4, ddY + 1 + i * ddItemH + 2);
				t.visible = true;
			}
			else
				ddTxt[i].visible = false;
		}
	}

	function closeDropdown():Void
	{
		ddOpen = false;
		ddBg.visible = false;
		for (t in ddTxt)
			t.visible = false;
	}

	function isInDropdownArea(mx:Float, my:Float):Bool
	{
		return ddOpen && mx >= ddX && mx < ddX + ddW && my >= ddY && my < ddY + ddBg.height;
	}

	function selectDropdownItem(mx:Float, my:Float):Void
	{
		var relY = my - ddY - 1;
		var idx = Std.int(relY / ddItemH);
		if (idx < 0 || idx >= ddChoices.length)
		{
			closeDropdown();
			return;
		}

		var displayNew = ddChoices[idx];
		var storeNew = displayNew == "No data" ? "" : displayNew;
		var displayOld = ddCurrentValue.length == 0 ? "No data" : ddCurrentValue;
		var path = ddPath;

		closeDropdown();

		if (storeNew == ddCurrentValue)
			return;

		var label = CitizenRegistry.fieldLabel(entries, path);
		confirmDialog.show(areaX, areaY, areaW, areaH, label, displayOld, displayNew, function()
		{
			CitizenRegistry.setFieldValue(citizen, path, storeNew);
			setCitizen(citizen, false);
		}, function()
		{
		});
	}

	function updateDropdownHover():Void
	{
		if (!ddOpen)
			return;

		var p = FlxG.mouse.getViewPosition();
		var mx = p.x;
		var my = p.y;

		for (i in 0...ddChoices.length)
		{
			if (i >= ddTxt.length || !ddTxt[i].visible)
				continue;
			var itemY = ddY + 1 + i * ddItemH + 2;
			var hovered = mx >= ddX && mx < ddX + ddW && my >= itemY && my < itemY + ddItemH;
			var isSelected = ddChoices[i] == ddCurrentValue;
			if (hovered)
				ddTxt[i].color = MonitorScreenUi.GREEN_BRIGHT;
			else if (isSelected)
				ddTxt[i].color = MonitorScreenUi.GREEN_BRIGHT;
			else
				ddTxt[i].color = MonitorScreenUi.GREEN;
		}
	}

	public function hide():Void
	{
		suspendInput();
		scrollIndex = 0;
		visible = false;
		for (row in entryRows)
			row.visible = false;
		scrollColumn.visible = false;
		scrollThumb.visible = false;
		scrollTrack.visible = false;
		scrollUpBtn.visible = false;
		scrollDownBtn.visible = false;
		panelBg.visible = false;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!visible || citizen == null || isModalOpen())
			return;

		if (ddOpen)
		{
			updateDropdownHover();
			if (FlxG.keys.justPressed.ESCAPE)
				closeDropdown();
			return;
		}

		if (focusedPath == null)
			return;

		if (FlxG.keys.justPressed.SPACE)
		{
			var row = getFocusedFieldRow();
			if (row != null && row.visible)
			{
				row.setDraft(row.getDraft() + " ");
				refreshRowPositions();
			}
		}
	}
}
