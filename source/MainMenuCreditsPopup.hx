package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

enum MainMenuCreditKind
{
	Title;
	Role;
	Name;
	Blank;
}

typedef MainMenuCreditLine =
{
	kind:MainMenuCreditKind,
	text:String,
}

class MainMenuCreditsPopup extends MainMenuSlidePopup
{
	static inline var PANEL_COLOR = 0xEE120E0A;
	static inline var BORDER_COLOR = 0xFFD4AF6A;
	static inline var TITLE_COLOR = 0xFFE8C878;
	static inline var ROLE_COLOR = 0xFFC9A04A;
	static inline var NAME_COLOR = 0xFFF4E4C4;
	static inline var BTN_BG = 0xFF241C14;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	var panel:FlxSprite;
	var ornamentTop:FlxSprite;
	var ornamentBottom:FlxSprite;
	var titleLabel:FlxText;
	var closeBtn:FlxSprite;
	var closeLabel:FlxText;
	var lineTexts:Array<FlxText> = [];
	var creditLines:Array<MainMenuCreditLine> = [];
	var scrollIndex = 0;
	var contentTop = 0.0;
	var contentBottom = 0.0;
	var contentPad = 16.0;
	var fontSize = 14;
	var popupPad = 18;
	var popupTitleSize = 28;
	var popupCloseBtnW = 0.0;
	var popupCloseBtnH = 0.0;
	var popupCloseBtnX = 0.0;
	var popupCloseBtnY = 0.0;
	var closeHovered = false;
	var closeHoverTween:FlxTween;
	var closeLabelY = 0.0;

	public function new()
	{
		super();

		panel = new FlxSprite();
		ornamentTop = new FlxSprite();
		ornamentBottom = new FlxSprite();
		titleLabel = new FlxText(0, 0, 200, "Credits");
		closeBtn = new FlxSprite();
		closeLabel = new FlxText(0, 0, 80, "Close");

		creditLines = defaultCreditLines();

		slideRoot.add(panel);
		slideRoot.add(ornamentTop);
		slideRoot.add(ornamentBottom);
		slideRoot.add(titleLabel);
		slideRoot.add(closeBtn);
		slideRoot.add(closeLabel);
	}

	override function onBeforeShow():Void
	{
		scrollIndex = 0;
		resetCloseHover();
	}

	override function onClosed():Void
	{
		resetCloseHover();
	}

	public function updateHover():Void
	{
		if (!visible || isAnimating)
			return;

		var p = FlxG.mouse.getViewPosition();
		var nextHover = closeBtn.overlapsPoint(p);
		if (nextHover != closeHovered)
		{
			closeHovered = nextHover;
			refreshCloseButton();
		}

		tweenCloseScale(closeHovered ? HOVER_SCALE : 1);
	}

	public function handleWheel(wheel:Float):Void
	{
		if (!visible || isAnimating || wheel == 0)
			return;

		scrollBy(wheel > 0 ? -1 : 1);
	}

	override function handlePanelClick(p:FlxPoint):Bool
	{
		if (closeBtn.overlapsPoint(p))
		{
			close();
			return true;
		}

		return containsPanelPoint(p);
	}

	function scrollBy(delta:Int):Void
	{
		var old = scrollIndex;
		scrollIndex += delta;
		scrollIndex = Std.int(FlxMath.bound(scrollIndex, 0, maxScrollIndex()));
		if (scrollIndex != old)
			refreshLines();
	}

	function maxScrollIndex():Int
	{
		var viewportH = contentBottom - contentTop;
		var totalH = 0.0;
		for (entry in creditLines)
			totalH += entryHeight(entry);

		if (totalH <= viewportH)
			return 0;

		var scroll = 0;
		for (start in 0...creditLines.length)
		{
			var h = heightFromIndex(start);
			if (h <= viewportH + 0.5)
				return start;
			scroll = start;
		}
		return scroll;
	}

	function heightFromIndex(start:Int):Float
	{
		var h = 0.0;
		for (i in start...creditLines.length)
			h += entryHeight(creditLines[i]);
		return h;
	}

