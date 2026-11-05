package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

typedef PlacedSprite =
{
	sprite:FlxSprite,
	x:Float,
	y:Float,
}

typedef StatTile =
{
	parts:Array<FlxSprite>,
	icon:FlxSprite,
	value:FlxText,
	target:Float,
	format:Float->String,
	done:Bool,
	started:Bool,
	startAt:Float,
	sound:String,
}

/**
 * The end-of-shift report: a stat board that fills in tile by tile, the score counting up, a grade
 * stamped into its box, then Chef's verdict.
 */
class EndOfDemoPopup extends MainMenuSlidePopup
{
	static inline var BTN_BG = UiSkin.BUTTON;
	static inline var HOVER_SCALE = 1.06;
	static inline var HOVER_TWEEN_DURATION = 0.14;

	static inline var PANEL_W = 744;
	static inline var PANEL_H = 548;
	static inline var PAD = 18;
	static inline var TILE_W = 232;
	static inline var TILE_H = 70;
	static inline var TILE_GAP = 8;
	static inline var GRID_Y = 72;
	static inline var COL2_X = 508;
	static inline var COL2_W = 218;
	static inline var GRADE_H = 228;
	static inline var VERDICT_Y = 388;
	static inline var BTN_W = 160;
	static inline var BTN_H = 36;
	static inline var ICON_WELL = 46;
	static inline var ICON_SCALE = 3;

	// Reveal timing, in seconds after the panel lands.
	static inline var TILE_STEP = 0.14;
	static inline var TILE_FADE = 0.18;
	static inline var COUNT_TIME = 0.4;
	static inline var STAMP_DROP = 0.16;

	static var instance:EndOfDemoPopup;

	var panel = new FlxSprite();
	var placed:Array<PlacedSprite> = [];
	var tiles:Array<StatTile> = [];

	var scoreValue:FlxText;
	var gradeBox:FlxSprite;
	var gradeLabel:FlxText;
	var chefFrame:FlxSprite;
	var bubbleBg:FlxSprite;
	var bubbleText:FlxText;
	var footerText:FlxText;

	var okHit:FlxSprite;
	var okBg:FlxSprite;
	var okLabel:FlxText;
	var okHoverTween:FlxTween;
	var okHovered = false;

