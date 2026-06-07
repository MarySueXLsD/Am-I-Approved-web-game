package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;
import StringTools;

enum LoanAppView
{
	Menu;
	NewForm;
}

class MonitorLoanApplication extends FlxGroup
{
	static var MENU_ITEMS:Array<String> = [
		"New Application",
		"Print Checklist",
		"Print Application Form",
		"Submit for Approval"
	];

	static var LOAN_TYPES:Array<String> = LoanProductRates.LOAN_PRODUCTS;
	static var SECURITY_TYPES:Array<String> = LoanProductRates.SECURITY_TYPES;

	static inline var MAX_TERM = 360;
	static inline var MAX_CALC_LINE_TEXTS = 28;
	static inline var SCROLL_W = 18;
	static inline var BTN_H = 16;
	static inline var PANEL_PAD = 4;
	static inline var FIELD_PAD_X = 6;
	static inline var CALC_TITLE_GAP = 10;
	static inline var CALC_LINE_GAP = 6;
	static inline var CALC_BLANK_GAP = 8;
	static inline var SUBMIT_SUCCESS_MSG = "Loan application started.\nPlease put all necessary documentation\nin the loan application folder on your desk.";

	var state:LoanApplicationState;
	var view:LoanAppView = LoanAppView.Menu;
	var areaX:Float = 0;
	var areaY:Float = 0;
	var areaW:Float = 0;
	var areaH:Float = 0;
	var fontSize = 12;
	var menuFontSize = 14;

	var titleText:FlxText;
	var progressBanner:FlxText;
	var menuRows:Array<MonitorMenuRow> = [];
	var formEntries:Array<MonitorDetailEntryRow> = [];
	var formScrollIndex = 0;
	var formPanelBg:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;
	var scrollUpBtn:FlxSprite;
	var scrollDownBtn:FlxSprite;
	var scrollColumn:FlxSprite;
	var scrollX:Float = 0;
	var contentW:Float = 0;
	var trackY:Float = 0;
	var trackH:Float = 0;
	var thumbH = 12;
	var lastThumbH = -1;
	var thumbDragging = false;
	var dragGrabY = 0.0;
	var rowHeight = 32;
	var panelTopY:Float = 0;
	var sectionsViewportH:Float = 0;
	var calcTitleText:FlxText;
	var calcLineTexts:Array<FlxText> = [];
	var calcValueTexts:Array<FlxText> = [];
	var cachedCalcScrollSlots = 1;
	var cachedCalcLines:Array<String> = [];
	var reopenDraftOnNextOpen = false;

	var backButton:MonitorBackButton;
	var submitButton:MonitorBackButton;
	var confirmDialog:MonitorConfirmDialog;

	var focusedPath:Null<String> = null;
	var keyHandler:KeyboardEvent->Void;

	var ddBg:FlxSprite;
	var ddTxt:Array<FlxText> = [];
	static inline var MAX_DD = 6;
	static inline var MAX_NATIONAL_ID_SUGGESTIONS = 5;
	var ddOpen = false;
	var ddIsNationalIdSuggestions = false;
	var ddNationalIds:Array<String> = [];
	var ddPath = "";
	var ddChoices:Array<String> = [];
	var ddX:Float = 0;
	var ddY:Float = 0;
	var ddW:Float = 0;
	var ddItemH:Int = 0;
	var ddCurrentValue = "";
	var ddVisibleCount = 0;

	public var onPrintRequest:Void->Bool;
	public var onPrintChecklistRequest:Void->Bool;
	public var onSubmitForApprovalRequest:Void->Bool;
	public var onInternalViewChanged:Void->Void;

	public function new(appState:LoanApplicationState)
	{
		super();
		state = appState;
		keyHandler = onKeyDown;

		formPanelBg = new FlxSprite();
		formPanelBg.scrollFactor.set(0, 0);
		add(formPanelBg);

		titleText = new FlxText(0, 0, 100, "");
		titleText.scrollFactor.set(0, 0);
		add(titleText);

		progressBanner = new FlxText(0, 0, 100, "");
		progressBanner.scrollFactor.set(0, 0);
		progressBanner.visible = false;
		add(progressBanner);

		for (i in 0...MENU_ITEMS.length)
		{
			var row = new MonitorMenuRow(MENU_ITEMS[i], true);
			menuRows.push(row);
			add(row.hit);
			add(row.label);
		}

		initFormEntries();

		scrollColumn = new FlxSprite();
		scrollTrack = new FlxSprite();
		scrollThumb = new FlxSprite();
		scrollUpBtn = new FlxSprite();
		scrollDownBtn = new FlxSprite();
		for (spr in [scrollColumn, scrollTrack, scrollThumb, scrollUpBtn, scrollDownBtn])
		{
			spr.scrollFactor.set(0, 0);
			spr.visible = false;
			add(spr);
		}

		ddBg = new FlxSprite();
		ddBg.scrollFactor.set(0, 0);
		ddBg.visible = false;
		add(ddBg);

		for (i in 0...MAX_DD)
		{
			var t = new FlxText(0, 0, 0, "");
			t.scrollFactor.set(0, 0);
			t.visible = false;
			add(t);
			ddTxt.push(t);
		}

		backButton = new MonitorBackButton("< BACK");
		submitButton = new MonitorBackButton("SUBMIT >");
		add(backButton.hit);
		add(backButton.label);
		add(submitButton.hit);
		add(submitButton.label);

		calcTitleText = new FlxText(0, 0, 100, "AFFORDABILITY");
		calcTitleText.scrollFactor.set(0, 0);
		calcTitleText.visible = false;
		add(calcTitleText);

		for (i in 0...MAX_CALC_LINE_TEXTS)
		{
			var lineText = new FlxText(0, 0, 100, "");
			lineText.scrollFactor.set(0, 0);
			lineText.visible = false;
			calcLineTexts.push(lineText);
			add(lineText);

			var valueText = new FlxText(0, 0, 100, "");
			valueText.scrollFactor.set(0, 0);
			valueText.visible = false;
			calcValueTexts.push(valueText);
			add(valueText);
		}

		confirmDialog = new MonitorConfirmDialog();
		add(confirmDialog);

		hideAll();
	}

