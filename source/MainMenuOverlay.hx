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

typedef MainMenuItem =
{
	label:String,
	enabled:Bool,
	action:Void->Void,
	hit:FlxSprite,
	text:FlxText,
	hoverTween:FlxTween,
	layoutX:Float,
	layoutY:Float,
	layoutW:Float,
}

class MainMenuOverlay extends FlxGroup
{
	static inline var SIDEBAR_RATIO = 0.26;
	static inline var SIDEBAR_ALPHA = 0.72;
	static inline var ITEM_COLOR = 0xFFF4E4C4;
	static inline var ITEM_HOVER = 0xFFE8C878;
	static inline var ITEM_DISABLED = 0xFF7A7068;
	static inline var TITLE_COLOR = 0xFFE8C878;
	static inline var GOLD_LINE = 0xFFD4AF6A;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;
	static inline var INTRO_FADE_DURATION = 0.9;

	static var instance:MainMenuOverlay;

	var bgImage:FlxSprite;
	var blackScreen:FlxSprite;
	var introFadeTween:FlxTween;
	var clouds:MainMenuClouds;
	var traffic:MainMenuTraffic;
	var sidebar:FlxSprite;
	var sidebarDivider:FlxSprite;
	var titleOrnament:FlxSprite;
	var titleLine1:FlxText;
	var titleLine2:FlxText;
	var menuItems:Array<MainMenuItem> = [];
	var creditsPopup:MainMenuCreditsPopup;
	var optionsPopup:MainMenuOptionsPopup;
	var onNewGame:Void->Void;
	var hoveredIndex = -1;

	public var isShowing(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && instance.isShowing;
	}

	public function new(?newGame:Void->Void)
	{
		super();
		instance = this;
		onNewGame = newGame;

		bgImage = new FlxSprite();
		bgImage.loadGraphic("static/Main_Menu/menu_image.png");
		add(bgImage);

		clouds = new MainMenuClouds();
		add(clouds);

		traffic = new MainMenuTraffic();
		add(traffic);

		sidebar = new FlxSprite();
		add(sidebar);

		sidebarDivider = new FlxSprite();
		add(sidebarDivider);

		titleOrnament = new FlxSprite();
		add(titleOrnament);

		titleLine1 = new FlxText(0, 0, 200, "Am I");
		titleLine2 = new FlxText(0, 0, 200, "approved?");
		add(titleLine1);
		add(titleLine2);

		addMenuItem("New Game", true, startNewGame);
		addMenuItem("Load Game", false, null);
		addMenuItem("Options", true, openOptions);
		addMenuItem("Credits", true, openCredits);

		creditsPopup = new MainMenuCreditsPopup();
		add(creditsPopup);

		optionsPopup = new MainMenuOptionsPopup();
		add(optionsPopup);

		blackScreen = new FlxSprite();
		add(blackScreen);

		resetVisualState();
	}

	public function show(?fadeFromBlack:Bool = false):Void
	{
		if (isShowing)
			return;

		cancelIntroFade();
		isShowing = true;
		visible = true;
		creditsPopup.forceClose();
		optionsPopup.forceClose();
		layout();
		optionsPopup.prepare();
		creditsPopup.prepare();
		clouds.startClouds();
		traffic.startTraffic();

		if (fadeFromBlack)
			startIntroFade();
		else
		{
			blackScreen.visible = false;
			blackScreen.alpha = 0;
		}
	}

	public function hide():Void
	{
		if (!isShowing)
			return;

		cancelIntroFade();
		creditsPopup.forceClose();
		optionsPopup.forceClose();
		clouds.stopClouds();
		traffic.stopTraffic();
		isShowing = false;
		visible = false;
		hoveredIndex = -1;
		resetMenuItemScales();
	}

	public function handleClick(p:FlxPoint):Bool
	{
		if (!isShowing)
			return false;

		if (optionsPopup.isActive())
		{
			optionsPopup.handleClick(p);
			return true;
		}

		if (creditsPopup.isActive())
		{
			creditsPopup.handleClick(p);
			return true;
		}

		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			if (item.enabled && item.hit.overlapsPoint(p))
			{
				if (item.action != null)
					item.action();
				return true;
			}
		}

