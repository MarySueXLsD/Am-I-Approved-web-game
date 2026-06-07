package;

import flixel.FlxG;
import flixel.math.FlxMath;

class GameSettings
{
	public static var masterVolume(default, set):Float = 1.0;
	public static var musicVolume(default, set):Float = 0.85;
	public static var sfxVolume(default, set):Float = 1.0;

	static function set_masterVolume(v:Float):Float
	{
		masterVolume = FlxMath.bound(v, 0, 1);
		apply();
		return masterVolume;
	}

	static function set_musicVolume(v:Float):Float
	{
		musicVolume = FlxMath.bound(v, 0, 1);
		apply();
		return musicVolume;
	}

	static function set_sfxVolume(v:Float):Float
	{
		sfxVolume = FlxMath.bound(v, 0, 1);
		apply();
		return sfxVolume;
	}

	public static function apply():Void
	{
		FlxG.sound.volume = masterVolume;
	}

	public static function toggleFullscreen():Void
	{
		FlxG.fullscreen = !FlxG.fullscreen;
	}
}