	public function isOnMenu():Bool
	{
		return view == LoanAppView.Menu;
	}

	public function reset():Void
	{
		state.reset();
		showMenu();
		clearForm();
	}

	public function consumeFolderSlide():Bool
	{
		return state.consumeFolderSlide();
	}

	public function showMenu():Void
	{
		view = LoanAppView.Menu;
		focusedPath = null;
		detachKeyListener();
		closeDropdown();
		layout();
		notifyViewChanged();
	}

	function showNewForm():Void
	{
		closeDropdown();
		view = LoanAppView.NewForm;
		formScrollIndex = 0;
		if (reopenDraftOnNextOpen)
		{
			reopenDraftOnNextOpen = false;
			layout();
			notifyViewChanged();
			return;
		}

		var previousData:Null<LoanApplicationData> = null;
		if (state.hasApplication() && state.data != null)
			previousData = state.data;

		clearForm();

		if (previousData != null)
			applyFormData(previousData);

		layout();
		notifyViewChanged();
	}

	function applyFormData(data:LoanApplicationData):Void
	{
		applyFieldDraft("nationalId", data.nationalId);
		applyFieldDraft("loanType", data.loanType);
		applyFieldDraft("security", data.security);
		applyFieldDraft("amount", data.amount);
		applyFieldDraft("term", data.term);
		applyFieldDraft("declaredSalary", data.declaredSalary);
		applyFieldDraft("spendHousing", data.spendHousing);
		applyFieldDraft("spendLiving", data.spendLiving);
		applyFieldDraft("spendOther", data.spendOther);
	}

	function applyFieldDraft(path:String, value:String):Void
	{
		if (StringTools.trim(value).length == 0)
			return;

		var row = getRowByPath(path);
		if (row == null)
			return;

		row.setDraft(value);
		row.commitDraft();
	}

	function clearForm():Void
	{
		resetFormEntries();
		focusedPath = null;
		detachKeyListener();
	}

	public function suspendInput():Void
	{
		blurField();
		closeDropdown();
		if (!confirmDialog.isOpen())
			confirmDialog.close();
		endDrag();
	}

	public function isModalOpen():Bool
	{
		return confirmDialog.isOpen();
	}

	public function setBounds(x:Float, y:Float, w:Float, h:Float, textSize:Int, menuSize:Int):Void
	{
		var dimChanged = Math.abs(areaX - x) > 0.5
			|| Math.abs(areaY - y) > 0.5
			|| Math.abs(areaW - w) > 0.5
			|| Math.abs(areaH - h) > 0.5
			|| fontSize != textSize
			|| menuFontSize != menuSize;

		areaX = x;
		areaY = y;
		areaW = w;
		areaH = h;
		fontSize = textSize;
		menuFontSize = menuSize;
		rowHeight = MonitorDetailEntryRow.rowHeight(fontSize);
		contentW = w - SCROLL_W - 8;
		scrollX = x + contentW + 4;

		if (dimChanged)
			layout();
		else
			syncOpenDropdown();

		if (confirmDialog.isOpen())
			confirmDialog.syncBounds(areaX, areaY, areaW, areaH);
	}

	public function handleClick(mx:Float, my:Float):Bool
	{
		if (confirmDialog.isOpen())
			return confirmDialog.handleClick(mx, my);

		if (ddOpen)
		{
			if (isInDropdownArea(mx, my))
				return handleDropdownClick(mx, my);

			var owningRow = getRowByPath(ddPath);
			if (owningRow != null && !ddIsNationalIdSuggestions && owningRow.overlaps(mx, my))
				return true;

			closeDropdown();
		}

		switch (view)
		{
			case LoanAppView.Menu:
				for (i in 0...menuRows.length)
				{
					var row = menuRows[i];
					if (row.enabled && row.hit.overlapsPoint(new FlxPoint(mx, my)))
					{
						handleMenuAction(MENU_ITEMS[i]);
						return true;
					}
				}
			case LoanAppView.NewForm:
				if (backButton.visible && backButton.hit.overlapsPoint(new FlxPoint(mx, my)))
				{
					reopenDraftOnNextOpen = true;
					showMenu();
					return true;
				}
				if (submitButton.visible && submitButton.isEnabled()
					&& submitButton.hit.overlapsPoint(new FlxPoint(mx, my)))
				{
					submitForm();
					return true;
				}
				if (handleFormScrollClick(mx, my))
					return true;
				if (tryFocusField(mx, my))
					return true;
				blurField();
		}
		return true;
	}

	public function updateDrag(mx:Float, my:Float):Void
	{
		if (view != LoanAppView.NewForm || !thumbDragging)
			return;

		var newY = my - dragGrabY;
		newY = FlxMath.bound(newY, trackY, trackY + trackH - thumbH);
		scrollThumb.y = newY;
		syncScrollFromThumb();
	}

	public function endDrag():Void
	{
		thumbDragging = false;
	}

	public function updateHover(mx:Float, my:Float):Void
	{
		if (confirmDialog.isOpen())
			return;

		switch (view)
		{
			case LoanAppView.Menu:
				for (row in menuRows)
					row.updateHover(mx, my);
			case LoanAppView.NewForm:
				if (backButton.visible)
					backButton.updateHover(mx, my);
				if (submitButton.visible)
					submitButton.updateHover(mx, my);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!visible || confirmDialog.isOpen())
			return;

		if (ddOpen)
			updateDropdownHover();
	}

	public function handleWheel(delta:Float):Void
	{
		if (view != LoanAppView.NewForm || delta == 0 || maxFormScrollIndex() <= 0)
			return;
		closeDropdown();
		scrollFormBy(delta > 0 ? -1 : 1);
	}

