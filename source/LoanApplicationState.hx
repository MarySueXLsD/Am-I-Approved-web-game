package;

class LoanApplicationState
{
	static var nextId = 472622;

	public var loanId:Null<String> = null;
	public var data:Null<LoanApplicationData> = null;
	public var pendingFolderSlide = false;
	public var pendingAutoPrintLoanForm = false;

	public function new() {}

	public function hasApplication():Bool
	{
		return loanId != null;
	}

	public function submit(data:LoanApplicationData):String
	{
		loanId = formatLoanId(nextId++);
		this.data = data;
		pendingFolderSlide = true;
		pendingAutoPrintLoanForm = true;
		return loanId;
	}

	public function consumeAutoPrintLoanForm():Bool
	{
		if (!pendingAutoPrintLoanForm)
			return false;
		pendingAutoPrintLoanForm = false;
		return true;
	}

	public function consumeFolderSlide():Bool
	{
		if (!pendingFolderSlide)
			return false;
		pendingFolderSlide = false;
		return true;
	}

	public function reset():Void
	{
		loanId = null;
		data = null;
		pendingFolderSlide = false;
		pendingAutoPrintLoanForm = false;
	}

	static function formatLoanId(n:Int):String
	{
		return "LN-" + Std.string(n);
	}
}
