package;

class ClientScenarios
{
	static inline var STEP_PLAYER = 0;
	static inline var STEP_CLIENT = 1;
	static inline var STEP_CHOICES = 2;

	public static function count():Int
	{
		return 2;
	}

	public static function get(index:Int):ClientScenario
	{
		return switch (index)
		{
			case 0: peterWedding();
			case 1: walterSilent();
			default: peterWedding();
		}
	}

	static function peterWedding():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client1.png",
			14,
			false,
			true,
			Lorian,
			35000,
			"personal",
			"secured",
			[24, 25],
			1600,
			100,
			1200,
			900,
			200
		);
	}

	static function walterSilent():ClientScenario
	{
		return new ClientScenario(
			"static/Clients/client2.png",
			2,
			true,
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
			0
		);
	}

	public static function openingMessagesFor(scenario:ClientScenario):Array<String>
	{
		if (scenario.silent)
			return [];

		if (scenario.citizenIndex == 14)
		{
			return [
				"Hey! How are you doing today?",
				"I need to get a loan sorted soon — planning my wedding!",
				"My fiancée sent me a wishlist the size of a phone book, haha.",
				"I'll need around 35,000 LOR to make it happen.",
				"Oh — here's my ID and passport, by the way."
			];
		}

		return ["Hello!", "How are you?", "Nice weather outside, huh?"];
	}

	public static function thanksMessagesFor(scenario:ClientScenario):Array<String>
	{
		if (scenario.citizenIndex == 14)
		{
			return [
				"Thank you so much!",
				"My fiancée is going to love this.",
				"Have a great day!"
			];
		}
		return ["Thanks.", "Goodbye."];
	}

	public static function smallTalkChoiceLabelFor(scenario:ClientScenario):Null<String>
	{
		if (scenario.silent)
			return null;

		if (scenario.citizenIndex == 14)
			return "How's the wedding planning?";

		return "Nice weather today, huh?";
	}

	public static function smallTalkStepsFor(scenario:ClientScenario):Null<Array<ClientConvStep>>
	{
		if (scenario.silent)
			return null;

		if (scenario.citizenIndex == 14)
		{
			return [
				{type: STEP_PLAYER, text: "How's the wedding planning going?"},
				{type: STEP_CLIENT, text: "Honestly? Stressful — but exciting! The wishlist keeps growing though."},
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
		if (timesAskedPreviously > 0)
		{
			var repeat = repeatBookScanSteps(scenario, actionId, timesAskedPreviously);
			if (repeat != null)
				return repeat;
		}

		if (scenario == null)
			return defaultFirstTimeSteps(actionId);

		return firstTimeBookScanSteps(scenario, actionId);
	}

	static function firstTimeBookScanSteps(scenario:ClientScenario, actionId:String):Null<Array<ClientConvStep>>
	{
		if (scenario.citizenIndex != 14)
			return defaultFirstTimeSteps(actionId);

		return switch (actionId)
		{
			case "borrow_amount":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Around 35,000 LOR — that should cover the wedding wishlist!"},
					{type: STEP_CHOICES, text: ""}
				];
			case "loan_purpose":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "The wedding! Venue, catering, the whole celebration."},
					{type: STEP_CHOICES, text: ""}
				];
			case "loan_security":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Um... what's that mean?"},
					{type: STEP_PLAYER, text: "Secured means you pledge collateral for a lower rate. Unsecured costs more but needs no collateral."},
					{type: STEP_CLIENT, text: "Oh! Well, in this case let's make it secure."},
					{type: STEP_CHOICES, text: ""}
				];
			case "living_expenses":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "Rent's about 1,200, living costs maybe 900, and other stuff around 200."},
					{type: STEP_CLIENT, text: "Should be fine for the loan, right?"},
					{type: STEP_CHOICES, text: ""}
				];
			case "comfortable_rate":
				[
					{type: STEP_PLAYER, text: playerLine(actionId)},
					{type: STEP_CLIENT, text: "I'd like to keep it close to 1,600 LOR per month — plus or minus about 100."},
					{type: STEP_CHOICES, text: ""}
				];
			default:
				null;
		}
	}

	static function repeatBookScanSteps(?scenario:ClientScenario, actionId:String, timesAskedPreviously:Int):Null<Array<ClientConvStep>>
	{
		var player = playerLine(actionId);
		var quick = quickAnswerFor(scenario, actionId);
		if (player == null || quick == null)
			return null;

		var annoyance = timesAskedPreviously == 1
			? "Didn't I already answered you that?"
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
		if (scenario != null && scenario.citizenIndex == 14)
		{
			return switch (actionId)
			{
				case "borrow_amount": "It's 35,000 LOR.";
				case "loan_purpose": "For the wedding.";
				case "loan_security": "It should be secured.";
				case "living_expenses": "About 1,200 housing, 900 living, and 200 other.";
				case "comfortable_rate": "Around 1,600 LOR a month, give or take 100.";
				default: null;
			};
		}

		return switch (actionId)
		{
			case "borrow_amount": "Uhh around 3000 LOR.";
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
					{type: STEP_CLIENT, text: "Uhh around 3000 LOR"},
					{type: STEP_CLIENT, text: "I really wanna buy electro bike haha"},
					{type: STEP_CHOICES, text: ""}
				];
			default:
				null;
		};
	}

	static function playerLine(actionId:String):Null<String>
	{
		return BookScanActions.questionMessage(actionId);
	}
}
