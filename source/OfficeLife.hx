package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

typedef SteamPuff =
{
	sprite:FlxSprite,
	life:Float,
	maxLife:Float,
}

/**
 * Keeps the office feeling inhabited between clients: sunlight through the blinds, a steaming mug and
 * other desk clutter, a wall clock that follows the shift, and coworkers' shadows crossing the wall.
 * This group is the desk layer; `wallLayer` is added separately so it draws behind the client.
 */
class OfficeLife extends FlxGroup
{
	static inline var SIP_SOUND = "static/Audio/Ambient/sipping-coffee.wav";
	static inline var SHADOW_COUNT = 9;
	static inline var SHADOW_MIN_GAP = 4.0;
	static inline var SHADOW_MAX_GAP = 11.0;
	static inline var SHADOW_MIN_SPEED = 210.0;
	static inline var SHADOW_MAX_SPEED = 320.0;
	static inline var STEAM_INTERVAL = 0.45;
	static inline var CLOCK_SIZE = 64;

	public var wallLayer(default, null):FlxGroup;
	/** Added by PlayState above the documents: nothing on the desk ever lands on top of the plant. */
	public var plant(default, null):FlxSprite;

	var zones:LayoutZones;
	var sunlight:FlxSprite;
	var mug:FlxSprite;
	var pen:FlxSprite;
	var steam:Array<SteamPuff> = [];
	var steamTimer = 0.0;
	var sunlightBaseX = 0.0;
	var time = 0.0;

	var clockHour:FlxSprite;
	var clockMinute:FlxSprite;
	var clockSecond:FlxSprite;
	var clockCenterX = 0.0;
	var clockCenterY = 0.0;

	var wallShadow:FlxSprite;
	var shadowSources:Array<BitmapData> = [];
	var shadowSource:BitmapData;
	var lastShadow = -1;
	var shadowWalking = false;
	var shadowX = 0.0;
	var shadowSpeed = 0.0;
	var shadowBob = 0.0;
	var shadowCooldown = 4.0;

	public function new(zones:LayoutZones)
	{
		super();
		this.zones = zones;
		wallLayer = new FlxGroup();
		buildDesk();
		buildWall();
	}

	function buildDesk():Void
	{
		// A worn blotter marks out the working area; everything else is clutter around it.
		var blotter = new FlxSprite(zones.employerX + 60, 86);
		UiSkin.panel(blotter, 420, 258, 0xFF5A6048, 0xFF3A3E2C, 5, 2, 0);
		blotter.pixels.fillRect(new Rectangle(8, 8, 404, 1), 0xFF7C8264);
		blotter.pixels.fillRect(new Rectangle(8, 249, 404, 1), 0xFF7C8264);
		blotter.pixels.fillRect(new Rectangle(8, 8, 1, 242), 0xFF7C8264);
		blotter.pixels.fillRect(new Rectangle(411, 8, 1, 242), 0xFF7C8264);
		blotter.dirty = true;
		blotter.alpha = 0.6;
		add(blotter);

		// Tucked into the corner, partly off the desk, so it never hides the open Guide Book's text.
		plant = new FlxSprite(zones.employerX + zones.employerW - 96, -8);
		plant.loadGraphic("static/Desk/plant.png");
		mug = addProp("static/Desk/mug.png", zones.employerX + 22, 386);
		pen = addProp("static/Desk/pen.png", zones.employerX + 262, 388);

		var plate = new FlxSprite(zones.employerX + 122, 436);
		UiSkin.panel(plate, 124, 26, UiSkin.PANEL, UiSkin.PANEL_DEEP, 3, 2, 2);
		add(plate);
		var plateLabel = new FlxText(plate.x, plate.y + 6, 124, "CLERK #447-B");
		plateLabel.setFormat(null, 10, UiSkin.TRIM, "center");
		add(plateLabel);

		for (_ in 0...6)
		{
			var puff = new FlxSprite();
			puff.makeGraphic(4, 4, 0xFFFFFFFF);
			puff.visible = false;
			add(puff);
			steam.push({sprite: puff, life: 0, maxLife: 1});
		}

		sunlight = new FlxSprite(zones.employerX - 40, 0);
		sunlight.loadGraphic(makeBlindsLight(zones.employerW + 80, FlxG.height));
		sunlight.alpha = 0.55;
		sunlightBaseX = sunlight.x;
		add(sunlight);
	}

