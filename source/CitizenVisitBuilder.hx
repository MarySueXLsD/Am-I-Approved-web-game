package;

import Reflect;

class CitizenVisitBuilder
{
	public static function scenarioFrom(citizen:Citizen, citizenIndex:Int, ?portraitPath:String = null, ?idVariantOverride:Null<IdCardVariant> = null):ClientScenario
	{
		var visit = citizen.visit;
		var portrait = portraitPath != null ? portraitPath : ClientPortraits.defaultPath();
		var autoDocs = false;
		var idVariant = idVariantOverride != null ? idVariantOverride : idVariantForCountry(citizen.country);
		var jobContract:Null<JobContractVariant> = null;

		if (visit == null)
		{
			return new ClientScenario(
				portrait,
				citizenIndex,
				false,
				autoDocs,
				idVariant,
				0, "", "", [],
				0, 0, 0, 0, 0,
				false
			);
		}

		var amount = visitFloat(visit, "loanAmountLOR");
		var product = visitString(visit, "loanProduct");
		var security = visitString(visit, "loanSecurity");
		var terms = visitIntArray(visit, "loanTerms");
		var comfortable = visitFloat(visit, "comfortablePaymentLOR");
		var comfortableTol = visitFloat(visit, "comfortablePaymentToleranceLOR");
		var housing = visitFloat(visit, "spendHousingLOR");
		var living = visitFloat(visit, "spendLivingLOR");
		var other = visitFloat(visit, "spendOtherLOR");
		var expectedAnnual = visitFloat(visit, "expectedSalaryLOR");
		var annualTol = visitFloat(visit, "salaryToleranceLOR");
		if (annualTol <= 0)
			annualTol = 100;

		if (citizenIndex == 40)
			jobContract = Kethran;

		var outcome = visitString(visit, "outcome");

		return new ClientScenario(
			portrait,
			citizenIndex,
			false,
			autoDocs,
			idVariant,
			amount,
			product,
			security,
			terms,
			comfortable,
			comfortableTol,
			housing,
			living,
			other,
			false,
			jobContract,
			-1,
			expectedAnnual,
			annualTol,
			false,
			outcome != "decline",
			false
		);
	}

	static function idVariantForCountry(country:String):IdCardVariant
	{
		return switch (country)
		{
			case "ostmark": Ostmark;
			default: Lorian;
		}
	}

	public static function dialogueFor(citizen:Citizen):Dynamic
	{
		if (citizen.visit == null)
			return null;
		return Reflect.field(citizen.visit, "dialogue");
	}

	public static function quickAnswer(dialogue:Dynamic, actionId:String):Null<String>
	{
		if (dialogue == null)
			return null;
		var quick = Reflect.field(dialogue, "quickAnswers");
		if (quick == null)
			return null;
		var answer = Reflect.field(quick, actionId);
		return answer != null ? Std.string(answer) : null;
	}

	public static function stringField(dialogue:Dynamic, field:String):Null<String>
	{
		if (dialogue == null)
			return null;
		var value = Reflect.field(dialogue, field);
		return value != null ? Std.string(value) : null;
	}

	public static function stringArrayField(dialogue:Dynamic, field:String):Array<String>
	{
		if (dialogue == null)
			return [];

		var raw = Reflect.field(dialogue, field);
		if (raw == null)
			return [];

		var out:Array<String> = [];
		for (entry in (raw : Array<Dynamic>))
			out.push(Std.string(entry));
		return out;
	}

	public static function boolField(dialogue:Dynamic, field:String):Bool
	{
		if (dialogue == null)
			return false;
		var value = Reflect.field(dialogue, field);
		return value == true;
	}

	static function visitString(visit:Dynamic, field:String):String
	{
		var value = Reflect.field(visit, field);
		return value != null ? Std.string(value) : "";
	}

	static function visitFloat(visit:Dynamic, field:String):Float
	{
		var value = Reflect.field(visit, field);
		if (value == null)
			return 0;
		var n = Std.parseFloat(Std.string(value));
		return n != null ? n : 0;
	}

	static function visitIntArray(visit:Dynamic, field:String):Array<Int>
	{
		var raw = Reflect.field(visit, field);
		if (raw == null)
			return [];

		var out:Array<Int> = [];
		for (entry in (raw : Array<Dynamic>))
		{
			var n = Std.parseInt(Std.string(entry));
			if (n != null)
				out.push(n);
		}
		return out;
	}
}
