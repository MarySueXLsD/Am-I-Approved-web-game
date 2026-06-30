package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class StudioLogoSplash extends FlxGroup
{
	static inline var LOGO_PATH = "static/Main_Menu/logo.png";
	static inline var FADE_IN = 1.5;
	static inline var HOLD = 3.0;
	static inline var FADE_OUT = 1.5;

	static var instance:StudioLogoSplash;

	var bg:FlxSprite;
	var logo:FlxSprite;
	var activeTween:FlxTween;
	var onFinished:Void->Void;
	var activeTimer = 0.0;

	static inline var MAX_SPLASH_SECONDS = 12.0;

	public var isActive(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isActive;
	}

	public function new()
	{
		super();
		instance = this;

		bg = new FlxSprite();
		add(bg);

		logo = new FlxSprite();
		logo.loadGraphic(LOGO_PATH);
		add(logo);

		visible = false;
	}

	public function show(?finished:Void->Void):Void
	{
		if (isActive)
			return;

		cancelTween();
		onFinished = finished;
		activeTimer = 0.0;
		isActive = true;
		visible = true;

		layout();
		logo.alpha = 0;
		logo.visible = true;
		bg.visible = true;

		MainMenuOverlay.preloadAudio();

		activeTween = FlxTween.tween(logo, {alpha: 1}, FADE_IN, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				activeTween = null;
				beginHold();
			}
		});
	}

	public function hide():Void
	{
		cancelTween();
		isActive = false;
		visible = false;
		onFinished = null;
		logo.alpha = 0;
	}

	function beginHold():Void
	{
		activeTween = FlxTween.num(0, 1, HOLD, {
			onComplete: function(_)
			{
				activeTween = null;
				beginFadeOut();
			}
		});
	}

	function beginFadeOut():Void
	{
		activeTween = FlxTween.tween(logo, {alpha: 0}, FADE_OUT, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				activeTween = null;
				finish();
			}
		});
	}

	function finish():Void
	{
		var cb = onFinished;
		hide();
		if (cb != null)
			cb();
	}

	function layout():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;

		bg.setPosition(0, 0);
		bg.makeGraphic(Std.int(w), Std.int(h), 0xFF000000, false);
		bg.updateHitbox();

		if (logo.frameWidth < 1 || logo.frameHeight < 1)
			return;

		var maxW = w * 0.88;
		var maxH = h * 0.64;
		var scale = Math.min(maxW / logo.frameWidth, maxH / logo.frameHeight);
		logo.scale.set(scale, scale);
		logo.updateHitbox();
		logo.setPosition((w - logo.width) * 0.5, (h - logo.height) * 0.5);
	}

	function cancelTween():Void
	{
		if (activeTween != null)
		{
			activeTween.cancel();
			activeTween = null;
		}

		FlxTween.cancelTweensOf(logo);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isActive)
			return;

		activeTimer += elapsed;
		if (activeTimer >= MAX_SPLASH_SECONDS)
			finish();
	}

	public function skip():Void
	{
		if (!isActive)
			return;
		finish();
	}

}
