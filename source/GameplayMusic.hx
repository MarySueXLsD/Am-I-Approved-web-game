package;

import flixel.FlxG;
import flixel.sound.FlxSound;

class GameplayMusic
{
	static inline var MUSIC = "static/Audio/OST/BreakTheBankloop.mp3";

	var music:FlxSound;
	var active = false;

	public function new()
	{
		FlxG.sound.cache(MUSIC);
		GameSettings.onVolumeChanged(syncVolume);
	}

	public function start():Void
	{
		active = true;

		if (music == null)
		{
			music = FlxG.sound.load(MUSIC, volume(), true, null, false, true);
			if (music != null)
				music.persist = true;
			return;
		}

		music.volume = volume();
		if (!music.playing)
			music.play(true);
	}

	public function stop():Void
	{
		active = false;

		if (music == null)
			return;

		music.stop();
	}

	function volume():Float
	{
		return MusicVolume.gameplayVolume();
	}

	function syncVolume():Void
	{
		if (!active || music == null || !music.playing)
			return;

		music.volume = volume();
	}
}
