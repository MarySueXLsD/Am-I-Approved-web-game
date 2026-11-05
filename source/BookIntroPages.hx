package;

typedef BookBullet =
{
	?id:Null<String>,
	text:String,
}

enum BookBlock
{
	/** Plain paragraph. */
	Para(text:String);
	/** Small underlined section label. */
	Label(text:String);
	/** Ruled two-column table: label, then value. */
	Rows(rows:Array<Array<String>>);
	/** Numbered procedure: a keyword and what to do. */
	Steps(steps:Array<Array<String>>);
	/** Tick-box list of things to watch for. */
	Checks(items:Array<String>);
	/** Coloured chip, then what it means. */
	Chips(chips:Array<{color:Int, label:String, text:String}>);
	/** Tiny picture of a desk tool, a name, and what it does. */
	Tools(tools:Array<Array<String>>);
	/** Worked sum in a box. */
	Formula(lines:Array<String>);
	/** Stamped warning anchored to the bottom of the page. */
	Note(text:String);
}

typedef BookPage =
{
	title:String,
	blocks:Array<BookBlock>,
}

/** The whole handbook: four spreads a clerk can actually use mid-shift. Page numbers are referenced in dialogue. */
class BookIntroPages
{
	public static inline var FIRST_PAGE = 3;
	public static inline var LAST_PAGE = 10;

	public static function hasContent(pageNum:Int):Bool
	{
		return pageNum >= FIRST_PAGE && pageNum <= LAST_PAGE;
	}

	public static function hasBulletList(pageNum:Int):Bool
	{
		return pageNum == 5 || pageNum == 6;
	}

	public static function isQuestionBullet(entry:BookBullet):Bool
	{
		return entry.id != null && entry.id.length > 0;
	}

	public static function getBullets(pageNum:Int):Array<BookBullet>
	{
		return switch (pageNum)
		{
			case 5:
				[
					{text: "The Request"},
					{id: "borrow_amount", text: "How much are you looking to borrow?"},
					{id: "loan_purpose", text: "What will the loan be used for?"},
					{id: "loan_security", text: "Do you wish your loan to be secured or not?"},
					{id: "comfortable_rate", text: "What monthly payment would you be comfortable with?"}
				];
			case 6:
				[
					{text: "Expenses"},
					{id: "living_expenses", text: "What are your monthly living expenses?"},
					{text: "Income"},
					{id: "annual_salary", text: "What is your annual salary?"},
					{id: "monthly_salary", text: "What is your monthly salary?"}
				];
			default:
				[];
		}
	}

	public static function getPage(pageNum:Int):Null<BookPage>
	{
		return switch (pageNum)
		{
			case 3:
				{
					title: "The Five Steps",
					blocks: [
						Steps([
							["Listen", "Note amount and purpose. Open their ID. Check the photo."],
							["Ask", "\"Let me ask you...\" Pick a question (p. 5-6), then the client."],
							["File", "Terminal: Loan Application, New Application. SUBMIT."],
							["Folder", "Print the checklist. File the form, checklist and an ID copy."],
							["Approve", "Terminal: Submit for Approval."]
						]),
						Note("Record fix only? No loan, no folder. Fix it, return their papers.")
					]
				};
			case 4:
				{
					title: "The Application",
					blocks: [
						Rows([
							["National ID", "From the ID card, exactly"],
							["Product", "Car: Auto. Home: Mortgage. Else: Personal"],
							["Amount", "Client's FINAL answer"],
							["Term", "Months that hit their payment"],
							["Salary", "Database annual / 12"],
							["Security", "What the client asked for"],
							["Housing", "Rent or mortgage, monthly"],
							["Living", "Food, transport, utilities"],
							["Other", "Yearly bills / 12, plus existing loan payments"]
						])
					]
				};
			case 5:
				{
					title: "Questions to Ask",
					blocks: [Note("Scan Mode: select a question, then the client.")]
				};
			case 6:
				{
					title: "Questions to Ask",
					blocks: [Note("Ask once. Clients dislike repetition.")]
				};
			case 7:
				{
					title: "The Verdict",
					blocks: [
						Label("Affordable requires"),
						Rows([
							["Salary", "More than all spending"],
							["Room after loan", "30% or more"],
							["Debt to income", "35% or less"]
						]),
						Chips([
							{color: 0xFF4E7A3C, label: "Affordable", text: "Passes review."},
							{color: 0xFFB8862A, label: "Marginal", text: "Rejected. Adjust the term."},
							{color: 0xFFA63A2E, label: "Not Affordable", text: "Rejected. See below."}
						]),
						Note("Honest numbers, red verdict? Never fudge. Submit. The bank says no. That is correct.")
					]
				};
			case 8:
				{
					title: "Red Flags",
					blocks: [
						Checks([
							"Face differs from ID photo: scan client + photo, confront. No loan.",
							"Salary they hope to earn: the database wins.",
							"Amount changed mid-talk: use the last figure.",
							"Yearly bill: divide by 12.",
							"Payslip in foreign money: convert first (p. 9).",
							"Monthly or annual? Clients mix them up."
						])
					]
				};
			case 9:
				{
					title: "Foreign Pay",
					blocks: [
						Formula(["LOR = foreign / rate", "185,000 KTH / 68.42 = 2,704", "2,704 x 12 = 32,448 LOR a year"]),
						Para("Rates: Terminal, Currency Exchange. Each shows units per 1 LOR."),
						Rows([["VAL", "Valdoria"], ["KTH", "Kethran"], ["MRD", "Meridian"], ["OST", "Ostmark"]]),
						Note("Enter the annual figure in the Client Database.")
					]
				};
			case 10:
				{
					title: "Your Desk",
					blocks: [
						Tools([
							["static/printer.png", "Printer", "Drag an ID to copy. Clear the tray first."],
							["static/loan_folder.png", "Folder", "Copies only. Arrow opens it."],
							["static/shredder.png", "Shredder", "Copies only. Sleep better."],
							["static/magnifying_glass.png", "Lens", "Drag over documents to read fine print."],
							["static/computer.png", "Terminal", "Click the screen. Click outside to close."]
						]),
						Note("ESC pauses. Management will not notice.")
					]
				};
			default:
				null;
		}
	}
}
