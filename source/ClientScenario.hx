package;

class ClientScenario
{
	public var portraitPath:String;
	public var citizenIndex:Int;
	public var silent:Bool;
	public var autoDeliverDocuments:Bool;
	public var idVariant:Null<IdCardVariant>;
	public var expectedAmount:Float;
	public var expectedLoanType:String;
	public var expectedSecurity:String;
	public var expectedTerms:Array<Int>;
	public var expectedComfortablePayment:Float;
	public var comfortablePaymentTolerance:Float;
	public var expectedSpendHousing:Float;
	public var expectedSpendLiving:Float;
	public var expectedSpendOther:Float;

	public function new(
		portraitPath:String,
		citizenIndex:Int,
		silent:Bool,
		autoDeliverDocuments:Bool,
		idVariant:Null<IdCardVariant>,
		expectedAmount:Float,
		expectedLoanType:String,
		expectedSecurity:String,
		expectedTerms:Array<Int>,
		expectedComfortablePayment:Float,
		comfortablePaymentTolerance:Float,
		expectedSpendHousing:Float,
		expectedSpendLiving:Float,
		expectedSpendOther:Float
	)
	{
		this.portraitPath = portraitPath;
		this.citizenIndex = citizenIndex;
		this.silent = silent;
		this.autoDeliverDocuments = autoDeliverDocuments;
		this.idVariant = idVariant;
		this.expectedAmount = expectedAmount;
		this.expectedLoanType = expectedLoanType;
		this.expectedSecurity = expectedSecurity;
		this.expectedTerms = expectedTerms;
		this.expectedComfortablePayment = expectedComfortablePayment;
		this.comfortablePaymentTolerance = comfortablePaymentTolerance;
		this.expectedSpendHousing = expectedSpendHousing;
		this.expectedSpendLiving = expectedSpendLiving;
		this.expectedSpendOther = expectedSpendOther;
	}

	public function expectedMonthlySalary(citizen:Citizen):Float
	{
		if (citizen.averageAnnualSalary <= 0)
			return 0;
		return Math.round(citizen.averageAnnualSalary / 12);
	}

	public function openingMessages():Array<String>
	{
		return ClientScenarios.openingMessagesFor(this);
	}

	public function thanksMessages():Array<String>
	{
		return ClientScenarios.thanksMessagesFor(this);
	}

	public function bookScanSteps(actionId:String, timesAskedPreviously:Int):Null<Array<ClientConvStep>>
	{
		return ClientScenarios.bookScanStepsFor(this, actionId, timesAskedPreviously);
	}

	public function smallTalkChoiceLabel():Null<String>
	{
		return ClientScenarios.smallTalkChoiceLabelFor(this);
	}

	public function smallTalkSteps():Null<Array<ClientConvStep>>
	{
		return ClientScenarios.smallTalkStepsFor(this);
	}
}
