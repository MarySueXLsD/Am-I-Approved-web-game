package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

typedef ShiftPauseMenuItem =
{
	label:String,
	action:Void->Void,
	hit:FlxSprite,
	text:FlxText,
	hoverTween:FlxTween,
	layoutX:Float,
	layoutY:Float,
	layoutW:Float,
}

class ShiftPausePopup extends MainMenuSlidePopup
{
	static inline var PANEL_COLOR = 0xEE1A1410;
	static inline var BORDER_COLOR = 0xFFD4AF6A;
	static inline var ITEM_COLOR = 0xFFF4E4C4;
	static inline var ITEM_HOVER = 0xFFE8C878;
	static inline var TITLE_COLOR = 0xFFE8C878;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	var panel:FlxSprite;
	var titleLabel:FlxText;
	var ornament:FlxSprite;
	var menuItems:Array<ShiftPauseMenuItem> = [];
	var hoveredIndex = -1;
	var popupPad = 16;
	var popupTitleSize = 24;
	var popupItemSize = 18;
	var popupItemH = 0;
	var popupItemGap = 8;
	var popupMenuStartY = 0.0;
	var popupItemW = 0.0;
	var onContinue:Void->Void;
	var onRestartShift:Void->Void;
	var onOpenOptions:Void->Void;
	var onQuitJob:Void->Void;

	public function new(?continueAction:Void->Void, ?restartAction:Void->Void, ?optionsAction:Void->Void, ?quitJobAction:Void->Void)
	{
		super();

		onContinue = continueAction;
		onRestartShift = restartAction;
		onOpenOptions = optionsAction;
		onQuitJob = quitJobAction;

		panel = new FlxSprite();
		ornament = new FlxSprite();
		titleLabel = new FlxText(0, 0, 200, "Paused");

		slideRoot.add(panel);
		slideRoot.add(ornament);
		slideRoot.add(titleLabel);

		addMenuItem("Continue", handleContinue);
		addMenuItem("Start the shift over", handleRestartShift);
		addMenuItem("Options", handleOpenOptions);
		addMenuItem("Quit the job", handleQuitJob);
	}

	public function updateHover():Void
	{
		if (!visible || isAnimating)
			return;

		var p = FlxG.mouse.getViewPosition();
		var nextHover = -1;

		for (i in 0...menuItems.length)
		{
			if (menuItems[i].hit.overlapsPoint(p))
			{
				nextHover = i;
				break;
			}
		}

		if (nextHover != hoveredIndex)
		{
			hoveredIndex = nextHover;
			refreshMenuColors();
		}

		updateMenuItemHover();
	}

	public function resetHover():Void
	{
		hoveredIndex = -1;
		resetMenuItemScales();
		refreshMenuColors();
	}

	override function onBeforeShow():Void
	{
		resetHover();
	}

	override function onClosed():Void
	{
		resetHover();
		if (onContinue != null)
			onContinue();
	}

