package;

typedef BookPageSideContent =
{
	title:String,
	body:String,
	imagePath:Null<String>,
	imageCaption:Null<String>,
}

typedef BookBullet =
{
	?id:Null<String>,
	text:String,
}

class BookIntroPages
{
	public static inline var FIRST_PAGE = 3;
	public static inline var LAST_PAGE = 32;

	public static function hasContent(pageNum:Int):Bool
	{
		return pageNum >= FIRST_PAGE && pageNum <= LAST_PAGE;
	}

	public static function hasBulletList(pageNum:Int):Bool
	{
		return pageNum == 31 || pageNum == 32;
	}

	public static function isQuestionBullet(entry:BookBullet):Bool
	{
		return entry.id != null && entry.id.length > 0;
	}

	public static function getBullets(pageNum:Int):Array<BookBullet>
	{
		return switch (pageNum)
		{
			case 31:
				[
					{text: "The Request"},
					{id: "borrow_amount", text: "How much are you looking to borrow?"},
					{id: "loan_purpose", text: "What will the loan be used for?"},
					{id: "loan_security", text: "Do you wish your loan to be secured or not?"},
					{id: "comfortable_rate", text: "What monthly payment would you be comfortable with?"}
				];
			case 32:
				[
					{text: "Expenses"},
					{id: "living_expenses", text: "What are your monthly living expenses?"}
				];
			default:
				[];
		}
	}

