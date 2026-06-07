package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;

private typedef SmokePuff = {
	var spr:FlxSprite;
	var life:Float;
	var maxLife:Float;
	var vx:Float;
	var vy:Float;
	var startY:Float;
}

class CoffeeSmokeEffect extends FlxGroup
{
	static inline var PUFF_COUNT = 26;
	static inline var PUFFS_PER_TICK = 2;
	static inline var EMIT_X_RATIO = 0.102;
	static inline var EMIT_Y_RATIO = 0.168;
	static inline var EMIT_HALF_W_RATIO = 0.095;
	static inline var EMIT_HALF_H_RATIO = 0.07;
	static inline var EMIT_Y_BIAS = -0.12;
	static inline var SPAWN_INTERVAL = 0.1;
	static inline var TOP_FADE_RATIO = 0.1;

	var puffs:Array<SmokePuff> = [];
	var emitX = 0.0;
	var emitY = 0.0;
	var emitHalfW = 0.0;
	var emitHalfH = 0.0;
	var screenH = 600.0;
	var topFadeZone = 60.0;
	var spawnAcc = 0.0;
	var nextPuff = 0;
	var puffRadius = 12.0;
	var riseSpeed = 22.0;
	var driftSpeed = 10.0;

	public function new()
	{
		super();

		for (i in 0...PUFF_COUNT)
		{
			var spr = makePuffGraphic(12);
			spr.visible = false;
			add(spr);
			puffs.push({spr: spr, life: 0, maxLife: 0, vx: 0, vy: 0, startY: 0});
		}
	}

	public function layout(screenW:Float, screenH:Float):Void
	{
		this.screenH = screenH;
		topFadeZone = screenH * TOP_FADE_RATIO;

		emitX = screenW * EMIT_X_RATIO;
		emitY = screenH * EMIT_Y_RATIO;
		emitHalfW = screenW * EMIT_HALF_W_RATIO;
		emitHalfH = screenH * EMIT_HALF_H_RATIO;

		var scale = screenH / 600.0;
		puffRadius = 10.0 + scale * 7.0;
		riseSpeed = 22.0 + scale * 14.0;
		driftSpeed = 10.0 + scale * 5.0;

		for (p in puffs)
		{
			if (p.spr.frameWidth != Std.int(puffRadius * 2 + 1))
			{
				remove(p.spr, false);
				p.spr = makePuffGraphic(Std.int(puffRadius));
				add(p.spr);
			}
			p.life = 0;
			p.spr.visible = false;
		}
	}

	public function resetEffect():Void
	{
		spawnAcc = 0;
		nextPuff = 0;
		for (p in puffs)
		{
			p.life = 0;
			p.spr.visible = false;
		}
	}

	override function update(elapsed:Float):Void
	{
		if (!visible)
			return;

		spawnAcc += elapsed;
		while (spawnAcc >= SPAWN_INTERVAL)
		{
			spawnAcc -= SPAWN_INTERVAL;
			for (i in 0...PUFFS_PER_TICK)
				spawnPuff();
		}

		for (p in puffs)
		{
			if (p.life <= 0)
				continue;

			p.life -= elapsed;
			p.spr.x += p.vx * elapsed;
			p.spr.y += p.vy * elapsed;
			p.vx += (Math.random() - 0.5) * driftSpeed * elapsed;

			var t = 1.0 - p.life / p.maxLife;
			var edgeFade = p.spr.y < topFadeZone ? p.spr.y / topFadeZone : 1.0;
			if (edgeFade < 0)
				edgeFade = 0;

			p.spr.alpha = (0.42 + (1.0 - t) * 0.06) * edgeFade;
			var s = 0.95 + t * 2.1;
			p.spr.scale.set(s, s);

			if (p.life <= 0 || p.spr.y + p.spr.height * 0.5 < 0)
				p.spr.visible = false;
		}

		super.update(elapsed);
	}

	function spawnPuff():Void
	{
		var p = puffs[nextPuff];
		nextPuff = (nextPuff + 1) % PUFF_COUNT;

		p.vx = (Math.random() - 0.5) * driftSpeed;
		p.vy = -(riseSpeed + Math.random() * riseSpeed * 0.35);

		var yOff = ((Math.random() - 0.5) + EMIT_Y_BIAS) * emitHalfH;
		var spawnY = emitY + yOff;
		p.startY = spawnY;
		p.spr.setPosition(
			emitX + (Math.random() - 0.5) * emitHalfW,
			spawnY
		);

		var travelDist = spawnY + puffRadius * 2.0;
		p.maxLife = travelDist / Math.abs(p.vy) * 1.12;
		p.life = p.maxLife;

		p.spr.alpha = 0.42 + Math.random() * 0.12;
		p.spr.scale.set(0.85, 0.85);
		p.spr.visible = true;
	}

	function makePuffGraphic(radius:Int):FlxSprite
	{
		var size = radius * 2 + 1;
		var spr = new FlxSprite();
		spr.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var bmp = spr.pixels;
		var cx = radius;
		var cy = radius;
		var outer = radius + 0.5;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - cx;
				var dy = py - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist > outer)
					continue;

				var t = 1.0 - dist / outer;
				var alpha = Std.int(255 * t * t * 0.85);
				if (alpha > 0)
					bmp.setPixel32(px, py, (alpha << 24) | 0x00E8E4DC);
			}
		}

		spr.origin.set(radius, radius);
		spr.dirty = true;
		return spr;
	}
}
