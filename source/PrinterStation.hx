package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
class PrinterStation extends FlxGroup
{
	static inline var TEX_YELLOW_X = 57;
	static inline var TEX_YELLOW_Y = 463;
	static inline var TEX_GREEN_X = 143;
	static inline var TEX_GREEN_Y = 463;
	static inline var TEX_LED_RADIUS = 27;
	static inline var BORDER_PX = 5;

	static inline var YELLOW_ON = 0xFFFFE033;
	static inline var GREEN_ON = 0xFF39E06E;
	static inline var BORDER = 0xFF000000;

	static inline var BLINK_PERIOD = 0.9;
	static inline var PAPER_LEFT_X = 277.0;
	static inline var PAPER_RIGHT_X = 558.0;
	static inline var PAPER_START_Y = 118.0;
	static inline var PAPER_END_Y = -70.0;
	static inline var PAPER_FEED_DURATION = 3.0;
	static inline var DEFAULT_FEED_PAPER_PATH = "static/copy_paper_small.png";
	static inline var SCANNER_LEFT = 278.0;
	static inline var SCANNER_TOP = 201.0;
	static inline var SCANNER_RIGHT = 710.0;
	static inline var SCANNER_BOTTOM = 481.0;
	static inline var SCAN_DOC_X = 500.0;
	static inline var SCAN_DOC_Y = 340.0;
	static inline var SCAN_DURATION = 3.0;
	static inline var SCAN_LINE_WIDTH = 8.0;

	var body:FlxSprite;
	var paper:FlxSprite;
	var scanPreview:FlxSprite;
	var scanLine:FlxSprite;
	var yellowGlow:FlxSprite;
	var greenGlow:FlxSprite;
	var yellowBorder:FlxSprite;
	var yellowLed:FlxSprite;
	var greenBorder:FlxSprite;
	var greenLed:FlxSprite;
	var paperTween:FlxTween;
	var scanLineTween:FlxTween;
	var scanLineProgress = 0.0;
	var isScanning = false;
	var isPrinting = false;
	var printCompleted = false;
	var lastScannedDoc:DeskDocument;
	var terminalPrintJob:TerminalPrintJob = TerminalPrintJob.None;
	var isPaused = false;
	var blinkTimer = 0.0;
	var texW:Float;
	var texH:Float;
	var basePaperWidth = 0.0;
	var feedPaperPath = DEFAULT_FEED_PAPER_PATH;

	public function new(x:Float, tableY:Float, tableH:Float, targetHeight:Float, employerX:Float, employerY:Float, employerW:Float, employerH:Float, clientTableX:Float,
			clientTableY:Float, clientTableW:Float, clientTableH:Float)
	{
		super();

		body = new FlxSprite(x, tableY);
		body.loadGraphic("static/printer.png");
		texW = body.frameWidth;
		texH = body.frameHeight;

		var scale = targetHeight / texH;
		body.scale.set(scale, scale);
		body.updateHitbox();
		body.y = tableY + tableH - body.height;

		yellowGlow = makeGlowSprite(YELLOW_ON);
		yellowGlow.blend = BlendMode.ADD;
		greenGlow = makeGlowSprite(GREEN_ON);
		greenGlow.blend = BlendMode.ADD;
		yellowBorder = makeLedBorderSprite();
		yellowLed = makeLedFillSprite(YELLOW_ON);
		greenBorder = makeLedBorderSprite();
		greenLed = makeLedFillSprite(GREEN_ON);
		paper = new FlxSprite();
		paper.loadGraphic(feedPaperPath);

		add(body);
		add(paper);
		add(yellowGlow);
		add(greenGlow);
		add(yellowBorder);
		add(yellowLed);
		add(greenBorder);
		add(greenLed);

		syncLedPositions();
		syncPaperPosition();
		paper.visible = false;
	}

	public function setExclusionZones(calculatorX:Float, calculatorY:Float, calculatorW:Float, calculatorH:Float, shredderX:Float, shredderY:Float, shredderW:Float,
			shredderH:Float):Void
	{
		// Kept for API compatibility with existing PlayState wiring.
	}