	function scrollFormBy(delta:Int):Void
	{
		if (delta == 0)
			return;
		var old = formScrollIndex;
		formScrollIndex += delta;
		clampFormScroll();
		if (formScrollIndex != old)
			layoutFormFields();
	}

	function handleMenuAction(action:String):Void
	{
		switch (action)
		{
			case "New Application":
				showNewForm();
			case "Print Checklist":
				if (!state.hasApplication())
				{
					showWarning("No current application in progress", function() {});
					return;
				}
				tryPrintChecklist();
			case "Print Application Form":
				if (!state.hasApplication())
				{
					showWarning("No current application in progress", function() {});
					return;
				}
				tryPrint();
			case "Submit for Approval":
				if (!state.hasApplication())
				{
					showWarning("No current application in progress", function() {});
					return;
				}
				trySubmitForApproval();
		}
	}

	function trySubmitForApproval():Void
	{
		var submitted = onSubmitForApprovalRequest != null && onSubmitForApprovalRequest();
		if (!submitted)
			showWarning("All required documents must be\nin the loan folder before submitting\nfor approval.", function() {});
	}

	function tryPrintChecklist():Void
	{
		var printed = onPrintChecklistRequest != null && onPrintChecklistRequest();
		if (!printed)
			showWarning("You need to free up printer\notherwise you cant print.", function() {});
	}

	function tryPrint():Void
	{
		var printed = onPrintRequest != null && onPrintRequest();
		if (!printed)
			showWarning("You need to free up printer\notherwise you cant print.", function() {});
	}

	function submitForm():Void
	{
		blurField();
		var data = collectFormData();
		if (!requireField(data.nationalId, "National ID is required."))
			return;
		if (!requireField(data.loanType, "Loan product is required."))
			return;
		if (!requireField(data.security, "Security type is required."))
			return;
		if (!requireField(data.amount, "Amount is required."))
			return;
		if (!requireField(data.term, "Term is required."))
			return;
		if (!requireField(data.declaredSalary, "Monthly salary is required."))
			return;
		if (!requireField(data.spendHousing, "Housing / mo is required."))
			return;
		if (!requireField(data.spendLiving, "Living / mo is required."))
			return;
		state.submit(data);
		showSuccess(SUBMIT_SUCCESS_MSG, showMenu);
	}

	function requireField(value:String, message:String):Bool
	{
		if (StringTools.trim(value).length == 0)
		{
			showWarning(message, function() {});
			return false;
		}
		return true;
	}

	function collectFormData():LoanApplicationData
	{
		return {
			nationalId: getFieldDraft("nationalId"),
			loanType: getFieldDraft("loanType"),
			security: getFieldDraft("security"),
			amount: getFieldDraft("amount"),
			term: getFieldDraft("term"),
			purpose: "",
			declaredSalary: getFieldDraft("declaredSalary"),
			spendHousing: getFieldDraft("spendHousing"),
			spendLiving: getFieldDraft("spendLiving"),
			spendOther: getFieldDraft("spendOther")
		};
	}

	function getFieldDraft(path:String):String
	{
		for (entry in formEntries)
		{
			var row = entry.getFieldRow(path);
			if (row != null)
				return row.getDraft();
		}
		return "";
	}

	function notifyViewChanged():Void
	{
		if (onInternalViewChanged != null)
			onInternalViewChanged();
	}

	function showWarning(text:String, dismiss:Void->Void):Void
	{
		blurField();
		closeDropdown();
		confirmDialog.showWarning(areaX, areaY, areaW, areaH, text, dismiss);
		bringConfirmDialogToFront();
	}

	function showSuccess(text:String, dismiss:Void->Void):Void
	{
		blurField();
		closeDropdown();
		confirmDialog.showSuccess(areaX, areaY, areaW, areaH, text, dismiss);
		bringConfirmDialogToFront();
	}

	function bringConfirmDialogToFront():Void
	{
		if (!confirmDialog.isOpen())
			return;
		remove(confirmDialog, false);
		add(confirmDialog);
	}

	function layout():Void
	{
		hideAll();
		if (areaW <= 1 || areaH <= 1)
			return;

		switch (view)
		{
			case LoanAppView.Menu:
				layoutMenu();
			case LoanAppView.NewForm:
				layoutForm();
		}
	}

	function layoutMenu():Void
	{
		titleText.text = "LOAN APPLICATION";
		titleText.setFormat(null, menuFontSize + 2, MonitorScreenUi.GREEN_BRIGHT, "center");
		titleText.fieldWidth = Std.int(areaW);
		titleText.scale.set(1, 1);
		titleText.setPosition(areaX, areaY);
		titleText.visible = true;

		var contentY = titleText.y + titleText.height + 8;
		if (state.hasApplication())
		{
			progressBanner.text = 'Loan Application in progress.\nLoan ID: ${state.loanId}';
			progressBanner.setFormat(null, fontSize, MonitorScreenUi.GREEN, "center");
			progressBanner.fieldWidth = Std.int(areaW);
			progressBanner.scale.set(1, 1);
			progressBanner.setPosition(areaX, contentY);
			progressBanner.visible = true;
			contentY = progressBanner.y + progressBanner.height + 8;
		}

		var rowH = menuFontSize + 14;
		var rowGap = Std.int(Math.max(6, areaH * 0.025));
		for (i in 0...menuRows.length)
		{
			var row = menuRows[i];
			var ry = contentY + i * (rowH + rowGap);
			row.layout(areaX, ry, areaW, rowH, menuFontSize, MonitorScreenUi.GREEN, MonitorScreenUi.GREEN_DIM);
			row.visible = true;
		}
	}

