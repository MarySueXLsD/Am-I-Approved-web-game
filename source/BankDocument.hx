package;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;

@:access(flixel.text.FlxText)
class BankDocument extends DeskDocument
{
	static inline var OPEN_SIZE_MULTIPLIER = 6.0;
	static inline var DOCUMENT_FONT_SIZE = 11;
	static inline var FIELD_SCAN_PAD = 3.0;
	static inline var COPY_FONT_SIZE_SCALE = 1.85;

	var textLayer:FlxGroup;
	var bodyTexts:Array<FlxText>;
	var fieldValues:Array<FlxText>;
	var citizen:Citizen;
	var bodyTextsShown = false;
	var footerTextsShown = false;
	var layout:BankDocumentLayout;
	var variant:BankDocumentVariant;
	var currentLoanId = "";
	var completedChecklistItems:Array<LoanChecklistItem> = [];
	var loanDecisionApproved = false;
	var textLayoutDirty = false;
	var lastTextOverlayLayoutKey = -1.0;

	public function new(zones:LayoutZones, layer:FlxGroup, ?documentVariant:BankDocumentVariant)
	{
		variant = documentVariant != null ? documentVariant : BankDocumentVariant.ApplicationForm;
		layout = layoutForVariant(variant);
		super(zones, layer, layout.documentPath, layout.documentPath, OPEN_SIZE_MULTIPLIER, false);
		textLayer = layer;

		bodyTexts = [];
		for (i in 0...BankDocumentLayouts.bodyBlockCount(layout))
		{
			var block = bodyBlockAt(layout, i);
			var text = new FlxText(0, 0, 0, block.text);
			text.wordWrap = false;
			text.visible = false;
			bodyTexts.push(text);
			layer.add(text);
		}

		fieldValues = [];
		for (slot in layout.fields)
		{
			var value = new FlxText(0, 0, 0, "");
			value.visible = false;
			fieldValues.push(value);
			layer.add(value);
		}
	}

	public function getLayout():BankDocumentLayout
	{
		return layout;
	}

	public function getVariant():BankDocumentVariant
	{
		return variant;
	}

	public function setLoanId(loanId:String):Void
	{
		if (variant != BankDocumentVariant.LoanChecklist)
			return;

		currentLoanId = loanId;
		refreshChecklistLayout();
	}

	public function setClientDetailsData(c:Citizen):Void
	{
		if (variant != BankDocumentVariant.ClientDetails)
			return;

		layout = BankDocumentLayouts.clientDetails(c);
		invalidateTextOverlays();
	}

	public function setApplicationData(loanId:String, data:LoanApplicationData):Void
	{
		if (variant != BankDocumentVariant.ApplicationForm)
			return;

		layout = BankDocumentLayouts.applicationForm(loanId, data);
		invalidateTextOverlays();
	}

	public function setDecisionResult(review:LoanReviewResult, ?loanId:String):Void
	{
		if (variant != BankDocumentVariant.LoanDecision)
			return;

		loanDecisionApproved = review.approved;
		layout = BankDocumentLayouts.loanDecision(review, loanId);
		invalidateTextOverlays();
	}

	public function refreshCompletion(completed:Array<LoanChecklistItem>):Void
	{
		if (variant != BankDocumentVariant.LoanChecklist)
			return;

		completedChecklistItems = completed.copy();
		refreshChecklistLayout();
	}

	public function matchesLoanChecklistItem(item:LoanChecklistItem):Bool
	{
		switch (item)
		{
			case LoanApplicationForm:
				return variant == BankDocumentVariant.ApplicationForm;
			case LoanChecklist:
				return variant == BankDocumentVariant.LoanChecklist;
			default:
				return false;
		}
	}

	override public function belongsInClientTableRow():Bool
	{
		if (variant == BankDocumentVariant.LoanChecklist || variant == BankDocumentVariant.LoanDecision)
			return false;
		return super.belongsInClientTableRow();
	}

	function refreshChecklistLayout():Void
	{
		layout = BankDocumentLayouts.loanChecklist(currentLoanId, completedChecklistItems);
		invalidateTextOverlays();
	}

