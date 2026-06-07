package;

import StringTools;

class LoanApplicationValidator
{
	static inline var AMOUNT_TOLERANCE = 1.0;

	public static function review(citizen:Citizen, scenario:ClientScenario, data:Null<LoanApplicationData>, loanId:Null<String>):LoanReviewResult
	{
		var errors:Array<String> = [];

		if (data == null)
		{
			errors.push("No loan application was submitted.");
			return {approved: false, errors: errors, grantLines: []};
		}

		if (StringTools.trim(data.nationalId) != citizen.nationalId)
			errors.push("National ID on the application does not match the applicant (" + citizen.nationalId + ").");

		if (scenario.expectedAmount > 0)
		{
			var amount = parseAmount(data.amount);
			if (amount == null || Math.abs(amount - scenario.expectedAmount) > AMOUNT_TOLERANCE)
				errors.push("Loan amount should be " + LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedAmount) + " LOR.");
		}

		if (scenario.expectedLoanType.length > 0)
		{
			var product = LoanProductRates.normalizeProduct(data.loanType);
			if (product != scenario.expectedLoanType)
				errors.push("Loan product should be " + LoanAffordabilityCalculator.formatProductDisplay(scenario.expectedLoanType) + ".");
		}

		if (scenario.expectedSecurity.length > 0)
		{
			var security = LoanProductRates.normalizeSecurity(data.security);
			if (security != scenario.expectedSecurity)
				errors.push("Security type should be " + (scenario.expectedSecurity == "secured" ? "Secured" : "Unsecured") + ".");
		}

		if (scenario.expectedTerms.length > 0)
		{
			var term = parseTerm(data.term);
			if (term == null || scenario.expectedTerms.indexOf(term) < 0)
				errors.push("Loan term does not match the client's preferred monthly payment.");
		}

