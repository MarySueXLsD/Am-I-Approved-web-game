package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import StringTools;
import openfl.Lib;
import openfl.events.KeyboardEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class PlayState extends FlxState
{
	var zones:LayoutZones;
	var documentsAbove:FlxGroup;
	var documentsBelow:FlxGroup;
	var passport:Passport;
	var idDocument:IdDocument;
	var magnifyingGlass:MagnifyingGlass;
	var monitor:MonitorOverlay;
	var printerStation:PrinterStation;
	var shredderStation:ShredderStation;
	var stampPanel:FlxSprite;
	var calculatorObj:FlxSprite;
	var calculatorExpandedY = 0.0;
	var calculatorCollapsedY = 0.0;
	var calculatorCollapsed = false;
	var calculatorMoveTween:FlxTween;
	var calculatorToggleOverlay:FlxSprite;
	var calculatorToggleLabel:FlxText;
	var calculatorDisplayScan:FlxSprite;
	var calculatorDisplayText:FlxText;
	var calculatorDisplayTimer = 0.0;
	var calculatorDisplayLastW = -1;
	var calculatorDisplayLastH = -1;
	var calculatorDisplayValue = "0";
	var calculatorAccumulator:Null<Float> = null;
	var calculatorPendingOp:String = "";
	var calculatorLastEqualsOp:String = "";
	var calculatorLastEqualsOperand:Null<Float> = null;
	var calculatorAwaitingNewInput = false;
	var calculatorBtnOverlays:Array<FlxSprite>;
	var calculatorBtnClickTweens:Array<FlxTween>;
	var calculatorFocused = false;
	var printerPausedByMonitor = false;
	var printedPapers:Array<PrinterPaperDocument> = [];

	var clientImg:FlxSprite;
	var clientFinalX:Float;
	var clientFinalY:Float;
	var clientAnimPhase:Int = 0;
	var clientAnimTimer:Float = 0;
	var clientBobOffset:Float = 0;
	var clientDialog:ClientDialog;

	static inline var LEFT_COL_RATIO:Float = 0.3;
	static inline var CLIENT_H_RATIO:Float = 0.4;
	static inline var CLIENT_TABLE_H_RATIO:Float = 0.25;
	static inline var WINDOW_H_RATIO:Float = 0.20;
	static inline var CALC_DISPLAY_LEFT = 71.0;
	static inline var CALC_DISPLAY_TOP = 96.0;
	static inline var CALC_DISPLAY_RIGHT = 801.0;
	static inline var CALC_DISPLAY_BOTTOM = 247.0;
	static inline var CALC_TOGGLE_LEFT = 62.0;
	static inline var CALC_TOGGLE_RIGHT = 815.0;
	static inline var CALC_TOGGLE_TOP = 0.0;
	static inline var CALC_TOGGLE_BOTTOM = 72.0;
	static inline var CALC_VISIBLE_TOP_RATIO = 0.11;
	static inline var CALC_BTN_HEIGHT = 111.0;
	static inline var CALC_MAX_DISPLAY_CHARS = 10;
	static var CALC_BTN_COL_LEFTS:Array<Float> = [62.0, 251.0, 442.0, 635.0];
	static var CALC_BTN_COL_RIGHTS:Array<Float> = [211.0, 404.0, 598.0, 815.0];
	static var CALC_BTN_ROW_TOPS:Array<Float> = [318.0, 456.0, 600.0, 744.0];
	static inline var CALC_BTN_ROW5_TOP = 891.0;
	static var CALC_BTN_LABELS:Array<String> = [
		"C", "CE", "%", "÷",
		"7", "8", "9", "*",
		"4", "5", "6", "-",
		"1", "2", "3", "+",
		"0", ".", "="
	];

	override function create():Void
	{
		super.create();
		DebugOverlay.init();
		#if FLX_DEBUG
		if (Lib.current.stage != null)
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onDebugKeyUp);
		#end
		buildLayout();
	}

	#if FLX_DEBUG
	function onDebugKeyUp(e:KeyboardEvent):Void
	{
		DebugOverlay.handleKeyUp(e);
	}
	#end

	function buildLayout():Void
	{
		var screenW = FlxG.width;
		var screenH = FlxG.height;
		var sep = Std.int(Math.max(2, screenH / 300));

		var leftW = Std.int(screenW * LEFT_COL_RATIO);
		var clientH = Std.int(screenH * CLIENT_H_RATIO);
		var clientTableY = clientH;
		var clientTableH = Std.int(screenH * CLIENT_TABLE_H_RATIO);
		var computerY = clientTableY + clientTableH;
		var computerH = screenH - computerY;

		var employerX = leftW;
		var employerW = screenW - leftW;
		var windowH = 0;
		var employerTableY = 0;
		var employerTableH = screenH;

		var client = new LayoutPanel(0, 0, leftW, clientH, "Client", FlxColor.fromRGB(42, 58, 74));
		add(client);

		var clientWall = new FlxSprite(0, 0);
		clientWall.loadGraphic("static/wall.png");
		clientWall.setGraphicSize(leftW, clientH);
		clientWall.updateHitbox();
		add(clientWall);

		clientImg = new FlxSprite(0, 0);
		clientImg.loadGraphic("static/client.png");
		var clientScale = (leftW * 0.75) / clientImg.frameWidth;
		clientImg.scale.set(clientScale, clientScale);
		clientImg.updateHitbox();
		clientFinalX = (leftW - clientImg.width) / 2;
		clientFinalY = clientH - clientImg.height + CLIENT_BOB_AMPLITUDE;
		clientImg.x = -clientImg.width;
		clientImg.y = clientFinalY;
		clientImg.color = FlxColor.BLACK;
		clientAnimPhase = 1;
		clientAnimTimer = 0;
		add(clientImg);

		var dialogMaxW = Std.int(leftW * 0.75);
		clientDialog = new ClientDialog(leftW, 0.0, clientH, dialogMaxW, clientImg, clientFinalY);
		add(clientDialog);

		var clientTable = new LayoutPanel(0, clientTableY, leftW, clientTableH, "Client's table", FlxColor.fromRGB(52, 68, 84));
		add(clientTable);

		var clientTableImg = new FlxSprite(0, clientTableY);
		clientTableImg.loadGraphic("static/table.png");
		clientTableImg.setGraphicSize(leftW, clientTableH);
		clientTableImg.updateHitbox();
		add(clientTableImg);

		var computer = new LayoutPanel(0, computerY, leftW, computerH, "Computer", FlxColor.fromRGB(44, 54, 68));
		add(computer);

		var hudFont = Std.int(Math.max(7, FlxG.height / 72));
		var hudBottomPad = Std.int(Math.max(6, FlxG.height / 80));
		var computerHudH = hudFont + 4 + hudBottomPad + 2;
		if (computerHudH >= computerH)
			computerHudH = computerH - 1;
		var computerImgH = computerH - computerHudH;
		if (computerImgH < 1)
			computerImgH = 1;

		var computerTable = new FlxSprite(0, computerY);
		computerTable.loadGraphic("static/computer_table.png");
		computerTable.setGraphicSize(leftW, computerImgH);
		computerTable.updateHitbox();
		add(computerTable);

		var computerImgScale = 0.85;
		var computerImgW = Std.int(leftW * computerImgScale);
		var computerImgDrawH = Std.int(computerImgH * computerImgScale);
		var computerImgX = Std.int((leftW - computerImgW) * 0.5);
		var computerImgY = computerY + Std.int((computerImgH - computerImgDrawH) * 0.5);
		var computerImg = new FlxSprite(computerImgX, computerImgY);
		computerImg.loadGraphic("static/computer.png");
		computerImg.setGraphicSize(computerImgW, computerImgDrawH);
		computerImg.updateHitbox();
		add(computerImg);

		var computerHud = new ComputerHud(0, computerY + computerImgH, leftW, computerHudH);
		add(computerHud);

		var employerTable = new LayoutPanel(employerX, employerTableY, employerW, employerTableH, "Employer's table", FlxColor.fromRGB(32, 48, 62));
		add(employerTable);

		var employerTableTiles = createTiledSprite("static/employers_table.png", employerX, employerTableY, employerW, employerTableH);
		add(employerTableTiles);

		var dotGrid = createDotGrid(employerX, employerTableY, employerW, employerTableH);
		add(dotGrid);

		stampPanel = new FlxSprite();
		stampPanel.loadGraphic("static/stamp_panel.png");
		var stampTargetH = employerTableH * 0.15;
		var stampScale = stampTargetH / stampPanel.frameHeight;
		stampPanel.scale.set(stampScale, stampScale);
		stampPanel.updateHitbox();
		stampPanel.x = employerX + employerW - stampPanel.width;
		stampPanel.y = employerTableY + employerTableH * 0.32 - stampPanel.height * 0.5;

		var printerMargin = Std.int(Math.max(4, employerTableH * 0.01));
		var printerTargetH = employerTableH * 0.2;
		printerStation = new PrinterStation(employerX + printerMargin, employerTableY, employerTableH, printerTargetH, employerX, employerTableY, employerW, employerTableH, 0,
			clientTableY, leftW, clientTableH);

		calculatorObj = new FlxSprite();
		calculatorObj.loadGraphic("static/calculator.png");
		var calculatorTargetH = employerTableH * 0.42;
		var calculatorScale = calculatorTargetH / calculatorObj.frameHeight;
		calculatorObj.scale.set(calculatorScale, calculatorScale);
		calculatorObj.updateHitbox();
		calculatorObj.x = employerX + employerW - calculatorObj.width - printerMargin;
		calculatorObj.y = employerTableY + employerTableH - calculatorObj.height;
		calculatorExpandedY = calculatorObj.y;
		calculatorCollapsedY = employerTableY + employerTableH - calculatorObj.height * CALC_VISIBLE_TOP_RATIO;

		var shredderBody = new FlxSprite();
		shredderBody.loadGraphic("static/shredder.png");
		var shredderScale = (printerTargetH / shredderBody.frameHeight) * 0.75;
		shredderBody.scale.set(shredderScale, shredderScale);
		shredderBody.updateHitbox();
		var printerRight = printerStation.getBodyX() + printerStation.getBodyW();
		var calcLeft = calculatorObj.x;
		shredderBody.x = printerRight + (calcLeft - printerRight - shredderBody.width) * 0.5;
		shredderBody.y = employerTableY + employerTableH - shredderBody.height;
		shredderStation = new ShredderStation(shredderBody);
		printerStation.setExclusionZones(calculatorObj.x, calculatorObj.y, calculatorObj.width, calculatorObj.height, shredderStation.getBodyX(),
			shredderStation.getBodyY(), shredderStation.getBodyW(), shredderStation.getBodyH());

		calculatorToggleOverlay = new FlxSprite();
		calculatorToggleOverlay.makeGraphic(1, 1, 0xFFFFFFFF, true);
		calculatorToggleOverlay.color = 0x000000;
		calculatorToggleOverlay.alpha = 0.0;

		calculatorToggleLabel = new FlxText();
		calculatorToggleLabel.text = "v";
		calculatorToggleLabel.alignment = "center";
		calculatorToggleLabel.visible = true;
		updateCalculatorToggleUi();

		calculatorDisplayScan = new FlxSprite();
		calculatorDisplayScan.visible = true;

		calculatorDisplayText = new FlxText();
		calculatorDisplayText.text = "1234567890";
		calculatorDisplayText.alignment = "right";
		calculatorDisplayText.wordWrap = false;
		calculatorDisplayText.color = FlxColor.fromRGB(72, 110, 78);
		calculatorDisplayText.visible = true;
		updateCalculatorDisplayVisuals(0.0);

		calculatorBtnOverlays = [];
		calculatorBtnClickTweens = [];
		var totalBtnCount = CALC_BTN_COL_LEFTS.length * CALC_BTN_ROW_TOPS.length + 3;
		for (i in 0...totalBtnCount)
		{
			var overlay = new FlxSprite();
			overlay.makeGraphic(1, 1, 0xFFFFFFFF, true);
			overlay.color = 0x000000;
			overlay.alpha = 0.0;
			overlay.visible = true;
			calculatorBtnOverlays.push(overlay);
			calculatorBtnClickTweens.push(null);
		}
		updateCalculatorButtonOverlay();

		zones = {
			leftW: leftW,
			clientH: clientH,
			clientTableY: clientTableY,
			clientTableH: clientTableH,
			computerY: computerY,
			computerH: computerH,
			employerX: employerX,
			employerW: employerW,
			windowH: windowH,
			employerTableY: employerTableY,
			employerTableH: employerTableH,
			printerX: Std.int(printerStation.getBodyX()),
			printerY: Std.int(printerStation.getBodyY()),
			printerW: Std.int(printerStation.getBodyW()),
			printerH: Std.int(printerStation.getBodyH()),
			calculatorX: Std.int(calculatorObj.x),
			calculatorY: Std.int(calculatorObj.y),
			calculatorW: Std.int(calculatorObj.width),
			calculatorH: Std.int(calculatorObj.height),
			shredderX: Std.int(shredderStation.getBodyX()),
			shredderY: Std.int(shredderStation.getBodyY()),
			shredderW: Std.int(shredderStation.getBodyW()),
			shredderH: Std.int(shredderStation.getBodyH())
		};
		documentsAbove = new FlxGroup();
		documentsBelow = new FlxGroup();
		passport = new Passport(zones, documentsAbove);
		passport.visible = false;
		passport.onDroppedOnPrinter = handleDocumentDroppedOnPrinter;
		idDocument = new IdDocument(zones, documentsAbove);
		idDocument.onDroppedOnPrinter = handleDocumentDroppedOnPrinter;
		var idPosX = leftW * 0.5 - idDocument.width * 0.5;
		var idPosY = clientTableY + clientTableH * 0.5 - idDocument.height * 0.5;
		idDocument.setPosition(idPosX, idPosY);

		magnifyingGlass = new MagnifyingGlass(zones, documentsAbove);
		magnifyingGlass.placeBeside(idDocument);

		documentsAbove.add(idDocument);
		documentsAbove.add(magnifyingGlass);
		DeskDocument.onDrawLayerChanged = moveDocumentToLayer;
		DeskDocument.onCanStartDrag = isTopmostDocumentAtPoint;
		addDeskPropsAndDocuments();

		var lc = magnifyingGlass.lensCam;
		var cc = magnifyingGlass.coverCam;
		if (lc != null)
		{
			employerTable.cameras = [FlxG.camera, lc];
			employerTableTiles.cameras = [FlxG.camera, lc];
			dotGrid.cameras = [FlxG.camera, lc];
			stampPanel.cameras = [FlxG.camera];
			printerStation.setStationCameras([FlxG.camera]);
			shredderStation.setStationCameras([FlxG.camera]);
			calculatorObj.cameras = [FlxG.camera];
			calculatorToggleOverlay.cameras = [FlxG.camera];
			calculatorToggleLabel.cameras = [FlxG.camera];
			calculatorDisplayScan.cameras = [FlxG.camera];
			calculatorDisplayText.cameras = [FlxG.camera];
			for (overlay in calculatorBtnOverlays)
				overlay.cameras = [FlxG.camera];
			passport.cameras = [FlxG.camera, lc];
			idDocument.cameras = [FlxG.camera, lc];
		}
		if (cc != null)
		{
			client.cameras = [FlxG.camera, cc];
			clientWall.cameras = [FlxG.camera, cc];
			clientImg.cameras = [FlxG.camera, cc];
			clientDialog.setCameras([FlxG.camera, cc]);
			clientTable.cameras = [FlxG.camera, cc];
			clientTableImg.cameras = [FlxG.camera, cc];
			computer.cameras = [FlxG.camera, cc];
			computerTable.cameras = [FlxG.camera, cc];
			computerImg.cameras = [FlxG.camera, cc];
			computerHud.cameras = [FlxG.camera, cc];
			stampPanel.cameras = [FlxG.camera, cc];
			printerStation.setStationCameras([FlxG.camera, cc]);
			shredderStation.setStationCameras([FlxG.camera, cc]);
			calculatorObj.cameras = [FlxG.camera, cc];
			calculatorToggleOverlay.cameras = [FlxG.camera, cc];
			calculatorToggleLabel.cameras = [FlxG.camera, cc];
			calculatorDisplayScan.cameras = [FlxG.camera, cc];
			calculatorDisplayText.cameras = [FlxG.camera, cc];
			for (overlay in calculatorBtnOverlays)
				overlay.cameras = [FlxG.camera, cc];
		}

		CitizenRegistry.load();
		if (CitizenRegistry.all.length > 0)
		{
			var citizen = CitizenRegistry.all[0];
			passport.setCitizen(citizen);
			idDocument.setCitizen(citizen);
			clientDialog.setCitizenName(citizen.firstName + " " + citizen.lastName);
		}

		clientDialog.onPassportRequest = function()
		{
			spawnPassport();
		};

		monitor = new MonitorOverlay();
		monitor.setOnPrintRequest(handleMonitorPrintRequest);
		add(monitor);
	}

	override function update(elapsed:Float):Void
	{
		updateClientEntrance(elapsed);
		syncCalculatorZone();
		syncPrinterPauseForMonitor();
		magnifyingGlass.setHidden(monitor.isActive());
		updateCalculatorToggleUi();
		updateCalculatorDisplayVisuals(elapsed);
		updateCalculatorButtonOverlay();

		var p = FlxG.mouse.getViewPosition();

		if (!monitor.isActive() && FlxG.mouse.justPressed && !MonitorOverlay.blocksWorldInput())
			tryPickupPrintedPaper(p);

		if (monitor.isActive())
		{
			if (!monitor.isBusy)
				monitor.updateScreenInput(p);

			if (FlxG.mouse.justReleased)
				monitor.handleScreenRelease();

			super.update(elapsed);
			syncDocumentLayers();

			if (FlxG.mouse.justPressed)
			{
				if (monitor.isShowing && monitor.containsInteractivePoint(p))
					monitor.handleScreenClick(p);
				else
					monitor.hide();
			}
			return;
		}

		super.update(elapsed);
		syncDocumentLayers();
		updateCalculatorToggleInput(p);
		updateCalculatorButtonInput(p);
		updateCalculatorFocus(p);
		updateCalculatorKeyboardInput();

		if (!FlxG.mouse.justPressed)
			return;
		if (clientDialog.consumedClick)
			return;

		if (!isComputerZoneClick() || isDocumentAtMouse())
			return;

		monitor.show();
	}

	function addDeskPropsAndDocuments():Void
	{
		// Large/open employer-table docs draw under desk props; closed docs draw on top.
		add(documentsBelow);
		add(stampPanel);
		add(printerStation);
		add(shredderStation);
		add(calculatorObj);
		add(calculatorToggleOverlay);
		add(calculatorToggleLabel);
		add(calculatorDisplayScan);
		add(calculatorDisplayText);
		for (overlay in calculatorBtnOverlays)
			add(overlay);
		add(documentsAbove);
	}

	function syncDocumentLayers():Void
	{
		moveDocumentToLayer(passport);
		moveDocumentToLayer(idDocument);
		moveDocumentToLayer(magnifyingGlass);
		for (paper in printedPapers)
			movePrintedPaperToLayer(paper);
		syncOpenDocumentCameras();
	}

	function movePrintedPaperToLayer(paper:PrinterPaperDocument):Void
	{
		var target = paper.isOpenOnEmployerTable() ? documentsBelow : documentsAbove;
		paper.moveToDocumentLayer(target);
	}

	function moveDocumentToLayer(doc:DeskDocument):Void
	{
		var target = doc.visible && doc.isOpenOnEmployerTable() ? documentsBelow : documentsAbove;
		var printedPaper = Std.downcast(doc, PrinterPaperDocument);
		if (printedPaper != null)
		{
			printedPaper.moveToDocumentLayer(target);
			return;
		}

		var passportDoc = Std.downcast(doc, Passport);
		if (passportDoc != null)
		{
			passportDoc.moveToDocumentLayer(target);
			return;
		}

		var idDoc = Std.downcast(doc, IdDocument);
		if (idDoc != null)
		{
			idDoc.moveToDocumentLayer(target);
			return;
		}

		doc.moveToLayer(target);
	}

	function syncOpenDocumentCameras():Void
	{
		if (magnifyingGlass == null)
			return;

		syncDocumentLensCameras(passport);
		syncDocumentLensCameras(idDocument);
	}

	function syncDocumentLensCameras(doc:DeskDocument):Void
	{
		if (doc == null || magnifyingGlass == null)
			return;

		var updated = [FlxG.camera];
		var lensCam = magnifyingGlass.lensCam;
		var coverCam = magnifyingGlass.coverCam;
		var lensActive = lensCam != null && magnifyingGlass.visible && magnifyingGlass.isCurrentlyOpen();

		if (!lensActive)
		{
			doc.cameras = updated;
			return;
		}

		var docGroup = documentsAbove.members.indexOf(doc) >= 0 ? documentsAbove : (documentsBelow.members.indexOf(doc) >= 0 ? documentsBelow : null);
		var magnifierGroup = documentsAbove.members.indexOf(magnifyingGlass) >= 0 ? documentsAbove : (documentsBelow.members.indexOf(magnifyingGlass) >= 0 ? documentsBelow : null);

		var shouldZoom = false;
		if (docGroup != null && magnifierGroup != null && docGroup == magnifierGroup && doc.isCurrentlyOpen())
		{
			var docIndex = docGroup.members.indexOf(doc);
			var magnifierIndex = magnifierGroup.members.indexOf(magnifyingGlass);
			shouldZoom = docIndex >= 0 && magnifierIndex >= 0 && docIndex < magnifierIndex;
		}

		if (shouldZoom && lensCam != null)
			updated.push(lensCam);
		if (!shouldZoom && coverCam != null)
			updated.push(coverCam);

		doc.cameras = updated;
	}

	function updateCalculatorDisplayVisuals(elapsed:Float):Void
	{
		calculatorDisplayTimer += elapsed;
		var s = calculatorObj.scale.x;
		var x = calculatorObj.x + CALC_DISPLAY_LEFT * s;
		var y = calculatorObj.y + CALC_DISPLAY_TOP * s;
		var w = (CALC_DISPLAY_RIGHT - CALC_DISPLAY_LEFT) * s;
		var h = (CALC_DISPLAY_BOTTOM - CALC_DISPLAY_TOP) * s;
		var wi = Std.int(Math.max(1, w));
		var hi = Std.int(Math.max(1, h));

		if (wi != calculatorDisplayLastW || hi != calculatorDisplayLastH)
		{
			calculatorDisplayLastW = wi;
			calculatorDisplayLastH = hi;
			rebuildCalculatorDisplayScan(wi, hi);
		}

		calculatorDisplayScan.setPosition(x, y);
		var textPad = Math.max(2.0, w * 0.015);
		calculatorDisplayText.setPosition(x + textPad, y + h * 0.12);
		calculatorDisplayText.fieldWidth = Math.max(1, w - textPad);
		var fontSize = Std.int(Math.max(12, h * 0.62));
		calculatorDisplayText.setFormat(null, fontSize, FlxColor.fromRGB(76, 118, 84), "right");
		calculatorDisplayText.setBorderStyle(OUTLINE, FlxColor.fromRGB(12, 28, 14), 1);
		calculatorDisplayText.text = formatCalculatorForUi(calculatorDisplayValue);
		calculatorDisplayText.alpha = 0.82;
	}

	function updateCalculatorToggleUi():Void
	{
		var s = calculatorObj.scale.x;
		var w = (CALC_TOGGLE_RIGHT - CALC_TOGGLE_LEFT) * s;
		var h = (CALC_TOGGLE_BOTTOM - CALC_TOGGLE_TOP) * s;
		calculatorToggleOverlay.setGraphicSize(Std.int(Math.max(1, w)), Std.int(Math.max(1, h)));
		calculatorToggleOverlay.updateHitbox();
		calculatorToggleOverlay.x = calculatorObj.x + CALC_TOGGLE_LEFT * s;
		calculatorToggleOverlay.y = calculatorObj.y + CALC_TOGGLE_TOP * s;

		calculatorToggleLabel.text = calculatorCollapsed ? "/\\" : "\\/";
		calculatorToggleLabel.setPosition(calculatorToggleOverlay.x, calculatorToggleOverlay.y + h * 0.05);
		calculatorToggleLabel.fieldWidth = w;
		var size = Std.int(Math.max(10, h * 0.72));
		calculatorToggleLabel.setFormat(null, size, FlxColor.BLACK, "center");
		calculatorToggleLabel.setBorderStyle(OUTLINE, FlxColor.fromRGB(16, 16, 16), 1);
	}

	function syncCalculatorZone():Void
	{
		var visibleRatio = calculatorCollapsed ? CALC_VISIBLE_TOP_RATIO : 1.0;
		zones.calculatorX = Std.int(calculatorObj.x);
		zones.calculatorY = Std.int(calculatorObj.y);
		zones.calculatorW = Std.int(calculatorObj.width);
		zones.calculatorH = Std.int(calculatorObj.height * visibleRatio);
		if (printerStation != null)
		{
			printerStation.setExclusionZones(zones.calculatorX, zones.calculatorY, zones.calculatorW, zones.calculatorH, zones.shredderX, zones.shredderY, zones.shredderW,
				zones.shredderH);
		}
	}

	function isDeskItemBeingDragged():Bool
	{
		if (isDraggingInGroup(documentsAbove))
			return true;
		return isDraggingInGroup(documentsBelow);
	}

	function isDraggingInGroup(group:FlxGroup):Bool
	{
		for (member in group.members)
		{
			if (member == null)
				continue;
			var doc = Std.downcast(member, DeskDocument);
			if (doc != null && doc.isDragging())
				return true;
		}
		return false;
	}

	function updateCalculatorToggleInput(mousePos:flixel.math.FlxPoint):Void
	{
		if (isDeskItemBeingDragged())
		{
			calculatorToggleOverlay.alpha += (0 - calculatorToggleOverlay.alpha) * 0.35;
			return;
		}

		var hovered = calculatorToggleOverlay.overlapsPoint(mousePos);
		var targetAlpha = hovered ? 0.22 : 0.0;
		calculatorToggleOverlay.alpha += (targetAlpha - calculatorToggleOverlay.alpha) * 0.35;
		if (hovered && FlxG.mouse.justPressed)
			toggleCalculatorCollapsed();
	}

	function toggleCalculatorCollapsed():Void
	{
		if (calculatorMoveTween != null)
		{
			calculatorMoveTween.cancel();
			calculatorMoveTween = null;
		}

		calculatorCollapsed = !calculatorCollapsed;
		var targetY = calculatorCollapsed ? calculatorCollapsedY : calculatorExpandedY;
		calculatorMoveTween = FlxTween.tween(calculatorObj, {y: targetY}, 0.28, {
			ease: FlxEase.quadInOut,
			onComplete: function(_)
			{
				calculatorMoveTween = null;
			}
		});
	}

	function rebuildCalculatorDisplayScan(w:Int, h:Int):Void
	{
		calculatorDisplayScan.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		var px = calculatorDisplayScan.pixels;
		for (yy in 0...h)
		{
			var a = (yy % 2 == 0) ? 26 : 10;
			var c = (a << 24) | 0x00101010;
			for (xx in 0...w)
				px.setPixel32(xx, yy, c);
		}
		calculatorDisplayScan.dirty = true;
	}

	function updateCalculatorButtonOverlay():Void
	{
		var s = calculatorObj.scale.x;
		var idx = 0;
		for (rowTop in CALC_BTN_ROW_TOPS)
		{
			for (col in 0...CALC_BTN_COL_LEFTS.length)
			{
				var overlay = calculatorBtnOverlays[idx++];
				setCalculatorButtonOverlayRect(overlay, CALC_BTN_COL_LEFTS[col], CALC_BTN_COL_RIGHTS[col], rowTop, s);
			}
		}

		// 5th row: one double-width left button + two normal right buttons.
		if (idx < calculatorBtnOverlays.length)
		{
			setCalculatorButtonOverlayRect(calculatorBtnOverlays[idx++], 62.0, 404.0, CALC_BTN_ROW5_TOP, s);
			setCalculatorButtonOverlayRect(calculatorBtnOverlays[idx++], 442.0, 598.0, CALC_BTN_ROW5_TOP, s);
			setCalculatorButtonOverlayRect(calculatorBtnOverlays[idx++], 635.0, 815.0, CALC_BTN_ROW5_TOP, s);
		}
	}

	function setCalculatorButtonOverlayRect(overlay:FlxSprite, left:Float, right:Float, top:Float, scale:Float):Void
	{
		var btnW = (right - left) * scale;
		var btnH = CALC_BTN_HEIGHT * scale;
		overlay.setGraphicSize(Std.int(Math.max(1, btnW)), Std.int(Math.max(1, btnH)));
		overlay.updateHitbox();
		overlay.x = calculatorObj.x + left * scale;
		overlay.y = calculatorObj.y + top * scale;
	}

	function updateCalculatorButtonInput(mousePos:flixel.math.FlxPoint):Void
	{
		if (isDeskItemBeingDragged())
		{
			for (overlay in calculatorBtnOverlays)
				overlay.alpha += (0 - overlay.alpha) * 0.35;
			return;
		}

		for (i in 0...calculatorBtnOverlays.length)
		{
			var overlay = calculatorBtnOverlays[i];
			var hovered = overlay.overlapsPoint(mousePos);
			var targetAlpha = hovered ? 0.26 : 0.0;
			overlay.alpha += (targetAlpha - overlay.alpha) * 0.35;

			if (hovered && FlxG.mouse.justPressed)
			{
				handleCalculatorButtonPress(i);
				playCalculatorButtonClickAnim(i);
			}
		}
	}

	function updateCalculatorFocus(mousePos:flixel.math.FlxPoint):Void
	{
		if (!FlxG.mouse.justPressed)
			return;
		if (isDeskItemBeingDragged())
		{
			calculatorFocused = false;
			return;
		}

		calculatorFocused = isPointOnCalculator(mousePos);
	}

	function isPointOnCalculator(mousePos:flixel.math.FlxPoint):Bool
	{
		if (calculatorObj.overlapsPoint(mousePos))
			return true;
		if (calculatorToggleOverlay.overlapsPoint(mousePos))
			return true;
		if (calculatorDisplayScan.overlapsPoint(mousePos))
			return true;
		for (overlay in calculatorBtnOverlays)
		{
			if (overlay.overlapsPoint(mousePos))
				return true;
		}
		return false;
	}

	function updateCalculatorKeyboardInput():Void
	{
		if (!calculatorFocused || isDeskItemBeingDragged())
			return;

		if (FlxG.keys.anyJustPressed([FlxKey.BACKSPACE]))
		{
			pressCalculatorLabel("CE");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.ENTER]))
		{
			pressCalculatorLabel("=");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.SLASH, FlxKey.NUMPADSLASH]))
		{
			pressCalculatorLabel("÷");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADMULTIPLY]) || (FlxG.keys.anyJustPressed([FlxKey.EIGHT]) && FlxG.keys.pressed.SHIFT))
		{
			pressCalculatorLabel("*");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.MINUS, FlxKey.NUMPADMINUS]))
		{
			pressCalculatorLabel("-");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADPLUS]) || (FlxG.keys.anyJustPressed([FlxKey.PLUS]) && FlxG.keys.pressed.SHIFT))
		{
			pressCalculatorLabel("+");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.PLUS]) && !FlxG.keys.pressed.SHIFT)
		{
			pressCalculatorLabel("=");
			return;
		}

		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADZERO, FlxKey.ZERO]))
		{
			pressCalculatorLabel("0");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADONE, FlxKey.ONE]))
		{
			pressCalculatorLabel("1");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADTWO, FlxKey.TWO]))
		{
			pressCalculatorLabel("2");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADTHREE, FlxKey.THREE]))
		{
			pressCalculatorLabel("3");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADFOUR, FlxKey.FOUR]))
		{
			pressCalculatorLabel("4");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADFIVE, FlxKey.FIVE]))
		{
			pressCalculatorLabel("5");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADSIX, FlxKey.SIX]))
		{
			pressCalculatorLabel("6");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADSEVEN, FlxKey.SEVEN]))
		{
			pressCalculatorLabel("7");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADEIGHT, FlxKey.EIGHT]))
		{
			pressCalculatorLabel("8");
			return;
		}
		if (FlxG.keys.anyJustPressed([FlxKey.NUMPADNINE, FlxKey.NINE]))
		{
			pressCalculatorLabel("9");
			return;
		}
	}

	function pressCalculatorLabel(label:String):Void
	{
		var idx = CALC_BTN_LABELS.indexOf(label);
		if (idx < 0)
			return;
		handleCalculatorButtonPress(idx);
		playCalculatorButtonClickAnim(idx);
	}

	function handleCalculatorButtonPress(index:Int):Void
	{
		if (index < 0 || index >= CALC_BTN_LABELS.length)
			return;
		var label = CALC_BTN_LABELS[index];

		switch (label)
		{
			case "C":
				resetCalculatorAll();
			case "CE":
				resetCalculatorEntry();
			case "%":
				applyPercentToEntry();
			case "+", "-", "*", "÷":
				applyOperator(label);
			case "=":
				applyEquals();
			case ".":
				appendDecimalPoint();
			default:
				appendDigit(label);
		}
	}

	function resetCalculatorAll():Void
	{
		calculatorDisplayValue = "0";
		calculatorAccumulator = null;
		calculatorPendingOp = "";
		calculatorLastEqualsOp = "";
		calculatorLastEqualsOperand = null;
		calculatorAwaitingNewInput = false;
	}

	function resetCalculatorEntry():Void
	{
		if (isCalculatorError())
		{
			resetCalculatorAll();
			return;
		}
		calculatorDisplayValue = "0";
		calculatorAwaitingNewInput = false;
	}

	function appendDigit(digit:String):Void
	{
		if (isCalculatorError())
			resetCalculatorAll();

		if (calculatorAwaitingNewInput)
		{
			calculatorDisplayValue = digit;
			calculatorLastEqualsOp = "";
			calculatorLastEqualsOperand = null;
			calculatorAwaitingNewInput = false;
			return;
		}

		if (calculatorDisplayValue == "0")
		{
			calculatorDisplayValue = digit;
			return;
		}

		if (calculatorDisplayValue.length >= CALC_MAX_DISPLAY_CHARS)
			return;
		calculatorDisplayValue += digit;
	}

	function appendDecimalPoint():Void
	{
		if (isCalculatorError())
			resetCalculatorAll();

		if (calculatorAwaitingNewInput)
		{
			calculatorDisplayValue = "0.";
			calculatorLastEqualsOp = "";
			calculatorLastEqualsOperand = null;
			calculatorAwaitingNewInput = false;
			return;
		}

		if (calculatorDisplayValue.indexOf(".") >= 0)
			return;
		if (calculatorDisplayValue.length >= CALC_MAX_DISPLAY_CHARS)
			return;
		calculatorDisplayValue += ".";
	}

	function applyOperator(op:String):Void
	{
		if (isCalculatorError())
			resetCalculatorAll();

		var current = parseCalculatorDisplay();
		if (current == null)
			return;

		if (calculatorPendingOp != "" && !calculatorAwaitingNewInput && calculatorAccumulator != null)
		{
			var result = calculateBinary(calculatorAccumulator, current, calculatorPendingOp);
			if (result == null)
			{
				showCalculatorError();
				return;
			}
			calculatorAccumulator = result;
			calculatorDisplayValue = formatCalculatorNumber(result);
		}
		else
		{
			calculatorAccumulator = current;
		}

		calculatorPendingOp = op;
		calculatorLastEqualsOp = "";
		calculatorLastEqualsOperand = null;
		calculatorAwaitingNewInput = true;
	}

	function applyEquals():Void
	{
		if (isCalculatorError())
			return;

		if (calculatorPendingOp != "" && calculatorAccumulator != null)
		{
			var current = parseCalculatorDisplay();
			if (current == null)
				return;
			var result = calculateBinary(calculatorAccumulator, current, calculatorPendingOp);
			if (result == null)
			{
				showCalculatorError();
				return;
			}

			calculatorDisplayValue = formatCalculatorNumber(result);
			calculatorAccumulator = result;
			calculatorLastEqualsOp = calculatorPendingOp;
			calculatorLastEqualsOperand = current;
			calculatorPendingOp = "";
			calculatorAwaitingNewInput = true;
			return;
		}

		if (calculatorLastEqualsOp == "" || calculatorLastEqualsOperand == null)
			return;

		var current = parseCalculatorDisplay();
		if (current == null)
			return;
		var chained = calculateBinary(current, calculatorLastEqualsOperand, calculatorLastEqualsOp);
		if (chained == null)
		{
			showCalculatorError();
			return;
		}

		calculatorDisplayValue = formatCalculatorNumber(chained);
		calculatorAccumulator = chained;
		calculatorAwaitingNewInput = true;
	}

	function applyPercentToEntry():Void
	{
		if (isCalculatorError())
		{
			resetCalculatorAll();
			return;
		}
		var current = parseCalculatorDisplay();
		if (current == null)
			return;
		calculatorDisplayValue = formatCalculatorNumber(current / 100.0);
		calculatorAwaitingNewInput = false;
	}

	function parseCalculatorDisplay():Null<Float>
	{
		if (calculatorDisplayValue == "Error")
			return null;
		var n = Std.parseFloat(calculatorDisplayValue);
		return Math.isNaN(n) ? null : n;
	}

	function calculateBinary(a:Float, b:Float, op:String):Null<Float>
	{
		return switch (op)
		{
			case "+": a + b;
			case "-": a - b;
			case "*": a * b;
			case "÷":
				if (Math.abs(b) <= 0.0000001) null else a / b;
			default: null;
		}
	}

	function showCalculatorError():Void
	{
		calculatorDisplayValue = "Error";
		calculatorAccumulator = null;
		calculatorPendingOp = "";
		calculatorAwaitingNewInput = true;
	}

	function isCalculatorError():Bool
	{
		return calculatorDisplayValue == "Error";
	}

	function formatCalculatorNumber(value:Float):String
	{
		var rounded = Math.round(value * 1000000000.0) / 1000000000.0;
		var s = Std.string(rounded);
		if (s.indexOf(".") >= 0)
		{
			while (StringTools.endsWith(s, "0"))
				s = s.substr(0, s.length - 1);
			if (StringTools.endsWith(s, "."))
				s = s.substr(0, s.length - 1);
		}
		if (s == "-0")
			s = "0";
		return s;
	}

	function formatCalculatorForUi(value:String):String
	{
		if (value == null)
			return "0";
		if (value == "Error")
			return value;
		if (value == "Infinity")
			return "Infinity :)";
		if (value == "-Infinity")
			return "-Infinity :)";
		if (value.length <= CALC_MAX_DISPLAY_CHARS)
			return value;

		var n = Std.parseFloat(value);
		if (Math.isNaN(n))
			return value;
		if (n == 0)
			return "0";

		return formatCompactScientific(n);
	}

	function formatCompactScientific(n:Float):String
	{
		var sign = n < 0 ? "-" : "";
		var absN = Math.abs(n);
		var exp = Std.int(Math.floor(Math.log(absN) / Math.log(10)));

		// Prefer 4-digit mantissa style (e.g. 3232e2), reduce only if needed to fit.
		for (mantissaDigits in [4, 3, 2, 1])
		{
			var power = exp - (mantissaDigits - 1);
			var mantissaInt = Std.int(Math.round(absN / Math.pow(10, power)));
			var out = sign + Std.string(mantissaInt) + "e" + Std.string(power);
			if (out.length <= CALC_MAX_DISPLAY_CHARS)
				return out;
		}

		// Last fallback (still scientific, never clipped).
		return sign + "1e" + Std.string(exp);
	}

	function playCalculatorButtonClickAnim(index:Int):Void
	{
		var overlay = calculatorBtnOverlays[index];
		var tween = calculatorBtnClickTweens[index];
		if (tween != null)
		{
			tween.cancel();
			calculatorBtnClickTweens[index] = null;
		}

		overlay.alpha = 0.44;
		calculatorBtnClickTweens[index] = FlxTween.tween(overlay, {alpha: 0.18}, 0.09, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				calculatorBtnClickTweens[index] = FlxTween.tween(overlay, {alpha: 0.26}, 0.1, {ease: FlxEase.quadInOut});
			}
		});
	}

	static inline var CLIENT_WALK_DURATION:Float = 1.1;
	static inline var CLIENT_REVEAL_DURATION:Float = 0.5;
	static inline var CLIENT_BOB_SPEED:Float = 6.0;
	static inline var CLIENT_BOB_AMPLITUDE:Float = 4.0;

	function updateClientEntrance(elapsed:Float):Void
	{
		if (clientAnimPhase == 0)
			return;

		clientAnimTimer += elapsed;

		if (clientAnimPhase == 1)
		{
			var t = Math.min(clientAnimTimer / CLIENT_WALK_DURATION, 1.0);
			var eased = FlxEase.quadOut(t);
			clientImg.x = -clientImg.width + (clientFinalX + clientImg.width) * eased;

			clientBobOffset += elapsed * CLIENT_BOB_SPEED;
			clientImg.y = clientFinalY + Math.sin(clientBobOffset) * CLIENT_BOB_AMPLITUDE;

			if (t >= 1.0)
			{
				clientImg.x = clientFinalX;
				clientImg.y = clientFinalY;
				clientAnimPhase = 2;
				clientAnimTimer = 0;
			}
		}
		else if (clientAnimPhase == 2)
		{
			var t = Math.min(clientAnimTimer / CLIENT_REVEAL_DURATION, 1.0);
			var eased = FlxEase.sineOut(t);
			var c = Std.int(eased * 255);
			clientImg.color = FlxColor.fromRGB(c, c, c);

			if (t >= 1.0)
			{
				clientImg.color = FlxColor.WHITE;
				clientAnimPhase = 0;
				clientDialog.startDialog(["Hello!", "How are you?", "Nice weather outside, huh?"]);
			}
		}
	}

	function handleDocumentDroppedOnPrinter(doc:DeskDocument):Bool
	{
		if (!printerStation.canAcceptDocument())
			return false;

		doc.lockForPrinterScan();
		printerStation.startScan(doc, function()
		{
			doc.unlockAfterPrinterScan();
			printerStation.animatePaperFeed();
		});
		return true;
	}

	function handleCopyPaperDroppedOnShredder(doc:DeskDocument):Bool
	{
		var paper = Std.downcast(doc, PrinterPaperDocument);
		if (paper == null)
			return false;
		if (!shredderStation.canAcceptDocument())
			return false;

		bringPaperAboveShredder(paper);
		return shredderStation.startShred(paper, function()
		{
			removePrintedPaper(paper);
		});
	}

	function bringPaperAboveShredder(paper:PrinterPaperDocument):Void
	{
		if (documentsAbove.members.indexOf(paper) < 0)
		{
			if (documentsBelow.members.indexOf(paper) >= 0)
				documentsBelow.remove(paper, true);
			documentsAbove.add(paper);
		}
	}

	function removePrintedPaper(paper:PrinterPaperDocument):Void
	{
		printedPapers.remove(paper);
	}

	function syncPrinterPauseForMonitor():Void
	{
		var shouldPause = monitor.isActive() && printerStation.hasActiveJob();
		if (shouldPause == printerPausedByMonitor)
			return;
		printerPausedByMonitor = shouldPause;
		printerStation.setPaused(shouldPause);
	}

	function handleMonitorPrintRequest():Bool
	{
		if (!printerStation.canAcceptDocument())
			return false;
		monitor.hide();
		printerStation.animatePaperFeed();
		return true;
	}

	function tryPickupPrintedPaper(p:flixel.math.FlxPoint):Void
	{
		if (!printerStation.tryPickupPrintedPaper(p.x, p.y))
			return;

		spawnPrintedPaper(printerStation.getPrintedPaperCenterX(), printerStation.getPrintedPaperCenterY(), p.x, p.y);
	}

	function spawnPrintedPaper(centerX:Float, centerY:Float, ?dragMouseX:Float, ?dragMouseY:Float):Void
	{
		var scannedFrom = printerStation.getLastScannedDocument();
		printerStation.clearLastScannedDocument();
		var paper = new PrinterPaperDocument(zones, documentsAbove, scannedFrom);
		var lensCam = magnifyingGlass != null ? magnifyingGlass.lensCam : null;
		paper.cameras = [FlxG.camera];
		if (lensCam != null)
			paper.cameras.push(lensCam);
		paper.onPickedUp = function()
		{
			printerStation.notifyPrintedPaperPickedUp();
		};
		paper.onDroppedOnShredder = handleCopyPaperDroppedOnShredder;
		paper.setPosition(centerX - paper.width * 0.5, centerY - paper.height * 0.5);
		documentsAbove.add(paper);
		printedPapers.push(paper);

		if (dragMouseX != null && dragMouseY != null)
			paper.beginPickupDrag(dragMouseX, dragMouseY);
	}

	function spawnPassport():Void
	{
		passport.prepareClientHandoff();
		var lensCam = magnifyingGlass != null ? magnifyingGlass.lensCam : null;
		passport.cameras = [FlxG.camera];
		if (lensCam != null)
			passport.cameras.push(lensCam);

		if (documentsAbove.members.indexOf(passport) >= 0)
			documentsAbove.remove(passport, true);
		documentsAbove.add(passport);

		var targetX = (zones.leftW - passport.width) * 0.5;
		var targetY = zones.clientTableY + (zones.clientTableH - passport.height) * 0.5;

		passport.setPosition(targetX, zones.clientTableY - passport.height);
		passport.angle = -20;

		FlxTween.tween(passport, {y: targetY, angle: -14.0}, 0.5, {ease: FlxEase.bounceOut});
	}

	function isComputerZoneClick():Bool
	{
		var p = FlxG.mouse.getViewPosition();
		return p.x >= 0 && p.x < zones.leftW && p.y >= zones.computerY && p.y < zones.computerY + zones.computerH;
	}

	function isDocumentAtMouse():Bool
	{
		var p = FlxG.mouse.getViewPosition();
		if (hitsDeskDocumentInGroup(documentsAbove, p))
			return true;
		return hitsDeskDocumentInGroup(documentsBelow, p);
	}

	function hitsDeskDocumentInGroup(group:FlxGroup, p:flixel.math.FlxPoint):Bool
	{
		for (member in group.members)
		{
			if (member == null)
				continue;
			var doc:DeskDocument = Std.downcast(member, DeskDocument);
			if (doc != null && doc.hitsPoint(p))
				return true;
		}
		return false;
	}

	function isTopmostDocumentAtPoint(candidate:DeskDocument, p:flixel.math.FlxPoint):Bool
	{
		return frontmostDocumentAtPoint(p) == candidate;
	}

	function frontmostDocumentAtPoint(p:flixel.math.FlxPoint):DeskDocument
	{
		var doc = frontmostDocumentInGroupAtPoint(documentsAbove, p);
		if (doc != null)
			return doc;
		return frontmostDocumentInGroupAtPoint(documentsBelow, p);
	}

	function frontmostDocumentInGroupAtPoint(group:FlxGroup, p:flixel.math.FlxPoint):DeskDocument
	{
		for (i in 0...group.members.length)
		{
			var idx = group.members.length - 1 - i;
			var member = group.members[idx];
			if (member == null)
				continue;
			var doc:DeskDocument = Std.downcast(member, DeskDocument);
			if (doc == null || !doc.visible || !doc.hitsPoint(p))
				continue;
			return doc;
		}
		return null;
	}

	function createTiledSprite(path:String, x:Int, y:Int, w:Int, h:Int):FlxSprite
	{
		var sample = new FlxSprite();
		sample.loadGraphic(path);
		var tileW = sample.frameWidth;
		var tileH = sample.frameHeight;
		var tilePixels = sample.pixels;

		var bg = new FlxSprite(x, y);
		bg.makeGraphic(w, h, FlxColor.TRANSPARENT, true);

		var destY = 0;
		while (destY < h)
		{
			var destX = 0;
			while (destX < w)
			{
				var copyW = Std.int(Math.min(tileW, w - destX));
				var copyH = Std.int(Math.min(tileH, h - destY));
				bg.pixels.copyPixels(tilePixels, new Rectangle(0, 0, copyW, copyH), new Point(destX, destY));
				destX += tileW;
			}
			destY += tileH;
		}
		bg.dirty = true;
		return bg;
	}

	function createDotGrid(x:Int, y:Int, w:Int, h:Int):FlxSprite
	{
		var dotSpacing = Std.int(Math.max(20, FlxG.height / 30));
		var dotRadius = Std.int(Math.max(1, dotSpacing / 14));
		var dotColor:Int = 0x40FFFFFF;

		var spr = new FlxSprite(x, y);
		spr.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		var bmd = spr.pixels;

		var py = dotSpacing;
		while (py < h)
		{
			var px = dotSpacing;
			while (px < w)
			{
				for (dy in -dotRadius...dotRadius + 1)
				{
					for (dx in -dotRadius...dotRadius + 1)
					{
						if (dx * dx + dy * dy <= dotRadius * dotRadius)
						{
							var drawX = px + dx;
							var drawY = py + dy;
							if (drawX >= 0 && drawX < w && drawY >= 0 && drawY < h)
								bmd.setPixel32(drawX, drawY, dotColor);
						}
					}
				}
				px += dotSpacing;
			}
			py += dotSpacing;
		}

		spr.dirty = true;
		return spr;
	}

	function addSeparator(x:Int, y:Int, w:Int, h:Int):Void
	{
		var line = new LayoutPanel(x, y, w, h, "", FlxColor.fromRGB(120, 130, 145), FlxColor.fromRGB(120, 130, 145));
		add(line);
	}
}
