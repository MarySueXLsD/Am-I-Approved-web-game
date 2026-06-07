package;

import StringTools;

typedef AmountTier = {
	var minAmount:Float;
	var rateDiscount:Float;
}

typedef ProductRateProfile = {
	var baseRate:Float;
	var aprSpread:Float;
	var securedDiscount:Float;
	var unsecuredPremium:Float;
}

typedef ResolvedLoanRates = {
	var productKey:String;
	var baseRate:Float;
	var amountDiscount:Float;
	var securityAdjustment:Float;
	var noteRate:Float;
	var aprPercent:Float;
}

class LoanProductRates
{
	static var PROFILES:Map<String, ProductRateProfile> = [
		"auto" => {
			baseRate: 7.5,
			aprSpread: 0.20,
			securedDiscount: 0.75,
			unsecuredPremium: 1.0
		},
		"personal" => {
			baseRate: 11.5,
			aprSpread: 0.30,
			securedDiscount: 0.50,
			unsecuredPremium: 1.25
		},
		"credit card" => {
			baseRate: 16.0,
			aprSpread: 0.15,
			securedDiscount: 1.0,
			unsecuredPremium: 2.0
		},
		"mortgage" => {
			baseRate: 5.25,
			aprSpread: 0.12,
			securedDiscount: 0.40,
			unsecuredPremium: 0.50
		}
	];

	static var AMOUNT_TIERS:Array<AmountTier> = [
		{minAmount: 0, rateDiscount: 0.0},
		{minAmount: 25000, rateDiscount: 0.25},
		{minAmount: 75000, rateDiscount: 0.50},
		{minAmount: 200000, rateDiscount: 0.75},
		{minAmount: 500000, rateDiscount: 1.0}
	];

	static var DEFAULT_PROFILE:ProductRateProfile = {
		baseRate: 10.0,
		aprSpread: 0.25,
		securedDiscount: 0.50,
		unsecuredPremium: 1.0
	};

	static inline var MIN_NOTE_RATE = 2.0;

	public static var LOAN_PRODUCTS:Array<String> = [
		"personal",
		"auto",
		"credit card",
		"mortgage"
	];

	public static var SECURITY_TYPES:Array<String> = ["secured", "unsecured"];

	public static function normalizeProduct(raw:String):String
	{
		return StringTools.trim(raw).toLowerCase();
	}

	public static function normalizeSecurity(raw:String):String
	{
		return StringTools.trim(raw).toLowerCase();
	}

	public static function isKnownProduct(productKey:String):Bool
	{
		return PROFILES.exists(productKey);
	}

	public static function resolve(productKey:String, amount:Float, securityRaw:String):ResolvedLoanRates
	{
		var profile = PROFILES.get(productKey);
		if (profile == null)
			profile = DEFAULT_PROFILE;

		var amountDiscount = amountTierDiscount(amount);
		var securityAdjustment = securityRateAdjustment(securityRaw, profile);
		var noteRate = profile.baseRate - amountDiscount + securityAdjustment;
		if (noteRate < MIN_NOTE_RATE)
			noteRate = MIN_NOTE_RATE;

		var apr = noteRate + profile.aprSpread;

		return {
			productKey: productKey,
			baseRate: profile.baseRate,
			amountDiscount: amountDiscount,
			securityAdjustment: securityAdjustment,
			noteRate: noteRate,
			aprPercent: apr
		};
	}

	static function amountTierDiscount(amount:Float):Float
	{
		var discount = 0.0;
		for (tier in AMOUNT_TIERS)
		{
			if (amount >= tier.minAmount)
				discount = tier.rateDiscount;
		}
		return discount;
	}

	static function securityRateAdjustment(securityRaw:String, profile:ProductRateProfile):Float
	{
		switch (normalizeSecurity(securityRaw))
		{
			case "secured":
				return -profile.securedDiscount;
			case "unsecured":
				return profile.unsecuredPremium;
			default:
				return 0.0;
		}
	}
}
