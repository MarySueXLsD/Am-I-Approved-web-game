package;

import StringTools;

typedef LoanCalcResult = {
	var ready:Bool;
	var baseRate:Float;
	var noteRate:Float;
	var aprPercent:Float;
	var amountDiscount:Float;
	var securityAdjustment:Float;
	var amountFinanced:Float;
	var financeCharge:Float;
	var totalOfPayments:Float;
	var monthlyPayment:Float;
	var totalSpending:Float;
	var disposableIncome:Float;
	var freeCashPerMonth:Float;
	var dtiPercent:Float;
	var paymentShareOfDisposable:Float;
	var affordabilityPercent:Float;
	var verdict:String;
	var verdictColor:Int;
	var lines:Array<String>;
}

class LoanAffordabilityCalculator
{
	public static inline var SECTION_MARK = "::";
	public static inline var FIELD_SEP = "\x17";

	static inline var AFFORDABLE_MIN_REMAINING = 30.0;
	static inline var MARGINAL_MIN_REMAINING = 10.0;
	static inline var MAX_DTI_AFFORDABLE = 35.0;
	static inline var MAX_DTI_MARGINAL = 45.0;

	public static function compute(data:LoanApplicationData):LoanCalcResult
	{
		var amount = parsePositive(data.amount);
		var term = parsePositiveInt(data.term);
		var salary = parsePositive(data.declaredSalary);
		var housing = parseNonNegative(data.spendHousing);
		var living = parseNonNegative(data.spendLiving);
		var other = parseNonNegative(data.spendOther);
		var productKey = LoanProductRates.normalizeProduct(data.loanType);
		var security = LoanProductRates.normalizeSecurity(data.security);

		var incomplete:LoanCalcResult = {
			ready: false,
			baseRate: 0,
			noteRate: 0,
			aprPercent: 0,
			amountDiscount: 0,
			securityAdjustment: 0,
			amountFinanced: 0,
			financeCharge: 0,
			totalOfPayments: 0,
			monthlyPayment: 0,
			totalSpending: 0,
			disposableIncome: 0,
			freeCashPerMonth: 0,
			dtiPercent: 0,
			paymentShareOfDisposable: 0,
			affordabilityPercent: 0,
			verdict: "ENTER VALUES",
			verdictColor: MonitorScreenUi.GREEN_DIM,
			lines: ["Fill loan product, amount, term,", "security, salary, and spending."]
		};

		if (amount == null || term == null || term < 1 || salary == null)
			return incomplete;
		if (!hasRequiredSpendingFields(data))
			return incomplete;
		if (security.length == 0 || !isValidSecurity(security))
			return incomplete;
		if (!LoanProductRates.isKnownProduct(productKey))
			return incomplete;

		var rates = LoanProductRates.resolve(productKey, amount, security);
		var amountFinanced = amount;
		var monthlyRate = rates.noteRate / 100 / 12;
		var payment = amortizedPayment(amountFinanced, term, monthlyRate);
		var totalOfPayments = payment * term;
		var financeCharge = totalOfPayments - amountFinanced;

		var totalSpending = housing + living + other;
		var disposable = salary - totalSpending;
		var freeCash = salary - payment - totalSpending;
		var dti = salary > 0 ? payment / salary * 100 : 0.0;

		var paymentShare = 0.0;
		var affordPct = 0.0;
		if (disposable > 0)
		{
			paymentShare = payment / disposable * 100;
			affordPct = (disposable - payment) / disposable * 100;
		}
		else if (disposable <= 0 && payment > 0)
		{
			paymentShare = 100;
			affordPct = 0;
		}

		var verdict = assessVerdict(disposable, affordPct, dti);
		var verdictColor = verdictColorFor(verdict);
		var securityLabel = security == "secured" ? "Secured" : "Unsecured";

		var lines = [
			sectionLine("RATE & PRICING"),
			dataLine("Loan Product", formatProductLabel(productKey)),
			dataLine("Security", securityLabel),
			dataLine("Base Rate", formatPercent(rates.baseRate)),
			dataLine("Amount discount", '-${formatPercent(rates.amountDiscount)}'),
			dataLine("Security adj.", formatSignedPercent(rates.securityAdjustment)),
			dataLine("Note Rate", formatPercent(rates.noteRate)),
			dataLine("APR", formatPercent(rates.aprPercent)),
			"",
			sectionLine("LOAN DISCLOSURE"),
			dataLine("Amount Financed", '${formatLor(amountFinanced)} LOR'),
			dataLine("Finance Charge", '${formatLor(financeCharge)} LOR'),
			dataLine("Total of Payments", '${formatLor(totalOfPayments)} LOR'),
			dataLine("Term", '$term months'),
			"",
			sectionLine("MONTHLY CASH FLOW"),
			dataLine("Salary/mo", '${formatLor(salary)} LOR'),
			dataLine("Spending/mo", '${formatLor(totalSpending)} LOR'),
			dataLine("Loan rate/mo", '${formatLor(payment)} LOR'),
			dataLine("Free cash before loan/mo", '${formatLor(disposable)} LOR'),
			dataLine("Free cash after loan/mo", '${formatLor(freeCash)} LOR'),
			"",
			sectionLine("AFFORDABILITY"),
			dataLine("Debt-to-Income (DTI)", formatPercent(dti)),
			dataLine("Loan uses", '${formatPercent(paymentShare)} of free cash'),
			dataLine("Room after loan", formatPercent(affordPct)),
			verdictLine(verdict)
		];

		return {
			ready: true,
			baseRate: rates.baseRate,
			noteRate: rates.noteRate,
			aprPercent: rates.aprPercent,
			amountDiscount: rates.amountDiscount,
			securityAdjustment: rates.securityAdjustment,
			amountFinanced: amountFinanced,
			financeCharge: financeCharge,
			totalOfPayments: totalOfPayments,
			monthlyPayment: payment,
			totalSpending: totalSpending,
			disposableIncome: disposable,
			freeCashPerMonth: freeCash,
			dtiPercent: dti,
			paymentShareOfDisposable: paymentShare,
			affordabilityPercent: affordPct,
			verdict: verdict,
			verdictColor: verdictColor,
			lines: lines
		};
	}

