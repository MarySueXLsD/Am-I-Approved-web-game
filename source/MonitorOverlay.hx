package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.filters.BlurFilter;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class MonitorOverlay extends FlxGroup
{
	static inline var SLIDE_DURATION = 0.5;
	static inline var SCREEN_FILL_RATIO = 0.9;
	static inline var BLUR_X = 8.0;
	static inline var BLUR_Y = 8.0;
	static inline var BLUR_QUALITY = 2;
	static inline var ALPHA_HIT_THRESHOLD = 32;

	static inline var INNER_X = 84;
	static inline var INNER_Y = 86;
	static inline var INNER_W = 633;
	static inline var INNER_H = 442;

	static inline var SCANLINE_THICKNESS = 8;
	static inline var SCANLINE_SPEED = 1.3;

	var backdrop:FlxSprite;
	var monitor:FlxSprite;
	var screenUi:MonitorScreenUi;
	var crtOverlay:FlxSprite;
	var animOverlay:FlxSprite;
	var animBmp:BitmapData;
	var slideTween:FlxTween;
	var targetX:Float;
	var targetY:Float;
	var uiInitialized = false;
	var blurGraphicKey:String;
	var crtGraphicKey:String;
	var animGraphicKey:String;
	var captureOnPostDraw:Void->Void;
	var lastCrtW:Int = 0;
	var lastCrtH:Int = 0;

	var scanLineT:Float = -1.0;
	var scanLineCooldown:Float = 3.0;
	var distortTimer:Float = -1.0;
	var distortCooldown:Float = 5.0;
	var distortBands:Array<{y:Int, h:Int, color:Int}>;

	public var isShowing(default, null) = false;
	public var isAnimating(default, null) = false;
	public var pendingCapture(default, null) = false;

	static var instance:MonitorOverlay;

	var captureWaitFrames = 0;
	static inline var CAPTURE_TIMEOUT_FRAMES = 30;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isActive();
	}

	public static function pausesDialogue():Bool
	{
		if (instance == null || !instance.isShowing)
			return false;
		return instance.visible || instance.isAnimating;
	}

	public function isActive():Bool
	{
		return isShowing || pendingCapture;
	}

	public var isBusy(get, never):Bool;

	function get_isBusy():Bool
	{
		return isAnimating || pendingCapture;
	}

	public function new()
	{
		super();
		instance = this;

		backdrop = new FlxSprite();
		backdrop.visible = false;
		add(backdrop);

		monitor = new FlxSprite();
		monitor.loadGraphic("static/monitor.png");
		fillInnerScreen(monitor);
		monitor.visible = false;
		add(monitor);

		screenUi = new MonitorScreenUi();
		screenUi.visible = false;
		add(screenUi);

		crtOverlay = new FlxSprite();
		crtOverlay.visible = false;
		add(crtOverlay);

		animOverlay = new FlxSprite();
		animOverlay.visible = false;
		add(animOverlay);

		distortBands = [];
		visible = false;
	}

	public function containsInteractivePoint(p:FlxPoint):Bool
	{
		if (!monitor.visible)
			return false;
		if (containsOpaquePoint(p))
			return true;
		return screenUi.visible && screenUi.containsPoint(p.x, p.y);
	}

	public function handleScreenClick(p:FlxPoint):Bool
	{
		if (!screenUi.visible)
			return false;
		return screenUi.handleClick(p.x, p.y);
	}

	public function updateScreenInput(p:FlxPoint):Void
	{
		if (!screenUi.visible)
			return;
		screenUi.updateInput(p.x, p.y);
	}

	public function handleScreenRelease():Void
	{
		if (!screenUi.visible)
			return;
		screenUi.handleRelease();
	}

	public function setOnPrintRequest(cb:Void->Bool):Void
	{
		screenUi.onPrintRequest = cb;
	}

	public function show():Void
	{
		if (isAnimating || pendingCapture)
			return;

		cancelCaptureListener();
		applyDisplaySize();
		backdrop.visible = false;
		monitor.visible = false;
		visible = false;
		pendingCapture = true;
		captureWaitFrames = 0;

		captureOnPostDraw = onPostDrawCapture;
		FlxG.signals.postDraw.add(captureOnPostDraw);
	}

	public function hide():Void
	{
		if (pendingCapture)
		{
		cancelCaptureListener();
		isShowing = false;
		visible = false;
		screenUi.suspendInput();
		screenUi.visible = false;
		crtOverlay.visible = false;
		animOverlay.visible = false;
		return;
		}

		if (!isShowing || isAnimating)
			return;

		screenUi.suspendInput();
		isAnimating = true;

		if (slideTween != null)
		{
			slideTween.cancel();
			slideTween = null;
		}

		slideTween = FlxTween.tween(monitor, {x: -monitor.width}, SLIDE_DURATION, {
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				backdrop.visible = false;
				monitor.visible = false;
				visible = false;
				isShowing = false;
				isAnimating = false;
				screenUi.suspendInput();
				screenUi.visible = false;
				crtOverlay.visible = false;
				animOverlay.visible = false;
				slideTween = null;
			}
		});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (pendingCapture)
		{
			captureWaitFrames++;
			if (captureWaitFrames >= CAPTURE_TIMEOUT_FRAMES)
				cancelPendingShow();
			return;
		}

		if (!screenUi.visible || !monitor.visible)
			return;

		syncScreenUi();
		if (!isAnimating)
		{
			screenUi.updateHoverState();
			updateCrtEffects(elapsed);
		}
	}

	function syncScreenUi():Void
	{
		var sx = monitor.scale.x;
		var sy = monitor.scale.y;
		var ix = monitor.x + INNER_X * sx;
		var iy = monitor.y + INNER_Y * sy;
		var iw = INNER_W * sx;
		var ih = INNER_H * sy;
		screenUi.syncScreen(ix, iy, iw, ih);
		syncCrtOverlay(ix, iy, iw, ih);
	}

	function prepareScreenUi():Void
	{
		if (!uiInitialized)
		{
			uiInitialized = true;
			screenUi.reset();
		}
		screenUi.visible = true;
		scanLineT = -1.0;
		scanLineCooldown = 2.0 + Math.random() * 4.0;
		distortTimer = -1.0;
		distortCooldown = 3.0 + Math.random() * 5.0;
		syncScreenUi();
	}

	function onPostDrawCapture():Void
	{
		if (!pendingCapture)
			return;

		cancelCaptureListener();
		captureBackdrop();
		isShowing = true;
		visible = true;
		beginSlideIn();
	}

	function cancelCaptureListener():Void
	{
		pendingCapture = false;
		captureWaitFrames = 0;
		if (captureOnPostDraw != null)
		{
			FlxG.signals.postDraw.remove(captureOnPostDraw);
			captureOnPostDraw = null;
		}
	}

	function cancelPendingShow():Void
	{
		cancelCaptureListener();
		visible = false;
		screenUi.visible = false;
		crtOverlay.visible = false;
		animOverlay.visible = false;
	}

	public function containsOpaquePoint(p:FlxPoint):Bool
	{
		if (!monitor.visible)
			return false;

		if (!monitor.overlapsPoint(p))
			return false;

		var lx = Std.int((p.x - monitor.x) / monitor.scale.x);
		var ly = Std.int((p.y - monitor.y) / monitor.scale.y);

		if (lx < 0 || ly < 0 || lx >= monitor.frameWidth || ly >= monitor.frameHeight)
			return false;

		return (monitor.pixels.getPixel32(lx, ly) >>> 24) >= ALPHA_HIT_THRESHOLD;
	}

	function beginSlideIn():Void
	{
		targetX = (FlxG.width - monitor.width) * 0.5;
		targetY = (FlxG.height - monitor.height) * 0.5;
		monitor.setPosition(-monitor.width, targetY);
		backdrop.visible = true;
		monitor.visible = true;
		prepareScreenUi();
		isAnimating = true;

		if (slideTween != null)
		{
			slideTween.cancel();
			slideTween = null;
		}

		slideTween = FlxTween.tween(monitor, {x: targetX}, SLIDE_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				isAnimating = false;
				slideTween = null;
			}
		});
	}

	function captureBackdrop():Void
	{
		var copy = captureScreen();
		if (copy == null)
			return;

		applyBlur(copy);

		if (blurGraphicKey != null)
			FlxG.bitmap.removeByKey(blurGraphicKey);

		blurGraphicKey = 'monitor_blur_${Std.int(Math.random() * 1e9)}';
		var graphic = FlxG.bitmap.add(copy, false, blurGraphicKey);
		backdrop.loadGraphic(graphic, false);
		backdrop.setGraphicSize(FlxG.width, FlxG.height);
		backdrop.setPosition(0, 0);
		backdrop.updateHitbox();
	}

	function captureScreen():BitmapData
	{
		var w = Std.int(FlxG.width);
		var h = Std.int(FlxG.height);
		var cam = FlxG.camera;

		if (FlxG.renderBlit && cam.buffer != null)
		{
			var blitCopy = new BitmapData(w, h, true, 0);
			blitCopy.copyPixels(cam.buffer, new Rectangle(0, 0, w, h), new Point(0, 0));
			return blitCopy;
		}

		var copy = new BitmapData(w, h, true, cam.bgColor);
		var matrix = new Matrix(1, 0, 0, 1, cam.flashSprite.x, cam.flashSprite.y);
		copy.draw(cam.flashSprite, matrix, null, null, new Rectangle(0, 0, w, h), true);
		return copy;
	}

	function applyBlur(bmp:BitmapData):Void
	{
		var filter = new BlurFilter(BLUR_X, BLUR_Y, BLUR_QUALITY);
		bmp.applyFilter(bmp, bmp.rect, new Point(0, 0), filter);
	}

	function syncCrtOverlay(ix:Float, iy:Float, iw:Float, ih:Float):Void
	{
		var w = Std.int(iw);
		var h = Std.int(ih);
		if (w < 4 || h < 4)
			return;

		if (w != lastCrtW || h != lastCrtH)
		{
			buildCrtOverlay(w, h);
			ensureAnimBmp(w, h);
		}

		crtOverlay.setPosition(ix, iy);
		crtOverlay.visible = monitor.visible;
		animOverlay.setPosition(ix, iy);
	}

	function buildCrtOverlay(w:Int, h:Int):Void
	{
		lastCrtW = w;
		lastCrtH = h;

		var bmp = new BitmapData(w, h, true, 0x00000000);
		bmp.lock();

		var hw = w * 0.5;
		var hh = h * 0.5;

		for (py in 0...h)
		{
			var ny = (py - hh) / hh;
			var ny2 = ny * ny;

			for (px in 0...w)
			{
				var nx = (px - hw) / hw;
				var nx2 = nx * nx;

				var hCurve = nx2;
				var vCurve = ny2 * 0.3;
				var cross = nx2 * ny2 * 0.4;
				var vig = hCurve + vCurve + cross;

				var darkA = vig * 70.0;
				if (darkA > 95.0)
					darkA = 95.0;

				var gx = nx * 0.85;
				var gy = ny * 1.15;
				var gd = Math.sqrt(gx * gx + gy * gy);
				var glow = 1.0 - gd * 1.2;
				if (glow < 0.0)
					glow = 0.0;
				glow = glow * glow * glow * 22.0;

				var edgeX = nx2 * nx2;
				var rim = edgeX * (1.0 - ny2 * 0.4);
				if (rim > 1.0)
					rim = 1.0;
				var rimGlow = rim * 15.0;

				var bright = glow + rimGlow;
				var r = Std.int(bright * 0.7);
				var g = Std.int(bright);
				var b = Std.int(bright * 0.75);
				if (r > 255)
					r = 255;
				if (g > 255)
					g = 255;
				if (b > 255)
					b = 255;

				var a = Std.int(darkA);
				if (bright > 0.5)
				{
					var ba = Std.int(bright * 4.0);
					if (ba > a)
						a = ba;
				}
				if (a > 255)
					a = 255;

				if (py % 2 == 0)
				{
					var scanAlpha = Std.int(100 * (1.0 - vig * 0.3));
					if (scanAlpha < 50) scanAlpha = 50;
					a = Std.int(Math.min(255, a + scanAlpha));
				}

				if (a > 0)
					bmp.setPixel32(px, py, (a << 24) | (r << 16) | (g << 8) | b);
			}
		}

		bmp.unlock();

		if (crtGraphicKey != null)
			FlxG.bitmap.removeByKey(crtGraphicKey);

		crtGraphicKey = 'crt_overlay_${Std.int(Math.random() * 1e9)}';
		var graphic = FlxG.bitmap.add(bmp, false, crtGraphicKey);
		crtOverlay.loadGraphic(graphic, false);
		crtOverlay.updateHitbox();
		crtOverlay.shader = new BarrelShader();
	}

	function ensureAnimBmp(w:Int, h:Int):Void
	{
		if (animBmp != null && animBmp.width == w && animBmp.height == h)
			return;

		animBmp = new BitmapData(w, h, true, 0x00000000);

		if (animGraphicKey != null)
			FlxG.bitmap.removeByKey(animGraphicKey);

		animGraphicKey = 'crt_anim_${Std.int(Math.random() * 1e9)}';
		var graphic = FlxG.bitmap.add(animBmp, false, animGraphicKey);
		animOverlay.loadGraphic(graphic, false);
		animOverlay.updateHitbox();
		animOverlay.shader = new BarrelShader();
	}

	function updateCrtEffects(elapsed:Float):Void
	{
		if (animBmp == null || lastCrtW < 4 || lastCrtH < 4)
			return;

		var anyActive = false;

		scanLineCooldown -= elapsed;
		if (scanLineT >= 0.0)
		{
			scanLineT += SCANLINE_SPEED * elapsed;
			if (scanLineT > 1.15)
			{
				scanLineT = -1.0;
				scanLineCooldown = 4.0 + Math.random() * 8.0;
			}
			else
				anyActive = true;
		}
		else if (scanLineCooldown <= 0.0)
		{
			scanLineT = -0.05;
			anyActive = true;
		}

		distortCooldown -= elapsed;
		if (distortTimer > 0.0)
		{
			distortTimer -= elapsed;
			anyActive = true;
			if (distortTimer <= 0.0)
				distortCooldown = 3.0 + Math.random() * 6.0;
		}
		else if (distortCooldown <= 0.0)
		{
			spawnDistortion();
			anyActive = true;
		}

		if (anyActive)
		{
			drawAnimEffects();
			animOverlay.visible = true;
		}
		else
			animOverlay.visible = false;
	}

	function drawAnimEffects():Void
	{
		if (animBmp == null)
			return;

		animBmp.lock();
		animBmp.fillRect(animBmp.rect, 0x00000000);

		if (scanLineT >= 0.0 && scanLineT <= 1.1)
			drawTravelingScanLine();

		if (distortTimer > 0.0)
			drawDistortionBands();

		animBmp.unlock();
		animOverlay.dirty = true;
	}

	function drawTravelingScanLine():Void
	{
		var w = lastCrtW;
		var h = lastCrtH;
		var halfThick:Float = SCANLINE_THICKNESS * 0.5;
		var baseY = scanLineT * h;

		var minY = Std.int(baseY - halfThick);
		var maxY = Std.int(baseY + halfThick);
		if (minY < 0)
			minY = 0;
		if (maxY >= h)
			maxY = h - 1;

		for (py in minY...maxY + 1)
		{
			var dist = Math.abs(py - baseY) / halfThick;
			var intensity = 1.0 - dist;
			if (intensity < 0.0)
				intensity = 0.0;
			intensity *= intensity;

			var ia = Std.int(intensity * 85);
			var ig = Std.int(intensity * 170);
			var iw = Std.int(intensity * 130);
			if (ia > 0)
			{
				var color = (ia << 24) | (iw << 16) | (ig << 8) | iw;
				for (px in 0...w)
					animBmp.setPixel32(px, py, color);
			}
		}
	}

	function spawnDistortion():Void
	{
		distortTimer = 0.06 + Math.random() * 0.14;
		distortBands = [];
		var count = 2 + Std.int(Math.random() * 3);
		for (i in 0...count)
		{
			var by = Std.int(Math.random() * lastCrtH);
			var bh = 2 + Std.int(Math.random() * 6);
			var bright = Std.int(12 + Math.random() * 38);
			var alpha = Std.int(22 + Math.random() * 52);
			var r = Std.int(bright * 0.7);
			var g = bright;
			var b = Std.int(bright * 0.8);
			distortBands.push({y: by, h: bh, color: (alpha << 24) | (r << 16) | (g << 8) | b});
		}
	}

	function drawDistortionBands():Void
	{
		var w = lastCrtW;
		var h = lastCrtH;

		for (band in distortBands)
		{
			var yEnd = band.y + band.h;
			if (yEnd > h)
				yEnd = h;
			if (band.y < 0 || band.y >= h)
				continue;

			for (py in band.y...yEnd)
				for (px in 0...w)
					animBmp.setPixel32(px, py, band.color);
		}
	}

	function fillInnerScreen(sprite:FlxSprite):Void
	{
		sprite.pixels.fillRect(new Rectangle(INNER_X, INNER_Y, INNER_W, INNER_H), 0xFF000000);
		sprite.dirty = true;
	}

	function applyDisplaySize():Void
	{
		var maxW = FlxG.width * SCREEN_FILL_RATIO;
		var maxH = FlxG.height * SCREEN_FILL_RATIO;
		var scale = Math.min(maxW / monitor.frameWidth, maxH / monitor.frameHeight);
		monitor.setGraphicSize(Std.int(monitor.frameWidth * scale), Std.int(monitor.frameHeight * scale));
		monitor.updateHitbox();
	}
}
