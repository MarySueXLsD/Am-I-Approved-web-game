package;

import flixel.FlxG;
import flixel.sound.FlxSound;

typedef AmbientClip =
{
	path:String,
	duration:Float,
	?volumeScale:Float,
}

class OfficeAmbientAudio
{
	public static inline var VOLUME_SCALE = 0.25;
	static inline var TYPING_VOLUME_SCALE = 0.32;
	static inline var BLAH_BLAH_VOLUME_SCALE = 1.4;
	static inline var PAPER_WAVING = "static/Audio/Ambient/Paper_Waving_2sec.wav";
	static inline var PRINTER_WORKING = "static/Audio/Ambient/printer_5sec.wav";
	static inline var SCANNER_WORKING = "static/Audio/Ambient/scanner_5sec.wav";
	static inline var MIN_SHORT_GAP = 2.0;
	static inline var MAX_SHORT_GAP = 6.0;

	static var LONG_AMBIENCE:Array<AmbientClip> = [
		{path: "static/Audio/Ambient/Office_Ambience_30sec.wav", duration: 30},
	];

	static var SHORT_CLIPS:Array<AmbientClip> = [
		{path: "static/Audio/Ambient/Heavy_Door_Opening_4sec.wav", duration: 4},
		{path: "static/Audio/Ambient/Office_Chair_Rolling_3sec.wav", duration: 3},
		{path: "static/Audio/Ambient/Office_Chair_Rolling_16sec.wav", duration: 16},
		{path: "static/Audio/Ambient/Computer_Typing_7sec.wav", duration: 7, volumeScale: TYPING_VOLUME_SCALE},
		{path: "static/Audio/Ambient/Man_Nearby_Coughing_13sec.wav", duration: 13},
	];

	static var BLAH_BLAH_CLIPS:Array<AmbientClip> = [
		{path: "static/Audio/Ambient/Blah_Blah_01_1sec.wav", duration: 1},
		{path: "static/Audio/Ambient/Blah_Blah_02_2sec.wav", duration: 2},
		{path: "static/Audio/Ambient/Blah_Blah_03_3sec.wav", duration: 3},
		{path: "static/Audio/Ambient/Blah_Blah_04_2sec.wav", duration: 2},
		{path: "static/Audio/Ambient/Blah_Blah_05_4sec.wav", duration: 4},
		{path: "static/Audio/Ambient/Blah_Blah_06_3sec.wav", duration: 3},
		{path: "static/Audio/Ambient/Blah_Blah_07_5sec.wav", duration: 5},
	];

	var active = false;
	var bedSound:FlxSound;
	var shortCooldown = 0.0;

	public function new()
	{
		for (clip in BLAH_BLAH_CLIPS)
			FlxG.sound.cache(clip.path);

		GameSettings.onVolumeChanged(syncVolumes);
	}

	public function start():Void
	{
		if (active)
			return;

		active = true;
		shortCooldown = FlxG.random.float(1.0, 3.0);
		playRandomBed();
	}

	public function stop():Void
	{
		active = false;
		shortCooldown = 0;
		stopBed();
	}

	public function update(elapsed:Float):Void
	{
		if (!active)
			return;

		if (bedSound != null && !bedSound.playing)
		{
			bedSound = null;
			playRandomBed();
		}

		shortCooldown -= elapsed;
		if (shortCooldown > 0)
			return;

		playRandomShort();
		shortCooldown = FlxG.random.float(MIN_SHORT_GAP, MAX_SHORT_GAP);
	}

	public static function playPaperWavingForDocument(doc:DeskDocument):Void
	{
		if (!isPaperDocument(doc))
			return;

		playSfx(PAPER_WAVING);
	}

	public static function playPrinterWorking():Void
	{
		playSfx(PRINTER_WORKING);
	}

	public static function playScannerWorking():Void
	{
		playSfx(SCANNER_WORKING);
	}

	public static function playRandomBlahBlah():Void
	{
		if (BLAH_BLAH_CLIPS.length == 0)
			return;

		var clip = BLAH_BLAH_CLIPS[FlxG.random.int(0, BLAH_BLAH_CLIPS.length - 1)];
		FlxG.sound.play(clip.path, GameSettings.sfxVolume * BLAH_BLAH_VOLUME_SCALE);
	}

	static function isPaperDocument(doc:DeskDocument):Bool
	{
		return Std.isOfType(doc, PrinterPaperDocument)
			|| Std.isOfType(doc, BankDocument)
			|| Std.isOfType(doc, IdDocument)
			|| Std.isOfType(doc, JobContractDocument);
	}

	static function playSfx(path:String, ?volumeScale:Float = 1.0):Void
	{
		FlxG.sound.play(path, sfxVolume(volumeScale));
	}

	static function sfxVolume(?clipScale:Float = 1.0):Float
	{
		return GameSettings.sfxVolume * VOLUME_SCALE * clipScale;
	}

	function playRandomBed():Void
	{
		if (!active || LONG_AMBIENCE.length == 0)
			return;

		stopBed();
		var clip = LONG_AMBIENCE[FlxG.random.int(0, LONG_AMBIENCE.length - 1)];
		bedSound = FlxG.sound.play(clip.path, sfxVolume(clip.volumeScale));

		if (bedSound == null)
			return;

		bedSound.persist = true;
	}

	function playRandomShort():Void
	{
		if (!active || SHORT_CLIPS.length == 0)
			return;

		var clip = SHORT_CLIPS[FlxG.random.int(0, SHORT_CLIPS.length - 1)];
		FlxG.sound.play(clip.path, sfxVolume(clip.volumeScale));
	}

	function stopBed():Void
	{
		if (bedSound == null)
			return;

		bedSound.stop();
		bedSound = null;
	}

	function syncVolumes():Void
	{
		if (bedSound != null && bedSound.playing)
			bedSound.volume = sfxVolume();
	}
}
