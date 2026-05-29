package;

import flixel.group.FlxGroup;
import flixel.text.FlxText;

class Passport extends DeskDocument
{
	static inline var CLOSED_PATH = "static/closed_passport.png";
	static inline var OPEN_PATH = "static/lorian_open_passport.png";
	static inline var OPEN_SIZE_MULTIPLIER = 9.0;
	static inline var DOCUMENT_FONT_SIZE = 11;

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
		target.add(this);
		target.add(idText);
		target.add(nameText);
	}

	public function getCitizenForCopy():Citizen
	{
		return citizen;
	}

	public function getOverlayText():String
	{
		return idText.text;
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		if (c != null)
		{
			var doc = c.passportDoc;
			idText.text = "Passport ID: " + doc.passportId
				+ "\nNational ID: " + doc.nationalId
				+ "\nSurname: " + doc.lastName
				+ "\nName: " + doc.firstName
				+ "\nDate of birth: " + doc.dateOfBirth
				+ "\nSex: " + doc.sex
				+ "\nAuthority: " + doc.issuingAuthority
				+ "\nDate of expiration: " + doc.dateOfExpiration;
			nameText.text = "";
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		syncTextCameras();
		if (!scanLocked)
			updateTextOverlays();
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (locked)
		{
			idText.visible = false;
			nameText.visible = false;
			idText.clipRect = null;
			nameText.clipRect = null;
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
		{
			idText.clipRect = null;
			nameText.clipRect = null;
			return;
		}

		ensureTextOnTop();

		var fontSize = DOCUMENT_FONT_SIZE;

		idText.setFormat(null, fontSize, 0xFF1A1A1A, "left");
		idText.setBorderStyle(NONE, 0x00000000, 0);
		idText.bold = false;
		idText.fieldWidth = width * 0.37;
		idText.setPosition(x + width * 0.595, y + height * 0.085);
		syncOverlayClip(idText);

		nameText.setFormat(null, fontSize, 0xFF1A1A1A, "left");
		nameText.setBorderStyle(NONE, 0x00000000, 0);
		nameText.bold = false;
		nameText.visible = false;
		nameText.setPosition(x + width * 0.595, y + height * 0.17);
		syncOverlayClip(nameText);
	}

	function ensureTextOnTop():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		var idIndex = textLayer.members.indexOf(idText);
		var nameIndex = textLayer.members.indexOf(nameText);

		if (spriteIndex < 0 || idIndex < 0 || nameIndex < 0)
			return;

		if (idIndex > spriteIndex && nameIndex > spriteIndex)
			return;

		textLayer.remove(idText, true);
		textLayer.remove(nameText, true);
		textLayer.add(idText);
		textLayer.add(nameText);
	}

	function syncTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [flixel.FlxG.camera];
		idText.cameras = cams.copy();
		nameText.cameras = cams.copy();
	}
}