	function invalidateTextOverlays():Void
	{
		textLayoutDirty = true;
		bodyTextsShown = false;
		footerTextsShown = false;
	}

	public function getTextOverlayMembers():Array<FlxText>
	{
		return overlayTexts();
	}

	static function layoutForVariant(documentVariant:BankDocumentVariant):BankDocumentLayout
	{
		return switch (documentVariant)
		{
			case BankDocumentVariant.ApplicationForm:
				BankDocumentLayouts.applicationForm("");
			case BankDocumentVariant.LoanChecklist:
				BankDocumentLayouts.loanChecklist();
			case BankDocumentVariant.LoanDecision:
				BankDocumentLayouts.loanDecision({approved: false, errors: ["Pending review."], grantLines: []});
			case BankDocumentVariant.ClientDetails:
				BankDocumentLayouts.clientDetails(null);
		}
	}

	public function getCitizenForCopy():Citizen
	{
		return citizen;
	}

	public function getOverlayText():String
	{
		var lines:Array<String> = [];
		lines.push(layout.title.text);
		lines.push(BankDocumentLayouts.stripFormBodyMarkup(layout.formBody.text));
		lines.push(layout.disclaimer.text);
		if (citizen != null)
		{
			for (slot in layout.fields)
				lines.push(BankDocumentLayouts.fieldValue(citizen, slot.kind));
		}
		return lines.join("\n");
	}

	public static function layoutCopyOverlays(
		layout:BankDocumentLayout,
		bodyTexts:Array<FlxText>,
		footerFields:Array<FlxText>,
		docX:Float,
		docY:Float,
		docW:Float,
		docH:Float,
		textColor:Int,
		?baseFontSize:Null<Int>
	):Void
	{
		for (i in 0...BankDocumentLayouts.bodyBlockCount(layout))
		{
			if (i >= bodyTexts.length)
				break;
			layoutCopyBodyBlock(layout, i, bodyTexts[i], docX, docY, docW, docH, textColor, baseFontSize);
		}

		layoutCopyFieldOverlays(layout, footerFields, docX, docY, docW, docH, textColor, baseFontSize);
	}

