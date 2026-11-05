package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

/** Navy status bar under the computer: a tear-off calendar, an amber desk clock and the shift tally. */
class ComputerHud extends FlxGroup
{
	static inline var BLINK_INTERVAL_SECONDS = 1.2;
	static inline var BAR_H = 32;
	static inline var AMBER = 0xFFE8A83C;

	var timeLabel:FlxText;
	var servedLabel:FlxText;
	var scoreLabel:FlxText;
	var blinkTimer = 0.0;
	var colonVisible = true;
	var shownServed = -1;
	var shownScore = 0.0;
	var targetScore = 0;

	public function new(x:Int, y:Int, width:Int, height:Int)
	{
		super();

		// Taller than the reserved strip on purpose: it sits over the dark bottom edge of the computer table.
		var barY = y + height - BAR_H;
		var bar = new FlxSprite(x, barY);
		UiSkin.panel(bar, width, BAR_H, UiSkin.PANEL, UiSkin.PANEL_DEEP, 3, 2, 0);
		bar.pixels.fillRect(new Rectangle(3, 2, width - 6, 1), UiSkin.TRIM_DARK);
		bar.dirty = true;
		add(bar);

		var cellY = barY + 5;
		var cellH = BAR_H - 8;
		var cellX = x + 4;

		var calendarW = 58;
		addCalendar(cellX, cellY, calendarW, cellH);
		cellX += calendarW + 4;

		var clockW = 58;
		var clockFace = new FlxSprite(cellX, cellY);
		UiSkin.panel(clockFace, clockW, cellH, UiSkin.PANEL_DEEP, UiSkin.TRIM_DARK, 2, 1, 0);
		add(clockFace);
		timeLabel = addLabel(cellX, cellY + 3, clockW, "08:00", 14, AMBER);
		cellX += clockW + 3;

		var counterW = Std.int((x + width - 3 - cellX) / 2);
		servedLabel = addCounter(cellX, cellY, counterW, "SERVED");
		cellX += counterW;
		scoreLabel = addCounter(cellX, cellY, counterW, "SCORE");

		updateClockLabel();
	}

	function addCalendar(cx:Int, cy:Int, w:Int, h:Int):Void
	{
		var page = new FlxSprite(cx, cy);
		UiSkin.panel(page, w, h, UiSkin.CREAM, UiSkin.INK, 2, 1, 0);
		page.pixels.fillRect(new Rectangle(1, 1, w - 2, 6), UiSkin.STAMP_RED);
		page.dirty = true;
		add(page);
		addLabel(cx, cy + 8, w, "June 1st", 9, UiSkin.INK);
	}

	function addCounter(cx:Int, cy:Int, w:Int, title:String):FlxText
	{
		addLabel(cx, cy - 1, w, title, 8, UiSkin.STEEL);
		return addLabel(cx, cy + 9, w, "0", 11, UiSkin.CREAM);
	}

	function addLabel(lx:Int, ly:Int, w:Int, text:String, size:Int, color:Int):FlxText
	{
		var label = new FlxText(lx, ly, w, text);
		label.setFormat(null, size, color, "center");
		add(label);
		return label;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (MonitorOverlay.pausesDialogue() || ShiftPauseOverlay.pausesDialogue()
			|| MainMenuOverlay.blocksWorldInput() || BeginningDayOverlay.blocksWorldInput()
			|| StudioLogoSplash.blocksWorldInput())
			return;

		GameClock.advance(elapsed);

		blinkTimer += elapsed;
		if (blinkTimer >= BLINK_INTERVAL_SECONDS)
		{
			blinkTimer -= BLINK_INTERVAL_SECONDS;
			colonVisible = !colonVisible;
		}

		updateClockLabel();
		updateStatLabels(elapsed);
	}

	/** Live shift tally: the score counts up instead of jumping, and both counters pop when they change. */
	function updateStatLabels(elapsed:Float):Void
	{
		if (ShiftStats.clientsServed != shownServed)
		{
			var grew = shownServed >= 0 && ShiftStats.clientsServed > shownServed;
			shownServed = ShiftStats.clientsServed;
			servedLabel.text = Std.string(shownServed);
			if (grew)
				Juice.punch(servedLabel, 0.25, 0.35);
		}

		var score = ShiftStats.score();
		if (score != targetScore)
		{
			if (score > targetScore)
				Juice.punch(scoreLabel, 0.3, 0.4);
			targetScore = score;
		}

		if (Math.abs(shownScore - targetScore) > 0.5)
		{
			var step = Math.max(60, Math.abs(targetScore - shownScore) * 3) * elapsed;
			shownScore = shownScore < targetScore ? Math.min(targetScore, shownScore + step) : Math.max(targetScore, shownScore - step);
			scoreLabel.color = shownScore < targetScore ? UiSkin.TRIM : UiSkin.CREAM;
		}
		else
		{
			shownScore = targetScore;
			scoreLabel.color = UiSkin.CREAM;
		}
		scoreLabel.text = Std.string(Std.int(shownScore));
	}

	function updateClockLabel():Void
	{
		timeLabel.text = GameClock.formatHudTime(colonVisible);
	}

	public function setCameras(cams:Array<FlxCamera>):Void
	{
		for (member in members)
		{
			if (member != null)
				member.cameras = cams;
		}
	}
}
