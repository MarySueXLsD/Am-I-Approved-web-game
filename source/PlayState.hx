package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
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
	var idDocuments:Array<IdDocument>;
	var printedBankDocuments:Array<BankDocument> = [];
	var bookDocument:BookDocument;
	var jobContractDocuments:Array<JobContractDocument>;
	var magnifyingGlass:MagnifyingGlass;
	var monitor:MonitorOverlay;
	var printerStation:PrinterStation;
	var shredderStation:ShredderStation;
	var clientPanel:LayoutPanel;
	var clientWall:FlxSprite;
	var clientTablePanel:LayoutPanel;
	var clientTableImg:FlxSprite;
	var computerPanel:LayoutPanel;
	var computerTable:FlxSprite;
	var computerScreenImg:FlxSprite;
	var computerHud:ComputerHud;
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
	var calculatorDisplayLastFontSize = -1;
	var calculatorDisplayLastValue = "";
	var documentLayersNeedSync = true;
	var bankTextOverlaysNeedSync = true;
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
	var loanFolder:LoanFolderDocument;
	var loanFolderSubmitting = false;
	var pendingLoanFolderSubmit = false;
	var pendingLoanFolderSlide = false;
	var pendingAutoPrintLoanForm = false;
	var currentClientIndex = 0;
	var currentScenario:ClientScenario;
	var chefTutorial:Null<ChefTutorial> = null;
	var chefTutorialPaperWasReady = false;
	var pendingClientAdvance = false;
	var pendingDocumentReturn = false;
	var fraudConfronted = false;
	var salaryUpdateAcknowledged = false;
	var clientHandoutDocs:Array<DeskDocument> = [];
	var pendingLoanReview:Null<LoanReviewResult> = null;

	var clientImg:FlxSprite;
	var clientFinalX:Float;
	var clientFinalY:Float;
	var clientAnimPhase:Int = 0;
	var clientAnimTimer:Float = 0;
	var clientBobOffset:Float = 0;
	var clientEntranceDelayRemaining = 0.0;
	var clientDialog:ClientDialog;
	var beginningDayOverlay:BeginningDayOverlay;
	var mainMenuOverlay:MainMenuOverlay;
	var studioLogoSplash:StudioLogoSplash;
	var officeAmbientAudio:OfficeAmbientAudio;
	var gameplayMusic:GameplayMusic;
	var shiftPauseOverlay:ShiftPauseOverlay;
	var endOfDemoPopup:EndOfDemoPopup;
	var screenFadeOverlay:ScreenFadeOverlay;
	var scanModeOverlay:ScanModeOverlay;
	var deskTutorialCoach:TutorialGuideOverlay;
	var monitorTutorialCoach:TutorialGuideOverlay;
	var scanSelectionConsumed = false;
	var scanClickPending = false;
	var scanClickTimer = 0.0;
	var scanClickX = 0.0;
	var scanClickY = 0.0;
	var lastLensActive = false;
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
	static inline var SCAN_DOUBLE_CLICK_TIME = 0.35;
	static inline var SCAN_DOUBLE_CLICK_DIST = 12.0;

	override function create():Void
	{
		super.create();
		GameSettings.load();
		GameSettings.apply();
		MainMenuOverlay.preloadAudio();

		mainMenuOverlay = new MainMenuOverlay(showBeginningDaySequence);

		GameVisualFilter.install();
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

		clientPanel = new LayoutPanel(0, 0, leftW, clientH, "Client", FlxColor.fromRGB(42, 58, 74));

		clientWall = new FlxSprite(0, 0);
		clientWall.loadGraphic("static/wall.png");
		clientWall.setGraphicSize(leftW, clientH);
		clientWall.updateHitbox();

		clientImg = new FlxSprite(0, 0);
		clientImg.loadGraphic(ClientPortraits.defaultPath());
		var clientScale = (leftW * 0.75) / clientImg.frameWidth;
		clientImg.scale.set(clientScale, clientScale);
		clientImg.updateHitbox();
		clientFinalX = (leftW - clientImg.width) / 2;
		clientFinalY = clientH - clientImg.height + CLIENT_BOB_AMPLITUDE + CLIENT_IMAGE_Y_OFFSET;
		clientImg.x = -clientImg.width;
		clientImg.y = clientFinalY;
		clientImg.color = FlxColor.BLACK;
		clientAnimPhase = 0;
		clientAnimTimer = 0;
		clientEntranceDelayRemaining = 0;

		var dialogMaxW = Std.int(leftW * 0.75);
		clientDialog = new ClientDialog(leftW, 0.0, clientH, dialogMaxW, clientImg, clientFinalY);

		clientTablePanel = new LayoutPanel(0, clientTableY, leftW, clientTableH, "Client's table", FlxColor.fromRGB(52, 68, 84));

		clientTableImg = new FlxSprite(0, clientTableY);
		clientTableImg.loadGraphic("static/table.png");
		clientTableImg.setGraphicSize(leftW, clientTableH);
		clientTableImg.updateHitbox();

		computerPanel = new LayoutPanel(0, computerY, leftW, computerH, "Computer", FlxColor.fromRGB(44, 54, 68));

		var hudFont = Std.int(Math.max(7, FlxG.height / 72));
		var hudBottomPad = Std.int(Math.max(6, FlxG.height / 80));
		var computerHudH = hudFont + 4 + hudBottomPad + 2;
		if (computerHudH >= computerH)
			computerHudH = computerH - 1;
		var computerImgH = computerH - computerHudH;
		if (computerImgH < 1)
			computerImgH = 1;

		computerTable = new FlxSprite(0, computerY);
		computerTable.loadGraphic("static/computer_table.png");
		computerTable.setGraphicSize(leftW, computerImgH);
		computerTable.updateHitbox();

		var computerImgScale = 0.85;
		var computerImgW = Std.int(leftW * computerImgScale);
		var computerImgDrawH = Std.int(computerImgH * computerImgScale);
		var computerImgX = Std.int((leftW - computerImgW) * 0.5);
		var computerImgY = computerY + Std.int((computerImgH - computerImgDrawH) * 0.5);
		computerScreenImg = new FlxSprite(computerImgX, computerImgY);
		computerScreenImg.loadGraphic("static/computer.png");
		computerScreenImg.setGraphicSize(computerImgW, computerImgDrawH);
		computerScreenImg.updateHitbox();

		computerHud = new ComputerHud(0, computerY + computerImgH, leftW, computerHudH);

		var employerTable = new LayoutPanel(employerX, employerTableY, employerW, employerTableH, "Employer's table", FlxColor.fromRGB(32, 48, 62));
		add(employerTable);

		var employerTableTiles = createTiledSprite("static/employers_table.png", employerX, employerTableY, employerW, employerTableH);
		add(employerTableTiles);

		var dotGrid = createDotGrid(employerX, employerTableY, employerW, employerTableH);
		add(dotGrid);

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
		wireDocumentClientWindowHandler(passport);
		idDocuments = [];
		for (variant in IdCardLayouts.defaultDeskVariants())
		{
			var idDoc = new IdDocument(zones, documentsAbove, variant);
			idDoc.onDroppedOnPrinter = handleDocumentDroppedOnPrinter;
			wireDocumentClientWindowHandler(idDoc);
			idDocuments.push(idDoc);
			documentsAbove.add(idDoc);
			stashDocumentOffDesk(idDoc);
		}
		bookDocument = new BookDocument(zones, documentsAbove);
		bookDocument.onDroppedOnPrinter = handleNonPrintableDocumentDrop;
		bookDocument.onDroppedOnShredder = handleNonPrintableDocumentDrop;
		bookDocument.hideFromDesk();
		documentsAbove.add(bookDocument);
		jobContractDocuments = [];
		for (variant in JobContractLayouts.defaultDeskVariants())
		{
			var jobContractDoc = new JobContractDocument(zones, documentsAbove, variant);
			jobContractDoc.onDroppedOnPrinter = handleNonPrintableDocumentDrop;
			jobContractDoc.onDroppedOnShredder = handleNonPrintableDocumentDrop;
			wireDocumentClientWindowHandler(jobContractDoc);
			jobContractDocuments.push(jobContractDoc);
			documentsAbove.add(jobContractDoc);
			stashDocumentOffDesk(jobContractDoc);
		}
		layoutClientTableDocuments();

		magnifyingGlass = new MagnifyingGlass(zones, documentsAbove);
		documentsAbove.add(magnifyingGlass);
		DeskDocument.onDrawLayerChanged = onDocumentDrawLayerChanged;
		DeskDocument.resolveClientTableLayoutTarget = getClientTableLayoutTarget;
		DeskDocument.onUpdateDragPresentation = updateDraggedDocPresentation;
		DeskDocument.isOpenFolderStackUnderDragHover = isOpenFolderStackUnderDragHover;
		DeskDocument.onLensCamerasSync = syncDocumentLensCameras;
		DeskDocument.onDeskPropsLensSync = syncDeskPropCameras;
		DeskDocument.lensSyncGroups = [documentsAbove, documentsBelow];
		DeskDocument.onCanStartDrag = canStartDocumentDrag;
		DeskDocument.isTopmostAtPoint = isTopmostDocumentAtPoint;
		DeskDocument.frontmostDocumentAtPoint = frontmostDocumentAtPoint;
		DeskDocument.magnifierHitsPoint = magnifierHitsPoint;
		DeskDocument.isOverDeskPropsAtPoint = cursorOverDeskPropsAt;
		DeskDocument.isAboveDrawLayerBlockingPoint = isAboveDrawLayerBlockingPoint;
		DeskDocument.shouldHonorClientWindowDrop = shouldHonorClientWindowDrop;
		addDeskPropsAndDocuments();
		syncDeskPropCameras();

		var lc = magnifyingGlass.lensCam;
		var cc = magnifyingGlass.coverCam;
		if (lc != null)
		{
			employerTable.cameras = [FlxG.camera, lc];
			employerTableTiles.cameras = [FlxG.camera, lc];
			dotGrid.cameras = [FlxG.camera, lc];
		}

		CitizenRegistry.load();
		currentClientIndex = initialClientIndex();
		currentScenario = ClientScenarios.get(currentClientIndex);
		applyClientScenario();

		clientDialog.onPassportRequest = function()
		{
		};

		clientDialog.onIdHandoffRequest = function()
		{
			if (chefTutorial != null && chefTutorial.needsChefIdHandoff())
				deliverChefTutorialIdHandoff();
			else
				deliverScenarioDocuments(true);
		};

		clientDialog.onAutoDocumentsRequest = function()
		{
			deliverScenarioDocuments();
		};

		clientDialog.onVisitComplete = function()
		{
			if (chefTutorial != null && chefTutorial.shouldAdvanceOnVisitComplete)
			{
				chefTutorial = null;
				clearTutorialUiRestrictions();
				startClientDeparture();
				return;
			}
			if (pendingDocumentReturn)
				return;
			if (pendingClientAdvance)
				startClientDeparture();
		};

		clientDialog.onPrepareTutorialExit = function()
		{
			if (chefTutorial != null)
				beginChefTutorialIdReturn();
		};

		clientDialog.onTutorialIntroSteps = function()
		{
			if (chefTutorial == null || CitizenRegistry.all.length <= ChefTutorial.CITIZEN_INDEX)
				return ClientScenarios.chefTutorialIntroBaseSteps();
			return chefTutorial.buildIntroSteps(buildChefTutorialContext());
		};

		clientDialog.isScanHintAllowed = function()
		{
			if (isClientEntranceBlocking())
				return false;
			if (chefTutorial == null)
				return true;
			if (chefTutorial.shouldAdvanceOnVisitComplete)
				return false;
			return chefTutorial.shouldAllowScanHint();
		};

		clientDialog.onUnlockScanHint = function()
		{
			if (chefTutorial != null)
				chefTutorial.scanHintUnlocked = true;
		};

		clientDialog.onScanRequest = function()
		{
			enterScanMode();
		};

		clientDialog.onScanDismiss = function()
		{
			if (scanModeOverlay != null)
				scanModeOverlay.setActive(false);
		};

		clientDialog.onTutorialIdle = function()
		{
			if (chefTutorial == null)
				return;
			if (chefTutorial.shouldBeginGuidedTraining())
				chefTutorial.beginGuidedTraining();
			else if (chefTutorial.shouldMarkLoanWalkthroughReady())
				chefTutorial.markLoanWalkthroughReady();
			else if (chefTutorial.shouldBeginLoanGuide())
				chefTutorial.beginLoanGuide();
			else if (chefTutorial.shouldResumeAfterLoanQuestion())
				chefTutorial.resumeAfterLoanQuestion();
			else if (chefTutorial.shouldCompleteFolderIntro())
				chefTutorial.onFolderIntroDialogComplete();
		};

		deskTutorialCoach = new TutorialGuideOverlay();
		add(deskTutorialCoach);

		monitor = new MonitorOverlay();
		monitor.setOnPrintRequest(handleMonitorPrintRequest);
		monitor.setOnPrintChecklistRequest(handleMonitorPrintChecklistRequest);
		monitor.setOnSubmitForApprovalRequest(handleMonitorSubmitForApprovalRequest);
		monitor.getScreenUi().setOnLoanApplicationSubmitted(function()
		{
			if (chefTutorial != null)
				chefTutorial.notifyLoanSubmitted();
		});
		monitor.setOnConversationLogRequest(function() return clientDialog.getConversationLog());
		monitor.setValidateFieldEdit(validateMonitorFieldEdit);
		monitor.setOnFieldValidationFailed(function(path, message)
		{
			if (chefTutorial != null && chefTutorial.handlesUnneededFieldEditInCoach(path))
			{
				chefTutorial.notifyUnneededFieldEdit();
				return true;
			}
			if (chefTutorial != null && path == "averageAnnualSalary"
				&& chefTutorial.handlesSalaryValidationInCoach())
			{
				chefTutorial.notifySalaryValidationFailed(message);
				return true;
			}
			return false;
		});
		monitor.getScreenUi().setShouldRevertOnCoachValidation(function(path:String)
		{
			if (chefTutorial != null && chefTutorial.isWrongClientActive())
				return true;
			return path != "averageAnnualSalary";
		});
		monitor.onMonitorClosed = handleMonitorClosed;
		monitor.onMonitorSlideOutComplete = handleMonitorSlideOutComplete;
		monitor.onMonitorSlideInComplete = function()
		{
			if (chefTutorial != null)
				chefTutorial.notifyMonitorSlideInComplete(monitorTutorialCoach, monitor);
		};
		monitorTutorialCoach = new TutorialGuideOverlay();
		monitor.setTutorialCoach(monitorTutorialCoach);
		add(monitor);
		syncTutorialCoachCameras();

		beginningDayOverlay = new BeginningDayOverlay();
		add(beginningDayOverlay);

		officeAmbientAudio = new OfficeAmbientAudio();
		gameplayMusic = new GameplayMusic();

		screenFadeOverlay = new ScreenFadeOverlay();
		add(screenFadeOverlay);

		shiftPauseOverlay = new ShiftPauseOverlay(showBeginningDaySequence, showMainMenuFromPause, fadeScreenToBlack);
		add(shiftPauseOverlay);

		endOfDemoPopup = new EndOfDemoPopup(showMainMenuFromPause);
		add(endOfDemoPopup);

		scanModeOverlay = new ScanModeOverlay(leftW, clientH);
		ScanModeOverlay.isPointAllowed = isScanModePointAllowed;
		var scanGrayCams = [FlxG.camera];
		if (lc != null)
			scanGrayCams.push(lc);
		if (cc != null)
		{
			scanModeOverlay.setHintCameras([FlxG.camera, cc]);
			scanGrayCams.push(cc);
		}
		scanModeOverlay.setGrayOverlayCameras(scanGrayCams);
		scanModeOverlay.onActionConfirm = function(actionId:String)
		{
			if (actionId == "review_loan_application")
				startLoanApplicationReview();
			else if ((actionId == "compare_id_photo" || actionId == "compare_id_passport")
				&& currentScenario != null && currentScenario.identityFraud && !fraudConfronted)
			{
				fraudConfronted = true;
				pendingDocumentReturn = true;
				clientDialog.startScriptedConversation(ClientScenarios.fraudConfrontationSteps(), true);
			}
			else if (actionId == "compare_id_photo" || actionId == "compare_id_passport")
			{
				clientDialog.startFollowUpDialog(["Looks consistent to me."]);
			}
			else
			{
				if (chefTutorial != null)
				{
					if (actionId == "verify_client_details")
						chefTutorial.onPrintedScanConfirmed();
					else if (BookScanActions.isBookQuestionId(actionId))
						chefTutorial.onLoanQuestionAsked(actionId);
				}

				clientDialog.startBookScanAction(actionId);
				ChefTutorial.pendingBookScanFarewell = false;
			}
		};
		scanModeOverlay.getCitizenDisplayName = function() return clientDialog.getCitizenDisplayName();
		add(scanModeOverlay);

		studioLogoSplash = new StudioLogoSplash();
		add(studioLogoSplash);
		bringToFront(studioLogoSplash);
		studioLogoSplash.show(showMainMenuAfterSplash);
	}

	function showMainMenuAfterSplash():Void
	{
		if (studioLogoSplash != null)
			studioLogoSplash.hide();

		if (mainMenuOverlay == null)
			mainMenuOverlay = new MainMenuOverlay(showBeginningDaySequence);

		remove(mainMenuOverlay, false);
		add(mainMenuOverlay);
		mainMenuOverlay.show(true);
	}

	override function update(elapsed:Float):Void
	{
		scanSelectionConsumed = false;
		ScanModeOverlay.suppressDocumentPress = false;
		updateClientEntrance(elapsed);
		syncCalculatorZone();
		syncPrinterPauseForMonitor();
		magnifyingGlass.setHidden(monitor.isActive() || beginningDayOverlay.isShowing || mainMenuOverlay.isShowing
			|| shiftPauseOverlay.isActive() || EndOfDemoPopup.blocksWorldInput() || StudioLogoSplash.blocksWorldInput());
		updateCalculatorToggleUi();
		updateCalculatorDisplayVisuals(elapsed);
		updateCalculatorButtonOverlay();

		var p = FlxG.mouse.getViewPosition();

		if (StudioLogoSplash.blocksWorldInput())
		{
			if (FlxG.mouse.justPressed && studioLogoSplash != null)
				studioLogoSplash.skip();
			super.update(elapsed);
			return;
		}

		if (screenFadeOverlay.isBusy)
		{
			bringToFront(screenFadeOverlay);
			super.update(elapsed);
			return;
		}

		updateScanModeUi(p, elapsed);
		officeAmbientAudio.update(elapsed);

		if (beginningDayOverlay.isShowing)
		{
			if (FlxG.mouse.justPressed)
				beginningDayOverlay.handleClick(p);
			super.update(elapsed);
			return;
		}

		if (MainMenuOverlay.blocksWorldInput() && !mainMenuOverlay.isShowing)
		{
			super.update(elapsed);
			return;
		}

		if (mainMenuOverlay.isShowing)
		{
			if (FlxG.mouse.wheel != 0)
				mainMenuOverlay.handleWheel(FlxG.mouse.wheel);
			if (FlxG.mouse.justPressed)
				mainMenuOverlay.handleClick(p);
			super.update(elapsed);
			return;
		}

		if (shiftPauseOverlay.isActive())
		{
			if (FlxG.keys.justPressed.ESCAPE)
				shiftPauseOverlay.handleEscape();
			if (FlxG.mouse.justPressed)
				shiftPauseOverlay.handleClick(p);
			super.update(elapsed);
			return;
		}

		if (EndOfDemoPopup.blocksWorldInput())
		{
			endOfDemoPopup.updateHover();
			if (FlxG.mouse.justPressed)
				endOfDemoPopup.handleClick(p);
			super.update(elapsed);
			return;
		}

		if (FlxG.keys.justPressed.ESCAPE && !beginningDayOverlay.isShowing && !mainMenuOverlay.isShowing && !monitor.isActive())
		{
			if (scanModeOverlay != null)
				scanModeOverlay.setActive(false);
			scanClickPending = false;
			remove(shiftPauseOverlay, false);
			add(shiftPauseOverlay);
			shiftPauseOverlay.show();
			super.update(elapsed);
			return;
		}

		if (!scanSelectionConsumed && !monitor.isActive() && FlxG.mouse.justPressed && !MonitorOverlay.blocksWorldInput()
			&& !BeginningDayOverlay.blocksWorldInput() && !MainMenuOverlay.blocksWorldInput()
			&& !ShiftPauseOverlay.blocksWorldInput() && !EndOfDemoPopup.blocksWorldInput() && !ScreenFadeOverlay.blocksWorldInput()
			&& !scanModeBlocksPoint(p)
			&& (chefTutorial == null || !chefTutorial.blocksDeskInteraction(p.x, p.y, deskTutorialCoach)))
		{
			tryPickupPrintedPaper(p);
		}

		if (monitor.isActive())
		{
			fadeCalculatorButtonOverlays(elapsed);

			if (!monitor.isBusy)
				monitor.updateScreenInput(p);

			if (FlxG.mouse.justReleased)
				monitor.handleScreenRelease();

			updateChefTutorialGuide(elapsed);
			super.update(elapsed);
			syncDocumentLayers();
			finalizeTutorialOverlay();

			if (FlxG.mouse.justPressed)
			{
				var monitorCoach = monitorTutorialCoach;
				if (monitorCoach.isShowing && monitorCoach.isPointOnOverlay(p.x, p.y))
					return;

				if (monitor.isShowing && monitor.containsInteractivePoint(p))
				{
					if (chefTutorial == null || chefTutorial.isMonitorClickAllowed(p.x, p.y, monitor.getScreenUi(), monitorCoach))
						monitor.handleScreenClick(p);
				}
				else if (chefTutorial == null || !chefTutorial.blocksMonitorDismiss())
					monitor.hide();
			}
			return;
		}

		updateChefTutorialGuide(elapsed);
		updateChefTutorialProgressTriggers();

		super.update(elapsed);
		syncDocumentLayers();
		finalizeTutorialOverlay();

		if (scanSelectionConsumed)
			return;

		updateCalculatorToggleInput(p);
		updateCalculatorButtonInput(p);
		updateCalculatorFocus(p);
		updateCalculatorKeyboardInput();

		if (!FlxG.mouse.justPressed)
			return;
		if (clientDialog.consumedClick)
			return;

		if (chefTutorial != null && chefTutorial.blocksDeskInteraction(p.x, p.y, deskTutorialCoach))
			return;

		if (scanModeOverlay != null && scanModeOverlay.isActive)
			return;

		if (scanModeBlocksPoint(p))
			return;

		if (!isComputerZoneClick() || isDocumentAtMouse())
			return;

		if (chefTutorial != null && currentScenario.isTutorial && !chefTutorial.allowsComputerClick()
			&& !(chefTutorial.isLoanSalaryComputerClickReady() && isComputerZoneClick()))
			return;

		resetCalculatorButtonOverlayVisuals();
		if (chefTutorial != null
			&& (chefTutorial.allowsComputerClick() || chefTutorial.isLoanSalaryComputerClickReady()))
		{
			chefTutorial.requestComputerOpen(deskTutorialCoach, function()
			{
				monitor.show();
			});
		}
		else
			monitor.show();
	}

	function addDeskPropsAndDocuments():Void
	{
		// Large/open employer-table docs draw under desk props; closed docs draw on top.
		add(documentsBelow);
		// Left-column panels sit above open employer docs so ID text/card cannot bleed over them.
		add(clientPanel);
		add(clientWall);
		add(clientImg);
		add(clientDialog);
		add(clientTablePanel);
		add(clientTableImg);
		add(computerPanel);
		add(computerTable);
		add(computerScreenImg);
		add(computerHud);
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
		var lensActive = magnifyingGlass != null && magnifyingGlass.visible && magnifyingGlass.isCurrentlyOpen();
		var dragging = DeskDocument.currentDrag != null;
		var needLensSync = lensActive || lastLensActive || dragging;

		if (documentLayersNeedSync || dragging)
		{
			// Place folder first so other closed docs stack above it within documentsAbove.
			if (loanFolder != null)
				moveDocumentToLayer(loanFolder);
			moveDocumentToLayer(passport);
			for (idDoc in idDocuments)
				moveDocumentToLayer(idDoc);
			for (bankDoc in printedBankDocuments)
				moveDocumentToLayer(bankDoc);
			moveDocumentToLayer(bookDocument);
			if (bookDocument.slideAboveTableDocs)
				bookDocument.bringToFrontInLayer();
			for (jobContractDoc in jobContractDocuments)
				moveDocumentToLayer(jobContractDoc);
			moveDocumentToLayer(magnifyingGlass);
			for (paper in printedPapers)
				movePrintedPaperToLayer(paper);
			documentLayersNeedSync = false;
		}

		if (bankTextOverlaysNeedSync || dragging)
		{
			syncAllBankDocumentTextOverlays();
			bankTextOverlaysNeedSync = false;
		}

		if (needLensSync)
			syncOpenDocumentCameras();
		lastLensActive = lensActive;

		updateClientGiveBackHint();
	}

	function updateClientGiveBackHint():Void
	{
		if (!pendingDocumentReturn)
		{
			clientDialog.setGiveBackHintVisible(false);
			return;
		}

		var drag = DeskDocument.currentDrag;
		if (drag == null || !isRegisteredClientHandout(drag))
		{
			clientDialog.setGiveBackHintVisible(false);
			return;
		}

		var mouse = FlxG.mouse.getViewPosition();
		clientDialog.setGiveBackHintVisible(clientDialog.isPointInClientArea(mouse.x, mouse.y));
	}

	function shouldHonorClientWindowDrop(doc:DeskDocument, mx:Float, my:Float):Bool
	{
		if (!pendingDocumentReturn || !isRegisteredClientHandout(doc))
			return false;
		return clientDialog.isPointInClientArea(mx, my);
	}

	function returnStrandedDocsFromClientWindow():Void
	{
		for (member in documentsAbove.members)
			returnStrandedDocFromClientWindow(Std.downcast(member, DeskDocument));
		for (member in documentsBelow.members)
			returnStrandedDocFromClientWindow(Std.downcast(member, DeskDocument));
		layoutClientTableDocuments();
	}

	function returnStrandedDocFromClientWindow(doc:DeskDocument):Void
	{
		if (doc == null || !doc.visible || !doc.isOnClientWindow())
			return;

		var cx = doc.x + doc.width * 0.5;
		var cy = doc.y + doc.height * 0.5;
		if (shouldHonorClientWindowDrop(doc, cx, cy))
			return;

		doc.placeOnClientTable();
	}

	function isRegisteredClientHandout(doc:DeskDocument):Bool
	{
		return clientHandoutDocs.indexOf(doc) >= 0;
	}

	function onDocumentDrawLayerChanged(doc:DeskDocument):Void
	{
		moveDocumentToLayer(doc);
	}

	function markDocumentLayersDirty():Void
	{
		documentLayersNeedSync = true;
		bankTextOverlaysNeedSync = true;
	}

	function syncAllBankDocumentTextOverlays():Void
	{
		for (bankDoc in printedBankDocuments)
		{
			if (bankDoc.isCurrentlyOpen() || bankDoc.isStoredInLoanFolder())
				bankDoc.syncTextOverlayLayerOrder();
		}

		if (loanFolder != null)
		{
			for (stored in loanFolder.getStoredDocuments())
			{
				var bankDoc = Std.downcast(stored, BankDocument);
				if (bankDoc != null)
					bankDoc.syncTextOverlayLayerOrder();
			}
		}
	}

	function movePrintedPaperToLayer(paper:PrinterPaperDocument):Void
	{
		assignDocToDrawLayer(paper, resolveDrawLayerForDoc(paper));
		if (paper.isStoredInLoanFolder())
		{
			paper.refreshStoredCopyOverlays();
			var folder = paper.loanFolderStorage;
			if (folder != null)
				folder.syncStoredCopiesToLayer();
		}
		markDocumentLayersDirty();
	}

	function moveDocumentToLayer(doc:DeskDocument):Void
	{
		var printedPaper = Std.downcast(doc, PrinterPaperDocument);
		if (printedPaper != null)
		{
			movePrintedPaperToLayer(printedPaper);
			return;
		}

		assignDocToDrawLayer(doc, resolveDrawLayerForDoc(doc));
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null && bankDoc.isStoredInLoanFolder())
			bankDoc.refreshStoredTextOverlays();
		markDocumentLayersDirty();
	}

	function resolveDrawLayerForDoc(doc:DeskDocument):FlxGroup
	{
		if (doc.isDragging() && doc.isCompactDragPreviewActive())
			return documentsAbove;

		// Pocket copies share the open folder's below-desk-props layer and stack on top of it.
		if (doc.loanFolderStorage != null)
		{
			var hostFolder = doc.loanFolderStorage;
			if (hostFolder.isSpreadOpen() && hostFolder.isOpenOnEmployerTable())
				return documentsBelow;
			return documentsAbove;
		}

		if (!doc.isCurrentlyOpen())
			return documentsAbove;

		var folder = Std.downcast(doc, LoanFolderDocument);
		if (folder != null && folder.isSpreadOpen() && doc.isOpenOnEmployerTable())
			return documentsBelow;

		if (doc.visible && doc.isOpenOnEmployerTable())
			return documentsBelow;

		return documentsAbove;
	}

	function updateDraggedDocPresentation(doc:DeskDocument):Void
	{
		if (doc == null || !doc.isDragging())
			return;

		if (Std.downcast(doc, LoanFolderDocument) != null || Std.downcast(doc, MagnifyingGlass) != null)
		{
			doc.endCompactDragPreview();
			return;
		}

		var mouse = FlxG.mouse.getViewPosition();
		if (shouldUseCompactDragPreview(doc, mouse.x, mouse.y))
			doc.beginCompactDragPreview();
		else
			doc.endCompactDragPreview();

		if (isOpenFolderStackUnderDragHover())
		{
			assignDocToDrawLayer(doc, documentsAbove);
			doc.bringToFrontInLayer();
			if (loanFolder != null)
				loanFolder.syncStoredCopiesToLayer();
			markDocumentLayersDirty();
		}
	}

	function isOpenFolderStackUnderDragHover():Bool
	{
		var drag = DeskDocument.currentDrag;
		if (drag == null || Std.downcast(drag, LoanFolderDocument) != null)
			return false;

		var folder = loanFolder;
		if (folder == null || !folder.isSpreadOpen() || !folder.isOpenOnEmployerTable())
			return false;

		var mouse = FlxG.mouse.getViewPosition();
		return isPointOverOpenFolderStack(folder, mouse.x, mouse.y);
	}

	function isPointOverOpenFolderStack(folder:LoanFolderDocument, mx:Float, my:Float):Bool
	{
		if (folder.isDepositHoverAt(mx, my))
			return true;

		if (folder.pointInStorageWorld(mx, my))
			return true;

		var p = FlxPoint.get(mx, my);
		for (stored in folder.getStoredDocuments())
		{
			if (stored.visible && stored.overlapsPoint(p))
			{
				p.put();
				return true;
			}
		}
		p.put();
		return false;
	}

	function shouldUseCompactDragPreview(doc:DeskDocument, mx:Float, my:Float):Bool
	{
		if (cursorOverDeskProps(mx, my))
			return true;

		var folder = loanFolder;
		if (folder == null || !folder.isSpreadOpen() || !folder.isOpenOnEmployerTable())
			return false;

		return isPointOverOpenFolderStack(folder, mx, my);
	}

	function cursorOverDeskProps(mx:Float, my:Float):Bool
	{
		var p = FlxPoint.get(mx, my);
		var hit = cursorOverDeskPropsAt(p);
		p.put();
		return hit;
	}

	function cursorOverDeskPropsAt(p:FlxPoint):Bool
	{
		if (printerStation != null
			&& cursorInAxisRect(p.x, p.y, printerStation.getBodyX(), printerStation.getBodyY(), printerStation.getBodyW(), printerStation.getBodyH()))
			return true;

		if (shredderStation != null
			&& cursorInAxisRect(p.x, p.y, shredderStation.getBodyX(), shredderStation.getBodyY(), shredderStation.getBodyW(), shredderStation.getBodyH()))
			return true;

		if (calculatorObj != null && calculatorObj.visible && calculatorObj.overlapsPoint(p))
			return true;

		if (calculatorToggleOverlay != null && calculatorToggleOverlay.visible && calculatorToggleOverlay.overlapsPoint(p))
			return true;

		if (calculatorDisplayScan != null && calculatorDisplayScan.visible && calculatorDisplayScan.overlapsPoint(p))
			return true;

		for (overlay in calculatorBtnOverlays)
		{
			if (overlay != null && overlay.visible && overlay.overlapsPoint(p))
				return true;
		}

		if (p.x >= 0 && p.x < zones.leftW)
		{
			if (p.y >= 0 && p.y < zones.clientH)
				return true;
			if (p.y >= zones.clientTableY && p.y < zones.clientTableY + zones.clientTableH)
				return true;
			if (p.y >= zones.computerY && p.y < zones.computerY + zones.computerH)
				return true;
		}

		return false;
	}

	function isAboveDrawLayerBlockingPoint(p:FlxPoint):Bool
	{
		for (member in documentsAbove.members)
		{
			if (member == null)
				continue;

			var doc = Std.downcast(member, DeskDocument);
			if (doc == null || !doc.visible || doc.isStoredInLoanFolder())
				continue;

			if (doc.overlapsPoint(p))
				return true;
		}

		return false;
	}

	function cursorInAxisRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
	{
		return px >= rx && px < rx + rw && py >= ry && py < ry + rh;
	}

	function assignDocToDrawLayer(doc:DeskDocument, target:FlxGroup):Void
	{
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

		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null)
		{
			bankDoc.moveToDocumentLayer(target);
			return;
		}

		var bookDoc = Std.downcast(doc, BookDocument);
		if (bookDoc != null)
		{
			bookDoc.moveToDocumentLayer(target);
			return;
		}

		var folder = Std.downcast(doc, LoanFolderDocument);
		if (folder != null)
		{
			folder.moveToLayer(target);
			folder.syncStoredCopiesToLayer();
			return;
		}

		doc.moveToLayer(target);
	}

	function syncDeskPropCameras():Void
	{
		var cams = [FlxG.camera];
		if (magnifyingGlass != null)
		{
			var coverCam = magnifyingGlass.coverCam;
			var lensActive = coverCam != null && magnifyingGlass.visible && magnifyingGlass.isCurrentlyOpen();
			if (lensActive)
				cams.push(coverCam);
			if (!sameCameras(magnifyingGlass.cameras, cams))
				magnifyingGlass.cameras = cams;
		}

		if (sameCameras(clientPanel.cameras, cams))
		{
			syncTutorialCoachCameras();
			return;
		}

		clientPanel.cameras = cams;
		clientWall.cameras = cams;
		clientImg.cameras = cams;
		clientDialog.setCameras(cams);
		clientTablePanel.cameras = cams;
		clientTableImg.cameras = cams;
		computerPanel.cameras = cams;
		computerTable.cameras = cams;
		computerScreenImg.cameras = cams;
		computerHud.setCameras(cams);
		printerStation.setStationCameras(cams);
		shredderStation.setStationCameras(cams);
		calculatorObj.cameras = cams;
		calculatorToggleOverlay.cameras = cams;
		calculatorToggleLabel.cameras = cams;
		calculatorDisplayScan.cameras = cams;
		calculatorDisplayText.cameras = cams;
		for (overlay in calculatorBtnOverlays)
			overlay.cameras = cams;

		syncTutorialCoachCameras();
	}

	function getGameplayOverlayCameras():Array<FlxCamera>
	{
		var cams = [FlxG.camera];
		if (magnifyingGlass != null)
		{
			var lensCam = magnifyingGlass.lensCam;
			var coverCam = magnifyingGlass.coverCam;
			if (lensCam != null)
				cams.push(lensCam);
			if (coverCam != null)
				cams.push(coverCam);
		}
		return cams;
	}

	function syncTutorialCoachCameras():Void
	{
		var cams = [FlxG.camera];
		if (magnifyingGlass != null)
		{
			var coverCam = magnifyingGlass.coverCam;
			var lensActive = coverCam != null && magnifyingGlass.visible && magnifyingGlass.isCurrentlyOpen();
			if (lensActive)
				cams.push(coverCam);
		}
		if (deskTutorialCoach != null)
			deskTutorialCoach.setCameras(cams);
		if (monitorTutorialCoach != null)
			monitorTutorialCoach.setCameras(cams);
	}

	function finalizeTutorialOverlay():Void
	{
		syncTutorialCoachCameras();
		var preferMonitorCoach = chefTutorial != null && chefTutorial.isMonitorGuidePhase() && monitor.isActive();
		if (preferMonitorCoach)
		{
			if (monitor != null)
				bringToFront(monitor);
		}
		else if (deskTutorialCoach != null && deskTutorialCoach.isShowing)
			bringToFront(deskTutorialCoach);
		else if (monitorTutorialCoach != null && monitorTutorialCoach.isShowing)
			bringToFront(monitorTutorialCoach);
	}

	function syncOpenDocumentCameras():Void
	{
		if (magnifyingGlass == null)
			return;

		var lensActive = magnifyingGlass.visible && magnifyingGlass.isCurrentlyOpen();
		if (!lensActive)
			syncDeskPropCameras();

		syncDocumentLensCameras(passport);
		for (idDoc in idDocuments)
			syncDocumentLensCameras(idDoc);
		for (bankDoc in printedBankDocuments)
			syncDocumentLensCameras(bankDoc);
		syncDocumentLensCameras(bookDocument);
		for (jobContractDoc in jobContractDocuments)
			syncDocumentLensCameras(jobContractDoc);
		if (loanFolder != null)
		{
			syncDocumentLensCameras(loanFolder);
			for (stored in loanFolder.getStoredDocuments())
				syncDocumentLensCameras(stored);
		}
	}

	function layoutClientTableDocuments():Void
	{
		for (idDoc in idDocuments)
		{
			if (!idDoc.belongsInClientTableRow() || idDoc.isSnappingToTable())
				continue;
			var target = getClientTableLayoutTarget(idDoc);
			idDoc.setPosition(target.x, target.y);
		}
		for (bankDoc in printedBankDocuments)
		{
			if (!bankDoc.belongsInClientTableRow() || bankDoc.isSnappingToTable())
				continue;
			bankDoc.refreshDisplaySize();
			var bankTarget = getClientTableLayoutTarget(bankDoc);
			bankDoc.setPosition(bankTarget.x, bankTarget.y);
		}
		if (bookDocument != null && bookDocument.belongsInClientTableRow() && !bookDocument.isSnappingToTable())
		{
			bookDocument.refreshDisplaySize();
			var bookTarget = getClientTableLayoutTarget(bookDocument);
			bookDocument.setPosition(bookTarget.x, bookTarget.y);
		}
		for (jobContractDoc in jobContractDocuments)
		{
			if (!jobContractDoc.belongsInClientTableRow() || jobContractDoc.isSnappingToTable())
				continue;
			jobContractDoc.refreshDisplaySize();
			var contractTarget = getClientTableLayoutTarget(jobContractDoc);
			jobContractDoc.setPosition(contractTarget.x, contractTarget.y);
		}
	}

	function includesDocInClientTableLayout(doc:DeskDocument, forDoc:DeskDocument):Bool
	{
		if (doc.isStoredInLoanFolder())
			return false;
		if (doc == forDoc)
			return true;
		return doc.belongsInClientTableRow();
	}

	function getClientTableLayoutTarget(doc:DeskDocument):{x:Float, y:Float}
	{
		var gap = zones.leftW * 0.015;
		var totalW = 0.0;
		var docCount = 0;
		for (idDoc in idDocuments)
		{
			if (!includesDocInClientTableLayout(idDoc, doc))
				continue;
			totalW += idDoc.width;
			docCount += 1;
		}
		for (bankDoc in printedBankDocuments)
		{
			if (!includesDocInClientTableLayout(bankDoc, doc))
				continue;
			totalW += bankDoc.width;
			docCount += 1;
		}
		if (bookDocument != null && includesDocInClientTableLayout(bookDocument, doc))
		{
			totalW += bookDocument.width;
			docCount += 1;
		}
		for (jobContractDoc in jobContractDocuments)
		{
			if (!includesDocInClientTableLayout(jobContractDoc, doc))
				continue;
			totalW += jobContractDoc.width;
			docCount += 1;
		}
		if (docCount == 0)
		{
			var fallbackY = zones.clientTableY + zones.clientTableH * 0.5 - doc.height * 0.5;
			return {x: (zones.leftW - doc.width) * 0.5, y: fallbackY};
		}
		totalW += gap * (docCount - 1);

		var startX = (zones.leftW - totalW) * 0.5;
		var centerY = zones.clientTableY + zones.clientTableH * 0.5;
		var x = startX;
		for (idDoc in idDocuments)
		{
			if (!includesDocInClientTableLayout(idDoc, doc))
				continue;
			if (idDoc == doc)
				return {x: x, y: centerY - idDoc.height * 0.5};
			x += idDoc.width + gap;
		}
		for (bankDoc in printedBankDocuments)
		{
			if (!includesDocInClientTableLayout(bankDoc, doc))
				continue;
			if (bankDoc == doc)
				return {x: x, y: centerY - bankDoc.height * 0.5};
			x += bankDoc.width + gap;
		}
		if (bookDocument != null && includesDocInClientTableLayout(bookDocument, doc))
		{
			if (bookDocument == doc)
				return {x: x, y: centerY - bookDocument.height * 0.5};
			x += bookDocument.width + gap;
		}
		for (jobContractDoc in jobContractDocuments)
		{
			if (!includesDocInClientTableLayout(jobContractDoc, doc))
				continue;
			if (jobContractDoc == doc)
				return {x: x, y: centerY - jobContractDoc.height * 0.5};
			x += jobContractDoc.width + gap;
		}
		return {x: (zones.leftW - doc.width) * 0.5, y: centerY - doc.height * 0.5};
	}

	function applyCurrentCitizen(citizen:Citizen):Void
	{
		applyClientPortrait(citizen);
		passport.setCitizen(citizen);
		setCitizenOnClientDocuments(citizen);
		clientDialog.setCitizenName(citizen.firstName + " " + citizen.lastName);
	}

	function idCardCitizenForScenario(citizen:Citizen):Citizen
	{
		if (currentScenario == null || currentScenario.idCardCitizenIndex < 0)
			return citizen;

		var idx = currentScenario.idCardCitizenIndex;
		if (idx < 0 || idx >= CitizenRegistry.all.length)
			return citizen;

		return CitizenRegistry.all[idx];
	}

	function wireDocumentClientWindowHandler(doc:DeskDocument):Void
	{
		doc.onDroppedOnClientWindow = handleDocumentDroppedOnClientWindow;
	}

	function handleDocumentDroppedOnClientWindow(doc:DeskDocument):Void
	{
		checkClientDocumentReturn();
	}

	function clearClientHandoutDocs():Void
	{
		clientHandoutDocs = [];
	}

	function registerClientHandout(doc:DeskDocument):Void
	{
		if (doc == null || clientHandoutDocs.indexOf(doc) >= 0)
			return;
		clientHandoutDocs.push(doc);
	}

	function resetScenarioVisitState():Void
	{
		pendingDocumentReturn = false;
		fraudConfronted = false;
		salaryUpdateAcknowledged = false;
		clearClientHandoutDocs();
	}

	function checkClientDocumentReturn():Void
	{
		if (!pendingDocumentReturn || clientHandoutDocs.length == 0)
			return;

		for (doc in clientHandoutDocs)
		{
			if (!doc.visible || !doc.isOnClientWindow())
				return;
		}

		pendingDocumentReturn = false;
		consumeReturnedClientHandouts();

		if (chefTutorial != null && chefTutorial.awaitingIdReturn)
		{
			chefTutorial.awaitingIdReturn = false;
			chefTutorial.shouldAdvanceOnVisitComplete = true;
			if (clientDialog.canAcceptFollowUp())
				clientDialog.startScriptedConversation(ClientScenarios.chefTutorialIdReturnThanksSteps(), true);
			return;
		}

		startClientDeparture();
	}

	function beginChefTutorialIdReturn():Void
	{
		if (chefTutorial == null)
			return;

		chefTutorial.awaitingIdReturn = true;
		pendingDocumentReturn = true;

		var chefId = findIdDocument(Lorian);
		if (chefId != null && clientHandoutDocs.indexOf(chefId) < 0)
			registerClientHandout(chefId);
	}

	function consumeReturnedClientHandouts():Void
	{
		for (doc in clientHandoutDocs)
			stashDocumentOffDesk(doc);
		clearClientHandoutDocs();
	}

	function isScenarioAnnualSalaryCorrect(citizen:Citizen):Bool
	{
		if (currentScenario == null || !currentScenario.needsAnnualSalaryUpdate())
			return false;

		var target = currentScenario.expectedAnnualSalary;
		var tolerance = currentScenario.annualSalaryTolerance;
		return Math.abs(citizen.averageAnnualSalary - target) <= tolerance;
	}

	function validateMonitorFieldEdit(citizen:Citizen, path:String, value:String):Null<String>
	{
		if (chefTutorial != null && chefTutorial.shouldBlockFieldEdit(citizen, path))
			return ChefTutorial.unneededFieldEditCoachText();

		if (path != "averageAnnualSalary" || value.length == 0)
			return null;

		var salary = Std.parseFloat(StringTools.trim(value));
		if (salary == null)
			return null;

		var rounded = Math.round(salary);

		if (chefTutorial != null && CitizenRegistry.indexOf(citizen) == ChefTutorial.CITIZEN_INDEX)
		{
			if (rounded != ChefTutorial.TARGET_SALARY)
				return ChefTutorial.salaryValidationMessage();
			return null;
		}

		if (currentScenario != null && currentScenario.needsAnnualSalaryUpdate()
			&& CitizenRegistry.indexOf(citizen) == currentScenario.citizenIndex)
		{
			var target = Std.int(currentScenario.expectedAnnualSalary);
			if (Math.abs(rounded - target) > currentScenario.annualSalaryTolerance)
				return 'Sorry! Annual salary needs\nto be $target LOR.';
		}

		return null;
	}

	function tryScenarioSalaryProgressDialogue():Void
	{
		if (currentScenario == null || !currentScenario.needsAnnualSalaryUpdate())
			return;
		if (salaryUpdateAcknowledged || pendingDocumentReturn)
			return;
		if (CitizenRegistry.all.length == 0)
			return;

		var citizenIdx = currentScenario.citizenIndex;
		if (citizenIdx < 0 || citizenIdx >= CitizenRegistry.all.length)
			return;

		var citizen = CitizenRegistry.all[citizenIdx];
		if (!isScenarioAnnualSalaryCorrect(citizen))
			return;
		if (!clientDialog.canAcceptFollowUp())
			return;

		salaryUpdateAcknowledged = true;
		pendingDocumentReturn = true;
		clientDialog.startScriptedConversation(ClientScenarios.kethranSalaryCompleteSteps(), true);
	}

	function applyClientScenario():Void
	{
		if (CitizenRegistry.all.length == 0)
			return;

		currentScenario = ClientScenarios.get(currentClientIndex);
		var citizenIdx = currentScenario.citizenIndex;
		if (citizenIdx < 0 || citizenIdx >= CitizenRegistry.all.length)
			citizenIdx = 0;

		chefTutorial = currentScenario.isTutorial ? new ChefTutorial() : null;
		chefTutorialPaperWasReady = false;
		resetScenarioVisitState();

		clientDialog.setScenario(currentScenario);
		bookDocument.setHidePassportBookQuestion(true);
		applyCurrentCitizen(CitizenRegistry.all[citizenIdx]);
		setupDefaultClientTable();
	}

	function setupDefaultClientTable():Void
	{
		hidePassportOnDesk();

		for (idDoc in idDocuments)
			stashDocumentOffDesk(idDoc);
		for (jobContractDoc in jobContractDocuments)
			stashDocumentOffDesk(jobContractDoc);

		if (currentScenario != null && currentScenario.isTutorial)
			stashDocumentOffDesk(bookDocument);
		else
			ensureGuideBookOnClientTable();

		magnifyingGlass.placeOnClientTable();
		layoutClientTableDocuments();
		moveDocumentToLayer(magnifyingGlass);
	}

	function ensureGuideBookOnClientTable():Void
	{
		if (bookDocument == null)
			return;

		bookDocument.placeClosedOnClientTable();
		if (documentsAbove.members.indexOf(bookDocument) < 0)
			documentsAbove.add(bookDocument);
		moveDocumentToLayer(bookDocument);
		layoutClientTableDocuments();
	}

	function stashDocumentOffDesk(doc:DeskDocument):Void
	{
		doc.hideFromDesk();
	}

	function deliverScenarioDocuments(?fromClient:Bool = false):Void
	{
		if (fromClient)
			clientDialog.markScenarioDocumentsDelivered();

		clearClientHandoutDocs();

		if (currentScenario != null && currentScenario.passportIncludedInOpening)
		{
			spawnPassport();
			registerClientHandout(passport);
		}

		if (currentScenario != null && currentScenario.idVariant != null)
		{
			spawnClientIdDocument(currentScenario.idVariant, fromClient);
			registerClientHandout(findIdDocument(currentScenario.idVariant));
		}

		if (currentScenario != null && currentScenario.jobContractVariant != null)
		{
			spawnJobContractDocument(currentScenario.jobContractVariant);
			registerClientHandout(findJobContractDocument(currentScenario.jobContractVariant));
		}

		layoutClientTableDocuments();
	}

	function findIdDocument(variant:IdCardVariant):Null<IdDocument>
	{
		for (idDoc in idDocuments)
		{
			if (idDoc.getVariant() == variant)
				return idDoc;
		}
		return null;
	}

	function findJobContractDocument(variant:JobContractVariant):Null<JobContractDocument>
	{
		for (jobContractDoc in jobContractDocuments)
		{
			if (jobContractDoc.getVariant() == variant)
				return jobContractDoc;
		}
		return null;
	}

	function spawnJobContractDocument(variant:JobContractVariant):Void
	{
		for (jobContractDoc in jobContractDocuments)
		{
			if (jobContractDoc.getVariant() != variant)
				continue;

			jobContractDoc.prepareClientHandoff();
			var lensCam = magnifyingGlass != null ? magnifyingGlass.lensCam : null;
			jobContractDoc.cameras = [FlxG.camera];
			if (lensCam != null)
				jobContractDoc.cameras.push(lensCam);

			if (documentsAbove.members.indexOf(jobContractDoc) < 0)
				documentsAbove.add(jobContractDoc);

			var target = getClientTableLayoutTarget(jobContractDoc);
			jobContractDoc.setPosition(target.x, zones.clientTableY - jobContractDoc.height);
			jobContractDoc.angle = 10;

			FlxTween.tween(jobContractDoc, {y: target.y, angle: 6.0}, 0.5, {ease: FlxEase.bounceOut});
			moveDocumentToLayer(jobContractDoc);
			return;
		}
	}

	function spawnClientIdDocument(variant:IdCardVariant, ?fromClient:Bool = false):Void
	{
		for (idDoc in idDocuments)
		{
			if (idDoc.getVariant() != variant)
				continue;

			idDoc.prepareClientHandoff();
			var lensCam = magnifyingGlass != null ? magnifyingGlass.lensCam : null;
			idDoc.cameras = [FlxG.camera];
			if (lensCam != null)
				idDoc.cameras.push(lensCam);

			if (documentsAbove.members.indexOf(idDoc) < 0)
				documentsAbove.add(idDoc);

			var target = getClientTableLayoutTarget(idDoc);
			if (fromClient)
			{
				var startX = clientFinalX + (clientImg.width - idDoc.width) * 0.5;
				var startY = clientFinalY + clientImg.height * 0.35;
				idDoc.playDropFromClient(startX, startY, target.x, target.y, 8.0);
			}
			else
			{
				idDoc.setPosition(target.x, zones.clientTableY - idDoc.height);
				idDoc.angle = 12;
				FlxTween.tween(idDoc, {y: target.y, angle: 8.0}, 0.5, {ease: FlxEase.bounceOut});
			}

			moveDocumentToLayer(idDoc);
			return;
		}
	}

	function applyClientPortrait(citizen:Citizen):Void
	{
		var portraitPath = currentScenario != null ? currentScenario.portraitPath : ClientPortraits.pathForCitizen(citizen);
		clientImg.loadGraphic(portraitPath);
		var clientScale = (zones.leftW * 0.75) / clientImg.frameWidth;
		clientImg.scale.set(clientScale, clientScale);
		clientImg.updateHitbox();
		clientFinalX = (zones.leftW - clientImg.width) / 2;
		clientFinalY = zones.clientH - clientImg.height + CLIENT_BOB_AMPLITUDE + CLIENT_IMAGE_Y_OFFSET;
	}

	function setCitizenOnClientDocuments(citizen:Citizen):Void
	{
		var idCitizen = idCardCitizenForScenario(citizen);
		var idPortraitPath = currentScenario != null
			? currentScenario.portraitPath
			: ClientPortraits.pathForClientSlot(currentClientIndex);
		for (idDoc in idDocuments)
			idDoc.setCitizen(idCitizen, idPortraitPath);
		for (bankDoc in printedBankDocuments)
			bankDoc.setCitizen(citizen);
	}

	function sameCameras(a:Array<FlxCamera>, b:Array<FlxCamera>):Bool
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
			if (sameCameras(doc.cameras, updated))
				return;
			doc.cameras = updated;
			return;
		}

		// Top-layer docs must share coverCam with desk props or the cover pass draws
		// printer/shredder over them once the magnifier is open on the employer table.
		if (documentsAbove.members.indexOf(doc) >= 0)
		{
			if (coverCam != null)
				updated.push(coverCam);
			if (sameCameras(doc.cameras, updated))
				return;
			doc.cameras = updated;
			return;
		}

		var docIndex = documentsBelow.members.indexOf(doc);
		if (docIndex < 0)
		{
			if (sameCameras(doc.cameras, updated))
				return;
			doc.cameras = updated;
			return;
		}

		var magnifierIndex = documentsBelow.members.indexOf(magnifyingGlass);
		if (magnifierIndex < 0)
		{
			if (sameCameras(doc.cameras, updated))
				return;
			doc.cameras = updated;
			return;
		}

		var shouldZoom = DeskDocument.shouldUseLensMagnifier(doc, docIndex, magnifierIndex);
		var shouldCover = !shouldZoom && DeskDocument.usesMagnifierCoverLayer(doc);

		if (shouldZoom && lensCam != null)
			updated.push(lensCam);
		else if (shouldCover && coverCam != null)
			updated.push(coverCam);

		if (sameCameras(doc.cameras, updated))
			return;
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
		if (fontSize != calculatorDisplayLastFontSize)
		{
			calculatorDisplayLastFontSize = fontSize;
			calculatorDisplayText.setFormat(null, fontSize, FlxColor.fromRGB(76, 118, 84), "right");
			calculatorDisplayText.setBorderStyle(OUTLINE, FlxColor.fromRGB(12, 28, 14), 1);
		}

		var displayText = formatCalculatorForUi(calculatorDisplayValue);
		if (displayText != calculatorDisplayLastValue)
		{
			calculatorDisplayLastValue = displayText;
			calculatorDisplayText.text = displayText;
		}
		calculatorDisplayText.alpha = 0.82;
	}

	function initialClientIndex():Int
	{
		return 0;
	}

	function resetToBeginning():Void
	{
		CitizenRegistry.resetForNewGame();

		if (monitor.isShowing)
			monitor.hide();

		if (scanModeOverlay != null)
			scanModeOverlay.setActive(false);

		cancelActiveShredder();
		unlockPrinterScannedDocuments();
		printerStation.resetForNewDay();
		clearAllPrintedPapers();
		clearAllPrintedBankDocuments();
		removeLoanFolder();
		pendingLoanFolderSlide = false;
		pendingAutoPrintLoanForm = false;
		pendingLoanFolderSubmit = false;
		monitor.resetScreen();

		passport.prepareClientHandoff();
		passport.visible = false;
		if (documentsAbove.members.indexOf(passport) >= 0)
			documentsAbove.remove(passport, true);

		for (idDoc in idDocuments)
			stashDocumentOffDesk(idDoc);
		clearAllPrintedBankDocuments();
		for (jobContractDoc in jobContractDocuments)
			stashDocumentOffDesk(jobContractDoc);
		bookDocument.resetForNewDay();
		magnifyingGlass.placeOnClientTable();
		layoutClientTableDocuments();
		for (idDoc in idDocuments)
			moveDocumentToLayer(idDoc);
		for (bankDoc in printedBankDocuments)
			moveDocumentToLayer(bankDoc);
		for (jobContractDoc in jobContractDocuments)
			moveDocumentToLayer(jobContractDoc);
		moveDocumentToLayer(magnifyingGlass);

		clientImg.x = -clientImg.width;
		clientImg.y = clientFinalY;
		clientImg.color = FlxColor.BLACK;
		clientAnimPhase = 0;
		clientAnimTimer = 0;
		clientBobOffset = 0;
		clientEntranceDelayRemaining = 0;

		GameClock.reset();
		clientDialog.resetForNewDay();
		currentClientIndex = initialClientIndex();
		chefTutorial = null;
		clearTutorialUiRestrictions();
		pendingClientAdvance = false;
		pendingDocumentReturn = false;
		fraudConfronted = false;
		salaryUpdateAcknowledged = false;
		clearClientHandoutDocs();
		pendingLoanReview = null;
		applyClientScenario();

		printerPausedByMonitor = false;
		printerStation.setPaused(false);
	}

	function cancelActiveShredder():Void
	{
		var shreddingDoc = shredderStation.cancelActiveShred();
		if (shreddingDoc == null)
			return;

		var paper = Std.downcast(shreddingDoc, PrinterPaperDocument);
		if (paper != null)
		{
			printedPapers.remove(paper);
			paper.disposeCopyDocument();
			return;
		}

		var bankDoc = Std.downcast(shreddingDoc, BankDocument);
		if (bankDoc != null)
			removePrintedBankDocument(bankDoc);
	}

	function unlockPrinterScannedDocuments():Void
	{
		var scannedDoc = printerStation.getLastScannedDocument();
		if (scannedDoc != null)
			scannedDoc.unlockAfterPrinterScan();
		passport.unlockAfterPrinterScan();
		for (idDoc in idDocuments)
			idDoc.unlockAfterPrinterScan();
		for (bankDoc in printedBankDocuments)
			bankDoc.unlockAfterPrinterScan();
		bookDocument.unlockAfterPrinterScan();
		for (jobContractDoc in jobContractDocuments)
			jobContractDoc.unlockAfterPrinterScan();
	}

	function clearAllPrintedPapers():Void
	{
		var papers = printedPapers.copy();
		for (paper in papers)
		{
			printedPapers.remove(paper);
			paper.disposeCopyDocument();
		}
	}

	function showBeginningDaySequence():Void
	{
		gameplayMusic.stop();
		officeAmbientAudio.stop();
		screenFadeOverlay.reset();
		remove(beginningDayOverlay, false);
		add(beginningDayOverlay);
		beginningDayOverlay.onStartDayPressed = onBeginningDayStartPressed;
		beginningDayOverlay.show(resetToBeginning, startChefEntranceDelay);
		mainMenuOverlay.completeNewGameTransition();
	}

	function onBeginningDayStartPressed():Void
	{
		mainMenuOverlay.releaseMenuMusicForGameplay();
		gameplayMusic.start();
		officeAmbientAudio.start();
	}

	function startChefEntranceDelay():Void
	{
		beginClientEntrance();
	}

	function showMainMenuFromPause():Void
	{
		gameplayMusic.stop();
		officeAmbientAudio.stop();
		mainMenuOverlay.stopMenuMusicForReturnToMenu();
		screenFadeOverlay.reset();
		remove(mainMenuOverlay, false);
		add(mainMenuOverlay);
		mainMenuOverlay.show(true);
	}

	function fadeScreenToBlack(onComplete:Void->Void):Void
	{
		bringToFront(screenFadeOverlay);
		screenFadeOverlay.fadeToBlack(onComplete);
	}

	function bringToFront(child:flixel.FlxBasic):Void
	{
		remove(child, false);
		add(child);
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
		if (scanModeOverlay != null && scanModeOverlay.isActive)
		{
			calculatorToggleOverlay.alpha += (0 - calculatorToggleOverlay.alpha) * 0.35;
			return;
		}

		if (scanModeBlocksPoint(mousePos))
		{
			calculatorToggleOverlay.alpha += (0 - calculatorToggleOverlay.alpha) * 0.35;
			return;
		}

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
		overlay.color = 0xFF000000;
		overlay.x = calculatorObj.x + left * scale;
		overlay.y = calculatorObj.y + top * scale;
	}

	function resetCalculatorButtonOverlayVisuals():Void
	{
		for (i in 0...calculatorBtnOverlays.length)
		{
			var tween = calculatorBtnClickTweens[i];
			if (tween != null)
			{
				tween.cancel();
				calculatorBtnClickTweens[i] = null;
			}
			calculatorBtnOverlays[i].alpha = 0.0;
		}
	}

	function fadeCalculatorButtonOverlays(elapsed:Float):Void
	{
		for (i in 0...calculatorBtnOverlays.length)
		{
			var tween = calculatorBtnClickTweens[i];
			if (tween != null)
			{
				tween.cancel();
				calculatorBtnClickTweens[i] = null;
			}
			var overlay = calculatorBtnOverlays[i];
			overlay.alpha += (0 - overlay.alpha) * Math.min(1.0, elapsed * 12.0);
		}
	}

	function updateCalculatorButtonInput(mousePos:flixel.math.FlxPoint):Void
	{
		if (scanModeOverlay != null && scanModeOverlay.isActive)
		{
			for (overlay in calculatorBtnOverlays)
				overlay.alpha += (0 - overlay.alpha) * 0.35;
			return;
		}

		if (scanModeBlocksPoint(mousePos))
		{
			for (overlay in calculatorBtnOverlays)
				overlay.alpha += (0 - overlay.alpha) * 0.35;
			return;
		}

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
		if (scanModeOverlay != null && scanModeOverlay.isActive)
		{
			calculatorFocused = false;
			return;
		}
		if (scanModeBlocksPoint(mousePos))
		{
			calculatorFocused = false;
			return;
		}
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

		for (precision in [8, 7, 6, 5, 4, 3, 2, 1, 0])
		{
			var factor = Math.pow(10, precision);
			var rounded = Math.round(n * factor) / factor;
			var s = formatCalculatorNumber(rounded);
			if (s.length <= CALC_MAX_DISPLAY_CHARS)
				return s;
		}

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
				calculatorBtnClickTweens[index] = FlxTween.tween(overlay, {alpha: 0.0}, 0.1, {
					ease: FlxEase.quadInOut,
					onComplete: function(_)
					{
						calculatorBtnClickTweens[index] = null;
					}
				});
			}
		});
	}

	static inline var CLIENT_ENTRANCE_DELAY:Float = 5.0;
	static inline var CLIENT_WALK_DURATION:Float = 1.1;
	static inline var CLIENT_REVEAL_DURATION:Float = 0.5;
	static inline var CLIENT_HANDOFF_PAUSE:Float = 2.0;
	static inline var CLIENT_BOB_SPEED:Float = 6.0;
	static inline var CLIENT_BOB_AMPLITUDE:Float = 4.0;
	static inline var CLIENT_IMAGE_Y_OFFSET:Float = 6.0;

	function placeGuideBookOnEmployerTable():Void
	{
		bookDocument.placeOpenOnEmployerTableCenter();
		bookDocument.refreshOverlaysNow();
		magnifyingGlass.placeOnClientTable();
		moveDocumentToLayer(bookDocument);
		moveDocumentToLayer(magnifyingGlass);
	}

	function isClientEntranceBlocking():Bool
	{
		return clientEntranceDelayRemaining > 0 || clientAnimPhase != 0;
	}

	function beginClientEntrance():Void
	{
		clientAnimPhase = 1;
		clientAnimTimer = 0;
		clientBobOffset = 0;
	}

	function updateClientEntrance(elapsed:Float):Void
	{
		if (clientEntranceDelayRemaining > 0)
		{
			clientEntranceDelayRemaining -= elapsed;
			if (clientEntranceDelayRemaining <= 0)
			{
				clientEntranceDelayRemaining = 0;
				beginClientEntrance();
			}
			return;
		}

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
				clientDialog.startScenarioDialog();
			}
		}
		else if (clientAnimPhase == 3)
		{
			var t = Math.min(clientAnimTimer / CLIENT_REVEAL_DURATION, 1.0);
			var eased = FlxEase.sineIn(t);
			var c = 255 - Std.int(eased * 255);
			clientImg.color = FlxColor.fromRGB(c, c, c);

			if (t >= 1.0)
			{
				clientImg.color = FlxColor.BLACK;
				clientAnimPhase = 4;
				clientAnimTimer = 0;
			}
		}
		else if (clientAnimPhase == 4)
		{
			var t = Math.min(clientAnimTimer / CLIENT_WALK_DURATION, 1.0);
			var eased = FlxEase.quadIn(t);
			clientImg.x = clientFinalX - (clientFinalX + clientImg.width) * eased;

			clientBobOffset += elapsed * CLIENT_BOB_SPEED;
			clientImg.y = clientFinalY + Math.sin(clientBobOffset) * CLIENT_BOB_AMPLITUDE;

			if (t >= 1.0)
			{
				clientImg.x = -clientImg.width;
				clientImg.y = clientFinalY;
				clientImg.color = FlxColor.BLACK;
				clientAnimPhase = 5;
				clientAnimTimer = 0;
			}
		}
		else if (clientAnimPhase == 5)
		{
			if (clientAnimTimer >= CLIENT_HANDOFF_PAUSE)
				advanceToNextClientPreservingDesk();
		}
	}

	function startClientDeparture():Void
	{
		returnStrandedDocsFromClientWindow();
		clientAnimPhase = 3;
		clientAnimTimer = 0;
		clientBobOffset = 0;
	}

	function applyClientScenarioPreservingDesk():Void
	{
		if (CitizenRegistry.all.length == 0)
			return;

		currentScenario = ClientScenarios.get(currentClientIndex);
		var citizenIdx = currentScenario.citizenIndex;
		if (citizenIdx < 0 || citizenIdx >= CitizenRegistry.all.length)
			citizenIdx = 0;

		chefTutorial = null;
		resetScenarioVisitState();
		clientDialog.setScenario(currentScenario);
		bookDocument.setHidePassportBookQuestion(true);
		hidePassportOnDesk();
		applyCurrentCitizen(CitizenRegistry.all[citizenIdx]);
	}

	function advanceToNextClientPreservingDesk():Void
	{
		pendingClientAdvance = false;
		pendingDocumentReturn = false;
		fraudConfronted = false;
		salaryUpdateAcknowledged = false;
		clearClientHandoutDocs();
		pendingLoanReview = null;

		if (currentClientIndex >= ClientScenarios.LAST_PLAYABLE_CLIENT_INDEX)
		{
			showEndOfDemoPopup();
			return;
		}

		var leavingTutorial = currentScenario != null && currentScenario.isTutorial;
		currentClientIndex++;
		if (currentClientIndex >= ClientScenarios.count())
			currentClientIndex = ClientScenarios.count() - 1;

		clientDialog.resetForNewDay();
		applyClientScenarioPreservingDesk();
		clearTutorialUiRestrictions();
		if (leavingTutorial)
		{
			monitor.resetScreen();
			monitor.hide();
		}
		clientDialog.suppressAutoDocumentDelivery();

		clientImg.x = -clientImg.width;
		clientImg.y = clientFinalY;
		clientImg.color = FlxColor.BLACK;
		clientAnimPhase = 1;
		clientAnimTimer = 0;
		clientBobOffset = 0;
	}

	function showEndOfDemoPopup():Void
	{
		clientAnimPhase = 0;
		clientAnimTimer = 0;
		remove(endOfDemoPopup, false);
		add(endOfDemoPopup);
		bringToFront(endOfDemoPopup);
		endOfDemoPopup.show();
	}

	function handleNonPrintableDocumentDrop(doc:DeskDocument):Bool
	{
		return false;
	}

	function handleDocumentDroppedOnPrinter(doc:DeskDocument):Bool
	{
		if (Std.downcast(doc, LoanFolderDocument) != null)
			return false;

		if (Std.downcast(doc, BankDocument) != null)
			return false;

		if (Std.downcast(doc, JobContractDocument) != null)
			return false;

		if (Std.downcast(doc, BookDocument) != null)
			return false;

		if (Std.downcast(doc, PrinterPaperDocument) != null)
			return false;

		if (!printerStation.canAcceptDocument())
			return false;

		doc.lockForPrinterScan();
		printerStation.startScan(doc, function()
		{
			doc.unlockAfterPrinterScan();
			printerStation.resetFeedPaperGraphic();
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

		bringDocumentAboveShredder(paper);
		return shredderStation.startShred(paper, function()
		{
			removePrintedPaper(paper);
		});
	}

	function handleBankDocumentDroppedOnShredder(doc:DeskDocument):Bool
	{
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc == null)
			return false;
		if (!shredderStation.canAcceptDocument())
			return false;

		bringDocumentAboveShredder(bankDoc);
		var isChefClientDetails = bankDoc.getVariant() == BankDocumentVariant.ClientDetails
			&& bankDoc.getCitizenForCopy() != null
			&& CitizenRegistry.indexOf(bankDoc.getCitizenForCopy()) == ChefTutorial.CITIZEN_INDEX;
		return shredderStation.startShred(bankDoc, function()
		{
			if (isChefClientDetails && chefTutorial != null)
			{
				if (chefTutorial.tryCompleteLoanPrepShred())
					chefTutorial.beginLoanGuide();
				else
					chefTutorial.notifyDetailsShredded();
			}
			removePrintedBankDocument(bankDoc);
		});
	}

	function bringDocumentAboveShredder(doc:DeskDocument):Void
	{
		if (documentsAbove.members.indexOf(doc) < 0)
		{
			if (documentsBelow.members.indexOf(doc) >= 0)
				documentsBelow.remove(doc, true);
			documentsAbove.add(doc);
		}
	}

	function bringPaperAboveShredder(paper:PrinterPaperDocument):Void
	{
		bringDocumentAboveShredder(paper);
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
		trackChefDetailsPrint();
		printerStation.setFeedPaperGraphic(BankDocumentLayouts.DOCUMENT_PATH);
		printerStation.setTerminalPrintJob(monitor.getTerminalPrintJob());
		monitor.hide();
		printerStation.animatePaperFeed();
		return true;
	}

	function handleMonitorPrintChecklistRequest():Bool
	{
		if (!printerStation.canAcceptDocument())
			return false;
		printerStation.setFeedPaperGraphic(BankDocumentLayouts.DOCUMENT_PATH);
		printerStation.setTerminalPrintJob(TerminalPrintJob.LoanChecklist);
		monitor.hide();
		printerStation.animatePaperFeed();
		return true;
	}

	function handleMonitorClosed():Void
	{
		pendingLoanFolderSlide = monitor.consumePendingLoanFolderSlide();
		pendingAutoPrintLoanForm = monitor.consumePendingAutoPrintLoanForm();
		handleChefTutorialMonitorClosed();
		tryScenarioSalaryProgressDialogue();
	}

	function trackChefDetailsPrint():Void
	{
		if (chefTutorial == null)
			return;
		if (monitor.getTerminalPrintJob() != TerminalPrintJob.ClientDetails)
			return;
		var selected = monitor.getSelectedCitizen();
		if (selected == null)
			return;
		if (CitizenRegistry.indexOf(selected) != ChefTutorial.CITIZEN_INDEX)
			return;
		chefTutorial.markDetailsPrinted();
	}

	function handleChefTutorialMonitorClosed():Void
	{
		if (chefTutorial != null)
			chefTutorial.notifyMonitorClosed();
		tryChefTutorialProgressDialogue();
	}

	function buildChefTutorialContext():ChefTutorialContext
	{
		if (CitizenRegistry.all.length <= ChefTutorial.CITIZEN_INDEX)
		{
			return {
				salaryUpdated: false,
				detailsPrinted: chefTutorial != null && chefTutorial.detailsPrinted,
				paperOnPrinter: hasChefDetailsPaperOnPrinter(),
				printerBusy: printerStation.isPrintingPaper(),
				docOnDesk: hasChefClientDetailsOnDesk()
			};
		}

		var citizen = CitizenRegistry.all[ChefTutorial.CITIZEN_INDEX];
		if (chefTutorial != null)
			chefTutorial.refreshSalaryState(citizen);

		return {
			salaryUpdated: chefTutorial != null && chefTutorial.salaryUpdated,
			detailsPrinted: chefTutorial != null && chefTutorial.detailsPrinted,
			paperOnPrinter: hasChefDetailsPaperOnPrinter(),
			printerBusy: printerStation.isPrintingPaper(),
			docOnDesk: hasChefClientDetailsOnDesk()
		};
	}

	function hasChefDetailsPaperOnPrinter():Bool
	{
		return printerStation.hasPrintedPaperReady()
			&& printerStation.getTerminalPrintJob() == TerminalPrintJob.ClientDetails;
	}

	function hasChefClientDetailsOnDesk():Bool
	{
		return hasChefClientDetailsOnClientTable() || hasChefClientDetailsOnEmployerDesk();
	}

	function hasChefClientDetailsOnClientTable():Bool
	{
		return hasChefClientDetailsWhere(function(doc) return doc.isOnClientTable());
	}

	function hasChefClientDetailsOnEmployerDesk():Bool
	{
		return hasChefClientDetailsWhere(function(doc) return doc.isOpenOnEmployerTable());
	}

	function hasChefClientDetailsWhere(where:DeskDocument->Bool):Bool
	{
		for (doc in printedBankDocuments)
		{
			if (doc.getVariant() != BankDocumentVariant.ClientDetails)
				continue;
			var citizen = doc.getCitizenForCopy();
			if (citizen == null || CitizenRegistry.indexOf(citizen) != ChefTutorial.CITIZEN_INDEX)
				continue;
			if (where(doc))
				return true;
		}
		return false;
	}

	function isDraggingChefClientDetails():Bool
	{
		var drag = DeskDocument.currentDrag;
		if (drag == null)
			return false;
		var bankDoc = Std.downcast(drag, BankDocument);
		if (bankDoc == null)
			return false;
		if (bankDoc.getVariant() != BankDocumentVariant.ClientDetails)
			return false;
		var citizen = bankDoc.getCitizenForCopy();
		return citizen != null && CitizenRegistry.indexOf(citizen) == ChefTutorial.CITIZEN_INDEX;
	}

	function updateChefTutorialProgressTriggers():Void
	{
		if (chefTutorial == null || chefTutorial.scanVerified)
			return;

		var ctx = buildChefTutorialContext();
		var paperReady = ctx.paperOnPrinter;

		if (paperReady && !chefTutorialPaperWasReady)
			tryChefTutorialProgressDialogue();

		chefTutorialPaperWasReady = paperReady;
	}

	function tryChefTutorialProgressDialogue():Void
	{
		if (chefTutorial == null || chefTutorial.scanVerified)
			return;
		if (CitizenRegistry.all.length <= ChefTutorial.CITIZEN_INDEX)
			return;
		if (!clientDialog.canAcceptFollowUp())
			return;

		var steps = chefTutorial.tryGetProgressDialogue(buildChefTutorialContext());
		if (steps == null)
			return;

		clientDialog.startScriptedConversation(steps, true);
	}

	function getCalculatorNumericValue():Float
	{
		var n = parseCalculatorDisplay();
		return n != null ? n : 0;
	}

	function placeGuideBookForLoanTutorial():Void
	{
		bookDocument.slideOpenToEmployerTableCenter(function()
		{
			if (chefTutorial != null)
				chefTutorial.notifyBookSlideComplete();
		});
		if (chefTutorial != null)
		{
			bookDocument.setTutorialInteractionLock(
				chefTutorial.shouldLockLoanBook(),
				chefTutorial.getLoanBookTocLockIndex()
			);
		}
		moveDocumentToLayer(bookDocument);
		if (bookDocument.slideAboveTableDocs)
			bookDocument.bringToFrontInLayer();
		markDocumentLayersDirty();
	}

	function clearTutorialUiRestrictions():Void
	{
		if (deskTutorialCoach != null)
			deskTutorialCoach.hide();
		if (monitorTutorialCoach != null)
			monitorTutorialCoach.hide();
		if (bookDocument != null)
			bookDocument.setTutorialInteractionLock(false);
		if (monitor != null)
		{
			monitor.getScreenUi().tutorialClickFilter = null;
			monitor.getScreenUi().onTutorialClickBlocked = null;
			monitor.getScreenUi().setPrintButtonEnabled(true);
		}
	}

	function updateChefTutorialGuide(elapsed:Float):Void
	{
		if (chefTutorial == null)
		{
			clearTutorialUiRestrictions();
			return;
		}

		if (chefTutorial.consumePendingMonitorClose())
			monitor.hide();

		chefTutorial.updateBookSlideDelay(elapsed);

		if (chefTutorial.consumePendingPlaceBook())
			placeGuideBookForLoanTutorial();

		if (chefTutorial.isLoanGuideActive())
		{
			bookDocument.setTutorialInteractionLock(
				chefTutorial.shouldLockLoanBook(),
				chefTutorial.getLoanBookTocLockIndex()
			);
		}

		if (chefTutorial.isBookTutorialComplete())
		{
			clearTutorialUiRestrictions();
			return;
		}

		var computerHighlight:TutorialGuideRect = {
			x: computerScreenImg.x,
			y: computerScreenImg.y,
			w: computerScreenImg.width,
			h: computerScreenImg.height
		};

		if (chefTutorial.isDeskGuideActive())
		{
			chefTutorial.updateDeskGuide(deskTutorialCoach, buildBookTutorialContext());
			if (monitorTutorialCoach != null)
				monitorTutorialCoach.hide();
			monitor.getScreenUi().tutorialClickFilter = null;
			monitor.getScreenUi().onTutorialClickBlocked = null;
			return;
		}

		if (chefTutorial.isLoanGuideActive())
		{
			var calculatorHighlight:TutorialGuideRect = {
				x: calculatorObj.x,
				y: calculatorObj.y,
				w: calculatorObj.width,
				h: calculatorObj.height
			};
			chefTutorial.updateLoanGuide(
				monitor,
				deskTutorialCoach,
				monitorTutorialCoach,
				computerHighlight,
				calculatorHighlight,
				getCalculatorNumericValue(),
				loanFolder != null,
				buildBookTutorialContext()
			);
			var folderCtx = buildLoanFolderTutorialContext();
			chefTutorial.updateLoanFolderGuide(
				monitor,
				deskTutorialCoach,
				monitorTutorialCoach,
				monitor.getScreenUi(),
				folderCtx
			);
			var loanFilter = chefTutorial.getLoanTutorialClickFilter(monitor.getScreenUi());
			monitor.getScreenUi().tutorialClickFilter = loanFilter;
			monitor.getScreenUi().onTutorialClickBlocked = loanFilter != null
				? function(px:Float, py:Float)
				{
					chefTutorial.showLoanWrongClickCoach(monitorTutorialCoach, monitor, monitor.getScreenUi(), px, py);
				}
				: null;
			return;
		}

		if (!chefTutorial.isMonitorGuideActive())
		{
			deskTutorialCoach.hide();
			monitorTutorialCoach.hide();
			monitor.getScreenUi().tutorialClickFilter = null;
			return;
		}

		chefTutorial.updateGuide(monitor, deskTutorialCoach, monitorTutorialCoach, computerHighlight);

		if (chefTutorial.shouldFilterMonitorClicks(monitorTutorialCoach))
		{
			monitor.getScreenUi().tutorialClickFilter = function(px:Float, py:Float)
			{
				return chefTutorial.isMonitorClickAllowed(px, py, monitor.getScreenUi(), monitorTutorialCoach);
			};
		}
		else
			monitor.getScreenUi().tutorialClickFilter = null;
	}

	function buildLoanFolderTutorialContext():LoanFolderTutorialContext
	{
		var chefId = findIdDocument(Lorian);
		var chefIdOnTable = chefId != null && chefId.visible && chefId.isOnClientTable();
		var chefIdDragging = false;
		var drag = DeskDocument.currentDrag;
		if (drag != null && chefId != null && drag == chefId)
			chefIdDragging = true;

		var idCopyOnPrinter = printerStation.hasPrintedPaperReady()
			&& printerStation.getTerminalPrintJob() == TerminalPrintJob.None;
		var folderComplete = loanFolder != null
			&& LoanChecklistItems.isComplete(loanFolder.getStoredDocuments());
		var folderSpreadOpen = loanFolder != null && loanFolder.isSpreadOpen();

		return {
			folderVisible: loanFolder != null,
			folderSpreadOpen: folderSpreadOpen,
			chefIdOnClientTable: chefIdOnTable,
			chefIdDragging: chefIdDragging,
			chefIdOnPrinter: chefId != null && chefId.isLockedForPrinterScan(),
			printerCanAccept: printerStation.canAcceptDocument(),
			idCopyOnPrinter: idCopyOnPrinter,
			hasIdCopy: hasLoanChecklistItemAvailable(IdOrPassportCopy),
			hasChecklistCopy: hasLoanChecklistItemAvailable(LoanChecklist),
			hasFormCopy: hasLoanChecklistItemAvailable(LoanApplicationForm),
			folderComplete: folderComplete,
			folderApprovalRequested: chefTutorial != null && chefTutorial.folderApprovalRequested,
			computerHighlight: {
				x: computerScreenImg.x,
				y: computerScreenImg.y,
				w: computerScreenImg.width,
				h: computerScreenImg.height
			},
			printerHighlight: {
				x: printerStation.getBodyX(),
				y: printerStation.getBodyY(),
				w: printerStation.getBodyW(),
				h: printerStation.getBodyH()
			},
			folderArrowHighlight: loanFolder != null ? loanFolder.getArrowWorldBounds() : null,
			folderStorageHighlight: loanFolder != null ? loanFolder.getStorageWorldBounds() : null
		};
	}

	function hasLoanChecklistItemAvailable(item:LoanChecklistItem):Bool
	{
		if (loanFolder != null)
		{
			for (doc in loanFolder.getStoredDocuments())
			{
				if (LoanChecklistItems.matches(doc, item))
					return true;
			}
		}

		for (doc in printedBankDocuments)
		{
			if (doc.isStoredInLoanFolder())
				continue;
			if (LoanChecklistItems.matches(doc, item))
				return true;
		}

		for (paper in printedPapers)
		{
			if (paper.isStoredInLoanFolder())
				continue;
			if (LoanChecklistItems.matches(paper, item))
				return true;
		}

		return false;
	}

	function buildBookTutorialContext():BookTutorialContext
	{
		var scanActive = scanModeOverlay != null && scanModeOverlay.isActive;
		return {
			scanActive: scanActive,
			paperOnPrinter: hasChefDetailsPaperOnPrinter(),
			docOnDesk: hasChefClientDetailsOnDesk(),
			printedOnClientTable: hasChefClientDetailsOnClientTable(),
			printedOnEmployerDesk: hasChefClientDetailsOnEmployerDesk(),
			draggingPrintedRecord: isDraggingChefClientDetails(),
			printedHighlight: getChefPrintedRecordHighlight(),
			clientHighlight: {
				x: clientImg.x,
				y: clientImg.y,
				w: clientImg.width,
				h: clientImg.height
			},
			scanHintHighlight: scanModeOverlay != null ? scanModeOverlay.getHintBounds() : null,
			questionHighlight: bookDocument.isOnQuestionsSpread()
				? bookDocument.getTutorialHighlight("first_question")
				: bookDocument.getTutorialHighlight("questions_area"),
			hasPrintedSelection: scanModeOverlay != null && scanModeOverlay.hasClientDetailsSelection(),
			hasBookQuestionSelection: scanModeOverlay != null
				&& scanModeOverlay.hasSelectionWithTagPrefix(BookScanActions.BOOK_TAG_PREFIX),
			hasClientSelection: scanModeOverlay != null && scanModeOverlay.hasClientSelection(),
			actionReady: scanModeOverlay != null && scanModeOverlay.isActionReady(),
			bookOnEmployerTable: bookDocument.isOpenOnEmployerTable(),
			bookSlideComplete: bookDocument.isBookSlideComplete,
			bookSlideAnimating: bookDocument.isBookSlideAnimating,
			onQuestionsSpread: bookDocument.isOnQuestionsSpread(),
			bookFrameHighlight: bookDocument.getTutorialHighlight("book_frame"),
			tocQuestionsHighlight: bookDocument.getTutorialHighlight("toc_questions_to_ask"),
			shredderHighlight: {
				x: zones.shredderX,
				y: zones.shredderY,
				w: zones.shredderW,
				h: zones.shredderH
			}
		};
	}

	function getChefPrintedRecordHighlight():Null<TutorialGuideRect>
	{
		for (doc in printedBankDocuments)
		{
			if (doc.getVariant() != BankDocumentVariant.ClientDetails)
				continue;
			var citizen = doc.getCitizenForCopy();
			if (citizen == null || CitizenRegistry.indexOf(citizen) != ChefTutorial.CITIZEN_INDEX)
				continue;
			if (!doc.isOnClientOrEmployerTable())
				continue;
			return {x: doc.x, y: doc.y, w: doc.width, h: doc.height};
		}
		return null;
	}

	function refreshLoanChecklistCompletion():Void
	{
		if (loanFolder == null)
			return;

		var loanId = monitor.getLoanId();
		var idText = loanId != null ? loanId : "";
		var completed = LoanChecklistItems.completedFromStored(loanFolder.getStoredDocuments());

		for (doc in loanFolder.getStoredDocuments())
		{
			var bankDoc = Std.downcast(doc, BankDocument);
			if (bankDoc != null && bankDoc.getVariant() == BankDocumentVariant.LoanChecklist)
			{
				bankDoc.setLoanId(idText);
				bankDoc.refreshCompletion(completed);
			}
		}

		for (bankDoc in printedBankDocuments)
		{
			if (bankDoc.getVariant() != BankDocumentVariant.LoanChecklist)
				continue;
			if (bankDoc.isStoredInLoanFolder())
				continue;
			bankDoc.setLoanId(idText);
			bankDoc.refreshCompletion(completed);
		}
	}

	function handleMonitorSubmitForApprovalRequest():Bool
	{
		if (loanFolder == null || loanFolderSubmitting)
			return false;
		if (!loanFolder.hasStoredDocuments())
			return false;
		if (!LoanChecklistItems.isComplete(loanFolder.getStoredDocuments()))
			return false;

		if (chefTutorial != null)
			chefTutorial.notifyFolderApprovalRequested();

		pendingLoanFolderSubmit = true;
		monitor.hide();
		return true;
	}

	function handleLoanFolderSubmit():Void
	{
		if (loanFolder == null || loanFolderSubmitting)
			return;
		if (!LoanChecklistItems.isComplete(loanFolder.getStoredDocuments()))
			return;

		loanFolderSubmitting = true;

		var folder = loanFolder;
		folder.submitAndSlideOut(0.55, function()
		{
			finishLoanFolderSubmit(folder);
		});
	}

	function finishLoanFolderSubmit(folder:LoanFolderDocument):Void
	{
		for (doc in folder.getStoredDocuments())
		{
			var bankDoc = Std.downcast(doc, BankDocument);
			if (bankDoc != null)
				printedBankDocuments.remove(bankDoc);
			var paper = Std.downcast(doc, PrinterPaperDocument);
			if (paper != null)
				printedPapers.remove(paper);
		}

		if (documentsAbove.members.indexOf(folder) >= 0)
			documentsAbove.remove(folder, false);
		else if (documentsBelow.members.indexOf(folder) >= 0)
			documentsBelow.remove(folder, false);

		folder.destroyWithStoredDocuments();

		if (LoanFolderDocument.activeFolder == folder)
			LoanFolderDocument.activeFolder = null;
		if (loanFolder == folder)
			loanFolder = null;

		loanFolderSubmitting = false;

		if (chefTutorial != null && chefTutorial.shouldStartFolderFarewell())
		{
			chefTutorial.onFolderTutorialSubmitComplete();
			if (clientDialog.canAcceptFollowUp())
				clientDialog.startScriptedConversation(ClientScenarios.chefTutorialFolderCompletionSteps(), true);
			return;
		}

		handleLoanReviewAfterSubmit();
	}

	function startLoanApplicationReview():Void
	{
		if (CitizenRegistry.all.length == 0 || currentScenario == null)
			return;

		var citizenIdx = currentScenario.citizenIndex;
		if (citizenIdx < 0 || citizenIdx >= CitizenRegistry.all.length)
			return;

		var citizen = CitizenRegistry.all[citizenIdx];
		var data = monitor.getLoanApplicationData();
		var messages = LoanApplicationValidator.clientFacingErrors(citizen, currentScenario, data);
		clientDialog.startApplicationReview(messages);
	}

	function handleLoanReviewAfterSubmit():Void
	{
		if (CitizenRegistry.all.length == 0 || currentScenario == null)
			return;

		if (currentScenario.identityFraud)
		{
			var loanId = monitor.getLoanId();
			if (fraudConfronted)
				clientDialog.startFollowUpDialog(["Forget the loan — just give me my documents back."]);
			else
				clientDialog.startFollowUpDialog(["Can we skip the paperwork? I'm in a hurry..."]);
			return;
		}

		var citizenIdx = currentScenario.citizenIndex;
		if (citizenIdx < 0 || citizenIdx >= CitizenRegistry.all.length)
			return;

		var citizen = CitizenRegistry.all[citizenIdx];
		var loanId = monitor.getLoanId();
		var data = monitor.getLoanApplicationData();
		var review = LoanApplicationValidator.review(citizen, currentScenario, data, loanId);
		pendingLoanReview = review;
		spawnLoanDecisionDocument(review, loanId);

		if (review.approved)
		{
			pendingClientAdvance = true;
			if (currentScenario != null && currentScenario.requiresDocumentReturn)
				pendingDocumentReturn = true;
			clientDialog.startThanksDialog();
		}
	}

	function spawnLoanDecisionDocument(review:LoanReviewResult, ?loanId:String):Void
	{
		var doc = new BankDocument(zones, documentsAbove, BankDocumentVariant.LoanDecision);
		if (CitizenRegistry.all.length > 0)
		{
			var citizenIdx = currentScenario != null ? currentScenario.citizenIndex : 0;
			if (citizenIdx >= 0 && citizenIdx < CitizenRegistry.all.length)
				doc.setCitizen(CitizenRegistry.all[citizenIdx]);
		}
		doc.setDecisionResult(review, loanId);
		doc.onDroppedOnPrinter = handleNonPrintableDocumentDrop;
		doc.onDroppedOnShredder = handleBankDocumentDroppedOnShredder;

		documentsAbove.add(doc);
		printedBankDocuments.push(doc);
		moveDocumentToLayer(doc);
		doc.slideOpenFromRightToEmployerCenter();
	}

	function configurePrintedBankDocument(doc:BankDocument, variant:BankDocumentVariant):Void
	{
		var loanId = monitor.getLoanId();
		var idText = loanId != null ? loanId : "";
		if (variant == BankDocumentVariant.ClientDetails)
		{
			var selected = monitor.getSelectedCitizen();
			if (selected != null)
				doc.setCitizen(selected);
		}
		else if (CitizenRegistry.all.length > 0)
		{
			var citizenIdx = currentScenario != null ? currentScenario.citizenIndex : 0;
			if (citizenIdx >= 0 && citizenIdx < CitizenRegistry.all.length)
				doc.setCitizen(CitizenRegistry.all[citizenIdx]);
		}

		switch (variant)
		{
			case BankDocumentVariant.LoanChecklist:
				var completed:Array<LoanChecklistItem> = loanFolder != null
					? LoanChecklistItems.completedFromStored(loanFolder.getStoredDocuments())
					: [];
				doc.setLoanId(idText);
				doc.refreshCompletion(completed);
			case BankDocumentVariant.ApplicationForm:
				doc.setApplicationData(idText, monitor.getLoanApplicationData());
			case BankDocumentVariant.ClientDetails:
				var selected = monitor.getSelectedCitizen();
				if (selected != null)
					doc.setClientDetailsData(selected);
			case BankDocumentVariant.LoanDecision:
		}
	}

	function spawnPrintedBankDocument(variant:BankDocumentVariant, centerX:Float, centerY:Float, ?dragMouseX:Float, ?dragMouseY:Float):Void
	{
		var doc = new BankDocument(zones, documentsAbove, variant);
		configurePrintedBankDocument(doc, variant);
		doc.onDroppedOnPrinter = handleNonPrintableDocumentDrop;
		doc.onDroppedOnShredder = handleBankDocumentDroppedOnShredder;
		doc.prepareClientHandoff();
		doc.setPosition(centerX - doc.width * 0.5, centerY - doc.height * 0.5);
		documentsAbove.add(doc);
		printedBankDocuments.push(doc);
		moveDocumentToLayer(doc);

		if (dragMouseX != null && dragMouseY != null)
			doc.startDragFromExternal(dragMouseX, dragMouseY);

		printerStation.notifyPrintedPaperPickedUp();
	}

	function removePrintedBankDocument(doc:BankDocument):Void
	{
		printedBankDocuments.remove(doc);
		if (documentsAbove.members.indexOf(doc) >= 0)
			documentsAbove.remove(doc, true);
		else if (documentsBelow.members.indexOf(doc) >= 0)
			documentsBelow.remove(doc, true);
		doc.destroy();
	}

	function clearAllPrintedBankDocuments():Void
	{
		var docs = printedBankDocuments.copy();
		for (doc in docs)
			removePrintedBankDocument(doc);
	}

	function handleMonitorSlideOutComplete():Void
	{
		if (pendingLoanFolderSlide)
		{
			pendingLoanFolderSlide = false;
			spawnLoanFolderSlide();
		}

		if (pendingAutoPrintLoanForm)
		{
			pendingAutoPrintLoanForm = false;
			tryAutoPrintLoanApplicationForm();
		}

		if (pendingLoanFolderSubmit)
		{
			pendingLoanFolderSubmit = false;
			handleLoanFolderSubmit();
		}
	}

	function tryAutoPrintLoanApplicationForm():Void
	{
		if (!printerStation.canAcceptDocument())
			return;

		printerStation.setFeedPaperGraphic(BankDocumentLayouts.DOCUMENT_PATH);
		printerStation.setTerminalPrintJob(TerminalPrintJob.LoanApplicationForm);
		printerStation.animatePaperFeed();
	}

	function spawnLoanFolderSlide():Void
	{
		if (monitor.isActive())
			return;

		if (loanFolder != null)
			return;

		loanFolder = new LoanFolderDocument(zones, documentsAbove);
		LoanFolderDocument.activeFolder = loanFolder;
		var lensCam = magnifyingGlass != null ? magnifyingGlass.lensCam : null;
		loanFolder.cameras = [FlxG.camera];
		if (lensCam != null)
			loanFolder.cameras.push(lensCam);

		documentsAbove.add(loanFolder);
		loanFolder.onStoredDocumentsChanged = refreshLoanChecklistCompletion;
		loanFolder.tweenSlideInFromEdge(0.55);
		tryChefTutorialFolderIntroDialogue();
	}

	function tryChefTutorialFolderIntroDialogue():Void
	{
		if (chefTutorial == null || !chefTutorial.shouldTryFolderIntroDialog())
			return;
		if (!clientDialog.canAcceptFollowUp())
			return;

		chefTutorial.consumeFolderIntroDialog();
		clientDialog.startScriptedConversation(ClientScenarios.chefTutorialFolderIntroSteps(), true);
	}

	function deliverChefTutorialIdHandoff():Void
	{
		if (chefTutorial == null || !chefTutorial.needsChefIdHandoff())
			return;

		spawnClientIdDocument(Lorian, true);
		registerClientHandout(findIdDocument(Lorian));
		chefTutorial.markChefIdHandedOff();
	}

	function removeLoanFolder():Void
	{
		if (loanFolder == null)
			return;

		if (documentsAbove.members.indexOf(loanFolder) >= 0)
			documentsAbove.remove(loanFolder, true);
		else if (documentsBelow.members.indexOf(loanFolder) >= 0)
			documentsBelow.remove(loanFolder, true);
		loanFolder.destroy();
		if (LoanFolderDocument.activeFolder == loanFolder)
			LoanFolderDocument.activeFolder = null;
		loanFolder = null;
	}

	function tryPickupPrintedPaper(p:flixel.math.FlxPoint):Void
	{
		if (!printerStation.tryPickupPrintedPaper(p.x, p.y))
			return;

		var centerX = printerStation.getPrintedPaperCenterX();
		var centerY = printerStation.getPrintedPaperCenterY();
		switch (printerStation.consumeTerminalPrintJob())
		{
			case TerminalPrintJob.LoanChecklist:
				spawnPrintedBankDocument(BankDocumentVariant.LoanChecklist, centerX, centerY, p.x, p.y);
			case TerminalPrintJob.LoanApplicationForm:
				spawnPrintedBankDocument(BankDocumentVariant.ApplicationForm, centerX, centerY, p.x, p.y);
			case TerminalPrintJob.ClientDetails:
				spawnPrintedBankDocument(BankDocumentVariant.ClientDetails, centerX, centerY, p.x, p.y);
			default:
				spawnPrintedPaper(centerX, centerY, p.x, p.y);
		}
	}

	function spawnPrintedPaper(centerX:Float, centerY:Float, ?dragMouseX:Float, ?dragMouseY:Float):Void
	{
		var scannedFrom = printerStation.consumePrintSource();
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

	function hidePassportOnDesk():Void
	{
		passport.visible = false;
		if (documentsAbove.members.indexOf(passport) >= 0)
			documentsAbove.remove(passport, true);
	}

	function spawnPassport():Void
	{
	}

	function isComputerZoneClick():Bool
	{
		return isComputerZoneAt(FlxG.mouse.getViewPosition());
	}

	function isComputerZoneAt(p:flixel.math.FlxPoint):Bool
	{
		return p.x >= 0 && p.x < zones.leftW && p.y >= zones.computerY && p.y < zones.computerY + zones.computerH;
	}

	function scanModeBlocksPoint(p:flixel.math.FlxPoint):Bool
	{
		return scanModeOverlay != null && scanModeOverlay.isActive && !isScanModePointAllowed(p);
	}

	function isScanModePointAllowed(p:flixel.math.FlxPoint):Bool
	{
		if (scanModeOverlay == null || !scanModeOverlay.isActive)
			return true;

		if (chefTutorial != null && (chefTutorial.isBookGuideActive() || chefTutorial.isDeskGuideActive()))
			return chefTutorial.isScanPointAllowed(p.x, p.y, deskTutorialCoach, scanModeOverlay);

		if (scanModeOverlay.isPointOnActionableMessage(p))
			return true;

		if (p.x >= 0 && p.x < zones.leftW && p.y >= 0 && p.y < zones.clientH)
			return true;

		if (p.x >= 0 && p.x < zones.leftW && p.y >= zones.clientTableY && p.y < zones.clientTableY + zones.clientTableH)
			return true;

		if (isComputerZoneAt(p))
			return true;

		if (pointInRect(p, zones.printerX, zones.printerY, zones.printerW, zones.printerH))
			return true;

		if (pointInRect(p, zones.shredderX, zones.shredderY, zones.shredderW, zones.shredderH))
			return true;

		if (isPointOnCalculator(p))
			return true;

		var doc = frontmostDocumentAtPoint(p);
		if (doc != null && doc.isOnClientOrEmployerTable())
			return true;

		return false;
	}

	function pointInRect(p:flixel.math.FlxPoint, x:Float, y:Float, w:Float, h:Float):Bool
	{
		return p.x >= x && p.x < x + w && p.y >= y && p.y < y + h;
	}

	function updateScanModeUi(p:flixel.math.FlxPoint, elapsed:Float):Void
	{
		if (scanModeOverlay == null)
			return;

		scanModeOverlay.syncScreenSize();
		scanModeOverlay.setClientArea(zones.leftW, zones.clientH);

		if (beginningDayOverlay.isShowing || mainMenuOverlay.isShowing || monitor.isActive() || isClientEntranceBlocking()
			|| shiftPauseOverlay.isActive())
		{
			scanModeOverlay.setActive(false);
			scanModeOverlay.setHintVisible(false);
			scanClickPending = false;
			return;
		}

		var showHint = clientDialog.shouldShowScanHint();
		scanModeOverlay.setHintVisible(false);
		if (scanModeOverlay.isActive && !showHint)
			scanModeOverlay.setActive(false);

		handleScanDoubleClick(p, elapsed, showHint);

		if (showHint || scanModeOverlay.isActive)
		{
			remove(scanModeOverlay, false);
			add(scanModeOverlay);
			if (scanModeOverlay.isActive && showHint)
			{
				remove(clientDialog, false);
				add(clientDialog);
			}
		}

		if (FlxG.keys.justPressed.SPACE && (scanModeOverlay.isActive || showHint))
		{
			if (scanModeOverlay.isActive)
				scanModeOverlay.setActive(false);
			else
				enterScanMode();
		}

		if (scanModeOverlay.isActive && scanModeOverlay.handleActionClick(p))
			scanSelectionConsumed = true;
		else if (scanModeOverlay.isActive && FlxG.keys.justPressed.ENTER && scanModeOverlay.tryConfirmAction())
			scanSelectionConsumed = true;
		else if (scanModeOverlay.isActive && scanModeOverlay.handleScanSelection(p, resolveScanTargetAt))
			scanSelectionConsumed = true;
	}

	function handleScanDoubleClick(p:flixel.math.FlxPoint, elapsed:Float, showHint:Bool):Void
	{
		if (scanClickPending)
		{
			scanClickTimer += elapsed;
			if (scanClickTimer > SCAN_DOUBLE_CLICK_TIME)
				scanClickPending = false;
		}

		if (!showHint || scanModeOverlay.isActive)
		{
			scanClickPending = false;
			return;
		}

		if (MonitorOverlay.blocksWorldInput() || BeginningDayOverlay.blocksWorldInput() || MainMenuOverlay.blocksWorldInput()
			|| ShiftPauseOverlay.blocksWorldInput() || EndOfDemoPopup.blocksWorldInput() || ScreenFadeOverlay.blocksWorldInput())
			return;

		if (clientDialog.isPointOnChoiceControls(p))
			return;

		if (!FlxG.mouse.justPressed)
			return;

		var bounds = resolveScanTargetAt(p);
		var isDouble = scanClickPending
			&& scanClickTimer <= SCAN_DOUBLE_CLICK_TIME
			&& Math.abs(p.x - scanClickX) <= SCAN_DOUBLE_CLICK_DIST
			&& Math.abs(p.y - scanClickY) <= SCAN_DOUBLE_CLICK_DIST;

		if (isDouble)
		{
			scanClickPending = false;
			if (bounds == null)
				return;

			enterScanMode();
			scanModeOverlay.showSelection(bounds);
			ScanModeOverlay.suppressDocumentPress = true;
			scanSelectionConsumed = true;
			return;
		}

		if (bounds != null)
		{
			scanClickPending = true;
			scanClickTimer = 0;
			scanClickX = p.x;
			scanClickY = p.y;
		}
		else
			scanClickPending = false;
	}

	function resolveScanTargetAt(p:flixel.math.FlxPoint):Null<ScanBounds>
	{
		var doc = frontmostDocumentAtPoint(p);
		if (doc != null && doc.isOnClientOrEmployerTable())
		{
			var docBounds = doc.resolveScanBoundsAt(p);
			if (docBounds != null)
				return docBounds;
		}

		if (isPointOnCalculator(p))
			return spriteScanBounds(calculatorObj);

		if (pointInRect(p, zones.printerX, zones.printerY, zones.printerW, zones.printerH))
			return {
				x: zones.printerX,
				y: zones.printerY,
				w: zones.printerW,
				h: zones.printerH
			};

		if (pointInRect(p, zones.shredderX, zones.shredderY, zones.shredderW, zones.shredderH))
			return {
				x: zones.shredderX,
				y: zones.shredderY,
				w: zones.shredderW,
				h: zones.shredderH
			};

		if (clientImg.visible && clientImg.overlapsPoint(p))
			return taggedSpriteScanBounds(clientImg, BookScanActions.CLIENT_TAG);

		if (p.x >= 0 && p.x < zones.leftW && p.y >= zones.clientTableY && p.y < zones.clientTableY + zones.clientTableH)
			return {
				x: 0,
				y: zones.clientTableY,
				w: zones.leftW,
				h: zones.clientTableH
			};

		if (isComputerZoneAt(p))
			return {
				x: 0,
				y: zones.computerY,
				w: zones.leftW,
				h: zones.computerH
			};

		if (p.x >= 0 && p.x < zones.leftW && p.y >= 0 && p.y < zones.clientH)
			return {
				x: 0,
				y: 0,
				w: zones.leftW,
				h: zones.clientH
			};

		return null;
	}

	function spriteScanBounds(sprite:FlxSprite):ScanBounds
	{
		return taggedSpriteScanBounds(sprite, null);
	}

	function taggedSpriteScanBounds(sprite:FlxSprite, tag:Null<String>):ScanBounds
	{
		return {
			x: sprite.x,
			y: sprite.y,
			w: sprite.width,
			h: sprite.height,
			tag: tag
		};
	}

	function enterScanMode():Void
	{
		cancelActiveDocumentDrags();
		scanModeOverlay.setActive(true);
		remove(scanModeOverlay, false);
		add(scanModeOverlay);
	}

	function cancelActiveDocumentDrags():Void
	{
		cancelDragsInGroup(documentsAbove);
		cancelDragsInGroup(documentsBelow);
	}

	function cancelDragsInGroup(group:FlxGroup):Void
	{
		for (member in group.members)
		{
			if (member == null)
				continue;
			var doc = Std.downcast(member, DeskDocument);
			if (doc != null)
				doc.cancelDrag();
		}
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

	function canStartDocumentDrag(candidate:DeskDocument, p:flixel.math.FlxPoint):Bool
	{
		if (chefTutorial != null && chefTutorial.blocksAnyDeskDrag())
			return false;
		if (candidate != magnifyingGlass && magnifierHitsPoint(p))
			return false;
		if (isPointOnCalculator(p))
			return false;
		if (candidate.isStoredInLoanFolder())
			return false;

		if (documentsBelow.members.indexOf(candidate) >= 0 && isAboveDrawLayerBlockingPoint(p))
			return false;

		var folder = Std.downcast(candidate, LoanFolderDocument);
		if (folder != null && !folder.canBeginDragAt(p))
			return false;

		var book = Std.downcast(candidate, BookDocument);
		if (book != null && !book.canBeginDragAt(p))
			return false;

		return isTopmostDocumentAtPoint(candidate, p);
	}

	function magnifierHitsPoint(p:flixel.math.FlxPoint):Bool
	{
		if (magnifyingGlass == null || !magnifyingGlass.visible || !magnifyingGlass.hitsPoint(p))
			return false;
		return frontmostDocumentAtPoint(p) == magnifyingGlass;
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
			if (doc == null || !doc.visible || doc.isStoredInLoanFolder() || !doc.hitsPoint(p))
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
