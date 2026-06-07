package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;

class ShredderStation extends FlxGroup
{
	static inline var PAPER_LEFT_X = 161.0;
	static inline var PAPER_RIGHT_X = 709.0;
	static inline var SHRED_LINE_Y = 189.0;
	static inline var PAPER_FEED_DURATION = 3.0;

	static inline var TEX_RED_X = 759.0;
	static inline var TEX_RED_Y = 266.0;
	static inline var TEX_LED_RADIUS = 18.0;
	static inline var BORDER_PX = 5.0;
	static inline var RED_ON = 0xFFE83A2A;
	static inline var BORDER = 0xFF000000;
	static inline var BLINK_PERIOD_IDLE = 0.9;
	static inline var BLINK_PERIOD_SHRED = 0.35;

	public var body:FlxSprite;

	var redGlow:FlxSprite;
	var redBorder:FlxSprite;
	var redLed:FlxSprite;
	var shreddingDoc:DeskDocument;
	var shredTween:FlxTween;
	var isShredding = false;
	var blinkTimer = 0.0;

	public function new(bodySprite:FlxSprite)
	{
		super();
		body = bodySprite;

		redGlow = makeGlowSprite(RED_ON);
		redGlow.blend = BlendMode.ADD;
		redBorder = makeLedBorderSprite();
		redLed = makeLedFillSprite(RED_ON);

		add(body);
		add(redGlow);
		add(redBorder);
		add(redLed);
		syncLedPositions();
	}

	public function setStationCameras(cams:Array<FlxCamera>):Void
	{
		body.cameras = cams;
		redGlow.cameras = cams;
		redBorder.cameras = cams;
		redLed.cameras = cams;
		if (shreddingDoc != null)
			shreddingDoc.cameras = cams;
	}

	public function canAcceptDocument():Bool
	{
		return !isShredding;
	}

	public function cancelActiveShred():DeskDocument
	{
		if (shredTween != null)
		{
			shredTween.cancel();
			shredTween = null;
		}

		var doc = shreddingDoc;
		shreddingDoc = null;
		isShredding = false;
		return doc;
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

	public function startShred(doc:DeskDocument, onComplete:Void->Void):Bool
	{
		if (!canAcceptDocument())
			return false;

		isShredding = true;
		shreddingDoc = doc;
		doc.lockForShredder();

		var s = body.scale.x;
		var slotW = (PAPER_RIGHT_X - PAPER_LEFT_X) * s;
		doc.setGraphicSize(Std.int(Math.max(1, slotW)), 0);
		doc.updateHitbox();
		doc.angle = 0;
		doc.x = body.x + PAPER_LEFT_X * s;

		var shredLineY = body.y + SHRED_LINE_Y * s;
		// Half the sheet above the line of no return; the rest feeds in invisibly below y=189.
		var startY = shredLineY - doc.height * 0.5;
		var endY = shredLineY + doc.height * 0.5;
		doc.y = startY;
		applyShredClip(doc);

		if (shredTween != null)
		{
			shredTween.cancel();
			shredTween = null;
		}

		shredTween = FlxTween.tween(doc, {y: endY}, PAPER_FEED_DURATION, {
			ease: FlxEase.linear,
			onUpdate: function(_)
			{
				applyShredClip(doc);
			},
			onComplete: function(_)
			{
				shredTween = null;
				isShredding = false;
				shreddingDoc = null;
				doc.finishShredder();
				if (onComplete != null)
					onComplete();
			}
		});
		return true;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		blinkTimer += elapsed;
		var period = isShredding ? BLINK_PERIOD_SHRED : BLINK_PERIOD_IDLE;
		var phase = blinkTimer / period * Math.PI * 2.0;
		var pulse = 0.5 + 0.5 * Math.sin(phase);

		if (isShredding)
		{
			redLed.alpha = 0.45 + 0.55 * pulse;
			redGlow.alpha = 0.5 + 0.5 * pulse;
			if (shreddingDoc != null)
				applyShredClip(shreddingDoc);
		}
		else
		{
			redLed.alpha = 0.65 + 0.35 * pulse;
			redGlow.alpha = 0.38 + 0.52 * pulse;
		}
	}

	function applyShredClip(doc:FlxSprite):Void
	{
		var shredLine = body.y + SHRED_LINE_Y * body.scale.x;

		if (doc.y >= shredLine)
		{
			doc.visible = false;
			return;
		}

		var visTop = doc.y;
		var visBottom = Math.min(doc.y + doc.height, shredLine);
		if (visBottom <= visTop)
		{
			doc.visible = false;
			return;
		}

		var sy = Math.abs(doc.scale.y);
		if (doc.clipRect == null)
			doc.clipRect = FlxRect.get();
		doc.clipRect.set(0, (visTop - doc.y) / sy, doc.frameWidth, (visBottom - visTop) / sy);
		doc.visible = true;
	}

	function syncLedPositions():Void
	{
		var s = body.scale.x;
		var ledD = (TEX_LED_RADIUS * 2 + BORDER_PX * 2) * s;
		var glowD = ledD * 2.6;

		placeLed(redGlow, TEX_RED_X, TEX_RED_Y, glowD);
		placeLed(redBorder, TEX_RED_X, TEX_RED_Y, ledD);
		placeLed(redLed, TEX_RED_X, TEX_RED_Y, ledD);
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
