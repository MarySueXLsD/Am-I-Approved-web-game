package;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

typedef CopyPaperBuild = {
	var graphic:BitmapData;
	var docNormX:Float;
	var docNormY:Float;
	var docNormW:Float;
	var docNormH:Float;
}

class CopyPaperCompositor
{
	public static inline var PAPER_LARGE_HORIZONTAL_PATH = "static/copy_paper_large_horizontal.png";
	public static inline var PAPER_LARGE_VERTICAL_PATH = "static/copy_paper_large_vertical.png";

	// Portrait printable area; right edge stays left of the COPY stamp.
	static inline var PRINT_LEFT_NORM = 0.04;
	static inline var PRINT_TOP_NORM = 0.06;
	static inline var PRINT_RIGHT_NORM = 0.90;
	static inline var PRINT_BOTTOM_NORM = 0.93;
	static inline var DOCUMENT_SCALE_BOOST = 1.12;
	static inline var MAX_FILL_NORM = 0.92;
	// Landscape: smaller scan, centered on the sheet (paper display size unchanged).
	static inline var HORIZONTAL_PRINT_LEFT_NORM = 0.14;
	static inline var HORIZONTAL_PRINT_TOP_NORM = 0.16;
	static inline var HORIZONTAL_PRINT_RIGHT_NORM = 0.18;
	static inline var HORIZONTAL_PRINT_BOTTOM_NORM = 0.16;
	static inline var HORIZONTAL_DOCUMENT_SCALE_BOOST = 0.86;
	static inline var HORIZONTAL_MAX_FILL_NORM = 0.72;
	// Landscape paper reads larger at equal pixel area; nudge down to match portrait visually.
	static inline var HORIZONTAL_OPEN_SCALE = 0.93;

	public static function getLargePaperPath(source:DeskDocument):String
	{
		if (Std.downcast(source, Passport) != null)
			return PAPER_LARGE_VERTICAL_PATH;

		var docBmp = Assets.getBitmapData(source.getOpenGraphicPath());
		return docBmp.width >= docBmp.height ? PAPER_LARGE_HORIZONTAL_PATH : PAPER_LARGE_VERTICAL_PATH;
	}

	public static function getOpenDisplayScale(employerW:Float, openEmployerWidthRatio:Float, isHorizontalPaper:Bool):Float
	{
		var vertical = Assets.getBitmapData(PAPER_LARGE_VERTICAL_PATH);
		var refTargetWidth = employerW * openEmployerWidthRatio;
		var s = refTargetWidth / vertical.width;
		return isHorizontalPaper ? s * HORIZONTAL_OPEN_SCALE : s;
	}

	public static function loadLargePaperBitmap(path:String):BitmapData
	{
		var vertical = Assets.getBitmapData(PAPER_LARGE_VERTICAL_PATH);
		var targetW = path == PAPER_LARGE_HORIZONTAL_PATH ? vertical.height : vertical.width;
		var targetH = path == PAPER_LARGE_HORIZONTAL_PATH ? vertical.width : vertical.height;
		var src = Assets.getBitmapData(path);
		if (src.width == targetW && src.height == targetH)
			return src.clone();

		var result = new BitmapData(targetW, targetH, true, 0x00000000);
		var matrix = new Matrix(targetW / src.width, 0, 0, targetH / src.height, 0, 0);
		result.draw(src, matrix);
		return result;
	}

	public static function buildLargeCopy(source:DeskDocument):CopyPaperBuild
	{
		var paperPath = getLargePaperPath(source);
		var isHorizontal = paperPath == PAPER_LARGE_HORIZONTAL_PATH;
		var result = loadLargePaperBitmap(paperPath);

		var docPath = source.getOpenGraphicPath();
		var docBmp = Assets.getBitmapData(docPath);
		var printRect = getPrintRect(result.width, result.height, isHorizontal);
		var placement = drawDocumentGrayed(result, docBmp, printRect, isHorizontal);

		return {
			graphic: result,
			docNormX: placement.x / result.width,
			docNormY: placement.y / result.height,
			docNormW: placement.width / result.width,
			docNormH: placement.height / result.height
		};
	}