	function layoutForm():Void
	{
		titleText.text = "NEW LOAN APPLICATION";
		titleText.setFormat(null, menuFontSize + 2, MonitorScreenUi.GREEN_BRIGHT, "center");
		titleText.fieldWidth = Std.int(areaW);
		titleText.scale.set(1, 1);
		titleText.setPosition(areaX, areaY);
		titleText.visible = true;

		var backH = fontSize + 10;
		var backW = areaW * 0.35;
		var btnY = areaY + areaH - backH;
		backButton.layout(areaX, btnY, backW, backH, fontSize);
		submitButton.layout(areaX + areaW - backW, btnY, backW, backH, fontSize);
		backButton.visible = true;
		submitButton.visible = true;
		submitButton.setEnabled(true);

		contentW = areaW - SCROLL_W - 8;
		scrollX = areaX + contentW + 4;

		panelTopY = titleText.y + titleText.height + 8;
		sectionsViewportH = backButton.hit.y - 6 - panelTopY;
		if (sectionsViewportH < rowHeight)
			sectionsViewportH = rowHeight;

		refreshCalculatedFields();
		clampFormScroll();

		drawFormPanel();
		layoutScrollbar();
		layoutFormFields();
	}

	function calcTitleSlotHeight():Int
	{
		var labelSize = Std.int(Math.max(10, fontSize - 1));
		return labelSize + CALC_TITLE_GAP;
	}

	function calcLineHeight():Int
	{
		return fontSize + CALC_LINE_GAP;
	}

	function calcScrollSlotHeight(calcSlot:Int):Float
	{
		if (calcSlot == 0)
			return calcTitleSlotHeight();
		var lineIdx = calcSlot - 1;
		if (lineIdx >= 0 && lineIdx < cachedCalcLines.length)
		{
			var line = cachedCalcLines[lineIdx];
			if (line.length == 0)
				return CALC_BLANK_GAP;
			if (LoanAffordabilityCalculator.isSectionLine(line))
				return calcTitleSlotHeight();
		}
		return calcLineHeight();
	}

	function scrollSlotCount():Int
	{
		return formEntries.length + cachedCalcScrollSlots;
	}

	function scrollSlotHeight(slot:Int):Float
	{
		if (slot < formEntries.length)
			return rowHeight;
		return calcScrollSlotHeight(slot - formEntries.length);
	}

	function scrollOffsetForIndex(index:Int):Float
	{
		var offset = 0.0;
		for (i in 0...index)
			offset += scrollSlotHeight(i);
		return offset;
	}

	function totalScrollContentHeight():Float
	{
		return scrollOffsetForIndex(scrollSlotCount());
	}

	function contentAreaHeight():Float
	{
		return sectionsViewportH - PANEL_PAD * 2;
	}

	function isFormScrollable():Bool
	{
		return totalScrollContentHeight() > contentAreaHeight();
	}

	function maxFormScrollIndex():Int
	{
		var count = scrollSlotCount();
		if (count == 0)
			return 0;

		var viewH = contentAreaHeight();
		if (totalScrollContentHeight() <= viewH)
			return 0;

		var sum = scrollSlotHeight(count - 1);
		var start = count - 1;
		while (start > 0)
		{
			var prevH = scrollSlotHeight(start - 1);
			if (sum + prevH > viewH)
				break;
			start--;
			sum += prevH;
		}
		return start;
	}

	function clampFormScroll():Void
	{
		formScrollIndex = Std.int(FlxMath.bound(formScrollIndex, 0, maxFormScrollIndex()));
	}

	function viewportBottomY():Float
	{
		return panelTopY + sectionsViewportH - PANEL_PAD;
	}

	function scrollContentTopY():Float
	{
		var y = panelTopY + PANEL_PAD;
		if (formScrollIndex == maxFormScrollIndex())
		{
			var tailH = totalScrollContentHeight() - scrollOffsetForIndex(formScrollIndex);
			var extra = contentAreaHeight() - tailH;
			if (extra > 0)
				y += extra;
		}
		return y;
	}

	function updateSubmitButton(calc):Void
	{
		submitButton.setEnabled(calc.ready);
	}

	function layoutCalcScrollSlot(y:Float, calc, calcSlot:Int):Void
	{
		var padX = areaX + FIELD_PAD_X;
		var innerW = contentW - FIELD_PAD_X * 2;
		var labelSize = Std.int(Math.max(10, fontSize - 1));
		var slotH = calcScrollSlotHeight(calcSlot);

		if (calcSlot == 0)
		{
			calcTitleText.text = "AFFORDABILITY ANALYSIS";
			calcTitleText.setFormat(null, labelSize, MonitorScreenUi.GREEN_DIM, "left");
			calcTitleText.fieldWidth = Std.int(innerW);
			calcTitleText.scale.set(1, 1);
			calcTitleText.setPosition(padX, y + 1);
			calcTitleText.visible = true;
			return;
		}

		var lineIdx = calcSlot - 1;
		if (lineIdx < 0 || lineIdx >= calc.lines.length || lineIdx >= calcLineTexts.length)
			return;

		var line = calc.lines[lineIdx];
		if (line.length == 0)
		{
			if (lineIdx < calcLineTexts.length)
				calcLineTexts[lineIdx].visible = false;
			if (lineIdx < calcValueTexts.length)
				calcValueTexts[lineIdx].visible = false;
			return;
		}

		var lineText = calcLineTexts[lineIdx];
		var valueText = lineIdx < calcValueTexts.length ? calcValueTexts[lineIdx] : null;
		if (valueText != null)
			valueText.visible = false;

		if (LoanAffordabilityCalculator.isSectionLine(line))
		{
			lineText.text = LoanAffordabilityCalculator.sectionLabel(line);
			lineText.setFormat(null, labelSize, MonitorScreenUi.GREEN, "left");
			lineText.color = MonitorScreenUi.GREEN;
			lineText.fieldWidth = Std.int(innerW);
			lineText.wordWrap = false;
			lineText.scale.set(1, 1);
			lineText.setPosition(padX, y + 1);
			lineText.visible = true;
			return;
		}

		var textY = y + Std.int((slotH - fontSize) * 0.5);
		if (!LoanAffordabilityCalculator.isDataLine(line) || valueText == null)
		{
			lineText.text = line;
			lineText.setFormat(null, fontSize, MonitorScreenUi.GREEN_CALC_VALUE, "left");
			lineText.color = MonitorScreenUi.GREEN_CALC_VALUE;
			lineText.fieldWidth = Std.int(innerW);
			lineText.wordWrap = false;
			lineText.scale.set(1, 1);
			lineText.setPosition(padX, textY);
			lineText.visible = true;
			return;
		}

		var parts = LoanAffordabilityCalculator.parseDataLine(line);
		var isVerdict = lineIdx == calc.lines.length - 1;
		var labelStr = parts.label + ": ";
		var valueColor = isVerdict ? calc.verdictColor : MonitorScreenUi.GREEN_CALC_VALUE;

		lineText.text = labelStr;
		lineText.setFormat(null, fontSize, MonitorScreenUi.GREEN_CALC_LABEL, "left");
		lineText.color = MonitorScreenUi.GREEN_CALC_LABEL;
		lineText.fieldWidth = Std.int(innerW);
		lineText.wordWrap = false;
		lineText.scale.set(1, 1);
		lineText.setPosition(padX, textY);
		lineText.visible = true;

		var labelW = calcTextWidth(lineText);
		valueText.text = parts.value;
		valueText.setFormat(null, fontSize, valueColor, "left");
		valueText.color = valueColor;
		valueText.fieldWidth = Std.int(Math.max(20, innerW - labelW));
		valueText.wordWrap = false;
		valueText.scale.set(1, 1);
		valueText.setPosition(padX + labelW, textY);
		valueText.visible = true;
	}

