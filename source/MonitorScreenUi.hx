package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

enum MonitorTab
{
	Terminal;
	LoanApplication;
}

enum MonitorView
{
	MainMenu;
	ClientDatabase;
	ClientDetail;
	SystemStatus;
	CurrencyExchange;
	ConversationRecorder;
	LoanApplication;
}

class MonitorScreenUi extends FlxGroup
{
	public static inline var GREEN = 0xFF33FF66;
	public static inline var GREEN_DIM = 0xFF1A9940;
	public static inline var GREEN_BRIGHT = 0xFF66FF99;
	public static inline var GREEN_CALC_LABEL = 0xFF1F9A44;
	public static inline var GREEN_CALC_VALUE = 0xFF2BD062;
	public static inline var BG = 0xFF050A08;

	static inline var SHOW_TAB_BAR = false;

	static var MENU_ITEMS:Array<String> = [
		"Client Database",
		"Loan Application",
		"Conversation Recorder",
		"Currency Exchange",
		"System Status"
	];

	var screenX:Float = 0;
	var screenY:Float = 0;
	var screenW:Float = 0;
	var screenH:Float = 0;

	var view:MonitorView = MainMenu;
	var activeTab:MonitorTab = MonitorTab.Terminal;
	var loanState:LoanApplicationState;
	var loanApp:MonitorLoanApplication;
	var tabHits:Array<FlxSprite> = [];
	var tabLabels:Array<FlxText> = [];
	static var TAB_NAMES:Array<String> = ["Terminal", "Loan Application"];
	var tabBarH = 0.0;
	var contentY = 0.0;
	var bg:FlxSprite;
	var menuRows:Array<MonitorMenuRow> = [];
	var searchLabel:FlxText;
	var searchInputBox:FlxSprite;
	var searchField:FlxText;
	var searchHit:FlxSprite;
	var clientList:MonitorClientList;
	var clientDetail:MonitorClientDetail;
	var creditsPanel:MonitorCreditsPanel;
	var currencyExchangePanel:MonitorCurrencyExchangePanel;
	var conversationRecorderPanel:MonitorConversationRecorderPanel;
	var backButton:MonitorBackButton;
	var printButton:MonitorBackButton;
	var printButtonEnabled = true;
	var titleText:FlxText;
	var selectedCitizen:Citizen = null;
	public var onPrintRequest:Void->Bool;
	public var onConversationLogRequest:Void->Array<ConversationLogEntry>;
	public var tutorialClickFilter:Null<Float->Float->Bool> = null;
	public var onTutorialClickBlocked:Null<Float->Float->Void> = null;

	public function setPrintButtonEnabled(value:Bool):Void
	{
		printButtonEnabled = value;
		printButton.setEnabled(value);
	}

	public function setOnPrintRequest(cb:Void->Bool):Void
	{
		onPrintRequest = cb;
		loanApp.onPrintRequest = cb;
	}

	public function setOnPrintChecklistRequest(cb:Void->Bool):Void
	{
		loanApp.onPrintChecklistRequest = cb;
	}

	public function setOnSubmitForApprovalRequest(cb:Void->Bool):Void
	{
		loanApp.onSubmitForApprovalRequest = cb;
	}

	public function setOnLoanApplicationSubmitted(cb:Void->Void):Void
	{
		loanApp.onApplicationSubmitted = cb;
	}

	public function setValidateFieldEdit(cb:Null<(citizen:Citizen, path:String, value:String) -> Null<String>>):Void
	{
		clientDetail.validateFieldEdit = cb;
	}

	public function setOnFieldValidationFailed(cb:Null<(path:String, message:String) -> Bool>):Void
	{
		clientDetail.onFieldValidationFailed = cb;
	}

	public function setShouldRevertOnCoachValidation(cb:Null<String->Bool>):Void
	{
		clientDetail.shouldRevertOnCoachValidation = cb;
	}

	public function consumePendingLoanFolderSlide():Bool
	{
		return loanState.consumeFolderSlide();
	}

	public function consumePendingAutoPrintLoanForm():Bool
	{
		return loanState.consumeAutoPrintLoanForm();
	}

	public function getLoanId():Null<String>
	{
		return loanState.loanId;
	}

	public function getLoanApplicationData():Null<LoanApplicationData>
	{
		return loanState.data;
	}

	public function getTerminalPrintJob():TerminalPrintJob
	{
		return switch (view)
		{
			case ClientDetail:
				TerminalPrintJob.ClientDetails;
			case LoanApplication:
				TerminalPrintJob.LoanApplicationForm;
			default:
				TerminalPrintJob.LoanApplicationForm;
		}
	}

	public function getSelectedCitizen():Null<Citizen>
	{
		return selectedCitizen;
	}

	public function getSearchQuery():String
	{
		return searchQuery;
	}

	var searchQuery = "";
	var searchFocused = false;
	var searchKeyListenerAttached = false;
	var filtered:Array<Citizen> = [];
	var rowHeight = 14;
	var fontSize = 12;
	var menuFontSize = 14;
	var keyHandler:KeyboardEvent->Void;
	var lastLayoutW = -1.0;
	var lastLayoutH = -1.0;
	var lastConversationLogCount = -1;
	var listAreaY = 0.0;
	var searchRowY = 0.0;

	public function new()
	{
		super();
		filtered = [];
		loanState = new LoanApplicationState();

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, BG, true);
		bg.visible = false;
		add(bg);

		titleText = makeText("", menuFontSize + 2, GREEN_BRIGHT, "center");
		titleText.visible = false;
		add(titleText);