	public function setStationCameras(cams:Array<FlxCamera>):Void
	{
		body.cameras = cams;
		paper.cameras = cams;
		yellowGlow.cameras = cams;
		greenGlow.cameras = cams;
		yellowBorder.cameras = cams;
		yellowLed.cameras = cams;
		greenBorder.cameras = cams;
		greenLed.cameras = cams;
		if (scanPreview != null)
			scanPreview.cameras = cams;
		if (scanLine != null)
			scanLine.cameras = cams;
	}

	public function setFeedPaperGraphic(path:String):Void
	{
		feedPaperPath = path != null && path != "" ? path : DEFAULT_FEED_PAPER_PATH;
		paper.loadGraphic(feedPaperPath);
		syncPaperPosition();
	}

	public function resetFeedPaperGraphic():Void
	{
		setFeedPaperGraphic(DEFAULT_FEED_PAPER_PATH);
	}

	public function animatePaperFeed():Void
	{
		if (paper.graphic == null || paper.graphic.key != feedPaperPath)
			paper.loadGraphic(feedPaperPath);

		var s = body.scale.x;
		isPrinting = true;
		printCompleted = false;
		paper.angle = 0;
		if (paperTween != null)
		{
			paperTween.cancel();
			paperTween = null;
		}
		paper.x = body.x + PAPER_LEFT_X * s;
		paper.y = body.y + PAPER_START_Y * s;
		paper.visible = true;
		paperTween = FlxTween.tween(paper, {y: body.y + PAPER_END_Y * s}, PAPER_FEED_DURATION, {
			ease: FlxEase.linear,
			onComplete: function(_)
			{
				isPrinting = false;
				printCompleted = true;
				paperTween = null;
				updatePaperClip();
			}
		});
	}

	public function canAcceptDocument():Bool
	{
		return !isScanning && !isPrinting && !printCompleted;
	}

	public function notifyPrintedPaperPickedUp():Void
	{
		if (!printCompleted)
			return;
		printCompleted = false;
		paper.clipRect = null;
		paper.visible = false;
		resetFeedPaperGraphic();
	}

	public function hasPrintedPaperReady():Bool
	{
		return printCompleted;
	}

	public function tryPickupPrintedPaper(mx:Float, my:Float):Bool
	{
		if (!printCompleted || !paper.visible)
			return false;
		return mx >= paper.x && mx < paper.x + paper.width && my >= paper.y && my < paper.y + paper.height;
	}

	public function getPrintedPaperCenterX():Float
	{
		return paper.x + paper.width * 0.5;
	}

	public function getPrintedPaperCenterY():Float
	{
		return paper.y + paper.height * 0.5;
	}

	public function hasActiveJob():Bool
	{
		return isScanning || isPrinting;
	}

	public function setPaused(value:Bool):Void
	{
		if (isPaused == value)
			return;

		isPaused = value;
		if (paperTween != null)
			paperTween.active = !value;
		if (scanLineTween != null)
			scanLineTween.active = !value;
	}

	public function getLastScannedDocument():DeskDocument
	{
		return lastScannedDoc;
	}

	public function setTerminalPrintJob(job:TerminalPrintJob):Void
	{
		terminalPrintJob = job;
	}

	public function consumeTerminalPrintJob():TerminalPrintJob
	{
		var job = terminalPrintJob;
		terminalPrintJob = TerminalPrintJob.None;
		return job;
	}

	public function consumePrintSource():Null<DeskDocument>
	{
		var doc = lastScannedDoc;
		lastScannedDoc = null;
		return doc;
	}

	public function clearLastScannedDocument():Void
	{
		lastScannedDoc = null;
	}

	public function resetForNewDay():Void
	{
		if (paperTween != null)
		{
			paperTween.cancel();
			paperTween = null;
		}
		clearScanVisuals();
		isScanning = false;
		isPrinting = false;
		printCompleted = false;
		lastScannedDoc = null;
		terminalPrintJob = TerminalPrintJob.None;
		isPaused = false;
		paper.visible = false;
		paper.clipRect = null;
		resetFeedPaperGraphic();
	}

