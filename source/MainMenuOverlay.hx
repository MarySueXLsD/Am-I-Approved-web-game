package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

typedef MainMenuItem =
{
	label:String,
	enabled:Bool,
	action:Void->Void,
	hit:FlxSprite,
	text:FlxText,
	bg:FlxSprite,
	hoverTween:FlxTween,
	layoutX:Float,
	layoutY:Float,
	layoutW:Float,
	layoutH:Float,
	slideX:Float,
}

class MainMenuOverlay extends FlxGroup
{
	static inline var SIDEBAR_RATIO = 0.27;
	static inline var CARD_MARGIN = 12;
	static inline var DEMO_BADGE_W = 60;
	static inline var DEMO_BADGE_H = 24;
	static inline var DEMO_BADGE_ANGLE = 8.0;
	static inline var ITEM_COLOR = UiSkin.INK;
	static inline var ITEM_HOVER = UiSkin.PANEL_DEEP;
	static inline var ITEM_DISABLED = UiSkin.MUTED;
	static inline var HOVER_TINT = UiSkin.HOVER_TINT;
	static inline var HOVER_SCALE = 1.08;
	static inline var HOVER_TWEEN_DURATION = 0.14;
	static inline var INTRO_FADE_DURATION = 0.9;
	static inline var NEW_GAME_FADE_TO_BLACK = 0.9;
	static inline var NEW_GAME_TRAFFIC_FADE_DURATION = 3.0;
	static inline var NEW_GAME_MUSIC_FADE_DURATION = 2.0;
	static inline var NEW_GAME_MUSIC_VOLUME_FACTOR = 0.5;
	static inline var TRAFFIC_AMBIENT = "static/Audio/Ambient/TrafficMenu.mp3";
	static inline var MENU_MUSIC = "static/Audio/OST/BreakTheBankloop.mp3";

	static var instance:MainMenuOverlay;
	static var preloadedMenuMusic:FlxSound;
	static var preloadedTrafficAmbient:FlxSound;

	public static function preloadAudio():Void
	{
		FlxG.sound.cache(MENU_MUSIC);
		FlxG.sound.cache(TRAFFIC_AMBIENT);

		if (preloadedMenuMusic == null)
		{
			preloadedMenuMusic = FlxG.sound.load(MENU_MUSIC, 0, true, null, false, false);
			if (preloadedMenuMusic != null)
				preloadedMenuMusic.persist = true;
		}

		if (preloadedTrafficAmbient == null)
		{
			preloadedTrafficAmbient = FlxG.sound.load(TRAFFIC_AMBIENT, 0, true, null, false, false);
			if (preloadedTrafficAmbient != null)
				preloadedTrafficAmbient.persist = true;
		}
	}

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
	var demoBadge:FlxSprite;
	var demoLabel:FlxText;
	var footerText:FlxText;
	var titleStampBaseAngle = -7.0;
	var titlePlateBaseY = 0.0;
	var titleLine1BaseY = 0.0;
	var titleLine2BaseY = 0.0;
	var demoBadgeBaseY = 0.0;
	var demoLabelBaseY = 0.0;
	var titleStampLanded = false;
	var idleTime = 0.0;
	var introTweens:Array<FlxTween> = [];
	var menuItems:Array<MainMenuItem> = [];
	var creditsPopup:MainMenuCreditsPopup;
	var optionsPopup:MainMenuOptionsPopup;
	var trafficAmbient:FlxSound;
	var menuMusic:FlxSound;
	var trafficAmbientFadeTween:FlxTween;
	var menuMusicFadeTween:FlxTween;
	var musicVolumeMultiplier = 1.0;
	var newGameTransition = false;
	var menuAudioPending = false;
	var onNewGame:Void->Void;
	var hoveredIndex = -1;

	public var isShowing(default, null) = false;

