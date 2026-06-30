package;

class ClientScenarios
{
	static inline var STEP_PLAYER = 0;
	static inline var STEP_CLIENT = 1;
	static inline var STEP_CHOICES = 2;
	static inline var STEP_PLAYER_PROMPT = 4;
	static inline var STEP_TUTORIAL_IDLE = 5;
	static inline var STEP_UNLOCK_SCAN_HINT = 6;
	static inline var STEP_END_VISIT = 7;
	static inline var STEP_TUTORIAL_CHOICES = 8;
	static inline var STEP_PREPARE_TUTORIAL_EXIT = 9;
	static inline var STEP_PASSPORT = 3;
	static inline var STEP_ID_HANDOFF = 10;

	static inline var CLIENT_1_CITIZEN_INDEX = 21;
	static inline var CLIENT_2_CITIZEN_INDEX = 1;
	static inline var CLIENT_3_CITIZEN_INDEX = 2;
	static inline var CLIENT_4_CITIZEN_INDEX = 22;
	static inline var CLIENT_5_CITIZEN_INDEX = 80;
	static inline var VADZIM_TARGET_ANNUAL = 85240.82;
	static inline var VADZIM_ANNUAL_TOLERANCE = 2.0;
	static inline var KETHRAN_CITIZEN_INDEX = 40;
	static inline var KETHRAN_CONTRACT_KTH = 185000.0;
	static inline var KTH_PER_LOR = 68.42;
	static inline var KETHRAN_TARGET_ANNUAL = 32446.0;
	static inline var KETHRAN_ANNUAL_TOLERANCE = 100.0;
	static inline var FRAUD_CITIZEN_INDEX = 81;
	static inline var FRAUD_ID_CITIZEN_INDEX = 7;

	public static function count():Int
	{
		return 8;
	}

	public static inline var LAST_PLAYABLE_CLIENT_INDEX = 4;

	public static function get(index:Int):ClientScenario
	{
		return switch (index)
		{
			case 0: chefTutorial();
			case 1: clientOneWedding();
			case 2: clientTwoDenis();
			case 3: clientThree();
			case 4: clientFour();
			case 5: vadzimSalaryAndLoan();
			case 6: yerasylSalaryUpdate();
			case 7: ostmarkIdentityFraud();
			default: clientOneWedding();
		}
	}

