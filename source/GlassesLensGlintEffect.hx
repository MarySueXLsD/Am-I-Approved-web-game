package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;

private typedef LensDef = {
	var cxRatio:Float;
	var cyRatio:Float;
	var halfWRatio:Float;
	var halfHRatio:Float;
}

class GlassesLensGlintEffect extends FlxGroup
{
	static var LEFT_LENS:LensDef = {
		cxRatio: 0.78,
		cyRatio: 0.45,
		halfWRatio: 0.028,
		halfHRatio: 0.042
	};

	static var RIGHT_LENS:LensDef = {
		cxRatio: 0.91,
		cyRatio: 0.52,
		halfWRatio: 0.032,
		halfHRatio: 0.042
	};

	static inline var SWEEP_DURATION = 3.0;
	static inline var WAIT_DURATION = 3.0;
	static inline var CYCLE_DURATION = SWEEP_DURATION + WAIT_DURATION;
	static inline var LINE_SLOPE = -0.38;
	static inline var BASE_LINE_WIDTH = 2.4;
	static inline var SWEEP_STEPS = 90;

	var leftLens:FlxSprite;
	var rightLens:FlxSprite;
	var cycleTime = 0.0;
	var sweepT = 0.0;
	var isSweeping = true;
	var hasLayout = false;
	var clearedForWait = false;
	var lastDrawStep = -1;
	var lineWidth = 2.0;
	var screenW = 800.0;
	var screenH = 600.0;

	public function new()
	{
		super();

		leftLens = new FlxSprite();
		rightLens = new FlxSprite();
		add(leftLens);
		add(rightLens);

		visible = false;
	}

	public function layout(screenW:Float, screenH:Float):Void
	{
		this.screenW = screenW;
		this.screenH = screenH;
		lineWidth = BASE_LINE_WIDTH * (screenH / 600.0);
		hasLayout = true;

		layoutLens(leftLens, LEFT_LENS);
		layoutLens(rightLens, RIGHT_LENS);

		cycleTime = 0;
		sweepT = 0;
		isSweeping = true;
		clearedForWait = false;
		lastDrawStep = -1;
		redrawIfNeeded(true);
	}

	public function resetEffect():Void
	{
		cycleTime = 0;
		sweepT = 0;
		isSweeping = true;
		clearedForWait = false;
		lastDrawStep = -1;
		redrawIfNeeded(true);
	}

	override function update(elapsed:Float):Void
	{
		if (!visible || !hasLayout)
			return;

		cycleTime += elapsed;
		while (cycleTime >= CYCLE_DURATION)
			cycleTime -= CYCLE_DURATION;

		if (cycleTime < SWEEP_DURATION)
		{
			isSweeping = true;
			clearedForWait = false;
			sweepT = cycleTime / SWEEP_DURATION;
			redrawIfNeeded(false);
		}
		else
		{
			isSweeping = false;
			sweepT = 0;
			if (!clearedForWait)
			{
				clearBothLenses();
				clearedForWait = true;
				lastDrawStep = -1;
			}
		}

		super.update(elapsed);
	}

	function layoutLens(spr:FlxSprite, lens:LensDef):Void
	{
		var w = Std.int(Math.max(8, screenW * lens.halfWRatio * 2.0));
		var h = Std.int(Math.max(8, screenH * lens.halfHRatio * 2.0));
		spr.setPosition(
			screenW * lens.cxRatio - w * 0.5,
			screenH * lens.cyRatio - h * 0.5
		);
		spr.setGraphicSize(w, h);
		spr.updateHitbox();
	}

	function redrawIfNeeded(force:Bool):Void
	{
		if (!isSweeping)
			return;

		var step = Std.int(sweepT * SWEEP_STEPS);
		if (!force && step == lastDrawStep)
			return;

		lastDrawStep = step;
		drawLensGlint(leftLens, LEFT_LENS);
		drawLensGlint(rightLens, RIGHT_LENS);
	}

	function clearBothLenses():Void
	{
		clearLens(leftLens, LEFT_LENS);
		clearLens(rightLens, RIGHT_LENS);
	}

	function clearLens(spr:FlxSprite, lens:LensDef):Void
	{
		var w = Std.int(Math.max(8, screenW * lens.halfWRatio * 2.0));
		var h = Std.int(Math.max(8, screenH * lens.halfHRatio * 2.0));
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		spr.dirty = true;
	}

	function drawLensGlint(spr:FlxSprite, lens:LensDef):Void
	{
		var w = Std.int(Math.max(8, screenW * lens.halfWRatio * 2.0));
		var h = Std.int(Math.max(8, screenH * lens.halfHRatio * 2.0));
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);

		var bmp = spr.pixels;
		var cx = w * 0.5;
		var cy = h * 0.5;
		var rx = cx - 1.0;
		var ry = cy - 1.0;
		var lineX = -rx + sweepT * rx * 2.0;
		var lw = lineWidth;

		for (py in 0...h)
		{
			for (px in 0...w)
			{
				var dx = (px - cx) / rx;
				var dy = (py - cy) / ry;
				if (dx * dx + dy * dy > 1.0)
					continue;

				var lineDist = Math.abs((px - cx) - (py - cy) * LINE_SLOPE - lineX);
				if (lineDist > lw)
					continue;

				var edge = 1.0 - lineDist / lw;
				var lensEdge = 1.0 - (dx * dx + dy * dy);
				if (lensEdge < 0)
					lensEdge = 0;

				var alpha = Std.int(255 * edge * edge * lensEdge * 0.72);
				if (alpha > 0)
					bmp.setPixel32(px, py, (alpha << 24) | 0x00FFFFFF);
			}
		}

		spr.dirty = true;
	}
}
