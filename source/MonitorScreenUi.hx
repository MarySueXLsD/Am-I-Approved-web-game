package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;

enum MonitorView
{
	MainMenu;
	ClientDatabase;
	ClientDetail;
}

class MonitorScreenUi extends FlxGroup
{
	public static inline var GREEN = 0xFF33FF66;
	public static inline var GREEN_DIM = 0xFF1A9940;
	public static inline var GREEN_BRIGHT = 0xFF66FF99;
	public static inline var BG = 0xFF050A08;

	static var MENU_ITEMS:Array<String> = [
		"Client Database",
		"Pending Approvals",
		"Flagged Accounts",
		"Wire Transfer Queue",
		"System Status"
	];

	var screenX:Float = 0;
	var screenY:Float = 0;
	var screenW:Float = 0;
	var screenH:Float = 0;

	var view:MonitorView = MainMenu;
	var bg:FlxSprite;
	var menuRows:Array<MonitorMenuRow> = [];
	var searchLabel:FlxText;
	var searchInputBox:FlxSprite;
	var searchField:FlxText;
	var searchHit:FlxSprite;
	var clientList:MonitorClientList;
	var clientDetail:MonitorClientDetail;
	var backButton:MonitorBackButton;
	var printButton:MonitorBackButton;
	var titleText:FlxText;
	var selectedCitizen:Citizen = null;
	public var onPrintRequest:Void->Bool;

	var searchQuery = "";
	var searchFocused = false;
	var filtered:Array<Citizen> = [];
	var rowHeight = 14;
	var fontSize = 12;
	var menuFontSize = 14;
	var keyHandler:KeyboardEvent->Void;
	var lastLayoutW = -1.0;
	var lastLayoutH = -1.0;
	var listAreaY = 0.0;
	var searchRowY = 0.0;

	public function new()
	{
		super();
		filtered = [];

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, BG, true);
		bg.visible = false;
		add(bg);

		titleText = makeText("", menuFontSize + 2, GREEN_BRIGHT, "center");
		titleText.visible = false;
		add(titleText);

		for (i in 0...MENU_ITEMS.length)
		{
			var row = new MonitorMenuRow(MENU_ITEMS[i], i == 0);
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

		backButton = new MonitorBackButton();
		printButton = new MonitorBackButton("PRINT >");
		add(backButton.hit);
		add(backButton.label);
		add(printButton.hit);
		add(printButton.label);

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
		switch (view)
		{
			case MainMenu:
				syncMainMenuPositions();
			case ClientDatabase:
				syncDatabasePositions();
			case ClientDetail:
				syncDetailPositions();
		}
	}

	function syncMainMenuPositions():Void
	{
		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;
		applyText(titleText, titleText.text, menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, screenY + pad);
		var rowH = menuFontSize + 14;
		var startY = titleText.y + titleText.height + pad;
		var rowGap = Std.int(Math.max(6, screenH * 0.025));
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
		titleText.setPosition(screenX + pad, screenY + pad);
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
	}

	public function containsPoint(px:Float, py:Float):Bool
	{
		return px >= screenX && px < screenX + screenW && py >= screenY && py < screenY + screenH;
	}

	public function updateInput(px:Float, py:Float):Void
	{
		switch (view)
		{
			case ClientDatabase:
				clientList.updateDrag(px, py);
			case ClientDetail:
				clientDetail.updateDrag(px, py);
			default:
		}
	}

	public function handleRelease():Void
	{
		clientList.endDrag();
		clientDetail.endDrag();
	}

	public function handleClick(px:Float, py:Float):Bool
	{
		if (!containsPoint(px, py))
			return false;

		switch (view)
		{
			case MainMenu:
				for (row in menuRows)
				{
					if (row.enabled && row.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
					{
						setView(ClientDatabase);
						return true;
					}
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
				if (printButton.visible && printButton.hit.overlapsPoint(new flixel.math.FlxPoint(px, py)))
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
			default:
		}
	}

	public function updateHoverState():Void
	{
		if (!visible || screenW <= 0)
			return;

		var mouse = FlxG.mouse.getViewPosition();
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
		}
	}

	function layout():Void
	{
		if (screenW <= 1 || screenH <= 1)
			return;

		var pad = Std.int(Math.max(8, screenW * 0.04));
		var innerW = screenW - pad * 2;

		switch (view)
		{
			case MainMenu:
				layoutMainMenu(pad, innerW);
			case ClientDatabase:
				layoutClientDatabase(pad, innerW);
			case ClientDetail:
				layoutClientDetail(pad, innerW);
		}
	}

	function layoutMainMenu(pad:Int, innerW:Float):Void
	{
		applyText(titleText, "BANK TERMINAL v2.1", menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, screenY + pad);
		titleText.visible = true;

		var rowH = menuFontSize + 14;
		var startY = titleText.y + titleText.height + pad;
		var rowGap = Std.int(Math.max(6, screenH * 0.025));

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

		clientDetail.hide();

		applyText(titleText, "CLIENT DATABASE", menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, screenY + pad);
		titleText.visible = true;

		listAreaY = layoutSearchRow(pad, innerW, titleText.y + titleText.height + pad);

		var backH = fontSize + 10;
		var backW = innerW * 0.35;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, backW, backH, fontSize);
		printButton.layout(screenX + pad + innerW - backW, screenY + screenH - pad - backH, backW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = true;

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

		hideDatabaseListWidgets();

		var name = selectedCitizen != null ? CitizenRegistry.displayName(selectedCitizen) : "CLIENT RECORD";
		applyText(titleText, name.toUpperCase(), menuFontSize + 2, GREEN_BRIGHT, "center", Std.int(innerW));
		titleText.setPosition(screenX + pad, screenY + pad);
		titleText.visible = true;

		var backH = fontSize + 10;
		var backW = innerW * 0.35;
		backButton.layout(screenX + pad, screenY + screenH - pad - backH, backW, backH, fontSize);
		printButton.layout(screenX + pad + innerW - backW, screenY + screenH - pad - backH, backW, backH, fontSize);
		backButton.visible = true;
		printButton.visible = true;

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
		titleText.setPosition(screenX + pad, screenY + pad);

		var backH = fontSize + 10;
		var backX = screenX + pad;
		var backY = screenY + screenH - pad - backH;
		backButton.reposition(backX, backY);
		printButton.reposition(screenX + pad + innerW - backButton.hit.width, backY);
		backButton.visible = true;
		printButton.visible = true;

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

	function hideDatabaseWidgets():Void
	{
		hideDatabaseListWidgets();
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
		view = next;

		if (view == ClientDatabase || view == ClientDetail)
			DebugOverlay.hide();

		if (view == MainMenu)
		{
			setSearchFocused(false);
			searchQuery = "";
			clientList.scrollIndex = 0;
			filtered = CitizenRegistry.all;
			selectedCitizen = null;
		}
		else if (view == ClientDatabase && prev == MainMenu)
			refreshListData();

		layout();
	}

	function setSearchFocused(focused:Bool):Void
	{
		if (searchFocused == focused)
			return;

		searchFocused = focused;
		var stage = Lib.current.stage;
		if (stage == null)
			return;

		if (searchFocused)
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false, 0, true);
		else
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);

		if (view == ClientDatabase)
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
		else if (e.charCode > 32)
			searchQuery += Std.string(String.fromCharCode(e.charCode));
		else
			return;

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
		DebugOverlay.hide();
		super.destroy();
	}
}
