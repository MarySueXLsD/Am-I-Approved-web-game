package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class BeginningDayOverlay extends FlxGroup
{
	static inline var FADE_DURATION = 0.9;
	static inline var SLIDE_DURATION = 0.75;
	static inline var START_BTN_DELAY = 3.0;
	static inline var START_BTN_REVEAL_DURATION = 0.55;
	static inline var START_BTN_PULSE_DURATION = 1.1;
	static inline var TWEEN_PINGPONG = 4;
	static inline var OUTRO_FADE_IN = 0.8;
	static inline var OUTRO_TITLE_HOLD = 1.5;
	static inline var OUTRO_TITLE_FADE_OUT = 1.0;
	static inline var OUTRO_FADE_OUT = 0.9;
	static inline var OUTRO_TITLE_Y_RATIO = 0.38;
	static inline var NEWSPAPER_SCREEN_RATIO = 0.38;
	static inline var NEWSPAPER_SIZE_MULTIPLIER = 2.5;
	static inline var NEWSPAPER_MARGIN = -290.0;
	static inline var NEWSPAPER_LIFT = 520.0;
	static inline var NEWSPAPER_TILT = -10.0;
	static inline var COFFEE_SIP = "static/Audio/Ambient/sipping-coffee.wav";
	static inline var COFFEE_SIP_INTERVAL = 5.0;
	static inline var COFFEE_SIP_START_DELAY = 2.0;

	static var instance:BeginningDayOverlay;

	var blackScreen:FlxSprite;
	var tableBg:FlxSprite;
	var coffeeSmoke:CoffeeSmokeEffect;
	var glassesGlint:GlassesLensGlintEffect;
	var newspaper:FlxSprite;
	var startLabel:FlxText;
	var dayTitleLabel:FlxText;
	var activeTween:FlxTween;
	var startBtnPulseTween:FlxTween;
	var waitTimer = 0.0;
	var phase = 0;
	var newspaperTargetX = 0.0;
	var newspaperTargetY = 0.0;
	var onGameStart:Void->Void;
	var onFinished:Void->Void;
	public var onStartDayPressed:Void->Void;
	var coffeeSipTimer = 0.0;
	var coffeeSipLoopEnabled = false;
	var coffeeSipStarted = false;

	public var isShowing(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isShowing;
	}

	public function isRevealingGame():Bool
	{
		return isShowing && phase == 8;
	}

	public static function isGameRevealInProgress():Bool
	{
		return instance != null && instance.isRevealingGame();
	}

	public function new()
	{
		super();
		instance = this;

		tableBg = new FlxSprite();
		tableBg.loadGraphic("static/beginning_day_table.png");
		add(tableBg);

		coffeeSmoke = new CoffeeSmokeEffect();
		add(coffeeSmoke);

		glassesGlint = new GlassesLensGlintEffect();
		glassesGlint.visible = false;
		add(glassesGlint);

		newspaper = new FlxSprite();
		newspaper.loadGraphic("static/folded_newspaper.png");
		add(newspaper);

		blackScreen = new FlxSprite();
		add(blackScreen);

		startLabel = new FlxText(0, 0, 200, "Start the day");
		dayTitleLabel = new FlxText(0, 0, 200, "First Day");
		add(startLabel);
		add(dayTitleLabel);

		resetVisualState();
		visible = false;
	}

	public function show(?gameStart:Void->Void, ?finished:Void->Void):Void
	{
		if (isShowing)
			return;

		cancelTween();
		FlxTween.cancelTweensOf(blackScreen);
		FlxTween.cancelTweensOf(newspaper);
		onGameStart = gameStart;
		onFinished = finished;
		isShowing = true;
		visible = true;
		phase = 0;
		waitTimer = 0;
		coffeeSipTimer = 0;
		startCoffeeSipLoop();

		resetVisualState();
		layoutFullscreen();
		layoutStartButton();
		resetNewspaperStartPosition();

		tableBg.visible = true;
		tableBg.alpha = 1;
		coffeeSmoke.visible = true;
		coffeeSmoke.resetEffect();
		glassesGlint.visible = true;
		glassesGlint.resetEffect();
		newspaper.visible = false;
		startLabel.visible = false;
		dayTitleLabel.visible = false;

		bringBlackToFront();
		blackScreen.visible = true;
		blackScreen.alpha = 1;
	}

	public function hide():Void
	{
		if (!isShowing)
			return;

		cancelTween();
		cancelStartButtonPulse();
		stopCoffeeSips();
		FlxTween.cancelTweensOf(blackScreen);
		FlxTween.cancelTweensOf(tableBg);
		FlxTween.cancelTweensOf(newspaper);
		isShowing = false;
		visible = false;
		phase = 0;
		onGameStart = null;
		onFinished = null;
		onStartDayPressed = null;
		resetVisualState();
	}

	function resetVisualState():Void
	{
		blackScreen.alpha = 0;
		blackScreen.visible = false;
		tableBg.visible = true;
		tableBg.alpha = 1;
		coffeeSmoke.visible = false;
		coffeeSmoke.resetEffect();
		glassesGlint.visible = false;
		glassesGlint.resetEffect();
		newspaper.visible = false;
		newspaper.alpha = 1;
		startLabel.visible = false;
		startLabel.alpha = 1;
		startLabel.scale.set(1, 1);
		dayTitleLabel.visible = false;
		dayTitleLabel.alpha = 1;
		dayTitleLabel.scale.set(1, 1);
		FlxTween.cancelTweensOf(dayTitleLabel);
		FlxTween.cancelTweensOf(dayTitleLabel.scale);
	}

	function bringBlackToFront():Void
	{
		remove(blackScreen, false);
		add(blackScreen);
	}

	function bringTitleToFront():Void
	{
		remove(dayTitleLabel, false);
		add(dayTitleLabel);
	}

	function startIntroFade():Void
	{
		bringBlackToFront();
		blackScreen.visible = true;
		blackScreen.alpha = 1;

		activeTween = FlxTween.tween(blackScreen, {alpha: 0}, FADE_DURATION, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				onIntroFadeComplete();
			}
		});
	}

	function onIntroFadeComplete():Void
	{
		activeTween = null;
		blackScreen.alpha = 0;
		blackScreen.visible = false;
		resetNewspaperStartPosition();
		newspaper.visible = true;
		beginNewspaperSlide();
	}

	public function handleClick(p:FlxPoint):Bool
	{
		if (!isShowing || phase < 4)
			return isShowing;

		if (startLabel.visible && startLabel.alpha > 0 && startLabel.overlapsPoint(p))
		{
			beginStartDayOutro();
			return true;
		}

		return true;
	}

	function beginStartDayOutro():Void
	{
		cancelTween();
		cancelStartButtonPulse();
		stopCoffeeSipLoop();
		phase = 5;
		waitTimer = 0;

		if (onStartDayPressed != null)
			onStartDayPressed();

		startLabel.visible = false;
		dayTitleLabel.visible = false;

		layoutFullscreen();
		bringBlackToFront();
		blackScreen.visible = true;
		blackScreen.alpha = 0;

		activeTween = FlxTween.tween(blackScreen, {alpha: 1}, OUTRO_FADE_IN, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				activeTween = null;
				tableBg.visible = false;
				coffeeSmoke.visible = false;
				coffeeSmoke.resetEffect();
				glassesGlint.visible = false;
				glassesGlint.resetEffect();
				newspaper.visible = false;
				showFirstDayTitle();
			}
		});
	}

	function showFirstDayTitle():Void
	{
		phase = 6;
		waitTimer = 0;
		layoutDayTitle();
		bringTitleToFront();

		dayTitleLabel.alpha = 0;
		dayTitleLabel.scale.set(0.92, 0.92);
		dayTitleLabel.visible = true;

		FlxTween.tween(dayTitleLabel, {alpha: 1}, 0.325, {ease: FlxEase.sineOut});
		FlxTween.tween(dayTitleLabel.scale, {x: 1, y: 1}, 0.325, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				waitTimer = 0;
			}
		});
	}

	function beginFirstDayTitleFadeOut():Void
	{
		phase = 7;
		waitTimer = 0;

		activeTween = FlxTween.tween(dayTitleLabel, {alpha: 0}, OUTRO_TITLE_FADE_OUT, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				activeTween = null;
				beginRevealGame();
			}
		});
	}

	function layoutDayTitle():Void
	{
		var fontSize = Std.int(Math.max(40, FlxG.height / 9));
		var outline = Math.max(2, Std.int(fontSize / 13));

		dayTitleLabel.text = "First Day";
		dayTitleLabel.setFormat(null, fontSize, FlxColor.fromRGB(244, 228, 196), "center");
		dayTitleLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(52, 34, 22), outline);
		dayTitleLabel.fieldWidth = FlxG.width;
		dayTitleLabel.scale.set(1, 1);
		dayTitleLabel.setPosition(0, (FlxG.height - fontSize) * OUTRO_TITLE_Y_RATIO);
	}

	function beginRevealGame():Void
	{
		phase = 8;
		waitTimer = 0;
		dayTitleLabel.visible = false;

		layoutFullscreen();
		bringBlackToFront();
		blackScreen.visible = true;
		blackScreen.alpha = 1;

		var cb = onGameStart;
		onGameStart = null;
		if (cb != null)
			cb();

		activeTween = FlxTween.tween(blackScreen, {alpha: 0}, OUTRO_FADE_OUT, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				completeRevealGame();
			}
		});
	}

	function completeRevealGame():Void
	{
		if (phase != 8)
			return;

		cancelTween();
		FlxTween.cancelTweensOf(blackScreen);
		blackScreen.alpha = 0;
		blackScreen.visible = false;
		finish();
	}

	function finish():Void
	{
		var cb = onFinished;
		hide();
		if (cb != null)
			cb();
	}

	function layoutFullscreen():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;

		tableBg.setPosition(0, 0);
		tableBg.setGraphicSize(w, h);
		tableBg.updateHitbox();
		coffeeSmoke.layout(w, h);
		glassesGlint.layout(w, h);

		ensureBlackScreen(Std.int(w), Std.int(h));
	}

	function ensureBlackScreen(w:Int, h:Int):Void
	{
		if (w < 1 || h < 1)
			return;

		blackScreen.setPosition(0, 0);
		if (blackScreen.width != w || blackScreen.height != h)
			blackScreen.makeGraphic(w, h, 0xFF000000, false);
		blackScreen.updateHitbox();
	}

	function layoutNewspaperScale():Void
	{
		if (newspaper.frameWidth < 1 || newspaper.frameHeight < 1)
			return;

		var targetSize = Std.int(Math.min(FlxG.width, FlxG.height) * NEWSPAPER_SCREEN_RATIO * NEWSPAPER_SIZE_MULTIPLIER);
		var scale = targetSize / Math.max(newspaper.frameWidth, newspaper.frameHeight);
		newspaper.scale.set(scale, scale);
		newspaper.origin.set(newspaper.frameWidth * 0.5, newspaper.frameHeight * 0.5);
		newspaper.angle = NEWSPAPER_TILT;
		newspaper.updateHitbox();
	}

	function getNewspaperHalfSize():FlxPoint
	{
		var hw = newspaper.frameWidth * Math.abs(newspaper.scale.x) * 0.5;
		var hh = newspaper.frameHeight * Math.abs(newspaper.scale.y) * 0.5;
		return new FlxPoint(hw, hh);
	}

	function getNewspaperBottomLeftTarget():FlxPoint
	{
		var half = getNewspaperHalfSize();
		return new FlxPoint(NEWSPAPER_MARGIN + half.x, FlxG.height - NEWSPAPER_MARGIN - NEWSPAPER_LIFT - half.y);
	}

	function resetNewspaperStartPosition():Void
	{
		layoutNewspaperScale();

		var target = getNewspaperBottomLeftTarget();
		var half = getNewspaperHalfSize();
		newspaperTargetX = target.x;
		newspaperTargetY = target.y;

		newspaper.x = -half.x * 2 - NEWSPAPER_MARGIN;
		newspaper.y = FlxG.height + half.y + NEWSPAPER_MARGIN;
	}

	function beginNewspaperSlide():Void
	{
		phase = 2;

		var target = getNewspaperBottomLeftTarget();
		newspaperTargetX = target.x;
		newspaperTargetY = target.y;

		activeTween = FlxTween.tween(newspaper, {x: newspaperTargetX, y: newspaperTargetY}, SLIDE_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				activeTween = null;
				newspaper.setPosition(newspaperTargetX, newspaperTargetY);
				phase = 3;
				waitTimer = 0;
			}
		});
	}

	function layoutStartButton():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		var fontSize = Std.int(Math.max(44, h / 11));
		var labelW = Std.int(Math.max(380, w * 0.72));
		var labelY = Std.int(Math.max(24, h * 0.06));

		startLabel.text = "Start the day";
		startLabel.setFormat(null, fontSize, 0xFF5C4033, "center");
		startLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, Math.max(2, fontSize / 16));
		startLabel.fieldWidth = labelW;
		startLabel.setPosition((w - labelW) * 0.5, labelY);
	}

	function revealStartButton():Void
	{
		layoutStartButton();

		var targetY = startLabel.y;
		startLabel.alpha = 0;
		startLabel.scale.set(0.88, 0.88);
		startLabel.y = targetY - 14;
		startLabel.visible = true;

		FlxTween.tween(startLabel, {alpha: 1, y: targetY}, START_BTN_REVEAL_DURATION, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				beginStartButtonPulse();
			}
		});
		FlxTween.tween(startLabel.scale, {x: 1, y: 1}, START_BTN_REVEAL_DURATION, {ease: FlxEase.backOut});
	}

	function beginStartButtonPulse():Void
	{
		cancelStartButtonPulse();
		startBtnPulseTween = FlxTween.tween(startLabel.scale, {x: 1.06, y: 1.06}, START_BTN_PULSE_DURATION, {
			type: TWEEN_PINGPONG,
			ease: FlxEase.sineInOut
		});
	}

	function cancelStartButtonPulse():Void
	{
		if (startBtnPulseTween != null)
		{
			startBtnPulseTween.cancel();
			startBtnPulseTween = null;
		}
		FlxTween.cancelTweensOf(startLabel);
		FlxTween.cancelTweensOf(startLabel.scale);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isShowing)
			return;

		updateCoffeeSips(elapsed);

		if (phase == 0)
		{
			phase = 1;
			startIntroFade();
			return;
		}

		if (phase == 3)
		{
			waitTimer += elapsed;
			if (waitTimer >= START_BTN_DELAY)
			{
				phase = 4;
				revealStartButton();
			}
			return;
		}

		if (phase == 6)
		{
			waitTimer += elapsed;
			if (waitTimer >= OUTRO_TITLE_HOLD)
				beginFirstDayTitleFadeOut();
			return;
		}

		if (phase == 8)
		{
			waitTimer += elapsed;
			if (waitTimer >= OUTRO_FADE_OUT + 0.35)
				completeRevealGame();
		}
	}

	function cancelTween():Void
	{
		if (activeTween != null)
		{
			activeTween.cancel();
			activeTween = null;
		}
	}

	function updateCoffeeSips(elapsed:Float):Void
	{
		if (!coffeeSipLoopEnabled)
			return;

		coffeeSipTimer += elapsed;

		if (!coffeeSipStarted)
		{
			if (coffeeSipTimer >= COFFEE_SIP_START_DELAY)
			{
				coffeeSipStarted = true;
				coffeeSipTimer = 0;
				playCoffeeSip();
			}
			return;
		}

		if (coffeeSipTimer >= COFFEE_SIP_INTERVAL)
		{
			coffeeSipTimer -= COFFEE_SIP_INTERVAL;
			playCoffeeSip();
		}
	}

	function playCoffeeSip():Void
	{
		FlxG.sound.play(COFFEE_SIP, GameSettings.sfxVolume);
	}

	function stopCoffeeSipLoop():Void
	{
		coffeeSipLoopEnabled = false;
	}

	function stopCoffeeSips():Void
	{
		stopCoffeeSipLoop();
		coffeeSipTimer = 0;
		coffeeSipStarted = false;
	}

	function startCoffeeSipLoop():Void
	{
		coffeeSipLoopEnabled = true;
		coffeeSipStarted = false;
		coffeeSipTimer = 0;
	}

}
