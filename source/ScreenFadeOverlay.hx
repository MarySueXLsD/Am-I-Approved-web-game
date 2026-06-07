package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class ScreenFadeOverlay extends FlxGroup
{
	public static inline var FADE_DURATION = 0.9;
	public static inline var HOLD_DURATION = 1.0;

	static var instance:ScreenFadeOverlay;

	var blackScreen:FlxSprite;
	var fadeTween:FlxTween;
	var holdTween:FlxTween;
	var cachedW = -1.0;
	var cachedH = -1.0;

	public var isBusy(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isBusy;
	}

	public function new()
	{
		super();
		instance = this;

		blackScreen = new FlxSprite();
		add(blackScreen);

		visible = false;
	}

	public function fadeToBlack(?onComplete:Void->Void):Void
	{
		cancelTweens();
		ensureLayout();
		visible = true;
		isBusy = true;
		blackScreen.visible = true;
		blackScreen.alpha = 0;

		fadeTween = FlxTween.tween(blackScreen, {alpha: 1}, FADE_DURATION, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				fadeTween = null;
				holdTween = FlxTween.num(0, 1, HOLD_DURATION, {
					onComplete: function(_)
					{
						holdTween = null;
						isBusy = false;
						if (onComplete != null)
							onComplete();
					}
				});
			}
		});
	}

	public function reset():Void
	{
		cancelTweens();
		isBusy = false;
		visible = false;
		blackScreen.visible = false;
		blackScreen.alpha = 0;
	}

	function ensureLayout():Void
	{
		if (cachedW == FlxG.width && cachedH == FlxG.height)
			return;

		cachedW = FlxG.width;
		cachedH = FlxG.height;
		blackScreen.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0xFF000000, true);
		blackScreen.setPosition(0, 0);
		blackScreen.updateHitbox();
	}

	function cancelTweens():Void
	{
		if (fadeTween != null)
		{
			fadeTween.cancel();
			fadeTween = null;
		}

		if (holdTween != null)
		{
			holdTween.cancel();
			holdTween = null;
		}

		FlxTween.cancelTweensOf(blackScreen);
	}
}
