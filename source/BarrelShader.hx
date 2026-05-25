package;

import flixel.system.FlxAssets;

class BarrelShader extends FlxAssets.FlxShader
{
	@:glFragmentSource("
		#pragma header

		void main(void)
		{
			vec2 uv = openfl_TextureCoordv;
			vec2 d = uv - 0.5;
			float r2 = d.x * d.x + d.y * d.y * 0.35;
			vec2 duv = d / (1.0 + 0.35 * r2) + 0.5;

			if (duv.x < 0.0 || duv.x > 1.0 || duv.y < 0.0 || duv.y > 1.0)
			{
				gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
			}
			else
			{
				gl_FragColor = flixel_texture2D(bitmap, duv);
			}
		}
	")
	public function new()
	{
		super();
	}
}
