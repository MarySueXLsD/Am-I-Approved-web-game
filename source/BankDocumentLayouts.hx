package;

class BankDocumentLayouts
{
	public static inline var DOCUMENT_PATH = "static/empty_bank_document.png";
	static inline var BODY_X = 100.0;
	static inline var BODY_W = 855.0;
	static inline var BODY_COLOR = 0xFF1A1A1A;
	public static inline var LABEL_COLOR = 0xFF1A4FA8;
	public static inline var VERDICT_GREEN = 0xFF1F9A44;
	public static inline var STRIKETHROUGH_COLOR = 0xFF707070;
	static inline var FORM_FONT = 8;
	static inline var FORM_LEADING = 4;

	static function checklistBodyText(?loanId:String, ?completedItems:Array<LoanChecklistItem>):String
	{
		var id = loanId != null && loanId != "" ? loanId : "—";
		var completed = completedItems != null ? completedItems : [];
		return [
			labeledLine("Loan ID", id),
			"",
			"@Required documents:@",
			checklistBullet("Passport copy", completed.indexOf(PassportCopy) >= 0),
			checklistBullet("National ID copy", completed.indexOf(NationalIdCopy) >= 0),
			checklistBullet("Loan application form", completed.indexOf(LoanApplicationForm) >= 0),
			checklistBullet("Loan checklist", completed.indexOf(LoanChecklist) >= 0)
		].join("\n");
	}

	static function checklistBullet(text:String, done:Bool):String
	{
		var line = "• " + text;
		return done ? "#" + line + "#" : line;
	}

	public static function loanChecklist(?loanId:String, ?completedItems:Array<LoanChecklistItem>):BankDocumentLayout
	{
		return {
			documentPath: DOCUMENT_PATH,
			title: {
				text: "Loan Checklist",
				x: BODY_X,
				y: 250,
				width: BODY_W,
				fontSize: 13,
				bold: true,
				color: BODY_COLOR,
				leading: null,
				align: "center"
			},
			formBody: {
				text: checklistBodyText(loanId, completedItems),
				x: BODY_X,
				y: 330,
				width: BODY_W,
				fontSize: FORM_FONT,
				bold: false,
				color: BODY_COLOR,
				leading: FORM_LEADING,
				align: "left"
			},
			disclaimer: {
				text: "Please collect every item listed above\nbefore submitting the loan folder",
				x: BODY_X,
				y: 1140,
				width: BODY_W,
				fontSize: 8,
				bold: false,
				color: BODY_COLOR,
				leading: null,
				align: "center",
				wordWrap: true
			},
			fields: [
				{kind: AccountHolder, x: 80, y: 1375, width: 500, fontSize: 8},
				{kind: Date, x: 700, y: 1375, width: 300, fontSize: 8}
			],
			valueColor: BODY_COLOR
		};
	}

	public static function applicationForm(loanId:String, ?data:LoanApplicationData):BankDocumentLayout
	{
		return {
			documentPath: DOCUMENT_PATH,
			title: {
				text: "Loan Application Form",
				x: BODY_X,
				y: 250,
				width: BODY_W,
				fontSize: 13,
				bold: true,
				color: BODY_COLOR,
				leading: null,
				align: "center"
			},
			formBody: {
				text: applicationFormBodyText(loanId, data),
				x: BODY_X,
				y: 330,
				width: BODY_W,
				fontSize: FORM_FONT,
				bold: false,
				color: BODY_COLOR,
				leading: FORM_LEADING,
				align: "left"
			},
			disclaimer: {
				text: "Please check through this document\ncarefully",
				x: BODY_X,
				y: 1140,
				width: BODY_W,
				fontSize: 8,
				bold: false,
				color: BODY_COLOR,
				leading: null,
				align: "center",
				wordWrap: true
			},
			fields: [
				{kind: AccountHolder, x: 80, y: 1375, width: 500, fontSize: 8},
				{kind: Date, x: 700, y: 1375, width: 300, fontSize: 8}
			],
			valueColor: BODY_COLOR
		};
	}

	public static function standard():BankDocumentLayout
	{
		return applicationForm("");
	}

	public static function loanDecision(review:LoanReviewResult, ?loanId:String):BankDocumentLayout
	{
		var id = loanId != null && loanId != "" ? loanId : "—";
		var title = review.approved ? "Loan Approval" : "Application Errors";
		var body = review.approved ? approvalBodyText(review, id) : errorsBodyText(review.errors);
		var disclaimer = review.approved
			? "This document confirms loan approval.\nRetain for your records."
			: "Correct the errors listed above\nbefore resubmitting the application.";

		return {
			documentPath: DOCUMENT_PATH,
			title: {
				text: title,
				x: BODY_X,
				y: 250,
				width: BODY_W,
				fontSize: 13,
				bold: true,
				color: review.approved ? VERDICT_GREEN : BODY_COLOR,
				leading: null,
				align: "center"
			},
			formBody: {
				text: body,
				x: BODY_X,
				y: 330,
				width: BODY_W,
				fontSize: FORM_FONT,
				bold: false,
				color: BODY_COLOR,
				leading: FORM_LEADING,
				align: "left"
			},
			disclaimer: {
				text: disclaimer,
				x: BODY_X,
				y: 1140,
				width: BODY_W,
				fontSize: 8,
				bold: false,
				color: BODY_COLOR,
				leading: null,
				align: "center",
				wordWrap: true
			},
			fields: [
				{kind: AccountHolder, x: 80, y: 1375, width: 500, fontSize: 8},
				{kind: Date, x: 700, y: 1375, width: 300, fontSize: 8}
			],
			valueColor: BODY_COLOR
		};
	}

