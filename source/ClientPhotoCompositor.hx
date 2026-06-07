package;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class ClientPhotoCompositor
{
	static inline var CROP_TOP_NORM = 0.52;
	static inline var GRAY_OVERLAY_ALPHA = 0.32;

	public static function samplePhotoBackdrop(closeupPath:String, photoX:Float, photoY:Float):Int
	{
		var frame = Assets.getBitmapData(closeupPath);
		var sx = Std.int(Math.min(frame.width - 1, Math.max(0, photoX + 6)));
		var sy = Std.int(Math.min(frame.height - 1, Math.max(0, photoY + 6)));
		return 0xFF000000 | (frame.getPixel32(sx, sy) & 0x00FFFFFF);
	}

	public static function buildGrayPortrait(outW:Int, outH:Int, ?clientPath:String, ?backdropColor:Int):BitmapData
	{
		if (outW <= 0 || outH <= 0)
			return new BitmapData(1, 1, true, 0x00000000);

		var path = clientPath != null ? clientPath : ClientPortraits.defaultPath();
		var src = Assets.getBitmapData(path);
		var cropH = Std.int(Math.max(1, src.height * CROP_TOP_NORM));
		var cropped = new BitmapData(src.width, cropH, true, 0x00000000);
		cropped.copyPixels(src, new Rectangle(0, 0, src.width, cropH), new Point(0, 0));

		var scale = Math.max(outW / cropped.width, outH / cropped.height);
		var drawW = cropped.width * scale;
		var drawH = cropped.height * scale;
		var drawX = (outW - drawW) * 0.5;
		var drawY = (outH - drawH) * 0.5;

		var scaled = new BitmapData(outW, outH, true, 0x00000000);
		var matrix = new Matrix(scale, 0, 0, scale, drawX, drawY);
		scaled.draw(cropped, matrix);

		var fill = backdropColor != null ? (0xFF000000 | (backdropColor & 0x00FFFFFF)) : 0x00000000;
		var result = new BitmapData(outW, outH, true, fill);
		for (py in 0...outH)
		{
			for (px in 0...outW)
			{
				var argb = scaled.getPixel32(px, py);
				var a = (argb >>> 24) & 0xFF;
				if (a < 12)
					continue;
				result.setPixel32(px, py, applyGrayOverlay(toGrayTone(argb)));
			}
		}

		return result;
	}

	public static function buildGrayGraphic(path:String):BitmapData
	{
		var src = Assets.getBitmapData(path);
		var result = new BitmapData(src.width, src.height, true, 0x00000000);
		for (py in 0...src.height)
		{
			for (px in 0...src.width)
			{
				var argb = src.getPixel32(px, py);
				var a = (argb >>> 24) & 0xFF;
				if (a < 12)
					continue;
				result.setPixel32(px, py, applyGrayOverlay(toGrayTone(argb)));
			}
		}
		return result;
	}

	static function toGrayTone(argb:Int):Int
	{
		var a = (argb >>> 24) & 0xFF;
		var r = (argb >> 16) & 0xFF;
		var g = (argb >> 8) & 0xFF;
		var b = argb & 0xFF;
		var lum = r * 0.299 + g * 0.587 + b * 0.114;
		var gray = Std.int(lum * 0.82 + 28);
		gray = Std.int(Math.min(200, Math.max(45, gray)));
		return (a << 24) | (gray << 16) | (gray << 8) | gray;
	}

	static function applyGrayOverlay(argb:Int):Int
	{
		var a = (argb >>> 24) & 0xFF;
		if (a < 12)
			return 0;

		var srcR = (argb >> 16) & 0xFF;
		var srcG = (argb >> 8) & 0xFF;
		var srcB = argb & 0xFF;
		var overlay = 128;
		var t = GRAY_OVERLAY_ALPHA;

		var r = Std.int(srcR * (1 - t) + overlay * t);
		var g = Std.int(srcG * (1 - t) + overlay * t);
		var b = Std.int(srcB * (1 - t) + overlay * t);
		return (a << 24) | (r << 16) | (g << 8) | b;
	}
}
