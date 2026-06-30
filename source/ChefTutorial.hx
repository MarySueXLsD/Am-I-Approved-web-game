package;

import StringTools;

class ChefTutorial
{
	public static inline var CITIZEN_INDEX = 0;
	public static inline var TARGET_SALARY = 42000;
	public static inline var MANAGER_FIRST_NAME = "Henri";
	public static inline var MANAGER_LAST_NAME = "Moreau";
	public static inline var MANAGER_NATIONAL_ID = "AAA3493A";
	public static inline var LOAN_TARGET_PRODUCT = "personal";
	public static inline var LOAN_TARGET_AMOUNT = 25500;
	public static inline var LOAN_TERM_TRIAL = 10;
	public static inline var LOAN_TERM_MID = 20;
	public static inline var LOAN_TERM_FINAL = 24;
	public static inline var LOAN_MONTHLY_SALARY = 3500;
	public static inline var LOAN_COMFORTABLE_PAYMENT = 1200;
	public static inline var LOAN_COMFORTABLE_TOLERANCE = 125;
	public static inline var LOAN_SPEND_HOUSING = 700;
	public static inline var LOAN_SPEND_LIVING = 400;
	public static inline var LOAN_SPEND_OTHER = 150;

	static inline var GUIDE_NONE = 0;
	static inline var GUIDE_DESK_OPEN_COMPUTER = 1;
	static inline var GUIDE_MONITOR_WELCOME = 2;
	static inline var GUIDE_MONITOR_MAIN_MENU = 3;
	static inline var GUIDE_MONITOR_DATABASE = 4;
	static inline var GUIDE_MONITOR_SEARCH = 5;
	static inline var GUIDE_MONITOR_SELECT = 6;
	static inline var GUIDE_MONITOR_SALARY = 7;
	static inline var GUIDE_MONITOR_PRINT = 8;
	static inline var GUIDE_DESK_DRAG = 9;
	static inline var GUIDE_SCAN_PRINTED = 10;
	static inline var GUIDE_LOAN_OPEN_COMPUTER = 11;
	static inline var GUIDE_LOAN_MAIN_MENU = 12;
	static inline var GUIDE_LOAN_NEW_APP = 13;
	static inline var GUIDE_LOAN_NATIONAL_ID = 14;
	static inline var GUIDE_LOAN_PRODUCT = 15;
	static inline var GUIDE_LOAN_AMOUNT = 16;
	static inline var GUIDE_LOAN_TERM = 17;
	static inline var GUIDE_LOAN_CLOSE_CALC = 18;
	static inline var GUIDE_LOAN_CALCULATOR = 19;
	static inline var GUIDE_LOAN_SALARY = 20;
	static inline var GUIDE_LOAN_PREP_SECURITY = 21;
	static inline var GUIDE_LOAN_BOOK_SLIDE = 22;
	static inline var GUIDE_LOAN_BOOK_TOC = 23;
	static inline var GUIDE_LOAN_BOOK_SCAN = 24;
	static inline var GUIDE_LOAN_SECURITY_DESK = 25;
	static inline var GUIDE_LOAN_SECURITY = 26;
	static inline var GUIDE_LOAN_PREP_EXPENSES = 27;
	static inline var GUIDE_LOAN_ASK_EXPENSES = 28;
	static inline var GUIDE_LOAN_EXPENSES_DESK = 29;
	static inline var GUIDE_LOAN_EXPENSES = 30;
	static inline var GUIDE_LOAN_REVIEW_VALUES = 31;
	static inline var GUIDE_LOAN_CHECK_RATE = 32;
	static inline var GUIDE_LOAN_PREP_COMFORTABLE = 33;
	static inline var GUIDE_LOAN_ASK_COMFORTABLE = 34;
	static inline var GUIDE_LOAN_TERM_DESK = 35;
	static inline var GUIDE_LOAN_TERM_FINAL = 36;
	static inline var GUIDE_LOAN_SUBMIT = 37;
	static inline var GUIDE_LOAN_FOLDER_INTRO = 38;
	static inline var GUIDE_LOAN_FOLDER = 39;
	static inline var GUIDE_BOOK_DONE = 40;

	public var salaryUpdated(default, null) = false;
	public var detailsPrinted(default, null) = false;
	public var scanVerified(default, null) = false;
	public var scanHintUnlocked = false;
	public var shouldAdvanceOnVisitComplete = false;
	public var awaitingIdReturn = false;
	public static var pendingBookScanFarewell = false;

	public var guidePhase(default, null) = GUIDE_NONE;
	public var guideMonitorActive(default, null) = false;
	var guideShownForPhase = -1;
	var openingMonitor = false;
	var monitorWelcomeSeen = false;
	var resumeMonitorGuidePhase = GUIDE_MONITOR_MAIN_MENU;
	var bookSlideStarted = false;
	var printedScanDone = false;
	var pendingMonitorClose = false;
	var pendingPlaceBook = false;
	var loanWelcomePending = false;
	var scanHintSubStep = 0;
	var scanModeWasActive = false;
	var loanSalaryCalcReady = false;
	var loanSalaryCheckpoint = false;
	var loanQuestionResumePending = false;
	var loanQuestionResumePhase = GUIDE_LOAN_OPEN_COMPUTER;
	var salaryRejectedMessage:Null<String> = null;
	var unneededFieldEditMessage:Null<String> = null;
	var wrongClientActive = false;
	var detailsShreddedRecovery = false;
	var bookSlideDelayRemaining = 0.0;
	var folderIntroDialogPending = false;
	var folderIdHandedOff = false;
	public var folderApprovalRequested(default, null) = false;
	var lastFolderGuideContext:Null<LoanFolderTutorialContext> = null;
	var loanRateGuideSubStep = 0;
	var loanPrepShredDone = false;
	var loanWalkthroughReady = false;

	public function new() {}

	public static function managerDisplayName():String
	{
		return '$MANAGER_FIRST_NAME $MANAGER_LAST_NAME';
	}

	public static function managerSearchHint():String
	{
		return MANAGER_LAST_NAME;
	}

	public function shouldBeginGuidedTraining():Bool
	{
		return guidePhase == GUIDE_NONE;
	}

	public function beginGuidedTraining():Void
	{
		guidePhase = GUIDE_DESK_OPEN_COMPUTER;
		guideShownForPhase = -1;
	}

	public function isGuideActive():Bool
	{
		return isMonitorGuideActive() || isDeskGuideActive() || isLoanGuideActive() || isBookGuideActive();
	}

	public function isMonitorGuideActive():Bool
	{
		return guidePhase >= GUIDE_DESK_OPEN_COMPUTER && guidePhase <= GUIDE_MONITOR_PRINT;
	}

	public function isDeskGuideActive():Bool
	{
		return guidePhase == GUIDE_DESK_DRAG || guidePhase == GUIDE_SCAN_PRINTED;
	}

	public function isLoanGuideActive():Bool
	{
		return guidePhase >= GUIDE_LOAN_OPEN_COMPUTER && guidePhase <= GUIDE_LOAN_FOLDER;
	}

	public function isBookGuideActive():Bool
	{
		return false;
	}

	public function shouldAllowScanHint():Bool
	{
		if (guidePhase == GUIDE_SCAN_PRINTED && scanHintUnlocked)
			return true;
		if (isLoanScanPhase())
			return true;
		if (isBookTutorialComplete())
			return true;
		return false;
	}

	function isLoanScanPhase():Bool
	{
		return guidePhase == GUIDE_LOAN_BOOK_SCAN
			|| guidePhase == GUIDE_LOAN_SECURITY_DESK
			|| guidePhase == GUIDE_LOAN_SECURITY
			|| guidePhase == GUIDE_LOAN_ASK_EXPENSES
			|| guidePhase == GUIDE_LOAN_EXPENSES_DESK
			|| guidePhase == GUIDE_LOAN_ASK_COMFORTABLE;
	}

	function isLoanAskQuestionPhase():Bool
	{
		return guidePhase == GUIDE_LOAN_ASK_EXPENSES || guidePhase == GUIDE_LOAN_ASK_COMFORTABLE;
	}

	function isLoanMonitorFormPhase():Bool
	{
		return guidePhase >= GUIDE_LOAN_NATIONAL_ID && guidePhase <= GUIDE_LOAN_SUBMIT;
	}

	function isLoanDeskOnlyPhase():Bool
	{
		return guidePhase == GUIDE_LOAN_OPEN_COMPUTER
			|| guidePhase == GUIDE_LOAN_CLOSE_CALC
			|| guidePhase == GUIDE_LOAN_CALCULATOR
			|| guidePhase == GUIDE_LOAN_PREP_SECURITY
			|| guidePhase == GUIDE_LOAN_BOOK_SLIDE
			|| guidePhase == GUIDE_LOAN_BOOK_TOC
			|| guidePhase == GUIDE_LOAN_BOOK_SCAN
			|| guidePhase == GUIDE_LOAN_SECURITY_DESK
			|| guidePhase == GUIDE_LOAN_PREP_EXPENSES
			|| guidePhase == GUIDE_LOAN_ASK_EXPENSES
			|| guidePhase == GUIDE_LOAN_EXPENSES_DESK
			|| guidePhase == GUIDE_LOAN_PREP_COMFORTABLE
			|| guidePhase == GUIDE_LOAN_ASK_COMFORTABLE
			|| guidePhase == GUIDE_LOAN_TERM_DESK
			|| guidePhase == GUIDE_LOAN_FOLDER_INTRO
			|| guidePhase == GUIDE_LOAN_FOLDER;
	}

