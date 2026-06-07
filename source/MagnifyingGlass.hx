package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Sprite;

class MagnifyingGlass extends DeskDocument
{
	static inline var IMG_PATH = "static/magnifying_glass.png";
	static inline var OPEN_SIZE_MULTIPLIER = 8.0;

	static inline var GLASS_CX:Float = 371;
	static inline var GLASS_CY:Float = 351;
	static inline var ZOOM:Float = 1.5;

	var glassR:Float;
	public var lensCam:FlxCamera;
	public var coverCam:FlxCamera;
	var lensMask:Shape;
	var maskAttached = false;
	var forceHidden = false;

	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		super(zones, layer, IMG_PATH, IMG_PATH, OPEN_SIZE_MULTIPLIER, false);
		closedDisplayWidth = zones.leftW * 0.2;
		useAlphaHitTest = true;
		glassR = detectGlassRadius();
		applyDisplaySize();
		placeOnClientTable();
		setupLens();
	}

	function detectGlassRadius():Float
	{
		var bmd = pixels;
		if (bmd == null)
			return 270;

		var cx = Std.int(GLASS_CX);
		var cy = Std.int(GLASS_CY);
		var maxR = Std.int(Math.min(bmd.width, bmd.height) * 0.5);
		var threshold = 30;
		var total = 0.0;
		var count = 0;

		for (i in 0...36)
		{
			var a = i * 2.0 * Math.PI / 36;
			var dx = Math.cos(a);
			var dy = Math.sin(a);
			var r = 1;
			while (r < maxR)
			{
				var px = cx + Std.int(dx * r);
				var py = cy + Std.int(dy * r);
				if (px < 0 || px >= bmd.width || py < 0 || py >= bmd.height)
					break;
				if (((bmd.getPixel32(px, py) >> 24) & 0xFF) > threshold)
				{
					total += r;
					count++;
					break;
				}
				r++;
			}
		}

		return count > 0 ? total / count : 270;
	}

	function setupLens():Void
	{
		lensCam = new FlxCamera(0, 0, 10, 10, ZOOM);
		lensCam.bgColor = 0x00000000;
		FlxG.cameras.add(lensCam, false);

		coverCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1.0);
		coverCam.bgColor = 0x00000000;
		FlxG.cameras.add(coverCam, false);

		lensCam.visible = false;
		coverCam.visible = false;

		lensMask = new Shape();
	}

	public function setHidden(hidden:Bool):Void
	{
		forceHidden = hidden;
		syncLens();
	}

	override public function hitsPoint(point:FlxPoint):Bool
	{
		if (!overlapsPoint(point))
			return false;
		if (pixelsOverlapPoint(point, alphaThreshold))
			return true;
		return isInsideGlassCircle(point);
	}

	function isInsideGlassCircle(point:FlxPoint):Bool
	{
		var s = Math.abs(scale.x);
		var relCx = GLASS_CX * s;
		var relCy = GLASS_CY * s;
		var hw = width * 0.5;
		var hh = height * 0.5;
		var rad = angle * Math.PI / 180.0;
		var cosA = Math.cos(rad);
		var sinA = Math.sin(rad);
		var gcx = x + (relCx - hw) * cosA - (relCy - hh) * sinA + hw;
		var gcy = y + (relCx - hw) * sinA + (relCy - hh) * cosA + hh;
		var sr = glassR * s;
		var dx = point.x - gcx;
		var dy = point.y - gcy;
		return dx * dx + dy * dy <= sr * sr;
	}

	function glassCenterWorld():{x:Float, y:Float}
	{
		var s = Math.abs(scale.x);
		var relCx = GLASS_CX * s;
		var relCy = GLASS_CY * s;
		var hw = width * 0.5;
		var hh = height * 0.5;
		var rad = angle * Math.PI / 180.0;
		var cosA = Math.cos(rad);
		var sinA = Math.sin(rad);
		return {
			x: x + (relCx - hw) * cosA - (relCy - hh) * sinA + hw,
			y: y + (relCx - hw) * sinA + (relCy - hh) * cosA + hh
		};
	}

	override public function isOpenOnEmployerTable():Bool
	{
		if (!isOpen)
			return false;
		if (dragging)
		{
			var mouse = FlxG.mouse.getViewPosition();
			return cursorInEmployerTable(mouse.x, mouse.y);
		}
		return activeZone == EmployerTable;
	}

	override function shouldOpenOnEmployerDrop():Bool
	{
		var mouse = FlxG.mouse.getViewPosition();
		return cursorInEmployerTable(mouse.x, mouse.y);
	}

	override function shouldSnapToEmployerTableOpenOnDrop():Bool
	{
		return false;
	}

	override function getDocumentZone()
	{
		if (dragging)
			return getZoneAtCursor();
		return super.getDocumentZone();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		syncLens();
		syncDocumentLensCameras();
	}

	function syncDocumentLensCameras():Void
	{
		if (lensCam == null)
			return;

		if (DeskDocument.onLensCamerasSync != null && DeskDocument.lensSyncGroups != null)
		{
			for (group in DeskDocument.lensSyncGroups)
			{
				for (member in group.members)
				{
					if (member == null || member == this)
						continue;
					var doc = Std.downcast(member, DeskDocument);
					if (doc == null || Std.downcast(doc, Passport) != null)
						continue;
					DeskDocument.onLensCamerasSync(doc);
				}
			}
			return;
		}

		var myIndex = layer.members.indexOf(this);
		if (myIndex < 0)
			return;

		for (i in 0...layer.members.length)
		{
			if (i == myIndex)
				continue;
			var member = layer.members[i];
			if (member == null)
				continue;
			var doc = Std.downcast(member, DeskDocument);
			if (doc == null)
				continue;
			if (Std.downcast(doc, Passport) != null)
				continue;

			var shouldZoom = DeskDocument.shouldUseLensMagnifier(doc, i, myIndex);
			var shouldCover = !shouldZoom && DeskDocument.usesMagnifierCoverLayer(doc);

			var cams = doc.cameras;
			var hasLens = cams.indexOf(lensCam) >= 0;
			var hasCover = coverCam != null && cams.indexOf(coverCam) >= 0;

			if (hasLens != shouldZoom || hasCover != shouldCover)
			{
				var updated = [FlxG.camera];
				if (shouldZoom)
					updated.push(lensCam);
				if (shouldCover && coverCam != null)
					updated.push(coverCam);
				doc.cameras = updated;
			}
		}
	}

	function syncLens():Void
	{
		if (lensCam == null)
			return;

		if (forceHidden || !visible || !isOpen || frameWidth < 1)
		{
			lensCam.visible = false;
			if (coverCam != null)
				coverCam.visible = false;
			return;
		}
		lensCam.visible = true;
		if (coverCam != null)
			coverCam.visible = true;

		var s = Math.abs(scale.x);
		var relCx = GLASS_CX * s;
		var relCy = GLASS_CY * s;
		var hw = width * 0.5;
		var hh = height * 0.5;
		var rad = angle * Math.PI / 180.0;
		var cosA = Math.cos(rad);
		var sinA = Math.sin(rad);
		var gcx = x + (relCx - hw) * cosA - (relCy - hh) * sinA + hw;
		var gcy = y + (relCx - hw) * sinA + (relCy - hh) * cosA + hh;
		var sr = glassR * s;

		var d = Std.int(Math.max(10, sr * 2));
		var camL = Std.int(gcx - d * 0.5);
		var camT = Std.int(gcy - d * 0.5);

		lensCam.x = camL;
		lensCam.y = camT;
		lensCam.width = d;
		lensCam.height = d;
		lensCam.scroll.x = gcx - d / (2.0 * ZOOM);
		lensCam.scroll.y = gcy - d / (2.0 * ZOOM);

		updateMask();

		if (DeskDocument.onDeskPropsLensSync != null)
			DeskDocument.onDeskPropsLensSync();
	}

	function updateMask():Void
	{
		if (lensCam.flashSprite == null)
			return;

		if (!maskAttached)
		{
			lensCam.flashSprite.addChild(lensMask);
			lensCam.flashSprite.mask = lensMask;
			maskAttached = true;
		}

		var cx = 0.0;
		var cy = 0.0;
		var r:Float = lensCam.width * 0.5;

		if (lensCam.flashSprite.numChildren > 0)
		{
			var scrollRectChild = Std.downcast(lensCam.flashSprite.getChildAt(0), Sprite);
			if (scrollRectChild != null && scrollRectChild.scrollRect != null)
			{
				var sr = scrollRectChild.scrollRect;
				r = Math.min(sr.width, sr.height) / (2.0 * ZOOM);
				cx = scrollRectChild.x + sr.width / (2.0 * ZOOM);
				cy = scrollRectChild.y + sr.height / (2.0 * ZOOM);
			}
		}

		lensMask.graphics.clear();
		lensMask.graphics.beginFill(0xFFFFFF);
		lensMask.graphics.drawCircle(cx, cy, r);
		lensMask.graphics.endFill();
	}
}