		return true;
	}

	public function handleWheel(wheel:Float):Void
	{
		if (!isShowing || !creditsPopup.isOpen() || creditsPopup.isBusy())
			return;

		creditsPopup.handleWheel(wheel);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isShowing)
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

		if (creditsPopup.isActive())
		{
			if (!creditsPopup.isBusy())
				creditsPopup.updateHover();
			return;
		}

		var nextHover = -1;
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			if (item.enabled && item.hit.overlapsPoint(p))
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

	function addMenuItem(label:String, enabled:Bool, action:Void->Void):Void
	{
		var hit = new FlxSprite();
		var text = new FlxText(0, 0, 100, label);
		menuItems.push({
			label: label,
			enabled: enabled,
			action: action,
			hit: hit,
			text: text,
			hoverTween: null,
			layoutX: 0,
			layoutY: 0,
			layoutW: 0
		});
		add(hit);
		add(text);
	}

	function startNewGame():Void
	{
		hide();
		if (onNewGame != null)
			onNewGame();
	}

	function openOptions():Void
	{
		if (optionsPopup.isActive())
			return;

		creditsPopup.forceClose();
		optionsPopup.show();
	}

	function openCredits():Void
	{
		if (creditsPopup.isActive())
			return;

		optionsPopup.forceClose();
		creditsPopup.show();
	}

	function startIntroFade():Void
	{
		blackScreen.visible = true;
		blackScreen.alpha = 1;
		introFadeTween = FlxTween.tween(blackScreen, {alpha: 0}, INTRO_FADE_DURATION, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				introFadeTween = null;
				blackScreen.visible = false;
			}
		});
	}

	function cancelIntroFade():Void
	{
		if (introFadeTween != null)
		{
			introFadeTween.cancel();
			introFadeTween = null;
		}

		FlxTween.cancelTweensOf(blackScreen);
	}

	function layout():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;

		blackScreen.makeGraphic(Std.int(w), Std.int(h), 0xFF000000, true);
		blackScreen.setPosition(0, 0);
		blackScreen.updateHitbox();

		var sidebarW = Std.int(w * SIDEBAR_RATIO);
		var sidebarX = w - sidebarW;

		bgImage.setPosition(0, 0);
		bgImage.setGraphicSize(Std.int(w), Std.int(h));
		bgImage.updateHitbox();

		clouds.layout(w, h);
		traffic.layout(w, h);

		sidebar.setPosition(sidebarX, 0);
		sidebar.makeGraphic(sidebarW, Std.int(h), 0xFF000000, true);
		sidebar.alpha = SIDEBAR_ALPHA;
		sidebar.updateHitbox();

		sidebarDivider.setPosition(sidebarX, 0);
		sidebarDivider.makeGraphic(2, Std.int(h), GOLD_LINE, true);
		sidebarDivider.updateHitbox();

		var titleSize = Std.int(Math.max(19, h / 22 - 1));
		var itemSize = Std.int(Math.max(18, h / 28));
		var pad = Std.int(Math.max(16, sidebarW * 0.1));
		var itemH = itemSize + 22;
		var itemGap = 8;
		var itemW = sidebarW - pad * 2;
		var ornamentH = 2;
		var ornamentW = Std.int(itemW * 0.42);
		var titleLineGap = Std.int(Math.max(2, titleSize * 0.08));
		var titleOrnamentGap = Std.int(Math.max(10, titleSize * 0.4));
		var titleMenuGap = Std.int(Math.max(20, h * 0.035));
		var contentX = sidebarX + pad;
		var contentY = Std.int(Math.max(pad, h * 0.07));
		var titleBlockH = titleSize * 2 + titleLineGap;

		layoutTitleLine(titleLine1, "Am I", titleSize, itemW, contentX, contentY);
		layoutTitleLine(titleLine2, "approved?", titleSize, itemW, contentX, contentY + titleSize + titleLineGap);

		var ornamentY = contentY + titleBlockH + titleOrnamentGap;
		var ornamentX = contentX + (itemW - ornamentW) * 0.5;
		titleOrnament.setPosition(ornamentX, ornamentY);
		titleOrnament.makeGraphic(ornamentW, ornamentH, GOLD_LINE, true);
		titleOrnament.updateHitbox();

		var menuStartY = ornamentY + ornamentH + titleMenuGap;
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var y = menuStartY + i * (itemH + itemGap);
			item.hit.setPosition(contentX, y);
			item.hit.makeGraphic(itemW, itemH, 0x00000000, true);
			item.hit.updateHitbox();

			item.layoutX = contentX;
			item.layoutY = y + (itemH - itemSize) * 0.5;
			item.layoutW = itemW;
			item.text.text = item.label;
			item.text.setFormat(null, itemSize, item.enabled ? ITEM_COLOR : ITEM_DISABLED, "center");
			item.text.fieldWidth = itemW;
			item.text.origin.set(0, 0);
			cancelItemHoverTween(item);
			item.text.scale.set(1, 1);
			syncItemScalePosition(item);
		}

		refreshMenuColors();
	}

	function layoutTitleLine(label:FlxText, text:String, size:Int, width:Int, x:Float, y:Float):Void
	{
		label.text = text;
		label.setFormat(null, size, TITLE_COLOR, "center");
		label.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(24, 16, 10), Math.max(1, size / 16));
		label.fieldWidth = width;
		label.setPosition(x, y);
	}

	function refreshMenuColors():Void
	{
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			if (!item.enabled)
				item.text.color = ITEM_DISABLED;
			else if (i == hoveredIndex)
				item.text.color = ITEM_HOVER;
			else
				item.text.color = ITEM_COLOR;
		}
	}

	function updateMenuItemHover():Void
	{
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			if (!item.enabled)
			{
				tweenItemScale(item, 1);
				continue;
			}

			tweenItemScale(item, i == hoveredIndex ? HOVER_SCALE : 1);
		}
	}

	function tweenItemScale(item:MainMenuItem, targetScale:Float):Void
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

	function syncItemScalePosition(item:MainMenuItem):Void
	{
		var s = item.text.scale.x;
		item.text.setPosition(item.layoutX + item.layoutW * (1 - s) * 0.5, item.layoutY);
	}

	function cancelItemHoverTween(item:MainMenuItem):Void
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

	function resetVisualState():Void
	{
		visible = false;
		isShowing = false;
		blackScreen.visible = false;
		blackScreen.alpha = 0;
	}
}