	public function shouldMarkLoanWalkthroughReady():Bool
	{
		return guidePhase == GUIDE_SCAN_PRINTED && printedScanDone && !loanWalkthroughReady;
	}

	public function markLoanWalkthroughReady():Void
	{
		if (!shouldMarkLoanWalkthroughReady())
			return;

		loanWalkthroughReady = true;
		guideShownForPhase = -1;
		if (loanPrepShredDone)
			beginLoanGuide();
	}

	public function shouldBeginLoanGuide():Bool
	{
		return guidePhase == GUIDE_SCAN_PRINTED && printedScanDone && loanWalkthroughReady && loanPrepShredDone;
	}

	public function tryCompleteLoanPrepShred():Bool
	{
		if (guidePhase != GUIDE_SCAN_PRINTED || !printedScanDone || loanPrepShredDone)
			return false;

		loanPrepShredDone = true;
		guideShownForPhase = -1;
		return loanWalkthroughReady;
	}

	public function beginLoanGuide():Void
	{
		guidePhase = GUIDE_LOAN_OPEN_COMPUTER;
		guideShownForPhase = -1;
		scanHintUnlocked = false;
		printedScanDone = false;
		loanWalkthroughReady = false;
		loanPrepShredDone = false;
		loanRateGuideSubStep = 0;
	}

	public function shouldResumeAfterLoanQuestion():Bool
	{
		return loanQuestionResumePending;
	}

	public function resumeAfterLoanQuestion():Void
	{
		loanQuestionResumePending = false;
		guidePhase = loanQuestionResumePhase;
		guideShownForPhase = -1;
	}

	public function onLoanQuestionAsked(actionId:String):Void
	{
		if (guidePhase == GUIDE_LOAN_BOOK_SCAN)
		{
			if (actionId != "loan_security")
				return;

			loanQuestionResumePhase = GUIDE_LOAN_SECURITY_DESK;
			loanQuestionResumePending = true;
			guideShownForPhase = -1;
			return;
		}

		if (guidePhase == GUIDE_LOAN_ASK_EXPENSES)
		{
			if (actionId != "living_expenses")
				return;

			loanQuestionResumePhase = GUIDE_LOAN_EXPENSES_DESK;
			loanQuestionResumePending = true;
			return;
		}

		if (guidePhase == GUIDE_LOAN_ASK_COMFORTABLE)
		{
			if (actionId != "comfortable_rate")
				return;

			loanQuestionResumePhase = GUIDE_LOAN_TERM_DESK;
			loanQuestionResumePending = true;
		}
	}

	public function notifyMonitorClosed():Void
	{
		if (guidePhase == GUIDE_LOAN_PREP_SECURITY)
		{
			guidePhase = GUIDE_LOAN_BOOK_SLIDE;
			guideShownForPhase = -1;
			bookSlideStarted = false;
			bookSlideDelayRemaining = 1.0;
			return;
		}

		if (guidePhase == GUIDE_LOAN_PREP_EXPENSES)
		{
			guidePhase = GUIDE_LOAN_ASK_EXPENSES;
			guideShownForPhase = -1;
			scanHintSubStep = 0;
			scanModeWasActive = false;
			return;
		}

		if (guidePhase == GUIDE_LOAN_PREP_COMFORTABLE)
		{
			guidePhase = GUIDE_LOAN_ASK_COMFORTABLE;
			guideShownForPhase = -1;
			scanHintSubStep = 0;
			scanModeWasActive = false;
			return;
		}

		if (guidePhase == GUIDE_LOAN_FOLDER)
			openingMonitor = false;
	}

	public function updateBookSlideDelay(elapsed:Float):Bool
	{
		if (bookSlideDelayRemaining <= 0)
			return false;

		bookSlideDelayRemaining -= elapsed;
		if (bookSlideDelayRemaining > 0)
			return false;

		bookSlideDelayRemaining = 0;
		pendingPlaceBook = true;
		return true;
	}

	public function notifyDetailsShredded():Void
	{
		if (printedScanDone || scanVerified)
			return;
		if (!isMonitorGuideActive() && !isDeskGuideActive())
			return;
		if (guidePhase > GUIDE_SCAN_PRINTED)
			return;

		detailsPrinted = false;
		detailsShreddedRecovery = true;
		resumeMonitorGuidePhase = GUIDE_MONITOR_PRINT;
		guidePhase = GUIDE_DESK_OPEN_COMPUTER;
		guideShownForPhase = -1;
		scanHintUnlocked = false;
		scanModeWasActive = false;
		printedScanDone = false;
		loanWalkthroughReady = false;
		loanPrepShredDone = false;
	}

	public function notifyBookSlideComplete():Void
	{
		bookSlideStarted = true;
		guideShownForPhase = -1;
	}

	public function shouldLockLoanBook():Bool
	{
		return guidePhase == GUIDE_LOAN_BOOK_SLIDE;
	}

	public function getLoanBookTocLockIndex():Int
	{
		return -1;
	}

	public function onPrintedScanConfirmed():Void
	{
		printedScanDone = true;
		if (guidePhase == GUIDE_SCAN_PRINTED)
		{
			guideShownForPhase = -1;
			scanHintSubStep = 0;
		}
	}

	public function consumePendingPlaceBook():Bool
	{
		if (!pendingPlaceBook)
			return false;
		pendingPlaceBook = false;
		return true;
	}

	public function consumePendingMonitorClose():Bool
	{
		if (!pendingMonitorClose)
			return false;
		pendingMonitorClose = false;
		return true;
	}

	public function completeBookTutorial():Void
	{
		markScanVerified();
		guidePhase = GUIDE_BOOK_DONE;
		guideShownForPhase = -1;
	}

	public function isBookTutorialComplete():Bool
	{
		return guidePhase == GUIDE_BOOK_DONE;
	}

	public function allowsComputerClick():Bool
	{
		if (openingMonitor)
			return false;
		if (guidePhase == GUIDE_DESK_OPEN_COMPUTER)
			return true;
		if (isLoanGuideActive())
			return guidePhase != GUIDE_LOAN_FOLDER_INTRO;
		return isLoanSalaryComputerClickReady();
	}

	public function isLoanSalaryComputerClickReady():Bool
	{
		return guidePhase == GUIDE_LOAN_CALCULATOR && loanSalaryCheckpoint;
	}

	public function isOpeningMonitor():Bool
	{
		return openingMonitor;
	}

	public function blocksMonitorDismiss():Bool
	{
		return guidePhase == GUIDE_MONITOR_WELCOME;
	}

	public function blocksAnyDeskDrag():Bool
	{
		return false;
	}

	public function blocksDeskInteraction(px:Float, py:Float, deskCoach:TutorialGuideOverlay):Bool
	{
		return false;
	}

	public function isScanPointAllowed(px:Float, py:Float, deskCoach:TutorialGuideOverlay,
			scanOverlay:ScanModeOverlay):Bool
	{
		if (!isBookGuideActive())
			return true;

		if (scanOverlay.isPointOnActionableMessage(new flixel.math.FlxPoint(px, py)))
			return true;

		return switch (guidePhase)
		{
			case GUIDE_SCAN_PRINTED:
				true;
			default:
				false;
		}
	}

	function isPointInAny(px:Float, py:Float, rects:Array<Null<TutorialGuideRect>>):Bool
	{
		for (rect in rects)
		{
			if (rect == null)
				continue;
			if (px >= rect.x && px < rect.x + rect.w && py >= rect.y && py < rect.y + rect.h)
				return true;
		}
		return false;
	}

	public function isMonitorGuidePhase():Bool
	{
		return isMonitorGuideActive() && guidePhase >= GUIDE_MONITOR_WELCOME;
	}

	public function shouldFilterMonitorClicks(coach:TutorialGuideOverlay):Bool
	{
		if (!guideMonitorActive)
			return false;
		if (guidePhase == GUIDE_MONITOR_WELCOME)
			return coach.isShowing;
		return true;
	}

	public function isMonitorClickAllowed(px:Float, py:Float, ui:MonitorScreenUi, coach:TutorialGuideOverlay):Bool
	{
		if (!guideMonitorActive)
			return true;

		if (guidePhase == GUIDE_MONITOR_WELCOME)
		{
			if (!coach.isShowing)
				return true;
			return coach.isPointOnContinue(px, py) || coach.isPointOnOverlay(px, py);
		}

		return true;
	}

