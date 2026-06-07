package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class MainMenuTrafficCloud extends FlxSpriteGroup
{
	static inline var BOB_SPEED = 1.8;
	static inline var BOB_AMPLITUDE_RATIO = 0.0035;

	public var vx(default, null):Float;
	public var lane(default, null):Int;
	public var depth(default, null):CloudDepth;

	var body:FlxSprite;
	var cloudHeight:Float;
	var baseY:Float = 0;
	var bobPhase:Float;
	var bobAmplitude:Float = 2.0;

	public function new(path:String, dir:Int, lane:Int, depth:CloudDepth, speed:Float, height:Float, alpha:Float, ?bobSeed:Float)
	{
		super();

		this.lane = lane;
		this.depth = depth;
		this.cloudHeight = height;
		vx = dir * speed;
		bobPhase = bobSeed != null ? bobSeed : Math.random() * Math.PI * 2;
		bobAmplitude = Math.max(0.8, height * BOB_AMPLITUDE_RATIO);

		body = new FlxSprite();
		body.loadGraphic(path);
		body.antialiasing = false;
		body.alpha = alpha;
		scaleBody();

		add(body);
	}

	public function getTravelWidth():Float
	{
		return body.width;
	}

	public function setLaneY(laneY:Float):Void
	{
		baseY = laneY - cloudHeight * 0.5;
		y = baseY;
	}

	public function resize(height:Float):Void
	{
		cloudHeight = height;
		bobAmplitude = Math.max(0.8, height * BOB_AMPLITUDE_RATIO);
		scaleBody();
		setLaneY(baseY + height * 0.5);
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
		var scale = cloudHeight / body.frameHeight;
		body.setGraphicSize(Std.int(body.frameWidth * scale), Std.int(cloudHeight));
		body.updateHitbox();
	}
}