	/** Soft diagonal bars of window light falling across the desk. */
	function makeBlindsLight(w:Int, h:Int):BitmapData
	{
		var bmd = new BitmapData(w, h, true, 0x00000000);
		var bars = [{x: -40, w: 70}, {x: 60, w: 34}, {x: 130, w: 90}, {x: 260, w: 30}, {x: 330, w: 70}];
		for (row in 0...h)
		{
			// Stepped every 2 rows so the edge keeps the chunky pixel look.
			var shift = Std.int(row / 2) * 1;
			for (bar in bars)
				bmd.fillRect(new Rectangle(bar.x + shift, row, bar.w, 1), 0x16FFF2D0);
		}
		return bmd;
	}

	function addProp(path:String, x:Float, y:Float):FlxSprite
	{
		var prop = new FlxSprite(x, y);
		prop.loadGraphic(path);
		add(prop);
		return prop;
	}

	function buildWall():Void
	{
		// The shadow draws first so the clock and the framed emblem stay in front of it.
		for (i in 0...SHADOW_COUNT)
			shadowSources.push(FlxG.bitmap.add('static/Desk/shadows/s$i.png').bitmap);
		shadowSource = shadowSources[0];
		wallShadow = new FlxSprite(0, 0);
		wallShadow.makeGraphic(zones.leftW, zones.clientH, FlxColor.TRANSPARENT, true);
		wallShadow.visible = false;
		wallLayer.add(wallShadow);

		var frame = new FlxSprite(144, 14);
		UiSkin.panel(frame, 90, 64, UiSkin.PAPER, UiSkin.PANEL, 2, 4, 2);
		wallLayer.add(frame);
		var emblem = new FlxSprite();
		emblem.loadGraphic("static/lorian_emblem.png");
		emblem.setGraphicSize(74, 46);
		emblem.updateHitbox();
		emblem.setPosition(frame.x + 8, frame.y + 9);
		wallLayer.add(emblem);

		var clockFace = new FlxSprite(8, 8);
		clockFace.makeGraphic(CLOCK_SIZE, CLOCK_SIZE, FlxColor.TRANSPARENT, true);
		var r = Std.int(CLOCK_SIZE * 0.5);
		UiSkin.roundRect(clockFace.pixels, 0, 0, CLOCK_SIZE, CLOCK_SIZE, r, UiSkin.PANEL);
		UiSkin.roundRect(clockFace.pixels, 4, 4, CLOCK_SIZE - 8, CLOCK_SIZE - 8, r - 4, UiSkin.CREAM);
		for (i in 0...12)
		{
			var a = i * Math.PI / 6;
			var tx = Std.int(r + Math.sin(a) * (r - 9));
			var ty = Std.int(r - Math.cos(a) * (r - 9));
			var dot = i % 3 == 0 ? 3 : 2;
			clockFace.pixels.fillRect(new Rectangle(tx - 1, ty - 1, dot, dot), UiSkin.INK);
		}
		clockFace.dirty = true;
		wallLayer.add(clockFace);
		clockCenterX = clockFace.x + r;
		clockCenterY = clockFace.y + r;

		clockHour = addClockHand(3, 15, UiSkin.INK);
		clockMinute = addClockHand(2, 22, UiSkin.INK);
		clockSecond = addClockHand(1, 24, UiSkin.STAMP_RED);
	}

	function addClockHand(w:Int, h:Int, color:Int):FlxSprite
	{
		var hand = new FlxSprite();
		hand.makeGraphic(w, h, color);
		hand.origin.set(w * 0.5, h);
		hand.setPosition(clockCenterX - w * 0.5, clockCenterY - h);
		wallLayer.add(hand);
		return hand;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		time += elapsed;

		// Clouds drifting past the sun: the bars breathe and wander very slowly.
		sunlight.x = sunlightBaseX + Math.sin(time * 0.11) * 14;
		sunlight.alpha = 0.5 + Math.sin(time * 0.23) * 0.18;

		updateSteam(elapsed);
		updateClock();
		updatePasserby(elapsed);
	}

