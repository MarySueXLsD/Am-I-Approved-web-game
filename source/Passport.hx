package;

import flixel.group.FlxGroup;
import flixel.text.FlxText;

class Passport extends DeskDocument
{
	static inline var CLOSED_PATH = "static/closed_passport.png";
	static inline var OPEN_PATH = "static/lorian_open_passport.png";
	static inline var OPEN_SIZE_MULTIPLIER = 9.0;

	var idText:FlxText;
	var nameText:FlxText;
	var textLayer:FlxGroup;
	var citizen:Citizen;
	var textsShown = false;

	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		super(zones, layer, CLOSED_PATH, OPEN_PATH, OPEN_SIZE_MULTIPLIER);
		textLayer = layer;

		idText = new FlxText(0, 0, 0, "");
		idText.visible = false;
		layer.add(idText);

		nameText = new FlxText(0, 0, 0, "");
		nameText.visible = false;
		layer.add(nameText);
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		textLayer.remove(idText, true);
		textLayer.remove(nameText, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(idText);
		target.add(nameText);
		target.add(this);
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		if (c != null)
		{
			idText.text = c.passportId;
			nameText.text = c.passportName;
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!scanLocked)
			updateTextOverlays();
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (locked)
		{
			idText.visible = false;
			nameText.visible = false;
		}
	}

	function updateTextOverlays():Void
	{
		var shouldShow = isOpen && citizen != null;

		if (shouldShow != textsShown)
		{
			textsShown = shouldShow;
			idText.visible = shouldShow;
			nameText.visible = shouldShow;
		}

		if (!shouldShow)
			return;

		var fontSize = Std.int(Math.max(14, height * 0.1));

		idText.setFormat(null, fontSize, 0xFF1A1A1A, "left");
		idText.setBorderStyle(OUTLINE, 0xFF1A1A1A, 0.5);
		idText.setPosition(x + width * 0.595, y + height * 0.085);

		nameText.setFormat(null, fontSize, 0xFF1A1A1A, "left");
		nameText.setBorderStyle(OUTLINE, 0xFF1A1A1A, 0.5);
		nameText.setPosition(x + width * 0.595, y + height * 0.17);
	}
}
