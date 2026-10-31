package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef JuiceParticle =
{
	sprite:FlxSprite,
	vx:Float,
	vy:Float,
	spin:Float,
	life:Float,
	maxLife:Float,
	gravity:Float,
}

/**
 * Game-feel layer: stamps, particle bursts, floating text, shake and short synthesized SFX.
 * Renders on its own transparent camera above everything else so effects are never clipped by desk layers.
 */
class Juice extends FlxGroup
{
	public static inline var SFX_STAMP = "static/Audio/SFX/stamp.wav";
	public static inline var SFX_SUCCESS = "static/Audio/SFX/success.wav";
	public static inline var SFX_TICK = "static/Audio/SFX/tick.wav";
	public static inline var SFX_FANFARE = "static/Audio/SFX/fanfare.wav";
	public static inline var SFX_ERROR = "static/Audio/SFX/error.wav";
	public static inline var SFX_ALARM = "static/Audio/SFX/alarm.wav";
	public static inline var SFX_PICKUP = "static/Audio/SFX/pickup.wav";
	public static inline var SFX_DROP = "static/Audio/SFX/drop.wav";
	public static inline var SFX_BLIP = "static/Audio/SFX/blip.wav";
	public static inline var SFX_KEY = "static/Audio/SFX/key.wav";
	public static inline var SFX_COINS = "static/Audio/SFX/coins.wav";
	public static inline var SFX_WHOOSH = "static/Audio/SFX/whoosh.wav";

	public static inline var GREEN = 0xFF5FD068;
	public static inline var RED = 0xFFE24A4A;
	public static inline var GOLD = 0xFFE8C878;
	public static inline var INK_BLUE = 0xFF4A6FD0;

	static inline var SFX_SCALE = 1.6;
	static inline var MAX_PARTICLES = 160;

	static var instance:Juice;
	static var blipCooldown = 0.0;
	static var lastKeyClickTime = -1.0;

	var cam:FlxCamera;
	var particles:Array<JuiceParticle> = [];
	var pool:Array<FlxSprite> = [];

	public function new()
	{
		super();
		instance = this;

		cam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		cam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(cam, false);
		cameras = [cam];

		for (path in [SFX_STAMP, SFX_SUCCESS, SFX_TICK, SFX_ERROR, SFX_PICKUP, SFX_DROP, SFX_BLIP, SFX_KEY, SFX_COINS, SFX_WHOOSH])
			FlxG.sound.cache(path);
	}

	override public function destroy():Void
	{
		if (instance == this)
			instance = null;
		if (cam != null && FlxG.cameras.list.indexOf(cam) >= 0)
			FlxG.cameras.remove(cam, true);
		cam = null;
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (blipCooldown > 0)
			blipCooldown -= elapsed;

		var i = particles.length - 1;
		while (i >= 0)
		{
			var p = particles[i];
			p.life -= elapsed;
			if (p.life <= 0)
			{
				recycleParticle(p.sprite);
				particles.splice(i, 1);
				i--;
				continue;
			}

			p.vy += p.gravity * elapsed;
			p.vx *= Math.pow(0.4, elapsed);
			p.sprite.x += p.vx * elapsed;
			p.sprite.y += p.vy * elapsed;
			p.sprite.angle += p.spin * elapsed;
			var t = p.life / p.maxLife;
			p.sprite.alpha = t < 0.35 ? t / 0.35 : 1;
			// Flat confetti "flutters" by squashing on one axis.
			p.sprite.scale.x = Math.abs(Math.cos(p.life * 9 + p.spin * 0.01));
			i--;
		}
	}

	// ---------------------------------------------------------------- audio

	public static function sfx(path:String, ?volume:Float = 1.0, ?pitchJitter:Float = 0.0):Void
	{
		var snd = FlxG.sound.play(path, Math.min(1, GameSettings.sfxVolume * SFX_SCALE * volume));
		if (snd != null && pitchJitter > 0)
			snd.pitch = 1 + FlxG.random.float(-pitchJitter, pitchJitter);
	}

