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

class MainMenuOptionsPopup extends MainMenuSlidePopup
{
	static inline var PANEL_COLOR = 0xEE1A1410;
	static inline var BORDER_COLOR = 0xFFD4AF6A;
	static inline var LABEL_COLOR = 0xFFF4E4C4;
	static inline var VALUE_COLOR = 0xFFE8C878;
	static inline var SLIDER_TRACK = 0xFF3A3028;
	static inline var SLIDER_FILL = 0xFFC9A04A;
	static inline var BTN_BG = 0xFF2A2218;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	var panel:FlxSprite;
	var titleLabel:FlxText;
	var closeBtn:FlxSprite;
	var closeLabel:FlxText;
	var fullscreenLabel:FlxText;
	var fullscreenBtn:FlxSprite;
	var fullscreenBtnLabel:FlxText;
	var lineLabels:Array<FlxText> = [];
	var lineValues:Array<FlxText> = [];
	var sliderTracks:Array<FlxSprite> = [];
	var sliderFills:Array<FlxSprite> = [];
	var sliderHits:Array<FlxSprite> = [];
	var draggingSlider = -1;
	var popupPad = 16;
	var popupFontSize = 14;
	var popupTitleSize = 24;
	var popupLabelW = 0.0;
	var popupRowH = 0.0;
	var popupSliderH = 14;
	var popupValueW = 56;
	var popupSliderHitPad = 8;
	var popupRowStartY = 0.0;
	var popupToggleBtnW = 72;
	var popupToggleBtnH = 0;
	var popupToggleY = 0.0;
	var popupCloseBtnW = 0;
	var popupCloseBtnH = 0;
	var popupCloseBtnX = 0.0;
	var popupCloseBtnY = 0.0;
	var closeHovered = false;
	var closeHoverTween:FlxTween;
	var closeLabelY = 0.0;

	public function new()
	{
		super();

		panel = new FlxSprite();
		titleLabel = new FlxText(0, 0, 200, "Options");
		closeBtn = new FlxSprite();
		closeLabel = new FlxText(0, 0, 80, "Close");
		fullscreenLabel = new FlxText(0, 0, 120, "Fullscreen");
		fullscreenBtn = new FlxSprite();
		fullscreenBtnLabel = new FlxText(0, 0, 80, "Off");

		slideRoot.add(panel);
		slideRoot.add(titleLabel);
		slideRoot.add(closeBtn);
		slideRoot.add(closeLabel);
		slideRoot.add(fullscreenLabel);
		slideRoot.add(fullscreenBtn);
		slideRoot.add(fullscreenBtnLabel);

		addSlider("Master Volume", function() return GameSettings.masterVolume, function(v) GameSettings.masterVolume = v);
		addSlider("Music Volume", function() return GameSettings.musicVolume, function(v) GameSettings.musicVolume = v);
		addSlider("SFX Volume", function() return GameSettings.sfxVolume, function(v) GameSettings.sfxVolume = v);
	}

	override function onBeforeShow():Void
	{
		resetCloseHover();
		refreshValues();
		refreshSliderFills();
	}