	function updateSteam(elapsed:Float):Void
	{
		steamTimer -= elapsed;
		for (puff in steam)
		{
			if (!puff.sprite.visible)
			{
				if (steamTimer <= 0)
				{
					steamTimer = STEAM_INTERVAL;
					emitPuff(puff);
				}
				continue;
			}

			puff.life -= elapsed;
			if (puff.life <= 0)
			{
				puff.sprite.visible = false;
				continue;
			}
			puff.sprite.y -= 16 * elapsed;
			puff.sprite.x += Math.sin(puff.life * 5) * 7 * elapsed;
			puff.sprite.alpha = 0.3 * (puff.life / puff.maxLife);
		}
	}

	function emitPuff(puff:SteamPuff, ?spread:Float = 10):Void
	{
		puff.maxLife = FlxG.random.float(1.1, 1.8);
		puff.life = puff.maxLife;
		puff.sprite.visible = true;
		puff.sprite.setPosition(mug.x + 36 + FlxG.random.float(-spread, spread), mug.y + 28 + FlxG.random.float(-6, 6));
	}

	function updateClock():Void
	{
		// Same time as the status bar, and the second hand stops whenever the shift clock does.
		var minutes = GameClock.displayedMinutes();
		clockMinute.angle = (minutes % 60) * 6;
		clockHour.angle = ((minutes % 720) / 60) * 30;
		clockSecond.angle = Math.floor(GameClock.elapsedSeconds) * 6;
	}

	function updatePasserby(elapsed:Float):Void
	{
		if (!shadowWalking)
		{
			shadowCooldown -= elapsed;
			if (shadowCooldown > 0)
				return;

			lastShadow = FlxG.random.int(0, SHADOW_COUNT - 1, [lastShadow]);
			shadowSource = shadowSources[lastShadow];
			var leftToRight = FlxG.random.bool();
			shadowWalking = true;
			wallShadow.visible = true;
			shadowX = leftToRight ? -shadowSource.width : zones.leftW;
			shadowSpeed = FlxG.random.float(SHADOW_MIN_SPEED, SHADOW_MAX_SPEED) * (leftToRight ? 1 : -1);
			shadowBob = 0;
		}

		shadowX += shadowSpeed * elapsed;
		shadowBob += elapsed * 15;

		// Drawn into a canvas the size of the wall, so the shadow can never land on anything else.
		var canvas = wallShadow.pixels;
		canvas.fillRect(canvas.rect, 0x00000000);
		var y = zones.clientH - shadowSource.height + 40 + Math.abs(Math.sin(shadowBob)) * 5;
		canvas.copyPixels(shadowSource, shadowSource.rect, new Point(Math.round(shadowX), Math.round(y)));
		wallShadow.dirty = true;

		if (shadowX > zones.leftW || shadowX < -shadowSource.width)
		{
			shadowWalking = false;
			wallShadow.visible = false;
			shadowCooldown = FlxG.random.float(SHADOW_MIN_GAP, SHADOW_MAX_GAP);
		}
	}

	public function plantHitsPoint(p:FlxPoint):Bool
	{
		return plant.pixelsOverlapPoint(p, 0x20);
	}

	public function pokePlant():Void
	{
		Juice.sfx(Juice.SFX_PICKUP, 0.7, 0.15);
		wiggle(plant, 7);
	}

	/** Desk toys: the mug and pen react when the player fiddles with them. */
	public function handleClick(p:FlxPoint):Bool
	{
		if (hits(mug, p))
		{
			FlxG.sound.play(SIP_SOUND, GameSettings.sfxVolume);
			Juice.punch(mug, 0.1, 0.35);
			for (puff in steam)
				if (!puff.sprite.visible)
					emitPuff(puff, 18);
			return true;
		}
		if (hits(pen, p))
		{
			Juice.sfx(Juice.SFX_KEY, 0.8, 0.1);
			wiggle(pen, 14);
			return true;
		}
		return false;
	}

	function hits(prop:FlxSprite, p:FlxPoint):Bool
	{
		return p.x >= prop.x && p.x < prop.x + prop.width && p.y >= prop.y && p.y < prop.y + prop.height;
	}

	function wiggle(prop:FlxSprite, degrees:Float):Void
	{
		FlxTween.cancelTweensOf(prop, ["angle"]);
		prop.angle = degrees;
		FlxTween.tween(prop, {angle: 0}, 0.6, {ease: FlxEase.elasticOut});
	}
}