	function calcTextWidth(t:FlxText):Float
	{
		return t.textField.textWidth * t.scale.x;
	}

	function hideCalcTexts():Void
	{
		calcTitleText.visible = false;
		for (t in calcLineTexts)
			t.visible = false;
		for (t in calcValueTexts)
			t.visible = false;
	}

	function refreshCalculatedFields()
	{
		var calc = LoanAffordabilityCalculator.compute(collectFormData());
		var totalRow = getRowByPath("spendTotal");
		if (totalRow != null)
			totalRow.setDraft(calc.ready ? formatLor(calc.totalSpending) : "-");
		cachedCalcLines = calc.lines;
		cachedCalcScrollSlots = 1 + calc.lines.length;
		return calc;
	}

	static function formatLor(value:Float):String
	{
		var rounded = Std.int(Math.round(value));
		var digits = Std.string(rounded < 0 ? -rounded : rounded);
		var out = "";
		var count = 0;
		for (i in 0...digits.length)
		{
			var pos = digits.length - 1 - i;
			if (count > 0 && count % 3 == 0)
				out = "," + out;
			out = digits.charAt(pos) + out;
			count++;
		}
		return rounded < 0 ? "-" + out : out;
	}

	function layoutFormFields():Void
	{
		var calc = refreshCalculatedFields();
		clampFormScroll();
		updateSubmitButton(calc);

		var fieldX = areaX + FIELD_PAD_X;
		var fieldW = contentW - FIELD_PAD_X * 2;
		var focusPath = focusedPath != null ? focusedPath : "";
		var bottom = viewportBottomY();

		for (entry in formEntries)
			entry.visible = false;
		hideCalcTexts();

		var y = scrollContentTopY();

		for (slot in formScrollIndex...scrollSlotCount())
		{
			var slotH = scrollSlotHeight(slot);
			if (y + slotH > bottom)
				break;

			if (slot < formEntries.length)
			{
				var entry = formEntries[slot];
				entry.layout(fieldX, y, fieldW, fontSize, focusPath);
				entry.visible = true;
			}
			else
			{
				var calcSlot = slot - formEntries.length;
				layoutCalcScrollSlot(y, calc, calcSlot);
			}

			y += slotH;
		}

		updateScrollbar();

		if (ddOpen)
		{
			if (ddIsNationalIdSuggestions && focusedPath != "nationalId")
				closeDropdown();
			else
			{
				var ddRow = getRowByPath(ddPath);
				if (ddRow != null)
					layoutDropdownUnderRow(ddRow);
				else
					closeDropdown();
			}
		}
	}

	function syncOpenDropdown():Void
	{
		if (!ddOpen || view != LoanAppView.NewForm)
			return;

		var ddRow = getRowByPath(ddPath);
		if (ddRow != null && ddRow.visible)
			layoutDropdownUnderRow(ddRow);
		else
			closeDropdown();
	}

	function isInDropdownArea(mx:Float, my:Float):Bool
	{
		return ddOpen && ddBg.visible && ddBg.overlapsPoint(new FlxPoint(mx, my));
	}

	function drawFormPanel():Void
	{
		var panelW = Std.int(contentW);
		var panelH = Std.int(sectionsViewportH);
		formPanelBg.setPosition(areaX, panelTopY);
		formPanelBg.makeGraphic(panelW, panelH, 0xFF0A120E, true);
		drawRectBorder(formPanelBg, panelW, panelH, MonitorScreenUi.GREEN, 1);
		formPanelBg.updateHitbox();
		formPanelBg.visible = true;
	}

	function layoutScrollbar():Void
	{
		trackY = panelTopY + BTN_H;
		trackH = sectionsViewportH - BTN_H * 2;
		drawScrollColumn();
		scrollUpBtn.setPosition(scrollX, panelTopY);
		scrollTrack.setPosition(scrollX + 1, trackY);
		scrollDownBtn.setPosition(scrollX, panelTopY + sectionsViewportH - BTN_H);
		updateScrollbar();
	}