	var revealing = false;
	var revealT = 0.0;
	var scoreAt = 0.0;
	var stampAt = 0.0;
	var verdictAt = 0.0;
	var stampLanded = false;
	var stampLandT = 0.0;
	var scoreStarted = false;
	var verdictShown = false;
	var built = false;
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
	}

	// ---- input ------------------------------------------------------------------------------

	public function updateHover():Void
	{
		if (!visible || isAnimating || !built)
			return;

		var p = FlxG.mouse.getViewPosition();
		var nextHover = !revealing && okHit.overlapsPoint(p);
		if (nextHover != okHovered)
		{
			okHovered = nextHover;
			okBg.color = okHovered ? UiSkin.HOVER_TINT : FlxColor.WHITE;
			updateOkHoverScale();
		}
	}

	public function resetHover():Void
	{
		okHovered = false;
		cancelOkHoverTween();
		if (!built)
			return;
		okBg.color = FlxColor.WHITE;
		okBg.scale.set(1, 1);
		okLabel.scale.set(1, 1);
	}

	override function handlePanelClick(p:FlxPoint):Bool
	{
		if (revealing)
		{
			skipReveal();
			return true;
		}
		if (okHit.overlapsPoint(p))
		{
			handleOk();
			return true;
		}
		return containsPanelPoint(p);
	}

	override function handleBackdropClick(p:FlxPoint):Bool
	{
		if (!visible || isAnimating)
			return false;
		if (revealing)
		{
			skipReveal();
			return true;
		}
		return containsPanelPoint(p) ? false : true;
	}

	function handleOk():Void
	{
		close();
		if (onDismiss != null)
			onDismiss();
	}

	// ---- lifecycle --------------------------------------------------------------------------

	override function onBeforeShow():Void
	{
		// Stats change every shift, so rebuild the report each time it opens.
		layoutPopup();
		resetHover();
	}

	override function finishOpen():Void
	{
		super.finishOpen();
		revealing = true;
		revealT = 0;
	}

	override function onClosed():Void
	{
		revealing = false;
		resetHover();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!visible || !built)
			return;
		if (revealing)
		{
			revealT += elapsed;
			advanceReveal();
		}
		if (stampLanded)
			settleStamp(elapsed);
	}

	// ---- reveal -----------------------------------------------------------------------------

	function advanceReveal():Void
	{
		for (tile in tiles)
			advanceTile(tile);

		if (revealT >= scoreAt)
		{
			if (!scoreStarted)
			{
				scoreStarted = true;
				Juice.sfx(Juice.SFX_BLIP, 0.6);
			}
			var t = Math.min(1, (revealT - scoreAt) / COUNT_TIME);
			scoreValue.text = Std.string(Std.int(ShiftStats.score() * FlxEase.quadOut(t)));
		}

		if (revealT >= stampAt && !stampLanded)
		{
			var t = Math.min(1, (revealT - stampAt) / STAMP_DROP);
			var s = 3.0 - 2.0 * t * t;
			gradeBox.visible = gradeLabel.visible = true;
			gradeBox.alpha = gradeLabel.alpha = Math.min(1, t * 2);
			gradeBox.scale.set(s, s);
			gradeLabel.scale.set(s, s);
			if (t >= 1)
				landStamp();
		}

		if (revealT >= verdictAt && !verdictShown)
			showVerdict();

		if (verdictShown)
		{
			var t = Math.min(1, (revealT - verdictAt) / 0.25);
			bubbleBg.alpha = bubbleText.alpha = footerText.alpha = t;
			okBg.alpha = okLabel.alpha = t;
			if (t >= 1)
				revealing = false;
		}
	}

	function advanceTile(tile:StatTile):Void
	{
		var local = revealT - tile.startAt;
		if (local < 0 || tile.done)
			return;

		if (!tile.started)
		{
			tile.started = true;
			if (tile.sound != null)
				Juice.sfx(tile.sound, 0.45, 0.05);
		}

		var fade = Math.min(1, local / TILE_FADE);
		for (part in tile.parts)
			part.alpha = fade;
		var pop = 1 + (1 - FlxEase.backOut(fade)) * 0.6;
		tile.icon.scale.set(pop, pop);

		var count = Math.min(1, local / COUNT_TIME);
		tile.value.text = tile.format(tile.target * FlxEase.quadOut(count));
		if (fade >= 1 && count >= 1)
		{
			tile.value.text = tile.format(tile.target);
			tile.icon.scale.set(1, 1);
			tile.done = true;
		}
	}

	function landStamp():Void
	{
		stampLanded = true;
		stampLandT = 0;
		gradeBox.alpha = gradeLabel.alpha = 1;

		Juice.sfx(Juice.SFX_STAMP, 1.0, 0.05);
		Juice.sfx(Juice.SFX_FANFARE, 0.9);
		Juice.shake(0.012, 0.22);

		var cx = panelX(COL2_X + COL2_W * 0.5);
		var cy = panelY(GRID_Y + GRADE_H * 0.5 + 8);
		Juice.burst(cx, cy, [gradeColor(), FlxColor.WHITE], 26, 260, 0.9);
		if (ShiftStats.grade().charAt(0) == "A")
			Juice.coinShower(cx, cy, 24);
	}

	function settleStamp(elapsed:Float):Void
	{
		stampLandT += elapsed;
		var s = 1 + 0.14 * Math.exp(-9 * stampLandT) * Math.cos(32 * stampLandT);
		gradeBox.scale.set(s, s);
		gradeLabel.scale.set(s, s);
	}

	function showVerdict():Void
	{
		verdictShown = true;
		Juice.sfx(Juice.SFX_PAGE, 0.6);
	}

	/** Clicking during the reveal jumps straight to the finished board. */
	function skipReveal():Void
	{
		revealT = Math.max(verdictAt + 1, revealT);
		advanceReveal();
		revealing = false;
	}

	// ---- layout -----------------------------------------------------------------------------

	override function layoutPopup():Void
	{
		panelW = Math.min(FlxG.width - 16, PANEL_W);
		panelH = Math.min(FlxG.height - 16, PANEL_H);
		restX = (FlxG.width - panelW) * 0.5;
		restY = (FlxG.height - panelH) * 0.5;

		for (entry in placed)
		{
			slideRoot.remove(entry.sprite, true);
			entry.sprite.destroy();
		}
		slideRoot.remove(panel, true);
		placed = [];
		tiles = [];
		revealing = false;
		revealT = 0;
		stampLanded = false;
		scoreStarted = false;
		verdictShown = false;

		skinPanel(panel, Std.int(panelW), Std.int(panelH));
		panel.updateHitbox();
		slideRoot.add(panel);

		buildHeader();
		buildTiles();
		buildGradeColumn();
		buildVerdict();
		buildButton();
		built = true;

		// Everything is hidden until its turn in the reveal.
		for (tile in tiles)
			for (part in tile.parts)
				part.alpha = 0;
		bubbleBg.alpha = bubbleText.alpha = footerText.alpha = 0;
		okBg.alpha = okLabel.alpha = 0;

		var last = 0.1 + tiles.length * TILE_STEP;
		scoreAt = last + 0.05;
		stampAt = scoreAt + COUNT_TIME + 0.1;
		verdictAt = stampAt + STAMP_DROP + 0.45;

		syncPopupLayout();
	}

	function buildHeader():Void
	{
		label(PAD, 15, 0, "END OF SHIFT", 32, UiSkin.TITLE);
		label(PAD + 2, 49, 0, "PERFORMANCE REVIEW", 10, UiSkin.TRIM);
		label(COL2_X, 22, COL2_W, "Clerk #447-B", 16, UiSkin.TEXT, "right");
		label(COL2_X, 45, COL2_W, "June 1st", 10, UiSkin.STEEL, "right");

		var rule = new FlxSprite();
		rule.makeGraphic(PANEL_W - PAD * 2, 2, UiSkin.TRIM_DARK, true);
		place(rule, PAD, 63);
	}

	function buildTiles():Void
	{
		var intFormat = function(v:Float) return Std.string(Math.round(v));
		var lorFormat = function(v:Float) return LoanAffordabilityCalculator.formatLorDisplay(Math.round(v));
		var timeFormat = function(v:Float)
		{
			var total = Math.round(v);
			var s = total % 60;
			return Std.int(total / 60) + ":" + (s < 10 ? "0" : "") + s;
		};

		var bounced = ShiftStats.rejectedSubmissions;
		addTile("client", "CLIENTS SERVED", ShiftStats.clientsServed, intFormat, UiSkin.TEXT, Juice.SFX_KEY);
		addTile("approved", "LOANS APPROVED", ShiftStats.loansApproved, intFormat, Juice.GREEN, Juice.SFX_KEY);
		addTile("coin", "LOR GRANTED", ShiftStats.lorGranted, lorFormat, Juice.GOLD, Juice.SFX_COINS);
		addTile("decline", "HONEST DECLINES", ShiftStats.correctDeclines, intFormat, UiSkin.TEXT, Juice.SFX_KEY);
		addTile("fraud", "FRAUD CAUGHT", ShiftStats.fraudCaught, intFormat, UiSkin.TEXT, Juice.SFX_KEY);
		addTile("record", "QUESTIONS ASKED", ShiftStats.questionsAsked, intFormat, UiSkin.TEXT, Juice.SFX_KEY);
		addTile("bounced", "APPLICATIONS BOUNCED", bounced, intFormat, bounced > 0 ? Juice.RED : UiSkin.TEXT, Juice.SFX_KEY);
		addTile("clock", "SHIFT TIME", ShiftStats.shiftSeconds, timeFormat, UiSkin.TEXT, Juice.SFX_KEY);
	}

	function addTile(icon:String, title:String, target:Float, format:Float->String, valueColor:Int, sound:String):Void
	{
		var index = tiles.length;
		var col = index % 2;
		var row = Std.int(index / 2);
		var x = PAD + col * (TILE_W + TILE_GAP + 4);
		var y = GRID_Y + row * (TILE_H + TILE_GAP);

		var bg = new FlxSprite();
		UiSkin.panel(bg, TILE_W, TILE_H, UiSkin.PANEL_DEEP, UiSkin.TRIM_DARK, 3, 1, 0);
		place(bg, x, y);

		var wellY = (TILE_H - ICON_WELL) * 0.5;
		var well = new FlxSprite();
		UiSkin.panel(well, ICON_WELL, ICON_WELL, UiSkin.BUTTON, UiSkin.TRIM_DARK, 3, 1, 0);
		place(well, x + 12, y + wellY);

		var iconSize = PixelIcons.SIZE * ICON_SCALE;
		var iconSprite = new FlxSprite();
		PixelIcons.make(iconSprite, icon, ICON_SCALE);
		iconSprite.updateHitbox();
		place(iconSprite, x + 12 + (ICON_WELL - iconSize) * 0.5, y + wellY + (ICON_WELL - iconSize) * 0.5);

		var value = label(x + 68, y + 12, TILE_W - 74, format(0), 24, valueColor);
		var name = label(x + 68, y + 44, TILE_W - 74, title, 8, UiSkin.STEEL);

		tiles.push({
			parts: [bg, well, iconSprite, value, name],
			icon: iconSprite,
			value: value,
			target: target,
			format: format,
			done: false,
			started: false,
			startAt: 0.1 + index * TILE_STEP,
			sound: sound,
		});
	}

	function buildGradeColumn():Void
	{
		var frame = new FlxSprite();
		UiSkin.panel(frame, COL2_W, GRADE_H, UiSkin.PANEL_DEEP, UiSkin.TRIM_DARK, 3, 1, 0);
		place(frame, COL2_X, GRID_Y);
		label(COL2_X, GRID_Y + 12, COL2_W, "GRADE", 16, UiSkin.TRIM, "center");

		var grade = ShiftStats.grade();
		var color = gradeColor();

		gradeLabel = new FlxText(0, 0, 0, grade, 64);
		gradeLabel.setFormat(null, 64, color, "center");
		gradeLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, UiSkin.OUTLINE, 3);
		gradeLabel.updateHitbox();

		var boxW = Std.int(Math.max(150, gradeLabel.width + 32));
		var boxH = Std.int(gradeLabel.height + 24);
		gradeBox = new FlxSprite();
		gradeBox.makeGraphic(boxW, boxH, FlxColor.TRANSPARENT, true);
		var c:FlxColor = color;
		gradeBox.pixels.fillRect(new Rectangle(0, 0, boxW, boxH), FlxColor.fromRGB(c.red, c.green, c.blue, 40));
		drawBorder(gradeBox, boxW, boxH, color, 5);

		var cx = COL2_X + COL2_W * 0.5;
		var cy = GRID_Y + GRADE_H * 0.5 + 12;
		place(gradeBox, cx - boxW * 0.5, cy - boxH * 0.5);
		place(gradeLabel, cx - gradeLabel.width * 0.5, cy - gradeLabel.height * 0.5);
		gradeBox.angle = gradeLabel.angle = -9;
		gradeBox.visible = gradeLabel.visible = false;

		var scoreY = GRID_Y + GRADE_H + 8;
		var scoreBg = new FlxSprite();
		UiSkin.panel(scoreBg, COL2_W, TILE_H - 2, UiSkin.PANEL_DEEP, UiSkin.TRIM_DARK, 3, 1, 0);
		place(scoreBg, COL2_X, scoreY);
		label(COL2_X, scoreY + 8, COL2_W, "SCORE", 8, UiSkin.STEEL, "center");
		scoreValue = label(COL2_X, scoreY + 26, COL2_W, "0", 24, UiSkin.TITLE, "center");
	}

	function gradeColor():Int
	{
		return switch (ShiftStats.grade().charAt(0))
		{
			case "A": Juice.GREEN;
			case "B": Juice.GOLD;
			default: Juice.RED;
		};
	}

	function buildVerdict():Void
	{
		var size = 92;
		chefFrame = new FlxSprite();
		UiSkin.panel(chefFrame, size, size, UiSkin.ACCENT, UiSkin.TRIM, 3, 2, 0);
		// Chef's head and shoulders, shrunk with hard pixels so it matches the game's art.
		var portrait = FlxG.bitmap.add("static/Clients/chef.png").bitmap;
		var scale = 0.27;
		var drawW = portrait.width * scale;
		var matrix = new Matrix(scale, 0, 0, scale, (size - drawW) * 0.5, 2);
		var clip = new Rectangle(2, 2, size - 4, size - 4);
		chefFrame.pixels.draw(portrait, matrix, null, null, clip, false);
		chefFrame.dirty = true;
		place(chefFrame, PAD, VERDICT_Y);

		var bubbleX = PAD + size + 6;
		var bubbleW = PANEL_W - PAD * 2 - size - 6 - UiSkin.TAIL_W - 2;
		bubbleBg = new FlxSprite();
		UiSkin.bubble(bubbleBg, bubbleW, 76, UiSkin.CREAM, UiSkin.INK, true);
		place(bubbleBg, bubbleX, VERDICT_Y + 8);
		bubbleText = label(bubbleX + UiSkin.TAIL_W + 14, VERDICT_Y + 22, bubbleW - 28, ShiftStats.gradeComment(), 16, UiSkin.INK);
		bubbleText.borderStyle = FlxTextBorderStyle.NONE;

		footerText = label(PAD, PANEL_H - PAD - 23, PANEL_W - PAD * 2 - BTN_W - 12, "That's the end of the demo. Thanks for playing!", 10, UiSkin.STEEL);
	}

	function buildButton():Void
	{
		var x = PANEL_W - PAD - BTN_W;
		var y = PANEL_H - PAD - BTN_H;
		okBg = new FlxSprite();
		UiSkin.panel(okBg, BTN_W, BTN_H, UiSkin.CREAM, UiSkin.INK, 4, 2, 0);
		place(okBg, x, y);
		okLabel = label(x, y + 9, BTN_W, "Clock out", 16, UiSkin.INK, "center");
		okLabel.borderStyle = FlxTextBorderStyle.NONE;
		okHit = new FlxSprite();
		okHit.makeGraphic(BTN_W, BTN_H, 0x00000000, true);
		place(okHit, x, y);
	}

	function label(x:Float, y:Float, width:Float, text:String, size:Int, color:Int, ?align:String = "left"):FlxText
	{
		var t = new FlxText(0, 0, width, text, size);
		t.setFormat(null, size, color, align);
		t.setBorderStyle(FlxTextBorderStyle.OUTLINE, UiSkin.OUTLINE, 1);
		place(t, x, y);
		return t;
	}

	function place(sprite:FlxSprite, x:Float, y:Float):Void
	{
		slideRoot.add(sprite);
		placed.push({sprite: sprite, x: x, y: y});
	}

	override function syncPopupLayout():Void
	{
		super.syncPopupLayout();
		panel.setPosition(panelX(0), panelY(0));
		for (entry in placed)
			entry.sprite.setPosition(panelX(entry.x), panelY(entry.y));
	}

	function updateOkHoverScale():Void
	{
		cancelOkHoverTween();
		var target = okHovered ? HOVER_SCALE : 1.0;
		okHoverTween = FlxTween.tween(okBg.scale, {x: target, y: target}, HOVER_TWEEN_DURATION, {
			ease: FlxEase.quadOut,
			onUpdate: function(_)
			{
				okLabel.scale.set(okBg.scale.x, okBg.scale.y);
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
