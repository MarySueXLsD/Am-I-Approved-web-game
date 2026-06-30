package;

import flixel.system.FlxAssets;

class LossyColorShader extends FlxAssets.FlxShader
{
	@:glFragmentSource("
		#pragma header

		float bayer4(vec2 pixel)
		{
			vec2 p = floor(mod(pixel, 4.0));
			return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
		}

		void main(void)
		{
			vec2 pixel = openfl_TextureCoordv * openfl_TextureSize;
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
			col.rgb += bayer4(pixel) * (1.0 / 64.0);

			col.r = floor(col.r * 15.0 + 0.5) / 15.0;
			col.g = floor(col.g * 15.0 + 0.5) / 15.0;
			col.b = floor(col.b * 7.0 + 0.5) / 7.0;

			gl_FragColor = vec4(col.rgb, col.a);
		}
	")
	public function new()
	{
		super();
	}
}
