package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class TutorialGuideOverlay extends FlxGroup
{
	static inline var PULSE_SPEED = 2.2;
	static inline var SPOTLIGHT_BOB_SPEED = 1.1;
	static inline var SPOTLIGHT_BOB_AMPLITUDE = 7.0;
	static inline var HIGHLIGHT_PAD = 4.0;
	static inline var HIGHLIGHT_BORDER = 3;
	static inline var BADGE_PAD = 10;
	static inline var BADGE_GAP = 8;
	static inline var CONTINUE_LABEL = "Got it";
	static inline var DIM_ALPHA = 155;

	static inline var HIGHLIGHT_BASE = 0xFF66FF99;
	static inline var BADGE_FILL = 0xF0141C24;
	static inline var BADGE_BORDER = 0xFFD4AF6A;
	static inline var TEXT_PRIMARY = 0xFFF4E4C4;
	static inline var TEXT_ACCENT = 0xFFE8C878;
	static inline var TEXT_BODY = 0xFFDCE6E0;
	static inline var BTN_FILL = 0xFF1A3824;
	static inline var BTN_BORDER = 0xFF50A060;
	static inline var BTN_TEXT = 0xFFB4D28C;
	static inline var ARROW_PATH = "static/arrow_right.png";
	static inline var ARROW_SIZE = 28;
	static inline var SCREEN_BOTTOM_MARGIN = 12;
	static inline var SCREEN_TOP_MARGIN = 12;
	static inline var SLIDE_DURATION = 0.28;

	var dimBg:FlxSprite;
	var arrowSprite:FlxSprite;
	var highlightTop:FlxSprite;
	var highlightBottom:FlxSprite;
	var highlightLeft:FlxSprite;
	var highlightRight:FlxSprite;
	var labelBadgeBg:FlxSprite;
	var titleLabel:FlxText;
	var speakerText:FlxText;
	var bodyText:FlxText;
	var continueHit:FlxSprite;
	var continueLabel:FlxText;

	var anchorX = 0.0;
	var anchorY = 0.0;
	var anchorW = 0.0;
	var anchorH = 0.0;
	var pulseTimer = 0.0;
	var highlightRect:Null<TutorialGuideRect> = null;
	var waitingForContinue = false;
	var onContinue:Null<Void->Void> = null;
	var spotlightMode = false;
	var compactTitle = false;
	var pinToScreenBottom = false;
	var pinToScreenTop = false;
	var pinToScreenAboveAnchor = false;
	var hideOnComplete:Null<Void->Void> = null;
	var arrowBaseX = 0.0;
	var arrowBaseY = 0.0;
	var titleBaseY = 0.0;
	var badgeBaseY = 0.0;
	var spotlightBobTimer = 0.0;
	var badgeRestX = 0.0;
	var badgeRestY = 0.0;
	var badgeW = 0;
	var slideDeltaX = 0.0;
	var slideTween:FlxTween;
	var slideBusy = false;
	var pendingShow:Null<{message:String, highlight:Null<TutorialGuideRect>, needsContinue:Bool,
		continueAction:Null<Void->Void>, pinBottom:Bool, pinTop:Bool, pinAboveAnchor:Bool, spotlight:Bool,
		title:String, animate:Bool}>;
	var currentCoachKey = "";
	public var isShowing(default, null) = false;

	public function new()
	{
		super();

		dimBg = new FlxSprite();
		dimBg.scrollFactor.set(0, 0);
		add(dimBg);

		highlightTop = makeHighlightBar();
		highlightBottom = makeHighlightBar();
		highlightLeft = makeHighlightBar();
		highlightRight = makeHighlightBar();
		add(highlightTop);
		add(highlightBottom);
		add(highlightLeft);
		add(highlightRight);

		labelBadgeBg = new FlxSprite();
		labelBadgeBg.scrollFactor.set(0, 0);
		labelBadgeBg.visible = false;
		add(labelBadgeBg);

		titleLabel = makeText("", 19, TEXT_PRIMARY, "center");
		titleLabel.visible = false;
		add(titleLabel);

		speakerText = makeText("Chef", 14, TEXT_ACCENT, "left");
		speakerText.visible = false;
		add(speakerText);

		bodyText = makeText("", 14, TEXT_BODY, "left");
		bodyText.wordWrap = true;
		bodyText.visible = false;
		add(bodyText);

		continueHit = new FlxSprite();
		continueHit.scrollFactor.set(0, 0);
		continueLabel = makeText(CONTINUE_LABEL, 13, BTN_TEXT, "center");
		add(continueHit);
		add(continueLabel);

		arrowSprite = new FlxSprite();
		arrowSprite.scrollFactor.set(0, 0);
		arrowSprite.visible = false;
		add(arrowSprite);

		finishHide();
	}

	function makeHighlightBar():FlxSprite
	{
		var bar = new FlxSprite();
		bar.scrollFactor.set(0, 0);
		bar.makeGraphic(1, 1, HIGHLIGHT_BASE, true);
		return bar;
	}

	function makeText(text:String, size:Int, color:Int, align:String):FlxText
	{
		var label = new FlxText(0, 0, 100, text);
		label.setFormat(null, size, color, align);
		label.scrollFactor.set(0, 0);
		return label;
	}

	public function setAnchor(x:Float, y:Float, w:Float, h:Float):Void
	{
		anchorX = x;
		anchorY = y;
		anchorW = w;
		anchorH = h;
		if (isShowing)
			layout();
	}

	public function isBusy():Bool
	{
		return slideBusy;
	}

	public function getHighlightRect():Null<TutorialGuideRect>
	{
		return highlightRect;
	}

	public function isPointOnContinue(px:Float, py:Float):Bool
	{
		return waitingForContinue && continueHit.visible && continueHit.overlapsPoint(new flixel.math.FlxPoint(px, py));
	}

	public function isPointOnOverlay(px:Float, py:Float):Bool
	{
		if (!isShowing)
			return false;

		var point = new flixel.math.FlxPoint(px, py);
		if (labelBadgeBg.visible && labelBadgeBg.overlapsPoint(point))
			return true;
		if (waitingForContinue && continueHit.visible && continueHit.overlapsPoint(point))
			return true;
		return false;
	}

	public function isPointInHighlight(px:Float, py:Float):Bool
	{
		if (highlightRect == null)
			return false;
		var h = highlightRect;
		return px >= h.x && px < h.x + h.w && py >= h.y && py < h.y + h.h;
	}

	public function showSpotlight(highlight:TutorialGuideRect, title:String):Void
	{
		queueShow({
			message: "",
			highlight: highlight,
			needsContinue: false,
			continueAction: null,
			pinBottom: false,
			pinTop: false,
			pinAboveAnchor: false,
			spotlight: true,
			title: title,
			animate: true
		});
	}

	public function showCoach(message:String, ?highlight:TutorialGuideRect, ?needsContinue:Bool = true,
			?continueAction:Void->Void, ?pinBottom:Bool = false, ?animate:Bool = true, ?pinTop:Bool = false,
			?pinAboveAnchor:Bool = false):Void
	{
		queueShow({
			message: message,
			highlight: highlight,
			needsContinue: needsContinue,
			continueAction: continueAction,
			pinBottom: pinBottom,
			pinTop: pinTop,
			pinAboveAnchor: pinAboveAnchor,
			spotlight: false,
			title: "",
			animate: animate
		});
	}

	function queueShow(spec:{message:String, highlight:Null<TutorialGuideRect>, needsContinue:Bool,
		continueAction:Null<Void->Void>, pinBottom:Bool, pinTop:Bool, pinAboveAnchor:Bool, spotlight:Bool,
		title:String, animate:Bool}):Void
	{
		var key = coachKey(spec);
		if (isShowing && !slideBusy && key == currentCoachKey)
			return;

		if (slideBusy)
		{
			pendingShow = spec;
			return;
		}

		var shouldAnimate = spec.animate;

		if (isShowing)
		{
			if (!shouldAnimate)
			{
				applyShow(spec);
				return;
			}

			slideOut(function()
			{
				applyShow(spec);
				slideIn();
			});
			return;
		}

		applyShow(spec);
		if (shouldAnimate)
			slideIn();
	}

	function coachKey(spec:{message:String, highlight:Null<TutorialGuideRect>, needsContinue:Bool,
		continueAction:Null<Void->Void>, pinBottom:Bool, pinTop:Bool, pinAboveAnchor:Bool, spotlight:Bool,
		title:String, animate:Bool}):String
	{
		if (spec.spotlight)
			return 'spotlight:${spec.title}:${spec.highlight != null}';
		return '${spec.message}:${spec.needsContinue}:${spec.pinBottom}:${spec.pinTop}:${spec.pinAboveAnchor}:${spec.highlight != null}';
	}

	function applyShow(spec:{message:String, highlight:Null<TutorialGuideRect>, needsContinue:Bool,
		continueAction:Null<Void->Void>, pinBottom:Bool, pinTop:Bool, pinAboveAnchor:Bool, spotlight:Bool,
		title:String, animate:Bool}):Void
	{
		currentCoachKey = coachKey(spec);
		isShowing = true;
		visible = true;
		spotlightMode = spec.spotlight;
		pinToScreenBottom = spec.pinBottom;
		pinToScreenTop = spec.pinTop;
		pinToScreenAboveAnchor = spec.pinAboveAnchor;
		compactTitle = spec.spotlight;
		spotlightBobTimer = 0;
		highlightRect = spec.highlight;
		waitingForContinue = spec.needsContinue;
		onContinue = spec.continueAction;

		if (spec.spotlight)
		{
			titleLabel.text = spec.title;
			titleLabel.visible = true;
			speakerText.visible = false;
			bodyText.visible = false;
			bodyText.text = "";
		}
		else
		{
			bodyText.text = spec.message;
			titleLabel.visible = false;
			speakerText.visible = spec.message.length > 0;
			bodyText.visible = spec.message.length > 0;
		}

		continueHit.visible = spec.needsContinue;
		continueLabel.visible = spec.needsContinue;
		layout();
	}

	public function refreshHighlight(?highlight:TutorialGuideRect):Void
	{
		if (!isShowing || slideBusy)
			return;
		if (highlight != null)
			highlightRect = highlight;
		layout();
	}

	public function hide(?animate:Bool = true, ?onComplete:Null<Void->Void> = null):Void
	{
		if (!isShowing && !slideBusy)
		{
			if (onComplete != null)
				onComplete();
			return;
		}

		if (slideBusy)
		{
			if (animate)
				return;
			cancelSlideTween();
			slideBusy = false;
			slideDeltaX = 0;
		}

		hideOnComplete = onComplete;

		if (!animate)
		{
			pendingShow = null;
			finishHide();
			return;
		}

		if (!isShowing)
		{
			finishHide();
			return;
		}

		slideOut(function()
		{
			finishHide();
		});
	}

	function finishHide():Void
	{
		isShowing = false;
		visible = false;
		spotlightMode = false;
		pinToScreenBottom = false;
		pinToScreenTop = false;
		pinToScreenAboveAnchor = false;
		compactTitle = false;
		highlightRect = null;
		waitingForContinue = false;
		onContinue = null;
		dimBg.visible = false;
		setHighlightVisible(false);
		labelBadgeBg.visible = false;
		titleLabel.visible = false;
		speakerText.visible = false;
		bodyText.visible = false;
		continueHit.visible = false;
		continueLabel.visible = false;
		arrowSprite.visible = false;
		slideDeltaX = 0;
		slideBusy = false;
		currentCoachKey = "";
		var cb = hideOnComplete;
		hideOnComplete = null;
		var next = pendingShow;
		pendingShow = null;

		if (cb != null)
			cb();
		else if (next != null)
			queueShow(next);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!isShowing)
			return;

		pulseTimer += elapsed * PULSE_SPEED;
		var pulse = 0.65 + 0.35 * Math.sin(pulseTimer * Math.PI * 2);
		var g = Std.int(102 + 54 * pulse);
		var color = FlxColor.fromRGB(g, 255, Std.int(153 + 40 * pulse), 255);
		for (bar in [highlightTop, highlightBottom, highlightLeft, highlightRight])
		{
			if (bar.visible)
				bar.color = color;
		}

		if (spotlightMode)
		{
			spotlightBobTimer += elapsed * SPOTLIGHT_BOB_SPEED;
			var bob = Math.sin(spotlightBobTimer * Math.PI * 2);
			if (arrowSprite.visible)
			{
				arrowSprite.y = arrowBaseY + bob * SPOTLIGHT_BOB_AMPLITUDE;
				arrowSprite.alpha = 0.75 + 0.25 * (0.5 + 0.5 * bob);
			}
			if (labelBadgeBg.visible)
			{
				labelBadgeBg.y = badgeBaseY + bob * 1.5;
				if (titleLabel.visible)
					titleLabel.y = titleBaseY + bob * 1.5;
			}
		}

		if (waitingForContinue && !slideBusy && FlxG.mouse.justPressed && isPointOnContinue(FlxG.mouse.x, FlxG.mouse.y))
		{
			var cb = onContinue;
			waitingForContinue = false;
			onContinue = null;
			slideOut(function()
			{
				finishHide();
				if (cb != null)
					cb();
			});
		}
	}

	function slideIn():Void
	{
		cancelSlideTween();
		slideBusy = true;
		slideDeltaX = -badgeW;
		applyBadgeSlideOffset();
		slideTween = FlxTween.tween(this, {slideDeltaX: 0}, SLIDE_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				applyBadgeSlideOffset();
			},
			onComplete: function(_)
			{
				slideTween = null;
				slideBusy = false;
				slideDeltaX = 0;
				applyBadgeSlideOffset();
				if (pendingShow != null)
				{
					var next = pendingShow;
					pendingShow = null;
					queueShow(next);
				}
			}
		});
	}

	function slideOut(onComplete:Void->Void):Void
	{
		cancelSlideTween();
		if (!labelBadgeBg.visible)
		{
			onComplete();
			return;
		}

		slideBusy = true;
		slideTween = FlxTween.tween(this, {slideDeltaX: -badgeW}, SLIDE_DURATION, {
			ease: FlxEase.quadIn,
			onUpdate: function(_)
			{
				applyBadgeSlideOffset();
			},
			onComplete: function(_)
			{
				slideTween = null;
				slideBusy = false;
				onComplete();
			}
		});
	}

	function cancelSlideTween():Void
	{
		if (slideTween != null)
		{
			slideTween.cancel();
			slideTween = null;
		}
		FlxTween.cancelTweensOf(this);
	}

	function applyBadgeSlideOffset():Void
	{
		if (!labelBadgeBg.visible)
			return;

		var x = badgeRestX + slideDeltaX;
		labelBadgeBg.setPosition(x, badgeRestY);

		var pad = BADGE_PAD;
		var textX = x + pad;
		var textY = badgeRestY + pad;
		if (titleLabel.visible)
		{
			titleLabel.setPosition(textX, textY);
			textY += titleLabel.height + (speakerText.visible || bodyText.visible ? 4 : 0);
		}
		if (speakerText.visible)
		{
			speakerText.setPosition(textX, textY);
			textY += speakerText.height + 2;
		}
		if (bodyText.visible)
			bodyText.setPosition(textX, textY);

		if (continueHit.visible)
		{
			var btnW = Std.int(continueHit.width);
			var btnH = Std.int(continueHit.height);
			var btnX = x + badgeW - pad - btnW;
			var btnY = badgeRestY + labelBadgeBg.height - pad - btnH;
			continueHit.setPosition(btnX, btnY);
			continueLabel.setPosition(btnX, btnY + 6);
		}
	}

	function layout():Void
	{
		layoutDim();
		layoutHighlight();
		layoutPinnedBadge();
		layoutSpotlightArrow();
	}

	function layoutDim():Void
	{
		if (highlightRect == null || pinToScreenBottom || pinToScreenTop || pinToScreenAboveAnchor)
		{
			dimBg.visible = false;
			return;
		}

		dimBg.visible = true;
		var sw = Std.int(Math.max(1, FlxG.width));
		var sh = Std.int(Math.max(1, FlxG.height));
		dimBg.makeGraphic(sw, sh, FlxColor.fromRGB(8, 12, 18, DIM_ALPHA), true);
		dimBg.setPosition(0, 0);
		dimBg.updateHitbox();

		var hole = highlightRect;
		var x = Std.int(hole.x - HIGHLIGHT_PAD);
		var y = Std.int(hole.y - HIGHLIGHT_PAD);
		var w = Std.int(hole.w + HIGHLIGHT_PAD * 2);
		var h = Std.int(hole.h + HIGHLIGHT_PAD * 2);
		cutHole(dimBg, x, y, w, h, sw, sh);
	}

	function cutHole(sprite:FlxSprite, x:Int, y:Int, w:Int, h:Int, sw:Int, sh:Int):Void
	{
		var px = sprite.pixels;
		var transparent = FlxColor.fromRGB(0, 0, 0, 0);
		if (y > 0)
			px.fillRect(new Rectangle(0, 0, sw, y), transparent);
		if (y + h < sh)
			px.fillRect(new Rectangle(0, y + h, sw, sh - (y + h)), transparent);
		if (x > 0)
			px.fillRect(new Rectangle(0, y, x, h), transparent);
		if (x + w < sw)
			px.fillRect(new Rectangle(x + w, y, sw - (x + w), h), transparent);
		sprite.dirty = true;
	}

	function layoutHighlight():Void
	{
		if (highlightRect == null || pinToScreenBottom || pinToScreenTop || pinToScreenAboveAnchor)
		{
			setHighlightVisible(false);
			return;
		}

		setHighlightVisible(true);
		var x = highlightRect.x - HIGHLIGHT_PAD;
		var y = highlightRect.y - HIGHLIGHT_PAD;
		var w = highlightRect.w + HIGHLIGHT_PAD * 2;
		var h = highlightRect.h + HIGHLIGHT_PAD * 2;
		var b = HIGHLIGHT_BORDER;

		highlightTop.setPosition(x, y);
		highlightTop.setGraphicSize(Std.int(w), b);
		highlightTop.updateHitbox();

		highlightBottom.setPosition(x, y + h - b);
		highlightBottom.setGraphicSize(Std.int(w), b);
		highlightBottom.updateHitbox();

		highlightLeft.setPosition(x, y);
		highlightLeft.setGraphicSize(b, Std.int(h));
		highlightLeft.updateHitbox();

		highlightRight.setPosition(x + w - b, y);
		highlightRight.setGraphicSize(b, Std.int(h));
		highlightRight.updateHitbox();
	}

	function setHighlightVisible(value:Bool):Void
	{
		highlightTop.visible = value;
		highlightBottom.visible = value;
		highlightLeft.visible = value;
		highlightRight.visible = value;
	}

	function layoutPinnedBadge():Void
	{
		var pad = BADGE_PAD;
		var hasTitle = titleLabel.visible && titleLabel.text.length > 0;
		var hasCoach = speakerText.visible || bodyText.visible;
		if (!hasTitle && !hasCoach)
		{
			labelBadgeBg.visible = false;
			continueHit.visible = false;
			continueLabel.visible = false;
			return;
		}

		var titleSize = compactTitle ? 19 : 16;
		var bodySize = 14;
		var maxTextW = (pinToScreenBottom || pinToScreenTop || pinToScreenAboveAnchor)
			? Math.min(520.0, FlxG.width - 48) : 280.0;

		if (hasTitle)
		{
			titleLabel.setFormat(null, titleSize, TEXT_PRIMARY, "center");
			titleLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(10, 14, 18), 2);
			titleLabel.fieldWidth = Std.int(maxTextW);
			titleLabel.text = titleLabel.text;
			titleLabel.updateHitbox();
		}

		if (hasCoach)
		{
			speakerText.setFormat(null, bodySize, TEXT_ACCENT, "left");
			speakerText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(10, 14, 18), 1);
			bodyText.setFormat(null, bodySize, TEXT_BODY, "left");
			bodyText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.fromRGB(10, 14, 18), 1);
			bodyText.fieldWidth = Std.int(maxTextW);
			bodyText.text = bodyText.text;
			bodyText.updateHitbox();
		}

		var btnW = 96;
		var btnH = 28;
		var btnBlockH = waitingForContinue ? btnH + 6 : 0;
		var contentW = maxTextW;
		if (hasTitle)
			contentW = Math.max(contentW, titleLabel.width);
		if (hasCoach)
			contentW = Math.max(contentW, Math.max(speakerText.width, bodyText.width));

		var badgeW = Std.int(Math.max(contentW + pad * 2, waitingForContinue ? btnW + pad * 2 : 0));
		var textBlockH = 0.0;
		if (hasTitle)
			textBlockH += titleLabel.height;
		if (hasCoach)
		{
			if (hasTitle)
				textBlockH += 4;
			textBlockH += speakerText.height + 2 + bodyText.height;
		}
		var badgeH = Std.int(textBlockH + pad * 2 + btnBlockH);

		var pinX = 0.0;
		var pinY = 0.0;
		if (pinToScreenTop)
		{
			pinX = (FlxG.width - badgeW) * 0.5;
			pinY = SCREEN_TOP_MARGIN;
		}
		else if (pinToScreenBottom)
		{
			pinX = (FlxG.width - badgeW) * 0.5;
			pinY = FlxG.height - badgeH - SCREEN_BOTTOM_MARGIN;
		}
		else if (pinToScreenAboveAnchor && anchorW > 0)
		{
			pinX = anchorX + (anchorW - badgeW) * 0.5;
			pinY = anchorY - badgeH - BADGE_GAP;
			if (pinY < SCREEN_TOP_MARGIN)
				pinY = SCREEN_TOP_MARGIN;
		}
		else if (spotlightMode && highlightRect != null)
		{
			pinX = highlightRect.x + (highlightRect.w - badgeW) * 0.5;
			pinY = highlightRect.y + highlightRect.h + BADGE_GAP;
		}
		else if (highlightRect != null)
		{
			pinX = highlightRect.x + (highlightRect.w - badgeW) * 0.5;
			pinY = highlightRect.y - badgeH - BADGE_GAP;
			if (pinY < 4)
				pinY = highlightRect.y + highlightRect.h + BADGE_GAP;
		}
		else if (anchorW > 0)
		{
			pinX = anchorX + (anchorW - badgeW) * 0.5;
			pinY = anchorY + 6;
		}
		else
		{
			pinX = (FlxG.width - badgeW) * 0.5;
			pinY = 12;
		}

		pinX = clampX(pinX, badgeW);
		pinY = clampY(pinY, badgeH);

		badgeRestX = pinX;
		badgeRestY = pinY;
		this.badgeW = badgeW;

		labelBadgeBg.visible = true;
		labelBadgeBg.makeGraphic(badgeW, badgeH, BADGE_FILL, true);
		drawBadgeBorder(labelBadgeBg, badgeW, badgeH, BADGE_BORDER);
		labelBadgeBg.setPosition(pinX + slideDeltaX, pinY);
		labelBadgeBg.updateHitbox();
		badgeBaseY = pinY;

		var textX = pinX + pad;
		var textY = pinY + pad;
		if (hasTitle)
		{
			titleLabel.setPosition(textX, textY);
			titleBaseY = textY;
			textY += titleLabel.height + (hasCoach ? 4 : 0);
		}
		if (hasCoach)
		{
			speakerText.setPosition(textX, textY);
			bodyText.setPosition(textX, textY + speakerText.height + 2);
		}

		if (waitingForContinue)
		{
			var btnX = pinX + badgeW - pad - btnW;
			var btnY = pinY + badgeH - pad - btnH;
			continueHit.visible = true;
			continueLabel.visible = true;
			continueHit.makeGraphic(btnW, btnH, BTN_FILL, true);
			drawBadgeBorder(continueHit, btnW, btnH, BTN_BORDER);
			continueHit.setPosition(btnX, btnY);
			continueHit.updateHitbox();
			continueLabel.setFormat(null, 13, BTN_TEXT, "center");
			continueLabel.fieldWidth = btnW;
			continueLabel.setPosition(btnX, btnY + 6);
		}
		else
		{
			continueHit.visible = false;
			continueLabel.visible = false;
		}

		applyBadgeSlideOffset();
	}

	function clampX(x:Float, w:Int):Float
	{
		if (x < 4)
			return 4;
		if (x + w > FlxG.width - 4)
			return FlxG.width - w - 4;
		return x;
	}

	function clampY(y:Float, h:Int):Float
	{
		if (y < 4)
			return 4;
		if (y + h > FlxG.height - 4)
			return FlxG.height - h - 4;
		return y;
	}

	function layoutSpotlightArrow():Void
	{
		if (!spotlightMode || highlightRect == null)
		{
			arrowSprite.visible = false;
			return;
		}

		arrowSprite.loadGraphic(ARROW_PATH);
		arrowSprite.angle = 90;
		arrowSprite.setGraphicSize(ARROW_SIZE, ARROW_SIZE);
		arrowSprite.updateHitbox();
		arrowSprite.color = TEXT_ACCENT;
		arrowSprite.visible = true;
		arrowBaseX = highlightRect.x + (highlightRect.w - ARROW_SIZE) * 0.5;
		arrowBaseY = highlightRect.y - HIGHLIGHT_PAD - BADGE_GAP - ARROW_SIZE;
		arrowBaseY = Math.max(4, arrowBaseY);
		arrowSprite.setPosition(arrowBaseX, arrowBaseY);
		remove(arrowSprite, false);
		add(arrowSprite);
	}

	function drawBadgeBorder(sprite:FlxSprite, w:Int, h:Int, color:Int):Void
	{
		var px = sprite.pixels;
		var s = 2;
		px.fillRect(new Rectangle(0, 0, w, s), color);
		px.fillRect(new Rectangle(0, h - s, w, s), color);
		px.fillRect(new Rectangle(0, 0, s, h), color);
		px.fillRect(new Rectangle(w - s, 0, s, h), color);
		sprite.dirty = true;
	}

	public function setCameras(cams:Array<flixel.FlxCamera>):Void
	{
		for (member in members)
		{
			if (member != null)
				member.cameras = cams;
		}
	}
}
