package;

class GameClock
{
	public static inline var START_HOUR = 8;
	public static inline var END_HOUR = 16;
	public static inline var DAY_DURATION_SECONDS = 3600.0;
	public static inline var HUD_MINUTE_STEP = 10;

	public static var elapsedSeconds(default, null) = 0.0;

	public static function advance(elapsed:Float):Void
	{
		elapsedSeconds += elapsed;
		if (elapsedSeconds > DAY_DURATION_SECONDS)
			elapsedSeconds = DAY_DURATION_SECONDS;
	}

	public static function reset():Void
	{
		elapsedSeconds = 0.0;
	}

	public static function formatHudTime(colonVisible:Bool):String
	{
		var dayMinutes = (END_HOUR - START_HOUR) * 60;
		var progressedRaw = dayMinutes * (elapsedSeconds / DAY_DURATION_SECONDS);
		var progressedMinutes = Std.int(Math.floor(progressedRaw / HUD_MINUTE_STEP) * HUD_MINUTE_STEP);
		var totalMinutes = START_HOUR * 60 + progressedMinutes;
		var hour = Std.int(totalMinutes / 60);
		var minute = totalMinutes % 60;

		var sep = colonVisible ? ":" : " ";
		return twoDigits(hour) + sep + twoDigits(minute);
	}

	public static function formatTime12h():String
	{
		var daySeconds = (END_HOUR - START_HOUR) * 3600;
		var progressedRaw = daySeconds * (elapsedSeconds / DAY_DURATION_SECONDS);
		var totalSeconds = START_HOUR * 3600 + Std.int(progressedRaw);
		var hour24 = Std.int(totalSeconds / 3600) % 24;
		var minute = Std.int(totalSeconds / 60) % 60;
		var second = totalSeconds % 60;

		var ampm = hour24 >= 12 ? "PM" : "AM";
		var hour12 = hour24 % 12;
		if (hour12 == 0)
			hour12 = 12;

		return twoDigits(hour12) + ":" + twoDigits(minute) + ":" + twoDigits(second) + " " + ampm;
	}

	static function twoDigits(v:Int):String
	{
		return v < 10 ? "0" + Std.string(v) : Std.string(v);
	}
}
