package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class MainMenuTrafficCar extends FlxSpriteGroup
{
	static inline var BOB_SPEED = 7.5;
	static inline var BOB_AMPLITUDE_RATIO = 0.0045;

	public var vx(default, null):Float;
	public var lane(default, null):Int;

	var body:FlxSprite;
	var carHeight:Float;
	var baseY:Float = 0;
	var bobPhase:Float;
	var bobAmplitude:Float = 2.0;

	public function new(path:String, dir:Int, lane:Int, speed:Float, height:Float, ?bobSeed:Float)
	{
		super();

		this.lane = lane;
		this.carHeight = height;
		vx = dir * speed;
		bobPhase = bobSeed != null ? bobSeed : Math.random() * Math.PI * 2;
		bobAmplitude = Math.max(1.0, height * BOB_AMPLITUDE_RATIO);

		body = new FlxSprite();
		body.loadGraphic(path);
		body.antialiasing = false;
		body.flipX = dir > 0;
		scaleBody();

		add(body);
	}

	public function getTravelWidth():Float
	{
		return body.width;
	}

	public function setLaneY(laneY:Float):Void
	{
		baseY = laneY - carHeight * 0.58;
		y = baseY;
	}

	public function resize(height:Float):Void
	{
		carHeight = height;
		bobAmplitude = Math.max(1.0, height * BOB_AMPLITUDE_RATIO);
		scaleBody();
		setLaneY(baseY + height * 0.58);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		x += vx * elapsed;
		bobPhase += elapsed * BOB_SPEED;
		y = baseY + Math.sin(bobPhase) * bobAmplitude;
	}

	function scaleBody():Void
	{
		var scale = carHeight / body.frameHeight;
		body.setGraphicSize(Std.int(body.frameWidth * scale), Std.int(carHeight));
		body.updateHitbox();
	}
}
