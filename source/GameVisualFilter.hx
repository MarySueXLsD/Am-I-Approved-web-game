package;

import flixel.FlxCamera;
import flixel.FlxG;
import openfl.filters.ShaderFilter;

class GameVisualFilter
{
	static var shader:LossyColorShader;
	static var tagged:Array<FlxCamera> = [];
	static var excluded:Array<FlxCamera> = [];
	static var lastCameraCount = -1;

	public static function install():Void
	{
		if (shader == null)
			shader = new LossyColorShader();
		ensureAllCameras();
	}

	public static function excludeCamera(cam:FlxCamera):Void
	{
		if (cam == null || excluded.indexOf(cam) >= 0)
			return;

		excluded.push(cam);
	}

	public static function ensureAllCameras():Void
	{
		if (shader == null)
			return;

		var cameras = FlxG.cameras.list;
		if (cameras.length == lastCameraCount)
			return;

		lastCameraCount = cameras.length;

		for (cam in cameras)
		{
			if (tagged.indexOf(cam) >= 0)
				continue;
			if (excluded.indexOf(cam) >= 0)
				continue;

			cam.filters = [new ShaderFilter(shader)];
			tagged.push(cam);
		}
	}
}
