package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.display.BitmapData;

enum CopyTextStyle
{
	PassportLayout;
	IdCardLayout;
	BankDocumentStyle;
}

class PrinterPaperDocument extends DeskDocument
{
	static inline var SMALL_PATH = "static/copy_paper_small.png";
	public static inline var CLOSED_ANGLE = -30.0;
	static inline var OPEN_SIZE_MULTIPLIER = 4.8;
	static inline var OPEN_EMPLOYER_WIDTH_RATIO = 0.45;
	static inline var COPY_FONT_SIZE = 8;
	static inline var COPY_TEXT_COLOR = 0xFF5A5A5A;

	public var onPickedUp:Void->Void;
	var hasBeenPickedUp = false;
	var scanComposite:BitmapData;
	var copyText:FlxText;
	var copyNationalityText:FlxText;
	var copyEmblemSprite:FlxSprite;
	var copyEmblemGraphic:BitmapData;
	var copyEmblemGraphicW = -1;
	var copyEmblemGraphicH = -1;
	var copyPhotoSprite:FlxSprite;
	var copyPhotoGraphic:BitmapData;
	var textLayer:FlxGroup;
	var copyTextStyle:CopyTextStyle;
	var docNormX = 0.0;
	var docNormY = 0.0;
	var docNormW = 1.0;
	var docNormH = 1.0;
	var copyTextReady = false;
	var copyNationalityReady = false;
	var copyEmblemReady = false;
	var copyPhotoReady = false;
	var copyTextShown = false;
	var copyNationalityShown = false;
	var copyEmblemShown = false;
	var copyPhotoShown = false;
	var idCardLayout:Null<IdCardLayout> = null;
	var passportLayout:Null<PassportLayout> = null;
	var bankDocumentLayout:Null<BankDocumentLayout> = null;
	var copyPassportFields:Array<FlxText> = [];
	var copyPassportFieldsReady = false;
	var copyPassportFieldsShown = false;
	var copyBankBodyTexts:Array<FlxText> = [];
	var copyBankBodyTextsReady = false;
	var copyBankBodyTextsShown = false;
	var copyBankDocumentFields:Array<FlxText> = [];
	var copyBankDocumentFieldsReady = false;
	var copyBankDocumentFieldsShown = false;
	var largePaperPath:String;
	var storedLargeGraphicLoaded = false;

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

		copyNationalityText = new FlxText(0, 0, 0, "");
		copyNationalityText.visible = false;
		layer.add(copyNationalityText);

		copyEmblemSprite = new FlxSprite();
		copyEmblemSprite.visible = false;
		copyEmblemSprite.antialiasing = false;
		layer.add(copyEmblemSprite);

