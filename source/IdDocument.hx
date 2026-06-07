package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.display.BitmapData;
import openfl.utils.Assets;

@:access(flixel.text.FlxText)
class IdDocument extends DeskDocument
{
	static inline var OPEN_SIZE_MULTIPLIER = 6;
	static inline var DOCUMENT_FONT_SIZE = 11;
	static inline var FIELD_SCAN_PAD = 3.0;
	static inline var COPY_FONT_SIZE_SCALE = 1.85;
	static inline var COPY_LINE_SPACING_SCALE = 0.85;
	static inline var COPY_LINE_EXTRA_LEADING = 1;

	var textLayer:FlxGroup;
	var photoSprite:FlxSprite;
	var photoGraphic:BitmapData;
	var emblemSprite:FlxSprite;
	var emblemGraphic:BitmapData;
	var photoShown = false;
	var emblemShown = false;
	var fieldLabels:Array<FlxText>;
	var fieldValues:Array<FlxText>;
	var nationalityValue:Null<FlxText>;
	var citizen:Citizen;
	var textShown = false;
	var variant:IdCardVariant;
	var layout:IdCardLayout;

	public function new(zones:LayoutZones, layer:FlxGroup, variant:IdCardVariant)
	{
		this.variant = variant;
		layout = IdCardLayouts.get(variant);
		super(zones, layer, layout.closeupPath, layout.closeupPath, OPEN_SIZE_MULTIPLIER, false);
		textLayer = layer;

		photoSprite = new FlxSprite();
		photoSprite.visible = false;
		photoSprite.antialiasing = false;
		layer.add(photoSprite);

		emblemSprite = new FlxSprite();
		emblemSprite.visible = false;
		emblemSprite.antialiasing = false;
		if (layout.emblem != null)
			rebuildEmblemGraphic();
		layer.add(emblemSprite);

		fieldLabels = [];
		fieldValues = [];
		for (i in 0...4)
		{
			var label = new FlxText(0, 0, 0, layout.fields[i].label);
			label.visible = false;
			fieldLabels.push(label);
			layer.add(label);

			var value = new FlxText(0, 0, 0, "");
			value.visible = false;
			fieldValues.push(value);
			layer.add(value);
		}

		if (layout.nationality != null)
		{
			nationalityValue = new FlxText(0, 0, 0, "");
			nationalityValue.visible = false;
			layer.add(nationalityValue);
		}
	}

	public function getVariant():IdCardVariant
	{
		return variant;
	}

	public function getLayout():IdCardLayout
	{
		return layout;
	}

	override public function resolveScanBoundsAt(point:FlxPoint):Null<ScanBounds>
	{
		if (!visible || !hitsPoint(point))
			return null;

		if (isOpen && citizen != null)
		{
			updateOverlayText();
			var partBounds = scanBoundsForPartAt(point);
			if (partBounds != null)
				return partBounds;
		}

		return {
			x: x,
			y: y,
			w: width,
			h: height
		};
	}

	public function getCitizenForCopy():Citizen
	{
		return citizen;
	}

	public function hasCopyEmblem():Bool
	{
		return layout.emblem != null;
	}

	public function hasCopyNationality():Bool
	{
		return layout.nationality != null;
	}

	public function getCopyNationalityText():String
	{
		if (citizen == null || layout.nationality == null)
			return "";
		return citizen.nationality;
	}

	public function getOverlayText():String
	{
		if (citizen == null)
			return "";
		var lines:Array<String> = [];
		for (field in layout.fields)
		{
			var value = IdCardLayouts.fieldValue(citizen, field.kind);
			if (layout.showFieldTitles)
				lines.push(field.label + " " + value);
			else
				lines.push(value);
		}
		return lines.join("\n");
	}

