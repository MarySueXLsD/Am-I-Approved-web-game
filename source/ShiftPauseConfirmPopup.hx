package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef ShiftPauseConfirmButton =
{
	hit:FlxSprite,
	bg:FlxSprite,
	label:FlxText,
	hoverTween:FlxTween,
	layoutX:Float,
	layoutY:Float,
	layoutW:Float,
	isPrimary:Bool,
}

class ShiftPauseConfirmPopup extends MainMenuSlidePopup
{
	static inline var PANEL_COLOR = 0xEE1A1410;
	static inline var BORDER_COLOR = 0xFFD4AF6A;
	static inline var LABEL_COLOR = 0xFFF4E4C4;
	static inline var VALUE_COLOR = 0xFFE8C878;
	static inline var BTN_BG = 0xFF2A2218;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	var panel:FlxSprite;
	var messageLabel:FlxText;
	var buttons:Array<ShiftPauseConfirmButton> = [];
	var hoveredIndex = -1;
	var popupPad = 16;
	var popupFontSize = 14;
	var popupBtnW = 0;
	var popupBtnH = 0;
	var popupBtnGap = 12;
	var popupBtnY = 0.0;
	var messageText = "Are you sure you want to start the shift over?";
	var onConfirm:Void->Void;
	var onCancel:Void->Void;

	public function new(?confirmAction:Void->Void, ?cancelAction:Void->Void)
	{
		super();

		onConfirm = confirmAction;
		onCancel = cancelAction;

		panel = new FlxSprite();
		messageLabel = new FlxText(0, 0, 200, messageText);

		slideRoot.add(panel);
		slideRoot.add(messageLabel);

		addButton("Yes", true);
		addButton("Cancel", false);
	}

	public function setMessage(text:String):Void
	{
		messageText = text;
		messageLabel.text = text;
	}

	public function updateHover():Void
	{
		if (!visible || isAnimating)
			return;

		var p = FlxG.mouse.getViewPosition();
		var nextHover = -1;

		for (i in 0...buttons.length)
		{
			if (buttons[i].hit.overlapsPoint(p))
			{
				nextHover = i;
				break;
			}
		}

		if (nextHover != hoveredIndex)
		{
			hoveredIndex = nextHover;
			refreshButtonColors();
		}

		updateButtonHover();
	}

	public function resetHover():Void
	{
		hoveredIndex = -1;
		resetButtonScales();
		refreshButtonColors();
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
		for (btn in buttons)
		{
			if (btn.hit.overlapsPoint(p))
			{
				if (btn.label.text == "Yes")
					handleConfirm();
				else
					handleCancel();
				return true;
			}
		}

		return containsPanelPoint(p);
	}

	override function handleBackdropClick(p:FlxPoint):Bool
	{
		if (!visible || isAnimating)
			return false;

		if (!containsPanelPoint(p))
		{
			handleCancel();
			return true;
		}

		return false;
	}

	function addButton(label:String, isPrimary:Bool):Void
	{
		var hit = new FlxSprite();
		var bg = new FlxSprite();
		var text = new FlxText(0, 0, 80, label);
		buttons.push({
			hit: hit,
			bg: bg,
			label: text,
			hoverTween: null,
			layoutX: 0,
			layoutY: 0,
			layoutW: 0,
			isPrimary: isPrimary
		});
		slideRoot.add(bg);
		slideRoot.add(text);
		slideRoot.add(hit);
	}

	function handleConfirm():Void
	{
		if (onConfirm != null)
			onConfirm();
	}

	function handleCancel():Void
	{
		close();
		if (onCancel != null)
			onCancel();
	}

	override function layoutPopup():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		popupPad = Std.int(Math.max(16, w * 0.03));
		popupFontSize = Std.int(Math.max(14, h / 38));
		panelW = Std.int(Math.min(w - 48, 460));
		popupBtnH = popupFontSize + 12;
		popupBtnW = Std.int(Math.max(100, (panelW - popupPad * 2 - popupBtnGap) * 0.5));
		panelH = Std.int(Math.min(h - 48, popupPad * 2 + popupFontSize * 3 + popupBtnH + 24));
		restX = (w - panelW) * 0.5;
		restY = (h - panelH) * 0.5;
		popupBtnY = panelH - popupPad - popupBtnH;

		panel.makeGraphic(Std.int(panelW), Std.int(panelH), PANEL_COLOR, true);
		drawBorder(panel, Std.int(panelW), Std.int(panelH), BORDER_COLOR, 2);
		panel.updateHitbox();

