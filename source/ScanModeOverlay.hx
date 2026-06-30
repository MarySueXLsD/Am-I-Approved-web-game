package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import StringTools;

private class ScanSelectionItem
{
	public var outline:FlxSprite;
	public var sourceX:Float;
	public var sourceY:Float;
	public var sourceW:Float;
	public var sourceH:Float;
	public var sourceTag:Null<String>;
	public var selectionW:Int = 0;
	public var selectionH:Int = 0;
	public var selectionCut:Int = 0;
	public var drawProgress = 1.0;
	public var drawAnimActive = false;

	public function new(outline:FlxSprite)
	{
		this.outline = outline;
	}
}

private typedef ScanRect = {
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
}

private typedef ScanLineSeg = {
	var x0:Float;
	var y0:Float;
	var x1:Float;
	var y1:Float;
}

private enum PlacementKind
{
	VerticalGap;
	SideLeft;
	SideRight;
	OutsideBelow;
	OutsideAbove;
	Fallback;
}

private typedef MessagePlacement = {
	var x:Float;
	var y:Float;
	var kind:PlacementKind;
}

class ScanModeOverlay extends FlxGroup
{
	static inline var GRAY_OVERLAY_ALPHA = 0.42;
	static inline var HINT_MARGIN = 6.0;
	static inline var SELECTION_PAD = 10.0;
	static inline var SELECTION_VIEW_INSET = 12.0;
	static inline var SELECTION_BORDER = 4;
	static inline var SELECTION_COLOR = 0xFFE8ECF2;
	static inline var SELECTION_ANIM_DURATION = 0.38;
	static inline var CONNECTOR_ANIM_DURATION = 0.42;
	static inline var MAX_SELECTIONS = 2;
	static inline var BOUNDS_MATCH_EPS = 3.0;
	static inline var DOT_DASH = 5;
	static inline var DOT_GAP = 4;
	static inline var DUAL_MESSAGE = "Nothing to ask, really...";
	static inline var ACTION_BG_COLOR = 0xFF18381C;
	static inline var ACTION_TEXT_COLOR = 0xFFB4D28C;
	static inline var ACTION_TEXT_HOVER = 0xFFFFF4B4;
	static inline var ACTION_BORDER_COLOR = 0xFF50A060;
	static inline var MESSAGE_PAD = 6;
	static inline var MESSAGE_GAP = 16.0;
	static inline var CONNECTOR_THICKNESS = 4;

	static var instance:ScanModeOverlay;

	var grayOverlay:FlxSprite;
	var connectorCanvas:FlxSprite;
	var messageBg:FlxSprite;
	var messageTxt:FlxText;
	var hintHitbox:FlxSprite;
	var hintGraphic:FlxSprite;
	var hintLabel:FlxText;
	var clientAreaW:Float;
	var clientAreaH:Float;
	var hintSize:Int = 0;
	var overlayCameras:Array<flixel.FlxCamera>;
	var selections:Array<ScanSelectionItem> = [];
	var connectorLines:Array<ScanLineSeg> = [];
	var connectorAnimProgress = 1.0;
	var connectorAnimActive = false;
	var dualPresentationVisible = false;
	var pendingDualLayout = false;
	var activeAction:Null<{id:String, message:String}> = null;
	var messageActionable = false;
	var messageHovered = false;

	public var isActive(default, null) = false;
	public var onActionConfirm:Null<String->Void>;
	public var getCitizenDisplayName:Void->String;
	public static var isPointAllowed:FlxPoint->Bool;

	public static function blocksDocumentInteraction(doc:DeskDocument, point:FlxPoint):Bool
	{
		if (instance == null || !instance.isActive)
			return false;
		if (isPointAllowed != null && isPointAllowed(point))
			return !doc.isOnClientOrEmployerTable();
		return true;
	}

	public static function isScanModeActive():Bool
	{
		return instance != null && instance.isActive;
	}

	public static var suppressDocumentPress(default, default) = false;

	public function new(clientAreaW:Float, clientAreaH:Float)
	{
		super();
		instance = this;
		this.clientAreaW = clientAreaW;
		this.clientAreaH = clientAreaH;

		grayOverlay = new FlxSprite();
		grayOverlay.visible = false;
		add(grayOverlay);

		connectorCanvas = new FlxSprite();
		connectorCanvas.visible = false;
		add(connectorCanvas);

		messageBg = new FlxSprite();
		messageBg.visible = false;
		add(messageBg);

		messageTxt = new FlxText(0, 0, 0, DUAL_MESSAGE);
		messageTxt.setFormat(null, 11, FlxColor.fromRGB(232, 236, 242), "center");
		messageTxt.visible = false;
		add(messageTxt);

		hintHitbox = new FlxSprite();
		hintHitbox.visible = false;
		add(hintHitbox);

		hintGraphic = new FlxSprite();
		hintGraphic.visible = false;
		add(hintGraphic);

		hintLabel = new FlxText(0, 0, 40, "?");
		hintLabel.setFormat(null, 16, FlxColor.fromRGB(210, 220, 235), "center");
		hintLabel.visible = false;
		add(hintLabel);

		rebuildGraphics();
	}

	public function setClientArea(w:Float, h:Float):Void
	{
		if (clientAreaW == w && clientAreaH == h)
			return;
		clientAreaW = w;
		clientAreaH = h;
		rebuildGraphics();
		if (dualPresentationVisible)
			layoutDualPresentation(true);
	}

