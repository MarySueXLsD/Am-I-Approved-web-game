package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class DeskDocument extends FlxSprite
{
	static inline var SNAP_DURATION = 0.4;

	var zones:LayoutZones;
	var layer:FlxGroup;
	var closedPath:String;
	var openPath:String;
	var openSizeMultiplier:Float;
	var closedDisplayWidth:Float;
	var dragging = false;
	var snapping = false;
	var dragGrabNormX = 0.0;
	var dragGrabNormY = 0.0;
	var isOpen = false;
	var snapTween:FlxTween;
	var activeZone:Zone = ClientTable;

	var useAlphaHitTest = false;
	var alphaThreshold = 20;

	var clientTableAngle = -14.0;
	var employerTableAngle = -6.0;
	var windowAngle = -10.0;
	var clientAngle = -12.0;
	var computerAngle = -12.0;
	var noneAngle = -14.0;

	public function new(zones:LayoutZones, layer:FlxGroup, closedPath:String, openPath:String, openSizeMultiplier:Float = 9.0, placeOnTable:Bool = true)
	{
		super();
		this.zones = zones;
		this.layer = layer;
		this.closedPath = closedPath;
		this.openPath = openPath;
		this.openSizeMultiplier = openSizeMultiplier;
		closedDisplayWidth = zones.leftW * 0.18;
		loadClosedGraphic();
		angle = clientTableAngle;
		if (placeOnTable)
			placeOnClientTable();
	}

	public function placeBeside(other:DeskDocument):Void
	{
		var gap = zones.leftW * 0.02;
		activeZone = ClientTable;
		setPosition(other.x + other.width + gap, other.y + (other.height - height) * 0.5);
		angle = clientTableAngle;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (snapping)
			return;

		var mouse = FlxG.mouse.getViewPosition();

		if (dragging)
		{
			setPosition(mouse.x - width * dragGrabNormX, mouse.y - height * dragGrabNormY);
			applyDragBounds();
			updateStateFromPosition();
			if (FlxG.mouse.justReleased)
				finishDrag();
			return;
		}

		if (FlxG.mouse.justPressed && hitsPoint(mouse) && isFrontmostAtPoint(mouse))
		{
			bringToFront();
			startDrag(mouse.x, mouse.y);
		}
	}

	function bringToFront():Void
	{
		if (layer.members.indexOf(this) < 0)
			return;
		layer.remove(this, true);
		layer.add(this);
	}

	function isFrontmostAtPoint(point:FlxPoint):Bool
	{
		var frontmost:DeskDocument = null;
		for (member in layer.members)
		{
			if (member == null)
				continue;
			var doc = Std.downcast(member, DeskDocument);
			if (doc == null || !doc.hitsPoint(point))
				continue;
			frontmost = doc;
		}
		return frontmost == this;
	}

	public function hitsPoint(point:FlxPoint):Bool
	{
		if (!overlapsPoint(point))
			return false;
		if (!useAlphaHitTest)
			return true;
		return pixelsOverlapPoint(point, alphaThreshold);
	}

	function startDrag(mouseX:Float, mouseY:Float):Void
	{
		if (snapTween != null)
		{
			snapTween.cancel();
			snapTween = null;
		}

		dragging = true;
		snapping = false;
		dragGrabNormX = (mouseX - x) / width;
		dragGrabNormY = (mouseY - y) / height;
		updateStateFromPosition();
	}

	function finishDrag():Void
	{
		dragging = false;
		clearEmployerClip();
		storeAngleForZone(activeZone);

		var mouse = FlxG.mouse.getViewPosition();
		var cursorZone = getZoneAt(mouse.x, mouse.y);

		// Cursor is on employer table: open on employer table.
		if (cursorZone == EmployerTable)
		{
			if (isOpen || overlapsEmployerTable())
			{
				activeZone = EmployerTable;
				if (!isOpen)
					setOpen();
				updateEmployerTableClip();
				return;
			}
			snapToClosestEmployerTableOpen();
			return;
		}

		// Cursor is NOT on employer table: always treat as closed, use cursor zone.
		var dropZone = cursorZone != None ? cursorZone : getDocumentZone();
		if (dropZone == None)
			dropZone = activeZone;
		updateZoneFromCenter(dropZone);

		setClosed();

		switch (dropZone)
		{
			case ClientTable:
				clampToClientTable();
				nudgeFromClientTableEdges();
			case Computer:
				clampToComputer();
				nudgeFromComputerEdges();
			case Client:
				snapToDesk(x, y);
			case Window:
				snapToClientTableTopRight();
			case EmployerTable:
				snapToDesk(x, y);
			case None:
				snapToDesk(x, y);
			default:
		}
	}

	function updateStateFromPosition():Void
	{
		var zone = dragging ? getZoneAtCursor() : getDocumentZone();
		updateZoneFromCenter(zone);

		if (shouldShowOpen())
		{
			setOpen();
			updateEmployerTableClip();
		}
		else
		{
			setClosed();
			clearEmployerClip();
		}
	}

	function updateZoneFromCenter(zone:Zone):Void
	{
		if (zone != activeZone)
		{
			storeAngleForZone(activeZone);
			activeZone = zone;
			if (!isOpen)
				angle = getAngleForZone(zone);
		}
	}

	function shouldShowOpen():Bool
	{
		if (dragging)
		{
			var mouse = FlxG.mouse.getViewPosition();
			return cursorInEmployerTable(mouse.x, mouse.y);
		}
		return activeZone == EmployerTable;
	}

	function cursorInEmployerTable(cx:Float, cy:Float):Bool
	{
		return inRect(cx, cy, zones.employerX, zones.employerTableY, zones.employerW, zones.employerTableH);
	}

	function getDocumentCenter():FlxPoint
	{
		return FlxPoint.get(x + width * 0.5, y + height * 0.5);
	}

	function getDocumentZone():Zone
	{
		var center = getDocumentCenter();
		var zone = getZoneAt(center.x, center.y);
		center.put();
		return zone != None ? zone : activeZone;
	}

	function getDropZoneOnRelease():Zone
	{
		var mouse = FlxG.mouse.getViewPosition();
		var zone = getZoneAt(mouse.x, mouse.y);
		if (zone != None)
			return zone;

		if (overlapsWindow())
			return Window;

		zone = getDocumentZone();
		return zone != None ? zone : activeZone;
	}

	function overlapsWindow():Bool
	{
		var wx = zones.employerX;
		var wy = 0.0;
		var ww = zones.employerW;
		var wh = zones.windowH;
		return x < wx + ww && x + width > wx && y < wy + wh && y + height > wy;
	}

	function overlapsEmployerTable():Bool
	{
		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var er = ex + zones.employerW;
		var eb = ey + zones.employerTableH;
		return x < er && x + width > ex && y < eb && y + height > ey;
	}

	function applyDragBounds():Void
	{
		if (dragging)
			return;

		switch (getDocumentZone())
		{
			case ClientTable:
				clampToClientTable();
			case Window:
				clampToWindow();
			case EmployerTable:
				clampToEmployerTable();
			case Client:
				clampToClient();
			case Computer:
				clampToComputer();
			default:
				clampToZone(activeZone);
		}
	}

	function getZoneAtCursor():Zone
	{
		var mouse = FlxG.mouse.getViewPosition();
		var zone = getZoneAt(mouse.x, mouse.y);
		return zone != None ? zone : activeZone;
	}

	function clampToZone(zone:Zone):Void
	{
		switch (zone)
		{
			case ClientTable:
				clampToClientTable();
			case Window:
				clampToWindow();
			case EmployerTable:
				clampToEmployerTable();
			case Client:
				clampToClient();
			case Computer:
				clampToComputer();
			default:
		}
	}

	function updateEmployerTableClip():Void
	{
		if (!isOpen)
		{
			clearEmployerClip();
			return;
		}

		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var er = ex + zones.employerW;
		var eb = ey + zones.employerTableH;

		var visL = Math.max(x, ex);
		var visT = Math.max(y, ey);
		var visR = Math.min(x + width, er);
		var visB = Math.min(y + height, eb);

		if (visR <= visL || visB <= visT)
		{
			visible = false;
			return;
		}

		visible = true;
		var sx = Math.abs(scale.x);
		var sy = Math.abs(scale.y);
		if (clipRect == null)
			clipRect = FlxRect.get();
		clipRect.set((visL - x) / sx, (visT - y) / sy, (visR - visL) / sx, (visB - visT) / sy);
	}

	function clearEmployerClip():Void
	{
		clipRect = null;
		visible = true;
	}

	function storeAngleForZone(zone:Zone):Void
	{
		switch (zone)
		{
			case ClientTable:
				clientTableAngle = angle;
			case EmployerTable:
				employerTableAngle = angle;
			case Window:
				windowAngle = angle;
			case Client:
				clientAngle = angle;
			case Computer:
				computerAngle = angle;
			case None:
				noneAngle = angle;
			default:
		}
	}

	function getAngleForZone(zone:Zone):Float
	{
		return switch (zone)
		{
			case ClientTable: clientTableAngle;
			case EmployerTable: employerTableAngle;
			case Window: windowAngle;
			case Client: clientAngle;
			case Computer: computerAngle;
			case None: noneAngle;
			default: noneAngle;
		}
	}

	function getZoneAt(cx:Float, cy:Float):Zone
	{
		if (inRect(cx, cy, zones.employerX, zones.employerTableY, zones.employerW, zones.employerTableH))
			return EmployerTable;
		if (inRect(cx, cy, zones.employerX, 0, zones.employerW, zones.windowH))
			return Window;
		if (inRect(cx, cy, 0, zones.clientTableY, zones.leftW, zones.clientTableH))
			return ClientTable;
		if (inRect(cx, cy, 0, 0, zones.leftW, zones.clientH))
			return Client;
		if (inRect(cx, cy, 0, zones.computerY, zones.leftW, zones.computerH))
			return Computer;
		return None;
	}

	function inRect(cx:Float, cy:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
	{
		return cx >= rx && cx < rx + rw && cy >= ry && cy < ry + rh;
	}

	function snapToDesk(fromX:Float, fromY:Float):Void
	{
		activeZone = ClientTable;
		var target = findClosestDeskSnap(fromX, fromY);
		snapping = true;
		snapTween = FlxTween.tween(this, {x: target.x, y: target.y, angle: clientTableAngle}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function findClosestDeskSnap(fromX:Float, fromY:Float):{x:Float, y:Float}
	{
		var points = getDeskSnapPoints();
		var best = points[0];
		var bestDist = Math.POSITIVE_INFINITY;

		for (p in points)
		{
			var dx = fromX - p.x;
			var dy = fromY - p.y;
			var dist = dx * dx + dy * dy;
			if (dist < bestDist)
			{
				bestDist = dist;
				best = p;
			}
		}
		return best;
	}

	function getDeskSnapPoints():Array<{x:Float, y:Float}>
	{
		var margin = Std.int(Math.max(6, zones.leftW * 0.04));
		var tableY = zones.clientTableY;
		var tableH = zones.clientTableH;
		var w = width;
		var h = height;

		return [
			{x: margin, y: tableY + tableH * 0.25 - h * 0.5},
			{x: zones.leftW * 0.5 - w * 0.5, y: tableY + tableH * 0.5 - h * 0.5},
			{x: zones.leftW - w - margin, y: tableY + tableH * 0.72 - h * 0.5}
		];
	}

	function placeOnClientTable():Void
	{
		activeZone = ClientTable;
		var center = findClosestDeskSnap(zones.leftW * 0.5, zones.clientTableY + zones.clientTableH * 0.5);
		setPosition(center.x, center.y);
		angle = clientTableAngle;
	}

	static inline var CLIENT_TABLE_PAD_LEFT:Float = 5;
	static inline var CLIENT_TABLE_PAD_RIGHT:Float = 5;
	static inline var CLIENT_TABLE_PAD_TOP:Float = 25;
	static inline var CLIENT_TABLE_PAD_BOTTOM:Float = 2;

	function clampToClientTable():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, zones.clientTableY, zones.clientTableY + zones.clientTableH - height);
	}

	function nudgeFromClientTableEdges():Void
	{
		var minX = CLIENT_TABLE_PAD_LEFT;
		var maxX = zones.leftW - width - CLIENT_TABLE_PAD_RIGHT;
		var minY = zones.clientTableY + CLIENT_TABLE_PAD_TOP;
		var maxY = zones.clientTableY + zones.clientTableH - height - CLIENT_TABLE_PAD_BOTTOM;

		var needsNudge = x < minX || x > maxX || y < minY || y > maxY;
		if (!needsNudge)
			return;

		var nx = FlxMath.bound(x, minX, maxX);
		var ny = FlxMath.bound(y, minY, maxY);

		snapping = true;
		snapTween = FlxTween.tween(this, {x: nx, y: ny}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function clampToClient():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, 0, zones.clientH - height);
	}

	static inline var COMPUTER_PAD_LEFT:Float = 10;
	static inline var COMPUTER_PAD_RIGHT:Float = 10;

	function clampToComputer():Void
	{
		x = FlxMath.bound(x, 0, zones.leftW - width);
		y = FlxMath.bound(y, zones.computerY, zones.computerY + zones.computerH - height);
	}

	function nudgeFromComputerEdges():Void
	{
		var minX = COMPUTER_PAD_LEFT;
		var maxX = zones.leftW - width - COMPUTER_PAD_RIGHT;

		var needsNudge = x < minX || x > maxX;
		if (!needsNudge)
			return;

		var nx = FlxMath.bound(x, minX, maxX);

		snapping = true;
		snapTween = FlxTween.tween(this, {x: nx}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function clampToWindow():Void
	{
		x = FlxMath.bound(x, zones.employerX, zones.employerX + zones.employerW - width);
		y = FlxMath.bound(y, 0, zones.windowH - height);
	}

	function clampToEmployerTable():Void
	{
		x = FlxMath.bound(x, zones.employerX, zones.employerX + zones.employerW - width);
		y = FlxMath.bound(y, zones.employerTableY, zones.employerTableY + zones.employerTableH - height);
	}

	function snapToClientTableTopRight():Void
	{
		activeZone = ClientTable;
		var margin = Std.int(Math.max(6, zones.leftW * 0.04));
		var targetX = zones.leftW - width - Math.max(margin, CLIENT_TABLE_PAD_RIGHT);
		var targetY = zones.clientTableY + Math.max(margin, CLIENT_TABLE_PAD_TOP);

		snapping = true;
		snapTween = FlxTween.tween(this, {x: targetX, y: targetY, angle: clientTableAngle}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function snapToClosestEmployerTableOpen():Void
	{
		activeZone = EmployerTable;
		setOpen();
		var target = findClosestEmployerTableSnap(x + width * 0.5, y + height * 0.5);
		clampSnapTargetToEmployerTable(target);
		snapping = true;
		snapTween = FlxTween.tween(this, {x: target.x, y: target.y, angle: employerTableAngle}, SNAP_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				snapping = false;
				snapTween = null;
			}
		});
	}

	function findClosestEmployerTableSnap(fromX:Float, fromY:Float):{x:Float, y:Float}
	{
		var points = getEmployerSnapPoints();
		var best = points[0];
		var bestDist = Math.POSITIVE_INFINITY;

		for (p in points)
		{
			var dx = fromX - (p.x + width * 0.5);
			var dy = fromY - (p.y + height * 0.5);
			var dist = dx * dx + dy * dy;
			if (dist < bestDist)
			{
				bestDist = dist;
				best = p;
			}
		}
		return best;
	}

	function getEmployerSnapPoints():Array<{x:Float, y:Float}>
	{
		var margin = Std.int(Math.max(6, zones.employerW * 0.02));
		var ex = zones.employerX;
		var ey = zones.employerTableY;
		var ew = zones.employerW;
		var eh = zones.employerTableH;
		var w = width;
		var h = height;

		return [
			{x: ex + margin, y: ey + margin},
			{x: ex + ew * 0.5 - w * 0.5, y: ey + eh * 0.5 - h * 0.5},
			{x: ex + ew - w - margin, y: ey + margin},
			{x: ex + margin, y: ey + eh - h - margin},
			{x: ex + ew - w - margin, y: ey + eh - h - margin}
		];
	}

	function clampSnapTargetToEmployerTable(target:{x:Float, y:Float}):Void
	{
		target.x = FlxMath.bound(target.x, zones.employerX, zones.employerX + zones.employerW - width);
		target.y = FlxMath.bound(target.y, zones.employerTableY, zones.employerTableY + zones.employerTableH - height);
	}

	function setClosed():Void
	{
		if (!isOpen)
			return;

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = false;
		loadGraphic(closedPath);
		applyDisplaySize();
		angle = getAngleForZone(activeZone);
		placeAfterResize(cx, cy);
	}

	function setOpen():Void
	{
		if (isOpen)
			return;

		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = true;
		loadGraphic(openPath);
		applyDisplaySize();
		angle = 0;
		placeAfterResize(cx, cy);
	}

	function placeAfterResize(prevCenterX:Float, prevCenterY:Float):Void
	{
		if (dragging)
			alignToDragPoint();
		else
			setPosition(prevCenterX - width * 0.5, prevCenterY - height * 0.5);
	}

	function alignToDragPoint():Void
	{
		var mouse = FlxG.mouse.getViewPosition();
		setPosition(mouse.x - width * dragGrabNormX, mouse.y - height * dragGrabNormY);
	}

	function loadClosedGraphic():Void
	{
		loadGraphic(closedPath);
		applyDisplaySize();
	}

	function applyDisplaySize():Void
	{
		var targetWidth = isOpen ? closedDisplayWidth * openSizeMultiplier : closedDisplayWidth;
		var s = targetWidth / frameWidth;
		scale.set(s, s);
		updateHitbox();
	}
}

enum Zone
{
	None;
	Client;
	ClientTable;
	Computer;
	Window;
	EmployerTable;
}
