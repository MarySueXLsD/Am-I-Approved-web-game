package;

class ClientPortraits
{
	static var ORDERED = [
		"static/Clients/client1.png",
		"static/Clients/client2.png",
	];

	public static function defaultPath():String
	{
		return ORDERED[0];
	}

	public static function pathForIndex(index:Int):String
	{
		if (ORDERED.length == 0)
			return "static/Clients/client1.png";
		if (index < 0)
			return ORDERED[0];
		return ORDERED[index % ORDERED.length];
	}

	public static function pathForCitizen(c:Citizen):String
	{
		return pathForIndex(CitizenRegistry.indexOf(c));
	}
}