		for (i in 0...MENU_ITEMS.length)
		{
			var row = new MonitorMenuRow(MENU_ITEMS[i], isMenuItemEnabled(MENU_ITEMS[i]));
			menuRows.push(row);
			add(row.hit);
			add(row.label);
		}

		searchLabel = makeText("SEARCH", fontSize, GREEN_DIM, "left");
		searchInputBox = new FlxSprite();
		searchInputBox.visible = false;
		searchField = makeText("", fontSize, GREEN, "left");
		searchHit = new FlxSprite();
		searchHit.visible = false;
		add(searchLabel);
		add(searchInputBox);
		add(searchField);
		add(searchHit);

		clientList = new MonitorClientList();
		add(clientList);

		clientDetail = new MonitorClientDetail();
		add(clientDetail);

		creditsPanel = new MonitorCreditsPanel();
		add(creditsPanel);

		currencyExchangePanel = new MonitorCurrencyExchangePanel();
		add(currencyExchangePanel);

		conversationRecorderPanel = new MonitorConversationRecorderPanel();
		add(conversationRecorderPanel);

		backButton = new MonitorBackButton();
		printButton = new MonitorBackButton("PRINT >");
		add(backButton.hit);
		add(backButton.label);
		add(printButton.hit);
		add(printButton.label);

		for (i in 0...TAB_NAMES.length)
		{
			var hit = new FlxSprite();
			hit.visible = false;
			var lbl = makeText(TAB_NAMES[i], menuFontSize, GREEN_DIM, "center");
			lbl.visible = false;
			tabHits.push(hit);
			tabLabels.push(lbl);
			add(hit);
			add(lbl);
		}

		loanApp = new MonitorLoanApplication(loanState);
		loanApp.onInternalViewChanged = onLoanInternalViewChanged;
		loanApp.visible = false;
		add(loanApp);