	override function onClosed():Void
	{
		draggingSlider = -1;
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

	override function handlePanelClick(p:FlxPoint):Bool
	{
		if (closeBtn.overlapsPoint(p))
		{
			close();
			return true;
		}

		if (fullscreenBtn.overlapsPoint(p))
		{
			GameSettings.toggleFullscreen();
			refreshFullscreenButton();
			return true;
		}

		for (i in 0...sliderHits.length)
		{
			if (sliderHits[i].overlapsPoint(p))
			{
				setSliderValue(i, (p.x - sliderHits[i].x) / sliderHits[i].width);
				draggingSlider = i;
				return true;
			}
		}

		return containsPanelPoint(p);
	}

	public function updateDrag(p:FlxPoint):Void
	{
		if (!visible || isAnimating || draggingSlider < 0)
			return;

		var hit = sliderHits[draggingSlider];
		setSliderValue(draggingSlider, (p.x - hit.x) / hit.width);
	}

	public function endDrag():Void
	{
		draggingSlider = -1;
	}

	function addSlider(label:String, getter:Void->Float, setter:Float->Void):Void
	{
		var labelText = new FlxText(0, 0, 100, label);
		var valueText = new FlxText(0, 0, 40, "");
		var track = new FlxSprite();
		var fill = new FlxSprite();
		var hit = new FlxSprite();

		lineLabels.push(labelText);
		lineValues.push(valueText);
		sliderTracks.push(track);
		sliderFills.push(fill);
		sliderHits.push(hit);

		slideRoot.add(labelText);
		slideRoot.add(track);
		slideRoot.add(fill);
		slideRoot.add(valueText);
		slideRoot.add(hit);
	}

	function setSliderValue(index:Int, ratio:Float):Void
	{
		ratio = FlxMath.bound(ratio, 0, 1);

		switch (index)
		{
			case 0:
				GameSettings.masterVolume = ratio;
			case 1:
				GameSettings.musicVolume = ratio;
			case 2:
				GameSettings.sfxVolume = ratio;
		}

		refreshValues();
		refreshSliderFills();
	}

	override function layoutPopup():Void
	{
		var w = FlxG.width;
		var h = FlxG.height;
		popupFontSize = Std.int(Math.max(14, h / 38));
		popupTitleSize = Std.int(Math.max(24, h / 22));
		popupPad = Std.int(Math.max(16, w * 0.03));
		panelW = Std.int(Math.min(w - 48, 460));
		panelH = Std.int(Math.min(h - 48, 380));
		restX = (w - panelW) * 0.5;
		restY = (h - panelH) * 0.5;

		panel.makeGraphic(Std.int(panelW), Std.int(panelH), PANEL_COLOR, true);
		drawBorder(panel, Std.int(panelW), Std.int(panelH), BORDER_COLOR, 2);
		panel.updateHitbox();

		titleLabel.text = "Options";
		titleLabel.setFormat(null, popupTitleSize, VALUE_COLOR, "center");
		titleLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(40, 28, 16), Math.max(1, popupTitleSize / 14));
		titleLabel.fieldWidth = Std.int(panelW - popupPad * 2);

		popupRowStartY = popupPad + popupTitleSize + 18;
		popupRowH = popupFontSize + 32;
		popupLabelW = panelW - popupPad * 2;
		popupSliderH = Std.int(Math.max(14, popupFontSize * 0.55));
		popupValueW = Std.int(Math.max(56, popupFontSize * 2.6));
		popupSliderHitPad = Std.int(Math.max(8, popupSliderH * 0.5));

		var rowY = popupRowStartY;
		var sliderW = popupLabelW - popupValueW;

		for (i in 0...lineLabels.length)
		{
			var label = lineLabels[i];
			var value = lineValues[i];
			var track = sliderTracks[i];
			var fill = sliderFills[i];
			var hit = sliderHits[i];

			label.setFormat(null, popupFontSize, LABEL_COLOR, "left");
			label.text = label.text;
			label.fieldWidth = Std.int(popupLabelW - popupValueW);
			label.visible = true;

			var sliderY = rowY + popupFontSize + 8;
			track.makeGraphic(Std.int(sliderW), popupSliderH, SLIDER_TRACK, true);
			drawBorder(track, Std.int(sliderW), popupSliderH, 0xFF5A4A38, 1);
			track.updateHitbox();

			fill.makeGraphic(1, popupSliderH, SLIDER_FILL, true);
			fill.updateHitbox();

			hit.makeGraphic(Std.int(sliderW), popupSliderH + popupSliderHitPad * 2, 0x00000000, true);
			hit.updateHitbox();

			value.setFormat(null, popupFontSize - 1, VALUE_COLOR, "right");
			value.wordWrap = false;
			value.autoSize = false;
			value.fieldWidth = popupValueW;

			rowY += popupRowH;
		}

		popupToggleBtnW = Std.int(Math.max(72, panelW * 0.18));
		popupToggleBtnH = popupFontSize + 10;
		popupToggleY = rowY + 6;
		fullscreenLabel.setFormat(null, popupFontSize, LABEL_COLOR, "left");
		fullscreenLabel.fieldWidth = Std.int(popupLabelW - popupToggleBtnW - 8);

		popupCloseBtnH = popupFontSize + 12;
		popupCloseBtnW = Std.int(Math.max(100, panelW * 0.34));
		popupCloseBtnX = (panelW - popupCloseBtnW) * 0.5;
		popupCloseBtnY = panelH - popupPad - popupCloseBtnH;

		closeLabelY = popupCloseBtnY + (popupCloseBtnH - popupFontSize) * 0.5;
		closeLabel.text = "Close";
		closeLabel.setFormat(null, popupFontSize, LABEL_COLOR, "center");
		closeLabel.fieldWidth = popupCloseBtnW;
		closeLabel.origin.set(0, 0);
		cancelCloseHoverTween();
		closeLabel.scale.set(1, 1);
		refreshCloseButton();

		layoutToggleButton(popupToggleBtnW, popupToggleBtnH, popupFontSize);
		refreshValues();
		refreshSliderFills();
		syncPopupLayout();
	}

