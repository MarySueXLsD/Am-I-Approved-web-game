package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.display.BitmapData;
import openfl.utils.Assets;

class Passport extends DeskDocument
{
	static inline var CLOSED_PATH = "static/closed_passport.png";
	static inline var OPEN_PATH = "static/lorian_open_passport.png";
	static inline var OPEN_SIZE_MULTIPLIER = 9.0;
	static inline var DOCUMENT_FONT_SIZE = 11;
	static inline var COPY_FONT_SIZE_SCALE = 1.85;

	var textLayer:FlxGroup;
	var photoSprite:FlxSprite;
	var photoGraphic:BitmapData;
	var fieldValues:Array<FlxText>;
	var photoShown = false;
	var textsShown = false;
	var citizen:Citizen;
	var layout:PassportLayout;

	public function new(zones:LayoutZones, layer:FlxGroup)
	{
		layout = PassportLayouts.lorian();
		super(zones, layer, CLOSED_PATH, OPEN_PATH, OPEN_SIZE_MULTIPLIER);
		textLayer = layer;

		photoSprite = new FlxSprite();
		photoSprite.visible = false;
		photoSprite.antialiasing = false;
		layer.add(photoSprite);

		fieldValues = [];
		for (slot in layout.fields)
		{
			var value = new FlxText(0, 0, 0, "");
			value.visible = false;
			fieldValues.push(value);
			layer.add(value);
		}
	}

	public function getLayout():PassportLayout
	{
		return layout;
	}

	public function getCitizenForCopy():Citizen
	{
		return citizen;
	}

	public function getOverlayText():String
	{
		if (citizen == null)
			return "";
		var lines:Array<String> = [];
		for (slot in layout.fields)
			lines.push(PassportLayouts.fieldValue(citizen, slot.kind));
		return lines.join("\n");
	}

	public static function layoutCopyPhotoOverlay(layout:PassportLayout, photo:FlxSprite, docX:Float, docY:Float, docW:Float, docH:Float):Void
	{
		var frame = Assets.getBitmapData(layout.openPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		photo.origin.set(0, 0);
		photo.scale.set(sx, sy);
		photo.updateHitbox();
		photo.angle = 0;
		photo.setPosition(docX + layout.photoX * sx, docY + layout.photoY * sy);
	}

	public static function layoutCopyFieldOverlays(
		layout:PassportLayout,
		fields:Array<FlxText>,
		docX:Float,
		docY:Float,
		docW:Float,
		docH:Float,
		textColor:Int,
		?baseFontSize:Null<Int>
	):Void
	{
		var frame = Assets.getBitmapData(layout.openPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		var fontSize = baseFontSize != null ? baseFontSize : Std.int(Math.max(7, DOCUMENT_FONT_SIZE * sy * COPY_FONT_SIZE_SCALE));

		for (i in 0...layout.fields.length)
		{
			var slot = layout.fields[i];
			var value = fields[i];
			var slotFontSize = slot.fontSize != null ? slot.fontSize : fontSize;
			var fieldWidth = slot.width != null ? slot.width * sx : docW - slot.x * sx;

			value.clearFormats();
			value.setFormat(null, slotFontSize, textColor, "left");
			value.setBorderStyle(NONE, 0x00000000, 0);
			value.bold = false;
			value.fieldWidth = fieldWidth;
			value.setPosition(docX + slot.x * sx, docY + slot.y * sy);
		}
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		rebuildPhotoGraphic();
		if (c == null)
		{
			for (value in fieldValues)
				value.text = "";
			return;
		}

		for (i in 0...fieldValues.length)
			fieldValues[i].text = PassportLayouts.fieldValue(c, layout.fields[i].kind);
	}

	function rebuildPhotoGraphic():Void
	{
		if (photoGraphic != null)
		{
			photoGraphic.dispose();
			photoGraphic = null;
		}

		if (citizen == null)
			return;

		photoGraphic = ClientPhotoCompositor.buildGrayPortrait(Std.int(layout.photoW), Std.int(layout.photoH),
			ClientPortraits.pathForCitizen(citizen));
		photoSprite.loadGraphic(photoGraphic, false);
		photoSprite.updateHitbox();
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		if (isOpen && citizen != null)
			ensureOverlaysOnTop();
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		for (value in fieldValues)
			textLayer.remove(value, true);
		textLayer.remove(photoSprite, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		target.add(photoSprite);
		for (value in fieldValues)
			target.add(value);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (isStoredInLoanFolder())
		{
			for (value in fieldValues)
				value.visible = false;
			photoSprite.visible = false;
			return;
		}
		syncTextCameras();
		if (!scanLocked)
			updateTextOverlays();
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (!locked)
			return;

		for (value in fieldValues)
		{
			value.visible = false;
			value.clipRect = null;
		}
		photoSprite.visible = false;
		photoSprite.clipRect = null;
	}

	function updateTextOverlays():Void
	{
		if (DeskDocument.blocksOverlayUpdates())
		{
			textsShown = false;
			photoShown = false;
			for (value in fieldValues)
			{
				value.visible = false;
				value.clipRect = null;
			}
			photoSprite.visible = false;
			photoSprite.clipRect = null;
			return;
		}

		if (isOpenOnEmployerTable())
			refreshEmployerTableClip();

		var shouldShow = isOpen && citizen != null;
		if (shouldShow && isOpenOnEmployerTable() && !hasEmployerClipReady())
			shouldShow = false;

		if (photoShown != shouldShow)
		{
			photoShown = shouldShow;
			photoSprite.visible = shouldShow;
		}

		if (shouldShow != textsShown)
		{
			textsShown = shouldShow;
			for (value in fieldValues)
				value.visible = shouldShow;
		}

		if (!shouldShow)
		{
			for (value in fieldValues)
				value.clipRect = null;
			photoSprite.clipRect = null;
			return;
		}

		ensureOverlaysOnTop();

		var sx = frameWidth > 0 ? width / frameWidth : 1.0;
		var sy = frameHeight > 0 ? height / frameHeight : 1.0;

		photoSprite.setPosition(x + layout.photoX * sx, y + layout.photoY * sy);
		photoSprite.scale.set(sx, sy);
		photoSprite.updateHitbox();
		syncOverlayClip(photoSprite);

		for (i in 0...fieldValues.length)
		{
			var slot = layout.fields[i];
			var value = fieldValues[i];
			var slotFontSize = slot.fontSize != null ? slot.fontSize : DOCUMENT_FONT_SIZE;
			var fieldWidth = slot.width != null ? slot.width * sx : width - slot.x * sx;

			value.setFormat(null, slotFontSize, layout.valueColor, "left");
			value.setBorderStyle(NONE, 0x00000000, 0);
			value.bold = false;
			value.fieldWidth = fieldWidth;
			value.setPosition(x + slot.x * sx, y + slot.y * sy);
			syncOverlayClip(value);
		}
	}

	function ensureOverlaysOnTop():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		textLayer.remove(photoSprite, true);
		for (value in fieldValues)
			textLayer.remove(value, true);
		textLayer.add(photoSprite);
		for (value in fieldValues)
			textLayer.add(value);
	}

	function syncTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [flixel.FlxG.camera];
		photoSprite.cameras = cams.copy();
		for (value in fieldValues)
			value.cameras = cams.copy();
	}
}