	public static function layoutCopyFieldOverlays(
		layout:BankDocumentLayout,
		fields:Array<FlxText>,
		docX:Float,
		docY:Float,
		docW:Float,
		docH:Float,
		textColor:Int,
		?baseFontSize:Null<Int>
	):Void
	{
		var frame = Assets.getBitmapData(layout.documentPath);
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

	public static function bodyBlockAt(layout:BankDocumentLayout, index:Int):BankDocumentBodyBlock
	{
		return switch (index)
		{
			case 0: textBlockToBody(layout.title);
			case 1: textBlockToBody(layout.formBody);
			case 2: textBlockToBody(layout.disclaimer);
			default: textBlockToBody(layout.title);
		};
	}

	static function layoutCopyBodyBlock(
		layout:BankDocumentLayout,
		index:Int,
		text:FlxText,
		docX:Float,
		docY:Float,
		docW:Float,
		docH:Float,
		textColor:Int,
		?baseFontSize:Null<Int>
	):Void
	{
		var block = bodyBlockAt(layout, index);
		var frame = Assets.getBitmapData(layout.documentPath);
		var sx = frame.width > 0 ? docW / frame.width : 1.0;
		var sy = frame.height > 0 ? docH / frame.height : 1.0;
		applyBodyBlockFormat(block, text, docX, docY, sx, sy, textColor, true, baseFontSize);
	}

	static function textBlockToBody(block:{text:String, x:Float, y:Float, width:Float, fontSize:Null<Int>, bold:Bool, color:Null<Int>, leading:Null<Int>, align:Null<String>, ?wordWrap:Bool}):BankDocumentBodyBlock
	{
		return {
			text: block.text,
			x: block.x,
			y: block.y,
			width: block.width,
			fontSize: block.fontSize,
			bold: block.bold,
			color: block.color,
			leading: block.leading,
			align: block.align,
			wordWrap: block.wordWrap
		};
	}

	static function applyBodyBlockFormat(
		block:BankDocumentBodyBlock,
		text:FlxText,
		docX:Float,
		docY:Float,
		sx:Float,
		sy:Float,
		textColor:Int,
		?forCopy:Bool,
		?baseFontSize:Null<Int>,
		?storedFontScale:Null<Float>
	):Void
	{
		var fontSize:Int;
		if (forCopy == true)
		{
			fontSize = block.fontSize != null
				? Std.int(block.fontSize * sy)
				: (baseFontSize != null ? baseFontSize : Std.int(Math.max(7, DOCUMENT_FONT_SIZE * sy * COPY_FONT_SIZE_SCALE)));
		}
		else if (storedFontScale != null)
		{
			fontSize = scaledStoredFontSize(block.fontSize != null ? block.fontSize : DOCUMENT_FONT_SIZE, storedFontScale);
		}
		else
		{
			fontSize = block.fontSize != null ? block.fontSize : DOCUMENT_FONT_SIZE;
		}
		var color = block.color != null ? block.color : textColor;
		var align = block.align != null ? block.align : "left";

		var hasMarkup = block.text.indexOf("@") >= 0 || block.text.indexOf("$") >= 0 || block.text.indexOf("#") >= 0;

		text.clearFormats();
		text.setFormat(null, fontSize, color, align);
		text.setBorderStyle(NONE, 0x00000000, 0);
		text.bold = block.bold;
		if (block.leading != null)
		{
			if (forCopy == true)
				text._defaultFormat.leading = Std.int(block.leading * sy);
			else if (storedFontScale != null)
				text._defaultFormat.leading = Std.int(Math.max(0, block.leading * storedFontScale));
			else
				text._defaultFormat.leading = block.leading;
			text.updateDefaultFormat();
		}
		text.fieldWidth = block.width * sx;
		text.wordWrap = block.wordWrap == true;
		text.setPosition(docX + block.x * sx, docY + block.y * sy);

		if (forCopy == true)
		{
			if (hasMarkup && block.text.indexOf("#") >= 0)
				applyFormBodyMarkup(text, block.text);
			else
				text.text = hasMarkup ? BankDocumentLayouts.stripFormBodyMarkup(block.text) : block.text;
		}
		else if (storedFontScale != null)
		{
			if (hasMarkup)
				applyFormBodyMarkup(text, block.text);
			else
				text.text = block.text;
		}
		else if (hasMarkup)
			applyFormBodyMarkup(text, block.text);
		else
			text.text = block.text;
	}

	static function scaledStoredFontSize(baseSize:Int, fontScale:Float):Int
	{
		return Std.int(Math.max(2, Math.round(baseSize * fontScale)));
	}

	static function applyFormBodyMarkup(text:FlxText, markupSource:String):Void
	{
		var parsed = parseFormBodyMarkup(markupSource);
		text.text = parsed.text;

		for (range in parsed.labelRanges)
			text.addFormat(makeTextFormat(BankDocumentLayouts.LABEL_COLOR), range.start, range.end);
		for (range in parsed.affordableRanges)
			text.addFormat(makeTextFormat(BankDocumentLayouts.VERDICT_GREEN), range.start, range.end);
		for (range in parsed.strikethroughRanges)
			text.addFormat(makeStrikethroughFormat(), range.start, range.end);
	}

	static function makeStrikethroughFormat():Dynamic
	{
		var format = makeTextFormat(BankDocumentLayouts.STRIKETHROUGH_COLOR);
		format.underline = true;
		return format;
	}

	static function makeTextFormat(color:Int):Dynamic
	{
		var cls = Type.resolveClass("flixel.text.FlxTextFormat");
		return Type.createInstance(cls, [FlxColor.fromInt(color)]);
	}

	static function parseFormBodyMarkup(input:String):{text:String, labelRanges:Array<{start:Int, end:Int}>, affordableRanges:Array<{start:Int, end:Int}>, strikethroughRanges:Array<{start:Int, end:Int}>}
	{
		var output = new StringBuf();
		var labelRanges:Array<{start:Int, end:Int}> = [];
		var affordableRanges:Array<{start:Int, end:Int}> = [];
		var strikethroughRanges:Array<{start:Int, end:Int}> = [];
		var i = 0;

		while (i < input.length)
		{
			if (input.charAt(i) == "@")
			{
				var start = output.length;
				i++;
				while (i < input.length && input.charAt(i) != "@")
				{
					output.addSub(input, i, 1);
					i++;
				}
				if (i < input.length)
					i++;
				labelRanges.push({start: start, end: output.length});
				continue;
			}
			if (input.charAt(i) == "$")
			{
				var affordStart = output.length;
				i++;
				while (i < input.length && input.charAt(i) != "$")
				{
					output.addSub(input, i, 1);
					i++;
				}
				if (i < input.length)
					i++;
				affordableRanges.push({start: affordStart, end: output.length});
				continue;
			}
			if (input.charAt(i) == "#")
			{
				var strikeStart = output.length;
				i++;
				while (i < input.length && input.charAt(i) != "#")
				{
					output.addSub(input, i, 1);
					i++;
				}
				if (i < input.length)
					i++;
				strikethroughRanges.push({start: strikeStart, end: output.length});
				continue;
			}

			output.addSub(input, i, 1);
			i++;
		}

		return {text: output.toString(), labelRanges: labelRanges, affordableRanges: affordableRanges, strikethroughRanges: strikethroughRanges};
	}

	override public function destroy():Void
	{
		if (textLayer != null)
		{
			for (text in bodyTexts)
				if (textLayer.members.indexOf(text) >= 0)
					textLayer.remove(text, true);
			for (value in fieldValues)
				if (textLayer.members.indexOf(value) >= 0)
					textLayer.remove(value, true);
		}
		super.destroy();
	}

	override public function setLoanFolderStorage(folder:Null<LoanFolderDocument>):Void
	{
		var leavingFolder = loanFolderStorage != null && folder == null;
		super.setLoanFolderStorage(folder);
		if (leavingFolder)
		{
			bodyTextsShown = false;
			footerTextsShown = false;
		}
	}

	public function setCitizen(c:Citizen):Void
	{
		citizen = c;
		if (c == null)
		{
			for (value in fieldValues)
				value.text = "";
			return;
		}

		for (i in 0...fieldValues.length)
			fieldValues[i].text = BankDocumentLayouts.fieldValue(c, layout.fields[i].kind);
	}

	override public function resolveScanBoundsAt(point:FlxPoint):Null<ScanBounds>
	{
		if (!visible || !hitsPoint(point))
			return null;

		if (isOpen)
		{
			updateTextOverlays();
			var partBounds = scanBoundsForPartAt(point);
			if (partBounds != null)
				return partBounds;
		}

		var tag:Null<String> = null;
		if (variant == BankDocumentVariant.ApplicationForm)
			tag = BookScanActions.LOAN_APPLICATION_TAG;
		else if (variant == BankDocumentVariant.ClientDetails)
			tag = BookScanActions.CLIENT_DETAILS_TAG;

		return getDocumentScanBounds(tag);
	}

	override function shouldOpenOnEmployerDrop():Bool
	{
		var mouse = flixel.FlxG.mouse.getViewPosition();
		if (LoanFolderDocument.blocksOpenWhileDraggingOver(mouse.x, mouse.y))
			return false;
		return super.shouldOpenOnEmployerDrop();
	}

	override function shouldSnapToEmployerTableOpenOnDrop():Bool
	{
		return false;
	}

	override public function rejectsPrinterAndShredder():Bool
	{
		return variant == BankDocumentVariant.LoanDecision && loanDecisionApproved;
	}

	override public function lockForShredder():Void
	{
		super.lockForShredder();
		for (text in bodyTexts)
			text.visible = false;
		for (value in fieldValues)
			value.visible = false;
	}

	override public function finishShredder():Void
	{
		for (text in bodyTexts)
		{
			if (textLayer != null && textLayer.members.indexOf(text) >= 0)
				textLayer.remove(text, true);
		}
		for (value in fieldValues)
		{
			if (textLayer != null && textLayer.members.indexOf(value) >= 0)
				textLayer.remove(value, true);
		}
		bodyTexts = [];
		fieldValues = [];
		destroy();
	}

	override function bringToFront():Void
	{
		super.bringToFront();
		if (isOpen || isStoredInLoanFolder())
			syncTextOverlayLayerOrder();
	}

	public function moveToDocumentLayer(target:FlxGroup):Void
	{
		if (layer == target && textLayer == target)
			return;

		for (text in bodyTexts)
			textLayer.remove(text, true);
		for (value in fieldValues)
			textLayer.remove(value, true);
		if (layer.members.indexOf(this) >= 0)
			layer.remove(this, true);

		textLayer = target;
		setInteractionLayer(target);
		target.add(this);
		for (text in bodyTexts)
			target.add(text);
		for (value in fieldValues)
			target.add(value);
		syncTextOverlayLayerOrder();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var pocketFolder = getActiveLoanFolderForPocketText();
		if (pocketFolder != null)
		{
			updateLoanFolderPocketTextOverlays(pocketFolder);
			return;
		}

		if (!isOpen && (bodyTextsShown || footerTextsShown))
			clearLoanFolderPocketText();

		syncTextCameras();
		if (!scanLocked)
			updateTextOverlays();
	}

	public function refreshStoredTextOverlays():Void
	{
		refreshLoanFolderPocketTextOverlays();
	}

	public function refreshLoanFolderPocketTextOverlays():Void
	{
		syncTextCameras();
		var pocketFolder = getActiveLoanFolderForPocketText();
		if (pocketFolder != null)
			updateLoanFolderPocketTextOverlays(pocketFolder);
	}

	public function clearLoanFolderPocketText():Void
	{
		bodyTextsShown = false;
		footerTextsShown = false;
		for (text in bodyTexts)
		{
			text.visible = false;
			text.clipRect = null;
		}
		for (value in fieldValues)
		{
			value.visible = false;
			value.clipRect = null;
		}
	}

	function getActiveLoanFolderForPocketText():Null<LoanFolderDocument>
	{
		if (loanFolderStorage != null)
			return loanFolderStorage;

		if (loanFolderPullHost != null && dragging)
		{
			var mouse = flixel.FlxG.mouse.getViewPosition();
			if (loanFolderPullHost.shouldPullSnapInStorage(mouse.x, mouse.y))
				return loanFolderPullHost;
		}

		return null;
	}

	function updateLoanFolderPocketTextOverlays(folder:LoanFolderDocument):Void
	{
		if (DeskDocument.blocksOverlayUpdates())
		{
			bodyTextsShown = false;
			footerTextsShown = false;
			for (text in bodyTexts)
			{
				text.visible = false;
				text.clipRect = null;
			}
			for (value in fieldValues)
			{
				value.visible = false;
				value.clipRect = null;
			}
			return;
		}

		var shouldShow = visible && folder.isSpreadOpen() && folder.isOpen;

		if (!shouldShow)
		{
			bodyTextsShown = false;
			footerTextsShown = false;
			for (text in bodyTexts)
			{
				text.visible = false;
				text.clipRect = null;
			}
			for (value in fieldValues)
			{
				value.visible = false;
				value.clipRect = null;
			}
			return;
		}

		var shouldShowFooter = citizen != null;

		syncTextCameras();

		if (bodyTextsShown != true)
		{
			bodyTextsShown = true;
			for (i in 0...bodyTexts.length)
				bodyTexts[i].visible = i != 2;
		}

		if (footerTextsShown != shouldShowFooter)
		{
			footerTextsShown = shouldShowFooter;
			for (value in fieldValues)
				value.visible = shouldShowFooter;
		}

		syncTextOverlayLayerOrder();

		layoutStoredTextOverlays(shouldShowFooter);

		for (text in bodyTexts)
		{
			text.angle = 0;
			text.clipRect = null;
		}
		for (value in fieldValues)
		{
			value.angle = 0;
			value.clipRect = null;
		}
	}

	function getStoredTextFontScale():Float
	{
		var openW = getOpenDisplayTargetWidth();
		if (openW <= 0 || width <= 0)
			return 1.0;
		return width / openW;
	}

	function layoutStoredTextOverlays(showFooter:Bool):Void
	{
		var sx = frameWidth > 0 ? width / frameWidth : 1.0;
		var sy = frameHeight > 0 ? height / frameHeight : 1.0;
		var fontScale = getStoredTextFontScale();

		for (i in 0...bodyTexts.length)
		{
			if (i == 2)
			{
				bodyTexts[i].visible = false;
				continue;
			}

			applyBodyBlockFormat(bodyBlockAt(layout, i), bodyTexts[i], x, y, sx, sy, layout.valueColor, false, null, fontScale);
		}

		if (!showFooter)
			return;

		for (i in 0...fieldValues.length)
		{
			var slot = layout.fields[i];
			var value = fieldValues[i];
			var baseSize = slot.fontSize != null ? slot.fontSize : DOCUMENT_FONT_SIZE;
			var slotFontSize = scaledStoredFontSize(baseSize, fontScale);
			var fieldWidth = slot.width != null ? slot.width * sx : width - slot.x * sx;

			value.clearFormats();
			value.setFormat(null, slotFontSize, layout.valueColor, "left");
			value.setBorderStyle(NONE, 0x00000000, 0);
			value.bold = false;
			value.fieldWidth = fieldWidth;
			value.setPosition(x + slot.x * sx, y + slot.y * sy);
		}
	}

	function layoutScreenTextOverlays(showFooter:Bool, clipToEmployerTable:Bool):Void
	{
		var sx = frameWidth > 0 ? width / frameWidth : 1.0;
		var sy = frameHeight > 0 ? height / frameHeight : 1.0;

		for (i in 0...bodyTexts.length)
		{
			applyBodyBlockFormat(bodyBlockAt(layout, i), bodyTexts[i], x, y, sx, sy, layout.valueColor);
			if (clipToEmployerTable)
				syncOverlayClip(bodyTexts[i]);
		}

		if (!showFooter)
			return;

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
			if (clipToEmployerTable)
				syncOverlayClip(value);
		}
	}