		messageLabel.text = messageText;
		messageLabel.setFormat(null, popupFontSize, LABEL_COLOR, "center");
		messageLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupFontSize / 14));
		messageLabel.fieldWidth = Std.int(panelW - popupPad * 2);

		var totalBtnW = popupBtnW * 2 + popupBtnGap;
		var btnStartX = (panelW - totalBtnW) * 0.5;

		for (i in 0...buttons.length)
		{
			var btn = buttons[i];
			var btnX = btnStartX + i * (popupBtnW + popupBtnGap);
			btn.layoutX = btnX;
			btn.layoutY = popupBtnY + (popupBtnH - popupFontSize) * 0.5;
			btn.layoutW = popupBtnW;

			btn.bg.makeGraphic(popupBtnW, popupBtnH, BTN_BG, true);
			drawBorder(btn.bg, popupBtnW, popupBtnH, btn.isPrimary ? VALUE_COLOR : BORDER_COLOR, 1);
			btn.bg.updateHitbox();

			btn.hit.makeGraphic(popupBtnW, popupBtnH, 0x00000000, true);
			btn.hit.updateHitbox();

			btn.label.setFormat(null, popupFontSize, btn.isPrimary ? VALUE_COLOR : LABEL_COLOR, "center");
			btn.label.fieldWidth = popupBtnW;
			btn.label.origin.set(0, 0);
			cancelButtonHoverTween(btn);
			btn.label.scale.set(1, 1);
		}

		refreshButtonColors();
		syncPopupLayout();
	}

	override function syncPopupLayout():Void
	{
		panel.setPosition(panelX(0), panelY(0));
		messageLabel.setPosition(panelX(popupPad), panelY(popupPad + 8));

		for (btn in buttons)
		{
			btn.bg.setPosition(panelX(btn.layoutX), panelY(popupBtnY));
			btn.hit.setPosition(btn.bg.x, btn.bg.y);
			syncButtonScalePosition(btn);
		}
	}

	function refreshButtonColors():Void
	{
		for (i in 0...buttons.length)
		{
			var btn = buttons[i];
			var hovered = i == hoveredIndex;
			btn.label.color = hovered ? VALUE_COLOR : (btn.isPrimary ? VALUE_COLOR : LABEL_COLOR);
			redrawButtonBg(btn, hovered);
		}
	}

	function redrawButtonBg(btn:ShiftPauseConfirmButton, hovered:Bool):Void
	{
		var border = hovered ? VALUE_COLOR : (btn.isPrimary ? VALUE_COLOR : BORDER_COLOR);
		btn.bg.makeGraphic(Std.int(btn.bg.width), Std.int(btn.bg.height), BTN_BG, true);
		drawBorder(btn.bg, Std.int(btn.bg.width), Std.int(btn.bg.height), border, hovered ? 2 : 1);
		btn.bg.updateHitbox();
	}

	function updateButtonHover():Void
	{
		for (i in 0...buttons.length)
			tweenButtonScale(buttons[i], i == hoveredIndex ? HOVER_SCALE : 1);
	}

	function tweenButtonScale(btn:ShiftPauseConfirmButton, targetScale:Float):Void
	{
		if (Math.abs(btn.label.scale.x - targetScale) <= 0.01)
			return;

		cancelButtonHoverTween(btn);
		btn.hoverTween = FlxTween.tween(btn.label.scale, {x: targetScale, y: targetScale}, HOVER_TWEEN_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				syncButtonScalePosition(btn);
			},
			onComplete: function(_)
			{
				syncButtonScalePosition(btn);
			}
		});
	}

	function syncButtonScalePosition(btn:ShiftPauseConfirmButton):Void
	{
		var s = btn.label.scale.x;
		btn.label.setPosition(btn.bg.x + btn.layoutW * (1 - s) * 0.5, panelY(btn.layoutY));
	}

	function cancelButtonHoverTween(btn:ShiftPauseConfirmButton):Void
	{
		if (btn.hoverTween != null)
		{
			btn.hoverTween.cancel();
			btn.hoverTween = null;
		}

		FlxTween.cancelTweensOf(btn.label.scale);
	}

	function resetButtonScales():Void
	{
		for (btn in buttons)
		{
			cancelButtonHoverTween(btn);
			btn.label.scale.set(1, 1);
			syncButtonScalePosition(btn);
		}
	}
}
