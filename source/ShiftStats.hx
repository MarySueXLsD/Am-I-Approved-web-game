package;

/** Running tally for the current shift — feeds the end-of-shift performance report. */
class ShiftStats
{
	public static var clientsServed = 0;
	public static var loansApproved = 0;
	public static var lorGranted = 0.0;
	public static var correctDeclines = 0;
	public static var fraudCaught = 0;
	public static var recordsFixed = 0;
	public static var rejectedSubmissions = 0;
	public static var shiftSeconds = 0.0;
	public static var running = false;

	public static function reset():Void
	{
		clientsServed = 0;
		loansApproved = 0;
		lorGranted = 0;
		correctDeclines = 0;
		fraudCaught = 0;
		recordsFixed = 0;
		rejectedSubmissions = 0;
		shiftSeconds = 0;
		running = false;
	}

	public static function tick(elapsed:Float):Void
	{
		if (running)
			shiftSeconds += elapsed;
	}

	/** Each perfect case is worth 100; every bounced submission costs 15. */
	public static function score():Int
	{
		var good = loansApproved + correctDeclines + fraudCaught + recordsFixed;
		return Std.int(Math.max(0, good * 100 - rejectedSubmissions * 15));
	}

	public static function grade():String
	{
		if (clientsServed == 0)
			return "—";
		var perCase = score() / (clientsServed * 100.0);
		if (perCase >= 0.97)
			return "A+";
		if (perCase >= 0.9)
			return "A";
		if (perCase >= 0.75)
			return "B";
		if (perCase >= 0.55)
			return "C";
		return "D";
	}

	public static function gradeComment():String
	{
		return switch (grade())
		{
			case "A+": "Management is speechless. Management is also still out to lunch.";
			case "A": "Employee of the month material. The plaque is on backorder.";
			case "B": "Solid shift. Chef only sighed twice.";
			case "C": "The paperwork survived. Mostly.";
			case "D": "Chef has scheduled a 'quick chat' for tomorrow morning.";
			default: "Did anyone come in today?";
		};
	}

	public static function formatDuration():String
	{
		var total = Std.int(shiftSeconds);
		var m = Std.int(total / 60);
		var s = total % 60;
		return '$m:${s < 10 ? "0" : ""}$s';
	}
}
