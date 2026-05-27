package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class ComputerHud extends FlxGroup
{
	static inline var START_HOUR = 8;
	static inline var END_HOUR = 16;
	static inline var DAY_DURATION_SECONDS = 600.0;
	static inline var BLINK_INTERVAL_SECONDS = 1.2;
	static inline var MINUTE_STEP = 10;

	var timeLabel:FlxText;
	var elapsedClock = 0.0;
	var blinkTimer = 0.0;
	var colonVisible = true;

	public function new(x:Int, y:Int, width:Int, height:Int)
	{
		super();

		var sidePad = 2;
		var bottomPad = Std.int(Math.max(6, FlxG.height / 80));
		var gap = Std.int(Math.max(2, width / 80));
		var borderSize = 1;

		var texts = ["June 1st", "08:00", "13$", "0$"];
		var totalGap = gap * (texts.length - 1);
		var boxW = Std.int((width - sidePad * 2 - totalGap) / texts.length);
		var fontSize = Std.int(Math.max(9, FlxG.height / 64));
		var contentH = fontSize + 6;

		var fillColor = FlxColor.fromRGB(44, 54, 68);
		var borderColor = FlxColor.fromRGB(80, 80, 90);

		var rowY = y + height - contentH - bottomPad;
		var boxH = y + height - rowY;
		var rowX = x + sidePad;
		for (i in 0...texts.length)
		{
			var label = addRow(rowX, rowY, boxW, boxH, contentH, texts[i], textColor(i), borderSize, fontSize, fillColor, borderColor);
			if (i == 1)
				timeLabel = label;
			rowX += boxW + gap;
		}

		updateClockLabel();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		elapsedClock += elapsed;
		if (elapsedClock > DAY_DURATION_SECONDS)
			elapsedClock = DAY_DURATION_SECONDS;

		blinkTimer += elapsed;
		if (blinkTimer >= BLINK_INTERVAL_SECONDS)
		{
			blinkTimer -= BLINK_INTERVAL_SECONDS;
			colonVisible = !colonVisible;
		}

		updateClockLabel();
	}

	function textColor(i:Int):Int
	{
		return switch (i)
		{
			case 2: FlxColor.fromRGB(96, 192, 132);
			case 3: FlxColor.fromRGB(210, 96, 96);
			default: FlxColor.fromRGB(228, 233, 240);
		}
	}

	function addRow(bx:Int, by:Int, bw:Int, bh:Int, contentH:Int, text:String, textColor:Int, borderSize:Int, fontSize:Int, fillColor:Int, borderColor:Int):FlxText
	{
		var box = new FlxSprite(bx, by);
		box.makeGraphic(bw, bh, fillColor, true);
		drawBorder(box, bw, bh, borderColor, borderSize);
		add(box);

		var label = new FlxText(bx, by + Std.int((contentH - fontSize) / 2), bw, text);
		label.setFormat(null, fontSize, textColor, "center");
		add(label);
		return label;
	}

	function updateClockLabel():Void
	{
		if (timeLabel == null)
			return;

		var dayMinutes = (END_HOUR - START_HOUR) * 60;
		var progressedRaw = dayMinutes * (elapsedClock / DAY_DURATION_SECONDS);
		var progressedMinutes = Std.int(Math.floor(progressedRaw / MINUTE_STEP) * MINUTE_STEP);
		var totalMinutes = START_HOUR * 60 + progressedMinutes;
		var hour = Std.int(totalMinutes / 60);
		var minute = totalMinutes % 60;

		var sep = colonVisible ? ":" : " ";
		timeLabel.text = twoDigits(hour) + sep + twoDigits(minute);
	}

	function twoDigits(v:Int):String
	{
		return v < 10 ? "0" + Std.string(v) : Std.string(v);
	}

	function drawBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}
}
