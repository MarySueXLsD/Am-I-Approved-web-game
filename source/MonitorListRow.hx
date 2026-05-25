package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import haxe.ds.IntMap;

class MonitorListRow
{
	static var idColWidthByFont = new IntMap<Int>();
	public var bg:FlxSprite;
	public var nameLabel:FlxText;
	public var idLabel:FlxText;
	public var dataIndex = -1;
	var lastHovered = false;
	var lastW = -1;
	var lastH = -1;

	public static function idColumnWidth(fontSize:Int):Int
	{
		if (!idColWidthByFont.exists(fontSize))
		{
			var probe = new FlxText(0, 0, 0, "F08E62F05C");
			probe.setFormat(null, fontSize, 0xFFFFFFFF, "left");
			idColWidthByFont.set(fontSize, Std.int(probe.width) + 4);
		}
		return idColWidthByFont.get(fontSize);
	}

	public static function idColumnX(rowX:Float, rowW:Float, fontSize:Int, pad:Int = 6):Float
	{
		return rowX + rowW - pad - idColumnWidth(fontSize);
	}

	public function new()
	{
		bg = new FlxSprite();
		nameLabel = new FlxText(0, 0, 100, "");
		idLabel = new FlxText(0, 0, 100, "");
		bg.visible = false;
		nameLabel.visible = false;
		idLabel.visible = false;
	}

	public function layout(x:Float, y:Float, w:Float, h:Int, citizen:Citizen, fontSize:Int, hovered:Bool):Void
	{
		layoutColumns(x, y, w, h, CitizenRegistry.displayName(citizen), citizen.nationalId, fontSize, hovered, false);
	}

	public function layoutMessage(x:Float, y:Float, w:Float, h:Int, message:String, fontSize:Int, dim:Bool):Void
	{
		bg.setPosition(x, y);
		bg.makeGraphic(Std.int(w), h, 0x00000000, true);
		bg.updateHitbox();
		bg.visible = true;

		nameLabel.setFormat(null, fontSize, dim ? MonitorScreenUi.GREEN_DIM : MonitorScreenUi.GREEN, "center");
		nameLabel.text = message;
		nameLabel.fieldWidth = Std.int(w - 8);
		nameLabel.scale.set(1, 1);
		nameLabel.setPosition(x + 4, y + (h - fontSize) * 0.5);
		nameLabel.visible = true;
		idLabel.text = "";
		idLabel.visible = false;
	}

	function layoutColumns(x:Float, y:Float, w:Float, h:Int, name:String, id:String, fontSize:Int, hovered:Bool,
			dim:Bool):Void
	{
		var pad = 6;
		var idColW = idColumnWidth(fontSize);
		var idColX = x + w - pad - idColW;
		var nameColW = Std.int(idColX - x - pad);
		var rowW = Std.int(w);
		var textY = y + (h - fontSize) * 0.5;
		var color = dim ? MonitorScreenUi.GREEN_DIM : (hovered ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN);

		bg.setPosition(x, y);

		if (hovered != lastHovered || rowW != lastW || h != lastH)
		{
			lastHovered = hovered;
			lastW = rowW;
			lastH = h;
			bg.makeGraphic(rowW, h, hovered ? 0xFF143020 : 0x00000000, true);
			bg.updateHitbox();
		}

		nameLabel.setFormat(null, fontSize, color, "left");
		nameLabel.text = name;
		nameLabel.fieldWidth = nameColW;
		nameLabel.scale.set(1, 1);
		nameLabel.setPosition(x + pad, textY);
		nameLabel.visible = true;

		idLabel.setFormat(null, fontSize, color, "right");
		idLabel.text = id;
		idLabel.fieldWidth = idColW;
		idLabel.scale.set(1, 1);
		idLabel.setPosition(idColX, textY);
		idLabel.visible = id.length > 0;

		bg.visible = true;
	}

	public function overlaps(mx:Float, my:Float):Bool
	{
		return bg.visible && bg.overlapsPoint(new FlxPoint(mx, my));
	}

	public var visible(get, set):Bool;

	function get_visible():Bool
	{
		return bg.visible;
	}

	function set_visible(v:Bool):Bool
	{
		bg.visible = v;
		nameLabel.visible = v;
		if (!v)
			idLabel.visible = false;
		else if (idLabel.text.length > 0)
			idLabel.visible = true;
		return v;
	}
}