	function drawScrollColumn():Void
	{
		var colH = Std.int(sectionsViewportH);
		scrollColumn.setPosition(scrollX, panelTopY);
		scrollColumn.makeGraphic(SCROLL_W, colH, 0xFF0A120E, true);
		drawRectBorder(scrollColumn, SCROLL_W, colH, MonitorScreenUi.GREEN_DIM, 1);
		scrollColumn.updateHitbox();
		scrollColumn.visible = true;

		drawTriangleBtn(scrollUpBtn, SCROLL_W, BTN_H, true);
		drawTriangleBtn(scrollDownBtn, SCROLL_W, BTN_H, false);

		var innerTrackW = SCROLL_W - 2;
		var innerTrackH = Std.int(Math.max(1, trackH));
		scrollTrack.makeGraphic(innerTrackW, innerTrackH, 0xFF0D1A12, true);
		drawRectBorder(scrollTrack, innerTrackW, innerTrackH, MonitorScreenUi.GREEN_DIM, 1);
		scrollTrack.updateHitbox();
		scrollTrack.visible = true;
		scrollUpBtn.visible = true;
		scrollDownBtn.visible = true;
	}

	function updateScrollbar():Void
	{
		trackY = panelTopY + BTN_H;
		trackH = sectionsViewportH - BTN_H * 2;

		scrollColumn.visible = true;
		scrollTrack.visible = true;
		scrollUpBtn.visible = true;
		scrollDownBtn.visible = true;

		if (!isFormScrollable())
		{
			scrollThumb.visible = false;
			return;
		}

		var maxScroll = maxFormScrollIndex();
		thumbH = Std.int(Math.max(14, trackH * contentAreaHeight() / totalScrollContentHeight()));
		var travel = trackH - thumbH;
		var maxOffset = scrollOffsetForIndex(maxScroll);
		var offset = scrollOffsetForIndex(formScrollIndex);
		var t = maxOffset > 0 ? offset / maxOffset : 0;
		var thumbY = trackY + travel * t;

		scrollThumb.visible = true;
		if (thumbH != lastThumbH)
		{
			lastThumbH = thumbH;
			scrollThumb.makeGraphic(SCROLL_W - 6, thumbH, MonitorScreenUi.GREEN, true);
			drawRectBorder(scrollThumb, SCROLL_W - 6, thumbH, MonitorScreenUi.GREEN_BRIGHT, 1);
			scrollThumb.updateHitbox();
		}
		scrollThumb.setPosition(scrollX + 3, thumbY);
	}

	function hideScrollbar():Void
	{
		for (spr in [scrollColumn, scrollTrack, scrollThumb, scrollUpBtn, scrollDownBtn])
			spr.visible = false;
	}

	function handleFormScrollClick(mx:Float, my:Float):Bool
	{
		if (!scrollTrack.visible)
			return false;

		if (scrollUpBtn.overlapsPoint(new FlxPoint(mx, my)))
		{
			closeDropdown();
			scrollFormBy(-1);
			return true;
		}
		if (scrollDownBtn.overlapsPoint(new FlxPoint(mx, my)))
		{
			closeDropdown();
			scrollFormBy(1);
			return true;
		}
		if (scrollThumb.overlapsPoint(new FlxPoint(mx, my)))
		{
			thumbDragging = true;
			dragGrabY = my - scrollThumb.y;
			return true;
		}
		if (scrollTrack.overlapsPoint(new FlxPoint(mx, my)))
		{
			jumpScrollToTrackY(my);
			return true;
		}
		return false;
	}

	function syncScrollFromThumb():Void
	{
		if (!isFormScrollable())
			return;
		var travel = trackH - thumbH;
		if (travel <= 0)
			return;
		var t = (scrollThumb.y - trackY) / travel;
		jumpScrollToRatio(t);
	}

	function jumpScrollToTrackY(my:Float):Void
	{
		if (!isFormScrollable())
			return;
		var t = (my - trackY) / trackH;
		jumpScrollToRatio(t);
	}

	function jumpScrollToRatio(t:Float):Void
	{
		var maxScroll = maxFormScrollIndex();
		var maxOffset = scrollOffsetForIndex(maxScroll);
		var targetOffset = maxOffset * FlxMath.bound(t, 0, 1);
		var old = formScrollIndex;
		formScrollIndex = scrollIndexForOffset(targetOffset);
		clampFormScroll();
		if (formScrollIndex != old)
			layoutFormFields();
	}

	function scrollIndexForOffset(targetOffset:Float):Int
	{
		var best = 0;
		for (start in 0...scrollSlotCount())
		{
			if (scrollOffsetForIndex(start) <= targetOffset + 0.5)
				best = start;
		}
		return best;
	}

	function tryFocusField(mx:Float, my:Float):Bool
	{
		var bottom = viewportBottomY();
		var y = scrollContentTopY();
		for (slot in formScrollIndex...scrollSlotCount())
		{
			if (slot >= formEntries.length)
				break;
			var slotH = scrollSlotHeight(slot);
			if (y + slotH > bottom)
				break;

			var entry = formEntries[slot];
			var path = entry.tryFocusPath(mx, my);
			if (path != null)
			{
				var row = entry.getFieldRow(path);
				if (row != null)
				{
					if (row.isDropdown())
					{
						openDropdown(row);
						return true;
					}
					focusField(path);
					return true;
				}
			}
			y += slotH;
		}
		return false;
	}

	function focusField(path:String):Void
	{
		var sameField = focusedPath == path;
		if (!sameField)
		{
			closeDropdown();
			focusedPath = path;
			attachKeyListener();
		}
		layoutFormFields();
		if (path == "nationalId")
		{
			var row = getFocusedRow();
			if (row != null && row.getDraft().length > 0)
				updateNationalIdSuggestions(row);
		}
	}

	function blurField():Void
	{
		if (focusedPath == null)
			return;
		focusedPath = null;
		detachKeyListener();
		closeDropdown();
		layoutFormFields();
	}

	function getFocusedRow():Null<MonitorDetailFieldRow>
	{
		if (focusedPath == null)
			return null;
		return getRowByPath(focusedPath);
	}