	static function getPrintRect(paperW:Int, paperH:Int, isHorizontal:Bool):Rectangle
	{
		if (isHorizontal)
		{
			var x = Std.int(paperW * HORIZONTAL_PRINT_LEFT_NORM);
			var y = Std.int(paperH * HORIZONTAL_PRINT_TOP_NORM);
			var w = Std.int(paperW * (1 - HORIZONTAL_PRINT_LEFT_NORM - HORIZONTAL_PRINT_RIGHT_NORM));
			var h = Std.int(paperH * (1 - HORIZONTAL_PRINT_TOP_NORM - HORIZONTAL_PRINT_BOTTOM_NORM));
			return new Rectangle(x, y, w, h);
		}

		var x = Std.int(paperW * PRINT_LEFT_NORM);
		var y = Std.int(paperH * PRINT_TOP_NORM);
		var r = Std.int(paperW * PRINT_RIGHT_NORM);
		var b = Std.int(paperH * PRINT_BOTTOM_NORM);
		return new Rectangle(x, y, r - x, b - y);
	}

	static function drawDocumentGrayed(dest:BitmapData, doc:BitmapData, printRect:Rectangle, isHorizontal:Bool):Rectangle
	{
		var scaleBoost = isHorizontal ? HORIZONTAL_DOCUMENT_SCALE_BOOST : DOCUMENT_SCALE_BOOST;
		var maxFill = isHorizontal ? HORIZONTAL_MAX_FILL_NORM : MAX_FILL_NORM;
		var fitScale = Math.min(printRect.width / doc.width, printRect.height / doc.height);
		var scale = fitScale * scaleBoost;
		var maxScale = Math.min(dest.width * maxFill / doc.width, dest.height * maxFill / doc.height);
		if (scale > maxScale)
			scale = maxScale;

		var drawW = Std.int(doc.width * scale);
		var drawH = Std.int(doc.height * scale);
		var drawX = isHorizontal
			? Std.int((dest.width - drawW) * 0.5)
			: Std.int(printRect.x + (printRect.width - drawW) * 0.5);
		var drawY = isHorizontal
			? Std.int((dest.height - drawH) * 0.5)
			: Std.int(printRect.y + (printRect.height - drawH) * 0.5);
		var placement = new Rectangle(drawX, drawY, drawW, drawH);

		var scaled = new BitmapData(drawW, drawH, true, 0x00000000);
		var matrix = new Matrix(scale, 0, 0, scale, 0, 0);
		scaled.draw(doc, matrix);

		for (py in 0...drawH)
		{
			for (px in 0...drawW)
			{
				var src = scaled.getPixel32(px, py);
				var a = (src >>> 24) & 0xFF;
				if (a < 12)
					continue;

				var blended = blendPhotocopyPixel(dest.getPixel32(drawX + px, drawY + py), toPhotocopyTone(src));
				dest.setPixel32(drawX + px, drawY + py, blended);
			}
		}

		return placement;
	}

	static function toPhotocopyTone(argb:Int):Int
	{
		var a = (argb >>> 24) & 0xFF;
		if (a < 12)
			return 0;

		var r = (argb >> 16) & 0xFF;
		var g = (argb >> 8) & 0xFF;
		var b = argb & 0xFF;
		var lum = r * 0.299 + g * 0.587 + b * 0.114;
		var gray = Std.int(lum * 0.7 + 72);
		gray = Std.int(Math.min(210, Math.max(55, gray)));
		return (Std.int(a * 0.9) << 24) | (gray << 16) | (gray << 8) | gray;
	}

	static function blendPhotocopyPixel(dest:Int, src:Int):Int
	{
		var sa = (src >>> 24) & 0xFF;
		if (sa == 0)
			return dest;

		var sr = (src >> 16) & 0xFF;
		var sg = (src >> 8) & 0xFF;
		var sb = src & 0xFF;
		var dr = (dest >> 16) & 0xFF;
		var dg = (dest >> 8) & 0xFF;
		var db = dest & 0xFF;
		var t = sa / 255.0;

		var nr = Std.int(dr * (1 - t) + sr * t);
		var ng = Std.int(dg * (1 - t) + sg * t);
		var nb = Std.int(db * (1 - t) + sb * t);
		return 0xFF000000 | (nr << 16) | (ng << 8) | nb;
	}
}