	public function requestComputerOpen(deskCoach:TutorialGuideOverlay, onDeskHidden:Void->Void):Void
	{
		if (openingMonitor)
			return;

		if (guidePhase == GUIDE_LOAN_SECURITY_DESK || guidePhase == GUIDE_LOAN_EXPENSES_DESK
			|| guidePhase == GUIDE_LOAN_TERM_DESK)
		{
			openingMonitor = true;
			if (guidePhase == GUIDE_LOAN_SECURITY_DESK)
				guidePhase = GUIDE_LOAN_SECURITY;
			else if (guidePhase == GUIDE_LOAN_EXPENSES_DESK)
				guidePhase = GUIDE_LOAN_EXPENSES;
			else
				guidePhase = GUIDE_LOAN_TERM_FINAL;
			guideShownForPhase = -1;
			if (!deskCoach.isShowing)
			{
				onDeskHidden();
				return;
			}
			deskCoach.hide(true, onDeskHidden);
			return;
		}

		if ((guidePhase == GUIDE_LOAN_CALCULATOR || guidePhase == GUIDE_LOAN_SALARY) && loanSalaryCheckpoint)
		{
			openingMonitor = true;
			guidePhase = GUIDE_LOAN_SALARY;
			guideShownForPhase = -1;
			if (!deskCoach.isShowing)
			{
				onDeskHidden();
				return;
			}
			deskCoach.hide(true, onDeskHidden);
			return;
		}

		if (guidePhase == GUIDE_DESK_OPEN_COMPUTER || guidePhase == GUIDE_LOAN_OPEN_COMPUTER)
		{
			openFirstTimeMonitor(deskCoach, onDeskHidden);
			return;
		}

		if (isLoanGuideActive() && guidePhase >= GUIDE_LOAN_MAIN_MENU)
		{
			openingMonitor = true;
			if (!deskCoach.isShowing)
			{
				onDeskHidden();
				return;
			}
			deskCoach.hide(true, onDeskHidden);
			return;
		}

		return;
	}

	function openFirstTimeMonitor(deskCoach:TutorialGuideOverlay, onDeskHidden:Void->Void):Void
	{
		openingMonitor = true;
		if (guidePhase == GUIDE_LOAN_OPEN_COMPUTER)
		{
			loanWelcomePending = !monitorWelcomeSeen;
			guidePhase = monitorWelcomeSeen ? GUIDE_LOAN_MAIN_MENU : GUIDE_MONITOR_WELCOME;
			guideShownForPhase = -1;
		}
		else if (monitorWelcomeSeen)
		{
			guidePhase = resumeMonitorGuidePhase;
			guideShownForPhase = -1;
		}
		else
		{
			guidePhase = GUIDE_MONITOR_WELCOME;
			guideShownForPhase = -1;
		}

		if (!deskCoach.isShowing)
		{
			onDeskHidden();
			return;
		}

		deskCoach.hide(true, onDeskHidden);
	}

	function showMonitorPhaseCoach(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay, message:String,
			?highlight:Null<TutorialGuideRect> = null, ?needsContinue:Bool = false,
			?continueAction:Null<Void->Void> = null):Void
	{
		monitorCoach.showCoach(message, highlight, needsContinue, continueAction, true, true, false, false);
	}

	function showMonitorWelcomeCoach(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay):Void
	{
		if (monitorWelcomeSeen)
			return;

		if (monitorCoach.isBusy())
			return;

		if (!monitor.isShowing)
			return;

		if (monitorCoach.isShowing && guideShownForPhase == GUIDE_MONITOR_WELCOME)
			return;

		guideShownForPhase = GUIDE_MONITOR_WELCOME;
		monitorCoach.showCoach(
			'Everything on the desk pauses while you are in here.\n\n'
				+ 'To leave the terminal, just click outside the monitor.',
			null,
			true,
			function()
			{
				monitorWelcomeSeen = true;
				guidePhase = loanWelcomePending ? GUIDE_LOAN_MAIN_MENU : GUIDE_MONITOR_MAIN_MENU;
				loanWelcomePending = false;
				guideShownForPhase = -1;
			},
			true,
			true,
			false
		);
	}

	public function notifyMonitorSlideInComplete(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay):Void
	{
		if (monitorWelcomeSeen || guidePhase != GUIDE_MONITOR_WELCOME)
			return;
		showMonitorWelcomeCoach(monitorCoach, monitor);
	}

	public function refreshSalaryState(c:Citizen):Void
	{
		salaryUpdated = c.averageAnnualSalary == TARGET_SALARY;
		if (salaryUpdated)
			salaryRejectedMessage = null;
	}

	public function notifySalaryValidationFailed(message:String):Void
	{
		salaryRejectedMessage = message;
		unneededFieldEditMessage = null;
	}

	public function handlesSalaryValidationInCoach():Bool
	{
		return guidePhase == GUIDE_MONITOR_SALARY;
	}

	public static function salaryValidationMessage():String
	{
		return 'Sorry! Annual salary needs\nto be $TARGET_SALARY LOR.';
	}

	public static function unneededFieldEditCoachText():String
	{
		return "No — it's better not to mess with a customer's data.\n"
			+ "The only change you need is " + managerDisplayName() + "'s Annual Salary — set it to "
			+ TARGET_SALARY + " LOR.";
	}

	public static function wrongCustomerCoachText():String
	{
		return "Oh, I don't think that's me.\n\nPress BACK to return to the client database.";
	}

	public function isWrongClientActive():Bool
	{
		return wrongClientActive;
	}

	function isCorrectTutorialClient(ui:MonitorScreenUi):Bool
	{
		var selected = ui.getSelectedCitizen();
		return selected != null && CitizenRegistry.indexOf(selected) == CITIZEN_INDEX;
	}

	function showWrongClientDetailCoach(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay):Void
	{
		var message = unneededFieldEditMessage != null
			? unneededFieldEditMessage
			: ChefTutorial.wrongCustomerCoachText();
		showMonitorPhaseCoach(monitorCoach, monitor, message);
	}

	function updateWrongClientGuide(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay, ui:MonitorScreenUi):Bool
	{
		if (guidePhase < GUIDE_MONITOR_DATABASE || guidePhase > GUIDE_MONITOR_SELECT)
			return false;

		if (wrongClientActive && !ui.isOnClientDetail())
		{
			wrongClientActive = false;
			guidePhase = GUIDE_MONITOR_DATABASE;
			guideShownForPhase = -1;
			unneededFieldEditMessage = null;
		}

		if (ui.isOnClientDetail())
		{
			if (!isCorrectTutorialClient(ui))
			{
				if (!wrongClientActive)
				{
					wrongClientActive = true;
					guideShownForPhase = -1;
				}
				showWrongClientDetailCoach(monitorCoach, monitor);
				return true;
			}

			wrongClientActive = false;
			guidePhase = GUIDE_MONITOR_SALARY;
			guideShownForPhase = -1;
			ui.setPrintButtonEnabled(false);
			return true;
		}

		return false;
	}

	public function shouldBlockFieldEdit(citizen:Citizen, path:String):Bool
	{
		if (!isMonitorGuidePhase())
			return false;
		if (wrongClientActive)
			return true;
		if (guidePhase >= GUIDE_MONITOR_SALARY && CitizenRegistry.indexOf(citizen) == CITIZEN_INDEX)
			return path != "averageAnnualSalary";
		return false;
	}

	public function handlesUnneededFieldEditInCoach(path:String):Bool
	{
		if (wrongClientActive)
			return true;
		return guidePhase >= GUIDE_MONITOR_SALARY && path != "averageAnnualSalary";
	}

	public function notifyUnneededFieldEdit():Void
	{
		unneededFieldEditMessage = ChefTutorial.unneededFieldEditCoachText();
		salaryRejectedMessage = null;
	}

	public function saveMonitorGuideResume():Void
	{
		if (!isMonitorGuidePhase())
			return;
		if (guidePhase == GUIDE_MONITOR_WELCOME && !monitorWelcomeSeen)
			return;
		if (wrongClientActive)
			resumeMonitorGuidePhase = GUIDE_MONITOR_DATABASE;
		else
			resumeMonitorGuidePhase = guidePhase == GUIDE_MONITOR_WELCOME ? GUIDE_MONITOR_MAIN_MENU : guidePhase;
	}

	public function hasSeenMonitorWelcome():Bool
	{
		return monitorWelcomeSeen;
	}

	public function markDetailsPrinted():Void
	{
		detailsPrinted = true;
		if (guidePhase == GUIDE_MONITOR_PRINT)
		{
			guidePhase = GUIDE_DESK_DRAG;
			guideMonitorActive = false;
			guideShownForPhase = -1;
			scanHintUnlocked = false;
		}
	}

	public function markScanVerified():Void
	{
		scanVerified = true;
	}

	public function buildIntroSteps(ctx:ChefTutorialContext):Array<ClientConvStep>
	{
		var steps = ClientScenarios.chefTutorialIntroBaseSteps();
		steps.push(ClientScenarios.chefTutorialIdleStep());
		return steps;
	}