	/** Rate-limited typewriter blip so long text doesn't machine-gun the speaker. */
	public static function blip():Void
	{
		if (blipCooldown > 0)
			return;
		blipCooldown = 0.055;
		sfx(SFX_BLIP, 0.35, 0.12);
	}

	/** Terminal key clack — several panels may see the same key event, so dedupe within a frame or two. */
	public static function keyClick():Void
	{
		var now = haxe.Timer.stamp();
		if (now - lastKeyClickTime < 0.03)
			return;
		lastKeyClickTime = now;
		sfx(SFX_KEY, 0.6, 0.2);
	}

	// ---------------------------------------------------------------- camera

	public static function shake(?intensity:Float = 0.006, ?duration:Float = 0.18):Void
	{
		FlxG.camera.shake(intensity, duration);
	}

	public static function flash(color:FlxColor, ?duration:Float = 0.25, ?alpha:Float = 0.35):Void
	{
		if (instance == null)
			return;
		var c = FlxColor.fromRGB(color.red, color.green, color.blue, Std.int(255 * alpha));
		instance.cam.flash(c, duration, null, true);
	}

	// ---------------------------------------------------------------- effects

	/** Big rubber stamp that slams onto the screen, shakes the desk and fades away. */
	public static function stamp(text:String, color:FlxColor, ?cx:Float = -1, ?cy:Float = -1, ?sub:String = null):Void
	{
		if (instance == null)
			return;

		if (cx < 0)
			cx = FlxG.width * 0.5;
		if (cy < 0)
			cy = FlxG.height * 0.42;

		var size = 54;
		var label = new FlxText(0, 0, 0, text, size);
		label.setFormat(null, size, color, "center");
		label.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(20, 12, 8), 3);
		label.updateHitbox();

		var padX = 26;
		var padY = 12;
		var boxW = Std.int(label.width + padX * 2);
		var boxH = Std.int(label.height + padY * 2 + (sub != null ? 26 : 0));
		var box = new FlxSprite();
		box.makeGraphic(boxW, boxH, FlxColor.TRANSPARENT, true);
		var t = 5;
		var fill = FlxColor.fromRGB(color.red, color.green, color.blue, 40);
		box.pixels.fillRect(new openfl.geom.Rectangle(0, 0, boxW, boxH), fill);
		for (r in [
			new openfl.geom.Rectangle(0, 0, boxW, t),
			new openfl.geom.Rectangle(0, boxH - t, boxW, t),
			new openfl.geom.Rectangle(0, 0, t, boxH),
			new openfl.geom.Rectangle(boxW - t, 0, t, boxH)
		])
			box.pixels.fillRect(r, color);
		box.dirty = true;

