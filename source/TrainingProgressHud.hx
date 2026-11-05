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

/**
 * Small "training card" pinned to the top of the desk while Chef coaches you:
 * lesson name, a row of pips, and a little celebration each time a lesson is finished.
 */
class TrainingProgressHud extends FlxGroup
{
	static inline var PANEL_W = 236;
	static inline var PANEL_H = 54;
	static inline var PIP = 12;
	static inline var PIP_GAP = 6;
	static inline var FILL = 0xF23A322A;
	static inline var BORDER = UiSkin.TRIM;
	static inline var TITLE = UiSkin.TITLE;
	static inline var BODY = 0xFFDCE6E0;
	static inline var PIP_EMPTY = UiSkin.BUTTON;
	static inline var PIP_DONE = 0xFF5FD068;
	static inline var PIP_CURRENT = UiSkin.TITLE;

	static var PRAISE = [
		"Nailed it!",
		"Chef's kiss!",
		"Look at you go!",
		"Textbook!",
		"Smooth.",
		"Management approves!"
	];

	var panel:FlxSprite;
	var titleText:FlxText;
	var lessonText:FlxText;
	var pips:Array<FlxSprite> = [];
	var baseX:Float;
	var baseY:Float;
	var currentLesson = -1;
	var lessonCount:Int;
	var shown = false;

	public function new(centerX:Float, topY:Float)
	{
		super();
		lessonCount = ChefTutorial.LESSON_NAMES.length;
		baseX = Math.round(centerX - PANEL_W * 0.5);
		baseY = topY;

		panel = new FlxSprite(baseX, baseY);
		UiSkin.panel(panel, PANEL_W, PANEL_H, FILL, BORDER, 5, 2);
		add(panel);

		titleText = new FlxText(baseX + 10, baseY + 5, PANEL_W - 20, "TRAINING", 10);
		titleText.setFormat(null, 10, TITLE, "left");
		add(titleText);

		lessonText = new FlxText(baseX + 10, baseY + 18, PANEL_W - 20, "", 14);
		lessonText.setFormat(null, 14, BODY, "left");
		lessonText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.BLACK, 1);
		add(lessonText);

		var pipsW = lessonCount * PIP + (lessonCount - 1) * PIP_GAP;
		var pipX = baseX + PANEL_W - 10 - pipsW;
		for (i in 0...lessonCount)
		{
			var pip = new FlxSprite(pipX + i * (PIP + PIP_GAP), baseY + 6);
			pip.makeGraphic(PIP, PIP, FlxColor.WHITE);
			pip.color = PIP_EMPTY;
			pips.push(pip);
			add(pip);
		}

		visible = false;
	}

	public function show():Void
	{
		if (shown)
			return;
		shown = true;
		visible = true;
		currentLesson = -1;
		for (pip in pips)
			pip.color = PIP_EMPTY;
		forEachSprite(function(s) s.y -= 70);
		lastSlide = -70;
		FlxTween.num(-70, 0, 0.45, {ease: FlxEase.backOut}, slideTo);
		setLesson(0, false);
	}

	public function hide():Void
	{
		if (!shown)
			return;
		shown = false;
		FlxTween.num(0, -80, 0.35, {
			ease: FlxEase.backIn,
			onComplete: function(_) visible = false
		}, slideTo);
	}

	public function isShown():Bool
	{
		return shown;
	}

	/** Advance to a lesson; any lessons passed on the way count as finished. */
	public function setLesson(index:Int, ?celebrate:Bool = true):Void
	{
		if (!shown || index <= currentLesson)
			return;

		var previous = currentLesson;
		currentLesson = Std.int(Math.min(index, lessonCount - 1));
		for (i in 0...lessonCount)
			pips[i].color = i < currentLesson ? PIP_DONE : (i == currentLesson ? PIP_CURRENT : PIP_EMPTY);

		lessonText.text = '${currentLesson + 1}/$lessonCount  ${ChefTutorial.LESSON_NAMES[currentLesson]}';
		Juice.punch(lessonText, 0.15);
		Juice.punch(pips[currentLesson], 0.4);

		if (celebrate && previous >= 0)
			celebrateLesson(previous);
	}

	/** Final pip goes green — training complete. */
	public function complete():Void
	{
		if (!shown)
			return;
		for (pip in pips)
			pip.color = PIP_DONE;
		lessonText.text = "Certified!";
		Juice.punch(lessonText, 0.2);
		celebrateLesson(lessonCount - 1);
	}

	function celebrateLesson(index:Int):Void
	{
		var pip = pips[index];
		Juice.sfx(Juice.SFX_TICK, 0.8);
		Juice.burst(pip.x + PIP * 0.5, pip.y + PIP * 0.5, [PIP_DONE, PIP_CURRENT, FlxColor.WHITE], 14, 140, 0.6, 4, 300);
		Juice.popText(baseX + PANEL_W * 0.5, baseY + PANEL_H + 16, PRAISE[FlxG.random.int(0, PRAISE.length - 1)], PIP_DONE, 16, 28);
		Juice.punch(pip, 0.5);
	}

	var lastSlide = 0.0;

	function slideTo(offset:Float):Void
	{
		var dy = offset - lastSlide;
		lastSlide = offset;
		forEachSprite(function(s) s.y += dy);
	}

	function forEachSprite(fn:FlxSprite->Void):Void
	{
		fn(panel);
		fn(titleText);
		fn(lessonText);
		for (pip in pips)
			fn(pip);
	}
}
