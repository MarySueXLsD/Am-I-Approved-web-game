package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;

class MonitorMenuRow
{
	public var hit:FlxSprite;
	public var label:FlxText;
	public var enabled:Bool;
	var labelColor:Int;
	var dimColor:Int;
	var text:String;
	var _visible = true;

	public var visible(get, set):Bool;

	public function new(labelText:String, enabled:Bool)
	{
		this.text = labelText;
		this.enabled = enabled;
		hit = new FlxSprite();
		label = new FlxText(0, 0, 100, labelText);
		labelColor = MonitorScreenUi.GREEN;
		dimColor = MonitorScreenUi.GREEN_DIM;
	}

	public function layout(x:Float, y:Float, w:Float, h:Float, fontSize:Int, onColor:Int, offColor:Int):Void
	{
		if (w < 1 || h < 1)
			return;

		labelColor = onColor;
		dimColor = offColor;

		hit.setPosition(x, y);
		hit.setGraphicSize(Std.int(w), Std.int(h));
		hit.makeGraphic(Std.int(w), Std.int(h), 0x00000000, true);
		hit.updateHitbox();

		label.setFormat(null, fontSize, enabled ? onColor : offColor, "center");
		label.text = text;
		label.fieldWidth = Std.int(w);
		label.scale.set(1, 1);
		label.setPosition(x, y + (h - fontSize) * 0.5);
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
		return v;
	}

	public function updateHover(mx:Float, my:Float):Void
	{
		if (!visible || !enabled)
		{
			label.color = dimColor;
			return;
		}

		var over = hit.overlapsPoint(new FlxPoint(mx, my));
		label.color = over ? MonitorScreenUi.GREEN_BRIGHT : labelColor;
	}
}