	public function startScan(doc:DeskDocument, onComplete:Void->Void):Void
	{
		if (!canAcceptDocument())
			return;

		lastScannedDoc = doc;
		isScanning = true;
		clearScanVisuals();

		var s = body.scale.x;
		scanPreview = new FlxSprite();
		scanPreview.loadGraphic(doc.getClosedGraphicPath());
		var previewScale = doc.getClosedDisplayScale();
		scanPreview.scale.set(previewScale, previewScale);
		scanPreview.updateHitbox();
		scanPreview.angle = 0;
		scanPreview.x = body.x + SCAN_DOC_X * s - scanPreview.width * 0.5;
		scanPreview.y = body.y + SCAN_DOC_Y * s - scanPreview.height * 0.5;

		var scannerH = (SCANNER_BOTTOM - SCANNER_TOP) * s;
		var lineW = Std.int(Math.max(2, SCAN_LINE_WIDTH * s));
		var lineH = Std.int(Math.max(2, scannerH));
		scanLine = new FlxSprite();
		scanLine.makeGraphic(lineW, lineH, 0xFF00FFCC, true);
		scanLine.blend = BlendMode.ADD;
		syncScanLinePosition(0.0);

		add(scanPreview);
		add(scanLine);
		syncScanVisualCameras();

		scanLineProgress = 0.0;
		scanLineTween = FlxTween.tween(this, {scanLineProgress: 1.0}, SCAN_DURATION, {
			ease: FlxEase.linear,
			onUpdate: function(_)
			{
				syncScanLinePosition(scanLineProgress);
			},
			onComplete: function(_)
			{
				scanLineTween = null;
				isScanning = false;
				clearScanVisuals();
				if (onComplete != null)
					onComplete();
			}
		});
	}

	function syncScanLinePosition(t:Float):Void
	{
		if (scanLine == null)
			return;

		var s = body.scale.x;
		var left = body.x + SCANNER_LEFT * s;
		var right = body.x + SCANNER_RIGHT * s;
		var top = body.y + SCANNER_TOP * s;
		scanLine.x = left + (right - left - scanLine.width) * t;
		scanLine.y = top;
	}

	function clearScanVisuals():Void
	{
		if (scanLineTween != null)
		{
			scanLineTween.cancel();
			scanLineTween = null;
		}
		if (scanPreview != null)
		{
			remove(scanPreview, true);
			scanPreview = null;
		}
		if (scanLine != null)
		{
			remove(scanLine, true);
			scanLine = null;
		}
	}

	function syncScanVisualCameras():Void
	{
		if (scanPreview == null || scanLine == null)
			return;
		var cams = body.cameras;
		scanPreview.cameras = cams;
		scanLine.cameras = cams;
	}

	public function getBodyX():Float
	{
		return body.x;
	}

	public function getBodyY():Float
	{
		return body.y;
	}

	public function getBodyW():Float
	{
		return body.width;
	}

	public function getBodyH():Float
	{
		return body.height;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (isPaused)
			return;

		blinkTimer += elapsed;
		var phase = blinkTimer / BLINK_PERIOD * Math.PI * 2.0;
		var pulse = 0.5 + 0.5 * Math.sin(phase);
		if (isPrinting)
		{
			// Printing: yellow dims, green blinks.
			yellowLed.alpha = 0.25;
			yellowGlow.alpha = 0.12;
			greenLed.alpha = 0.35 + 0.65 * pulse;
			greenGlow.alpha = 0.42 + 0.58 * pulse;
		}
		else if (printCompleted)
		{
			// Done: steady green, no blink.
			yellowLed.alpha = 0.2;
			yellowGlow.alpha = 0.0;
			greenLed.alpha = 1.0;
			greenGlow.alpha = 0.85;
		}
		else
		{
			// Idle: keep original yellow blink.
			yellowLed.alpha = 0.7 + 0.3 * pulse;
			yellowGlow.alpha = 0.42 + 0.58 * pulse;
			greenLed.alpha = 0.35;
			greenGlow.alpha = 0.2;
		}
		updatePaperClip();
	}

	function syncLedPositions():Void
	{
		var s = body.scale.y;
		var ledD = (TEX_LED_RADIUS * 2 + BORDER_PX * 2) * s;
		var glowD = ledD * 2.6;

		placeLed(yellowGlow, TEX_YELLOW_X, TEX_YELLOW_Y, glowD);
		placeLed(greenGlow, TEX_GREEN_X, TEX_GREEN_Y, glowD);
		placeLed(yellowBorder, TEX_YELLOW_X, TEX_YELLOW_Y, ledD);
		placeLed(yellowLed, TEX_YELLOW_X, TEX_YELLOW_Y, ledD);
		placeLed(greenBorder, TEX_GREEN_X, TEX_GREEN_Y, ledD);
		placeLed(greenLed, TEX_GREEN_X, TEX_GREEN_Y, ledD);
	}