	static function errorsBodyText(errors:Array<String>):String
	{
		if (errors.length == 0)
			return labeledLine("Status", "No errors found");

		var lines = ["@Errors found:@", ""];
		for (err in errors)
			lines.push("• " + err);
		return lines.join("\n");
	}

	static function approvalBodyText(review:LoanReviewResult, loanId:String):String
	{
		var lines = [labeledLine("Status", "Approved"), labeledLine("Application", loanId), ""];
		for (line in review.grantLines)
		{
			if (line.length == 0)
				lines.push("");
			else
				lines.push(line);
		}
		return lines.join("\n");
	}

	static function applicationFormBodyText(loanId:String, ?data:LoanApplicationData):String
	{
		if (data == null)
			return labeledLine("Status", "No active loan application");

		var calc = LoanAffordabilityCalculator.compute(data);
		if (!calc.ready)
			return labeledLine("Status", "Complete the loan application to print");

		var id = loanId != null && loanId != "" ? loanId : "—";
		var product = LoanAffordabilityCalculator.formatProductDisplay(data.loanType);
		var security = LoanProductRates.normalizeSecurity(data.security);
		var securityLabel = security == "secured" ? "Secured" : "Unsecured";
		var housing = LoanAffordabilityCalculator.formatLorDisplay(Std.parseFloat(StringTools.trim(data.spendHousing)) != null
			? Std.parseFloat(StringTools.trim(data.spendHousing)) : 0);
		var living = LoanAffordabilityCalculator.formatLorDisplay(Std.parseFloat(StringTools.trim(data.spendLiving)) != null
			? Std.parseFloat(StringTools.trim(data.spendLiving)) : 0);
		var other = LoanAffordabilityCalculator.formatLorDisplay(Std.parseFloat(StringTools.trim(data.spendOther)) != null
			? Std.parseFloat(StringTools.trim(data.spendOther)) : 0);
		var expensesLine = '$housing, $living, $other (${LoanAffordabilityCalculator.formatLorDisplay(calc.totalSpending)}/mo)';
		var obligations = calc.monthlyPayment + calc.totalSpending;
		var freeCashAfter = calc.freeCashPerMonth;
		var dtiLine = LoanAffordabilityCalculator.formatPercentDisplay(calc.dtiPercent);
		if (calc.verdict == "AFFORDABLE")
			dtiLine += " - $Affordable$";

		var salaryVal = Std.parseFloat(StringTools.trim(data.declaredSalary));

		return [
			labeledLine("National ID", data.nationalId),
			labeledLine("Application", id),
			labeledLine("Product", '$product / $securityLabel'),
			labeledLine("Loan", '${LoanAffordabilityCalculator.formatLorDisplay(calc.amountFinanced)} LOR / ${data.term} months'),
			labeledLine("Rates", '${LoanAffordabilityCalculator.formatPercentDisplay(calc.noteRate)} / ${LoanAffordabilityCalculator.formatPercentDisplay(calc.aprPercent)} APR'),
			labeledLine("Salary", '${LoanAffordabilityCalculator.formatLorDisplay(salaryVal != null ? salaryVal : 0)} LOR/mo'),
			labeledLine("Expenses", expensesLine),
			labeledLine("Loan Rate", '${LoanAffordabilityCalculator.formatLorDisplay(calc.monthlyPayment)} LOR/mo'),
			labeledLine("All financial Obligations", '${LoanAffordabilityCalculator.formatLorDisplay(obligations)} LOR/mo'),
			labeledLine("Free cash after loan", '${LoanAffordabilityCalculator.formatLorDisplay(freeCashAfter)} LOR/mo'),
			labeledLine("Room after loan", LoanAffordabilityCalculator.formatPercentDisplay(calc.affordabilityPercent)),
			labeledLine("Finance charge", '${LoanAffordabilityCalculator.formatLorDisplay(calc.financeCharge)} LOR'),
			labeledLine("Total payments", '${LoanAffordabilityCalculator.formatLorDisplay(calc.totalOfPayments)} LOR'),
			"@DTI:@ " + dtiLine
		].join("\n");
	}

	static function labeledLine(label:String, value:String):String
	{
		return "@" + label + ":@ " + value;
	}

	public static function stripFormBodyMarkup(text:String):String
	{
		return StringTools.replace(StringTools.replace(StringTools.replace(text, "@", ""), "$", ""), "#", "");
	}

	public static function bodyBlockCount(?layout:BankDocumentLayout):Int
	{
		return 3;
	}

	public static function fieldValue(citizen:Citizen, kind:BankDocumentFieldKind):String
	{
		switch (kind)
		{
			case AccountHolder:
				return citizen.firstName + " " + citizen.lastName;
			case Date:
				return formatBankDate(citizen.passportIssued != "" ? citizen.passportIssued : citizen.passportDoc.issuedDate);
		}
	}

	static function formatBankDate(iso:String):String
	{
		if (iso == null || iso == "")
			return "";
		var parts = iso.split("-");
		if (parts.length != 3)
			return iso;
		return parts[2] + "." + parts[1] + "." + parts[0];
	}
}
