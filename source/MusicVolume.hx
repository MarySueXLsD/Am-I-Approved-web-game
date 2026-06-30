package;

class MusicVolume
{
	public static inline var MENU_MAX = 0.2;
	public static inline var GAMEPLAY_MAX = 0.1;

	public static function menuVolume(?transitionFactor:Float = 1.0):Float
	{
		return GameSettings.musicVolume * MENU_MAX * transitionFactor;
	}

	public static function gameplayVolume():Float
	{
		return GameSettings.musicVolume * GAMEPLAY_MAX;
	}
}
