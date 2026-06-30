package;

import flixel.FlxG;
import flixel.math.FlxMath;

class GameSettings
{
	public static inline var DEFAULT_MASTER_VOLUME = 0.5;
	public static inline var DEFAULT_MUSIC_VOLUME = 0.2;
	public static inline var DEFAULT_SFX_VOLUME = 0.25;

	public static var masterVolume(default, set):Float = DEFAULT_MASTER_VOLUME;
	public static var musicVolume(default, set):Float = DEFAULT_MUSIC_VOLUME;
	public static var sfxVolume(default, set):Float = DEFAULT_SFX_VOLUME;

	static inline var SAVE_ID = "breakthebank";
	static inline var SAVE_PROFILE = "settings";

	static var volumeChangedListeners:Array<Void->Void> = [];
	static var loading = false;

	public static function load():Void
	{
		loading = true;
		FlxG.save.bind(SAVE_ID, SAVE_PROFILE);

		var data = FlxG.save.data;
		if (data.masterVolume != null)
			masterVolume = data.masterVolume;
		if (data.musicVolume != null)
			musicVolume = data.musicVolume;
		if (data.sfxVolume != null)
			sfxVolume = data.sfxVolume;
		if (data.fullscreen != null)
			FlxG.fullscreen = data.fullscreen;

		loading = false;
		apply();
	}

	public static function save():Void
	{
		if (loading)
			return;

		FlxG.save.bind(SAVE_ID, SAVE_PROFILE);
		FlxG.save.data.masterVolume = masterVolume;
		FlxG.save.data.musicVolume = musicVolume;
		FlxG.save.data.sfxVolume = sfxVolume;
		FlxG.save.data.fullscreen = FlxG.fullscreen;
		FlxG.save.flush();
	}

	static function set_masterVolume(v:Float):Float
	{
		masterVolume = FlxMath.bound(v, 0, 1);
		apply();
		notifyVolumeChanged();
		save();
		return masterVolume;
	}

	static function set_musicVolume(v:Float):Float
	{
		musicVolume = FlxMath.bound(v, 0, 1);
		apply();
		notifyVolumeChanged();
		save();
		return musicVolume;
	}

	static function set_sfxVolume(v:Float):Float
	{
		sfxVolume = FlxMath.bound(v, 0, 1);
		apply();
		notifyVolumeChanged();
		save();
		return sfxVolume;
	}

	public static function onVolumeChanged(listener:Void->Void):Void
	{
		volumeChangedListeners.push(listener);
	}

	static function notifyVolumeChanged():Void
	{
		for (listener in volumeChangedListeners)
			listener();
	}

	public static function apply():Void
	{
		FlxG.sound.volume = masterVolume;
		#if FLX_KEYBOARD
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;
		FlxG.sound.muteKeys = null;
		FlxG.sound.soundTrayEnabled = false;
		#end
	}

	public static function toggleFullscreen():Void
	{
		FlxG.fullscreen = !FlxG.fullscreen;
		save();
	}
}
