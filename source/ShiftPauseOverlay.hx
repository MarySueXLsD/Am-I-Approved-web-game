package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum ShiftPauseConfirmKind
{
	RestartShift;
	QuitJob;
}

class ShiftPauseOverlay extends FlxGroup
{
	static inline var RESTART_CONFIRM_MSG = "Are you sure you want to start the shift over?";
	static inline var QUIT_CONFIRM_MSG = "Are you sure you want to quit the job?";

	static var instance:ShiftPauseOverlay;

	var pausePopup:ShiftPausePopup;
	var confirmPopup:ShiftPauseConfirmPopup;
	var optionsPopup:MainMenuOptionsPopup;
	var onRestartShift:Void->Void;
	var onQuitJob:Void->Void;
	var fadeToBlack:(Void->Void)->Void;
	var pendingConfirm:ShiftPauseConfirmKind = RestartShift;
	var exitFade:FlxSprite;
	var exitFadeTween:FlxTween;
	var exitFadeCachedW = -1.0;
	var exitFadeCachedH = -1.0;
	var isExiting = false;

	public var isShowing(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isActive();
	}

	public static function pausesDialogue():Bool
	{
		return blocksWorldInput();
	}

	public function new(?restartShift:Void->Void, ?quitJob:Void->Void, ?fadeOut:(Void->Void)->Void)
	{
		super();
		instance = this;
		onRestartShift = restartShift;
		onQuitJob = quitJob;
		fadeToBlack = fadeOut;

		pausePopup = new ShiftPausePopup(closePauseMenu, openRestartConfirm, openOptions, openQuitConfirm);
		confirmPopup = new ShiftPauseConfirmPopup(confirmPendingAction, null);
		optionsPopup = new MainMenuOptionsPopup();

		add(pausePopup);
		add(confirmPopup);
		add(optionsPopup);

		exitFade = new FlxSprite();
		exitFade.visible = false;
		add(exitFade);

		visible = false;
	}

	public function isActive():Bool
	{
		return isExiting || isShowing || pausePopup.isActive() || confirmPopup.isActive() || optionsPopup.isActive();
	}

	public function show():Void
	{
		if (isShowing)
			return;

		isShowing = true;
		visible = true;
		confirmPopup.forceClose();
		optionsPopup.forceClose();
		pausePopup.prepare();
		optionsPopup.prepare();
		confirmPopup.prepare();
		pausePopup.show();
	}

	public function hide():Void
	{
		if (!isActive())
			return;

		resetExitFade();
		pausePopup.forceClose();
		confirmPopup.forceClose();
		optionsPopup.forceClose();
		isShowing = false;
		visible = false;
	}

	public function handleEscape():Bool
	{
		if (!isActive())
			return false;

		if (confirmPopup.isOpen())
		{
			confirmPopup.close();
			return true;
		}

		if (optionsPopup.isActive())
		{
			if (optionsPopup.isOpen() && !optionsPopup.isBusy())
				optionsPopup.close();
			return true;
		}

		if (pausePopup.isOpen())
		{
			pausePopup.close();
			return true;
		}

		return false;
	}

	public function handleClick(p:FlxPoint):Bool
	{
		if (!isActive())
			return false;

		if (confirmPopup.isActive())
		{
			confirmPopup.handleClick(p);
			return true;
		}

		if (optionsPopup.isActive())
		{
			optionsPopup.handleClick(p);
			return true;
		}

		if (pausePopup.isActive())
		{
			pausePopup.handleClick(p);
			return true;
		}

		return false;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isActive())
			return;

		var p = FlxG.mouse.getViewPosition();

		if (optionsPopup.isActive())
		{
			if (!optionsPopup.isBusy())
			{
				if (FlxG.mouse.pressed)
					optionsPopup.updateDrag(p);
				else
					optionsPopup.endDrag();
				optionsPopup.updateHover();
			}
			return;
		}

		if (confirmPopup.isOpen() && !confirmPopup.isBusy())
		{
			confirmPopup.updateHover();
			return;
		}

		if (pausePopup.isOpen() && !pausePopup.isBusy())
			pausePopup.updateHover();
	}

	function closePauseMenu():Void
	{
		isShowing = false;
		syncOverlayVisibility();
	}

	function syncOverlayVisibility():Void
	{
		if (!pausePopup.isActive() && !confirmPopup.isActive() && !optionsPopup.isActive())
			visible = false;
	}

	function openRestartConfirm():Void
	{
		openConfirm(RestartShift, RESTART_CONFIRM_MSG);
	}

	function openQuitConfirm():Void
	{
		openConfirm(QuitJob, QUIT_CONFIRM_MSG);
	}

	function openConfirm(kind:ShiftPauseConfirmKind, message:String):Void
	{
		if (confirmPopup.isActive())
			return;

		pendingConfirm = kind;
		optionsPopup.forceClose();
		confirmPopup.setMessage(message);
		confirmPopup.show();
	}

	function openOptions():Void
	{
		if (optionsPopup.isActive())
			return;

		confirmPopup.forceClose();
		optionsPopup.show();
	}

	function confirmPendingAction():Void
	{
		var pending = pendingConfirm;
		startExitFade();

		if (fadeToBlack != null)
		{
			fadeToBlack(function()
			{
				hide();
				runPendingAction(pending);
			});
			return;
		}

		hide();
		runPendingAction(pending);
	}

	function startExitFade():Void
	{
		isExiting = true;
		ensureExitFadeLayout();
		exitFade.visible = true;
		exitFade.alpha = 0;

		if (exitFadeTween != null)
			exitFadeTween.cancel();

		exitFadeTween = FlxTween.tween(exitFade, {alpha: 1}, ScreenFadeOverlay.FADE_DURATION, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				exitFadeTween = null;
			}
		});
	}

	function resetExitFade():Void
	{
		if (exitFadeTween != null)
		{
			exitFadeTween.cancel();
			exitFadeTween = null;
		}

		FlxTween.cancelTweensOf(exitFade);
		isExiting = false;
		exitFade.visible = false;
		exitFade.alpha = 0;
	}

	function ensureExitFadeLayout():Void
	{
		if (exitFadeCachedW == FlxG.width && exitFadeCachedH == FlxG.height)
			return;

		exitFadeCachedW = FlxG.width;
		exitFadeCachedH = FlxG.height;
		exitFade.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0xFF000000, true);
		exitFade.setPosition(0, 0);
		exitFade.updateHitbox();
	}

	function runPendingAction(pending:ShiftPauseConfirmKind):Void
	{
		switch (pending)
		{
			case RestartShift:
				if (onRestartShift != null)
					onRestartShift();
			case QuitJob:
				if (onQuitJob != null)
					onQuitJob();
		}
	}
}
