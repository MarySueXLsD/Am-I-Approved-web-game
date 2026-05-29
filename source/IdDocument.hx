package;

import flixel.group.FlxGroup;
import flixel.text.FlxText;

class IdDocument extends DeskDocument
{
	static inline var PREVIEW_PATH = "static/preview_ID.png";
	static inline var CLOSEUP_PATH = "static/closeup_ID.png";
	static inline var OPEN_SIZE_MULTIPLIER = 6;
	static inline var DOCUMENT_FONT_SIZE = 11;
	var textLayer:FlxGroup;
	var infoText:FlxText;
	var citizen:Citizen;
	var textShown = false;

	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		super(zones, layer, PREVIEW_PATH, CLOSEUP_PATH, OPEN_SIZE_MULTIPLIER, false);
		textLayer = layer;
		infoText = new FlxText(0, 0, 0, "");
		infoText.visible = false;
		layer.add(infoText);
	}

	public function getCitizenForCopy():Citizen
	{
		return citizen;
	}

	public function getOverlayText():String
	{
		return infoText.text;
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		if (c == null)
		{
			infoText.text = "";
			return;
		}
		var doc = c.idCardDoc;
		infoText.text = "National ID: " + doc.nationalId
			+ "\nSurname: " + doc.lastName
			+ "\nName: " + doc.firstName
			+ "\nDate of birth: " + doc.dateOfBirth
			+ "\nSex: " + doc.sex
			+ "\nAddress: " + doc.address.street + ", " + doc.address.city;
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		textLayer.remove(infoText, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		target.add(infoText);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		syncTextCameras();
		if (!scanLocked)
			updateOverlayText();
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (locked)
		{
			infoText.visible = false;
			infoText.clipRect = null;
		}
	}

	function updateOverlayText():Void
	{
		var shouldShow = isOpen && citizen != null;
		if (textShown != shouldShow)
		{
			textShown = shouldShow;
			infoText.visible = shouldShow;
		}
		if (!shouldShow)
		{
			infoText.clipRect = null;
			return;
		}

		ensureTextOnTop();
		var fontSize = DOCUMENT_FONT_SIZE;
		infoText.setFormat(null, fontSize, 0xFF1A1A1A, "left");
		infoText.setBorderStyle(NONE, 0x00000000, 0);
		infoText.bold = false;
		infoText.fieldWidth = width * 0.66;
		infoText.setPosition(x + width * 0.31, y + height * 0.12);
		syncOverlayClip(infoText);
	}

	function ensureTextOnTop():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;
		var spriteIndex = textLayer.members.indexOf(this);
		var textIndex = textLayer.members.indexOf(infoText);
		if (spriteIndex < 0 || textIndex < 0)
			return;
		if (textIndex > spriteIndex)
			return;
		textLayer.remove(infoText, true);
		textLayer.add(infoText);
	}

	function syncTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [flixel.FlxG.camera];
		infoText.cameras = cams.copy();
	}
}
