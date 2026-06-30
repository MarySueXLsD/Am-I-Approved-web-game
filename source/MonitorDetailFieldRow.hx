package;

import StringTools;
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
	var lastIsDropdown = false;
	var choices:Array<String> = [];
	public var digitsOnly:Bool = false;
	public var allowDecimal:Bool = false;
	public var dateField:Bool = false;
	public var readOnly:Bool = false;

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

	public function setup(fieldPath:String, label:String, value:String, ?fieldChoices:Array<String>,
			?isDigitsOnly:Bool, ?isDateField:Bool, ?isRequired:Bool, ?isReadOnly:Bool, ?decimalAllowed:Bool):Void
	{
		var newChoices = fieldChoices != null ? fieldChoices : [];
		digitsOnly = isDigitsOnly == true;
		allowDecimal = decimalAllowed == true;
		dateField = isDateField == true;
		readOnly = isReadOnly == true;
		var displayLabel = isRequired == true ? '$label *' : label;
		if (path == fieldPath)
		{
			if (draft == saved)
				draft = value;
			saved = value;
			fieldLabel = displayLabel;
			choices = newChoices;
			return;
		}
		path = fieldPath;
		fieldLabel = displayLabel;
		draft = value;
		saved = value;
		choices = newChoices;
		lastBoxW = -1;
		lastBoxH = -1;
		lastHitW = -1;
		lastHitH = -1;
		lastFocused = false;
		lastIsDropdown = false;
	}

	public function isDropdown():Bool
	{
		return choices.length > 0;
	}

	public function getChoices():Array<String>
	{
		return choices;
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

	public static function acceptsNumericChar(code:Int, draft:String, allowDecimal:Bool):Bool
	{
		if (code >= 48 && code <= 57)
			return true;
		if (allowDecimal && code == 46)
			return draft.indexOf(".") < 0;
		return false;
	}

	public static function isValidNumericDraft(text:String, allowDecimal:Bool):Bool
	{
		if (text.length == 0)
			return true;

		if (!allowDecimal)
		{
			for (i in 0...text.length)
			{
				var c = text.charCodeAt(i);
				if (c < 48 || c > 57)
					return false;
			}
			return true;
		}

		var trimmed = StringTools.trim(text);
		if (trimmed.length == 0)
			return false;
		if (trimmed == ".")
			return false;
		if (trimmed.charAt(trimmed.length - 1) == ".")
			return false;

		var dotCount = 0;
		for (i in 0...trimmed.length)
		{
			var c = trimmed.charCodeAt(i);
			if (c == 46)
				dotCount++;
			else if (c < 48 || c > 57)
				return false;
		}
		if (dotCount > 1)
			return false;

		return Std.parseFloat(trimmed) != null;
	}

	public function layout(x:Float, y:Float, w:Float, textSize:Int, isFocused:Bool):Void
	{
		fontSize = textSize;
		boxH = fontSize + 10;
		var rowGap = 2;
		var labelSize = fontSize;

		labelText.text = fieldLabel;
		labelText.setFormat(null, labelSize, MonitorScreenUi.GREEN_DIM, "left");
		labelText.color = MonitorScreenUi.GREEN_DIM;
		labelText.fieldWidth = Std.int(w);
		labelText.wordWrap = true;
		labelText.autoSize = false;
		labelText.scale.set(1, 1);
		labelText.setPosition(x, y);
		labelText.visible = fieldLabel.length > 0;
		labelText.height = labelText.textField.textHeight + 2;
		labelText.updateHitbox();
		var labelH = Std.int(Math.max(fontSize, labelText.textField.textHeight));

		var boxY = y + labelH + rowGap;
		var boxW = Std.int(Math.max(40, w));

		box.setPosition(x, boxY);
		var isDD = choices.length > 0;
		if (boxW != lastBoxW || boxH != lastBoxH || isFocused != lastFocused || isDD != lastIsDropdown)
		{
			lastBoxW = boxW;
			lastBoxH = boxH;
			lastFocused = isFocused;
			lastIsDropdown = isDD;
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
		valueText.wordWrap = false;
		valueText.scale.set(1, 1);
		var showCursor = isFocused && !readOnly && cursorFitsAtEnd(innerW);
		valueText.text = draft + (showCursor ? "_" : "");
		valueText.color = readOnly ? MonitorScreenUi.GREEN_DIM : MonitorScreenUi.GREEN;
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
		return !readOnly && hit.visible && hit.overlapsPoint(new FlxPoint(mx, my));
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

	public function textFits(text:String):Bool
	{
		var textPad = 6;
		var innerW = Std.int(Math.max(20, lastBoxW - textPad * 2));
		valueText.wordWrap = false;
		valueText.fieldWidth = innerW;
		valueText.wordWrap = false;
		valueText.text = text + "_";
		var fits = valueText.textField.textWidth <= innerW;
		valueText.text = draft + (fits ? "_" : "");
		return fits;
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
		if (choices.length > 0)
			drawDropdownArrow(w, h);
		box.updateHitbox();
	}

	function drawDropdownArrow(w:Int, h:Int):Void
	{
		var arrowH = Std.int(Math.max(3, fontSize * 0.35));
		var cx = w - arrowH - 6;
		var cy = Std.int((h - arrowH) * 0.5);

		for (row in 0...arrowH)
		{
			var half = arrowH - 1 - row;
			for (dx in -half...half + 1)
			{
				var px = cx + dx;
				var py = cy + row;
				if (px >= 1 && px < w - 1 && py >= 1 && py < h - 1)
					box.pixels.setPixel32(px, py, MonitorScreenUi.GREEN_DIM);
			}
		}
		box.dirty = true;
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