	public static function layoutCopyText(layout:IdCardLayout, text:FlxText, docX:Float, docY:Float, docW:Float, docH:Float, textColor:Int):Void
	{
		var frame = Assets.getBitmapData(layout.closeupPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		var fontSize = Std.int(Math.max(7, DOCUMENT_FONT_SIZE * sy * COPY_FONT_SIZE_SCALE));
		var lineStep = layout.fields.length > 1
			? (layout.fields[1].y - layout.fields[0].y) * sy * COPY_LINE_SPACING_SCALE
			: 52 * sy * COPY_LINE_SPACING_SCALE;
		var leading = Std.int(Math.max(0, lineStep - fontSize * 0.92)) + COPY_LINE_EXTRA_LEADING;

		text.clearFormats();
		text.setFormat(null, fontSize, textColor, "left");
		text.setBorderStyle(NONE, 0x00000000, 0);
		text.bold = false;
		text._defaultFormat.leading = leading;
		text.updateDefaultFormat();

		var first = layout.fields[0];
		text.fieldWidth = docW - first.x * sx;
		text.setPosition(docX + first.x * sx, docY + first.y * sy);
	}

	public static function computeEmblemLayout(layout:IdCardLayout, sx:Float, sy:Float, docW:Int, docH:Int):{drawW:Int, drawH:Int, anchorX:Float, anchorY:Float, angle:Float}
	{
		var emblem = layout.emblem;
		if (emblem == null)
			return {drawW: 0, drawH: 0, anchorX: 0, anchorY: 0, angle: 0};

		return {
			drawW: Std.int(emblem.width * sx),
			drawH: Std.int(emblem.height * sy),
			anchorX: (docW - emblem.marginRight) * sx,
			anchorY: (docH - emblem.marginBottom) * sy,
			angle: emblem.angle
		};
	}

	public static function layoutCopyNationalityText(layout:IdCardLayout, text:FlxText, docX:Float, docY:Float, docW:Float, docH:Float, textColor:Int):Void
	{
		if (layout.nationality == null || layout.fields.length == 0)
			return;

		var nat = layout.nationality;
		var frame = Assets.getBitmapData(layout.closeupPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		var fontSize = Std.int(Math.max(7, DOCUMENT_FONT_SIZE * sy * COPY_FONT_SIZE_SCALE));
		var first = layout.fields[0];
		var lineSpacing = layout.fields.length > 1 ? layout.fields[1].y - layout.fields[0].y : 52;

		text.clearFormats();
		text.setFormat(null, fontSize, textColor, "left");
		text.setBorderStyle(NONE, 0x00000000, 0);
		text.bold = false;
		text.setPosition(
			docX + (first.x + nat.xOffset) * sx,
			docY + (first.y + lineSpacing * 4 + nat.yExtra) * sy
		);
	}

	public static function layoutCopyEmblemOverlay(layout:IdCardLayout, emblem:FlxSprite, docX:Float, docY:Float, docW:Float, docH:Float):Void
	{
		if (layout.emblem == null)
			return;

		var frame = Assets.getBitmapData(layout.closeupPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		var emblemLayout = computeEmblemLayout(layout, sx, sy, frame.width, frame.height);
		var emblemFrame = Assets.getBitmapData(layout.emblem.path);
		var emblemSx = emblemFrame.width > 0 ? sx * layout.emblem.width / emblemFrame.width : sx;
		var emblemSy = emblemFrame.height > 0 ? sy * layout.emblem.height / emblemFrame.height : sy;
		emblem.scale.set(emblemSx, emblemSy);
		emblem.angle = emblemLayout.angle;
		emblem.updateHitbox();
		emblem.origin.set(emblem.frameWidth * 0.5, emblem.frameHeight * 0.5);
		emblem.setPosition(
			docX + emblemLayout.anchorX - emblem.width * 0.5,
			docY + emblemLayout.anchorY - emblem.height * 0.5
		);
	}

	public static function layoutCopyPhotoOverlay(layout:IdCardLayout, photo:FlxSprite, docX:Float, docY:Float, docW:Float, docH:Float):Void
	{
		var frame = Assets.getBitmapData(layout.closeupPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		photo.origin.set(0, 0);
		photo.scale.set(sx, sy);
		photo.updateHitbox();
		photo.angle = 0;
		photo.setPosition(docX + layout.photoX * sx, docY + layout.photoY * sy);
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		rebuildPhotoGraphic();
		if (c == null)
		{
			for (value in fieldValues)
				value.text = "";
			if (nationalityValue != null)
				nationalityValue.text = "";
			return;
		}

		var doc = c.idCardDoc;
		for (i in 0...fieldValues.length)
			fieldValues[i].text = IdCardLayouts.fieldValue(c, layout.fields[i].kind);
		if (nationalityValue != null)
			nationalityValue.text = c.nationality;
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

		var backdrop = ClientPhotoCompositor.samplePhotoBackdrop(layout.closeupPath, layout.photoX, layout.photoY);
		photoGraphic = ClientPhotoCompositor.buildGrayPortrait(Std.int(layout.photoW), Std.int(layout.photoH),
			ClientPortraits.pathForCitizen(citizen), backdrop);
		photoSprite.loadGraphic(photoGraphic, false);
		photoSprite.updateHitbox();
	}

	function rebuildEmblemGraphic():Void
	{
		if (emblemGraphic != null)
		{
			emblemGraphic.dispose();
			emblemGraphic = null;
		}

		if (layout.emblem == null)
			return;

		emblemGraphic = Assets.getBitmapData(layout.emblem.path).clone();
		emblemSprite.loadGraphic(emblemGraphic, false);
		emblemSprite.updateHitbox();
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

		for (text in overlayTexts())
			textLayer.remove(text, true);
		textLayer.remove(photoSprite, true);
		textLayer.remove(emblemSprite, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		target.add(photoSprite);
		if (layout.emblem != null)
			target.add(emblemSprite);
		for (text in overlayTexts())
			target.add(text);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (isStoredInLoanFolder())
		{
			for (text in overlayTexts())
				text.visible = false;
			photoSprite.visible = false;
			emblemSprite.visible = false;
			return;
		}
		syncTextCameras();
		if (!scanLocked)
			updateOverlayText();
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (!locked)
		{
			textShown = false;
			photoShown = false;
			emblemShown = false;
			return;
		}

		for (text in overlayTexts())
		{
			text.visible = false;
			text.clipRect = null;
		}
		photoSprite.visible = false;
		photoSprite.clipRect = null;
		emblemSprite.visible = false;
		emblemSprite.clipRect = null;
	}

	function updateOverlayText():Void
	{
		if (DeskDocument.blocksOverlayUpdates())
		{
			textShown = false;
			photoShown = false;
			emblemShown = false;
			for (text in overlayTexts())
			{
				text.visible = false;
				text.clipRect = null;
			}
			photoSprite.visible = false;
			photoSprite.clipRect = null;
			emblemSprite.visible = false;
			emblemSprite.clipRect = null;
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

		var shouldShowEmblem = shouldShow && layout.emblem != null;
		if (emblemShown != shouldShowEmblem)
		{
			emblemShown = shouldShowEmblem;
			emblemSprite.visible = shouldShowEmblem;
		}

		if (textShown != shouldShow)
		{
			textShown = shouldShow;
			for (text in overlayTexts())
				text.visible = shouldShow;
		}

		if (!shouldShow)
		{
			for (text in overlayTexts())
				text.clipRect = null;
			photoSprite.clipRect = null;
			emblemSprite.clipRect = null;
			return;
		}

		ensureOverlaysOnTop();

		var fontSize = DOCUMENT_FONT_SIZE;
		var valueFontSize = layout.valueFontSize != null ? layout.valueFontSize : fontSize;
		var sx = frameWidth > 0 ? width / frameWidth : 1.0;
		var sy = frameHeight > 0 ? height / frameHeight : 1.0;

		photoSprite.setPosition(x + layout.photoX * sx, y + layout.photoY * sy);
		photoSprite.scale.set(sx, sy);
		photoSprite.updateHitbox();
		syncOverlayClip(photoSprite);

		if (layout.emblem != null)
			layoutEmblemOverlay(sx, sy);

		for (i in 0...fieldValues.length)
		{
			var slot = layout.fields[i];
			var label = fieldLabels[i];
			var value = fieldValues[i];
			var rowY = y + slot.y * sy;
			var rowX = x + slot.x * sx;

			if (layout.showFieldTitles)
			{
				label.setFormat(null, fontSize, layout.labelColor, "left");
				label.setBorderStyle(NONE, 0x00000000, 0);
				label.bold = false;
				label.setPosition(rowX, rowY);
				syncOverlayClip(label);

				value.setFormat(null, valueFontSize, layout.valueColor, "left");
				value.setBorderStyle(NONE, 0x00000000, 0);
				value.bold = false;
				value.setPosition(rowX + label.width + layout.fieldValueGap * sx, rowY);
			}
			else
			{
				value.setFormat(null, valueFontSize, layout.valueColor, "left");
				value.setBorderStyle(NONE, 0x00000000, 0);
				value.bold = false;
				value.setPosition(rowX, rowY);
			}
			syncOverlayClip(value);
		}

		if (nationalityValue != null && layout.nationality != null && layout.fields.length > 0)
		{
			var nat = layout.nationality;
			var first = layout.fields[0];
			var lineSpacing = layout.fields.length > 1 ? layout.fields[1].y - layout.fields[0].y : 52;
			var natX = x + (first.x + nat.xOffset) * sx;
			var natY = y + (first.y + lineSpacing * 4 + nat.yExtra) * sy;
			nationalityValue.setFormat(null, fontSize, nat.color, "left");
			nationalityValue.setBorderStyle(NONE, 0x00000000, 0);
			nationalityValue.bold = false;
			nationalityValue.setPosition(natX, natY);
			syncOverlayClip(nationalityValue);
		}
	}

	function layoutEmblemOverlay(sx:Float, sy:Float):Void
	{
		var emblem = layout.emblem;
		var emblemFrame = Assets.getBitmapData(emblem.path);
		var emblemSx = emblemFrame.width > 0 ? sx * emblem.width / emblemFrame.width : sx;
		var emblemSy = emblemFrame.height > 0 ? sy * emblem.height / emblemFrame.height : sy;
		emblemSprite.scale.set(emblemSx, emblemSy);
		emblemSprite.angle = emblem.angle;
		emblemSprite.updateHitbox();
		emblemSprite.origin.set(emblemSprite.frameWidth * 0.5, emblemSprite.frameHeight * 0.5);
		var anchorX = x + (frameWidth - emblem.marginRight) * sx;
		var anchorY = y + (frameHeight - emblem.marginBottom) * sy;
		emblemSprite.setPosition(anchorX - emblemSprite.width * 0.5, anchorY - emblemSprite.height * 0.5);
		syncOverlayClip(emblemSprite);
	}

	function overlayTexts():Array<FlxText>
	{
		var texts = fieldValues.copy();
		if (layout.showFieldTitles)
			for (label in fieldLabels)
				texts.push(label);
		if (nationalityValue != null)
			texts.push(nationalityValue);
		return texts;
	}

	function scanBoundsForPartAt(point:FlxPoint):Null<ScanBounds>
	{
		for (i in 0...fieldValues.length)
		{
			var bounds = fieldRowScanBounds(i);
			if (bounds != null && pointInScanBounds(point, bounds))
				return bounds;
		}

		if (nationalityValue != null && nationalityValue.visible)
		{
			var natBounds = textScanBounds(nationalityValue);
			if (pointInScanBounds(point, natBounds))
				return natBounds;
		}

		if (photoSprite.visible)
		{
			var photoBounds = overlaySpriteScanBounds(photoSprite);
			if (pointInScanBounds(point, photoBounds))
				return photoBounds;
		}

		return null;
	}

	function fieldRowScanBounds(index:Int):Null<ScanBounds>
	{
		var value = fieldValues[index];
		if (!value.visible)
			return null;

		if (layout.showFieldTitles)
		{
			var label = fieldLabels[index];
			if (label.visible)
				return unionScanBounds(textScanBounds(label), textScanBounds(value));
		}

		return textScanBounds(value);
	}

	function textScanBounds(text:FlxText):ScanBounds
	{
		var glyphW = text.textField.textWidth;
		var glyphH = text.textField.textHeight;
		return {
			x: text.x,
			y: text.y,
			w: glyphW > 0 ? glyphW : text.width,
			h: glyphH > 0 ? glyphH : text.height,
			pad: FIELD_SCAN_PAD
		};
	}

	function overlaySpriteScanBounds(sprite:FlxSprite):ScanBounds
	{
		return {
			x: sprite.x,
			y: sprite.y,
			w: sprite.width,
			h: sprite.height,
			pad: FIELD_SCAN_PAD
		};
	}

	function unionScanBounds(a:ScanBounds, b:ScanBounds):ScanBounds
	{
		var left = Math.min(a.x, b.x);
		var top = Math.min(a.y, b.y);
		var right = Math.max(a.x + a.w, b.x + b.w);
		var bottom = Math.max(a.y + a.h, b.y + b.h);
		return {
			x: left,
			y: top,
			w: right - left,
			h: bottom - top,
			pad: FIELD_SCAN_PAD
		};
	}

	function pointInScanBounds(point:FlxPoint, bounds:ScanBounds):Bool
	{
		return point.x >= bounds.x && point.x < bounds.x + bounds.w
			&& point.y >= bounds.y && point.y < bounds.y + bounds.h;
	}

	function ensureOverlaysOnTop():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		for (overlay in [photoSprite, emblemSprite])
		{
			var overlayIndex = textLayer.members.indexOf(overlay);
			if (overlayIndex >= 0 && overlayIndex <= spriteIndex)
			{
				textLayer.remove(overlay, true);
				textLayer.add(overlay);
			}
		}

		for (text in overlayTexts())
		{
			var textIndex = textLayer.members.indexOf(text);
			if (textIndex < 0)
				continue;
			if (textIndex <= spriteIndex)
			{
				textLayer.remove(text, true);
				textLayer.add(text);
			}
		}
	}

	function syncTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [flixel.FlxG.camera];
		for (text in overlayTexts())
			text.cameras = cams.copy();
		photoSprite.cameras = cams.copy();
		emblemSprite.cameras = cams.copy();
	}
}