	function syncPaperPosition():Void
	{
		var s = body.scale.x;
		var paperW = (PAPER_RIGHT_X - PAPER_LEFT_X) * s;
		basePaperWidth = paperW;
		paper.setGraphicSize(Std.int(Math.max(1, paperW)), 0);
		paper.updateHitbox();
		paper.x = body.x + PAPER_LEFT_X * s;
		paper.y = body.y + PAPER_START_Y * s;
		paper.angle = 0;
		updatePaperClip();
	}

	function updatePaperClip():Void
	{
		if (isScanning || (!isPrinting && !printCompleted))
		{
			paper.visible = false;
			paper.clipRect = null;
			return;
		}

		var s = body.scale.x;
		var windowTop = body.y + PAPER_END_Y * s;
		var windowBottom = body.y + PAPER_START_Y * s;
		var visTop = Math.max(paper.y, windowTop);
		var visBottom = Math.min(paper.y + paper.height, windowBottom);
		if (visBottom <= visTop)
		{
			paper.visible = false;
			return;
		}

		var sx = Math.abs(paper.scale.x);
		var sy = Math.abs(paper.scale.y);
		if (paper.clipRect == null)
			paper.clipRect = FlxRect.get();
		paper.clipRect.set(0, (visTop - paper.y) / sy, paper.frameWidth, (visBottom - visTop) / sy);
		paper.visible = true;
	}

	function inRect(px:Float, py:Float, x:Float, y:Float, w:Float, h:Float):Bool
	{
		return px >= x && px < x + w && py >= y && py < y + h;
	}

	function placeLed(led:FlxSprite, texX:Float, texY:Float, drawSize:Float):Void
	{
		var s = body.scale.x;
		var cx = body.x + texX * s;
		var cy = body.y + texY * s;
		led.scale.set(drawSize / led.frameWidth, drawSize / led.frameHeight);
		led.updateHitbox();
		led.setPosition(cx - led.width * 0.5, cy - led.height * 0.5);
	}

	function makeLedFillSprite(fill:Int):FlxSprite
	{
		var outerR = TEX_LED_RADIUS + BORDER_PX;
		var size = Std.int(outerR * 2 + 1);
		var spr = new FlxSprite();
		spr.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var bmp = spr.pixels;
		var cx = (size - 1) * 0.5;
		var cy = (size - 1) * 0.5;
		var innerR = TEX_LED_RADIUS - 0.5;
		var ringOuter = outerR + 0.5;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - cx;
				var dy = py - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist > ringOuter)
					continue;
				if (dist <= innerR)
					bmp.setPixel32(px, py, fill);
			}
		}

		spr.dirty = true;
		return spr;
	}

	function makeLedBorderSprite():FlxSprite
	{
		var outerR = TEX_LED_RADIUS + BORDER_PX;
		var size = Std.int(outerR * 2 + 1);
		var spr = new FlxSprite();
		spr.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var bmp = spr.pixels;
		var cx = (size - 1) * 0.5;
		var cy = (size - 1) * 0.5;
		var innerR = TEX_LED_RADIUS - 0.5;
		var ringOuter = outerR + 0.5;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - cx;
				var dy = py - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist > ringOuter)
					continue;
				if (dist > innerR)
					bmp.setPixel32(px, py, BORDER);
			}
		}

		spr.dirty = true;
		return spr;
	}

	function makeGlowSprite(fill:Int):FlxSprite
	{
		var outerR = TEX_LED_RADIUS + BORDER_PX;
		var glowR = outerR * 2.8;
		var size = Std.int(glowR * 2 + 1);
		var spr = new FlxSprite();
		spr.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var bmp = spr.pixels;
		var cx = (size - 1) * 0.5;
		var cy = (size - 1) * 0.5;
		var base = fill & 0x00FFFFFF;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - cx;
				var dy = py - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist > glowR)
					continue;

				var t = 1.0 - (dist / glowR);
				var alpha = Std.int(170 * t * t);
				if (alpha > 0)
					bmp.setPixel32(px, py, (alpha << 24) | base);
			}
		}

		spr.dirty = true;
		return spr;
	}
}
