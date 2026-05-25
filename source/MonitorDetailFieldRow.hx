package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.geom.Rectangle;

class MonitorDetailFieldRow
{
	public var path(default, null):String;
	public var labelText:FlxText;
	public var box:FlxSprite;
	public var valueText:FlxText;
	public var hit:FlxSprite;

	var fieldLabel = "";
	var draft = "";
	var saved = "";
	var fontSize = 12;
	var boxH = 0;
	var lastBoxW = -1;
	var lastBoxH = -1;
	var lastHitW = -1;
	var lastHitH = -1;
	var lastFocused = false;

	public function new()
	{
		labelText = new FlxText(0, 0, 200, "");
		box = new FlxSprite();
		valueText = new FlxText(0, 0, 200, "");
		valueText.wordWrap = false;
		hit = new FlxSprite();
		labelText.scrollFactor.set(0, 0);
		valueText.scrollFactor.set(0, 0);
		box.scrollFactor.set(0, 0);
		hit.scrollFactor.set(0, 0);
		visible = false;
	}

	public function setup(fieldPath:String, label:String, value:String):Void
	{
		if (path == fieldPath)
		{
			saved = value;
			fieldLabel = label;
			return;
		}
		path = fieldPath;
		fieldLabel = label;
		draft = value;
		saved = value;
		lastBoxW = -1;
		lastBoxH = -1;
		lastHitW = -1;
		lastHitH = -1;
		lastFocused = false;
	}

	public function getDraft():String
	{
		return draft;
	}

	public function getSaved():String
	{
		return saved;
	}

	public function setDraft(value:String):Void
	{
		draft = value;
	}

	public function revertDraft():Void
	{
		draft = saved;
	}

	public function commitDraft():Void
	{
		saved = draft;
	}

	public function hasChanges():Bool
	{
		return draft != saved;
	}

	public function layout(x:Float, y:Float, w:Float, textSize:Int, isFocused:Bool):Void
	{
		fontSize = textSize;
		boxH = fontSize + 10;
		var labelH = fontSize;
		var rowGap = 2;
		var labelSize = Std.int(Math.max(10, fontSize - 1));

		labelText.text = fieldLabel;
		labelText.setFormat(null, labelSize, MonitorScreenUi.GREEN_DIM, "left");
		labelText.color = MonitorScreenUi.GREEN_DIM;
		labelText.fieldWidth = Std.int(w);
		labelText.scale.set(1, 1);
		labelText.setPosition(x, y);
		labelText.visible = fieldLabel.length > 0;

		var boxY = y + labelH + rowGap;
		var boxW = Std.int(Math.max(40, w));

		box.setPosition(x, boxY);
		if (boxW != lastBoxW || boxH != lastBoxH || isFocused != lastFocused)
		{
			lastBoxW = boxW;
			lastBoxH = boxH;
			lastFocused = isFocused;
			drawBox(boxW, boxH, isFocused);
		}
		box.visible = true;

		hit.setPosition(x, boxY);
		if (boxW != lastHitW || boxH != lastHitH)
		{
			lastHitW = boxW;
			lastHitH = boxH;
			hit.makeGraphic(boxW, boxH, 0x01000000, true);
			hit.updateHitbox();
		}
		else
			hit.setGraphicSize(boxW, boxH);
		hit.visible = true;

		var textPad = 6;
		var innerW = Std.int(Math.max(20, boxW - textPad * 2));
		valueText.setFormat(null, fontSize, MonitorScreenUi.GREEN, "left");
		valueText.color = MonitorScreenUi.GREEN;
		valueText.fieldWidth = innerW;
		valueText.scale.set(1, 1);
		var showCursor = isFocused && cursorFitsAtEnd(innerW);
		valueText.text = draft + (showCursor ? "_" : "");
		valueText.setPosition(x + textPad, boxY + (boxH - fontSize) * 0.5);
		valueText.visible = true;
	}

	public static function contentHeight(textSize:Int):Int
	{
		return textSize + 2 + (textSize + 10);
	}

	public static function rowHeight(textSize:Int):Int
	{
		return contentHeight(textSize) + 4;
	}

	public static function visibleRowCount(panelH:Float, textSize:Int):Int
	{
		var blockH = contentHeight(textSize);
		var stride = rowHeight(textSize);
		var topPad = 4;
		if (panelH < topPad + blockH)
			return 1;
		return Std.int(Math.max(1, Math.floor((panelH - topPad - blockH) / stride) + 1));
	}

	public function overlaps(mx:Float, my:Float):Bool
	{
		return hit.visible && hit.overlapsPoint(new FlxPoint(mx, my));
	}

	public var visible(get, set):Bool;

	function get_visible():Bool
	{
		return hit.visible;
	}

	function set_visible(v:Bool):Bool
	{
		labelText.visible = v && fieldLabel.length > 0;
		box.visible = v;
		valueText.visible = v;
		hit.visible = v;
		return v;
	}

	function cursorFitsAtEnd(maxW:Int):Bool
	{
		valueText.text = draft + "_";
		return valueText.textField.textWidth <= maxW;
	}

	function drawBox(w:Int, h:Int, isFocused:Bool):Void
	{
		var fill = 0xFF0A120E;
		var border = isFocused ? MonitorScreenUi.GREEN : MonitorScreenUi.GREEN_DIM;
		box.makeGraphic(w, h, fill, true);
		drawRectBorder(box, w, h, border, 1);
		box.updateHitbox();
	}

	function drawRectBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}
}
