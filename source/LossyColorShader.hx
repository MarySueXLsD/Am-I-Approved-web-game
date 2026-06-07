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
			vec2 blockSize = vec2(1.0);
			vec2 blockOrigin = floor(pixel / blockSize) * blockSize;
			vec2 blockUv = (blockOrigin + blockSize * 0.5) / openfl_TextureSize;
			vec2 cornerUv = blockOrigin / openfl_TextureSize;
			vec2 blockTexel = blockSize / openfl_TextureSize;

			vec4 blockColor = flixel_texture2D(bitmap, blockUv);
			vec4 c0 = flixel_texture2D(bitmap, cornerUv + blockTexel * vec2(0.25, 0.25));
			vec4 c1 = flixel_texture2D(bitmap, cornerUv + blockTexel * vec2(0.75, 0.25));
			vec4 c2 = flixel_texture2D(bitmap, cornerUv + blockTexel * vec2(0.25, 0.75));
			vec4 c3 = flixel_texture2D(bitmap, cornerUv + blockTexel * vec2(0.75, 0.75));
			vec3 col = mix(blockColor.rgb, (c0 + c1 + c2 + c3).rgb * 0.25, 0.2);

			col += bayer4(pixel) * (1.0 / 64.0);

			col.r = floor(col.r * 15.0 + 0.5) / 15.0;
			col.g = floor(col.g * 15.0 + 0.5) / 15.0;
			col.b = floor(col.b * 7.0 + 0.5) / 7.0;

			gl_FragColor = vec4(col, blockColor.a);
		}
	")
	public function new()
	{
		super();
	}
}
