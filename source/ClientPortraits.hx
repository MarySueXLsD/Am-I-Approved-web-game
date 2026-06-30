package;

class ClientPortraits
{
	static var ORDERED = [
		"static/Clients/client1.png",
		"static/Clients/client2.png",
		"static/Clients/client3.png",
		"static/Clients/client4.png",
		"static/Clients/client5.png",
		"static/Clients/client6.png",
		"static/Clients/client7.png",
	];

	public static function defaultPath():String
	{
		return ORDERED[0];
	}

	/** Story client slot (1 = first client after chef, 2 = second, …). */
	public static function pathForClientSlot(clientIndex:Int):String
	{
		if (ORDERED.length == 0)
			return "static/Clients/client1.png";
		if (clientIndex <= 0)
			return ORDERED[0];
		var slot = clientIndex - 1;
		if (slot >= ORDERED.length)
			return ORDERED[ORDERED.length - 1];
		return ORDERED[slot];
	}

	public static function pathForIndex(index:Int):String
	{
		return pathForClientSlot(index);
	}

	public static function pathForCitizen(c:Citizen):String
	{
		return pathForIndex(CitizenRegistry.indexOf(c));
	}
}
