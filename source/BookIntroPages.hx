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
	public static inline var LAST_PAGE = 94;

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
					{id: "living_expenses", text: "What are your monthly living expenses?"},
					{text: "Income"},
					{id: "annual_salary", text: "What is your annual salary?"},
					{id: "monthly_salary", text: "What is your monthly salary?"}
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
						+ "You were hired to approve loans, update citizen records, and look busy between visitors.",
					imagePath: null,
					imageCaption: null
				};
			case 4:
				{
					title: "Welcome, Clerk",
					body: "Management has full confidence in you. Management also left early.\n\n"
						+ "Chef — your floor manager — may drop by on day one to coach you.\n\n"
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
						+ "Below them is the client table — where IDs and contracts land automatically.",
					imagePath: null,
					imageCaption: null
				};
			case 7:
				{
					title: "Right Side",
					body: "Your tools live here: printer, shredder, calculator, and paperwork you will never fully understand.\n\n"
						+ "Drag documents from the client table onto your table to read them.",
					imagePath: null,
					imageCaption: null
				};
			case 8:
				{
					title: "Pause Menu",
					body: "Press ESC anytime for the pause menu.\n\n"
						+ "Continue — back to the desk.\n"
						+ "Start the shift over — fresh client, clean desk.\n"
						+ "Options — volume.\n"
						+ "Quit the job — main menu.",
					imagePath: null,
					imageCaption: null
				};
			case 9:
				{
					title: "The Client",
					body: "Use the buttons below to talk.\n\nSome visits are database fixes — not loans.",
					imagePath: "static/Clients/client1.png",
					imageCaption: "Fig. 2 — A typical client."
				};
			case 10:
				{
					title: "Small Talk",
					body: "One button at the bottom — usually small talk.\n\n"
						+ "After the opening chat, \"Let me ask you...\" appears for Scan Mode.\n\n"
						+ "Loan questions live on pages 31–32. Highlight a question together with the client to ask it.",
					imagePath: null,
					imageCaption: null
				};
			case 11:
				{
					title: "Their ID",
					body: "When a client needs a loan, their ID usually arrives on the client table automatically.\n\n"
						+ "Check name, National ID, address, and photo against what the client tells you.",
					imagePath: "static/closeup_loria_ID.png",
					imageCaption: "Fig. 3 — An ID card. Check every field."
				};
			case 12:
				{
					title: "Their Documents",
					body: "Drag ID cards and job contracts onto your table.\n\n"
						+ "Job contracts show foreign salaries — use Currency Exchange (page 92) to convert them.\n\n"
						+ "Job contracts cannot be printed. Trust no one. Trust this book slightly more.",
					imagePath: null,
					imageCaption: null
				};
			case 13:
				{
					title: "Scan Mode",
					body: "Press \"Let me ask you...\" after chatting — or double-click something suspicious — to enter Scan Mode.",
					imagePath: null,
					imageCaption: null
				};
			case 14:
				{
					title: "Scan Mode",
					body: "The world turns gray. Highlight up to two regions.\n\n"
						+ "• Client + handbook question (pages 31–32) — ask it aloud\n"
						+ "• Client + ID photo — does the face match?\n"
						+ "• Client + printed application — review the form\n"
						+ "• Client + printed client record — verify details\n\n"
						+ "Two unrelated picks? \"Nothing to ask, really...\" Normal.",
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
						+ "Update annual salary when a client brings proof — e.g. a foreign job contract.\n\n"
						+ "Hit Print on a record to produce a client-details copy for Scan Mode verification.\n\n"
						+ "Bad dates and impossible numbers get rejected by \"advanced AI.\"",
					imagePath: null,
					imageCaption: null
				};
			case 19:
				{
					title: "Loan Application",
					body: "Start a New Application. Enter National ID, product, amount, term, salary, and expenses.\n\n"
						+ "Housing and Living are required. Other is optional.\n\n"
						+ "The affordability panel shows rates, payments, and whether the loan is sensible.",
					imagePath: null,
					imageCaption: null
				};
			case 20:
				{
					title: "Other Terminal Apps",
					body: "CURRENCY EXCHANGE — live rates: 1 LOR buys VAL, KTH, MRD, or OST.\n\n"
						+ "SYSTEM STATUS — credits roll.\n\n"
						+ "CONVERSATION RECORDER — logs finished client exchanges.",
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
					body: "Put printed copies of every required document inside the folder pocket.\n\n"
						+ "Drag copies in. Pull them back out if you change your mind. The folder knows when you cheat. Probably.",
					imagePath: null,
					imageCaption: null
				};
			case 24:
				{
					title: "The Printer",
					body: "Drag an ID onto the printer to scan it. Wait for the lights.\n\n"
						+ "Job contracts, the guide book, and bank forms cannot go through the printer.",
					imagePath: "static/printer.png",
					imageCaption: "Fig. 8 — Printer. Makes paper your problem."
				};
			case 25:
				{
					title: "The Printer",
					body: "Pick up the copy from the tray before printing again.\n\n"
						+ "The terminal can print forms — but only if the printer is idle.\n\n"
						+ "If the monitor is open during a print job, the printer pauses until you close it.",
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
					body: "Drag it over open documents on your table to zoom in on fine print — salaries, names, dates.",
					imagePath: "static/magnifying_glass.png",
					imageCaption: "Fig. 10 — Magnifying glass."
				};
			case 28:
				{
					title: "Shredder",
					body: "Only accepts printed copies. Drag one in. Sleep better.\n\n"
						+ "Originals, job contracts, and the guide book are not shredder food.",
					imagePath: "static/shredder.png",
					imageCaption: "Fig. 11 — Shredder."
				};
			case 29:
				{
					title: "Fresh Starts",
					body: "ESC → Start the shift over — fresh client, clean desk.\n\n"
						+ "Read pages 33–35 before your first loan. Questions: pages 30–32.\n\n"
						+ "Detailed SOP follows on page 36 if you enjoy suffering.",
					imagePath: null,
					imageCaption: null
				};
			case 30:
				{
					title: "Questions to Ask",
					body: "On the following pages you will find questions you might ask during Scan Mode.\n\n"
						+ "Highlight the question on pages 31–32 together with the client.\n\n"
						+ "Only ask each question once. Clients dislike repetition.",
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
			case 33:
				{
					title: "Quick Reference",
					body: "THE FIVE STEPS — read this before your first loan.\n\n"
						+ "1. INTAKE — listen. Note amount & purpose. Open their ID.\n"
						+ "2. GATHER — Scan Mode + pages 31–32. Write every number.\n"
						+ "3. TERMINAL — Loan Application → New Application → fill all fields.",
					imagePath: null,
					imageCaption: null
				};
			case 34:
				{
					title: "Quick Reference",
					body: "4. FOLDER — SUBMIT the form (green Affordable verdict).\n"
						+ "Print ID copy, application, checklist.\n"
						+ "Drag copies into folder — not originals.\n\n"
						+ "5. APPROVE — Submit for Approval when all three items are in.",
					imagePath: null,
					imageCaption: null
				};
			case 35:
				{
					title: "Salaries & Exchange",
					body: "SALARIES IN LOR\n"
						+ "Monthly = annual ÷ 12 (round to nearest LOR).\n"
						+ "Not sure? Client Database → search by name.\n\n"
						+ "DATABASE-ONLY VISITS\n"
						+ "Some clients need annual salary corrected — no loan. Convert foreign pay (page 92), update the record, return their documents.\n\n"
						+ "FOREIGN CURRENCY\n"
						+ "Terminal → Currency Exchange. Rate = foreign units per 1 LOR.\n"
						+ "Convert: foreign amount ÷ rate = LOR.",
					imagePath: null,
					imageCaption: null
				};
			case 36:
				{
					title: "Detailed SOP",
					body: "The following pages are the full loan procedure — reference when stuck.\n\n"
						+ "Step 1 — Intake: read the opening message. Note amount, purpose, and documents.",
					imagePath: null,
					imageCaption: null
				};
			case 37:
				{
					title: "Step 1 — Intake",
					body: "",
					imagePath: "static/Clients/client1.png",
					imageCaption: "Fig. 12 — A client with a request."
				};
			case 38:
				{
					title: "Step 1 — Intake",
					body: "The client's ID usually lands on the client table automatically.\n\n"
						+ "Open it. Verify the photo matches the person in front of you.\n\n"
						+ "Write down their National ID for the terminal.",
					imagePath: null,
					imageCaption: null
				};
			case 39:
				{
					title: "Step 1 — Documents",
					body: "",
					imagePath: "static/closeup_loria_ID.png",
					imageCaption: "Fig. 13 — Check name, National ID, address, and photo."
				};
			case 40:
				{
					title: "Step 1 — Documents",
					body: "Check the ID card: National ID number, name, and address.\n\n"
						+ "In Scan Mode, highlight the client + ID photo to compare faces.",
					imagePath: null,
					imageCaption: null
				};
			case 41:
				{
					title: "Step 1 — Documents",
					body: "Use the Client Database to look up salary if the client does not say it aloud.\n\n"
						+ "Monthly salary = annual salary ÷ 12, rounded to the nearest LOR.\n\n"
						+ "Foreign job contract? Convert to LOR first (pages 92–94), then update the database if needed.",
					imagePath: null,
					imageCaption: null
				};
			case 42:
				{
					title: "Step 2 — Gather Info",
					body: "Press \"Let me ask you...\" to enter Scan Mode.\n\n"
						+ "Or double-click something suspicious on the desk.",
					imagePath: null,
					imageCaption: null
				};
			case 43:
				{
					title: "Step 2 — Gather Info",
					body: "Scan a question from pages 31–32 together with the client:\n\n"
						+ "• How much they want to borrow\n"
						+ "• What the loan is for\n"
						+ "• Secured or not secured",
					imagePath: null,
					imageCaption: null
				};
			case 44:
				{
					title: "Step 2 — Gather Info",
					body: "• Comfortable monthly payment\n"
						+ "• Monthly living expenses\n"
						+ "• Annual or monthly salary\n\n"
						+ "Write down every number. Clients forget. You cannot.",
					imagePath: null,
					imageCaption: null
				};
			case 45:
				{
					title: "Step 2 — What to Record",
					body: "Before touching the terminal, know:\n\n"
						+ "• National ID (from ID card)\n"
						+ "• Loan amount in LOR\n"
						+ "• Loan product (personal, auto, credit card, mortgage)",
					imagePath: null,
					imageCaption: null
				};
			case 46:
				{
					title: "Step 2 — What to Record",
					body: "• Secured or not secured\n"
						+ "• Term in months for the right payment\n"
						+ "• Monthly salary\n"
						+ "• Housing, living, and other expenses\n\n"
						+ "If any of these is a guess, it is probably wrong.",
					imagePath: null,
					imageCaption: null
				};
			case 47:
				{
					title: "Step 3 — The Terminal",
					body: "",
					imagePath: "static/computer.png",
					imageCaption: "Fig. 14 — Click the screen, not the desk."
				};
			case 48:
				{
					title: "Step 3 — The Terminal",
					body: "Click the computer screen to open the terminal.\n\n"
						+ "Click outside the monitor to close it.",
					imagePath: null,
					imageCaption: null
				};
			case 49:
				{
					title: "Step 3 — The Terminal",
					body: "Select Loan Application from the main menu.",
					imagePath: null,
					imageCaption: null
				};
			case 50:
				{
					title: "Step 3 — The Terminal",
					body: "",
					imagePath: "static/monitor.png",
					imageCaption: "Fig. 15 — The terminal."
				};
			case 51:
				{
					title: "Terminal Menu",
					body: "• New Application — enter or edit the form\n\n"
						+ "• Print Checklist — after submit only\n\n"
						+ "• Print Application Form — after submit only",
					imagePath: null,
					imageCaption: null
				};
			case 52:
				{
					title: "Terminal Menu",
					body: "• Submit for Approval — when the folder is complete\n\n"
						+ "Print and Submit require an application in progress (Loan ID assigned).",
					imagePath: null,
					imageCaption: null
				};
			case 53:
				{
					title: "National ID",
					body: "Select New Application. Fill every required field.\n\n"
						+ "NATIONAL ID — must match the ID card exactly.",
					imagePath: null,
					imageCaption: null
				};
			case 54:
				{
					title: "National ID",
					body: "Autocomplete suggestions appear as you type.",
					imagePath: null,
					imageCaption: null
				};
			case 55:
				{
					title: "Loan Product & Amount",
					body: "LOAN PRODUCT — personal, auto, credit card, or mortgage. Each has a different rate.\n\n"
						+ "LOAN AMOUNT — in LOR. Larger amounts earn a small rate discount.",
					imagePath: null,
					imageCaption: null
				};
			case 56:
				{
					title: "Term",
					body: "TERM (MONTHS) — not years. Maximum 360.\n\n"
						+ "Choose a term that produces the monthly payment the client expects.",
					imagePath: null,
					imageCaption: null
				};
			case 57:
				{
					title: "Monthly Salary",
					body: "MONTHLY SALARY (LOR) — annual salary ÷ 12.\n\n"
						+ "Look it up in Client Database if needed.",
					imagePath: null,
					imageCaption: null
				};
			case 58:
				{
					title: "Security",
					body: "SECURITY — Secured or Not secured.\n\n"
						+ "Secured: collateral pledged, lower rate.",
					imagePath: null,
					imageCaption: null
				};
			case 59:
				{
					title: "Security",
					body: "Not secured: no collateral, higher rate.\n\n"
						+ "Select what the client asked for.",
					imagePath: null,
					imageCaption: null
				};
			case 60:
				{
					title: "Monthly Expenses",
					body: "HOUSING / MO — rent or mortgage payment. Required.\n\n"
						+ "LIVING / MO — food, transport, utilities. Required.",
					imagePath: null,
					imageCaption: null
				};
			case 61:
				{
					title: "Monthly Expenses",
					body: "OTHER / MO — everything else. Optional but recommended.\n\n"
						+ "TOTAL / MO — calculated automatically.",
					imagePath: null,
					imageCaption: null
				};
			case 62:
				{
					title: "Monthly Expenses",
					body: "Use the numbers the client gave you in Scan Mode.\n\n"
						+ "Wrong expenses mean a wrong verdict.",
					imagePath: null,
					imageCaption: null
				};
			case 63:
				{
					title: "Affordability Panel",
					body: "Scroll down to see the Affordability Analysis. It updates as you type.",
					imagePath: null,
					imageCaption: null
				};
			case 64:
				{
					title: "Affordability Panel",
					body: "Rate & pricing — base rate, discounts, note rate, APR.\n\n"
						+ "Loan disclosure — amount, finance charge, total payments.",
					imagePath: null,
					imageCaption: null
				};
			case 65:
				{
					title: "Affordability Panel",
					body: "Monthly cash flow — salary, spending, payment, free cash.\n\n"
						+ "Affordability metrics — DTI, room after loan, verdict.",
					imagePath: null,
					imageCaption: null
				};
			case 66:
				{
					title: "Verdict",
					body: "Only Affordable (green) passes review.\n\n"
						+ "Marginal and Not Affordable are rejected.",
					imagePath: null,
					imageCaption: null
				};
			case 67:
				{
					title: "Verdict",
					body: "Affordable requires:\n\n"
						+ "• Salary exceeds total spending\n"
						+ "• Room after loan ≥ 30%\n"
						+ "• Debt-to-income ≤ 35%",
					imagePath: null,
					imageCaption: null
				};
			case 68:
				{
					title: "Verdict",
					body: "If the verdict is wrong, adjust the term or amount, or verify expense numbers.\n\n"
						+ "Do not submit until SUBMIT is enabled and the verdict is green.",
					imagePath: null,
					imageCaption: null
				};
			case 69:
				{
					title: "Submit the Application",
					body: "Click SUBMIT when all fields are filled and the verdict is Affordable.",
					imagePath: null,
					imageCaption: null
				};
			case 70:
				{
					title: "Submit the Application",
					body: "The system assigns a Loan ID (e.g. LN-472622). Remember it.\n\n"
						+ "Close the monitor when done.",
					imagePath: null,
					imageCaption: null
				};
			case 71:
				{
					title: "Submit the Application",
					body: "",
					imagePath: "static/loan_folder.png",
					imageCaption: "Fig. 16 — A loan folder slides onto your desk."
				};
			case 72:
				{
					title: "Submit the Application",
					body: "The application form auto-prints if the printer is free.\n\n"
						+ "If not, free the printer — then use Print Application Form from the menu.",
					imagePath: null,
					imageCaption: null
				};
			case 73:
				{
					title: "Step 4 — The Folder",
					body: "",
					imagePath: "static/loan_opened_folder.png",
					imageCaption: "Fig. 17 — Click the arrow to spread the folder open."
				};
			case 74:
				{
					title: "Step 4 — The Folder",
					body: "The storage pocket holds your documents.\n\n"
						+ "Drag copies in. Click a stored copy to pull it back out.",
					imagePath: null,
					imageCaption: null
				};
			case 75:
				{
					title: "Step 4 — The Folder",
					body: "The folder only accepts printed copies — not originals.\n\n"
						+ "Scan first, then store the copy.",
					imagePath: null,
					imageCaption: null
				};
			case 76:
				{
					title: "Required Documents",
					body: "Three items must be in the folder:\n\n"
						+ "☐ ID copy",
					imagePath: null,
					imageCaption: null
				};
			case 77:
				{
					title: "Required Documents",
					body: "☐ Loan application form\n"
						+ "☐ Loan checklist\n\n"
						+ "The checklist shows strikethrough on completed items.",
					imagePath: null,
					imageCaption: null
				};
			case 78:
				{
					title: "Scanning Copies",
					body: "",
					imagePath: "static/printer.png",
					imageCaption: "Fig. 18 — Drag an ID onto the printer."
				};
			case 79:
				{
					title: "Scanning Copies",
					body: "Wait for the scan line to finish. Pick up the copy from the tray.\n\n"
						+ "The printer must be idle — no paper in the tray, no scan running.",
					imagePath: null,
					imageCaption: null
				};
			case 80:
				{
					title: "Printing from Terminal",
					body: "Open terminal → Loan Application:\n\n"
						+ "Print Checklist — prints with your Loan ID and live completion status.",
					imagePath: null,
					imageCaption: null
				};
			case 81:
				{
					title: "Printing from Terminal",
					body: "Print Application Form — reprints if you edited the application.\n\n"
						+ "Both need a free printer. Pick up each document before printing the next.",
					imagePath: null,
					imageCaption: null
				};
			case 82:
				{
					title: "Filling the Folder",
					body: "Recommended order:\n\n"
						+ "1. Application form\n"
						+ "2. Checklist",
					imagePath: null,
					imageCaption: null
				};
			case 83:
				{
					title: "Filling the Folder",
					body: "3. ID copy\n\n"
						+ "Drag each document over the folder pocket and release.",
					imagePath: null,
					imageCaption: null
				};
			case 84:
				{
					title: "Filling the Folder",
					body: "Verify the checklist shows all three items struck through.",
					imagePath: null,
					imageCaption: null
				};
			case 85:
				{
					title: "Client Review",
					body: "Optional: have the client verify the application.\n\n"
						+ "Open the printed form on your desk. Enter Scan Mode.",
					imagePath: null,
					imageCaption: null
				};
			case 86:
				{
					title: "Client Review",
					body: "Scan the client together with the printed application.\n\n"
						+ "If something is wrong, they will tell you. Fix it, reprint, replace in folder.",
					imagePath: null,
					imageCaption: null
				};
			case 87:
				{
					title: "Submit for Approval",
					body: "When all three documents are in the folder:\n\n"
						+ "Terminal → Loan Application → Submit for Approval.",
					imagePath: null,
					imageCaption: null
				};
			case 88:
				{
					title: "Submit for Approval",
					body: "The folder slides away. The system reviews your application.\n\n"
						+ "Incomplete folder? You get a warning instead.",
					imagePath: null,
					imageCaption: null
				};
			case 89:
				{
					title: "Outcomes — Approved",
					body: "A Loan Approval document appears on your desk.\n\n"
						+ "The client thanks you. You may rest.",
					imagePath: null,
					imageCaption: null
				};
			case 90:
				{
					title: "Outcomes — Rejected",
					body: "An Application Errors document lists what went wrong.\n\n"
						+ "Read every bullet. Fix the form, reprint, reassemble, submit again.",
					imagePath: null,
					imageCaption: null
				};
			case 91:
				{
					title: "Common Errors",
					body: "Wrong National ID, amount, product, security, term, salary, or expenses.\n\n"
						+ "Also: submitting with a Marginal verdict. Do not do that.\n\n"
						+ "If a client's face does not match their ID photo, confront them before approving anything.",
					imagePath: null,
					imageCaption: null
				};
			case 92:
				{
					title: "Exchange Rates",
					body: "Terminal → Currency Exchange shows live spot rates.\n\n"
						+ "Each row shows how much foreign currency 1 LOR buys right now.\n\n"
						+ "VAL — Valdoria. KTH — Kethran. MRD — Meridian. OST — Ostmark.",
					imagePath: null,
					imageCaption: null
				};
			case 93:
				{
					title: "Converting to LOR",
					body: "LOR = foreign amount ÷ rate.\n\n"
						+ "185,000 KTH ÷ 68.42 ≈ 2,704 LOR/mo.",
					imagePath: "static/kethran_job_contract_with_name_1.png",
					imageCaption: "Fig. 19 — Check monthly vs annual."
				};
			case 94:
				{
					title: "Annual from Monthly",
					body: "Monthly LOR × 12 = annual salary in LOR.\n\n"
						+ "2,704 × 12 ≈ 32,448 LOR annual — enter that in Client Database.\n\n"
						+ "Always check: is the contract monthly or annual? Clients mix them up.",
					imagePath: null,
					imageCaption: null
				};
			default:
				null;
		}
	}
}