		if (scenario.expectedComfortablePayment > 0 && scenario.comfortablePaymentTolerance > 0)
		{
			var calcForPayment = LoanAffordabilityCalculator.compute(data);
			if (calcForPayment.ready)
			{
				var lo = scenario.expectedComfortablePayment - scenario.comfortablePaymentTolerance;
				var hi = scenario.expectedComfortablePayment + scenario.comfortablePaymentTolerance;
				if (calcForPayment.monthlyPayment < lo || calcForPayment.monthlyPayment > hi)
				{
					errors.push("Monthly payment should be around "
						+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedComfortablePayment)
						+ " LOR (±" + LoanAffordabilityCalculator.formatLorDisplay(scenario.comfortablePaymentTolerance) + ").");
				}
			}
		}

		var expectedMonthly = scenario.expectedMonthlySalary(citizen);
		if (expectedMonthly > 0)
		{
			var salary = parseAmount(data.declaredSalary);
			if (salary == null || Math.abs(salary - expectedMonthly) > AMOUNT_TOLERANCE)
			{
				errors.push("Monthly salary should be " + LoanAffordabilityCalculator.formatLorDisplay(expectedMonthly)
					+ " LOR (annual salary " + LoanAffordabilityCalculator.formatLorDisplay(citizen.averageAnnualSalary)
					+ " LOR ÷ 12).");
			}
		}

		if (scenario.expectedSpendHousing > 0)
		{
			var housing = parseAmount(data.spendHousing);
			if (housing == null || Math.abs(housing - scenario.expectedSpendHousing) > AMOUNT_TOLERANCE)
				errors.push("Housing expense should be " + LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendHousing) + " LOR/mo.");
		}

		if (scenario.expectedSpendLiving > 0)
		{
			var living = parseAmount(data.spendLiving);
			if (living == null || Math.abs(living - scenario.expectedSpendLiving) > AMOUNT_TOLERANCE)
				errors.push("Living expense should be " + LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendLiving) + " LOR/mo.");
		}

		if (scenario.expectedSpendOther > 0)
		{
			var other = parseAmount(data.spendOther);
			if (other == null || Math.abs(other - scenario.expectedSpendOther) > AMOUNT_TOLERANCE)
				errors.push("Other expense should be " + LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendOther) + " LOR/mo.");
		}

		var calc = LoanAffordabilityCalculator.compute(data);
		if (!calc.ready)
			errors.push("Loan application is incomplete — fill all required fields.");
		else if (calc.verdict != "AFFORDABLE")
			errors.push("Loan is not affordable with the stated income and expenses (" + formatVerdict(calc.verdict) + ").");

		if (errors.length > 0)
			return {approved: false, errors: errors, grantLines: []};

		var id = loanId != null && loanId != "" ? loanId : "—";
		var product = LoanAffordabilityCalculator.formatProductDisplay(data.loanType);
		var securityLabel = LoanProductRates.normalizeSecurity(data.security) == "secured" ? "Secured" : "Unsecured";

		var grantLines = [
			"Applicant: " + citizen.firstName + " " + citizen.lastName,
			"Loan ID: " + id,
			"Amount: " + LoanAffordabilityCalculator.formatLorDisplay(calc.amountFinanced) + " LOR",
			"Product: " + product + " / " + securityLabel,
			"Term: " + data.term + " months",
			"Note rate: " + LoanAffordabilityCalculator.formatPercentDisplay(calc.noteRate),
			"Monthly payment: " + LoanAffordabilityCalculator.formatLorDisplay(calc.monthlyPayment) + " LOR",
			"",
			"The loan has been approved and may be granted to the client."
		];

		return {approved: true, errors: [], grantLines: grantLines};
	}

	public static function clientFacingErrors(citizen:Citizen, scenario:ClientScenario, data:Null<LoanApplicationData>):Array<String>
	{
		var messages:Array<String> = [];

		if (data == null)
		{
			messages.push("I don't see a loan application here yet.");
			return messages;
		}

		if (StringTools.trim(data.nationalId) != citizen.nationalId)
			messages.push("That's not my national ID on the application.");

		if (scenario.expectedAmount > 0)
		{
			var amount = parseAmount(data.amount);
			if (amount == null || Math.abs(amount - scenario.expectedAmount) > AMOUNT_TOLERANCE)
				messages.push("That's not the amount I asked for — I need around "
					+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedAmount) + " LOR.");
		}

		if (scenario.expectedLoanType.length > 0)
		{
			var product = LoanProductRates.normalizeProduct(data.loanType);
			if (product != scenario.expectedLoanType)
				messages.push("That's not the kind of loan I wanted.");
		}

		if (scenario.expectedSecurity.length > 0)
		{
			var security = LoanProductRates.normalizeSecurity(data.security);
			if (security != scenario.expectedSecurity)
			{
				messages.push(scenario.expectedSecurity == "secured"
					? "I asked for a secured loan."
					: "I asked for an unsecured loan.");
			}
		}

		var expectedMonthly = scenario.expectedMonthlySalary(citizen);
		if (expectedMonthly > 0)
		{
			var salary = parseAmount(data.declaredSalary);
			if (salary == null || Math.abs(salary - expectedMonthly) > AMOUNT_TOLERANCE)
			{
				if (salary != null && salary < expectedMonthly)
					messages.push("But I earn more than that! You filled my salary wrong.");
				else
					messages.push("I don't earn that much — you got my salary wrong.");
			}
		}

		if (scenario.expectedSpendHousing > 0)
		{
			var housing = parseAmount(data.spendHousing);
			if (housing == null || Math.abs(housing - scenario.expectedSpendHousing) > AMOUNT_TOLERANCE)
				messages.push("My housing costs aren't " + formatExpenseValue(housing) + " — rent is about "
					+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendHousing) + " LOR.");
		}

		if (scenario.expectedSpendLiving > 0)
		{
			var living = parseAmount(data.spendLiving);
			if (living == null || Math.abs(living - scenario.expectedSpendLiving) > AMOUNT_TOLERANCE)
				messages.push("My living expenses aren't right on there — they're closer to "
					+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendLiving) + " LOR a month.");
		}

		if (scenario.expectedSpendOther > 0)
		{
			var other = parseAmount(data.spendOther);
			if (other == null || Math.abs(other - scenario.expectedSpendOther) > AMOUNT_TOLERANCE)
				messages.push("The other expenses look off — mine are around "
					+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedSpendOther) + " LOR.");
		}

		if (scenario.expectedTerms.length > 0)
		{
			var term = parseTerm(data.term);
			if (term == null || scenario.expectedTerms.indexOf(term) < 0)
			{
				messages.push("That monthly payment doesn't work for me — I wanted something closer to "
					+ LoanAffordabilityCalculator.formatLorDisplay(scenario.expectedComfortablePayment)
					+ " LOR a month.");
			}
		}

		var calc = LoanAffordabilityCalculator.compute(data);
		if (calc.ready && calc.verdict == "NOT AFFORDABLE" && messages.length == 0)
			messages.push("With those numbers I don't think I could keep up with the payments...");

		return messages;
	}

	static function formatExpenseValue(value:Null<Float>):String
	{
		if (value == null)
			return "that";
		return LoanAffordabilityCalculator.formatLorDisplay(value) + " LOR";
	}

	static function parseAmount(raw:String):Null<Float>
	{
		var trimmed = StringTools.trim(raw);
		if (trimmed.length == 0)
			return null;
		var n = Std.parseFloat(trimmed);
		if (n == null || n < 0)
			return null;
		return n;
	}

	static function parseTerm(raw:String):Null<Int>
	{
		var trimmed = StringTools.trim(raw);
		if (trimmed.length == 0)
			return null;
		var n = Std.parseInt(trimmed);
		if (n == null || n < 1)
			return null;
		return n;
	}

	static function formatVerdict(verdict:String):String
	{
		return switch (verdict)
		{
			case "AFFORDABLE": "Affordable";
			case "MARGINAL": "Marginal";
			case "NOT AFFORDABLE": "Not affordable";
			default: verdict;
		};
	}
}