	override function layoutPopup():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		fontSize = Std.int(Math.max(13, h / 42));
		popupTitleSize = Std.int(Math.max(28, h / 18));
		popupPad = Std.int(Math.max(18, w * 0.03));
		panelW = Std.int(Math.min(w - 40, 520));
		panelH = Std.int(Math.min(h - 40, 520));
		restX = (w - panelW) * 0.5;
		restY = (h - panelH) * 0.5;

		panel.makeGraphic(Std.int(panelW), Std.int(panelH), PANEL_COLOR, true);
		drawBorder(panel, Std.int(panelW), Std.int(panelH), BORDER_COLOR, 2);
		panel.updateHitbox();

		drawOrnament(ornamentTop, 0, 0, panelW - popupPad * 2);
		drawOrnament(ornamentBottom, 0, 0, panelW - popupPad * 2);

		titleLabel.text = "Credits";
		titleLabel.setFormat(null, popupTitleSize, TITLE_COLOR, "center");
		titleLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupTitleSize / 12));
		titleLabel.fieldWidth = Std.int(panelW - popupPad * 2);

		contentTop = popupPad + popupTitleSize + 20;

		popupCloseBtnH = fontSize + 12;
		popupCloseBtnW = Std.int(Math.max(110, panelW * 0.32));
		popupCloseBtnX = (panelW - popupCloseBtnW) * 0.5;
		popupCloseBtnY = panelH - popupPad - popupCloseBtnH - 14;

		contentBottom = popupCloseBtnY - 10;

		closeLabelY = popupCloseBtnY + (popupCloseBtnH - fontSize) * 0.5;
		closeLabel.text = "Close";
		closeLabel.setFormat(null, fontSize, NAME_COLOR, "center");
		closeLabel.fieldWidth = popupCloseBtnW;
		closeLabel.origin.set(0, 0);
		cancelCloseHoverTween();
		closeLabel.scale.set(1, 1);
		refreshCloseButton();

		refreshLines();
		syncPopupLayout();
	}

	override function syncPopupLayout():Void
	{
		panel.setPosition(panelX(0), panelY(0));
		ornamentTop.setPosition(panelX(popupPad), panelY(popupPad - 2));
		ornamentBottom.setPosition(panelX(popupPad), panelY(panelH - popupPad - 8));
		titleLabel.setPosition(panelX(popupPad), panelY(popupPad + 4));
		closeBtn.setPosition(panelX(popupCloseBtnX), panelY(popupCloseBtnY));
		syncCloseLabelPosition();
		syncLinePositions();
	}

	function refreshCloseButton():Void
	{
		closeLabel.color = closeHovered ? TITLE_COLOR : NAME_COLOR;
		closeBtn.makeGraphic(Std.int(popupCloseBtnW), Std.int(popupCloseBtnH), BTN_BG, true);
		drawBorder(closeBtn, Std.int(popupCloseBtnW), Std.int(popupCloseBtnH), closeHovered ? TITLE_COLOR : BORDER_COLOR,
			closeHovered ? 2 : 1);
		closeBtn.updateHitbox();
		closeBtn.setPosition(panelX(popupCloseBtnX), panelY(popupCloseBtnY));
		syncCloseLabelPosition();
	}

	function tweenCloseScale(targetScale:Float):Void
	{
		if (Math.abs(closeLabel.scale.x - targetScale) <= 0.01)
			return;

		cancelCloseHoverTween();
		closeHoverTween = FlxTween.tween(closeLabel.scale, {x: targetScale, y: targetScale}, HOVER_TWEEN_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				syncCloseLabelPosition();
			},
			onComplete: function(_)
			{
				syncCloseLabelPosition();
			}
		});
	}

	function syncCloseLabelPosition():Void
	{
		var s = closeLabel.scale.x;
		closeLabel.setPosition(closeBtn.x + popupCloseBtnW * (1 - s) * 0.5, panelY(closeLabelY));
	}

	function cancelCloseHoverTween():Void
	{
		if (closeHoverTween != null)
		{
			closeHoverTween.cancel();
			closeHoverTween = null;
		}

		FlxTween.cancelTweensOf(closeLabel.scale);
	}

	function resetCloseHover():Void
	{
		closeHovered = false;
		cancelCloseHoverTween();
		closeLabel.scale.set(1, 1);
		if (visible)
			refreshCloseButton();
	}

	function syncLinePositions():Void
	{
		var textW = Std.int(panel.width - contentPad * 2);
		var drawY = contentTop;
		var slot = 0;

		for (i in scrollIndex...creditLines.length)
		{
			var entry = creditLines[i];
			var lh = entryHeight(entry);
			if (drawY + lh > contentBottom && slot > 0)
				break;

			if (entry.kind != Blank)
			{
				var t = lineTexts[slot];
				t.setPosition(panelX(contentPad), panelY(drawY));
				slot++;
			}

			drawY += lh;
		}
	}

	function refreshLines():Void
	{
		var textW = Std.int(panel.width - contentPad * 2);
		var drawY = contentTop;
		var slot = 0;

		for (i in scrollIndex...creditLines.length)
		{
			var entry = creditLines[i];
			var lh = entryHeight(entry);
			if (drawY + lh > contentBottom && slot > 0)
				break;

			if (entry.kind != Blank)
			{
				var t = ensureLineText(slot);
				t.text = entry.text;
				t.setFormat(null, entryTextSize(entry), entryColor(entry), "center");
				t.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(24, 16, 10), 1);
				t.fieldWidth = textW;
				t.visible = true;
				slot++;
			}

			drawY += lh;
		}

		for (i in slot...lineTexts.length)
			lineTexts[i].visible = false;

		syncLinePositions();
	}

	function ensureLineText(slot:Int):FlxText
	{
		while (lineTexts.length <= slot)
		{
			var t = new FlxText(0, 0, 100, "");
			lineTexts.push(t);
			slideRoot.add(t);
		}
		return lineTexts[slot];
	}

	function entryHeight(entry:MainMenuCreditLine):Float
	{
		return switch (entry.kind)
		{
			case Title: fontSize + 10;
			case Role: fontSize + 6;
			case Name: fontSize + 4;
			case Blank: Math.max(8, fontSize * 0.5);
		}
	}

	function entryTextSize(entry:MainMenuCreditLine):Int
	{
		return switch (entry.kind)
		{
			case Title: fontSize + 6;
			case Role: fontSize + 1;
			case Name: fontSize;
			case Blank: fontSize;
		}
	}

	function entryColor(entry:MainMenuCreditLine):Int
	{
		return switch (entry.kind)
		{
			case Title: TITLE_COLOR;
			case Role: ROLE_COLOR;
			case Name: NAME_COLOR;
			case Blank: NAME_COLOR;
		}
	}

	function drawOrnament(sprite:FlxSprite, x:Float, y:Float, w:Float):Void
	{
		var iw = Std.int(Math.max(1, w));
		sprite.setPosition(x, y);
		sprite.makeGraphic(iw, 6, 0x00000000, true);
		sprite.pixels.fillRect(new Rectangle(0, 2, iw, 2), BORDER_COLOR);
		sprite.pixels.fillRect(new Rectangle(Std.int(iw * 0.5) - 2, 0, 4, 6), TITLE_COLOR);
		sprite.dirty = true;
		sprite.updateHitbox();
	}

	static function defaultCreditLines():Array<MainMenuCreditLine>
	{
		return [
			{kind: Title, text: "CoolMath Bank"},
			{kind: Blank, text: ""},
			{kind: Role, text: "GameDesigner / Programmer"},
			{kind: Name, text: "Viktar Syanau (MarySue)"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Artist"},
			{kind: Name, text: "Anush Kalivanjyan"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Composer / Audio Effects"},
			{kind: Name, text: "Bohdan Potomskyi (retipupu)"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Scenarist"},
			{kind: Name, text: "Serik - Al Farabiuly Yerasyl"},
			{kind: Blank, text: ""},
			{kind: Blank, text: ""},
			{kind: Role, text: "Special Thanks to"},
			{kind: Name, text: "Valeria Paziuk"},
			{kind: Name, text: "Vadzim Trayeuski (HonieHomie)"},
			{kind: Name, text: "Muhammad Bakanaev (Senshi)"},
			{kind: Name, text: "Muzafar Bektas (horseatersson)"},
			{kind: Blank, text: ""},
			{kind: Role, text: "Sounds"},
			{kind: Name, text: "freesound.org"}
		];
	}
}