	function attachKeyListener():Void
	{
		var stage = Lib.current.stage;
		if (stage == null)
			return;
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false, 0, true);
	}

	function detachKeyListener():Void
	{
		var stage = Lib.current.stage;
		if (stage == null)
			return;
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!visible || view != LoanAppView.NewForm)
			return;

		if (confirmDialog.isOpen())
		{
			if (confirmDialog.handleKey(e.keyCode))
				e.stopImmediatePropagation();
			return;
		}

		if (focusedPath == null)
			return;

		var row = getFocusedRow();
		if (row == null)
			return;

		if (e.keyCode == Keyboard.ESCAPE)
		{
			e.stopImmediatePropagation();
			blurField();
			return;
		}

		if (e.keyCode == Keyboard.BACKSPACE)
		{
			var draft = row.getDraft();
			if (draft.length > 0)
				row.setDraft(draft.substr(0, draft.length - 1));
		}
		else if (e.charCode > 32)
		{
			var code = e.charCode;
			if (row.digitsOnly)
			{
				if (!MonitorDetailFieldRow.acceptsNumericChar(code, row.getDraft(), row.allowDecimal))
				{
					e.stopImmediatePropagation();
					return;
				}
			}
			var ch = String.fromCharCode(code);
			var newDraft = row.getDraft() + ch;
			if (row.path == "term")
				newDraft = capTermDraft(newDraft);
			if (!row.textFits(newDraft))
			{
				e.stopImmediatePropagation();
				return;
			}
			row.setDraft(newDraft);
		}
		else
			return;

		e.stopImmediatePropagation();
		layoutFormFields();
		if (row.path == "nationalId")
			updateNationalIdSuggestions(row);
	}

	function updateNationalIdSuggestions(row:MonitorDetailFieldRow):Void
	{
		var draft = row.getDraft();
		if (focusedPath != "nationalId" || draft.length == 0)
		{
			if (ddIsNationalIdSuggestions)
				closeDropdown();
			return;
		}

		var matches = CitizenRegistry.nationalIdSuggestions(draft, MAX_NATIONAL_ID_SUGGESTIONS);
		if (matches.length == 0)
		{
			if (ddIsNationalIdSuggestions)
				closeDropdown();
			return;
		}

		ddIsNationalIdSuggestions = true;
		ddOpen = true;
		ddPath = row.path;
		ddCurrentValue = row.getDraft();
		ddChoices = [];
		ddNationalIds = [];
		for (c in matches)
		{
			ddChoices.push(CitizenRegistry.nationalIdSuggestionLine(c));
			ddNationalIds.push(c.nationalId);
		}
		layoutDropdownUnderRow(row);
	}

	function getRowByPath(path:String):Null<MonitorDetailFieldRow>
	{
		for (entry in formEntries)
		{
			var row = entry.getFieldRow(path);
			if (row != null)
				return row;
		}
		return null;
	}

	function capTermDraft(draft:String):String
	{
		if (draft.length == 0)
			return draft;
		var n = Std.parseInt(draft);
		if (n == null)
			return draft.substr(0, draft.length - 1);
		if (n > MAX_TERM)
			return Std.string(MAX_TERM);
		return draft;
	}

	function openDropdown(row:MonitorDetailFieldRow):Void
	{
		blurField();
		ddIsNationalIdSuggestions = false;
		ddNationalIds = [];
		ddOpen = true;
		ddPath = row.path;
		ddChoices = row.getChoices();
		ddCurrentValue = row.getDraft();
		layoutDropdownUnderRow(row);
	}

	function layoutDropdownUnderRow(row:MonitorDetailFieldRow):Void
	{
		var panelBottom = viewportBottomY();
		var panelTop = panelTopY + PANEL_PAD;
		ddItemH = fontSize + 8;
		var pad = 4;

		if (ddIsNationalIdSuggestions)
		{
			ddX = areaX + FIELD_PAD_X;
			ddW = contentW - FIELD_PAD_X * 2;
		}
		else
		{
			ddX = row.hit.x;
			ddW = row.hit.width;
		}

		var maxDropH = panelBottom - (row.hit.y + row.hit.height);
		if (maxDropH < ddItemH + pad * 2)
		{
			closeDropdown();
			return;
		}

		ddVisibleCount = ddChoices.length;
		var listH = ddVisibleCount * ddItemH + pad * 2;
		if (listH > maxDropH)
		{
			ddVisibleCount = Std.int(Math.max(1, Math.floor((maxDropH - pad * 2) / ddItemH)));
			listH = ddVisibleCount * ddItemH + pad * 2;
		}

		ddY = row.hit.y + row.hit.height;
		if (ddY + listH > panelBottom)
		{
			var aboveY = row.hit.y - listH;
			if (aboveY >= panelTop)
				ddY = aboveY;
		}

		ddBg.setPosition(ddX, ddY);
		ddBg.makeGraphic(Std.int(ddW), listH, 0xFF0A120E, true);
		drawRectBorder(ddBg, Std.int(ddW), listH, MonitorScreenUi.GREEN, 1);
		ddBg.visible = true;

		for (i in 0...MAX_DD)
		{
			var t = ddTxt[i];
			if (i < ddVisibleCount && i < ddChoices.length)
			{
				var itemY = ddY + pad + i * ddItemH;
				var hovered = isDropdownItemHovered(i, itemY, ddItemH);
				var isSelected = ddIsNationalIdSuggestions
					? (i < ddNationalIds.length && ddNationalIds[i] == ddCurrentValue)
					: ddChoices[i] == ddCurrentValue;
				t.text = ddChoices[i];
				t.setFormat(null, fontSize, hovered || isSelected ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN, "left");
				t.fieldWidth = Std.int(ddW - 12);
				t.scale.set(1, 1);
				t.setPosition(ddX + 6, itemY + (ddItemH - fontSize) * 0.5);
				t.visible = true;
			}
			else
				t.visible = false;
		}

		bringDropdownToFront();
	}

	function isDropdownItemHovered(i:Int, itemY:Float, itemH:Int, ?mx:Null<Float>, ?my:Null<Float>):Bool
	{
		var px = mx != null ? mx : FlxG.mouse.getViewPosition().x;
		var py = my != null ? my : FlxG.mouse.getViewPosition().y;
		return px >= ddX && px < ddX + ddW && py >= itemY && py < itemY + itemH;
	}

	function updateDropdownHover():Void
	{
		if (!ddOpen)
			return;

		for (i in 0...ddVisibleCount)
		{
			if (i >= ddTxt.length || !ddTxt[i].visible)
				continue;

			var itemY = ddY + 4 + i * ddItemH;
			var hovered = isDropdownItemHovered(i, itemY, ddItemH);
			var isSelected = ddIsNationalIdSuggestions
				? (i < ddNationalIds.length && ddNationalIds[i] == ddCurrentValue)
				: ddChoices[i] == ddCurrentValue;
			ddTxt[i].color = hovered || isSelected ? MonitorScreenUi.GREEN_BRIGHT : MonitorScreenUi.GREEN;
		}
	}

	function bringDropdownToFront():Void
	{
		remove(ddBg, false);
		add(ddBg);
		for (t in ddTxt)
		{
			if (t.visible)
			{
				remove(t, false);
				add(t);
			}
		}
		bringConfirmDialogToFront();
	}

	function closeDropdown():Void
	{
		ddOpen = false;
		ddIsNationalIdSuggestions = false;
		ddNationalIds = [];
		ddCurrentValue = "";
		ddVisibleCount = 0;
		ddBg.visible = false;
		for (t in ddTxt)
			t.visible = false;
	}

	function handleDropdownClick(mx:Float, my:Float):Bool
	{
		if (!ddBg.visible)
			return false;

		if (!ddBg.overlapsPoint(new FlxPoint(mx, my)))
			return false;

		var idx = -1;
		for (i in 0...ddVisibleCount)
		{
			var itemY = ddY + 4 + i * ddItemH;
			if (isDropdownItemHovered(i, itemY, ddItemH, mx, my))
			{
				idx = i;
				break;
			}
		}

		if (idx >= 0)
		{
			var row = getRowByPath(ddPath);
			if (row != null)
			{
				var value = ddIsNationalIdSuggestions && idx < ddNationalIds.length
					? ddNationalIds[idx] : ddChoices[idx];
				row.setDraft(value);
				row.commitDraft();
			}
		}
		closeDropdown();
		layoutFormFields();
		return true;
	}

	function hideAll():Void
	{
		titleText.visible = false;
		progressBanner.visible = false;
		formPanelBg.visible = false;
		for (row in menuRows)
			row.visible = false;
		for (entry in formEntries)
			entry.visible = false;
		backButton.visible = false;
		submitButton.visible = false;
		hideCalcTexts();
		hideScrollbar();
	}

	static function loanField(path:String, label:String, digitsOnly:Bool, isDropdown:Bool, ?required:Bool,
			?readOnly:Bool, ?choices:Array<String>, ?allowDecimal:Bool):CitizenDetailField
	{
		var fieldChoices:Array<String> = null;
		if (isDropdown)
			fieldChoices = choices != null ? choices : LOAN_TYPES;

		return {
			path: path,
			label: label,
			value: "",
			choices: fieldChoices,
			digitsOnly: digitsOnly,
			allowDecimal: allowDecimal == true,
			required: required == true,
			readOnly: readOnly == true
		};
	}

	function initFormEntries():Void
	{
		ensureFormEntryCount(5);
		resetFormEntries();
	}

	function ensureFormEntryCount(count:Int):Void
	{
		while (formEntries.length < count)
		{
			var entry = new MonitorDetailEntryRow();
			formEntries.push(entry);
			add(entry.left.labelText);
			add(entry.left.box);
			add(entry.left.valueText);
			add(entry.left.hit);
			add(entry.right.labelText);
			add(entry.right.box);
			add(entry.right.valueText);
			add(entry.right.hit);
		}
	}

	function resetFormEntries():Void
	{
		formEntries[0].setupPair(
			loanField("nationalId", "NATIONAL ID", false, false, true), "",
			loanField("loanType", "LOAN PRODUCT", false, true, true), ""
		);
		formEntries[1].setupPair(
			loanField("amount", "LOAN AMOUNT", true, false, true), "",
			loanField("term", "TERM (MONTHS)", true, false, true), ""
		);
		formEntries[2].setupPair(
			loanField("declaredSalary", "MONTHLY SALARY (LOR)", true, false, true, false, null, true), "",
			loanField("security", "SECURITY", false, true, true, false, SECURITY_TYPES), ""
		);
		formEntries[3].setupPair(
			loanField("spendHousing", "HOUSING / MO", true, false, true), "",
			loanField("spendLiving", "LIVING / MO", true, false, true), ""
		);
		formEntries[4].setupPair(
			loanField("spendOther", "OTHER SPENDING / MO", true, false, false), "",
			loanField("spendTotal", "TOTAL SPENDING / MO", false, false, false, true), ""
		);
	}

	function drawTriangleBtn(btn:FlxSprite, w:Int, h:Int, up:Bool):Void
	{
		btn.makeGraphic(w, h, 0xFF0D1A12, true);
		drawRectBorder(btn, w, h, MonitorScreenUi.GREEN_DIM, 1);

		var cx = Std.int(w * 0.5);
		var cy = Std.int(h * 0.5);
		var color = MonitorScreenUi.GREEN;

		for (i in 0...6)
		{
			var half = up ? i : (5 - i);
			var y = up ? (cy - 1 + i) : (cy - 4 + i);
			if (half >= 0)
				btn.pixels.fillRect(new Rectangle(cx - half, y, half * 2 + 1, 1), color);
		}

		btn.dirty = true;
		btn.updateHitbox();
		btn.visible = true;
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