		keyHandler = onKeyDown;
		view = MainMenu;
	}

	public function syncScreen(x:Float, y:Float, w:Float, h:Float):Void
	{
		screenX = x;
		screenY = y;
		screenW = w;
		screenH = h;

		bg.setPosition(x, y);
		bg.setGraphicSize(Std.int(w), Std.int(h));
		bg.updateHitbox();
		bg.visible = true;

		var newFont = Std.int(Math.max(13, h / 20));
		var newMenuFont = Std.int(Math.max(15, h / 16));
		var sizeChanged = Math.abs(w - lastLayoutW) > 0.5 || Math.abs(h - lastLayoutH) > 0.5;
		if (sizeChanged || newFont != fontSize || newMenuFont != menuFontSize)
		{
			fontSize = newFont;
			menuFontSize = newMenuFont;
			rowHeight = fontSize + 8;
			lastLayoutW = w;
			lastLayoutH = h;
			layout();
		}
		else
			syncPositionsOnly();
	}

	function syncPositionsOnly():Void
	{
		if (screenW <= 1 || screenH <= 1)
			return;

		bg.setPosition(screenX, screenY);
		syncTabBarPositions();
		if (SHOW_TAB_BAR && activeTab == MonitorTab.LoanApplication)
		{
			syncLoanContentBounds();
			return;
		}

		switch (view)
		{
			case MainMenu:
				syncMainMenuPositions();
			case ClientDatabase:
				syncDatabasePositions();
			case ClientDetail:
				syncDetailPositions();
			case SystemStatus:
				syncSystemStatusPositions();
			case CurrencyExchange:
				syncCurrencyExchangePositions();
			case ConversationRecorder:
				syncConversationRecorderPositions();
			case LoanApplication:
				syncLoanApplicationPositions();
		}
	}

	function syncMainMenuPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		applyText(titleText, titleText.text, menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, contentY);
		var rowH = menuFontSize + 14;
		var startY = titleText.y + titleText.height + pad;
		var rowGap = Std.int(Math.max(6, (screenH - contentY) * 0.025));
		for (i in 0...menuRows.length)
		{
			var row = menuRows[i];
			var ry = startY + i * (rowH + rowGap);
			row.layout(screenX + pad, ry, innerW, rowH, menuFontSize, GREEN, GREEN_DIM);
		}
	}

	function syncDatabasePositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		titleText.setPosition(screenX + pad, contentY);
		listAreaY = layoutSearchRow(pad, innerW, titleText.y + titleText.height + pad);
		var backH = fontSize + 10;
		var backX = screenX + pad;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(backX, backY);
		backButton.visible = true;
		printButton.visible = false;

		var listH = backButton.hit.y - listAreaY - 6;
		if (listH < rowHeight)
			listH = rowHeight;
		clientList.setBounds(screenX + pad, listAreaY, innerW, listH, rowHeight, fontSize);
	}

	public function reset():Void
	{
		CitizenRegistry.load();
		filtered = CitizenRegistry.all;
		activeTab = MonitorTab.Terminal;
		loanState.reset();
		loanApp.reset();
		setView(MainMenu);
		searchQuery = "";
		clientList.scrollIndex = 0;
		setSearchFocused(false);
	}

	public function suspendInput():Void
	{
		setSearchFocused(false);
		clientList.endDrag();
		clientDetail.suspendInput();
		currencyExchangePanel.endDrag();
		conversationRecorderPanel.endDrag();
		loanApp.suspendInput();
	}

	public function containsPoint(px:Float, py:Float):Bool
	{
		return px >= screenX && px < screenX + screenW && py >= screenY && py < screenY + screenH;
	}

	public function updateInput(px:Float, py:Float):Void
	{
		if (isLoanUiActive())
		{
			loanApp.updateDrag(px, py);
			return;
		}

		switch (view)
		{
			case ClientDatabase:
				clientList.updateDrag(px, py);
			case ClientDetail:
				clientDetail.updateDrag(px, py);
			case SystemStatus:
				creditsPanel.updateDrag(px, py);
			case CurrencyExchange:
				currencyExchangePanel.updateDrag(px, py);
			case ConversationRecorder:
				conversationRecorderPanel.updateDrag(px, py);
			default:
		}
	}

	public function handleRelease():Void
	{
		clientList.endDrag();
		clientDetail.endDrag();
		creditsPanel.endDrag();
		currencyExchangePanel.endDrag();
		conversationRecorderPanel.endDrag();
		loanApp.endDrag();
	}

	public function handleClick(px:Float, py:Float):Bool
	{
		if (!containsPoint(px, py))
			return false;

		if (tutorialClickFilter != null && !tutorialClickFilter(px, py))
		{
			if (onTutorialClickBlocked != null)
				onTutorialClickBlocked(px, py);
			return true;
		}

		if (SHOW_TAB_BAR && tryHandleTabClick(px, py))
			return true;

		if (SHOW_TAB_BAR && activeTab == MonitorTab.LoanApplication)
		{
			if (loanApp.isModalOpen())
				return loanApp.handleClick(px, py);
			return loanApp.handleClick(px, py);
		}

		switch (view)
		{
			case MainMenu:
				for (i in 0...menuRows.length)
				{
					var row = menuRows[i];
					if (row.enabled && row.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
					{
						if (MENU_ITEMS[i] == "System Status")
							setView(SystemStatus);
						else if (MENU_ITEMS[i] == "Client Database")
						{
							setView(ClientDatabase);
							focusSearchField();
						}
						else if (MENU_ITEMS[i] == "Loan Application")
							setView(MonitorView.LoanApplication);
						else if (MENU_ITEMS[i] == "Currency Exchange")
							setView(CurrencyExchange);
						else if (MENU_ITEMS[i] == "Conversation Recorder")
							setView(ConversationRecorder);
						return true;
					}
				}
			case LoanApplication:
				if (loanApp.isModalOpen())
					return loanApp.handleClick(px, py);
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					loanApp.suspendInput();
					setView(MainMenu);
					return true;
				}
				return loanApp.handleClick(px, py);
			case SystemStatus:
				if (creditsPanel.handleClick(px, py))
					return true;
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					setView(MainMenu);
					return true;
				}
			case CurrencyExchange:
				if (currencyExchangePanel.handleClick(px, py))
					return true;
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					setView(MainMenu);
					return true;
				}
			case ConversationRecorder:
				if (conversationRecorderPanel.handleClick(px, py))
					return true;
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					setView(MainMenu);
					return true;
				}
			case ClientDatabase:
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					setView(MainMenu);
					return true;
				}
				var rowIdx = clientList.trySelectRow(px, py);
				if (rowIdx >= 0 && rowIdx < filtered.length)
				{
					openClientDetail(filtered[rowIdx]);
					return true;
				}
				if (clientList.handleClick(px, py))
					return true;
				if (searchHit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					setSearchFocused(true);
					return true;
				}
				setSearchFocused(false);
			case ClientDetail:
				if (clientDetail.isModalOpen())
					return clientDetail.handleClick(px, py);
				if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					if (clientDetail.hasPendingEdit())
					{
						clientDetail.suspendInput();
						return true;
					}
					setView(ClientDatabase);
					return true;
				}
				if (printButton.visible && printButton.isEnabled()
					&& printButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
				{
					if (clientDetail.hasPendingEdit())
					{
						clientDetail.suspendInput();
						return true;
					}
					var printed = onPrintRequest != null && onPrintRequest();
					if (!printed)
						clientDetail.showWarning("You need to free up printer\notherwise you cant print.", function() {});
					return true;
				}
				if (clientDetail.handleClick(px, py))
					return true;
		}
		return true;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!visible || screenW <= 0)
			return;

		if (isLoanUiActive())
		{
			if (!loanApp.isModalOpen())
			{
				var loanMouse = FlxG.mouse.getViewPosition();
				if (loanMouse.x >= screenX && loanMouse.x < screenX + screenW
					&& loanMouse.y >= contentY && loanMouse.y < screenY + screenH)
					loanApp.handleWheel(FlxG.mouse.wheel);
			}
		}

		switch (view)
		{
			case ClientDatabase:
				if (searchFocused && FlxG.keys.justPressed.ESCAPE)
					setSearchFocused(false);

				if (searchFocused && FlxG.keys.justPressed.SPACE)
				{
					searchQuery += " ";
					refreshListData();
					refreshSearchRow();
				}

				var listMouse = FlxG.mouse.getViewPosition();
				if (clientList.isInListArea(listMouse.x, listMouse.y))
					clientList.handleWheel(FlxG.mouse.wheel);
			case ClientDetail:
				if (!clientDetail.isModalOpen())
				{
					var detailMouse = FlxG.mouse.getViewPosition();
					if (clientDetail.isInPanelArea(detailMouse.x, detailMouse.y))
						clientDetail.handleWheel(FlxG.mouse.wheel);
				}
			case SystemStatus:
				var creditsMouse = FlxG.mouse.getViewPosition();
				if (creditsPanel.isInPanelArea(creditsMouse.x, creditsMouse.y))
					creditsPanel.handleWheel(FlxG.mouse.wheel);
			case CurrencyExchange:
				currencyExchangePanel.updateTick(elapsed);
				var exchangeMouse = FlxG.mouse.getViewPosition();
				if (currencyExchangePanel.isInPanelArea(exchangeMouse.x, exchangeMouse.y))
					currencyExchangePanel.handleWheel(FlxG.mouse.wheel);
			case ConversationRecorder:
				refreshConversationRecorderIfNeeded();
				var recorderMouse = FlxG.mouse.getViewPosition();
				if (conversationRecorderPanel.isInPanelArea(recorderMouse.x, recorderMouse.y))
					conversationRecorderPanel.handleWheel(FlxG.mouse.wheel);
			default:
		}
	}

	public function updateHoverState():Void
	{
		if (!visible || screenW <= 0)
			return;

		var mouse = FlxG.mouse.getViewPosition();
		if (SHOW_TAB_BAR)
			updateTabHover(mouse.x, mouse.y);

		if (isLoanUiActive())
		{
			if (view == MonitorView.LoanApplication && backButton.visible)
				backButton.updateHover(mouse.x, mouse.y);
			loanApp.updateHover(mouse.x, mouse.y);
			return;
		}

		switch (view)
		{
			case MainMenu:
				for (row in menuRows)
					row.updateHover(mouse.x, mouse.y);
			case ClientDatabase:
				clientList.updateHover(mouse.x, mouse.y);
				if (backButton.visible)
					backButton.updateHover(mouse.x, mouse.y);
			case ClientDetail:
				if (backButton.visible)
					backButton.updateHover(mouse.x, mouse.y);
				if (printButton.visible)
					printButton.updateHover(mouse.x, mouse.y);
			case SystemStatus:
				if (backButton.visible)
					backButton.updateHover(mouse.x, mouse.y);
			case CurrencyExchange:
				if (backButton.visible)
					backButton.updateHover(mouse.x, mouse.y);
			case ConversationRecorder:
				if (backButton.visible)
					backButton.updateHover(mouse.x, mouse.y);
			case LoanApplication:
		}
	}

	function layout():Void
	{
		if (screenW <= 1 || screenH <= 1)
			return;

		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		layoutTabBar(pad, innerW);

		if (SHOW_TAB_BAR && activeTab == MonitorTab.LoanApplication)
		{
			hideTerminalContent();
			layoutLoanApplication(pad, innerW);
			return;
		}

		hideLoanContent();

		switch (view)
		{
			case MainMenu:
				layoutMainMenu(pad, innerW);
			case ClientDatabase:
				layoutClientDatabase(pad, innerW);
			case ClientDetail:
				layoutClientDetail(pad, innerW);
			case SystemStatus:
				layoutSystemStatus(pad, innerW);
			case CurrencyExchange:
				layoutCurrencyExchange(pad, innerW);
			case ConversationRecorder:
				layoutConversationRecorder(pad, innerW);
			case LoanApplication:
				layoutLoanApplicationView(pad, innerW);
		}
	}

	function layoutMainMenu(pad:Int, innerW:Float):Void
	{
		applyText(titleText, "CoolMath Bank Terminal v.2.1", menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, contentY);
		titleText.visible = true;

		var rowH = menuFontSize + 14;
		var startY = titleText.y + titleText.height + pad;
		var rowGap = Std.int(Math.max(6, (screenH - contentY) * 0.025));

		for (i in 0...menuRows.length)
		{
			var row = menuRows[i];
			var ry = startY + i * (rowH + rowGap);
			row.layout(screenX + pad, ry, innerW, rowH, menuFontSize, GREEN, GREEN_DIM);
			row.visible = true;
		}

		hideDatabaseWidgets();
	}

	function layoutClientDatabase(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		hideCreditsWidgets();
		hideCurrencyExchangeWidgets();
		hideConversationRecorderWidgets();
		clientDetail.hide();

		applyText(titleText, "CLIENT DATABASE", menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, contentY);
		titleText.visible = true;

		listAreaY = layoutSearchRow(pad, innerW, titleText.y + titleText.height + pad);

		var backH = fontSize + 10;
		var backW = innerW * 0.35;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, backW, backH, fontSize);
		printButton.layout(screenX + pad + innerW - backW, screenY + screenH - pad - backH, backW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = true;
		printButton.setEnabled(printButtonEnabled);

		var listH = backButton.hit.y - listAreaY - 6;
		if (listH < rowHeight)
			listH = rowHeight;

		clientList.setBounds(screenX + pad, listAreaY, innerW, listH, rowHeight, fontSize);
		clientList.applyData(filtered);
	}

	function layoutClientDetail(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		hideCreditsWidgets();
		hideCurrencyExchangeWidgets();
		hideConversationRecorderWidgets();
		hideDatabaseListWidgets();

		var name = selectedCitizen != null ? CitizenRegistry.displayName(selectedCitizen) : "CLIENT RECORD";
		applyText(titleText, name.toUpperCase(), menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, contentY);
		titleText.visible = true;

		var backH = fontSize + 10;
		var backW = innerW * 0.35;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, backW, backH, fontSize);
		printButton.layout(screenX + pad + innerW - backW, screenY + screenH - pad - backH, backW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = true;
		printButton.setEnabled(printButtonEnabled);

		var panelY = titleText.y + titleText.height + pad;
		var panelH = backButton.hit.y - panelY - 6;
		if (panelH < rowHeight)
			panelH = rowHeight;

		if (selectedCitizen != null)
			clientDetail.setCitizen(selectedCitizen, false);
		clientDetail.setBounds(screenX + pad, panelY, innerW, panelH, fontSize);
	}

	function syncDetailPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		titleText.setPosition(screenX + pad, contentY);

		var backH = fontSize + 10;
		var backX = screenX + pad;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(backX, backY);
		printButton.reposition(screenX + pad + innerW - backButton.hit.width, backY);
		backButton.visible = true;
		printButton.visible = true;
		printButton.setEnabled(printButtonEnabled);

		var panelY = titleText.y + titleText.height + pad;
		var panelH = backButton.hit.y - panelY - 6;
		if (panelH < rowHeight)
			panelH = rowHeight;

		clientDetail.reposition(screenX + pad, panelY, innerW, panelH);
	}

	function openClientDetail(c:Citizen):Void
	{
		selectedCitizen = c;
		setSearchFocused(false);
		setView(ClientDetail);
	}

	public function openTutorialCitizen(index:Int):Void
	{
		if (index < 0 || index >= CitizenRegistry.all.length)
			return;
		openClientDetail(CitizenRegistry.all[index]);
	}

	function layoutSearchRow(pad:Int, innerW:Float, y:Float):Float
	{
		searchRowY = y;
		var rowH = fontSize + 12;
		var leftX = screenX + pad;
		var labelW = Std.int(Math.max(56, innerW * 0.18));

		applyText(searchLabel, "SEARCH", fontSize, GREEN_DIM, "left", labelW);
		searchLabel.setPosition(leftX, y + (rowH - fontSize) * 0.5);
		searchLabel.visible = true;

		var gap = 6;
		var boxX = leftX + labelW + gap;
		var boxW = Std.int(leftX + innerW - boxX);
		var boxH = rowH;

		searchInputBox.setPosition(boxX, y);
		drawInputBox(searchInputBox, boxW, boxH, searchFocused);
		searchInputBox.visible = true;

		updateSearchField(boxX, y, boxW, boxH);
		searchHit.setPosition(boxX, y);
		searchHit.setGraphicSize(boxW, boxH);
		searchHit.makeGraphic(boxW, boxH, 0x01000000, true);
		searchHit.updateHitbox();
		searchHit.visible = true;

		return y + rowH + 8;
	}

	function updateSearchField(boxX:Float, y:Float, boxW:Int, boxH:Int):Void
	{
		var textPad = 6;
		applyText(searchField, searchQuery + (searchFocused ? "_" : ""), fontSize, GREEN, "left", boxW - textPad * 2);
		searchField.setPosition(boxX + textPad, y + (boxH - fontSize) * 0.5);
		searchField.visible = true;
	}

	function drawInputBox(box:FlxSprite, w:Int, h:Int, focused:Bool):Void
	{
		var fill = 0xFF0A120E;
		var border = focused ? GREEN : GREEN_DIM;
		box.makeGraphic(w, h, fill, true);
		drawRectBorder(box, w, h, border, 1);
		box.updateHitbox();
	}

	function drawRectBorder(sprite:FlxSprite, width:Int, height:Int, color:Int, size:Int):Void
	{
		sprite.pixels.fillRect(new Rectangle(0, 0, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, height - size, width, size), color);
		sprite.pixels.fillRect(new Rectangle(0, 0, size, height), color);
		sprite.pixels.fillRect(new Rectangle(width - size, 0, size, height), color);
		sprite.dirty = true;
	}

	function layoutSystemStatus(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		titleText.visible = false;
		hideDatabaseListWidgets();
		hideCurrencyExchangeWidgets();
		hideConversationRecorderWidgets();
		clientDetail.hide();

		layoutCreditsPanel(pad, innerW);

		var backH = fontSize + 10;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, innerW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = false;
	}

	function syncSystemStatusPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		syncCreditsPanel(pad, innerW);

		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(screenX + pad, backY);
		backButton.visible = true;
		printButton.visible = false;
	}

	function layoutCreditsPanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		creditsPanel.setBounds(boxX, boxY, boxW, boxH, fontSize);
	}

	function syncCreditsPanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		creditsPanel.reposition(boxX, boxY, boxW, boxH);
	}

	function hideCreditsWidgets():Void
	{
		creditsPanel.hide();
	}

	function hideCurrencyExchangeWidgets():Void
	{
		currencyExchangePanel.hide();
	}

	function hideConversationRecorderWidgets():Void
	{
		conversationRecorderPanel.hide();
	}

	function layoutCurrencyExchange(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		titleText.visible = false;
		hideDatabaseListWidgets();
		clientDetail.hide();
		hideCreditsWidgets();
		hideConversationRecorderWidgets();

		layoutCurrencyExchangePanel(pad, innerW);

		var backH = fontSize + 10;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, innerW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = false;
	}

	function syncCurrencyExchangePositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		syncCurrencyExchangePanel(pad, innerW);

		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(screenX + pad, backY);
		backButton.visible = true;
		printButton.visible = false;
	}

	function layoutCurrencyExchangePanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		currencyExchangePanel.setBounds(boxX, boxY, boxW, boxH, fontSize);
	}

	function syncCurrencyExchangePanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		currencyExchangePanel.reposition(boxX, boxY, boxW, boxH);
	}

	function hideDatabaseWidgets():Void
	{
		hideDatabaseListWidgets();
		hideCreditsWidgets();
		hideCurrencyExchangeWidgets();
		hideConversationRecorderWidgets();
		clientDetail.hide();
		backButton.visible = false;
		printButton.visible = false;
	}

	function hideDatabaseListWidgets():Void
	{
		searchLabel.visible = false;
		searchInputBox.visible = false;
		searchField.visible = false;
		searchHit.visible = false;
		clientList.hide();
	}

	function setView(next:MonitorView):Void
	{
		var prev = view;
		if (next != prev)
			suspendInput();
		view = next;

		if (view == ClientDatabase || view == ClientDetail)
			DebugOverlay.hide();

		if (view == MainMenu)
		{
			setSearchFocused(false);
			searchQuery = "";
			clientList.scrollIndex = 0;
			creditsPanel.scrollIndex = 0;
			currencyExchangePanel.scrollIndex = 0;
			filtered = CitizenRegistry.all;
			selectedCitizen = null;
		}
		else if (view == ClientDatabase && prev == MainMenu)
			refreshListData();
		else if (view == SystemStatus)
			creditsPanel.scrollIndex = 0;
		else if (view == CurrencyExchange)
			currencyExchangePanel.scrollIndex = 0;
		else if (view == ConversationRecorder)
			refreshConversationRecorder();
		else if (view == MonitorView.LoanApplication && prev != MonitorView.LoanApplication)
			loanApp.showMenu();

		layout();
	}

	public function focusSearchField():Void
	{
		if (view == ClientDatabase)
			setSearchFocused(true);
	}

	function setSearchFocused(focused:Bool):Void
	{
		var wasFocused = searchFocused;
		searchFocused = focused;
		var stage = Lib.current.stage;
		searchKeyListenerAttached = MonitorKeyboard.detach(stage, keyHandler, searchKeyListenerAttached);
		if (searchFocused)
			searchKeyListenerAttached = MonitorKeyboard.attach(stage, keyHandler, false);

		if (wasFocused != focused && view == ClientDatabase)
			refreshSearchRow();
	}

	function refreshSearchRow():Void
	{
		if (screenW <= 1)
			return;
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		var rowH = fontSize + 12;
		var labelW = Std.int(Math.max(56, innerW * 0.18));
		var boxX = screenX + pad + labelW + 6;
		var boxW = Std.int(screenX + pad + innerW - boxX);
		drawInputBox(searchInputBox, boxW, rowH, searchFocused);
		updateSearchField(boxX, searchRowY, boxW, rowH);
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!searchFocused || view != ClientDatabase)
			return;

		if (e.keyCode == Keyboard.BACKSPACE)
		{
			if (searchQuery.length > 0)
				searchQuery = searchQuery.substr(0, searchQuery.length - 1);
		}
		else if (e.keyCode == Keyboard.ESCAPE)
		{
			setSearchFocused(false);
			return;
		}
		else
		{
			var ch = MonitorKeyboard.typedCharacter(e);
			if (ch == null)
				return;
			searchQuery += ch;
		}

		e.stopImmediatePropagation();
		refreshListData();
		refreshSearchRow();
	}

	function refreshListData():Void
	{
		filtered = CitizenRegistry.search(searchQuery);
		if (view == ClientDatabase)
			clientList.setData(filtered);
	}

	function makeText(text:String, size:Int, color:Int, align:String, fieldWidth:Int = 100):FlxText
	{
		var t = new FlxText(0, 0, fieldWidth, text);
		applyText(t, text, size, color, align, fieldWidth);
		return t;
	}

	function applyText(t:FlxText, text:String, size:Int, color:Int, align:String, fieldWidth:Int):Void
	{
		t.text = text;
		t.setFormat(null, size, color, align);
		t.fieldWidth = fieldWidth;
		t.scale.set(1, 1);
	}

	override function destroy():Void
	{
		setSearchFocused(false);
		clientDetail.suspendInput();
		loanApp.suspendInput();
		DebugOverlay.hide();
		super.destroy();
	}

	function isMenuItemEnabled(label:String):Bool
	{
		return label == "Client Database" || label == "Loan Application" || label == "Conversation Recorder"
			|| label == "Currency Exchange" || label == "System Status";
	}

	function layoutConversationRecorder(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		applyText(titleText, "CONVERSATION RECORDER", menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, contentY);
		titleText.visible = true;

		hideDatabaseListWidgets();
		clientDetail.hide();
		hideCreditsWidgets();
		hideCurrencyExchangeWidgets();

		layoutConversationRecorderPanel(pad, innerW);

		var backH = fontSize + 10;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, innerW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = false;
	}

	function syncConversationRecorderPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		titleText.setPosition(screenX + pad, contentY);
		syncConversationRecorderPanel(pad, innerW);

		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(screenX + pad, backY);
		backButton.visible = true;
		printButton.visible = false;
	}

	function layoutConversationRecorderPanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY + titleText.height + pad;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		refreshConversationRecorder();
		conversationRecorderPanel.setBounds(boxX, boxY, boxW, boxH, fontSize);
	}

	function syncConversationRecorderPanel(pad:Int, innerW:Float):Void
	{
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var boxX = screenX + pad;
		var boxY = contentY + titleText.height + pad;
		var boxW = innerW;
		var boxH = backY - boxY - 8;
		if (boxH < 1)
			boxH = 1;

		conversationRecorderPanel.reposition(boxX, boxY, boxW, boxH);
	}

	public function refreshOnShow():Void
	{
		if (view == ConversationRecorder)
			refreshConversationRecorder();
	}

	function refreshConversationRecorder():Void
	{
		var entries = onConversationLogRequest != null ? onConversationLogRequest() : [];
		lastConversationLogCount = entries.length;
		conversationRecorderPanel.setEntries(entries);
		conversationRecorderPanel.scrollToEnd();
	}

	function refreshConversationRecorderIfNeeded():Void
	{
		var entries = onConversationLogRequest != null ? onConversationLogRequest() : [];
		if (entries.length == lastConversationLogCount)
			return;
		refreshConversationRecorder();
	}

	function isLoanUiActive():Bool
	{
		return (SHOW_TAB_BAR && activeTab == MonitorTab.LoanApplication) || view == MonitorView.LoanApplication;
	}

	function onLoanInternalViewChanged():Void
	{
		if (view == MonitorView.LoanApplication || (SHOW_TAB_BAR && activeTab == MonitorTab.LoanApplication))
			layout();
	}

	function layoutTabBar(pad:Int, innerW:Float):Void
	{
		if (!SHOW_TAB_BAR)
		{
			for (i in 0...tabHits.length)
			{
				tabHits[i].visible = false;
				tabLabels[i].visible = false;
			}
			contentY = screenY + pad;
			return;
		}

		tabBarH = menuFontSize + 16;
		var tabW = innerW / TAB_NAMES.length;
		var tabY = screenY + pad;
		for (i in 0...TAB_NAMES.length)
		{
			var tx = screenX + pad + i * tabW;
			var active = (i == 0 && activeTab == MonitorTab.Terminal) || (i == 1 && activeTab == MonitorTab.LoanApplication);
			tabHits[i].setPosition(tx, tabY);
			tabHits[i].makeGraphic(Std.int(tabW - 2), Std.int(tabBarH), active ? 0xFF143020 : 0xFF0A120E, true);
			drawRectBorder(tabHits[i], Std.int(tabW - 2), Std.int(tabBarH), active ? GREEN : GREEN_DIM, 1);
			tabHits[i].updateHitbox();
			tabHits[i].visible = true;

			applyText(tabLabels[i], TAB_NAMES[i], menuFontSize - 1, active ? GREEN_BRIGHT : GREEN_DIM, "center", Std.int(tabW - 2));
			tabLabels[i].setPosition(tx, tabY + (tabBarH - (menuFontSize - 1)) * 0.5);
			tabLabels[i].visible = true;
		}
		contentY = tabY + tabBarH + pad;
	}

	function syncTabBarPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		layoutTabBar(pad, innerW);
	}

	function tryHandleTabClick(px:Float, py:Float):Bool
	{
		if (!SHOW_TAB_BAR)
			return false;

		for (i in 0...tabHits.length)
		{
			if (tabHits[i].visible && tabHits[i].overlapsPoint(new flixel.math.FlxPoint(px, py)))
			{
				var next = i == 0 ? MonitorTab.Terminal : MonitorTab.LoanApplication;
				setTab(next);
				return true;
			}
		}
		return false;
	}

	function updateTabHover(mx:Float, my:Float):Void
	{
		if (!SHOW_TAB_BAR)
			return;

		for (i in 0...tabHits.length)
		{
			var active = (i == 0 && activeTab == MonitorTab.Terminal) || (i == 1 && activeTab == MonitorTab.LoanApplication);
			var over = tabHits[i].visible && tabHits[i].overlapsPoint(new flixel.math.FlxPoint(mx, my));
			tabLabels[i].color = active ? GREEN_BRIGHT : (over ? GREEN : GREEN_DIM);
		}
	}

	function setTab(next:MonitorTab):Void
	{
		if (activeTab == next)
			return;

		setSearchFocused(false);
		clientDetail.suspendInput();
		loanApp.suspendInput();

		activeTab = next;
		if (activeTab == MonitorTab.LoanApplication)
			loanApp.showMenu();
		else
			setView(MainMenu);

		layout();
	}

	function layoutLoanApplication(pad:Int, innerW:Float):Void
	{
		loanApp.visible = true;
		syncLoanContentBounds(pad, innerW);
	}

	function layoutLoanApplicationView(pad:Int, innerW:Float):Void
	{
		for (row in menuRows)
			row.visible = false;

		hideDatabaseWidgets();
		titleText.visible = false;

		var backH = fontSize + 10;
		var backW = innerW * 0.35;
		var backY = screenY + screenH - pad - backH;
		var onLoanMenu = loanApp.isOnMenu();

		backButton.layout(screenX + pad, backY, backW, backH, fontSize);
		backButton.visible = onLoanMenu;
		printButton.visible = false;

		loanApp.visible = true;
		var panelY = contentY;
		var panelBottom = onLoanMenu ? backButton.hit.y : screenY + screenH - pad;
		var panelH = panelBottom - panelY - 6;
		if (panelH < 1)
			panelH = 1;
		loanApp.setBounds(screenX + pad, panelY, innerW, panelH, fontSize, menuFontSize);
	}

	function syncLoanApplicationPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		var backH = fontSize + 10;
		var backY = screenY + screenH - pad - backH;
		var onLoanMenu = loanApp.isOnMenu();

		if (onLoanMenu)
		{
			backButton.reposition(screenX + pad, backY);
			backButton.visible = true;
		}
		else
			backButton.visible = false;

		var panelY = contentY;
		var panelBottom = onLoanMenu ? backButton.hit.y : screenY + screenH - pad;
		var panelH = panelBottom - panelY - 6;
		if (panelH < 1)
			panelH = 1;
		loanApp.setBounds(screenX + pad, panelY, innerW, panelH, fontSize, menuFontSize);
	}

	function syncLoanContentBounds(?pad:Int = null, ?innerW:Float = null):Void
	{
		if (pad == null)
			pad = Std.int(Math.max(8, screenW * 0.04));
		if (innerW == null)
			innerW = screenW - pad * 2;
		var contentH = screenY + screenH - contentY - pad;
		if (contentH < 1)
			contentH = 1;
		loanApp.setBounds(screenX + pad, contentY, innerW, contentH, fontSize, menuFontSize);
	}

	function hideTerminalContent():Void
	{
		hideDatabaseWidgets();
		for (row in menuRows)
			row.visible = false;
		titleText.visible = false;
	}

	function hideLoanContent():Void
	{
		loanApp.visible = false;
		loanApp.suspendInput();
	}

	public function getCurrentView():MonitorView
	{
		return view;
	}

	public function isOnMainMenu():Bool
	{
		return view == MainMenu;
	}

	public function isOnClientDatabase():Bool
	{
		return view == ClientDatabase;
	}

	public function isOnClientDetail():Bool
	{
		return view == ClientDetail;
	}

	public function isOnLoanApplication():Bool
	{
		return view == LoanApplication;
	}

	public function isOnLoanNewForm():Bool
	{
		return isOnLoanApplication() && loanApp.isOnNewForm();
	}

	public function getLoanFocusedFieldPath():Null<String>
	{
		if (!isOnLoanApplication())
			return null;
		return loanApp.getFocusedFieldPath();
	}

	public function hasLoanFieldValue(path:String):Bool
	{
		if (!isOnLoanApplication())
			return false;
		return loanApp.hasFieldValue(path);
	}

	public function getLoanFieldValue(path:String):String
	{
		if (!isOnLoanApplication())
			return "";
		return loanApp.getFieldValue(path);
	}

	public function getLoanMonthlyPayment():Float
	{
		if (!isOnLoanNewForm())
			return 0;
		return loanApp.getMonthlyPayment();
	}

	public function ensureLoanCalcPaymentVisible():Void
	{
		if (!isOnLoanNewForm())
			return;
		loanApp.ensureCalcPaymentVisible();
	}

	public function isLoanFormScrolledToBottom():Bool
	{
		if (!isOnLoanNewForm())
			return false;
		return loanApp.isScrolledToBottom();
	}

	public function isLoanFormScrolledNearBottom():Bool
	{
		if (!isOnLoanNewForm())
			return false;
		return loanApp.isScrolledNearBottom();
	}

	public function getLoanAffordabilityVerdict():String
	{
		if (!isOnLoanNewForm())
			return "";
		return loanApp.getAffordabilityVerdict();
	}

	public function isTutorialBackClick(px:Float, py:Float):Bool
	{
		if (backButton.visible && backButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
			return true;
		return false;
	}

	public function isTutorialMenuClick(px:Float, py:Float, kind:String):Bool
	{
		if (view != MainMenu)
			return false;
		return switch (kind)
		{
			case "menu_loan_application":
				menuRows.length > 1 && menuRows[1].enabled
					&& menuRows[1].hit.overlapsPoint(new flixel.math.FlxPoint(px, py));
			default:
				false;
		};
	}

	public function isTutorialLoanMenuClick(px:Float, py:Float, index:Int):Bool
	{
		if (!isOnLoanApplication())
			return false;
		return loanApp.isMenuClick(px, py, index);
	}

	public function isTutorialLoanSubmitClick(px:Float, py:Float):Bool
	{
		if (!isOnLoanNewForm())
			return false;
		var bounds = getTutorialHighlight("loan_submit_button");
		if (bounds == null)
			return false;
		return px >= bounds.x && px < bounds.x + bounds.w && py >= bounds.y && py < bounds.y + bounds.h;
	}

	public function prefillTutorialSearch(query:String):Void
	{
		searchQuery = query;
		if (view == ClientDatabase)
		{
			refreshListData();
			refreshSearchRow();
		}
	}

	public function ensureTutorialFieldVisible(path:String):Void
	{
		if (view == ClientDetail)
			clientDetail.ensureFieldVisible(path);
	}

	public function isConfirmModalOpen():Bool
	{
		return view == ClientDetail && clientDetail.isModalOpen();
	}

	public function getTutorialHighlight(kind:String):Null<TutorialGuideRect>
	{
		return switch (kind)
		{
			case "menu_client_database":
				if (view != MainMenu || menuRows.length == 0)
					null;
				else
					spriteRect(menuRows[0].hit);
			case "search_field":
				if (view != ClientDatabase || !searchInputBox.visible)
					null;
				else
					spriteRect(searchInputBox);
			case "client_row":
				getTutorialClientRowBounds();
			case "salary_field":
				if (view != ClientDetail)
					null;
				else
					clientDetail.getFieldBounds("averageAnnualSalary");
			case "print_button":
				if (view != ClientDetail || !printButton.visible)
					null;
				else
					spriteRect(printButton.hit);
			case "menu_loan_application":
				if (view != MainMenu || menuRows.length < 2)
					null;
				else
					spriteRect(menuRows[1].hit);
			case "loan_new_application":
				loanApp.getMenuRowBounds(0);
			case "loan_print_checklist":
				if (!isOnLoanApplication())
					null;
				else
					loanApp.getMenuRowBounds(1);
			case "loan_print_application":
				if (!isOnLoanApplication())
					null;
				else
					loanApp.getMenuRowBounds(2);
			case "loan_submit_approval":
				if (!isOnLoanApplication())
					null;
				else
					loanApp.getMenuRowBounds(3);
			case "loan_national_id":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("nationalId");
			case "loan_loan_type":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("loanType");
			case "loan_amount":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("amount");
			case "loan_term":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("term");
			case "loan_declared_salary":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("declaredSalary");
			case "loan_security":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("security");
			case "loan_spend_housing":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getFieldBounds("spendHousing");
			case "loan_scroll":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getScrollColumnBounds();
			case "loan_calc_payment":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getCalcPaymentBounds();
			case "loan_submit_button":
				if (!isOnLoanNewForm())
					null;
				else
					loanApp.getSubmitButtonBounds();
			default:
				null;
		}
	}

	function getTutorialClientRowBounds():Null<TutorialGuideRect>
	{
		if (view != ClientDatabase || CitizenRegistry.all.length <= ChefTutorial.CITIZEN_INDEX)
			return null;
		var citizen = CitizenRegistry.all[ChefTutorial.CITIZEN_INDEX];
		var dataIndex = clientList.findDataIndexForCitizen(citizen);
		if (dataIndex < 0)
			return null;
		return clientList.getRowBoundsForDataIndex(dataIndex);
	}

	function spriteRect(sprite:FlxSprite):TutorialGuideRect
	{
		return {x: sprite.x, y: sprite.y, w: sprite.width, h: sprite.height};
	}
}