	public static function getSide(pageNum:Int):Null<BookPageSideContent>
	{
		if (!hasContent(pageNum))
			return null;

		return switch (pageNum)
		{
			case 3:
				{
					title: "Welcome, Clerk",
					body: "Congratulations, employee #447-B!\n\n"
						+ "You were hired to approve loans, reject loans, and look busy between loans.",
					imagePath: null,
					imageCaption: null
				};
			case 4:
				{
					title: "Welcome, Clerk",
					body: "Management has full confidence in you. Management also left early.\n\n"
						+ "This book is legally binding, emotionally optional, and sponsored by the Republic of Loria (1967).",
					imagePath: null,
					imageCaption: null
				};
			case 5:
				{
					title: "Your Desk",
					body: "This is where you will spend your days making decisions that affect real imaginary people.",
					imagePath: "static/employers_table.png",
					imageCaption: "Fig. 1 — The employer's table (your side)."
				};
			case 6:
				{
					title: "Left Side",
					body: "The client stands here. They talk. You listen. They lie. You pretend not to notice.\n\n"
						+ "Below them is the client table — where passports land like homework you did not assign.",
					imagePath: null,
					imageCaption: null
				};
			case 7:
				{
					title: "Right Side",
					body: "Your tools live here: printer, shredder, calculator, and paperwork you will never fully understand.\n\n"
						+ "Open documents on this table to read them. Drag them around like a professional.",
					imagePath: null,
					imageCaption: null
				};
			case 8:
				{
					title: "Top Buttons",
					body: "MAIN MENU — options, credits, new game.\n\n"
						+ "BEGINNING OF DAY — resets the shift when you need a clean desk and a fresh regret.",
					imagePath: null,
					imageCaption: null
				};
			case 9:
				{
					title: "The Client",
					body: "When someone arrives, talk using the buttons at the bottom of the screen.",
					imagePath: "static/Clients/client1.png",
					imageCaption: "Fig. 2 — A typical client. Approach with paperwork."
				};
			case 10:
				{
					title: "Small Talk",
					body: "• \"Yeah, that's right\" — discuss the weather. Clients love weather.\n\n"
						+ "• \"What is your name?\" — they usually know it.\n\n"
						+ "• \"Passport, please.\" — they hand over their passport. Usually.",
					imagePath: null,
					imageCaption: null
				};
			case 11:
				{
					title: "Their Passport",
					body: "Check name, dates, and photo against what the client tells you.",
					imagePath: "static/lorian_open_passport.png",
					imageCaption: "Fig. 3 — A passport. Check every field."
				};
			case 12:
				{
					title: "Their Documents",
					body: "Drag anything the client gives you onto your table.\n\n"
						+ "Compare passport, ID cards, and contracts. Trust no one. Trust this book slightly more.",
					imagePath: null,
					imageCaption: null
				};
			case 13:
				{
					title: "Scan Mode",
					body: "After you chat, a button appears: \"Let me ask you...\"\n\n"
						+ "Press it — or double-click something suspicious — to enter Scan Mode.",
					imagePath: null,
					imageCaption: null
				};
			case 14:
				{
					title: "Scan Mode",
					body: "The world turns gray. Highlight up to two regions: a face, a number, the printer that knows too much.\n\n"
						+ "Pick two and the system says \"Nothing to ask, really...\" That is normal.",
					imagePath: null,
					imageCaption: null
				};
			case 15:
				{
					title: "Your Computer",
					body: "Click the screen — not the desk, not the client — to open the bank terminal.",
					imagePath: "static/computer.png",
					imageCaption: "Fig. 4 — Your computer. Do not spill coffee on it."
				};
			case 16:
				{
					title: "Your Computer",
					body: "From the terminal you can search citizens, edit records, and file loan applications.\n\n"
						+ "While the monitor is open, the rest of the desk waits politely.",
					imagePath: null,
					imageCaption: null
				};
			case 17:
				{
					title: "The Terminal",
					body: "The green screen is intentional. Click outside the monitor to close it.",
					imagePath: "static/monitor.png",
					imageCaption: "Fig. 5 — The terminal. Stare until numbers make sense."
				};
			case 18:
				{
					title: "Client Database",
					body: "Search citizens by name or ID. Click a row to view and edit their full record.\n\n"
						+ "Bad dates and impossible numbers get rejected by \"advanced AI.\"",
					imagePath: null,
					imageCaption: null
				};
			case 19:
				{
					title: "Loan Application",
					body: "Start a New Application. Enter National ID, product, amount, term, salary, and expenses.\n\n"
						+ "The affordability panel shows rates, payments, and whether the loan is sensible.",
					imagePath: null,
					imageCaption: null
				};
			case 20:
				{
					title: "Other Terminal Apps",
					body: "CURRENCY EXCHANGE — live rates for VAL, KTH, MRD, and OST.\n\n"
						+ "SYSTEM STATUS — credits roll. CONVERSATION RECORDER — logs finished client exchanges.",
					imagePath: null,
					imageCaption: null
				};
			case 21:
				{
					title: "The Loan Folder",
					body: "After you submit a loan application, a folder slides onto your desk.",
					imagePath: "static/loan_folder.png",
					imageCaption: "Fig. 6 — Loan folder. Click the arrow to open."
				};
			case 22:
				{
					title: "The Loan Folder",
					body: "Spread the folder open on your table using the arrow on the cover.",
					imagePath: "static/loan_opened_folder.png",
					imageCaption: "Fig. 7 — Open folder with storage pocket."
				};
			case 23:
				{
					title: "The Loan Folder",
					body: "Put printed copies of every relevant document inside the folder pocket.\n\n"
						+ "Drag copies in. Pull them back out if you change your mind. The folder knows when you cheat. Probably.",
					imagePath: null,
					imageCaption: null
				};
			case 24:
				{
					title: "The Printer",
					body: "Drag a passport or ID onto the printer to scan it. Wait for the lights.",
					imagePath: "static/printer.png",
					imageCaption: "Fig. 8 — Printer. Makes paper your problem."
				};
			case 25:
				{
					title: "The Printer",
					body: "Pick up the copy from the tray. The terminal can also print forms — but only if the printer is free.",
					imagePath: null,
					imageCaption: null
				};
			case 26:
				{
					title: "Calculator",
					body: "Full arithmetic on your desk. Collapse it with the /\\ toggle if it blocks your view.",
					imagePath: "static/calculator.png",
					imageCaption: "Fig. 9 — Calculator."
				};
			case 27:
				{
					title: "Magnifying Glass",
					body: "Drag it over open documents on your table to zoom in on fine print.",
					imagePath: "static/magnifying_glass.png",
					imageCaption: "Fig. 10 — Magnifying glass."
				};
			case 28:
				{
					title: "Shredder",
					body: "Only accepts printed copies. Drag one in. Sleep better.",
					imagePath: "static/shredder.png",
					imageCaption: "Fig. 11 — Shredder."
				};
			case 29:
				{
					title: "Fresh Starts",
					body: "BEGINNING OF DAY — fresh client, clean desk.\n\n"
						+ "You are trained. Go break—or approve—the bank. See page 30 when you forget. You will.",
					imagePath: null,
					imageCaption: null
				};
			case 30:
				{
					title: "Questions to Ask",
					body: "On the following pages you will find a series of questions you might ask the client regarding their request.\n\n"
						+ "Please do not annoy them.",
					imagePath: null,
					imageCaption: null
				};
			case 31:
				{
					title: "Questions to Ask",
					body: "",
					imagePath: null,
					imageCaption: null
				};
			case 32:
				{
					title: "Questions to Ask",
					body: "",
					imagePath: null,
					imageCaption: null
				};
			default:
				null;
		}
	}
}