	public static function blocksWorldInput():Bool
	{
		return instance != null && (instance.isShowing || instance.newGameTransition);
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
		titleLine2 = new FlxText(0, 0, 200, "APPROVED?");
		add(titleLine1);
		add(titleLine2);

		demoBadge = new FlxSprite();
		add(demoBadge);
		demoLabel = new FlxText(0, 0, DEMO_BADGE_W, "DEMO");
		add(demoLabel);

		footerText = new FlxText(0, 0, 200, "");
		add(footerText);

		addMenuItem("New Game", true, startNewGame);
		addMenuItem("Options", true, openOptions);
		addMenuItem("Credits", true, openCredits);

		creditsPopup = new MainMenuCreditsPopup();
		add(creditsPopup);

		optionsPopup = new MainMenuOptionsPopup();
		add(optionsPopup);

		GameSettings.onVolumeChanged(syncMenuAudioVolumes);

		blackScreen = new FlxSprite();
		add(blackScreen);

		resetVisualState();
	}

	public function show(?fadeFromBlack:Bool = false):Void
	{
		if (isShowing)
			return;

		cancelIntroFade();
		cancelNewGameAudioTweens();
		newGameTransition = false;
		musicVolumeMultiplier = 1.0;
		traffic.resetFadeState();
		restoreMenuChrome();
		isShowing = true;
		visible = true;
		creditsPopup.forceClose();
		optionsPopup.forceClose();
		layout();
		optionsPopup.prepare();
		creditsPopup.prepare();
		clouds.startClouds();
		traffic.startTraffic();
		menuAudioPending = true;
		ensureMenuAudio();

		if (fadeFromBlack)
			startIntroFade();
		else
		{
			blackScreen.visible = false;
			blackScreen.alpha = 0;
		}

		playIntro(fadeFromBlack ? INTRO_FADE_DURATION * 0.6 : 0.05);
	}

	/** Buttons slide in one after another, then the APPROVED? stamp slams onto the title plate. */
	function playIntro(delay:Float):Void
	{
		cancelIntroTweens();
		titleStampLanded = false;
		idleTime = 0;

		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			item.slideX = FlxG.width * 0.35;
			syncItemScalePosition(item);
			introTweens.push(FlxTween.tween(item, {slideX: 0}, 0.42, {
				ease: FlxEase.backOut,
				startDelay: delay + 0.08 * i,
				onUpdate: function(_) syncItemScalePosition(item),
				onComplete: function(_) syncItemScalePosition(item)
			}));
		}