	function rebuildGraphics():Void
	{
		hintSize = Std.int(Math.max(28, Math.min(clientAreaW, clientAreaH) * 0.14));
		var fontSize = Std.int(Math.max(12, hintSize * 0.52));
		hintLabel.setFormat(null, fontSize, FlxColor.fromRGB(210, 220, 235), "center");
		hintLabel.fieldWidth = hintSize;

		grayOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(72, 78, 88), true);
		grayOverlay.alpha = GRAY_OVERLAY_ALPHA;
		grayOverlay.updateHitbox();

		resizeConnectorCanvas();
		buildHintGraphic(hintSize);
		layoutHint();
	}

	function resizeConnectorCanvas():Void
	{
		connectorCanvas.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
		connectorCanvas.setPosition(0, 0);
		connectorCanvas.updateHitbox();
	}

	function buildHintGraphic(size:Int):Void
	{
		hintGraphic.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var px = hintGraphic.pixels;
		var fill = 0xCC3A4654;
		var line = 0xFFE8ECF2;

		for (py in 0...size)
		{
			for (pxX in 0...size)
			{
				if (pxX + py >= size - 1)
					px.setPixel32(pxX, py, fill);
			}
		}

		for (i in 0...size)
		{
			var pxX = i;
			var pyY = size - 1 - i;
			if (pxX >= 0 && pxX < size && pyY >= 0 && pyY < size)
				px.setPixel32(pxX, pyY, line);
			if (pxX + 1 < size && pyY >= 0)
				px.setPixel32(pxX + 1, pyY, line);
			if (pxX - 1 >= 0 && pyY >= 0)
				px.setPixel32(pxX - 1, pyY, line);
		}
		hintGraphic.dirty = true;
		hintGraphic.updateHitbox();

		hintHitbox.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		hintHitbox.updateHitbox();
	}

	function layoutHint():Void
	{
		var x = clientAreaW - hintSize - HINT_MARGIN;
		var y = clientAreaH - hintSize - HINT_MARGIN;
		hintHitbox.setPosition(x, y);
		hintGraphic.setPosition(x, y);
		hintLabel.setPosition(x, y + hintSize * 0.18);
	}

	public function setHintVisible(value:Bool):Void
	{
		if (isActive)
			value = false;
		hintHitbox.visible = value;
		hintGraphic.visible = value;
		hintLabel.visible = value;
	}

	public function setActive(value:Bool):Void
	{
		if (isActive == value)
			return;
		isActive = value;
		grayOverlay.visible = value;
		if (value)
		{
			hintHitbox.visible = false;
			hintGraphic.visible = false;
			hintLabel.visible = false;
		}
		else
			clearSelection();
	}

	public function toggle():Void
	{
		setActive(!isActive);
	}

	public function handleClick(point:FlxPoint):Bool
	{
		if (isActive)
			return false;

		return hintHitbox.visible && hintHitbox.overlapsPoint(point);
	}

	public function handleScanSelection(point:FlxPoint, resolveTarget:FlxPoint->Null<ScanBounds>):Bool
	{
		if (!isActive || !FlxG.mouse.justPressed)
			return false;

		if (isPointAllowed == null || !isPointAllowed(point))
		{
			if (selections.length == 0)
				clearSelection();
			return false;
		}

		var bounds = resolveTarget(point);
		if (bounds == null)
		{
			if (selections.length == 0)
				clearSelection();
			return false;
		}

		if (boundsMatchExisting(bounds))
			return false;

		addSelection(bounds);
		return true;
	}

	public function showSelection(bounds:ScanBounds):Void
	{
		if (boundsMatchExisting(bounds))
			return;

		addSelection(bounds);
	}

	function addSelection(bounds:ScanBounds):Void
	{
		if (selections.length >= MAX_SELECTIONS)
		{
			removeOldestSelection();
			hideDualPresentation();
		}

		var pad = bounds.pad != null ? bounds.pad : SELECTION_PAD;
		var x = bounds.x - pad;
		var y = bounds.y - pad;
		var w = bounds.w + pad * 2;
		var h = bounds.h + pad * 2;
		var clamped = clampSelectionToView(x, y, w, h);
		x = clamped.x;
		y = clamped.y;
		w = clamped.w;
		h = clamped.h;

		var outline = new FlxSprite();
		outline.visible = true;
		outline.alpha = 1;
		add(outline);

		var item = new ScanSelectionItem(outline);
		item.sourceX = bounds.x;
		item.sourceY = bounds.y;
		item.sourceW = bounds.w;
		item.sourceH = bounds.h;
		item.sourceTag = bounds.tag;
		item.selectionW = Std.int(Math.max(8, Math.ceil(w)));
		item.selectionH = Std.int(Math.max(8, Math.ceil(h)));
		item.selectionCut = Std.int(Math.max(4, Math.min(Math.min(item.selectionW, item.selectionH) * 0.12, 16)));
		item.outline.setPosition(x, y);
		item.drawProgress = 0;
		item.drawAnimActive = true;

		selections.push(item);
		syncOverlayCameras();

		if (selections.length < MAX_SELECTIONS)
		{
			pendingDualLayout = false;
			hideDualPresentation();
		}
		else
			pendingDualLayout = true;

		redrawSelectionOutline(item);
	}

	function removeOldestSelection():Void
	{
		if (selections.length == 0)
			return;

		var oldest = selections.shift();
		remove(oldest.outline, true);
	}

	function boundsMatchExisting(bounds:ScanBounds):Bool
	{
		for (item in selections)
		{
			if (Math.abs(item.sourceX - bounds.x) <= BOUNDS_MATCH_EPS
				&& Math.abs(item.sourceY - bounds.y) <= BOUNDS_MATCH_EPS
				&& Math.abs(item.sourceW - bounds.w) <= BOUNDS_MATCH_EPS
				&& Math.abs(item.sourceH - bounds.h) <= BOUNDS_MATCH_EPS)
				return true;
		}
		return false;
	}

	function clampSelectionToView(x:Float, y:Float, w:Float, h:Float):ScanBounds
	{
		var inset = SELECTION_VIEW_INSET;
		var minX = inset;
		var minY = inset;
		var maxX = FlxG.width - inset;
		var maxY = FlxG.height - inset;

		if (x < minX)
		{
			w -= minX - x;
			x = minX;
		}
		if (y < minY)
		{
			h -= minY - y;
			y = minY;
		}
		if (x + w > maxX)
			w = maxX - x;
		if (y + h > maxY)
			h = maxY - y;

		if (w < 8)
			w = 8;
		if (h < 8)
			h = 8;

		return {x: x, y: y, w: w, h: h};
	}

	public function clearSelection():Void
	{
		for (item in selections)
			remove(item.outline, true);
		selections = [];
		hideDualPresentation();
		pendingDualLayout = false;
	}

	function hideDualPresentation():Void
	{
		dualPresentationVisible = false;
		connectorAnimActive = false;
		connectorAnimProgress = 0;
		connectorLines = [];
		connectorCanvas.visible = false;
		messageBg.visible = false;
		messageTxt.visible = false;
		activeAction = null;
		messageActionable = false;
		messageHovered = false;
	}

	function beginDualPresentation():Void
	{
		if (selections.length < MAX_SELECTIONS)
			return;

		layoutDualPresentation(false);
		pendingDualLayout = false;
	}

	function layoutDualPresentation(instant:Bool):Void
	{
		if (selections.length < MAX_SELECTIONS)
			return;

		activeAction = BookScanActions.resolve(
			selections[0].sourceTag,
			selections[1].sourceTag,
			getCitizenDisplayName != null ? getCitizenDisplayName() : null
		);
		messageActionable = activeAction != null;
		messageHovered = false;

		var a = selectionRect(selections[0]);
		var b = selectionRect(selections[1]);
		var msgSize = measureMessageSize();
		var placement = findMessagePlacement(a, b, msgSize.w, msgSize.h);
		var msgW = Std.int(Math.ceil(msgSize.w));
		var msgH = Std.int(Math.ceil(msgSize.h));

		if (messageActionable)
		{
			messageBg.makeGraphic(msgW, msgH, ACTION_BG_COLOR, true);
			drawActionMessageBorder(messageBg.pixels, msgW, msgH);
		}
		else
		{
			messageBg.makeGraphic(msgW, msgH, FlxColor.fromRGB(18, 24, 34), true);
			drawMessageBorder(messageBg.pixels, msgW, msgH);
		}
		messageBg.dirty = true;
		messageBg.setPosition(placement.x, placement.y);
		messageBg.visible = true;

		var fontSize = Std.int(Math.max(9, FlxG.height / 70));
		messageTxt.setFormat(null, fontSize, currentMessageTextColor(), "center");
		messageTxt.text = currentMessageText();
		messageTxt.setPosition(placement.x + MESSAGE_PAD, placement.y + MESSAGE_PAD);
		messageTxt.visible = true;

		var textRect:ScanRect = {x: placement.x, y: placement.y, w: msgSize.w, h: msgSize.h};
		connectorLines = buildConnectors(a, b, textRect, placement.kind);

		dualPresentationVisible = true;
		connectorCanvas.visible = true;
		syncOverlayCameras();

		if (instant)
		{
			connectorAnimProgress = 1;
			connectorAnimActive = false;
			redrawConnectors();
		}
		else
		{
			connectorAnimProgress = 0;
			connectorAnimActive = true;
			redrawConnectors();
		}
	}

	function currentMessageText():String
	{
		return activeAction != null ? activeAction.message : DUAL_MESSAGE;
	}

	function currentMessageTextColor():Int
	{
		if (!messageActionable)
			return FlxColor.fromRGB(232, 236, 242);

		return messageHovered ? ACTION_TEXT_HOVER : ACTION_TEXT_COLOR;
	}

	function measureMessageSize():{w:Float, h:Float}
	{
		var fontSize = Std.int(Math.max(9, FlxG.height / 70));
		messageTxt.setFormat(null, fontSize, currentMessageTextColor(), "center");
		messageTxt.text = currentMessageText();
		var glyphW = messageTxt.textField.textWidth;
		var glyphH = messageTxt.textField.textHeight;
		return {
			w: (glyphW > 0 ? glyphW : messageTxt.width) + MESSAGE_PAD * 2,
			h: (glyphH > 0 ? glyphH : messageTxt.height) + MESSAGE_PAD * 2
		};
	}

	public function isPointOnActionableMessage(point:FlxPoint):Bool
	{
		return messageActionable && dualPresentationVisible && messageBg.visible && messageBg.overlapsPoint(point);
	}

	public function getHintBounds():Null<TutorialGuideRect>
	{
		if (!hintHitbox.visible)
			return null;
		return {x: hintHitbox.x, y: hintHitbox.y, w: hintHitbox.width, h: hintHitbox.height};
	}

	public function hasSelectionWithTagPrefix(prefix:String):Bool
	{
		for (item in selections)
		{
			if (item.sourceTag != null && StringTools.startsWith(item.sourceTag, prefix))
				return true;
		}
		return false;
	}

	public function hasClientSelection():Bool
	{
		for (item in selections)
		{
			if (item.sourceTag == BookScanActions.CLIENT_TAG)
				return true;
		}
		return false;
	}

	public function hasClientDetailsSelection():Bool
	{
		for (item in selections)
		{
			if (item.sourceTag == BookScanActions.CLIENT_DETAILS_TAG)
				return true;
		}
		return false;
	}

	public function isActionReady():Bool
	{
		return messageActionable && activeAction != null;
	}

	public function handleActionClick(point:FlxPoint):Bool
	{
		if (!isActive || !messageActionable || !FlxG.mouse.justPressed)
			return false;

		if (!messageBg.overlapsPoint(point))
			return false;

		return confirmActiveAction();
	}

	public function tryConfirmAction():Bool
	{
		if (!isActive || !messageActionable)
			return false;

		return confirmActiveAction();
	}

	function confirmActiveAction():Bool
	{
		if (activeAction == null || onActionConfirm == null)
			return false;

		var actionId = activeAction.id;
		setActive(false);
		onActionConfirm(actionId);
		return true;
	}

	public function updateActionHover(point:FlxPoint):Void
	{
		if (!messageActionable || !dualPresentationVisible)
		{
			messageHovered = false;
			return;
		}

		var hovered = messageBg.overlapsPoint(point);
		if (hovered == messageHovered)
			return;

		messageHovered = hovered;
		var fontSize = Std.int(Math.max(9, FlxG.height / 70));
		messageTxt.setFormat(null, fontSize, currentMessageTextColor(), "center");
	}

	function selectionRect(item:ScanSelectionItem):ScanRect
	{
		return {
			x: item.outline.x,
			y: item.outline.y,
			w: item.selectionW,
			h: item.selectionH
		};
	}

	function findMessagePlacement(a:ScanRect, b:ScanRect, textW:Float, textH:Float):MessagePlacement
	{
		var inset = SELECTION_VIEW_INSET;
		var viewW = FlxG.width - inset * 2;
		var viewH = FlxG.height - inset * 2;

		var candidates:Array<MessagePlacement> = [];
		if (isSideBySide(a, b))
			pushCandidate(candidates, tryAboveBelowForSideBySide(a, b, textW, textH, inset, viewW, viewH));
		else
		{
			pushCandidate(candidates, tryVerticalGapPlacement(a, b, textW, textH));

			var sideRight = trySidePlacement(a, b, textW, textH, false, inset, viewW, viewH);
			var sideLeft = trySidePlacement(a, b, textW, textH, true, inset, viewW, viewH);
			if (sideRight != null && sideLeft != null)
			{
				var roomRight = inset + viewW - Math.max(a.x + a.w, b.x + b.w);
				var roomLeft = Math.min(a.x, b.x) - inset;
				pushCandidate(candidates, roomRight >= roomLeft ? sideRight : sideLeft);
				pushCandidate(candidates, roomRight >= roomLeft ? sideLeft : sideRight);
			}
			else
			{
				pushCandidate(candidates, sideRight);
				pushCandidate(candidates, sideLeft);
			}
		}

		if (!isSideBySide(a, b))
		{
			pushCandidate(candidates, tryOutsidePlacement(a, b, textW, textH, true, inset, viewW, viewH));
			pushCandidate(candidates, tryOutsidePlacement(a, b, textW, textH, false, inset, viewW, viewH));
		}

		for (candidate in candidates)
		{
			var text = textRect(candidate.x, candidate.y, textW, textH);
			if (rectsOverlap(text, a) || rectsOverlap(text, b))
				continue;
			if (connectorsCrossSibling(a, b, text, candidate.kind))
				continue;
			return candidate;
		}

		var midX = (a.x + a.w * 0.5 + b.x + b.w * 0.5) * 0.5 - textW * 0.5;
		var midY = (a.y + a.h * 0.5 + b.y + b.h * 0.5) * 0.5 - textH * 0.5;
		return {
			x: clamp(midX, inset, inset + viewW - textW),
			y: clamp(midY, inset, inset + viewH - textH),
			kind: Fallback
		};
	}

	function pushCandidate(list:Array<MessagePlacement>, candidate:Null<MessagePlacement>):Void
	{
		if (candidate != null)
			list.push(candidate);
	}

	function textRect(x:Float, y:Float, w:Float, h:Float):ScanRect
	{
		return {x: x, y: y, w: w, h: h};
	}

	function rectsOverlap(a:ScanRect, b:ScanRect):Bool
	{
		return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
	}

	function connectorsCrossSibling(a:ScanRect, b:ScanRect, text:ScanRect, kind:PlacementKind):Bool
	{
		for (line in connectorLinesForSelection(a, text, kind))
		{
			if (segmentIntersectsRect(line, b))
				return true;
		}
		for (line in connectorLinesForSelection(b, text, kind))
		{
			if (segmentIntersectsRect(line, a))
				return true;
		}
		return false;
	}

	function segmentIntersectsRect(line:ScanLineSeg, rect:ScanRect):Bool
	{
		if (Math.abs(line.x0 - line.x1) < 0.5)
		{
			var x = line.x0;
			var yMin = Math.min(line.y0, line.y1);
			var yMax = Math.max(line.y0, line.y1);
			if (x <= rect.x + 0.5 || x >= rect.x + rect.w - 0.5)
				return false;
			var enterY = Math.max(yMin, rect.y + 0.5);
			var exitY = Math.min(yMax, rect.y + rect.h - 0.5);
			return exitY > enterY;
		}

		if (Math.abs(line.y0 - line.y1) < 0.5)
		{
			var y = line.y0;
			var xMin = Math.min(line.x0, line.x1);
			var xMax = Math.max(line.x0, line.x1);
			if (y <= rect.y + 0.5 || y >= rect.y + rect.h - 0.5)
				return false;
			var enterX = Math.max(xMin, rect.x + 0.5);
			var exitX = Math.min(xMax, rect.x + rect.w - 0.5);
			return exitX > enterX;
		}

		return false;
	}

	function isSideBySide(a:ScanRect, b:ScanRect):Bool
	{
		return a.x + a.w <= b.x || b.x + b.w <= a.x;
	}

	function tryAboveBelowForSideBySide(a:ScanRect, b:ScanRect, textW:Float, textH:Float, inset:Float, viewW:Float,
			viewH:Float):Null<MessagePlacement>
	{
		if (!isSideBySide(a, b))
			return null;

		var minY = Math.min(a.y, b.y);
		var maxY = Math.max(a.y + a.h, b.y + b.h);
		var roomAbove = minY - inset;
		var roomBelow = inset + viewH - maxY;
		var preferBelow = roomBelow >= roomAbove;

		if (preferBelow)
		{
			var below = tryOutsidePlacement(a, b, textW, textH, true, inset, viewW, viewH);
			if (below != null)
				return below;
			return tryOutsidePlacement(a, b, textW, textH, false, inset, viewW, viewH);
		}

		var above = tryOutsidePlacement(a, b, textW, textH, false, inset, viewW, viewH);
		if (above != null)
			return above;
		return tryOutsidePlacement(a, b, textW, textH, true, inset, viewW, viewH);
	}

	function tryVerticalGapPlacement(a:ScanRect, b:ScanRect, textW:Float, textH:Float):Null<MessagePlacement>
	{
		var top:ScanRect;
		var bottom:ScanRect;
		if (a.y + a.h <= b.y)
		{
			top = a;
			bottom = b;
		}
		else if (b.y + b.h <= a.y)
		{
			top = b;
			bottom = a;
		}
		else
			return null;

		var gapH = bottom.y - (top.y + top.h);
		var innerH = gapH - MESSAGE_GAP * 2;
		if (innerH + 0.01 < textH)
			return null;

		var overlapLeft = Math.max(top.x, bottom.x);
		var overlapRight = Math.min(top.x + top.w, bottom.x + bottom.w);
		var overlapW = overlapRight - overlapLeft;
		if (overlapW + 0.01 < textW)
			return null;

		return {
			x: overlapLeft + (overlapW - textW) * 0.5,
			y: top.y + top.h + MESSAGE_GAP + (innerH - textH) * 0.5,
			kind: VerticalGap
		};
	}

	function trySidePlacement(a:ScanRect, b:ScanRect, textW:Float, textH:Float, leftSide:Bool, inset:Float, viewW:Float,
			viewH:Float):Null<MessagePlacement>
	{
		var minX = Math.min(a.x, b.x);
		var maxX = Math.max(a.x + a.w, b.x + b.w);
		var minY = Math.min(a.y, b.y);
		var maxY = Math.max(a.y + a.h, b.y + b.h);
		var unionH = maxY - minY;
		if (unionH + 0.01 < textH)
			return null;

		var y = clamp(minY + (unionH - textH) * 0.5, inset, inset + viewH - textH);

		if (leftSide)
		{
			var x = minX - MESSAGE_GAP - textW;
			if (x < inset)
				return null;
			return {x: x, y: y, kind: SideLeft};
		}

		var rightX = maxX + MESSAGE_GAP;
		if (rightX + textW > inset + viewW)
			return null;
		return {x: rightX, y: y, kind: SideRight};
	}

	function tryOutsidePlacement(a:ScanRect, b:ScanRect, textW:Float, textH:Float, below:Bool, inset:Float, viewW:Float,
			viewH:Float):Null<MessagePlacement>
	{
		var minX = Math.min(a.x, b.x);
		var maxX = Math.max(a.x + a.w, b.x + b.w);
		var minY = Math.min(a.y, b.y);
		var maxY = Math.max(a.y + a.h, b.y + b.h);

		var x = minX + (maxX - minX - textW) * 0.5;
		x = clamp(x, inset, inset + viewW - textW);

		var y:Float;
		if (below)
		{
			y = maxY + MESSAGE_GAP;
			if (y + textH > inset + viewH)
				return null;
			return {x: x, y: y, kind: OutsideBelow};
		}

		y = minY - MESSAGE_GAP - textH;
		if (y < inset)
			return null;
		return {x: x, y: y, kind: OutsideAbove};
	}

	function buildConnectors(a:ScanRect, b:ScanRect, text:ScanRect, kind:PlacementKind):Array<ScanLineSeg>
	{
		return connectorLinesForSelection(a, text, kind).concat(connectorLinesForSelection(b, text, kind));
	}

	function connectorLinesForSelection(sel:ScanRect, text:ScanRect, kind:PlacementKind):Array<ScanLineSeg>
	{
		var textCy = text.y + text.h * 0.5;

		switch (kind)
		{
			case VerticalGap:
				var isTop = sel.y + sel.h * 0.5 <= textCy;
				if (isTop)
					return [horizontalSeg(sel.x, sel.y + sel.h * 0.5, text.x, textCy)];
				return [horizontalSeg(sel.x + sel.w, sel.y + sel.h * 0.5, text.x + text.w, textCy)];

			case SideLeft:
				return [horizontalSeg(sel.x, sel.y + sel.h * 0.5, text.x + text.w, textCy)];

			case SideRight:
				return [horizontalSeg(sel.x + sel.w, sel.y + sel.h * 0.5, text.x, textCy)];

			case OutsideBelow:
				return belowConnectors(sel, text);

			case OutsideAbove:
				return aboveConnectors(sel, text);

			case Fallback:
				return [fallbackConnector(sel, text)];
		}
	}

	function belowConnectors(sel:ScanRect, text:ScanRect):Array<ScanLineSeg>
	{
		var cx = sel.x + sel.w * 0.5;
		var junctionY = text.y;
		var lines:Array<ScanLineSeg> = [
			{x0: cx, y0: sel.y + sel.h, x1: cx, y1: junctionY}
		];

		var textLeft = text.x;
		var textRight = text.x + text.w;
		if (cx < textLeft - 0.5)
			lines.push({x0: cx, y0: junctionY, x1: textLeft, y1: junctionY});
		else if (cx > textRight + 0.5)
			lines.push({x0: cx, y0: junctionY, x1: textRight, y1: junctionY});

		return lines;
	}

	function aboveConnectors(sel:ScanRect, text:ScanRect):Array<ScanLineSeg>
	{
		var cx = sel.x + sel.w * 0.5;
		var junctionY = text.y + text.h;
		var lines:Array<ScanLineSeg> = [
			{x0: cx, y0: sel.y, x1: cx, y1: junctionY}
		];

		var textLeft = text.x;
		var textRight = text.x + text.w;
		if (cx < textLeft - 0.5)
			lines.push({x0: cx, y0: junctionY, x1: textLeft, y1: junctionY});
		else if (cx > textRight + 0.5)
			lines.push({x0: cx, y0: junctionY, x1: textRight, y1: junctionY});

		return lines;
	}

	function horizontalSeg(x0:Float, y0:Float, x1:Float, y1:Float):ScanLineSeg
	{
		return {x0: x0, y0: y0, x1: x1, y1: y1};
	}

	function verticalBottomSeg(sel:ScanRect, text:ScanRect):ScanLineSeg
	{
		var cx = sel.x + sel.w * 0.5;
		return {x0: cx, y0: sel.y + sel.h, x1: cx, y1: text.y};
	}

	function verticalTopSeg(sel:ScanRect, text:ScanRect):ScanLineSeg
	{
		var cx = sel.x + sel.w * 0.5;
		return {x0: cx, y0: sel.y, x1: cx, y1: text.y + text.h};
	}

	function fallbackConnector(sel:ScanRect, text:ScanRect):ScanLineSeg
	{
		var selCy = sel.y + sel.h * 0.5;
		var textCy = text.y + text.h * 0.5;

		if (text.y >= sel.y + sel.h)
		{
			var below = belowConnectors(sel, text);
			if (below.length > 1)
				return below[1];
			return below[0];
		}

		if (text.y + text.h <= sel.y)
		{
			var above = aboveConnectors(sel, text);
			if (above.length > 1)
				return above[1];
			return above[0];
		}

		if (sel.x + sel.w <= text.x)
			return horizontalSeg(sel.x + sel.w, selCy, text.x, textCy);
		if (text.x + text.w <= sel.x)
			return horizontalSeg(sel.x, selCy, text.x + text.w, textCy);

		if (textCy >= selCy)
			return verticalBottomSeg(sel, text);
		return verticalTopSeg(sel, text);
	}

	function clamp(value:Float, min:Float, max:Float):Float
	{
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	function drawActionMessageBorder(bmd:BitmapData, w:Int, h:Int):Void
	{
		var c = ACTION_BORDER_COLOR;
		var b = SELECTION_BORDER;
		for (py in 0...b)
		{
			for (px in 0...w)
			{
				bmd.setPixel32(px, py, c);
				bmd.setPixel32(px, h - 1 - py, c);
			}
		}
		for (px in 0...b)
		{
			for (py in 0...h)
			{
				bmd.setPixel32(px, py, c);
				bmd.setPixel32(w - 1 - px, py, c);
			}
		}
	}

	function drawMessageBorder(bmd:BitmapData, w:Int, h:Int):Void
	{
		var c = SELECTION_COLOR;
		var b = SELECTION_BORDER;
		for (py in 0...b)
		{
			for (px in 0...w)
			{
				bmd.setPixel32(px, py, c);
				bmd.setPixel32(px, h - 1 - py, c);
			}
		}
		for (px in 0...b)
		{
			for (py in 0...h)
			{
				bmd.setPixel32(px, py, c);
				bmd.setPixel32(w - 1 - px, py, c);
			}
		}
	}

	function redrawConnectors():Void
	{
		if (!dualPresentationVisible)
			return;

		resizeConnectorCanvas();
		var px = connectorCanvas.pixels;
		var totalLen = 0.0;
		for (line in connectorLines)
			totalLen += lineLength(line);

		var remaining = connectorAnimProgress * totalLen;
		for (line in connectorLines)
		{
			if (remaining <= 0)
				break;
			var len = lineLength(line);
			var t = remaining >= len ? 1.0 : remaining / len;
			drawDottedLine(px, FlxG.width, FlxG.height, line, t, CONNECTOR_THICKNESS);
			remaining -= len;
		}

		connectorCanvas.dirty = true;
	}

	function lineLength(line:ScanLineSeg):Float
	{
		var dx = line.x1 - line.x0;
		var dy = line.y1 - line.y0;
		return Math.sqrt(dx * dx + dy * dy);
	}

	function drawDottedLine(bmd:BitmapData, bw:Int, bh:Int, line:ScanLineSeg, progress:Float, thickness:Int):Void
	{
		if (progress <= 0)
			return;

		var len = lineLength(line);
		if (len <= 0.001)
		{
			stampPixelBlock(bmd, bw, bh, Std.int(Math.round(line.x0)), Std.int(Math.round(line.y0)), thickness);
			return;
		}

		var drawDist = len * progress;
		var cycle = DOT_DASH + DOT_GAP;
		var steps = Std.int(Math.max(1, Math.ceil(len)));

		for (i in 0...steps)
		{
			var dist = (i + 0.5) / steps * len;
			if (dist > drawDist)
				break;
			if (Std.int(dist) % cycle >= DOT_DASH)
				continue;

			var t = dist / len;
			var x = Std.int(Math.round(line.x0 + (line.x1 - line.x0) * t));
			var y = Std.int(Math.round(line.y0 + (line.y1 - line.y0) * t));
			stampPixelBlock(bmd, bw, bh, x, y, thickness);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (connectorAnimActive)
		{
			connectorAnimProgress += elapsed / CONNECTOR_ANIM_DURATION;
			if (connectorAnimProgress >= 1)
			{
				connectorAnimProgress = 1;
				connectorAnimActive = false;
			}
			redrawConnectors();
		}

		var anyDrawAnim = false;
		for (item in selections)
		{
			if (!item.drawAnimActive)
				continue;

			anyDrawAnim = true;
			item.drawProgress += elapsed / SELECTION_ANIM_DURATION;
			if (item.drawProgress >= 1)
			{
				item.drawProgress = 1;
				item.drawAnimActive = false;
			}
			redrawSelectionOutline(item);
		}

		if (pendingDualLayout && selections.length == MAX_SELECTIONS && !anyDrawAnim)
			beginDualPresentation();

		if (messageActionable && dualPresentationVisible)
		{
			var mouse = FlxG.mouse.getViewPosition();
			updateActionHover(mouse);
		}
	}

	function redrawSelectionOutline(item:ScanSelectionItem):Void
	{
		if (item.selectionW <= 0 || item.selectionH <= 0)
			return;

		item.outline.makeGraphic(item.selectionW, item.selectionH, FlxColor.TRANSPARENT, true);
		var px = item.outline.pixels;
		var w = item.selectionW;
		var h = item.selectionH;
		var cut = item.selectionCut;
		var b = SELECTION_BORDER;
		var progress = item.drawProgress;

		var segments:Array<{len:Float, draw:Float->Void}> = [];

		segments.push({
			len: diagonalLength(cut),
			draw: function(t) drawLineSegment(px, w, h, 0, cut, Std.int(cut * t), Std.int(cut * (1 - t)), b)
		});
		segments.push({
			len: w - cut,
			draw: function(t) drawDottedHorizontal(px, w, h, cut, 0, cut + Std.int((w - 1 - cut) * t), b, t)
		});
		segments.push({
			len: h,
			draw: function(t) drawDottedVertical(px, w, h, w - b, 0, h - 1, b, t)
		});
		segments.push({
			len: w - cut,
			draw: function(t) drawDottedHorizontal(px, w, h, w - 1 - Std.int((w - 1 - cut) * t), h - 1, w - 1, b, t)
		});
		segments.push({
			len: diagonalLength(cut),
			draw: function(t) drawLineSegment(px, w, h, cut, h - 1, Std.int(cut * (1 - t)), h - 1 + Std.int((1 - cut) * t), b)
		});
		segments.push({
			len: h - cut * 2,
			draw: function(t) drawLineSegment(px, w, h, 0, h - cut, 0, h - cut - Std.int((h - cut * 2) * t), b)
		});

		var totalLen = 0.0;
		for (seg in segments)
			totalLen += seg.len;

		var remaining = progress * totalLen;
		for (seg in segments)
		{
			if (remaining <= 0)
				break;
			var segT = remaining >= seg.len ? 1.0 : remaining / seg.len;
			seg.draw(segT);
			remaining -= seg.len;
		}

		item.outline.dirty = true;
		item.outline.updateHitbox();
	}

	function diagonalLength(cut:Int):Float
	{
		return cut * 1.41421356;
	}

	function drawDottedHorizontal(bmd:BitmapData, bw:Int, bh:Int, x0:Int, y:Int, x1:Int, thickness:Int, progress:Float):Void
	{
		var left = x0 < x1 ? x0 : x1;
		var right = x0 < x1 ? x1 : x0;
		var span = right - left + 1;
		var visibleRight = left + Std.int(Math.floor(span * progress + 0.999)) - 1;
		if (visibleRight < left)
			return;
		if (visibleRight > right)
			visibleRight = right;

		var cycle = DOT_DASH + DOT_GAP;
		var x = left;
		var lastDashEnd = left - 1;
		while (x <= right)
		{
			if (x > visibleRight)
				break;

			var dashEnd = Std.int(Math.min(x + DOT_DASH - 1, Math.min(right, visibleRight)));
			for (pxX in x...dashEnd + 1)
				stampPixelBlock(bmd, bw, bh, pxX, y, thickness);

			lastDashEnd = dashEnd;
			x += cycle;
		}

		if (progress >= 1 && lastDashEnd < right)
		{
			for (pxX in lastDashEnd + 1...right + 1)
				stampPixelBlock(bmd, bw, bh, pxX, y, thickness);
		}
	}

	function drawDottedVertical(bmd:BitmapData, bw:Int, bh:Int, x:Int, y0:Int, y1:Int, thickness:Int, progress:Float):Void
	{
		var top = y0;
		var bottom = y1;
		if (bottom < top)
		{
			var tmp = top;
			top = bottom;
			bottom = tmp;
		}

		var span = bottom - top + 1;
		var visibleBottom = top + Std.int(Math.floor(span * progress + 0.999)) - 1;
		if (visibleBottom < top)
			return;
		if (visibleBottom > bottom)
			visibleBottom = bottom;

		var cycle = DOT_DASH + DOT_GAP;
		var y = top;
		var lastDashEnd = top - 1;
		while (y <= bottom)
		{
			if (y > visibleBottom)
				break;

			var dashEnd = Std.int(Math.min(y + DOT_DASH - 1, Math.min(bottom, visibleBottom)));
			for (py in y...dashEnd + 1)
			{
				for (tx in 0...thickness)
				{
					var pxX = x + tx;
					if (pxX >= 0 && pxX < bw && py >= 0 && py < bh)
						bmd.setPixel32(pxX, py, SELECTION_COLOR);
				}
			}
			lastDashEnd = dashEnd;
			y += cycle;
		}

		if (progress >= 1 && lastDashEnd < bottom)
		{
			for (py in lastDashEnd + 1...bottom + 1)
			{
				for (tx in 0...thickness)
				{
					var pxX = x + tx;
					if (pxX >= 0 && pxX < bw && py >= 0 && py < bh)
						bmd.setPixel32(pxX, py, SELECTION_COLOR);
				}
			}
		}
	}

	function drawLineSegment(bmd:BitmapData, bw:Int, bh:Int, x0:Int, y0:Int, x1:Int, y1:Int, thickness:Int):Void
	{
		var dx = Math.abs(x1 - x0);
		var dy = Math.abs(y1 - y0);
		var sx = x0 < x1 ? 1 : -1;
		var sy = y0 < y1 ? 1 : -1;
		var err = dx - dy;
		var x = x0;
		var y = y0;

		while (true)
		{
			stampPixelBlock(bmd, bw, bh, x, y, thickness);
			if (x == x1 && y == y1)
				break;
			var e2 = 2 * err;
			if (e2 > -dy)
			{
				err -= dy;
				x += sx;
			}
			if (e2 < dx)
			{
				err += dx;
				y += sy;
			}
		}
	}

	function stampPixelBlock(bmd:BitmapData, bw:Int, bh:Int, cx:Int, cy:Int, thickness:Int):Void
	{
		var half = Std.int((thickness - 1) * 0.5);
		for (py in cy - half...cy + half + 1)
		{
			for (px in cx - half...cx + half + 1)
			{
				if (px >= 0 && px < bw && py >= 0 && py < bh)
					bmd.setPixel32(px, py, SELECTION_COLOR);
			}
		}
	}

	public function updateHintHover(point:FlxPoint):Void
	{
		if (!hintGraphic.visible)
			return;

		var hovered = hintHitbox.overlapsPoint(point);
		hintGraphic.alpha = hovered ? 1.0 : 0.88;
		hintLabel.alpha = hovered ? 1.0 : 0.9;
	}

	public function syncScreenSize():Void
	{
		if (grayOverlay.width != FlxG.width || grayOverlay.height != FlxG.height)
		{
			grayOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(72, 78, 88), true);
			grayOverlay.alpha = GRAY_OVERLAY_ALPHA;
			grayOverlay.updateHitbox();
		}

		if (dualPresentationVisible)
			redrawConnectors();
	}

	public function setHintCameras(cams:Array<flixel.FlxCamera>):Void
	{
		hintHitbox.cameras = cams;
		hintGraphic.cameras = cams;
		hintLabel.cameras = cams;
	}

	public function setGrayOverlayCameras(cams:Array<flixel.FlxCamera>):Void
	{
		overlayCameras = cams;
		grayOverlay.cameras = cams;
		syncOverlayCameras();
	}

	function syncOverlayCameras():Void
	{
		if (overlayCameras == null)
			return;

		connectorCanvas.cameras = overlayCameras;
		messageBg.cameras = overlayCameras;
		messageTxt.cameras = overlayCameras;

		for (item in selections)
			item.outline.cameras = overlayCameras;
	}
}