	override function syncPopupLayout():Void
	{
		panel.setPosition(panelX(0), panelY(0));
		titleLabel.setPosition(panelX(popupPad), panelY(popupPad));

		var rowY = popupRowStartY;
		var sliderW = popupLabelW - popupValueW;

		for (i in 0...lineLabels.length)
		{
			var label = lineLabels[i];
			var value = lineValues[i];
			var track = sliderTracks[i];
			var fill = sliderFills[i];
			var hit = sliderHits[i];
			var sliderY = rowY + popupFontSize + 8;

			label.setPosition(panelX(popupPad), panelY(rowY));
			track.setPosition(panelX(popupPad), panelY(sliderY));
			fill.setPosition(track.x, track.y);
			hit.setPosition(panelX(popupPad), panelY(sliderY - popupSliderHitPad));
			value.setPosition(panelX(popupPad + sliderW + 8), panelY(sliderY + (popupSliderH - (popupFontSize - 1)) * 0.5));

			rowY += popupRowH;
		}

		var toggleBtnX = popupPad + popupLabelW - popupToggleBtnW;
		fullscreenLabel.setPosition(panelX(popupPad), panelY(popupToggleY + (popupToggleBtnH - popupFontSize) * 0.5));
		fullscreenBtn.setPosition(panelX(toggleBtnX), panelY(popupToggleY));
		fullscreenBtnLabel.setPosition(fullscreenBtn.x, fullscreenBtn.y + (popupToggleBtnH - (popupFontSize - 1)) * 0.5);

		closeBtn.setPosition(panelX(popupCloseBtnX), panelY(popupCloseBtnY));
		syncCloseLabelPosition();
	}

	function refreshCloseButton():Void
	{
		closeLabel.color = closeHovered ? VALUE_COLOR : LABEL_COLOR;
		closeBtn.makeGraphic(Std.int(popupCloseBtnW), Std.int(popupCloseBtnH), BTN_BG, true);
		drawBorder(closeBtn, Std.int(popupCloseBtnW), Std.int(popupCloseBtnH), closeHovered ? VALUE_COLOR : BORDER_COLOR,
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

	function layoutToggleButton(btnW:Int, btnH:Int, fontSize:Int):Void
	{
		var on = FlxG.fullscreen;
		var bg = on ? 0xFF3A3020 : 0xFF2A2218;
		var border = on ? VALUE_COLOR : BORDER_COLOR;

		fullscreenBtn.makeGraphic(btnW, btnH, bg, true);
		drawBorder(fullscreenBtn, btnW, btnH, border, 1);
		fullscreenBtn.updateHitbox();

		fullscreenBtnLabel.text = on ? "On" : "Off";
		fullscreenBtnLabel.setFormat(null, fontSize - 1, on ? VALUE_COLOR : LABEL_COLOR, "center");
		fullscreenBtnLabel.fieldWidth = btnW;
		fullscreenBtnLabel.setPosition(fullscreenBtn.x, fullscreenBtn.y + (btnH - (fontSize - 1)) * 0.5);
	}

	function refreshFullscreenButton():Void
	{
		if (!visible)
			return;

		var fontSize = fullscreenBtnLabel.size;
		layoutToggleButton(Std.int(fullscreenBtn.width), Std.int(fullscreenBtn.height), fontSize + 1);
	}

	function refreshValues():Void
	{
		if (lineValues.length < 3)
			return;

		lineValues[0].text = pct(GameSettings.masterVolume);
		lineValues[1].text = pct(GameSettings.musicVolume);
		lineValues[2].text = pct(GameSettings.sfxVolume);
	}

	function refreshSliderFills():Void
	{
		var values = [
			GameSettings.masterVolume,
			GameSettings.musicVolume,
			GameSettings.sfxVolume
		];

		for (i in 0...sliderFills.length)
		{
			var track = sliderTracks[i];
			var fill = sliderFills[i];
			var fillW = Std.int(Math.max(1, track.width * values[i]));
			fill.makeGraphic(fillW, Std.int(track.height), SLIDER_FILL, true);
			fill.setPosition(track.x, track.y);
			fill.updateHitbox();
		}
	}

	function pct(v:Float):String
	{
		return Std.string(Std.int(Math.round(v * 100))) + "%";
	}
}