	override function handlePanelClick(p:FlxPoint):Bool
	{
		for (item in menuItems)
		{
			if (item.hit.overlapsPoint(p))
			{
				if (item.action != null)
					item.action();
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
			handleContinue();
			return true;
		}

		return false;
	}

	function addMenuItem(label:String, action:Void->Void):Void
	{
		var hit = new FlxSprite();
		var text = new FlxText(0, 0, 100, label);
		menuItems.push({
			label: label,
			action: action,
			hit: hit,
			text: text,
			hoverTween: null,
			layoutX: 0,
			layoutY: 0,
			layoutW: 0
		});
		slideRoot.add(hit);
		slideRoot.add(text);
	}

	function handleContinue():Void
	{
		close();
	}

	function handleRestartShift():Void
	{
		if (onRestartShift != null)
			onRestartShift();
	}

	function handleOpenOptions():Void
	{
		if (onOpenOptions != null)
			onOpenOptions();
	}

	function handleQuitJob():Void
	{
		if (onQuitJob != null)
			onQuitJob();
	}

	override function layoutPopup():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		popupPad = Std.int(Math.max(16, w * 0.03));
		popupTitleSize = Std.int(Math.max(24, h / 22));
		popupItemSize = Std.int(Math.max(18, h / 28));
		popupItemH = popupItemSize + 22;
		popupItemGap = 8;
		panelW = Std.int(Math.min(w - 48, 420));
		popupItemW = panelW - popupPad * 2;

		titleLabel.text = "Paused";
		titleLabel.setFormat(null, popupTitleSize, TITLE_COLOR, "center");
		titleLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupTitleSize / 14));
		titleLabel.fieldWidth = Std.int(popupItemW);

		var ornamentW = Std.int(popupItemW * 0.42);
		var ornamentH = 2;
		var titleOrnamentGap = Std.int(Math.max(10, popupTitleSize * 0.4));
		var titleMenuGap = Std.int(Math.max(20, h * 0.035));
		ornament.makeGraphic(ornamentW, ornamentH, BORDER_COLOR, true);
		ornament.updateHitbox();

		popupMenuStartY = popupPad + popupTitleSize + titleOrnamentGap + ornamentH + titleMenuGap;
		var menuHeight = menuItems.length * popupItemH + (menuItems.length - 1) * popupItemGap;
		panelH = Std.int(Math.min(h - 48, popupMenuStartY + menuHeight + popupPad));
		restX = (w - panelW) * 0.5;
		restY = (h - panelH) * 0.5;

		panel.makeGraphic(Std.int(panelW), Std.int(panelH), PANEL_COLOR, true);
		drawBorder(panel, Std.int(panelW), Std.int(panelH), BORDER_COLOR, 2);
		panel.updateHitbox();

		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var y = popupMenuStartY + i * (popupItemH + popupItemGap);
			item.hit.makeGraphic(Std.int(popupItemW), popupItemH, 0x00000000, true);
			item.hit.updateHitbox();

			item.layoutX = popupPad;
			item.layoutY = y + (popupItemH - popupItemSize) * 0.5;
			item.layoutW = popupItemW;
			item.text.text = item.label;
			item.text.setFormat(null, popupItemSize, ITEM_COLOR, "center");
			item.text.fieldWidth = Std.int(popupItemW);
			item.text.origin.set(0, 0);
			cancelItemHoverTween(item);
			item.text.scale.set(1, 1);
		}

		refreshMenuColors();
		syncPopupLayout();
	}

	override function syncPopupLayout():Void
	{
		panel.setPosition(panelX(0), panelY(0));
		titleLabel.setPosition(panelX(popupPad), panelY(popupPad));

		var ornamentW = ornament.width;
		ornament.setPosition(panelX(popupPad + (popupItemW - ornamentW) * 0.5),
			panelY(popupPad + popupTitleSize + Std.int(Math.max(10, popupTitleSize * 0.4))));

		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var y = popupMenuStartY + i * (popupItemH + popupItemGap);
			item.hit.setPosition(panelX(popupPad), panelY(y));
			syncItemScalePosition(item);
		}
	}

	function refreshMenuColors():Void
	{
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			item.text.color = i == hoveredIndex ? ITEM_HOVER : ITEM_COLOR;
		}
	}

	function updateMenuItemHover():Void
	{
		for (i in 0...menuItems.length)
			tweenItemScale(menuItems[i], i == hoveredIndex ? HOVER_SCALE : 1);
	}

	function tweenItemScale(item:ShiftPauseMenuItem, targetScale:Float):Void
	{
		if (Math.abs(item.text.scale.x - targetScale) <= 0.01)
			return;

		cancelItemHoverTween(item);
		item.hoverTween = FlxTween.tween(item.text.scale, {x: targetScale, y: targetScale}, HOVER_TWEEN_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				syncItemScalePosition(item);
			},
			onComplete: function(_)
			{
				syncItemScalePosition(item);
			}
		});
	}

	function syncItemScalePosition(item:ShiftPauseMenuItem):Void
	{
		var s = item.text.scale.x;
		item.text.setPosition(panelX(item.layoutX + item.layoutW * (1 - s) * 0.5), panelY(item.layoutY));
	}

	function cancelItemHoverTween(item:ShiftPauseMenuItem):Void
	{
		if (item.hoverTween != null)
		{
			item.hoverTween.cancel();
			item.hoverTween = null;
		}

		FlxTween.cancelTweensOf(item.text.scale);
	}

	function resetMenuItemScales():Void
	{
		for (item in menuItems)
		{
			cancelItemHoverTween(item);
			item.text.scale.set(1, 1);
			syncItemScalePosition(item);
		}
	}
}
