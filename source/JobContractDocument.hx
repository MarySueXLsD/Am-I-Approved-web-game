package;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

class JobContractDocument extends DeskDocument
{
	static inline var OPEN_SIZE_MULTIPLIER = 6.0;
	static inline var NAME_SCAN_PAD = 3.0;

	var layout:JobContractLayout;
	var variant:JobContractVariant;

	public function new(zones:LayoutZones, layer:FlxGroup, variant:JobContractVariant)
	{
		this.variant = variant;
		layout = JobContractLayouts.get(variant);
		super(zones, layer, layout.documentPath, layout.documentPath, OPEN_SIZE_MULTIPLIER, false);
	}

	public function getVariant():JobContractVariant
	{
		return variant;
	}

	public function getLayout():JobContractLayout
	{
		return layout;
	}

	override public function resolveScanBoundsAt(point:FlxPoint):Null<ScanBounds>
	{
		if (!visible || !hitsPoint(point))
			return null;

		if (isOpen)
		{
			var partBounds = regionScanBoundsAt(point, layout.nameScan);
			if (partBounds != null)
				return partBounds;

			partBounds = regionScanBoundsAt(point, layout.salaryScan);
			if (partBounds != null)
				return partBounds;
		}

		return {
			x: x,
			y: y,
			w: width,
			h: height
		};
	}

	override function shouldOpenOnEmployerDrop():Bool
	{
		var mouse = flixel.FlxG.mouse.getViewPosition();
		if (LoanFolderDocument.blocksOpenWhileDraggingOver(mouse.x, mouse.y))
			return false;
		return super.shouldOpenOnEmployerDrop();
	}

	override function shouldSnapToEmployerTableOpenOnDrop():Bool
	{
		return false;
	}

	override public function rejectsPrinterAndShredder():Bool
	{
		return true;
	}

	function regionScanBoundsAt(point:FlxPoint, scan:{x:Float, y:Float, w:Float, h:Float, ?pad:Null<Float>}):Null<ScanBounds>
	{
		var sx = frameWidth > 0 ? width / frameWidth : 1.0;
		var sy = frameHeight > 0 ? height / frameHeight : 1.0;
		var bounds:ScanBounds = {
			x: x + scan.x * sx,
			y: y + scan.y * sy,
			w: scan.w * sx,
			h: scan.h * sy,
			pad: scan.pad != null ? scan.pad : NAME_SCAN_PAD
		};

		if (point.x >= bounds.x && point.x < bounds.x + bounds.w
			&& point.y >= bounds.y && point.y < bounds.y + bounds.h)
			return bounds;

		return null;
	}
}
