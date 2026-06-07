package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.geom.Rectangle;

class MainMenuSlidePopup extends FlxGroup
{
	public static inline var SLIDE_DURATION = 0.28;

	var overlay:FlxSprite;
	var slideRoot:FlxGroup;
	var slideTween:FlxTween;
	var overlayTween:FlxTween;
	var isAnimating = false;
	var panelW = 0.0;
	var panelH = 0.0;
	var restX = 0.0;
	var restY = 0.0;
	var slideDeltaX = 0.0;
	var cachedLayoutW = -1.0;
	var cachedLayoutH = -1.0;
	var cachedOverlayW = -1.0;
	var cachedOverlayH = -1.0;

	public function new()
	{
		super();
		overlay = new FlxSprite();
		slideRoot = new FlxGroup();
		add(overlay);
		add(slideRoot);
		visible = false;
	}

	public function isOpen():Bool
	{
		return visible;
	}

	public function isBusy():Bool
	{
		return isAnimating;
	}

	public function isActive():Bool
	{
		return visible || isAnimating;
	}

	public function prepare():Void
	{
		ensureLayout();
		ensureOverlay();
	}

	public function show():Void
	{
		if (isActive())
			return;

		onBeforeShow();
		ensureLayout();
		slideDeltaX = -panelW;
		syncPopupLayout();
		visible = true;
		isAnimating = true;
		cancelTweens();

		ensureOverlay();
		overlay.alpha = 0;

		overlayTween = FlxTween.tween(overlay, {alpha: 1}, SLIDE_DURATION * 0.75, {ease: FlxEase.quadOut});
		slideTween = FlxTween.tween(this, {slideDeltaX: 0}, SLIDE_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				syncPopupLayout();
			},
			onComplete: function(_)
			{
				finishOpen();
			}
		});
	}

	public function close():Void
	{
		if (!visible || isAnimating)
			return;

		isAnimating = true;
		cancelTweens();
		overlayTween = FlxTween.tween(overlay, {alpha: 0}, SLIDE_DURATION * 0.75, {ease: FlxEase.quadIn});
		slideTween = FlxTween.tween(this, {slideDeltaX: -panelW}, SLIDE_DURATION, {
			ease: FlxEase.quadIn,
			onUpdate: function(_)
			{
				syncPopupLayout();
			},
			onComplete: function(_)
			{
				finishClose();
			}
		});
	}

	public function forceClose():Void
	{
		cancelTweens();
		isAnimating = false;
		slideDeltaX = 0;
		visible = false;
		onClosed();
	}

	public function handleBackdropClick(p:FlxPoint):Bool
	{
		if (!visible || isAnimating)
			return false;

		if (!containsPanelPoint(p))
		{
			close();
			return true;
		}

		return false;
	}

	public function handleClick(p:FlxPoint):Bool
	{
		if (!isActive())
			return false;

		if (handleBackdropClick(p))
			return true;

		if (isAnimating)
			return true;

		return handlePanelClick(p);
	}

	function containsPanelPoint(p:FlxPoint):Bool
	{
		var panelX = restX + slideDeltaX;
		return p.x >= panelX && p.x < panelX + panelW && p.y >= restY && p.y < restY + panelH;
	}

	function panelX(localX:Float):Float
	{
		return restX + slideDeltaX + localX;
	}

	function panelY(localY:Float):Float
	{
		return restY + localY;
	}

	function finishOpen():Void
	{
		isAnimating = false;
		slideTween = null;
		overlayTween = null;
		slideDeltaX = 0;
		syncPopupLayout();
	}

	function finishClose():Void
	{
		isAnimating = false;
		slideTween = null;
		overlayTween = null;
		visible = false;
		slideDeltaX = 0;
		onClosed();
	}

	function onBeforeShow():Void
	{
	}

	function onClosed():Void
	{
	}

	function ensureLayout():Void
	{
		if (cachedLayoutW == FlxG.width && cachedLayoutH == FlxG.height)
			return;

		cachedLayoutW = FlxG.width;
		cachedLayoutH = FlxG.height;
		layoutPopup();
	}

	function ensureOverlay():Void
	{
		if (cachedOverlayW != FlxG.width || cachedOverlayH != FlxG.height)
		{
			overlay.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0xAA000000, true);
			cachedOverlayW = FlxG.width;
			cachedOverlayH = FlxG.height;
		}

		overlay.setPosition(0, 0);
		overlay.updateHitbox();
	}

	function layoutPopup():Void
	{
	}

	function syncPopupLayout():Void
	{
	}

	function handlePanelClick(p:FlxPoint):Bool
	{
		return containsPanelPoint(p);
	}

	function cancelTweens():Void
	{
		if (slideTween != null)
		{
			slideTween.cancel();
			slideTween = null;
		}

		if (overlayTween != null)
		{
			overlayTween.cancel();
			overlayTween = null;
		}

		FlxTween.cancelTweensOf(overlay);
		FlxTween.cancelTweensOf(this);
	}

	function drawBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}
}