		var subText:FlxText = null;
		if (sub != null)
		{
			subText = new FlxText(0, 0, boxW, sub, 16);
			subText.setFormat(null, 16, color, "center");
			subText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(20, 12, 8), 2);
		}

		var angle = FlxG.random.float(-14, -6);
		var parts:Array<FlxSprite> = [box, label];
		if (subText != null)
			parts.push(subText);

		for (part in parts)
		{
			part.cameras = instance.cameras;
			part.angle = angle;
			instance.add(part);
		}

		box.setPosition(cx - boxW * 0.5, cy - boxH * 0.5);
		label.setPosition(cx - label.width * 0.5, box.y + padY);
		if (subText != null)
			subText.setPosition(cx - boxW * 0.5, label.y + label.height - 2);

		for (part in parts)
		{
			part.scale.set(3.2, 3.2);
			part.alpha = 0;
			FlxTween.tween(part.scale, {x: 1, y: 1}, 0.16, {ease: FlxEase.quadIn});
			FlxTween.tween(part, {alpha: 1}, 0.12);
		}

		new flixel.util.FlxTimer().start(0.16, function(_)
		{
			sfx(SFX_STAMP, 1.0, 0.05);
			shake(0.012, 0.22);
			burst(cx, cy, [color, FlxColor.WHITE, GOLD], 26, 260, 0.9);
			for (part in parts)
			{
				part.scale.set(1.1, 0.9);
				FlxTween.tween(part.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.elasticOut});
				FlxTween.tween(part, {alpha: 0}, 0.4, {
					startDelay: 1.15,
					onComplete: function(_)
					{
						instance.remove(part, true);
						part.destroy();
					}
				});
			}
		});
	}

	/** Confetti / sparks exploding from a point. */
	public static function burst(x:Float, y:Float, colors:Array<Int>, ?count:Int = 20, ?speed:Float = 220,
			?life:Float = 0.8, ?size:Int = 5, ?gravity:Float = 520):Void
	{
		if (instance == null)
			return;

		for (_ in 0...count)
		{
			if (instance.particles.length >= MAX_PARTICLES)
				return;

			var s = instance.takeParticle(size, colors[FlxG.random.int(0, colors.length - 1)]);
			s.setPosition(x - size * 0.5, y - size * 0.5);
			var dir = FlxG.random.float(0, Math.PI * 2);
			var v = FlxG.random.float(speed * 0.35, speed);
			var l = FlxG.random.float(life * 0.6, life);
			instance.particles.push({
				sprite: s,
				vx: Math.cos(dir) * v,
				vy: Math.sin(dir) * v - speed * 0.45,
				spin: FlxG.random.float(-540, 540),
				life: l,
				maxLife: l,
				gravity: gravity
			});
		}
	}

	/** Coins that pop up and rain down — used for granted loans. */
	public static function coinShower(x:Float, y:Float, ?count:Int = 18):Void
	{
		sfx(SFX_COINS, 0.9);
		burst(x, y, [0xFFF2C94C, 0xFFE0A82E, 0xFFFFE89A], count, 300, 1.2, 7, 700);
	}

	/** Floating text that drifts upward and fades. */
	public static function popText(x:Float, y:Float, text:String, color:FlxColor, ?size:Int = 18, ?rise:Float = 46):Void
	{
		if (instance == null)
			return;

		var t = new FlxText(0, 0, 0, text, size);
		t.setFormat(null, size, color, "center");
		t.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(16, 10, 6), 2);
		t.cameras = instance.cameras;
		t.updateHitbox();
		t.setPosition(x - t.width * 0.5, y - t.height * 0.5);
		t.scale.set(0.4, 0.4);
		instance.add(t);

		FlxTween.tween(t.scale, {x: 1, y: 1}, 0.22, {ease: FlxEase.backOut});
		FlxTween.tween(t, {y: t.y - rise}, 1.1, {ease: FlxEase.quadOut});
		FlxTween.tween(t, {alpha: 0}, 0.35, {
			startDelay: 0.85,
			onComplete: function(_)
			{
				instance.remove(t, true);
				t.destroy();
			}
		});
	}

	/** Quick squash-and-stretch on any sprite, restoring its original scale. */
	public static function punch(sprite:FlxSprite, ?amount:Float = 0.12, ?duration:Float = 0.22):Void
	{
		if (sprite == null)
			return;

		var bx = sprite.scale.x;
		var by = sprite.scale.y;
		FlxTween.cancelTweensOf(sprite.scale);
		sprite.scale.set(bx * (1 + amount), by * (1 - amount));
		FlxTween.tween(sprite.scale, {x: bx, y: by}, duration, {ease: FlxEase.elasticOut});
	}

	// ---------------------------------------------------------------- particle pool

	function takeParticle(size:Int, color:Int):FlxSprite
	{
		var s = pool.length > 0 ? pool.pop() : null;
		if (s == null)
		{
			s = new FlxSprite();
			s.cameras = cameras;
		}
		s.makeGraphic(size, Std.int(Math.max(2, size * 0.6)), color, false, 'juice_p_${size}_$color');
		s.alpha = 1;
		s.angle = 0;
		s.scale.set(1, 1);
		s.visible = true;
		s.active = true;
		add(s);
		return s;
	}

	function recycleParticle(s:FlxSprite):Void
	{
		remove(s, true);
		pool.push(s);
	}
}
