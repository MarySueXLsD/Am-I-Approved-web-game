package;

typedef BookScanAction =
{
	id:String,
	message:String,
}

class BookScanActions
{
	public static inline var BOOK_TAG_PREFIX = "book_q:";
	public static inline var CLIENT_TAG = "client";
	public static inline var LOAN_APPLICATION_TAG = "loan_application";

	public static function bookQuestionTag(id:String):String
	{
		return BOOK_TAG_PREFIX + id;
	}

	public static function isBookQuestionTag(tag:Null<String>):Bool
	{
		return tag != null && StringTools.startsWith(tag, BOOK_TAG_PREFIX);
	}

	public static function resolve(tagA:Null<String>, tagB:Null<String>):Null<BookScanAction>
	{
		var bookTag:Null<String> = null;
		var hasClient = false;
		var hasLoanApplication = false;

		for (tag in [tagA, tagB])
		{
			if (tag == CLIENT_TAG)
				hasClient = true;
			else if (tag == LOAN_APPLICATION_TAG)
				hasLoanApplication = true;
			else if (isBookQuestionTag(tag))
				bookTag = tag;
		}

		if (hasClient && hasLoanApplication)
			return {id: "review_loan_application", message: "Ask client to review the application"};

		if (!hasClient || bookTag == null)
			return null;

		var id = bookTag.substr(BOOK_TAG_PREFIX.length);
		var message = messageForQuestion(id);
		if (message == null)
			return null;

		return {id: id, message: message};
	}

	static function messageForQuestion(id:String):Null<String>
	{
		return questionMessage(id);
	}

	public static function questionMessage(id:String):Null<String>
	{
		return switch (id)
		{
			case "borrow_amount": "How much are you looking to borrow?";
			case "loan_purpose": "What will the loan be used for?";
			case "loan_security": "Do you wish your loan to be secured or not?";
			case "living_expenses": "What are your monthly living expenses?";
			case "comfortable_rate": "What monthly payment would you be comfortable with?";
			default: null;
		};
	}
}
