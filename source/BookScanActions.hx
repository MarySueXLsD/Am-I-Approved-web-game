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
	public static inline var CLIENT_DETAILS_TAG = "client_details";
	public static inline var DOCUMENT_NAME_TAG = "document_name";
	public static inline var PASSPORT_NAME_TAG = "passport_name";
	public static inline var ID_PHOTO_TAG = "id_photo";

	public static function bookQuestionTag(id:String):String
	{
		return BOOK_TAG_PREFIX + id;
	}

	public static function isBookQuestionTag(tag:Null<String>):Bool
	{
		return tag != null && StringTools.startsWith(tag, BOOK_TAG_PREFIX);
	}

	public static function resolve(tagA:Null<String>, tagB:Null<String>, ?citizenName:Null<String>):Null<BookScanAction>
	{
		var bookTag:Null<String> = null;
		var hasClient = false;
		var hasLoanApplication = false;
		var hasClientDetails = false;
		var hasDocumentName = false;
		var hasPassportName = false;
		var hasIdPhoto = false;

		for (tag in [tagA, tagB])
		{
			if (tag == CLIENT_TAG)
				hasClient = true;
			else if (tag == LOAN_APPLICATION_TAG)
				hasLoanApplication = true;
			else if (tag == CLIENT_DETAILS_TAG)
				hasClientDetails = true;
			else if (tag == DOCUMENT_NAME_TAG)
				hasDocumentName = true;
			else if (tag == PASSPORT_NAME_TAG)
				hasPassportName = true;
			else if (tag == ID_PHOTO_TAG)
				hasIdPhoto = true;
			else if (isBookQuestionTag(tag))
				bookTag = tag;
		}

		if (hasClient && hasIdPhoto)
			return {id: "compare_id_photo", message: "Compare client to ID photo."};

		if (hasPassportName && hasDocumentName)
			return {id: "compare_id_passport", message: "Compare passport and ID names."};

		if (hasClient && hasLoanApplication)
			return {id: "review_loan_application", message: "Ask client to review the application"};

		if (hasClient && hasClientDetails)
			return {id: "verify_client_details", message: "Verify client against their printed record"};

		if (hasClient && hasDocumentName)
			return {id: "confirm_name", message: confirmNameQuestion(citizenName)};

		if (!hasClient || bookTag == null)
			return null;

		var id = bookTag.substr(BOOK_TAG_PREFIX.length);
		var message = messageForQuestion(id);
		if (message == null)
			return null;

		return {id: id, message: message};
	}

	public static function confirmNameQuestion(?name:Null<String>):String
	{
		var display = name != null && StringTools.trim(name) != "" ? name : "…";
		return 'Is your name $display?';
	}

	static function messageForQuestion(id:String):Null<String>
	{
		return questionMessage(id);
	}

	public static function isBookQuestionId(id:String):Bool
	{
		return questionMessage(id) != null;
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
			case "annual_salary": "What is your annual salary?";
			case "monthly_salary": "What is your monthly salary?";
			case "passport_request": "Can I see your passport?";
			default: null;
		};
	}
}