		copyPhotoSprite = new FlxSprite();
		copyPhotoSprite.visible = false;
		copyPhotoSprite.antialiasing = false;
		layer.add(copyPhotoSprite);

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
		setZoneAngles(CLOSED_ANGLE, CLOSED_ANGLE, CLOSED_ANGLE, CLOSED_ANGLE, CLOSED_ANGLE, CLOSED_ANGLE);
		angle = CLOSED_ANGLE;
	}

	function initCopyTextFromSource(source:DeskDocument):Void
	{
		var passport = Std.downcast(source, Passport);
		if (passport != null)
		{
			copyTextStyle = PassportLayout;
			passportLayout = passport.getLayout();
			copyTextReady = false;
			var citizen = passport.getCitizenForCopy();
			ensureCopyPassportFields();
			for (i in 0...passportLayout.fields.length)
				copyPassportFields[i].text = PassportLayouts.fieldValue(citizen, passportLayout.fields[i].kind);
			copyPassportFieldsReady = citizen != null;
			if (citizen != null)
			{
				copyPhotoReady = true;
				copyPhotoGraphic = ClientPhotoCompositor.buildGrayPortrait(
					Std.int(passportLayout.photoW),
					Std.int(passportLayout.photoH),
					ClientPortraits.pathForCitizen(citizen)
				);
				copyPhotoSprite.loadGraphic(copyPhotoGraphic, false);
				copyPhotoSprite.visible = false;
			}
			return;
		}

		var idDoc = Std.downcast(source, IdDocument);
		if (idDoc != null)
		{
			copyTextStyle = IdCardLayout;
			idCardLayout = idDoc.getLayout();
			copyText.text = idDoc.getOverlayText();
			copyTextReady = copyText.text.length > 0;
			copyNationalityText.text = idDoc.getCopyNationalityText();
			copyNationalityReady = idDoc.hasCopyNationality() && copyNationalityText.text.length > 0;
			copyEmblemReady = idDoc.hasCopyEmblem();
			if (copyEmblemReady)
				rebuildCopyEmblemGraphic();
			if (idDoc.getCitizenForCopy() != null)
			{
				copyPhotoReady = true;
				copyPhotoGraphic = ClientPhotoCompositor.buildGrayPortrait(
					Std.int(idCardLayout.photoW),
					Std.int(idCardLayout.photoH),
					ClientPortraits.pathForCitizen(idDoc.getCitizenForCopy())
				);
				copyPhotoSprite.loadGraphic(copyPhotoGraphic, false);
				copyPhotoSprite.visible = false;
			}
			return;
		}

		var bankDoc = Std.downcast(source, BankDocument);
		if (bankDoc != null)
		{
			copyTextStyle = BankDocumentStyle;
			bankDocumentLayout = bankDoc.getLayout();
			copyTextReady = false;
			var citizen = bankDoc.getCitizenForCopy();
			ensureCopyBankBodyTexts();
			copyBankBodyTextsReady = true;
			ensureCopyBankDocumentFields();
			for (i in 0...bankDocumentLayout.fields.length)
			{
				copyBankDocumentFields[i].text = citizen != null
					? BankDocumentLayouts.fieldValue(citizen, bankDocumentLayout.fields[i].kind)
					: "";
			}
			copyBankDocumentFieldsReady = citizen != null;
		}
	}

	public function matchesLoanChecklistItem(item:LoanChecklistItem):Bool
	{
		switch (item)
		{
			case PassportCopy:
				return copyTextStyle == PassportLayout;
			case NationalIdCopy:
				return copyTextStyle == IdCardLayout;
			case LoanApplicationForm:
				return copyTextStyle == BankDocumentStyle
					&& bankDocumentLayout != null
					&& bankDocumentLayout.title.text == "Loan Application Form";
			case LoanChecklist:
				return isLoanChecklistCopy();
		}
	}

	public function isLoanChecklistCopy():Bool
	{
		return copyTextStyle == BankDocumentStyle
			&& bankDocumentLayout != null
			&& bankDocumentLayout.title.text == "Loan Checklist";
	}

	public function refreshLoanChecklistCompletion(loanId:String, completed:Array<LoanChecklistItem>):Void
	{
		if (!isLoanChecklistCopy())
			return;

		bankDocumentLayout = BankDocumentLayouts.loanChecklist(loanId, completed);
		copyBankBodyTextsShown = false;
		if (isStoredInLoanFolder())
			refreshStoredCopyOverlays();
		else
			updateCopyOverlays();
	}

	override function update(elapsed:Float):Void
	{
		if (isShredLocked())
		{
			syncCopyTextCameras();
			setCopyOverlaysVisible(false);
			return;
		}

		super.update(elapsed);
		syncCopyTextCameras();
		if (isStoredInLoanFolder())
		{
			updateStoredCopyOverlays();
			return;
		}
		updateCopyOverlays();
	}

	override public function lockForShredder():Void
	{
		super.lockForShredder();
		setCopyOverlaysVisible(false);
	}

	override public function finishShredder():Void
	{
		disposeCopyDocument();
	}

	public function disposeCopyDocument():Void
	{
		setCopyOverlaysVisible(false);
		if (textLayer != null && textLayer.members.indexOf(copyText) >= 0)
			textLayer.remove(copyText, true);
		if (textLayer != null && textLayer.members.indexOf(copyNationalityText) >= 0)
			textLayer.remove(copyNationalityText, true);
		if (textLayer != null && textLayer.members.indexOf(copyEmblemSprite) >= 0)
			textLayer.remove(copyEmblemSprite, true);
		if (textLayer != null && textLayer.members.indexOf(copyPhotoSprite) >= 0)
			textLayer.remove(copyPhotoSprite, true);
		for (field in copyPassportFields)
			if (textLayer != null && textLayer.members.indexOf(field) >= 0)
				textLayer.remove(field, true);
		copyPassportFields = [];
		copyPassportFieldsReady = false;
		for (text in copyBankBodyTexts)
			if (textLayer != null && textLayer.members.indexOf(text) >= 0)
				textLayer.remove(text, true);
		copyBankBodyTexts = [];
		copyBankBodyTextsReady = false;
		for (field in copyBankDocumentFields)
			if (textLayer != null && textLayer.members.indexOf(field) >= 0)
				textLayer.remove(field, true);
		copyBankDocumentFields = [];
		copyBankDocumentFieldsReady = false;
		disposeCopyEmblemGraphic();
		disposeCopyPhotoGraphic();
		if (scanComposite != null)
		{
			scanComposite.dispose();
			scanComposite = null;
		}
		if (layer != null && layer.members.indexOf(this) >= 0)
			layer.remove(this, true);
		destroy();
	}

	override function usesZoneAngleWhenClosed():Bool
	{
		return true;
	}

	override function shouldOpenOnEmployerDrop():Bool
	{
		var mouse = FlxG.mouse.getViewPosition();
		if (LoanFolderDocument.blocksOpenWhileDraggingOver(mouse.x, mouse.y))
			return false;
		return super.shouldOpenOnEmployerDrop();
	}

	public function ensureSmallClosedGraphic():Void
	{
		if (isOpen || frameWidth <= Std.int(closedDisplayWidth * 1.5))
			return;

		storedLargeGraphicLoaded = false;
		loadGraphic(SMALL_PATH);
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
		copyNationalityShown = false;
		copyEmblemShown = false;
		copyPhotoShown = false;
		copyPassportFieldsShown = false;
		copyBankBodyTextsShown = false;
		copyBankDocumentFieldsShown = false;
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

	public function isHorizontalLargePaper():Bool
	{
		return largePaperPath == CopyPaperCompositor.PAPER_LARGE_HORIZONTAL_PATH;
	}

	public function applyStoredInFolderLayout(pocketW:Float, pocketH:Float, marginRatio:Float):Void
	{
		if (isOpen)
		{
			isOpen = false;
			copyTextShown = false;
			copyNationalityShown = false;
			copyEmblemShown = false;
			copyPhotoShown = false;
			copyPassportFieldsShown = false;
			copyBankBodyTextsShown = false;
			copyBankDocumentFieldsShown = false;
		}

		clearEmployerClip();
		ensureStoredLargeGraphic();

		var isHorizontal = isHorizontalLargePaper();
		var paperW = frameWidth;
		var paperH = frameHeight;
		var maxW = pocketW * marginRatio;
		var maxH = pocketH * marginRatio;
		var s = isHorizontal
			? Math.min(maxW / paperH, maxH / paperW)
			: Math.min(maxW / paperW, maxH / paperH);

		scale.set(s, s);
		angle = isHorizontal ? 90 : 0;
		updateHitbox();
		clipRect = null;
	}

	function ensureStoredLargeGraphic():Void
	{
		if (storedLargeGraphicLoaded && frameWidth > Std.int(closedDisplayWidth * 1.5))
			return;

		if (scanComposite != null)
			loadGraphic(scanComposite.clone());
		else
			loadGraphic(CopyPaperCompositor.loadLargePaperBitmap(largePaperPath));
		storedLargeGraphicLoaded = true;
	}

	override function setClosed():Void
	{
		if (!isOpen)
		{
			var needsSmallGraphic = frameWidth > Std.int(closedDisplayWidth * 1.5);
			if (needsSmallGraphic)
			{
				storedLargeGraphicLoaded = false;
				loadGraphic(SMALL_PATH);
				applyDisplaySize();
				angle = getAngleForZone(activeZone);
			}
			else
				syncClosedDragAngle();
			return;
		}

		clearEmployerClip();
		var cx = x + width * 0.5;
		var cy = y + height * 0.5;
		isOpen = false;
		storedLargeGraphicLoaded = false;
		loadGraphic(SMALL_PATH);
		applyDisplaySize();
		angle = getAngleForZone(activeZone);
		placeAfterResize(cx, cy);
		copyTextShown = false;
		copyNationalityShown = false;
		copyEmblemShown = false;
		copyPhotoShown = false;
		copyPassportFieldsShown = false;
		copyBankBodyTextsShown = false;
		copyBankDocumentFieldsShown = false;
		setCopyOverlaysVisible(false);
		clearCopyOverlayClips();
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

	public function refreshStoredCopyOverlays():Void
	{
		if (!isStoredInLoanFolder())
			return;

		syncCopyTextCameras();
		updateStoredCopyOverlays();
	}

	function updateCopyOverlays():Void
	{
		if (DeskDocument.blocksOverlayUpdates())
		{
			resetCopyOverlayShownFlags();
			setCopyOverlaysVisible(false);
			clearCopyOverlayClips();
			return;
		}

		if (!copyTextReady && !copyNationalityReady && !copyEmblemReady && !copyPhotoReady && !copyPassportFieldsReady
			&& !copyBankBodyTextsReady && !copyBankDocumentFieldsReady)
		{
			setCopyOverlaysVisible(false);
			return;
		}

		if (isOpenOnEmployerTable())
			refreshEmployerTableClip();

		var shouldShow = isOpen;
		if (shouldShow && isOpenOnEmployerTable() && !hasEmployerClipReady())
			shouldShow = false;
		if (shouldShow != copyTextShown)
		{
			copyTextShown = shouldShow;
			copyText.visible = shouldShow && copyTextReady;
		}
		if (shouldShow != copyPassportFieldsShown)
		{
			copyPassportFieldsShown = shouldShow;
			for (field in copyPassportFields)
				field.visible = shouldShow && copyPassportFieldsReady;
		}
		if (shouldShow != copyBankBodyTextsShown)
		{
			copyBankBodyTextsShown = shouldShow;
			for (text in copyBankBodyTexts)
				text.visible = shouldShow && copyBankBodyTextsReady;
		}
		if (shouldShow != copyBankDocumentFieldsShown)
		{
			copyBankDocumentFieldsShown = shouldShow;
			for (field in copyBankDocumentFields)
				field.visible = shouldShow && copyBankDocumentFieldsReady;
		}

		if (shouldShow != copyNationalityShown)
		{
			copyNationalityShown = shouldShow;
			copyNationalityText.visible = shouldShow && copyNationalityReady;
		}

		if (shouldShow != copyEmblemShown)
		{
			copyEmblemShown = shouldShow;
			copyEmblemSprite.visible = shouldShow && copyEmblemReady;
		}

		if (shouldShow != copyPhotoShown)
		{
			copyPhotoShown = shouldShow;
			copyPhotoSprite.visible = shouldShow && copyPhotoReady;
		}

		if (!shouldShow)
		{
			clearCopyOverlayClips();
			return;
		}

		syncCopyOverlayLayerOrder();

		var docX = x + width * docNormX;
		var docY = y + height * docNormY;
		var docW = width * docNormW;
		var docH = height * docNormH;
		layoutCopyOverlaysAt(docX, docY, docW, docH, null);

		syncCopyOverlayClips();
	}

	function updateStoredCopyOverlays():Void
	{
		if (!copyTextReady && !copyNationalityReady && !copyEmblemReady && !copyPhotoReady && !copyPassportFieldsReady
			&& !copyBankBodyTextsReady && !copyBankDocumentFieldsReady)
		{
			setCopyOverlaysVisible(false);
			return;
		}

		var folder = loanFolderStorage;
		var shouldShow = visible && folder != null && folder.isSpreadOpen() && folder.isOpen;

		if (!shouldShow)
		{
			setCopyOverlaysVisible(false);
			copyTextShown = false;
			copyNationalityShown = false;
			copyEmblemShown = false;
			copyPhotoShown = false;
			copyPassportFieldsShown = false;
			copyBankBodyTextsShown = false;
			copyBankDocumentFieldsShown = false;
			clearCopyOverlayClips();
			return;
		}

		copyText.visible = copyTextReady;
		copyNationalityText.visible = copyNationalityReady;
		copyEmblemSprite.visible = copyEmblemReady;
		copyPhotoSprite.visible = copyPhotoReady;
		for (field in copyPassportFields)
			field.visible = copyPassportFieldsReady;
		for (text in copyBankBodyTexts)
			text.visible = copyBankBodyTextsReady;
		for (field in copyBankDocumentFields)
			field.visible = copyBankDocumentFieldsReady;
		copyTextShown = true;
		copyNationalityShown = true;
		copyEmblemShown = true;
		copyPhotoShown = true;
		copyPassportFieldsShown = true;
		copyBankBodyTextsShown = true;
		copyBankDocumentFieldsShown = true;

		syncCopyOverlayLayerOrder();

		var paperScale = Math.abs(scale.x);
		var paperW = frameWidth * paperScale;
		var paperH = frameHeight * paperScale;
		var docW = paperW * docNormW;
		var docH = paperH * docNormH;
		var docLocalX = paperW * docNormX;
		var docLocalY = paperH * docNormY;
		var openDocH = getReferenceOpenDocHeight();
		var passportFontSize = openDocH > 0 ? Std.int(Math.max(4, COPY_FONT_SIZE * docH / openDocH)) : COPY_FONT_SIZE;

		copyText.angle = 0;
		copyNationalityText.angle = 0;
		copyEmblemSprite.angle = 0;
		copyPhotoSprite.angle = 0;
		for (field in copyPassportFields)
			field.angle = 0;
		for (text in copyBankBodyTexts)
			text.angle = 0;
		for (field in copyBankDocumentFields)
			field.angle = 0;

		if (Math.abs(angle) < 0.01)
		{
			layoutCopyOverlaysAt(x + docLocalX, y + docLocalY, docW, docH, passportFontSize);
		}
		else
		{
			layoutCopyOverlaysAt(docLocalX, docLocalY, docW, docH, passportFontSize);

			var emblemLayoutAngle = copyEmblemSprite.angle;
			applyStoredPaperTransformToOverlay(copyPhotoSprite, 0);
			applyStoredPaperTransformToOverlay(copyText, 0);
			applyStoredPaperTransformToOverlay(copyNationalityText, 0);
			applyStoredPaperTransformToOverlay(copyEmblemSprite, emblemLayoutAngle);
			for (field in copyPassportFields)
				applyStoredPaperTransformToOverlay(field, 0);
			for (text in copyBankBodyTexts)
				applyStoredPaperTransformToOverlay(text, 0);
			for (field in copyBankDocumentFields)
				applyStoredPaperTransformToOverlay(field, 0);
		}

		clearCopyOverlayClips();
	}

	function getReferenceOpenDocHeight():Float
	{
		if (frameHeight <= 0)
			return 1.0;

		var openScale = CopyPaperCompositor.getOpenDisplayScale(zones.employerW, OPEN_EMPLOYER_WIDTH_RATIO, isHorizontalLargePaper());
		return frameHeight * openScale * docNormH;
	}

	function layoutCopyOverlaysAt(docX:Float, docY:Float, docW:Float, docH:Float, ?passportFontSize:Null<Int>):Void
	{
		copyText.alpha = 0.88;
		copyNationalityText.alpha = 0.88;
		copyEmblemSprite.alpha = 0.88;

		switch (copyTextStyle)
		{
			case PassportLayout:
				if (copyPhotoReady && passportLayout != null)
					Passport.layoutCopyPhotoOverlay(passportLayout, copyPhotoSprite, docX, docY, docW, docH);
				if (copyPassportFieldsReady && passportLayout != null)
					Passport.layoutCopyFieldOverlays(
						passportLayout,
						copyPassportFields,
						docX,
						docY,
						docW,
						docH,
						COPY_TEXT_COLOR,
						passportFontSize
					);
			case IdCardLayout:
				if (copyPhotoReady && idCardLayout != null)
					IdDocument.layoutCopyPhotoOverlay(idCardLayout, copyPhotoSprite, docX, docY, docW, docH);
				if (copyEmblemReady && idCardLayout != null)
					IdDocument.layoutCopyEmblemOverlay(idCardLayout, copyEmblemSprite, docX, docY, docW, docH);
				if (copyTextReady && idCardLayout != null)
					IdDocument.layoutCopyText(idCardLayout, copyText, docX, docY, docW, docH, COPY_TEXT_COLOR);
				if (copyNationalityReady && idCardLayout != null)
					IdDocument.layoutCopyNationalityText(idCardLayout, copyNationalityText, docX, docY, docW, docH, COPY_TEXT_COLOR);
			case BankDocumentStyle:
				if (bankDocumentLayout != null && (copyBankBodyTextsReady || copyBankDocumentFieldsReady))
					BankDocument.layoutCopyOverlays(
						bankDocumentLayout,
						copyBankBodyTexts,
						copyBankDocumentFields,
						docX,
						docY,
						docW,
						docH,
						COPY_TEXT_COLOR,
						passportFontSize
					);
		}
	}

	function paperLocalToWorld(localX:Float, localY:Float):{x:Float, y:Float}
	{
		var ox = origin.x * Math.abs(scale.x);
		var oy = origin.y * Math.abs(scale.y);
		var px = localX - ox;
		var py = localY - oy;
		if (Math.abs(angle) < 0.01)
			return {x: x + px + ox - offset.x, y: y + py + oy - offset.y};

		var rad = angle * Math.PI / 180;
		var cosA = Math.cos(rad);
		var sinA = Math.sin(rad);
		return {
			x: x + px * cosA - py * sinA + ox - offset.x,
			y: y + px * sinA + py * cosA + oy - offset.y
		};
	}

	function applyStoredPaperTransformToOverlay(overlay:FlxSprite, layoutAngle:Float):Void
	{
		var world = paperLocalToWorld(overlay.x, overlay.y);
		overlay.setPosition(world.x, world.y);
		overlay.angle = angle + layoutAngle;
	}

	function disposeCopyPhotoGraphic():Void
	{
		if (copyPhotoGraphic != null)
		{
			copyPhotoGraphic.dispose();
			copyPhotoGraphic = null;
		}
	}

	function rebuildCopyEmblemGraphic():Void
	{
		if (idCardLayout == null || idCardLayout.emblem == null)
			return;

		disposeCopyEmblemGraphic();
		copyEmblemGraphic = CopyPaperCompositor.buildGrayEmblemGraphic(idCardLayout.emblem.path);
		copyEmblemSprite.loadGraphic(copyEmblemGraphic, false);
		copyEmblemSprite.visible = false;
		copyEmblemSprite.updateHitbox();
	}

	function disposeCopyEmblemGraphic():Void
	{
		if (copyEmblemGraphic != null)
		{
			copyEmblemGraphic.dispose();
			copyEmblemGraphic = null;
		}
		copyEmblemGraphicW = -1;
		copyEmblemGraphicH = -1;
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		for (overlay in copyPassportOverlayMembers())
			textLayer.remove(overlay, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		for (overlay in copyPassportOverlayMembers())
			target.add(overlay);
		syncCopyOverlayLayerOrder();
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		syncCopyOverlayLayerOrder();
	}

	public function syncCopyOverlayLayerOrder():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		var targetIndex = spriteIndex + 1;
		for (overlay in copyPassportOverlayMembers())
		{
			var overlayIndex = textLayer.members.indexOf(overlay);
			if (overlayIndex == targetIndex)
			{
				targetIndex++;
				continue;
			}

			if (overlayIndex >= 0)
				textLayer.remove(overlay, true);

			textLayer.insert(targetIndex, overlay);
			targetIndex++;
		}
	}

	function syncCopyTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [FlxG.camera];
		copyText.cameras = cams.copy();
		copyNationalityText.cameras = cams.copy();
		copyEmblemSprite.cameras = cams.copy();
		copyPhotoSprite.cameras = cams.copy();
		for (field in copyPassportFields)
			field.cameras = cams.copy();
		for (text in copyBankBodyTexts)
			text.cameras = cams.copy();
		for (field in copyBankDocumentFields)
			field.cameras = cams.copy();
	}

	function ensureCopyPassportFields():Void
	{
		if (passportLayout == null)
			return;

		while (copyPassportFields.length < passportLayout.fields.length)
		{
			var field = new FlxText(0, 0, 0, "");
			field.visible = false;
			copyPassportFields.push(field);
			textLayer.add(field);
		}
	}

	function ensureCopyBankBodyTexts():Void
	{
		if (bankDocumentLayout == null)
			return;

		var targetCount = BankDocumentLayouts.bodyBlockCount(bankDocumentLayout);
		while (copyBankBodyTexts.length < targetCount)
		{
			var block = BankDocument.bodyBlockAt(bankDocumentLayout, copyBankBodyTexts.length);
			var text = new FlxText(0, 0, 0, block.text);
			text.visible = false;
			copyBankBodyTexts.push(text);
			textLayer.add(text);
		}
	}

	function ensureCopyBankDocumentFields():Void
	{
		if (bankDocumentLayout == null)
			return;

		while (copyBankDocumentFields.length < bankDocumentLayout.fields.length)
		{
			var field = new FlxText(0, 0, 0, "");
			field.visible = false;
			copyBankDocumentFields.push(field);
			textLayer.add(field);
		}
	}

	public function getCopyOverlayMembers():Array<Dynamic>
	{
		return copyPassportOverlayMembers();
	}

	function copyPassportOverlayMembers():Array<Dynamic>
	{
		var overlays:Array<Dynamic> = [copyPhotoSprite, copyEmblemSprite];
		for (field in copyPassportFields)
			overlays.push(field);
		for (text in copyBankBodyTexts)
			overlays.push(text);
		for (field in copyBankDocumentFields)
			overlays.push(field);
		overlays.push(copyText);
		overlays.push(copyNationalityText);
		return overlays;
	}

	function resetCopyOverlayShownFlags():Void
	{
		copyTextShown = false;
		copyNationalityShown = false;
		copyEmblemShown = false;
		copyPhotoShown = false;
		copyPassportFieldsShown = false;
		copyBankBodyTextsShown = false;
		copyBankDocumentFieldsShown = false;
	}

	function setCopyOverlaysVisible(visible:Bool):Void
	{
		copyText.visible = visible && copyTextReady;
		copyNationalityText.visible = visible && copyNationalityReady;
		copyEmblemSprite.visible = visible && copyEmblemReady;
		copyPhotoSprite.visible = visible && copyPhotoReady;
		for (field in copyPassportFields)
			field.visible = visible && copyPassportFieldsReady;
		for (text in copyBankBodyTexts)
			text.visible = visible && copyBankBodyTextsReady;
		for (field in copyBankDocumentFields)
			field.visible = visible && copyBankDocumentFieldsReady;
	}

	function clearCopyOverlayClips():Void
	{
		copyText.clipRect = null;
		copyNationalityText.clipRect = null;
		copyEmblemSprite.clipRect = null;
		copyPhotoSprite.clipRect = null;
		for (field in copyPassportFields)
		{
			field.clipRect = null;
			field.angle = 0;
		}
		for (text in copyBankBodyTexts)
		{
			text.clipRect = null;
			text.angle = 0;
		}
		for (field in copyBankDocumentFields)
		{
			field.clipRect = null;
			field.angle = 0;
		}
		copyText.angle = 0;
		copyNationalityText.angle = 0;
		copyEmblemSprite.angle = 0;
		copyPhotoSprite.angle = 0;
	}

	function syncCopyOverlayClips():Void
	{
		syncOverlayClip(copyPhotoSprite);
		syncOverlayClip(copyEmblemSprite);
		syncOverlayClip(copyText);
		syncOverlayClip(copyNationalityText);
		for (field in copyPassportFields)
			syncOverlayClip(field);
		for (text in copyBankBodyTexts)
			syncOverlayClip(text);
		for (field in copyBankDocumentFields)
			syncOverlayClip(field);
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
