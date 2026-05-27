package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.geom.Rectangle;

class MonitorBackButton
{
	public var hit:FlxSprite;
	public var label:FlxText;
	var buttonText:String;
	var hoverTween:FlxTween;
	var btnW = 0;
	var btnH = 0;
	var fontSize = 12;
	var hovered = false;
	var _visible = false;

	public var visible(get, set):Bool;

	public function new(?text:String = "< BACK")
	{
		buttonText = text;
		hit = new FlxSprite();
		label = new FlxText(0, 0, 100, buttonText);
		hit.visible = false;
		label.visible = false;
	}

	public function layout(x:Float, y:Float, w:Float, h:Int, textSize:Int):Void
	{
		if (w < 1 || h < 1)
			return;

		var newW = Std.int(w);
		var sizeChanged = newW != btnW || h != btnH || textSize != fontSize;

		btnW = newW;
		btnH = h;
		fontSize = textSize;

		hit.setPosition(x, y);
		label.setPosition(x, y + (h - fontSize) * 0.5);
		label.fieldWidth = btnW;

		if (sizeChanged)
		{
			hovered = false;
			drawButton(false);
			label.setFormat(null, fontSize, MonitorScreenUi.GREEN, "center");
			label.text = buttonText;
			label.scale.set(1, 1);
			label.color = MonitorScreenUi.GREEN;
		}
	}

	public function reposition(x:Float, y:Float):Void
	{
		hit.setPosition(x, y);
		label.setPosition(x, y + (btnH - fontSize) * 0.5);
	}

	function drawButton(over:Bool):Void
	{
		var fill = over ? 0xFF143020 : 0xFF0D1A12;
		var border = over ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN;
		hit.makeGraphic(btnW, btnH, fill, true);
		drawRectBorder(hit, btnW, btnH, border, 1);
		hit.updateHitbox();
	}

	function drawRectBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}

	public function updateHover(mx:Float, my:Float):Void
	{
		if (!_visible)
			return;

		var over = hit.overlapsPoint(new FlxPoint(mx, my));
		if (over != hovered)
		{
			hovered = over;
			drawButton(over);
		}

		label.color = over ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN;

		var targetScale = over ? 1.06 : 1.0;
		if (Math.abs(label.scale.x - targetScale) > 0.01)
		{
			if (hoverTween != null)
				hoverTween.cancel();
			hoverTween = FlxTween.tween(label.scale, {x: targetScale, y: targetScale}, 0.12, {ease: FlxEase.quadOut});
		}
	}

	function get_visible():Bool
	{
		return _visible;
	}

	function set_visible(v:Bool):Bool
	{
		_visible = v;
		hit.visible = v;
		label.visible = v;
		if (!v)
		{
			hovered = false;
			label.scale.set(1, 1);
			label.color = MonitorScreenUi.GREEN;
		}
		return v;
	}
}
