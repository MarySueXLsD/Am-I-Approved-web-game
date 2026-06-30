package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class EndOfDemoPopup extends MainMenuSlidePopup
{
	static inline var PANEL_COLOR = 0xEE1A1410;
	static inline var BORDER_COLOR = 0xFFD4AF6A;
	static inline var LABEL_COLOR = 0xFFF4E4C4;
	static inline var BTN_BG = 0xFF2A2218;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	static var instance:EndOfDemoPopup;

	var panel:FlxSprite;
	var messageLabel:FlxText;
	var okHit:FlxSprite;
	var okBg:FlxSprite;
	var okLabel:FlxText;
	var okHoverTween:FlxTween;
	var okHovered = false;
	var popupPad = 16;
	var popupFontSize = 14;
	var popupBtnW = 0;
	var popupBtnH = 0;
	var popupBtnY = 0.0;
	var onDismiss:Void->Void;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isActive();
	}

	public function new(?dismissAction:Void->Void)
	{
		super();
		instance = this;
		onDismiss = dismissAction;

		panel = new FlxSprite();
		messageLabel = new FlxText(0, 0, 200, "Thanks for playing!\n\nFor now, that's it.");
		okHit = new FlxSprite();
		okBg = new FlxSprite();
		okLabel = new FlxText(0, 0, 80, "OK");

		slideRoot.add(panel);
		slideRoot.add(messageLabel);
		slideRoot.add(okBg);
		slideRoot.add(okLabel);
		slideRoot.add(okHit);
	}

	public function updateHover():Void
	{
		if (!visible || isAnimating)
			return;

		var p = FlxG.mouse.getViewPosition();
		var nextHover = okHit.overlapsPoint(p);
		if (nextHover != okHovered)
		{
			okHovered = nextHover;
			okBg.color = okHovered ? 0xFF3A3024 : BTN_BG;
			updateOkHoverScale();
		}
	}

	public function resetHover():Void
	{
		okHovered = false;
		okBg.color = BTN_BG;
		cancelOkHoverTween();
		okBg.scale.set(1, 1);
		okLabel.scale.set(1, 1);
		syncOkButtonLayout();
	}

	override function onBeforeShow():Void
	{
		resetHover();
	}

	override function onClosed():Void
	{
		resetHover();
	}

	override function handlePanelClick(p:FlxPoint):Bool
	{
		if (okHit.overlapsPoint(p))
		{
			handleOk();
			return true;
		}

		return containsPanelPoint(p);
	}

	override function handleBackdropClick(p:FlxPoint):Bool
	{
		return visible && !isAnimating;
	}

	function handleOk():Void
	{
		close();
		if (onDismiss != null)
			onDismiss();
	}

	override function layoutPopup():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		popupPad = Std.int(Math.max(16, w * 0.03));
		popupFontSize = Std.int(Math.max(14, h / 38));
		panelW = Std.int(Math.min(w - 48, 460));
		popupBtnH = popupFontSize + 12;
		popupBtnW = Std.int(Math.max(120, panelW * 0.4));
		panelH = Std.int(Math.min(h - 48, popupPad * 2 + popupFontSize * 5 + popupBtnH + 24));
		restX = (w - panelW) * 0.5;
		restY = (h - panelH) * 0.5;
		popupBtnY = panelH - popupPad - popupBtnH;

		panel.makeGraphic(Std.int(panelW), Std.int(panelH), PANEL_COLOR, true);
		drawBorder(panel, Std.int(panelW), Std.int(panelH), BORDER_COLOR, 2);
		panel.updateHitbox();

		messageLabel.text = "Thanks for playing!\n\nFor now, that's it.";
		messageLabel.setFormat(null, popupFontSize, LABEL_COLOR, "center");
		messageLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupFontSize / 14));
		messageLabel.fieldWidth = Std.int(panelW - popupPad * 2);
		messageLabel.wordWrap = true;

		okBg.makeGraphic(popupBtnW, popupBtnH, BTN_BG, true);
		drawBorder(okBg, popupBtnW, popupBtnH, BORDER_COLOR, 1);
		okHit.makeGraphic(popupBtnW, popupBtnH, 0x00000000, true);
		okLabel.setFormat(null, popupFontSize, LABEL_COLOR, "center");
		okLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupFontSize / 14));
		okLabel.fieldWidth = popupBtnW;

		syncPopupLayout();
	}

	override function syncPopupLayout():Void
	{
		super.syncPopupLayout();
		messageLabel.setPosition(panelX(popupPad), panelY(popupPad + 8));
		syncOkButtonLayout();
	}

	function syncOkButtonLayout():Void
	{
		var btnX = (panelW - popupBtnW) * 0.5;
		okBg.setPosition(panelX(btnX), panelY(popupBtnY));
		okHit.setPosition(panelX(btnX), panelY(popupBtnY));
		okLabel.setPosition(panelX(btnX), panelY(popupBtnY + (popupBtnH - popupFontSize) * 0.5));
	}

	function updateOkHoverScale():Void
	{
		cancelOkHoverTween();
		var target = okHovered ? HOVER_SCALE : 1.0;
		okHoverTween = FlxTween.tween(okBg, {scaleX: target, scaleY: target}, HOVER_TWEEN_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				okLabel.scale.set(okBg.scale.x, okBg.scale.y);
				syncOkButtonLayout();
			},
			onComplete: function(_)
			{
				okHoverTween = null;
			}
		});
	}

	function cancelOkHoverTween():Void
	{
		if (okHoverTween != null)
		{
			okHoverTween.cancel();
			okHoverTween = null;
		}
	}
}