		titleLine2.alpha = 0;
		titleLine2.scale.set(2.6, 2.6);
		titleLine2.angle = titleStampBaseAngle - 10;
		demoBadge.alpha = 0;
		demoLabel.alpha = 0;
		var stampDelay = delay + 0.08 * menuItems.length + 0.2;
		introTweens.push(FlxTween.tween(titleLine2, {alpha: 1, angle: titleStampBaseAngle}, 0.16, {
			ease: FlxEase.quadIn,
			startDelay: stampDelay
		}));
		introTweens.push(FlxTween.tween(titleLine2.scale, {x: 1, y: 1}, 0.16, {
			ease: FlxEase.quadIn,
			startDelay: stampDelay,
			onComplete: function(_)
			{
				titleStampLanded = true;
				demoBadge.alpha = 1;
				demoLabel.alpha = 1;
				if (!isShowing)
					return;
				Juice.sfx(Juice.SFX_STAMP, 0.8);
				Juice.shake(0.005, 0.15);
				Juice.burst(titleLine2.x + titleLine2.width * 0.5, titleLine2.y + titleLine2.height * 0.5,
					[UiSkin.TRIM, UiSkin.STAMP_RED, UiSkin.CREAM], 18, 200, 0.7, 4, 420);
				Juice.punch(titleOrnament, 0.06, 0.3);
				Juice.punch(demoBadge, 0.25, 0.3);
				Juice.punch(demoLabel, 0.25, 0.3);
			}
		}));
	}

	function cancelIntroTweens():Void
	{
		for (t in introTweens)
			t.cancel();
		introTweens = [];
		FlxTween.cancelTweensOf(titleLine2);
		FlxTween.cancelTweensOf(titleLine2.scale);
		titleLine2.alpha = 1;
		titleLine2.scale.set(1, 1);
		titleLine2.angle = titleStampBaseAngle;
		demoBadge.alpha = 1;
		demoLabel.alpha = 1;
		for (item in menuItems)
		{
			item.slideX = 0;
			syncItemScalePosition(item);
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
		stopTrafficAmbient();
		stopMenuMusic();
		isShowing = false;
		visible = false;
		hoveredIndex = -1;
		resetMenuItemScales();
	}

	public function handleClick(p:FlxPoint):Bool
	{
		if (!isShowing)
			return false;

		ensureMenuAudio();

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
			if (item.hit.overlapsPoint(p))
			{
				if (!item.enabled)
				{
					// Locked buttons shake "no" instead of silently ignoring the click.
					Juice.sfx(Juice.SFX_ERROR, 0.35);
					FlxTween.cancelTweensOf(item, ["slideX"]);
					item.slideX = 10;
					FlxTween.tween(item, {slideX: 0}, 0.4, {
						ease: FlxEase.elasticOut,
						onUpdate: function(_) syncItemScalePosition(item),
						onComplete: function(_) syncItemScalePosition(item)
					});
					return true;
				}
				Juice.sfx(Juice.SFX_STAMP, 0.45, 0.1);
				Juice.punch(item.bg, 0.1, 0.25);
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

		if (menuAudioPending || !isMenuAudioPlaying())
			ensureMenuAudio();

		if (FlxG.mouse.justPressed || FlxG.mouse.justMoved)
			ensureMenuAudio();

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
			if (nextHover >= 0)
				Juice.blip();
			refreshMenuColors();
		}

		updateMenuItemHover();
		updateIdle(elapsed);
	}

	/** Small idle life: the title plate bobs and the stamp breathes once it has landed. */
	function updateIdle(elapsed:Float):Void
	{
		idleTime += elapsed;
		var bob = Math.round(Math.sin(idleTime * 1.6) * 2);
		titleOrnament.y = titlePlateBaseY + bob;
		titleLine1.y = titleLine1BaseY + bob;
		titleLine2.y = titleLine2BaseY + bob;
		demoBadge.y = demoBadgeBaseY + bob;
		demoLabel.y = demoLabelBaseY + bob;
		if (titleStampLanded)
			titleLine2.angle = titleStampBaseAngle + Math.sin(idleTime * 2.3) * 1.2;
	}

	function addMenuItem(label:String, enabled:Bool, action:Void->Void):Void
	{
		var hit = new FlxSprite();
		var bg = new FlxSprite();
		var text = new FlxText(0, 0, 100, label);
		menuItems.push({
			label: label,
			enabled: enabled,
			action: action,
			hit: hit,
			text: text,
			bg: bg,
			hoverTween: null,
			layoutX: 0,
			layoutY: 0,
			layoutW: 0,
			layoutH: 0,
			slideX: 0
		});
		add(bg);
		add(hit);
		add(text);
	}

	function startNewGame():Void
	{
		if (newGameTransition)
			return;

		beginNewGameTransition();
	}

	public function completeNewGameTransition():Void
	{
		cancelIntroFade();
		cancelTrafficAmbientFadeTween();
		newGameTransition = false;
		stopTrafficAmbient();
		traffic.resetFadeState();
		traffic.stopTraffic();
		blackScreen.visible = false;
		blackScreen.alpha = 0;
		visible = false;
		isShowing = false;
		hoveredIndex = -1;
		resetMenuItemScales();
		restoreMenuChrome();
	}

	public function releaseMenuMusicForGameplay():Void
	{
		cancelMenuMusicFadeTween();
		if (menuMusic != null)
			menuMusic.stop();
	}

	public function stopMenuMusicForReturnToMenu():Void
	{
		musicVolumeMultiplier = 1.0;
		releaseMenuMusicForGameplay();
	}

	function beginNewGameTransition():Void
	{
		newGameTransition = true;

		cancelIntroFade();
		creditsPopup.forceClose();
		optionsPopup.forceClose();
		clouds.stopClouds();
		isShowing = false;
		hoveredIndex = -1;
		resetMenuItemScales();

		traffic.beginFadeOut(NEW_GAME_TRAFFIC_FADE_DURATION, function()
		{
			if (newGameTransition)
				visible = false;
		});
		fadeTrafficAmbientOut(NEW_GAME_TRAFFIC_FADE_DURATION);
		fadeMenuMusicVolume(NEW_GAME_MUSIC_VOLUME_FACTOR, NEW_GAME_MUSIC_FADE_DURATION);

		layout();
		bringBlackToFront();
		blackScreen.visible = true;
		blackScreen.alpha = 0;

		introFadeTween = FlxTween.tween(blackScreen, {alpha: 1}, NEW_GAME_FADE_TO_BLACK, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				introFadeTween = null;
				hideMenuChrome();
				if (onNewGame != null)
					onNewGame();
			}
		});
	}

	function bringBlackToFront():Void
	{
		remove(blackScreen, false);
		add(blackScreen);
	}

	function hideMenuChrome():Void
	{
		sidebar.visible = false;
		sidebarDivider.visible = false;
		titleOrnament.visible = false;
		titleLine1.visible = false;
		titleLine2.visible = false;
		demoBadge.visible = false;
		demoLabel.visible = false;
		footerText.visible = false;
		clouds.visible = false;

		for (item in menuItems)
		{
			item.hit.visible = false;
			item.text.visible = false;
			item.bg.visible = false;
		}
	}

	function restoreMenuChrome():Void
	{
		sidebar.visible = true;
		sidebarDivider.visible = true;
		titleOrnament.visible = true;
		titleLine1.visible = true;
		titleLine2.visible = true;
		demoBadge.visible = true;
		demoLabel.visible = true;
		footerText.visible = true;
		clouds.visible = true;

		for (item in menuItems)
		{
			item.hit.visible = true;
			item.text.visible = true;
			item.bg.visible = true;
		}
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
		var cardX = w - sidebarW - CARD_MARGIN;
		var cardY = CARD_MARGIN;
		var cardH = Std.int(h - CARD_MARGIN * 2);

		bgImage.setPosition(0, 0);
		bgImage.setGraphicSize(Std.int(w), Std.int(h));
		bgImage.updateHitbox();

		clouds.layout(w, h);
		traffic.layout(w, h);

		sidebarDivider.makeGraphic(1, 1, FlxColor.TRANSPARENT, true);

		var pad = 16;
		var plateW = sidebarW - pad * 2;
		var plateX = cardX + pad;
		var plateY = cardY + pad + 6;
		var titleSize = Std.int(Math.max(16, h / 34));
		var stampSize = Std.int(Math.max(20, h / 19));

		titleLine1.text = "Am I";
		titleLine1.setFormat(null, titleSize, UiSkin.PANEL, "center");
		titleLine1.borderStyle = FlxTextBorderStyle.NONE;
		titleLine1.fieldWidth = plateW;
		titleLine1.wordWrap = false;

		// Setting fieldWidth re-enables word wrap, so switch it off afterwards.
		titleLine2.text = "APPROVED?";
		titleLine2.fieldWidth = plateW;
		titleLine2.wordWrap = false;
		do
		{
			titleLine2.setFormat(null, stampSize, UiSkin.STAMP_RED, "center");
			titleLine2.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF7A1E18, 1);
			stampSize--;
		}
		while (titleLine2.textField.textWidth > plateW - 14 && stampSize > 12);

		var plateH = Std.int(titleLine1.height + titleLine2.height + 22);
		UiSkin.panel(titleOrnament, plateW, plateH, UiSkin.CREAM, UiSkin.TRIM_DARK, 5, 3, 3);
		titleOrnament.setPosition(plateX, plateY);
		titleOrnament.updateHitbox();
		titlePlateBaseY = plateY;

		titleLine1BaseY = plateY + 8;
		titleLine1.setPosition(plateX, titleLine1BaseY);
		titleLine2BaseY = titleLine1BaseY + titleLine1.height - 2;
		titleLine2.setPosition(plateX, titleLine2BaseY);
		titleLine2.angle = titleStampBaseAngle;

		// Gold tag pinned over the plate's top-right corner.
		UiSkin.panel(demoBadge, DEMO_BADGE_W, DEMO_BADGE_H, Juice.GOLD, UiSkin.INK, 3, 2, 2);
		demoBadge.updateHitbox();
		demoBadge.angle = DEMO_BADGE_ANGLE;
		demoBadge.x = plateX + plateW - DEMO_BADGE_W + 12;
		demoBadgeBaseY = plateY - 13;
		demoBadge.y = demoBadgeBaseY;
		demoLabel.setFormat(null, 14, UiSkin.INK, "center");
		demoLabel.fieldWidth = DEMO_BADGE_W;
		demoLabel.wordWrap = false;
		demoLabel.angle = DEMO_BADGE_ANGLE;
		demoLabel.x = demoBadge.x;
		demoLabelBaseY = demoBadgeBaseY + (DEMO_BADGE_H - demoLabel.height) * 0.5;
		demoLabel.y = demoLabelBaseY;

		var itemSize = Std.int(Math.max(15, h / 36));
		var itemH = itemSize + 20;
		var itemGap = 10;
		var itemW = plateW;
		var menuStartY = plateY + plateH + 28;
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var y = menuStartY + i * (itemH + itemGap);
			item.hit.setPosition(plateX, y);
			item.hit.makeGraphic(itemW, itemH, 0x00000000, true);
			item.hit.updateHitbox();

			if (item.enabled)
				UiSkin.panel(item.bg, itemW - UiSkin.SHADOW_OFFSET, itemH - UiSkin.SHADOW_OFFSET, UiSkin.CREAM, UiSkin.INK, 4, 2);
			else
				UiSkin.panel(item.bg, itemW - UiSkin.SHADOW_OFFSET, itemH - UiSkin.SHADOW_OFFSET, UiSkin.BUTTON, UiSkin.PANEL_DEEP, 4, 2);

			item.layoutX = plateX;
			item.layoutY = y;
			item.layoutW = itemW;
			item.layoutH = itemH - UiSkin.SHADOW_OFFSET;
			item.text.text = item.enabled ? item.label : item.label + "  (soon)";
			item.text.setFormat(null, item.enabled ? itemSize : Std.int(itemSize * 0.8), item.enabled ? ITEM_COLOR : ITEM_DISABLED, "center");
			item.text.fieldWidth = itemW;
			item.text.origin.set(0, 0);
			cancelItemHoverTween(item);
			item.text.scale.set(1, 1);
			syncItemScalePosition(item);
		}

		footerText.text = "CoolMath Bank  -  Est. 1967\nRepublic of Loria";
		footerText.setFormat(null, 10, UiSkin.STEEL, "center");
		footerText.fieldWidth = plateW;
		footerText.alpha = 0.85;
		var footerY = menuStartY + menuItems.length * (itemH + itemGap) + 14;
		footerText.setPosition(plateX, footerY);

		// Floating navy card with a steel pinstripe, sized to its contents.
		cardH = Std.int(Math.min(cardH, footerY + footerText.height + pad - cardY));
		UiSkin.panel(sidebar, sidebarW, cardH, UiSkin.PANEL, UiSkin.PANEL_DEEP, 8, 3, 5);
		drawFrame(sidebar, 7, 7, sidebarW - 14, cardH - 14, UiSkin.TRIM_DARK);
		sidebar.setPosition(cardX, cardY);
		sidebar.alpha = 0.96;
		sidebar.updateHitbox();

		refreshMenuColors();
	}

	function drawFrame(spr:FlxSprite, x:Int, y:Int, w:Int, h:Int, color:Int):Void
	{
		var bmd = spr.pixels;
		bmd.fillRect(new Rectangle(x + 3, y, w - 6, 1), color);
		bmd.fillRect(new Rectangle(x + 3, y + h - 1, w - 6, 1), color);
		bmd.fillRect(new Rectangle(x, y + 3, 1, h - 6), color);
		bmd.fillRect(new Rectangle(x + w - 1, y + 3, 1, h - 6), color);
		spr.dirty = true;
	}

	function refreshMenuColors():Void
	{
		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var hovered = item.enabled && i == hoveredIndex;
			item.bg.color = hovered ? HOVER_TINT : FlxColor.WHITE;
			if (!item.enabled)
				item.text.color = ITEM_DISABLED;
			else if (hovered)
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
		var x = item.layoutX + item.slideX;
		item.bg.scale.set(s, s);
		item.bg.setPosition(x, item.layoutY);
		item.text.setPosition(x + item.layoutW * (1 - s) * 0.5, item.layoutY + (item.layoutH - item.text.height * s) * 0.5);
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

	function adoptPreloadedAudio():Void
	{
		if (menuMusic == null && preloadedMenuMusic != null)
			menuMusic = preloadedMenuMusic;
		if (trafficAmbient == null && preloadedTrafficAmbient != null)
			trafficAmbient = preloadedTrafficAmbient;
	}

	function startTrafficAmbient():Void
	{
		adoptPreloadedAudio();

		if (trafficAmbient != null)
		{
			syncTrafficAmbientVolume();
			if (!trafficAmbient.playing)
				trafficAmbient.play(true);
			return;
		}

		trafficAmbient = FlxG.sound.load(TRAFFIC_AMBIENT, GameSettings.sfxVolume, true, null, false, true);
		if (trafficAmbient != null)
			trafficAmbient.persist = true;
	}

	function stopTrafficAmbient():Void
	{
		cancelTrafficAmbientFadeTween();

		if (trafficAmbient == null)
			return;

		trafficAmbient.stop();
	}

	function fadeTrafficAmbientOut(duration:Float):Void
	{
		if (trafficAmbient == null || !trafficAmbient.playing)
			return;

		cancelTrafficAmbientFadeTween();
		trafficAmbientFadeTween = FlxTween.tween(trafficAmbient, {volume: 0}, duration, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				trafficAmbientFadeTween = null;
				stopTrafficAmbient();
			}
		});
	}

	function cancelTrafficAmbientFadeTween():Void
	{
		if (trafficAmbientFadeTween != null)
		{
			trafficAmbientFadeTween.cancel();
			trafficAmbientFadeTween = null;
		}

		if (trafficAmbient != null)
			FlxTween.cancelTweensOf(trafficAmbient);
	}

	function syncTrafficAmbientVolume():Void
	{
		if (trafficAmbient == null)
			return;

		trafficAmbient.volume = GameSettings.sfxVolume;
	}

	function syncMenuAudioVolumes():Void
	{
		syncTrafficAmbientVolume();
		syncMenuMusicVolume();
	}

	function ensureMenuAudio():Void
	{
		if (StudioLogoSplash.blocksWorldInput())
			return;

		startTrafficAmbient();
		startMenuMusic();
		menuAudioPending = !isMenuMusicPlaying();
	}

	function isMenuAudioPlaying():Bool
	{
		var musicOk = menuMusic != null && menuMusic.playing;
		var trafficOk = trafficAmbient != null && trafficAmbient.playing;
		return musicOk && trafficOk;
	}

	function isMenuMusicPlaying():Bool
	{
		return menuMusic != null && menuMusic.playing;
	}

	function startMenuMusic():Void
	{
		adoptPreloadedAudio();

		if (menuMusic != null)
		{
			syncMenuMusicVolume();
			if (!menuMusic.playing)
				menuMusic.play(true);
			return;
		}

		menuMusic = FlxG.sound.load(MENU_MUSIC, menuMusicVolume(), true, null, false, true);

		if (menuMusic != null)
		{
			menuMusic.persist = true;
			menuAudioPending = !isMenuMusicPlaying();
		}
	}

	function stopMenuMusic():Void
	{
		cancelMenuMusicFadeTween();

		if (menuMusic == null)
			return;

		menuMusic.stop();
	}

	function fadeMenuMusicVolume(factor:Float, duration:Float):Void
	{
		adoptPreloadedAudio();
		if (menuMusic == null)
			startMenuMusic();

		if (menuMusic == null)
			return;

		if (!menuMusic.playing)
			menuMusic.play(true);

		cancelMenuMusicFadeTween();
		var targetVol = MusicVolume.menuVolume(factor);
		if (duration <= 0)
		{
			menuMusic.volume = targetVol;
			musicVolumeMultiplier = factor;
			return;
		}

		menuMusicFadeTween = FlxTween.tween(menuMusic, {volume: targetVol}, duration, {
			ease: FlxEase.sineInOut,
			onComplete: function(_)
			{
				menuMusicFadeTween = null;
				musicVolumeMultiplier = factor;
			}
		});
	}

	function cancelMenuMusicFadeTween():Void
	{
		if (menuMusicFadeTween != null)
		{
			menuMusicFadeTween.cancel();
			menuMusicFadeTween = null;
		}

		if (menuMusic != null)
			FlxTween.cancelTweensOf(menuMusic);
	}

	function cancelNewGameAudioTweens():Void
	{
		cancelTrafficAmbientFadeTween();
		cancelMenuMusicFadeTween();
	}

	function menuMusicVolume():Float
	{
		return MusicVolume.menuVolume(musicVolumeMultiplier);
	}

	function syncMenuMusicVolume():Void
	{
		if (menuMusic == null)
			return;

		menuMusic.volume = menuMusicVolume();
	}
}