	override function onScanLockChanged(locked:Bool):Void
	{
		if (!locked)
		{
			bodyTextsShown = false;
			footerTextsShown = false;
			return;
		}

		for (text in bodyTexts)
		{
			text.visible = false;
			text.clipRect = null;
		}
		for (value in fieldValues)
		{
			value.visible = false;
			value.clipRect = null;
		}
	}

	function updateTextOverlays():Void
	{
		if (DeskDocument.blocksOverlayUpdates())
		{
			bodyTextsShown = false;
			footerTextsShown = false;
			for (text in bodyTexts)
			{
				text.visible = false;
				text.clipRect = null;
			}
			for (value in fieldValues)
			{
				value.visible = false;
				value.clipRect = null;
			}
			return;
		}

		if (textLayoutDirty)
		{
			textLayoutDirty = false;
			bodyTextsShown = false;
			footerTextsShown = false;
			lastTextOverlayLayoutKey = -1.0;
		}

		if (isOpenOnEmployerTable())
			refreshEmployerTableClip();

		var shouldShowBody = isOpen;
		if (shouldShowBody && isOpenOnEmployerTable() && !hasEmployerClipReady())
			shouldShowBody = false;

		var shouldShowFooter = shouldShowBody && citizen != null;

		if (bodyTextsShown != shouldShowBody)
		{
			bodyTextsShown = shouldShowBody;
			for (text in bodyTexts)
				text.visible = shouldShowBody;
		}

		if (footerTextsShown != shouldShowFooter)
		{
			footerTextsShown = shouldShowFooter;
			for (value in fieldValues)
				value.visible = shouldShowFooter;
		}

		if (!shouldShowBody)
		{
			lastTextOverlayLayoutKey = -1.0;
			for (text in bodyTexts)
				text.clipRect = null;
			for (value in fieldValues)
				value.clipRect = null;
			return;
		}

		var layoutKey = x + y * 10000 + width * 100 + height;
		if (layoutKey == lastTextOverlayLayoutKey)
			return;
		lastTextOverlayLayoutKey = layoutKey;

		syncTextOverlayLayerOrder();

		layoutScreenTextOverlays(shouldShowFooter, true);
	}

