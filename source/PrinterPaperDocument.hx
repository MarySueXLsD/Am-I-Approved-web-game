package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.display.BitmapData;

enum CopyTextStyle
{
	PassportLayout;
	IdCardLayout;
}

class PrinterPaperDocument extends DeskDocument
{
	static inline var SMALL_PATH = "static/copy_paper_small.png";
	static inline var OPEN_SIZE_MULTIPLIER = 4.8;
	static inline var OPEN_EMPLOYER_WIDTH_RATIO = 0.45;
	static inline var COPY_FONT_SIZE = 8;
	static inline var COPY_TEXT_COLOR = 0xFF5A5A5A;

	public var onPickedUp:Void->Void;
	var hasBeenPickedUp = false;
	var scanComposite:BitmapData;
	var copyText:FlxText;
	var textLayer:FlxGroup;
	var copyTextStyle:CopyTextStyle;
	var docNormX = 0.0;
	var docNormY = 0.0;
	var docNormW = 1.0;
	var docNormH = 1.0;
	var copyTextReady = false;
	var copyTextShown = false;
	var largePaperPath:String;

	public function new(zones:LayoutZones, layer:FlxGroup, ?scannedFrom:DeskDocument = null)
	{
		largePaperPath = scannedFrom != null
			? CopyPaperCompositor.getLargePaperPath(scannedFrom)
			: CopyPaperCompositor.PAPER_LARGE_HORIZONTAL_PATH;
		super(zones, layer, SMALL_PATH, largePaperPath, OPEN_SIZE_MULTIPLIER, false);
		textLayer = layer;

		copyText = new FlxText(0, 0, 0, "");
		copyText.visible = false;
		layer.add(copyText);

		if (scannedFrom != null)
		{
			var built = CopyPaperCompositor.buildLargeCopy(scannedFrom);
			scanComposite = built.graphic;
			docNormX = built.docNormX;
			docNormY = built.docNormY;
			docNormW = built.docNormW;
			docNormH = built.docNormH;
			setCustomOpenGraphic(scanComposite);
			initCopyTextFromSource(scannedFrom);
		}

		closedDisplayWidth = zones.leftW * 0.22;
		applyDisplaySize();
		setZoneAngles(-12.0, -6.0, -12.0, -12.0, -12.0, -12.0);
		angle = 0;
	}

	function initCopyTextFromSource(source:DeskDocument):Void
	{
		var passport = Std.downcast(source, Passport);
		if (passport != null)
		{
			copyTextStyle = PassportLayout;
			copyText.text = passport.getOverlayText();
			copyTextReady = copyText.text.length > 0;
			return;
		}

		var idDoc = Std.downcast(source, IdDocument);
		if (idDoc != null)
		{
			copyTextStyle = IdCardLayout;
			copyText.text = idDoc.getOverlayText();
			copyTextReady = copyText.text.length > 0;
		}
	}

	override function update(elapsed:Float):Void
	{
		if (isShredLocked())
		{
			syncCopyTextCameras();
			copyText.visible = false;
			return;
		}

		super.update(elapsed);
		syncCopyTextCameras();
		updateCopyTextOverlay();
	}

	override public function lockForShredder():Void
	{
		super.lockForShredder();
		copyText.visible = false;
	}

	public function finishShredder():Void
	{
		copyText.visible = false;
		if (textLayer != null && textLayer.members.indexOf(copyText) >= 0)
			textLayer.remove(copyText, true);
		if (layer != null && layer.members.indexOf(this) >= 0)
			layer.remove(this, true);
		destroy();
	}

	override function usesZoneAngleWhenClosed():Bool
	{
		return false;
	}

	override function applyDisplaySize():Void
	{
		if (frameWidth <= 0)
			return;

		var s = isOpen
			? CopyPaperCompositor.getOpenDisplayScale(zones.employerW, OPEN_EMPLOYER_WIDTH_RATIO, largePaperPath == CopyPaperCompositor.PAPER_LARGE_HORIZONTAL_PATH)
			: closedDisplayWidth / frameWidth;
		scale.set(s, s);
		updateHitbox();
	}

	override function setOpen():Void
	{
		if (isOpen)
		{
			clearEmployerClip();
			ensureOpenGraphic();
			return;
		}

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = true;
		if (scanComposite != null)
			loadGraphic(scanComposite.clone());
		else
			loadGraphic(CopyPaperCompositor.loadLargePaperBitmap(largePaperPath));
		applyDisplaySize();
		angle = 0;
		placeAfterResize(cx, cy);
		copyTextShown = false;
		notifyDrawLayerChanged();
	}

	function ensureOpenGraphic():Void
	{
		if (frameWidth > Std.int(closedDisplayWidth * 1.5))
			return;

		if (scanComposite != null)
			loadGraphic(scanComposite.clone());
		else
			loadGraphic(CopyPaperCompositor.loadLargePaperBitmap(largePaperPath));
		applyDisplaySize();
	}

	override function setClosed():Void
	{
		if (!isOpen)
			return;

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = false;
		loadGraphic(SMALL_PATH);
		applyDisplaySize();
		angle = getAngleForZone(activeZone);
		placeAfterResize(cx, cy);
		copyTextShown = false;
		copyText.visible = false;
		copyText.clipRect = null;
		notifyDrawLayerChanged();
	}

	override function startDrag(mouseX:Float, mouseY:Float, ?centerGrab:Bool = false):Void
	{
		notifyPickedUp();
		super.startDrag(mouseX, mouseY, centerGrab);
	}

	public function beginPickupDrag(mouseX:Float, mouseY:Float):Void
	{
		notifyPickedUp();
		startDragFromExternal(mouseX, mouseY, true);
	}

	function updateCopyTextOverlay():Void
	{
		if (!copyTextReady)
		{
			copyText.visible = false;
			return;
		}

		var shouldShow = isOpen;
		if (shouldShow != copyTextShown)
		{
			copyTextShown = shouldShow;
			copyText.visible = shouldShow;
		}

		if (!shouldShow)
		{
			copyText.clipRect = null;
			return;
		}

		syncCopyTextLayerOrder();

		copyText.setFormat(null, COPY_FONT_SIZE, COPY_TEXT_COLOR, "left");
		copyText.setBorderStyle(NONE, 0x00000000, 0);
		copyText.bold = false;
		copyText.alpha = 0.88;

		var docX = x + width * docNormX;
		var docY = y + height * docNormY;
		var docW = width * docNormW;
		var docH = height * docNormH;

		switch (copyTextStyle)
		{
			case PassportLayout:
				copyText.fieldWidth = docW * 0.37;
				copyText.setPosition(docX + docW * 0.595, docY + docH * 0.085);
			case IdCardLayout:
				copyText.fieldWidth = docW * 0.66;
				copyText.setPosition(docX + docW * 0.31, docY + docH * 0.12);
		}

		syncOverlayClip(copyText);
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		textLayer.remove(copyText, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		syncCopyTextLayerOrder();
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		syncCopyTextLayerOrder();
	}

	function syncCopyTextLayerOrder():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		var targetIndex = spriteIndex + 1;
		var textIndex = textLayer.members.indexOf(copyText);
		if (textIndex == targetIndex)
			return;

		if (textIndex >= 0)
			textLayer.remove(copyText, true);

		textLayer.insert(targetIndex, copyText);
	}

	function syncCopyTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [FlxG.camera];
		copyText.cameras = cams.copy();
	}

	function notifyPickedUp():Void
	{
		if (hasBeenPickedUp)
			return;
		hasBeenPickedUp = true;
		if (onPickedUp != null)
			onPickedUp();
	}
}