	public function tryGetProgressDialogue(ctx:ChefTutorialContext):Null<Array<ClientConvStep>>
	{
		return null;
	}

	public function updateDeskGuide(deskCoach:TutorialGuideOverlay, ctx:BookTutorialContext):Void
	{
		if (!isDeskGuideActive())
			return;

		if (guidePhase == GUIDE_DESK_DRAG)
		{
			if (ctx.printedOnEmployerDesk)
			{
				guidePhase = GUIDE_SCAN_PRINTED;
				guideShownForPhase = -1;
				scanHintUnlocked = true;
				scanHintSubStep = 0;
				return;
			}

			if (ctx.printedOnClientTable)
			{
				if (ctx.draggingPrintedRecord)
				{
					deskCoach.showCoach(
						'Drop the printed record on the employer desk on the right side.',
						null,
						false,
						null,
						true,
						true,
						false
					);
				}
				else if (guideShownForPhase != guidePhase)
				{
					guideShownForPhase = guidePhase;
					deskCoach.showCoach(
						'Drag the printed record from the client table to the employer desk on the right side.',
						ctx.printedHighlight,
						false,
						null,
						false,
						true,
						true
					);
				}
				return;
			}

			if (ctx.draggingPrintedRecord)
			{
				deskCoach.showCoach('Drop the printed record on your desk.', null, false, null, true, true, false);
			}
			else if (ctx.paperOnPrinter)
			{
				deskCoach.showCoach(
					'Drag the printed record from the printer to your desk.',
					null,
					false,
					null,
					false,
					true,
					true
				);
			}
			else
			{
				deskCoach.showCoach(
					'Pick up the printed record from the printer and place it on your desk.',
					null,
					false,
					null,
					false,
					true,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_SCAN_PRINTED)
		{
			if (printedScanDone)
			{
				if (!loanWalkthroughReady)
				{
					deskCoach.hide();
					return;
				}

				if (!loanPrepShredDone)
				{
					if (guideShownForPhase != GUIDE_SCAN_PRINTED + 100)
					{
						guideShownForPhase = GUIDE_SCAN_PRINTED + 100;
						deskCoach.showCoach(
							'You do not need the printed client details anymore — drag them to the shredder.\n\n'
								+ 'That is the small black machine along the bottom middle of your desk.',
							ctx.shredderHighlight,
							false,
							null,
							false,
							true,
							true
						);
					}

					return;
				}

				deskCoach.hide();
				scanModeWasActive = false;
				return;
			}

			if (!ctx.printedOnEmployerDesk)
			{
				guidePhase = GUIDE_DESK_DRAG;
				guideShownForPhase = -1;
				scanHintUnlocked = false;
				scanModeWasActive = false;
				return;
			}

			if (ctx.scanActive)
			{
				if (!scanModeWasActive)
				{
					scanModeWasActive = true;
					scanHintSubStep = -1;
					guideShownForPhase = -1;
				}

				var nextSubStep = if (ctx.actionReady)
					3
				else if (ctx.hasPrintedSelection && ctx.hasClientSelection)
					3
				else if (ctx.hasPrintedSelection)
					2
				else if (ctx.hasClientSelection)
					1
				else
					0;

				if (nextSubStep != scanHintSubStep)
				{
					scanHintSubStep = nextSubStep;
					guideShownForPhase = -1;
				}

				var hintKey = guidePhase * 100 + 10 + scanHintSubStep;
				if (guideShownForPhase != hintKey)
				{
					guideShownForPhase = hintKey;
					var scanMsg = switch (scanHintSubStep)
					{
						case 3: 'Click the green confirm button — or press Enter.';
						case 2: 'Now click my face to pair the scan.';
						case 1: 'Now click the printed record to pair the scan.';
						default: 'Click the printed record and my face — order does not matter.';
					}
					deskCoach.showCoach(scanMsg, null, false, null, true, false, false);
				}
			}
			else
			{
				if (scanModeWasActive)
				{
					scanModeWasActive = false;
					scanHintSubStep = 0;
					guideShownForPhase = -1;
				}

				var hintKey = guidePhase * 100;
				if (guideShownForPhase != hintKey)
				{
					guideShownForPhase = hintKey;
					deskCoach.showCoach(
						'Scan Mode links a document on your desk with your client and the guide book so you can ask structured questions.\n\n'
							+ 'Enter Scan Mode by clicking Let me ask you..., pressing SPACE, or double-clicking anything on the desk.',
						null,
						false,
						null,
						true,
						false,
						false
					);
				}
			}
		}
	}

	public function shouldTryFolderIntroDialog():Bool
	{
		return folderIntroDialogPending && guidePhase == GUIDE_LOAN_FOLDER_INTRO;
	}

	public function consumeFolderIntroDialog():Bool
	{
		if (!folderIntroDialogPending)
			return false;
		folderIntroDialogPending = false;
		return true;
	}

	public function shouldCompleteFolderIntro():Bool
	{
		return guidePhase == GUIDE_LOAN_FOLDER_INTRO;
	}

	public function onFolderIntroDialogComplete():Void
	{
		if (guidePhase != GUIDE_LOAN_FOLDER_INTRO)
			return;
		guidePhase = GUIDE_LOAN_FOLDER;
		guideShownForPhase = -1;
	}

	public function updateLoanFolderGuide(monitor:MonitorOverlay, deskCoach:TutorialGuideOverlay,
			monitorCoach:TutorialGuideOverlay, ui:MonitorScreenUi, ctx:LoanFolderTutorialContext):Void
	{
		if (guidePhase == GUIDE_LOAN_FOLDER_INTRO || guidePhase != GUIDE_LOAN_FOLDER)
		{
			if (guidePhase == GUIDE_LOAN_FOLDER_INTRO)
				deskCoach.hide(true);
			return;
		}

		if (!ctx.folderVisible || ctx.folderApprovalRequested)
			return;

		lastFolderGuideContext = ctx;
		var hintKey = folderGuideHintKey(ctx);
		var useMonitorCoach = folderGuideUsesMonitorCoach(hintKey) && monitor.isActive();
		var coachKey = hintKey + (useMonitorCoach ? 1000 : 0);
		if (guideShownForPhase == coachKey)
			return;

		guideShownForPhase = coachKey;
		var msg = folderGuideMessage(ctx, useMonitorCoach);
		var highlight = folderGuideHighlight(ctx, ui, hintKey);

		if (useMonitorCoach)
		{
			if (deskCoach.isShowing)
				deskCoach.hide(true);
			showMonitorPhaseCoach(monitorCoach, monitor, msg, highlight);
			return;
		}

		if (monitorCoach.isShowing)
			monitorCoach.hide(true);
		deskCoach.showCoach(msg, highlight, false, null, highlight == null, false, highlight != null);
	}

	public function notifyFolderApprovalRequested():Void
	{
		if (guidePhase == GUIDE_LOAN_FOLDER)
		{
			folderApprovalRequested = true;
			guideShownForPhase = -1;
		}
	}

	public function shouldStartFolderFarewell():Bool
	{
		return guidePhase == GUIDE_LOAN_FOLDER && folderApprovalRequested;
	}

	public function onFolderTutorialSubmitComplete():Void
	{
		if (guidePhase != GUIDE_LOAN_FOLDER)
			return;

		completeBookTutorial();
	}

	public function getFolderAllowedMenuIndex(ctx:LoanFolderTutorialContext):Int
	{
		return switch (folderGuideHintKey(ctx))
		{
			case 415: 2;
			case 410: 1;
			case 450: 3;
			default: -1;
		};
	}

	function folderGuideHintKey(ctx:LoanFolderTutorialContext):Int
	{
		if (!ctx.hasIdCopy)
		{
			if (ctx.chefIdOnPrinter)
				return 400;
			if (ctx.chefIdDragging)
				return 401;
			if (ctx.idCopyOnPrinter)
				return 402;
			return 403;
		}
		if (!ctx.hasFormCopy)
			return 415;
		if (!ctx.hasChecklistCopy)
			return 410;
		if (!ctx.folderSpreadOpen)
			return 425;
		if (!ctx.folderComplete)
			return 430;
		return 450;
	}

	function folderGuideUsesMonitorCoach(hintKey:Int):Bool
	{
		return hintKey == 410 || hintKey == 415 || hintKey == 450;
	}

	function folderGuideMessage(ctx:LoanFolderTutorialContext, ?onMonitor:Bool = false):String
	{
		return switch (folderGuideHintKey(ctx))
		{
			case 400:
				'Wait for the scanner to finish copying my ID.';
			case 401:
				'Drop my ID on the printer/scanner.';
			case 402:
				'Pick up the ID copy from the printer.';
			case 403:
				if (!ctx.chefIdOnClientTable)
					'You need my ID on the client table first.';
				else if (!ctx.printerCanAccept)
					'The printer is busy — drag the document out of the printer tray to free it up, then scan my ID.';
				else
					'Drag my ID to the scanner/printer on your desk.';
			case 415:
				'Open the terminal → Loan Application → Print Application Form, then pick up the copy.';
			case 410:
				'Now that you have a copy of my ID and the loan application form, you also need the checklist of all documents.\n\n'
					+ 'Go to the terminal and on the Loan Application screen click Print Checklist.';
			case 425:
				'Click the arrow on the bottom right of the folder to open it.';
			case 430:
				'Drag and drop all needed documents into the loan folder.';
			case 450:
				onMonitor
					? 'Click Submit for Approval.'
					: 'Go to the computer and submit the folder for approval.';
			default:
				'';
		}
	}

	function folderGuideHighlight(ctx:LoanFolderTutorialContext, ui:MonitorScreenUi,
			hintKey:Int):Null<TutorialGuideRect>
	{
		return switch (hintKey)
		{
			case 400, 401, 403:
				if (!ctx.hasIdCopy && ctx.chefIdOnClientTable && !ctx.chefIdOnPrinter)
					ctx.printerHighlight;
				else
					null;
			case 402:
				ctx.printerHighlight;
			case 415:
				ui.isOnLoanApplication()
					? ui.getTutorialHighlight("loan_print_application") : ctx.computerHighlight;
			case 410:
				ui.isOnLoanApplication()
					? ui.getTutorialHighlight("loan_print_checklist") : ctx.computerHighlight;
			case 425:
				ctx.folderArrowHighlight;
			case 430:
				ctx.folderStorageHighlight;
			case 450:
				ui.isOnLoanApplication()
					? ui.getTutorialHighlight("loan_submit_approval") : ctx.computerHighlight;
			default:
				ctx.computerHighlight;
		}
	}

	public function updateLoanGuide(monitor:MonitorOverlay, deskCoach:TutorialGuideOverlay,
			monitorCoach:TutorialGuideOverlay, computerHighlight:TutorialGuideRect,
			calculatorHighlight:TutorialGuideRect, calculatorValue:Float, loanFolderVisible:Bool,
			bookCtx:BookTutorialContext):Void
	{
		if (!isLoanGuideActive())
			return;

		var monitorEngaged = monitor.isActive();
		if (monitorEngaged)
			openingMonitor = false;
		else if (guidePhase == GUIDE_LOAN_OPEN_COMPUTER)
			openingMonitor = false;

		if (guidePhase == GUIDE_LOAN_FOLDER_INTRO || guidePhase == GUIDE_LOAN_FOLDER)
			return;
		var monitorReady = monitor.isShowing && !monitor.isAnimating;
		var ui = monitor.getScreenUi();
		var needsMonitor = !isLoanDeskOnlyPhase();

		if (guidePhase == GUIDE_LOAN_OPEN_COMPUTER)
		{
			monitorCoach.hide();
			guideMonitorActive = false;
			if (!monitorEngaged)
			{
				if (guideShownForPhase != guidePhase)
				{
					guideShownForPhase = guidePhase;
					deskCoach.showCoach('Click the computer to open the terminal.', null, false, null, true);
				}
				return;
			}

			guidePhase = GUIDE_LOAN_MAIN_MENU;
			guideShownForPhase = -1;
			if (deskCoach.isShowing)
				deskCoach.hide(true);
		}

		if (guidePhase == GUIDE_LOAN_CLOSE_CALC)
		{
			if (loanSalaryCheckpoint && monitorEngaged)
			{
				guidePhase = GUIDE_LOAN_SALARY;
				guideShownForPhase = -1;
				return;
			}

			if (!monitorEngaged)
			{
				guidePhase = GUIDE_LOAN_CALCULATOR;
				guideShownForPhase = -1;
				if (!loanSalaryCheckpoint)
					loanSalaryCalcReady = false;
				return;
			}

			if (deskCoach.isShowing)
				deskCoach.hide(true);
			guideMonitorActive = monitorReady;

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'As you remember we only have the annual salary we can base on, which is 42,000 LOR. '
						+ 'To get monthly one - we have to do some math, go ahead and close the terminal '
						+ 'by clicking outside of the monitor.',
					ui.getTutorialHighlight("loan_declared_salary")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_CALCULATOR)
		{
			monitorCoach.hide();
			guideMonitorActive = false;
			if (monitorEngaged)
			{
				guidePhase = loanSalaryCheckpoint ? GUIDE_LOAN_SALARY : GUIDE_LOAN_CLOSE_CALC;
				guideShownForPhase = -1;
				return;
			}

			if (loanSalaryCheckpoint)
			{
				if (guideShownForPhase != guidePhase + 1)
				{
					guideShownForPhase = guidePhase + 1;
					deskCoach.showCoach(
						'Nice — 3,500 LOR a month. Click the computer and enter that as Monthly Salary.',
						computerHighlight,
						false,
						null,
						false,
						false,
						true
					);
				}
				return;
			}

			loanSalaryCalcReady = calculatorMatchesSalary(calculatorValue);
			if (loanSalaryCalcReady)
			{
				loanSalaryCheckpoint = true;
				if (guideShownForPhase != guidePhase + 1)
				{
					guideShownForPhase = guidePhase + 1;
					deskCoach.showCoach(
						'Nice — 3,500 LOR a month. Click the computer and enter that as Monthly Salary.',
						computerHighlight,
						false,
						null,
						false,
						false,
						true
					);
				}
				return;
			}

			loanSalaryCalcReady = false;
			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Your calculator is in the bottom-right corner of your desk.\n\n'
						+ 'Use it to divide 42,000 by 12 — that gives you the monthly salary.',
					calculatorHighlight,
					false,
					null,
					false,
					false,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_SALARY && !monitorEngaged)
		{
			monitorCoach.hide();
			guideMonitorActive = false;
			if (guideShownForPhase != guidePhase + 1)
			{
				guideShownForPhase = guidePhase + 1;
				deskCoach.showCoach(
					'Click the computer and enter monthly salary as 3,500 LOR.',
					computerHighlight,
					false,
					null,
					false,
					false,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_PREP_SECURITY || guidePhase == GUIDE_LOAN_PREP_EXPENSES
			|| guidePhase == GUIDE_LOAN_PREP_COMFORTABLE)
		{
			if (!monitorEngaged)
				return;

			if (deskCoach.isShowing)
				deskCoach.hide(true);
			guideMonitorActive = monitorReady;

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				var prepMsg = switch (guidePhase)
				{
					case GUIDE_LOAN_PREP_SECURITY:
						'Next up is Security.\n\nGo ahead and close the terminal by clicking outside the monitor.';
					case GUIDE_LOAN_PREP_COMFORTABLE:
						'You know — the current rate is 1,419 LOR a month and the status is Marginal. '
							+ 'Better ask the client about their comfortable rate using the guide book questions.\n\n'
							+ 'Close the terminal when you are ready.';
					default:
						'Next up are monthly expenses — housing, living, and other.\n\n'
							+ 'You will need to ask the client using the guide book. '
							+ 'Go ahead and close the terminal by clicking outside the monitor.';
				}
				var prepHighlight = switch (guidePhase)
				{
					case GUIDE_LOAN_PREP_SECURITY: ui.getTutorialHighlight("loan_security");
					case GUIDE_LOAN_PREP_COMFORTABLE: ui.getTutorialHighlight("loan_calc_payment");
					default: ui.getTutorialHighlight("loan_spend_housing");
				}
				showMonitorPhaseCoach(monitorCoach, monitor, prepMsg, prepHighlight);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_BOOK_SLIDE || guidePhase == GUIDE_LOAN_BOOK_TOC
			|| guidePhase == GUIDE_LOAN_BOOK_SCAN || guidePhase == GUIDE_LOAN_SECURITY_DESK
			|| guidePhase == GUIDE_LOAN_ASK_EXPENSES || guidePhase == GUIDE_LOAN_EXPENSES_DESK
			|| guidePhase == GUIDE_LOAN_ASK_COMFORTABLE || guidePhase == GUIDE_LOAN_TERM_DESK)
		{
			updateLoanBookGuide(deskCoach, bookCtx, computerHighlight);
			return;
		}

		if (needsMonitor && !monitorEngaged && !openingMonitor
			&& guidePhase != GUIDE_LOAN_SALARY && guidePhase != GUIDE_LOAN_EXPENSES
			&& guidePhase != GUIDE_LOAN_PREP_EXPENSES && guidePhase != GUIDE_LOAN_PREP_COMFORTABLE
			&& !isLoanMonitorFormPhase())
		{
			if (deskCoach.isShowing)
				deskCoach.hide(true);
			monitorCoach.hide();
			guideMonitorActive = false;
			guidePhase = GUIDE_LOAN_OPEN_COMPUTER;
			guideShownForPhase = -1;
			return;
		}

		if (!needsMonitor)
			return;

		if (deskCoach.isShowing)
			deskCoach.hide(true);
		guideMonitorActive = monitorReady;

		if (!ui.isOnMainMenu() && !ui.isOnLoanApplication())
		{
			if (guideShownForPhase != -guidePhase)
			{
				guideShownForPhase = -guidePhase;
				showMonitorPhaseCoach(monitorCoach, monitor, 'Press BACK to return to the main menu.');
			}
			return;
		}

		if (guidePhase == GUIDE_LOAN_MAIN_MENU)
		{
			if (!ui.isOnMainMenu())
			{
				if (ui.isOnLoanApplication())
				{
					guidePhase = GUIDE_LOAN_NEW_APP;
					guideShownForPhase = -1;
				}
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Open Loan Application from the main menu.',
					ui.getTutorialHighlight("menu_loan_application")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_NEW_APP)
		{
			if (!ui.isOnLoanApplication())
			{
				guidePhase = GUIDE_LOAN_MAIN_MENU;
				guideShownForPhase = -1;
				return;
			}

			if (ui.isOnLoanNewForm())
			{
				guidePhase = GUIDE_LOAN_NATIONAL_ID;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Choose New Application.',
					ui.getTutorialHighlight("loan_new_application")
				);
			}

			return;
		}

		if (!ui.isOnLoanNewForm())
		{
			guidePhase = GUIDE_LOAN_NEW_APP;
			guideShownForPhase = -1;
			return;
		}

		updateLoanFormGuide(monitor, monitorCoach, ui);
	}

	function updateLoanBookGuide(deskCoach:TutorialGuideOverlay, ctx:BookTutorialContext,
			computerHighlight:TutorialGuideRect):Void
	{
		if (guidePhase == GUIDE_LOAN_BOOK_SLIDE)
		{
			if (!ctx.bookSlideComplete)
				return;

			guidePhase = GUIDE_LOAN_BOOK_TOC;
			guideShownForPhase = -1;
			return;
		}

		if (guidePhase == GUIDE_LOAN_BOOK_TOC)
		{
			if (ctx.onQuestionsSpread)
			{
				guidePhase = GUIDE_LOAN_BOOK_SCAN;
				guideShownForPhase = -1;
				scanHintSubStep = 0;
				scanModeWasActive = false;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'The book you see on your table is your guide book that will help you navigate in your job '
						+ 'and also allow you to ask relevant questions to your clients.\n\n'
						+ 'Click Questions to ask in the contents to jump to pages 31–32.',
					ctx.tocQuestionsHighlight,
					false,
					null,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_BOOK_SCAN)
		{
			if (loanQuestionResumePending)
				return;

			if (ctx.scanActive)
			{
				if (!scanModeWasActive)
				{
					scanModeWasActive = true;
					scanHintSubStep = -1;
					guideShownForPhase = -1;
				}

				var nextSubStep = if (ctx.actionReady)
					3
				else if (ctx.hasBookQuestionSelection && ctx.hasClientSelection)
					3
				else if (ctx.hasBookQuestionSelection)
					2
				else if (ctx.hasClientSelection)
					1
				else
					0;

				if (nextSubStep != scanHintSubStep)
				{
					scanHintSubStep = nextSubStep;
					guideShownForPhase = -1;
				}

				var hintKey = guidePhase * 100 + scanHintSubStep;
				if (guideShownForPhase != hintKey)
				{
					guideShownForPhase = hintKey;
					var scanMsg = switch (scanHintSubStep)
					{
						case 3: 'Click the green confirm button — or press Enter.';
						case 2: 'Now click my face to ask the question.';
						case 1: 'Pick a question from the handbook first.';
						default: 'Enter Scan Mode, choose a question from the handbook, then click my face.';
					}
					deskCoach.showCoach(scanMsg, null, false, null, true, false, false);
				}
			}
			else
			{
				if (scanModeWasActive)
				{
					scanModeWasActive = false;
					scanHintSubStep = 0;
					guideShownForPhase = -1;
				}

				if (guideShownForPhase != guidePhase)
				{
					guideShownForPhase = guidePhase;
					deskCoach.showCoach(
						'Use Scan Mode to ask a question from the handbook, then click the client.\n\n'
							+ 'Start with: Do you wish your loan to be secured or not?',
						ctx.questionHighlight,
						false,
						null,
						true
					);
				}
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_SECURITY_DESK)
		{
			if (loanQuestionResumePending)
				return;

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Nice — you have the answer. Open the terminal and set Security to Not secured.',
					computerHighlight,
					false,
					null,
					false,
					false,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_EXPENSES_DESK)
		{
			if (loanQuestionResumePending)
				return;

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Nice — you have the answer. Open the terminal and enter monthly expenses: 700 housing, 400 living, 150 other.',
					computerHighlight,
					false,
					null,
					false,
					false,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_ASK_EXPENSES)
		{
			if (loanQuestionResumePending)
				return;

			if (ctx.scanActive)
			{
				if (!scanModeWasActive)
				{
					scanModeWasActive = true;
					scanHintSubStep = -1;
					guideShownForPhase = -1;
				}

				var nextSubStep = if (ctx.actionReady)
					3
				else if (ctx.hasBookQuestionSelection && ctx.hasClientSelection)
					3
				else if (ctx.hasBookQuestionSelection)
					2
				else if (ctx.hasClientSelection)
					1
				else
					0;

				if (nextSubStep != scanHintSubStep)
				{
					scanHintSubStep = nextSubStep;
					guideShownForPhase = -1;
				}

				var hintKey = guidePhase * 100 + scanHintSubStep;
				if (guideShownForPhase != hintKey)
				{
					guideShownForPhase = hintKey;
					var scanMsg = switch (scanHintSubStep)
					{
						case 3: 'Click the green confirm button — or press Enter.';
						case 2: 'Now click my face to ask the question.';
						case 1: 'Pick What are your monthly living expenses? from the handbook.';
						default: 'Enter Scan Mode and ask about monthly living expenses.';
					}
					deskCoach.showCoach(scanMsg, null, false, null, true, false, false);
				}
			}
			else if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Use Scan Mode to ask a question from the handbook, then click the client.\n\n'
						+ 'Start with: What are your monthly living expenses?',
					ctx.questionHighlight,
					false,
					null,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_TERM_DESK)
		{
			if (loanQuestionResumePending)
				return;

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Okay, that will be around 24 months — go ahead and write the term as 24.',
					computerHighlight,
					false,
					null,
					false,
					false,
					true
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_ASK_COMFORTABLE)
		{
			if (loanQuestionResumePending)
				return;

			if (ctx.scanActive)
			{
				if (!scanModeWasActive)
				{
					scanModeWasActive = true;
					scanHintSubStep = -1;
					guideShownForPhase = -1;
				}

				var nextSubStep = if (ctx.actionReady)
					3
				else if (ctx.hasBookQuestionSelection && ctx.hasClientSelection)
					3
				else if (ctx.hasBookQuestionSelection)
					2
				else if (ctx.hasClientSelection)
					1
				else
					0;

				if (nextSubStep != scanHintSubStep)
				{
					scanHintSubStep = nextSubStep;
					guideShownForPhase = -1;
				}

				var hintKey = guidePhase * 100 + scanHintSubStep;
				if (guideShownForPhase != hintKey)
				{
					guideShownForPhase = hintKey;
					var scanMsg = switch (scanHintSubStep)
					{
						case 3: 'Click the green confirm button — or press Enter.';
						case 2: 'Now click my face to ask the question.';
						case 1: 'Pick What monthly payment would you be comfortable with? from the handbook.';
						default: 'Enter Scan Mode and ask about the comfortable monthly payment.';
					}
					deskCoach.showCoach(scanMsg, null, false, null, true, false, false);
				}
			}
			else if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				deskCoach.showCoach(
					'Use Scan Mode to ask a question from the handbook, then click the client.\n\n'
						+ 'Start with: What monthly payment would you be comfortable with?',
					ctx.questionHighlight,
					false,
					null,
					true
				);
			}

			return;
		}
	}

	function updateLoanFormGuide(monitor:MonitorOverlay, monitorCoach:TutorialGuideOverlay, ui:MonitorScreenUi):Void
	{
		if (guidePhase == GUIDE_LOAN_NATIONAL_ID)
		{
			if (loanNationalIdMatches(ui))
			{
				guidePhase = GUIDE_LOAN_PRODUCT;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'First, let\'s start with National ID. You can search by name here too.\n\n'
						+ 'Go ahead and find me: ${managerDisplayName()}.',
					ui.getTutorialHighlight("loan_national_id")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_PRODUCT)
		{
			if (loanProductMatches(ui))
			{
				guidePhase = GUIDE_LOAN_AMOUNT;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Choose loan product. For this test, pick Personal.',
					ui.getTutorialHighlight("loan_loan_type")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_AMOUNT)
		{
			if (loanAmountMatches(ui))
			{
				guidePhase = GUIDE_LOAN_TERM;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Enter the loan amount: 25,500 LOR.',
					ui.getTutorialHighlight("loan_amount")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_TERM)
		{
			if (loanTermMatches(ui, LOAN_TERM_TRIAL))
			{
				guidePhase = loanSalaryCheckpoint ? GUIDE_LOAN_SALARY : GUIDE_LOAN_CLOSE_CALC;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'We do not yet know which payment rate is comfortable for the client — for now, enter 10 months.',
					ui.getTutorialHighlight("loan_term")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_SALARY)
		{
			if (loanSalaryMatches(ui))
			{
				loanSalaryCheckpoint = false;
				guidePhase = GUIDE_LOAN_PREP_SECURITY;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Go ahead and write monthly salary as 3,500 LOR.',
					ui.getTutorialHighlight("loan_declared_salary")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_SECURITY)
		{
			if (loanSecurityMatches(ui))
			{
				guidePhase = GUIDE_LOAN_PREP_EXPENSES;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Set Security to Not secured.',
					ui.getTutorialHighlight("loan_security")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_EXPENSES)
		{
			if (!loanExpensesMatch(ui))
			{
				if (guideShownForPhase != guidePhase || !monitorCoach.isShowing)
				{
					guideShownForPhase = guidePhase;
					showMonitorPhaseCoach(
						monitorCoach,
						monitor,
						'Enter monthly expenses: 700 housing, 400 living, 150 other.',
						ui.getTutorialHighlight("loan_spend_housing")
					);
				}

				return;
			}

			guidePhase = GUIDE_LOAN_REVIEW_VALUES;
			guideShownForPhase = GUIDE_LOAN_REVIEW_VALUES * 10;
			showMonitorPhaseCoach(
				monitorCoach,
				monitor,
				'Scroll down and check all the data.',
				ui.getTutorialHighlight("loan_scroll")
			);
			return;
		}

		if (guidePhase == GUIDE_LOAN_REVIEW_VALUES)
		{
			if (!ui.isLoanFormScrolledToBottom())
			{
				var scrollKey = guidePhase * 10;
				if (!monitorCoach.isShowing && guideShownForPhase == scrollKey)
				{
					showMonitorPhaseCoach(
						monitorCoach,
						monitor,
						'Scroll down and check all the data.',
						ui.getTutorialHighlight("loan_scroll")
					);
				}

				return;
			}

			guidePhase = GUIDE_LOAN_CHECK_RATE;
			loanRateGuideSubStep = 0;
			guideShownForPhase = -1;
			return;
		}

		if (guidePhase == GUIDE_LOAN_CHECK_RATE)
		{
			if (loanRateGuideSubStep == 0)
			{
				if (loanTermMatches(ui, LOAN_TERM_MID))
				{
					loanRateGuideSubStep = 1;
					guideShownForPhase = -1;
					return;
				}

				var notAffordableKey = guidePhase * 10 + loanRateGuideSubStep;
				if (guideShownForPhase != notAffordableKey)
				{
					guideShownForPhase = notAffordableKey;
					showMonitorPhaseCoach(
						monitorCoach,
						monitor,
						'It\'s not affordable — try increasing the term to 20 months.',
						ui.getTutorialHighlight("loan_term")
					);
				}

				return;
			}

			if (loanRateGuideSubStep == 1)
			{
				if (!ui.isLoanFormScrolledToBottom())
				{
					var scrollAgainKey = guidePhase * 10 + loanRateGuideSubStep;
					if (guideShownForPhase != scrollAgainKey)
					{
						guideShownForPhase = scrollAgainKey;
						showMonitorPhaseCoach(
							monitorCoach,
							monitor,
							'Scroll all the way down to the affordability verdict.',
							ui.getTutorialHighlight("loan_scroll")
						);
					}

					return;
				}

				if (loanVerdictAtBottom(ui, "MARGINAL"))
				{
					guidePhase = GUIDE_LOAN_PREP_COMFORTABLE;
					loanRateGuideSubStep = 0;
					guideShownForPhase = -1;
					return;
				}

				var marginalKey = guidePhase * 10 + loanRateGuideSubStep + 1;
				if (guideShownForPhase != marginalKey)
				{
					guideShownForPhase = marginalKey;
					showMonitorPhaseCoach(
						monitorCoach,
						monitor,
						'Check the verdict — it should say Marginal.',
						ui.getTutorialHighlight("loan_calc_payment")
					);
				}

				return;
			}
		}

		if (guidePhase == GUIDE_LOAN_TERM_FINAL)
		{
			if (loanTermMatches(ui, LOAN_TERM_FINAL))
			{
				guidePhase = GUIDE_LOAN_SUBMIT;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Enter the term as 24 months.',
					ui.getTutorialHighlight("loan_term")
				);
			}

			return;
		}

		if (guidePhase == GUIDE_LOAN_SUBMIT)
		{
			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Looks good — hit SUBMIT FOR APPROVAL.',
					ui.getTutorialHighlight("loan_submit_button")
				);
			}
		}
	}

	public function notifyLoanSubmitted():Void
	{
		if (guidePhase == GUIDE_LOAN_SUBMIT)
		{
			guidePhase = GUIDE_LOAN_FOLDER_INTRO;
			guideShownForPhase = -1;
			folderIntroDialogPending = true;
		}
	}

	public function needsChefIdHandoff():Bool
	{
		return guidePhase == GUIDE_LOAN_FOLDER_INTRO && !folderIdHandedOff;
	}

	public function markChefIdHandedOff():Void
	{
		folderIdHandedOff = true;
	}

	public function getLoanTutorialClickFilter(ui:MonitorScreenUi):Null<Float->Float->Bool>
	{
		if (!isLoanGuideActive())
			return null;

		var self = this;
		return function(px:Float, py:Float):Bool
		{
			return self.isLoanMonitorClickAllowed(px, py, ui);
		};
	}

	public function showLoanWrongClickCoach(monitorCoach:TutorialGuideOverlay, monitor:MonitorOverlay, ui:MonitorScreenUi,
			px:Float, py:Float):Void
	{
		if (guidePhase == GUIDE_LOAN_MAIN_MENU && ui.isOnMainMenu())
		{
			showMonitorPhaseCoach(monitorCoach, monitor, 'No — open Loan Application.');
			return;
		}

		if (isLoanGuideActive() && guidePhase < GUIDE_LOAN_SUBMIT && ui.isTutorialLoanSubmitClick(px, py))
		{
			showMonitorPhaseCoach(monitorCoach, monitor, 'Not yet — finish the guided steps before submitting.');
			return;
		}

		if (guidePhase == GUIDE_LOAN_FOLDER && ui.isOnLoanApplication() && !ui.isOnLoanNewForm()
			&& (lastFolderGuideContext == null || folderGuideHintKey(lastFolderGuideContext) != 450)
			&& ui.isTutorialLoanMenuClick(px, py, 3))
		{
			showMonitorPhaseCoach(monitorCoach, monitor, 'Not yet — complete the folder first.');
		}
	}

	function isLoanMonitorClickAllowed(px:Float, py:Float, ui:MonitorScreenUi):Bool
	{
		if (!ui.isOnMainMenu() && !ui.isOnLoanApplication())
			return ui.isTutorialBackClick(px, py);

		if (guidePhase == GUIDE_LOAN_MAIN_MENU && ui.isOnMainMenu())
			return ui.isTutorialMenuClick(px, py, "menu_loan_application");

		if (guidePhase == GUIDE_LOAN_NEW_APP && ui.isOnLoanApplication() && !ui.isOnLoanNewForm())
			return ui.isTutorialLoanMenuClick(px, py, 0);

		if (isLoanGuideActive() && guidePhase < GUIDE_LOAN_SUBMIT && ui.isTutorialLoanSubmitClick(px, py))
			return false;

		if (guidePhase == GUIDE_LOAN_FOLDER && ui.isOnLoanApplication() && !ui.isOnLoanNewForm())
		{
			var menuIndex = getFolderAllowedMenuIndex(lastFolderGuideContext);
			if (menuIndex >= 0)
				return ui.isTutorialLoanMenuClick(px, py, menuIndex);
			if (ui.isTutorialLoanMenuClick(px, py, 3))
				return false;
		}

		return true;
	}

	function loanNationalIdMatches(ui:MonitorScreenUi):Bool
	{
		return normalizeId(ui.getLoanFieldValue("nationalId")) == normalizeId(MANAGER_NATIONAL_ID);
	}

	function loanProductMatches(ui:MonitorScreenUi):Bool
	{
		return LoanProductRates.normalizeProduct(ui.getLoanFieldValue("loanType")) == LOAN_TARGET_PRODUCT;
	}

	function loanAmountMatches(ui:MonitorScreenUi):Bool
	{
		return loanNumericMatches(ui.getLoanFieldValue("amount"), LOAN_TARGET_AMOUNT);
	}

	function loanTermMatches(ui:MonitorScreenUi, term:Int):Bool
	{
		var raw = Std.parseInt(StringTools.trim(ui.getLoanFieldValue("term")));
		return raw == term;
	}

	function loanSalaryMatches(ui:MonitorScreenUi):Bool
	{
		return loanNumericMatches(ui.getLoanFieldValue("declaredSalary"), LOAN_MONTHLY_SALARY);
	}

	function loanSecurityMatches(ui:MonitorScreenUi):Bool
	{
		return LoanProductRates.normalizeSecurity(ui.getLoanFieldValue("security")) == "unsecured";
	}

	function loanExpensesMatch(ui:MonitorScreenUi):Bool
	{
		return loanNumericMatches(ui.getLoanFieldValue("spendHousing"), LOAN_SPEND_HOUSING)
			&& loanNumericMatches(ui.getLoanFieldValue("spendLiving"), LOAN_SPEND_LIVING)
			&& loanNumericMatches(ui.getLoanFieldValue("spendOther"), LOAN_SPEND_OTHER);
	}

	function loanVerdictAtBottom(ui:MonitorScreenUi, verdict:String):Bool
	{
		if (!ui.isLoanFormScrolledToBottom())
			return false;
		return ui.getLoanAffordabilityVerdict() == verdict;
	}

	function loanPaymentMatchesComfortable(payment:Float):Bool
	{
		var lo = LOAN_COMFORTABLE_PAYMENT - LOAN_COMFORTABLE_TOLERANCE;
		var hi = LOAN_COMFORTABLE_PAYMENT + LOAN_COMFORTABLE_TOLERANCE;
		return payment >= lo && payment <= hi;
	}

	function calculatorMatchesSalary(value:Float):Bool
	{
		return Math.abs(value - LOAN_MONTHLY_SALARY) < 1.0;
	}

	function loanNumericMatches(raw:String, target:Float):Bool
	{
		var n = Std.parseFloat(StringTools.trim(raw));
		if (n == null)
			return false;
		return Math.abs(n - target) < 0.5;
	}

	function normalizeId(raw:String):String
	{
		return StringTools.trim(raw).toUpperCase();
	}

	public function updateGuide(monitor:MonitorOverlay, deskCoach:TutorialGuideOverlay, monitorCoach:TutorialGuideOverlay,
			computerHighlight:TutorialGuideRect):Void
	{
		if (isBookGuideActive())
			return;

		if (guidePhase == GUIDE_NONE || guidePhase == GUIDE_BOOK_DONE)
		{
			deskCoach.hide();
			monitorCoach.hide();
			guideMonitorActive = false;
			return;
		}

		var monitorEngaged = monitor.isActive();
		var monitorReady = monitor.isShowing && !monitor.isAnimating;

		if (monitorEngaged)
			openingMonitor = false;

		if (guidePhase == GUIDE_DESK_OPEN_COMPUTER)
		{
			if (!monitorEngaged)
			{
				monitorCoach.hide();
				guideMonitorActive = false;
				if (!openingMonitor && guideShownForPhase != guidePhase)
				{
					guideShownForPhase = guidePhase;
					var openMsg = if (detailsShreddedRecovery)
						'Whoops, well, now you know how shredder works. Go ahead and open the computer again.'
					else
						'Click the computer to open the terminal.';
					deskCoach.showCoach(openMsg, null, false, null, true);
				}
				return;
			}

			if (detailsShreddedRecovery)
			{
				detailsShreddedRecovery = false;
				monitor.getScreenUi().openTutorialCitizen(CITIZEN_INDEX);
				guidePhase = GUIDE_MONITOR_PRINT;
				guideShownForPhase = -1;
				if (deskCoach.isShowing)
					deskCoach.hide(true);
				return;
			}

			guidePhase = monitorWelcomeSeen ? resumeMonitorGuidePhase : GUIDE_MONITOR_WELCOME;
			guideShownForPhase = -1;
			if (deskCoach.isShowing)
				deskCoach.hide(true);
		}

		if (!monitorEngaged)
		{
			if (openingMonitor)
			{
				monitorCoach.hide();
				guideMonitorActive = false;
				return;
			}

			if (deskCoach.isShowing)
				deskCoach.hide(true);
			monitorCoach.hide();
			guideMonitorActive = false;
			if (isMonitorGuidePhase())
			{
				saveMonitorGuideResume();
				wrongClientActive = false;
				guidePhase = GUIDE_DESK_OPEN_COMPUTER;
				guideShownForPhase = -1;
			}
			return;
		}

		if (deskCoach.isShowing)
			deskCoach.hide(true);
		guideMonitorActive = monitorReady;
		var ui = monitor.getScreenUi();

		if (updateWrongClientGuide(monitorCoach, monitor, ui))
			return;

		if (guidePhase == GUIDE_MONITOR_WELCOME)
		{
			if (monitorWelcomeSeen)
			{
				guidePhase = resumeMonitorGuidePhase;
				guideShownForPhase = -1;
				return;
			}

			if (!monitorCoach.isShowing)
				guideShownForPhase = -1;
			showMonitorWelcomeCoach(monitorCoach, monitor);
			return;
		}

		if (guidePhase == GUIDE_MONITOR_MAIN_MENU)
		{
			if (!ui.isOnMainMenu())
			{
				guidePhase = GUIDE_MONITOR_DATABASE;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'This is our greatest terminal. Do not be afraid of so many things in there — '
						+ 'it is really easy to get the hang of.\n\n'
						+ 'Let\'s explore Client Database — go ahead and open it.'
				);
			}

			return;
		}

		if (guidePhase == GUIDE_MONITOR_DATABASE)
		{
			if (!ui.isOnClientDatabase())
			{
				guidePhase = GUIDE_MONITOR_MAIN_MENU;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Here is the list of all our clients.\n\n'
						+ 'You can look someone up by national ID or by name — try to find me, ${managerDisplayName()}.'
				);
				ui.focusSearchField();
			}

			if (StringTools.trim(ui.getSearchQuery()).length > 0)
			{
				guidePhase = GUIDE_MONITOR_SEARCH;
				guideShownForPhase = -1;
			}
			return;
		}

		if (guidePhase == GUIDE_MONITOR_SEARCH)
		{
			if (!ui.isOnClientDatabase())
			{
				guidePhase = GUIDE_MONITOR_MAIN_MENU;
				guideShownForPhase = -1;
				return;
			}

			if (ui.getTutorialHighlight("client_row") != null)
			{
				guidePhase = GUIDE_MONITOR_SELECT;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Use the search box to narrow the list — try "${managerSearchHint()}" or ${managerDisplayName()}.'
				);
				ui.focusSearchField();
			}

			return;
		}

		if (guidePhase == GUIDE_MONITOR_SELECT)
		{
			if (!ui.isOnClientDatabase())
			{
				guidePhase = GUIDE_MONITOR_MAIN_MENU;
				guideShownForPhase = -1;
				return;
			}

			if (ui.getTutorialHighlight("client_row") == null)
			{
				guidePhase = GUIDE_MONITOR_SEARCH;
				guideShownForPhase = -1;
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Click my row in the list to open my full record.'
				);
			}

			return;
		}

		if (guidePhase == GUIDE_MONITOR_SALARY)
		{
			ui.setPrintButtonEnabled(false);

			if (!ui.isOnClientDetail())
			{
				guidePhase = GUIDE_MONITOR_SEARCH;
				guideShownForPhase = -1;
				return;
			}

			var selected = ui.getSelectedCitizen();
			if (selected != null && CitizenRegistry.indexOf(selected) != CITIZEN_INDEX)
				ui.openTutorialCitizen(CITIZEN_INDEX);

			refreshSalaryState(ui.getSelectedCitizen());

			if (salaryUpdated)
			{
				salaryRejectedMessage = null;
				unneededFieldEditMessage = null;
				guidePhase = GUIDE_MONITOR_PRINT;
				guideShownForPhase = -1;
				ui.setPrintButtonEnabled(true);
				return;
			}

			if (unneededFieldEditMessage != null)
			{
				showMonitorPhaseCoach(monitorCoach, monitor, unneededFieldEditMessage);
			}
			else if (salaryRejectedMessage != null)
			{
				showMonitorPhaseCoach(monitorCoach, monitor, salaryRejectedMessage);
			}
			else if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'This screen is my full client record in the bank system.\n\n'
						+ 'Find Annual Salary — it incorrectly shows zero. Change it to ${TARGET_SALARY} LOR, then confirm the edit.'
				);
			}

			return;
		}

		if (guidePhase == GUIDE_MONITOR_PRINT)
		{
			ui.setPrintButtonEnabled(true);

			if (!ui.isOnClientDetail())
			{
				guidePhase = GUIDE_MONITOR_SALARY;
				guideShownForPhase = -1;
				return;
			}

			if (detailsPrinted)
			{
				monitorCoach.hide();
				return;
			}

			if (guideShownForPhase != guidePhase)
			{
				guideShownForPhase = guidePhase;
				showMonitorPhaseCoach(
					monitorCoach,
					monitor,
					'Good. Now hit PRINT > — the paper lands on the printer by your desk.'
				);
			}
		}
	}
}
