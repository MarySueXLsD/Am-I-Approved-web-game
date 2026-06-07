package;

import flixel.FlxG;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;

class GameVisualFilter
{
	static var shader:LossyColorShader;
	static var tagged:Array<FlxCamera> = [];

	public static function install():Void
	{
		if (shader == null)
			shader = new LossyColorShader();
		ensureAllCameras();
	}

	public static function ensureAllCameras():Void
	{
		if (shader == null)
			return;

		for (cam in FlxG.cameras.list)
		{
			if (tagged.indexOf(cam) >= 0)
				continue;

			cam.filters = [new ShaderFilter(shader)];
			tagged.push(cam);
		}
	}
}