	static function chefTutorial():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/chef.png",
			0,
			false,
			false,
			null,
			0,
			"",
			"",
			[],
			0,
			0,
			0,
			0,
			0,
			true
		);
	}

	static function clientOneWedding():ClientScenario
	{
		return fromCitizenIndex(CLIENT_1_CITIZEN_INDEX, "static/Clients/client1.png", Lorian);
	}

	static function clientTwoDenis():ClientScenario
	{
		return fromCitizenIndex(CLIENT_2_CITIZEN_INDEX, "static/Clients/client2.png");
	}

	static function clientThree():ClientScenario
	{
		return fromCitizenIndex(CLIENT_3_CITIZEN_INDEX, "static/Clients/client3.png");
	}

	static function clientFour():ClientScenario
	{
		return fromCitizenIndex(CLIENT_4_CITIZEN_INDEX, "static/Clients/client4.png");
	}

	static function vadzimSalaryAndLoan():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client5.png",
			CLIENT_5_CITIZEN_INDEX,
			false,
			true,
			Ostmark,
			40000,
			"personal",
			"unsecured",
			[],
			0,
			0,
			0,
			0,
			0,
			false,
			Ostmark,
			-1,
			VADZIM_TARGET_ANNUAL,
			VADZIM_ANNUAL_TOLERANCE,
			false,
			true,
			false
		);
	}

	public static function fromCitizenIndex(citizenIndex:Int, ?portraitPath:String, ?idVariant:Null<IdCardVariant> = null):ClientScenario
	{
		if (citizenIndex < 0 || citizenIndex >= CitizenRegistry.all.length)
			return peterWeddingFallback();

		return CitizenVisitBuilder.scenarioFrom(
			CitizenRegistry.all[citizenIndex],
			citizenIndex,
			portraitPath,
			idVariant
		);
	}

	static function peterWeddingFallback():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client1.png",
			CLIENT_1_CITIZEN_INDEX,
			false,
			false,
			Lorian,
			35000,
			"personal",
			"secured",
			[23, 24, 25],
			1600,
			100,
			1200,
			900,
			200,
			false,
			null,
			-1,
			0,
			100,
			false,
			true,
			false
		);
	}

	static function yerasylSalaryUpdate():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client6.png",
			KETHRAN_CITIZEN_INDEX,
			false,
			true,
			Lorian,
			0,
			"",
			"",
			[],
			0,
			0,
			0,
			0,
			0,
			false,
			Kethran,
			-1,
			KETHRAN_TARGET_ANNUAL,
			KETHRAN_ANNUAL_TOLERANCE,
			false,
			true,
			false
		);
	}

	static function ostmarkIdentityFraud():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client7.png",
			FRAUD_CITIZEN_INDEX,
			false,
			true,
			Ostmark,
			40000,
			"personal",
			"unsecured",
			[],
			0,
			0,
			0,
			0,
			0,
			false,
			null,
			FRAUD_ID_CITIZEN_INDEX,
			0,
			100,
			false,
			true,
			true
		);
	}

	public static function openingConvStepsFor(scenario:ClientScenario):Null<Array<ClientConvStep>>
	{
		var dialogue = citizenDialogue(scenario.citizenIndex);
		if (dialogue != null && CitizenVisitBuilder.stringArrayField(dialogue, "opening").length > 0)
			return openingStepsFromDialogue(dialogue);
		return null;
	}

	static function openingStepsFromDialogue(dialogue:Dynamic):Array<ClientConvStep>
	{
		var steps:Array<ClientConvStep> = [];
		for (line in CitizenVisitBuilder.stringArrayField(dialogue, "opening"))
			steps.push({type: STEP_CLIENT, text: line});
		steps.push({type: STEP_ID_HANDOFF, text: ""});
		steps.push({type: STEP_CHOICES, text: ""});
		return steps;
	}


	public static function chefTutorialIdReturnThanksSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Thanks. Good luck."},
			{type: STEP_END_VISIT, text: ""}
		];
	}

	public static function openingMessagesFor(scenario:ClientScenario):Array<String>
	{
		if (scenario.silent)
			return [];

		if (scenario.citizenIndex == 0 && scenario.isTutorial)
			return [];

		var scripted = citizenDialogue(scenario.citizenIndex);
		if (scripted != null && CitizenVisitBuilder.stringArrayField(scripted, "opening").length > 0)
			return CitizenVisitBuilder.stringArrayField(scripted, "opening");

		if (scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
		{
			return [
				"Hi — I need my salary corrected in your database.",
				"Here's my Kethran ID and job contract.",
				"The contract lists one hundred eighty-five thousand KTH.",
				"That's my monthly salary — not annual.",
				"Please fix my annual salary to match."
			];
		}

		if (scenario.identityFraud)
		{
			return [
				"Hey. I need a loan. Today.",
				"Forty thousand LOR — personal, unsecured.",
				"Can we hurry? I'm late.",
				"Here's my ID."
			];
		}

		return ["Hello!", "How are you?", "Nice weather outside, huh?"];
	}

	public static function thanksMessagesFor(scenario:ClientScenario):Array<String>
	{
		var scriptedThanks = citizenDialogue(scenario.citizenIndex);
		if (scriptedThanks != null && CitizenVisitBuilder.stringArrayField(scriptedThanks, "thanks").length > 0)
			return CitizenVisitBuilder.stringArrayField(scriptedThanks, "thanks");

		if (scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
		{
			return [
				"Perfect — that's what I needed.",
				"Thanks for fixing it.",
				"Have a good shift!"
			];
		}

		if (scenario.identityFraud)
		{
			return [
				"...fine.",
				"Just give me my papers back."
			];
		}

		return ["Thanks.", "Goodbye."];
	}

	public static function allowsPassportRequestChoiceFor(scenario:ClientScenario):Bool
	{
		return false;
	}

	public static function passportRequestStepsFor(?scenario:ClientScenario):Array<ClientConvStep>
	{
		if (scenario != null && scenario.isTutorial)
		{
			return chefTutorialLoanQuestionSteps("passport_request",
				"You don't need my passport — we're just walking through the application.");
		}

		if (scenario != null && scenario.passportIncludedInOpening)
		{
			return [
				{type: STEP_PLAYER, text: "Can I see your passport?"},
				{type: STEP_CLIENT, text: "Uhh, I gave it already."},
				{type: STEP_CHOICES, text: ""}
			];
		}

		return [
			{type: STEP_PLAYER, text: "Can I see your passport?"},
			{type: STEP_CLIENT, text: "We are not using passports right now."},
			{type: STEP_CHOICES, text: ""}
		];
	}

	public static function fraudConfrontationSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_PLAYER, text: "This ID isn't yours."},
			{type: STEP_CLIENT, text: "...Look, can we not do this here?"},
			{type: STEP_PLAYER, text: "The name and photo don't match you."},
			{type: STEP_CLIENT, text: "Fine. Just... give me my documents back."},
			{type: STEP_CHOICES, text: ""}
		];
	}

	public static function kethranSalaryCompleteSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Annual salary looks right now — thanks."},
			{type: STEP_CLIENT, text: "Could I have my documents back when you're done?"},
			{type: STEP_CHOICES, text: ""}
		];
	}

	public static function smallTalkChoiceLabelFor(scenario:ClientScenario):Null<String>
	{
		if (scenario.silent)
			return null;

		if (scenario.isTutorial)
			return null;

		var scripted = citizenDialogue(scenario.citizenIndex);
		var smallTalkLabel = CitizenVisitBuilder.stringField(scripted, "small_talk_label");
		if (smallTalkLabel != null && smallTalkLabel.length > 0)
			return smallTalkLabel;

		if (scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
			return "How's work at the school?";

		if (scenario.identityFraud)
			return "Lovely weather for a loan, huh?";

		return "Nice weather today, huh?";
	}

	public static function chefTutorialIntroBaseSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Hey, I'm your new manager. Folks call me Chef."},
			{type: STEP_CLIENT, text: "First day on the floor — wanted to see how you're doing."},
			{type: STEP_PLAYER_PROMPT, text: "Nice to meet you"},
			{type: STEP_CLIENT, text: "Just to make sure you remember your job, I'll coach you a bit."}
		];
	}

	public static function chefTutorialIdleStep():ClientConvStep
	{
		return {type: STEP_TUTORIAL_IDLE, text: ""};
	}

	public static function chefTutorialHomeworkSteps(ctx:ChefTutorialContext):Array<ClientConvStep>
	{
		var steps:Array<ClientConvStep> = [
			{type: STEP_CLIENT, text: 'Pull up my record — ${ChefTutorial.managerDisplayName()}.'}
		];

		if (!ctx.salaryUpdated)
		{
			steps.push({type: STEP_CLIENT, text: "Salary shows zero. Fix it to 42,000 LOR."});
			return steps;
		}

		steps.push({type: STEP_CLIENT, text: "Salary already shows 42,000 LOR — good."});

		if (!ctx.detailsPrinted)
		{
			for (step in chefTutorialPrintSteps(false))
			{
				if (step.type == STEP_TUTORIAL_IDLE)
					continue;
				steps.push(step);
			}
			return steps;
		}

		return steps;
	}

	public static function chefTutorialPrintSteps(ackSalary:Bool):Array<ClientConvStep>
	{
		if (ackSalary)
		{
			return [
				{type: STEP_CLIENT, text: "Salary's corrected — good."},
				{type: STEP_CLIENT, text: "Now hit Print on my record."},
				{type: STEP_TUTORIAL_IDLE, text: ""}
			];
		}

		return [
			{type: STEP_CLIENT, text: "Hit Print on my record."},
			{type: STEP_TUTORIAL_IDLE, text: ""}
		];
	}

	public static function chefTutorialGuideBookSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "For things like that, we have our beloved guide book."},
			{type: STEP_TUTORIAL_IDLE, text: ""}
		];
	}

	public static function chefTutorialDeclineSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Fair enough — didn't mean to hold you up."},
			{type: STEP_CLIENT, text: "Handbook pages 33–35 cover the loan process. Pages 92–94 cover currency math."},
			{type: STEP_CLIENT, text: "I'll check in later. Good luck out there."},
			{type: STEP_PREPARE_TUTORIAL_EXIT, text: ""},
			{type: STEP_END_VISIT, text: ""}
		];
	}

	public static function smallTalkStepsFor(scenario:ClientScenario):Null<Array<ClientConvStep>>
	{
		if (scenario.silent)
			return null;

		if (scenario.isTutorial)
			return null;

		var scripted = citizenDialogue(scenario.citizenIndex);
		var smallTalkLabel = CitizenVisitBuilder.stringField(scripted, "small_talk_label");
		var smallTalkLines = CitizenVisitBuilder.stringArrayField(scripted, "small_talk");
		if (scripted != null && smallTalkLabel != null && smallTalkLines.length > 0)
		{
			var steps:Array<ClientConvStep> = [
				{type: STEP_PLAYER, text: smallTalkLabel}
			];
			for (line in smallTalkLines)
				steps.push({type: STEP_CLIENT, text: line});
			steps.push({type: STEP_CHOICES, text: ""});
			return steps;
		}

		if (scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
		{
			return [
				{type: STEP_PLAYER, text: "How's work at the school?"},
				{type: STEP_CLIENT, text: "Busy — but the pay paperwork is the real headache."},
				{type: STEP_CLIENT, text: "That's why I'm here."},
				{type: STEP_CHOICES, text: ""}
			];
		}

		if (scenario.identityFraud)
		{
			return [
				{type: STEP_PLAYER, text: "Lovely weather for a loan, huh?"},
				{type: STEP_CLIENT, text: "Sure. Can we skip the small talk?"},
				{type: STEP_CLIENT, text: "I said I'm in a hurry."},
				{type: STEP_CHOICES, text: ""}
			];
		}

		return [
			{type: STEP_PLAYER, text: "Nice weather today, huh?"},
			{type: STEP_CLIENT, text: "Yeah, can't complain!"},
			{type: STEP_CHOICES, text: ""}
		];
	}

	public static function bookScanStepsFor(?scenario:ClientScenario, actionId:String, timesAskedPreviously:Int):Null<Array<ClientConvStep>>
	{
		if (actionId == "confirm_name")
			return confirmNameSteps(scenario);

		if (timesAskedPreviously > 0)
		{
			var repeat = repeatBookScanSteps(scenario, actionId, timesAskedPreviously);
			if (repeat != null)
				return repeat;
		}

		if (scenario != null)
		{
			var first = firstTimeBookScanSteps(scenario, actionId);
			if (first != null)
				return first;
		}

		if (actionId == "passport_request")
			return passportRequestStepsFor(scenario);

		if (scenario == null)
			return defaultFirstTimeSteps(actionId);

		return null;
	}

	static function firstTimeBookScanSteps(scenario:ClientScenario, actionId:String):Null<Array<ClientConvStep>>
	{
		if (scenario.citizenIndex == 0 && scenario.isTutorial)
			return chefTutorialBookScanSteps(actionId);

		if (scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
			return kethranBookScanSteps(actionId);

		if (scenario.identityFraud)
			return fraudBookScanSteps(actionId);

		var scripted = citizenDialogue(scenario.citizenIndex);
		if (scripted != null)
		{
			var scriptedSteps = visitDialogueBookScanSteps(actionId, scripted);
			if (scriptedSteps != null)
				return scriptedSteps;
		}

		return defaultFirstTimeSteps(actionId);
	}

	static function kethranBookScanSteps(actionId:String):Null<Array<ClientConvStep>>
	{
		var monthlyLor = Math.round(KETHRAN_CONTRACT_KTH / KTH_PER_LOR);
		return switch (actionId)
		{
			case "annual_salary":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Use the contract — one hundred eighty-five thousand KTH."},
					{type: STEP_CLIENT, text: "Remember, that's monthly. Convert to LOR and multiply by twelve."},
					{type: STEP_CHOICES, text: ""}
				];
			case "monthly_salary":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: 'Divide one hundred eighty-five thousand KTH by ${KTH_PER_LOR} — about ${monthlyLor} LOR a month.'},
					{type: STEP_CHOICES, text: ""}
				];
			case "borrow_amount":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "I'm not here for a loan — just the salary update."},
					{type: STEP_CHOICES, text: ""}
				];
			case "loan_purpose":
				kethranNonLoanStep(actionId);
			case "loan_security":
				kethranNonLoanStep(actionId);
			case "living_expenses":
				kethranNonLoanStep(actionId);
			case "comfortable_rate":
				kethranNonLoanStep(actionId);
			default:
				null;
		}
	}

	static function kethranNonLoanStep(actionId:String):Array<ClientConvStep>
	{
		return [
			{type: STEP_PLAYER, text: playerLine(actionId)},
			{type: STEP_CLIENT, text: "No loan today — please fix my annual salary in the database."},
			{type: STEP_CHOICES, text: ""}
		];
	}

	static function fraudBookScanSteps(actionId:String):Null<Array<ClientConvStep>>
	{
		return switch (actionId)
		{
			case "borrow_amount":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Forty thousand LOR. Personal."},
					{type: STEP_CLIENT, text: "Can we please move faster?"},
					{type: STEP_CHOICES, text: ""}
				];
			case "loan_purpose":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Personal expenses. Look, just process it."},
					{type: STEP_CHOICES, text: ""}
				];
			case "loan_security":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Unsecured. I don't have time for collateral talk."},
					{type: STEP_CHOICES, text: ""}
				];
			case "annual_salary":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Check your database — I'm in a rush."},
					{type: STEP_CHOICES, text: ""}
				];
			case "monthly_salary":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Whatever's on file. Divide by twelve if you need monthly."},
					{type: STEP_CHOICES, text: ""}
				];
			case "living_expenses":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Normal stuff. Can we finish this?"},
					{type: STEP_CHOICES, text: ""}
				];
			case "comfortable_rate":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Something I can pay. Just hurry."},
					{type: STEP_CHOICES, text: ""}
				];
			default:
				null;
		}
	}

	static function chefTutorialBookScanSteps(actionId:String):Null<Array<ClientConvStep>>
	{
		return switch (actionId)
		{
			case "verify_client_details":
				[
					{type: STEP_PLAYER, text: "Alright, I can see that the salary is looking correct now, great."},
					{type: STEP_CLIENT, text: "Great!"},
					{type: STEP_CLIENT, text: "Now we gonna walk through the loan application."},
					{type: STEP_TUTORIAL_IDLE, text: ""}
				];
			case "borrow_amount":
				chefTutorialLoanQuestionSteps(actionId,
					'I think I already told you — it\'s ${LoanAffordabilityCalculator.formatLorDisplay(ChefTutorial.LOAN_TARGET_AMOUNT)} LOR.');
			case "loan_purpose":
				chefTutorialLoanQuestionSteps(actionId, "Personal — same as on the application.");
			case "loan_security":
				chefTutorialLoanQuestionSteps(actionId, "Not secured, please.");
			case "living_expenses":
				chefTutorialLoanQuestionSteps(actionId, "About 700 for housing, 400 living, and 150 other.");
			case "comfortable_rate":
				chefTutorialLoanQuestionSteps(actionId, "Around 1,200 LOR a month.");
			case "annual_salary":
				chefTutorialLoanQuestionSteps(actionId, "42,000 LOR — you just fixed that for me.");
			case "monthly_salary":
				chefTutorialLoanQuestionSteps(actionId, "Annual divided by twelve.");
			case "passport_request":
				chefTutorialLoanQuestionSteps(actionId,
					"You don't need my passport — we're just walking through the application.");
			default:
				null;
		}
	}

	static function chefTutorialQuestionSteps(actionId:String, answer:String):Array<ClientConvStep>
	{
		var steps:Array<ClientConvStep> = [
			{type: STEP_PLAYER, text: playerLine(actionId)},
			{type: STEP_CLIENT, text: answer}
		];
		if (ChefTutorial.pendingBookScanFarewell)
			for (step in chefTutorialFarewellSteps())
				steps.push(step);
		else
			steps.push({type: STEP_CHOICES, text: ""});
		return steps;
	}

	static function chefTutorialLoanQuestionSteps(actionId:String, answer:String):Array<ClientConvStep>
	{
		return [
			{type: STEP_PLAYER, text: playerLine(actionId)},
			{type: STEP_CLIENT, text: answer},
			{type: STEP_TUTORIAL_IDLE, text: ""}
		];
	}

	static function chefTutorialFarewellSteps():Array<ClientConvStep>
	{
		var steps:Array<ClientConvStep> = [];
		for (step in chefTutorialLoanOverviewSteps())
			steps.push(step);
		steps.push({type: STEP_CLIENT, text: "I'll be around if you need me. Back to my desk."});
		steps.push({type: STEP_END_VISIT, text: ""});
		return steps;
	}

	public static function chefTutorialFolderIntroSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Okay, this is the folder where you have to submit all documents related to the loan."},
			{type: STEP_CLIENT, text: "For that you will need proof of my identity — there you go."},
			{type: STEP_ID_HANDOFF, text: ""},
			{type: STEP_TUTORIAL_IDLE, text: ""}
		];
	}

	public static function chefTutorialFolderCompletionSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "That's it! Nice work."},
			{type: STEP_CLIENT, text: "Give me my ID back — drop it on my side of the window."},
			{type: STEP_PREPARE_TUTORIAL_EXIT, text: ""},
			{type: STEP_TUTORIAL_IDLE, text: ""}
		];
	}

	static function chefTutorialLoanOverviewSteps():Array<ClientConvStep>
	{
		return [
			{type: STEP_CLIENT, text: "Good — you've got the tools. Here's the real loan process."},
			{type: STEP_CLIENT, text: "Step 1 — Intake. Listen. They hand over their ID. Note the amount they want."},
			{type: STEP_CLIENT, text: "Step 2 — Gather. Scan questions from pages 31–32. Write every number down."},
			{type: STEP_CLIENT, text: "Step 3 — Terminal. Computer → Loan Application → New Application."},
			{type: STEP_CLIENT, text: "Fill every field. Monthly salary = annual ÷ 12. Verdict must be green Affordable."},
			{type: STEP_CLIENT, text: "Hit SUBMIT. A loan folder slides onto your desk."},
			{type: STEP_CLIENT, text: "Step 4 — Folder. Print copies of ID, application form, and checklist."},
			{type: STEP_CLIENT, text: "Drag copies into the folder — not originals. Three items total."},
			{type: STEP_CLIENT, text: "Step 5 — Submit for Approval from the terminal when the folder is complete."},
			{type: STEP_CLIENT, text: "Foreign pay? Open Currency Exchange. Divide the foreign amount by the rate to get LOR."},
			{type: STEP_CLIENT, text: "Example: 68.42 KTH = 1 LOR. So 185,000 KTH ÷ 68.42 ≈ 2,700 LOR a month."},
			{type: STEP_CLIENT, text: "Annual salary in LOR = monthly × 12. Handbook pages 33–35 have a cheat sheet."},
			{type: STEP_CLIENT, text: "Your first real client should be here soon. Read pages 33–35 before they arrive."}
		];
	}

	static function confirmNameSteps(?scenario:ClientScenario):Array<ClientConvStep>
	{
		var name = "…";
		if (scenario != null && scenario.citizenIndex >= 0 && scenario.citizenIndex < CitizenRegistry.all.length)
			name = CitizenRegistry.displayName(CitizenRegistry.all[scenario.citizenIndex]);

		return [
			{type: STEP_PLAYER, text: BookScanActions.confirmNameQuestion(name)},
			{type: STEP_CLIENT, text: "Yep, that's right"},
			{type: STEP_CHOICES, text: ""}
		];
	}

	static function repeatBookScanSteps(?scenario:ClientScenario, actionId:String, timesAskedPreviously:Int):Null<Array<ClientConvStep>>
	{
		var player = playerLine(actionId);
		var quick = quickAnswerFor(scenario, actionId);
		if (player == null || quick == null)
			return null;

		var annoyance = timesAskedPreviously == 1
			? "Didn't I already tell you that?"
			: "Uh...";

		return [
			{type: STEP_PLAYER, text: player},
			{type: STEP_CLIENT, text: annoyance},
			{type: STEP_CLIENT, text: quick},
			{type: STEP_CHOICES, text: ""}
		];
	}

	static function quickAnswerFor(?scenario:ClientScenario, actionId:String):Null<String>
	{
		if (scenario != null && scenario.citizenIndex == 0 && scenario.isTutorial)
		{
			return switch (actionId)
			{
				case "borrow_amount":
					'I think I already told you — it\'s ${LoanAffordabilityCalculator.formatLorDisplay(ChefTutorial.LOAN_TARGET_AMOUNT)} LOR.';
				case "loan_purpose": "Personal — check the application.";
				case "loan_security": "Not secured.";
				case "living_expenses": "700 housing, 400 living, 150 other.";
				case "comfortable_rate": "About 1,600 LOR a month.";
				case "annual_salary": "42,000 LOR — check the system.";
				case "monthly_salary": "Annual divided by twelve.";
				case "passport_request": "No passport needed — we're just practicing the application.";
				default: null;
			};
		}

		if (scenario != null)
		{
			var scripted = citizenDialogue(scenario.citizenIndex);
			var quick = CitizenVisitBuilder.quickAnswer(scripted, actionId);
			if (quick != null)
				return quick;
		}

		if (scenario != null && scenario.citizenIndex == KETHRAN_CITIZEN_INDEX)
		{
			var monthlyLor = Math.round(KETHRAN_CONTRACT_KTH / KTH_PER_LOR);
			return switch (actionId)
			{
				case "annual_salary": "One eighty-five thousand KTH monthly — convert and multiply by twelve.";
				case "monthly_salary": 'About ${monthlyLor} LOR — divide the KTH by ${KTH_PER_LOR}.';
				case "borrow_amount": "No loan — salary update only.";
				default: null;
			};
		}

		if (scenario != null && scenario.identityFraud)
		{
			return switch (actionId)
			{
				case "borrow_amount": "40,000 LOR — hurry up.";
				case "loan_purpose": "Personal.";
				case "loan_security": "Unsecured.";
				default: null;
			};
		}

		return switch (actionId)
		{
			case "borrow_amount": "Uhh around 3000 LOR.";
			case "passport_request":
				scenario != null && scenario.passportIncludedInOpening
					? "Uhh, I gave it already."
					: "You already have it.";
			default: null;
		};
	}

	static function defaultFirstTimeSteps(actionId:String):Null<Array<ClientConvStep>>
	{
		return switch (actionId)
		{
			case "borrow_amount":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Uhh around 3000 LOR."},
					{type: STEP_CLIENT, text: "For an electro bike, haha."},
					{type: STEP_CHOICES, text: ""}
				];
			default:
				null;
		};
	}

	static function visitDialogueBookScanSteps(actionId:String, dialogue:Dynamic):Null<Array<ClientConvStep>>
	{
		return switch (actionId)
		{
			case "borrow_amount":
				bookScanReply(actionId, CitizenVisitBuilder.stringField(dialogue, "borrow_amount"));
			case "loan_purpose":
				bookScanReply(actionId, CitizenVisitBuilder.stringField(dialogue, "loan_purpose"));
			case "loan_security":
				if (CitizenVisitBuilder.boolField(dialogue, "loan_security_unsure"))
				{
					[
						{type: STEP_PLAYER, text: playerLine(actionId)},
						{type: STEP_CLIENT, text: "Um... what's that mean?"},
						{type: STEP_PLAYER, text: "Secured — collateral for a lower rate."},
						{type: STEP_PLAYER, text: "Unsecured costs more, no collateral needed."},
						{type: STEP_CLIENT, text: CitizenVisitBuilder.stringField(dialogue, "loan_security_answer") != null
							? CitizenVisitBuilder.stringField(dialogue, "loan_security_answer")
							: "Unsecured is fine."},
						{type: STEP_CHOICES, text: ""}
					];
				}
				else
				{
					var security = CitizenVisitBuilder.stringField(dialogue, "loan_security");
					bookScanReply(actionId, security == "secured" ? "Secured, please." : "Unsecured, please.");
				}
			case "living_expenses":
				livingExpenseSteps(actionId, CitizenVisitBuilder.stringArrayField(dialogue, "living_expenses"));
			case "comfortable_rate":
				bookScanReply(actionId, CitizenVisitBuilder.stringField(dialogue, "comfortable_rate"));
			case "annual_salary":
				bookScanReply(actionId, CitizenVisitBuilder.stringField(dialogue, "annual_salary"));
			case "monthly_salary":
				monthlySalarySteps(actionId, CitizenVisitBuilder.stringField(dialogue, "monthly_salary"));
			default:
				null;
		}
	}

	static function bookScanReply(actionId:String, answer:String):Array<ClientConvStep>
	{
		return [
			{type: STEP_PLAYER, text: playerLine(actionId)},
			{type: STEP_CLIENT, text: answer},
			{type: STEP_CHOICES, text: ""}
		];
	}

	static function livingExpenseSteps(actionId:String, lines:Array<String>):Null<Array<ClientConvStep>>
	{
		if (lines.length == 0)
			return null;

		var steps:Array<ClientConvStep> = [{type: STEP_PLAYER, text: playerLine(actionId)}];
		for (line in lines)
			steps.push({type: STEP_CLIENT, text: line});
		steps.push({type: STEP_CHOICES, text: ""});
		return steps;
	}

	static function monthlySalarySteps(actionId:String, answer:String):Array<ClientConvStep>
	{
		return bookScanReply(actionId, answer);
	}

	static function citizenDialogue(citizenIndex:Int):Dynamic
	{
		if (citizenIndex < 0 || citizenIndex >= CitizenRegistry.all.length)
			return null;
		return CitizenVisitBuilder.dialogueFor(CitizenRegistry.all[citizenIndex]);
	}

	static function playerLine(actionId:String):Null<String>
	{
		return BookScanActions.questionMessage(actionId);
	}
}