	public static function sectionLine(title:String):String
	{
		return SECTION_MARK + title;
	}

	public static function isSectionLine(line:String):Bool
	{
		return StringTools.startsWith(line, SECTION_MARK);
	}

	public static function sectionLabel(line:String):String
	{
		return isSectionLine(line) ? line.substr(SECTION_MARK.length) : line;
	}

	public static function dataLine(label:String, value:String):String
	{
		return label + FIELD_SEP + value;
	}

	public static function verdictLine(verdict:String):String
	{
		return ">>" + FIELD_SEP + formatVerdictLabel(verdict);
	}

	public static function isDataLine(line:String):Bool
	{
		return line.indexOf(FIELD_SEP) >= 0;
	}

	public static function parseDataLine(line:String):{label:String, value:String}
	{
		var sep = line.indexOf(FIELD_SEP);
		if (sep < 0)
			return {label: line, value: ""};
		return {
			label: line.substr(0, sep),
			value: line.substr(sep + FIELD_SEP.length)
		};
	}

	static function isValidSecurity(security:String):Bool
	{
		return security == "secured" || security == "unsecured";
	}

	static function formatProductLabel(productKey:String):String
	{
		if (productKey.length == 0)
			return productKey;

		var parts = productKey.split(" ");
		var out:Array<String> = [];
		for (part in parts)
		{
			if (part.length > 0)
				out.push(part.charAt(0).toUpperCase() + part.substr(1));
		}
		return out.join(" ");
	}

	static function formatSignedPercent(value:Float):String
	{
		if (value > 0.05)
			return '+${formatPercent(value)}';
		if (value < -0.05)
			return '-${formatPercent(-value)}';
		return '0%';
	}

	static function hasRequiredSpendingFields(data:LoanApplicationData):Bool
	{
		return StringTools.trim(data.spendHousing).length > 0 && StringTools.trim(data.spendLiving).length > 0;
	}

	static function amortizedPayment(principal:Float, months:Int, monthlyRate:Float):Float
	{
		if (months <= 0)
			return 0;
		if (monthlyRate <= 0.0000001)
			return principal / months;
		var factor = Math.pow(1 + monthlyRate, months);
		return principal * monthlyRate * factor / (factor - 1);
	}

	static function assessVerdict(disposable:Float, affordPct:Float, dti:Float):String
	{
		if (disposable <= 0)
			return "NOT AFFORDABLE";
		if (affordPct < 0)
			return "NOT AFFORDABLE";
		if (dti > MAX_DTI_MARGINAL || affordPct < MARGINAL_MIN_REMAINING)
			return "NOT AFFORDABLE";
		if (dti > MAX_DTI_AFFORDABLE || affordPct < AFFORDABLE_MIN_REMAINING)
			return "MARGINAL";
		return "AFFORDABLE";
	}

	static function verdictColorFor(verdict:String):Int
	{
		switch (verdict)
		{
			case "AFFORDABLE":
				return MonitorScreenUi.GREEN_BRIGHT;
			case "MARGINAL":
				return 0xFFD4C44A;
			default:
				return 0xFFE85A5A;
		}
	}

	static function formatVerdictLabel(verdict:String):String
	{
		switch (verdict)
		{
			case "AFFORDABLE":
				return "Affordable";
			case "MARGINAL":
				return "Marginal";
			case "NOT AFFORDABLE":
				return "Not affordable";
			default:
				return verdict;
		}
	}

	static function parsePositive(raw:String):Null<Float>
	{
		var n = parseNonNegative(raw);
		if (n <= 0)
			return null;
		return n;
	}

	static function parsePositiveInt(raw:String):Null<Int>
	{
		var trimmed = StringTools.trim(raw);
		if (trimmed.length == 0)
			return null;
		var n = Std.parseInt(trimmed);
		if (n == null || n < 1)
			return null;
		return n;
	}

	static function parseNonNegative(raw:String):Float
	{
		var trimmed = StringTools.trim(raw);
		if (trimmed.length == 0)
			return 0;
		var n = Std.parseFloat(trimmed);
		if (n == null || n < 0)
			return 0;
		return n;
	}

	static function formatLor(value:Float):String
	{
		var rounded = Std.int(Math.round(value));
		var negative = rounded < 0;
		var digits = Std.string(negative ? -rounded : rounded);
		var out = "";
		var count = 0;
		for (i in 0...digits.length)
		{
			var pos = digits.length - 1 - i;
			if (count > 0 && count % 3 == 0)
				out = "," + out;
			out = digits.charAt(pos) + out;
			count++;
		}
		return negative ? "-" + out : out;
	}

	static function formatPercent(value:Float):String
	{
		var rounded = Math.round(value * 10) / 10;
		if (Math.abs(rounded - Std.int(rounded)) < 0.05)
			return '${Std.int(rounded)}%';
		return '${rounded}%';
	}

	public static function formatLorDisplay(value:Float):String
	{
		return formatLor(value);
	}

	public static function formatPercentDisplay(value:Float):String
	{
		return formatPercent(value);
	}

	public static function formatProductDisplay(raw:String):String
	{
		return formatProductLabel(LoanProductRates.normalizeProduct(raw));
	}
}