	function scanBoundsForPartAt(point:FlxPoint):Null<ScanBounds>
	{
		for (i in 0...bodyTexts.length)
		{
			var text = bodyTexts[i];
			if (!text.visible)
				continue;

			if (variant == BankDocumentVariant.ClientDetails && i == 1)
			{
				var lineBounds = clientDetailsBodyScanBoundsAt(point, text);
				if (lineBounds != null)
					return lineBounds;
				continue;
			}

			var bounds = textScanBounds(text, scanTagForBodyText(i));
			if (pointInScanBounds(point, bounds))
				return bounds;
		}

		for (i in 0...fieldValues.length)
		{
			var value = fieldValues[i];
			if (!value.visible)
				continue;
			var bounds = textScanBounds(value, scanTagForField(i));
			if (pointInScanBounds(point, bounds))
				return bounds;
		}
		return null;
	}

	function clientDetailsBodyScanBoundsAt(point:FlxPoint, body:FlxText):Null<ScanBounds>
	{
		var fullBounds = textScanBounds(body, null);
		if (!pointInScanBounds(point, fullBounds))
			return null;

		var localX = Std.int(point.x - body.x);
		var localY = Std.int(point.y - body.y);
		var charIndex = body.textField.getCharIndexAtPoint(localX, localY);
		var tag = BookScanActions.CLIENT_DETAILS_TAG;
		if (charIndex >= 0)
		{
			var displayText = body.text;
			var lineStart = displayText.lastIndexOf("\n", charIndex - 1) + 1;
			var lineEnd = displayText.indexOf("\n", charIndex);
			if (lineEnd < 0)
				lineEnd = displayText.length;
			var line = StringTools.trim(displayText.substring(lineStart, lineEnd));
			if (StringTools.startsWith(line, "Person:"))
				tag = BookScanActions.DOCUMENT_NAME_TAG;
		}

		return textScanBounds(body, tag);
	}

	function scanTagForBodyText(index:Int):Null<String>
	{
		return null;
	}

	function scanTagForField(index:Int):Null<String>
	{
		if (index >= layout.fields.length)
			return null;

		if (layout.fields[index].kind == AccountHolder)
			return BookScanActions.DOCUMENT_NAME_TAG;

		if (variant == BankDocumentVariant.ClientDetails)
			return BookScanActions.CLIENT_DETAILS_TAG;

		return null;
	}

	function textScanBounds(text:FlxText, ?tag:Null<String>):ScanBounds
	{
		var glyphW = text.textField.textWidth;
		var glyphH = text.textField.textHeight;
		return {
			x: text.x,
			y: text.y,
			w: glyphW > 0 ? glyphW : text.width,
			h: glyphH > 0 ? glyphH : text.height,
			pad: FIELD_SCAN_PAD,
			tag: tag
		};
	}

	function pointInScanBounds(point:FlxPoint, bounds:ScanBounds):Bool
	{
		return point.x >= bounds.x && point.x < bounds.x + bounds.w
			&& point.y >= bounds.y && point.y < bounds.y + bounds.h;
	}

	public function syncTextOverlayLayerOrder():Void
	{
		if (textLayer == null || textLayer.members == null)
			return;

		var spriteIndex = textLayer.members.indexOf(this);
		if (spriteIndex < 0)
			return;

		var targetIndex = spriteIndex + 1;
		for (overlay in overlayTexts())
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

	function overlayTexts():Array<FlxText>
	{
		var texts = bodyTexts.copy();
		for (value in fieldValues)
			texts.push(value);
		return texts;
	}

	function syncTextCameras():Void
	{
		var cams = cameras;
		if (cams == null)
			cams = [flixel.FlxG.camera];
		for (text in bodyTexts)
		{
			if (sameCameras(text.cameras, cams))
				continue;
			text.cameras = cams.copy();
		}
		for (value in fieldValues)
		{
			if (sameCameras(value.cameras, cams))
				continue;
			value.cameras = cams.copy();
		}
	}

	function sameCameras(a:Array<flixel.FlxCamera>, b:Array<flixel.FlxCamera>):Bool
	{
		if (a == null || b == null)
			return a == b;
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}
}

typedef BankDocumentBodyBlock = {
	var text:String;
	var x:Float;
	var y:Float;
	var width:Float;
	var fontSize:Null<Int>;
	var bold:Bool;
	var color:Null<Int>;
	var leading:Null<Int>;
	var align:Null<String>;
	var ?wordWrap:Bool;
}
