package;

class LoanChecklistItems
{
	public static function all():Array<LoanChecklistItem>
	{
		return [IdOrPassportCopy, LoanApplicationForm, LoanChecklist];
	}

	public static function isComplete(stored:Array<DeskDocument>):Bool
	{
		var completed = completedFromStored(stored);
		for (item in all())
		{
			if (completed.indexOf(item) < 0)
				return false;
		}
		return true;
	}

	public static function completedFromStored(stored:Array<DeskDocument>):Array<LoanChecklistItem>
	{
		var result:Array<LoanChecklistItem> = [];
		for (doc in stored)
		{
			if (isChecklistDocument(doc))
			{
				if (result.indexOf(LoanChecklist) < 0)
					result.push(LoanChecklist);
				continue;
			}

			for (item in all())
			{
				if (item == LoanChecklist)
					continue;
				if (result.indexOf(item) >= 0)
					continue;
				if (matches(doc, item))
					result.push(item);
			}
		}
		return result;
	}

	public static function matches(doc:DeskDocument, item:LoanChecklistItem):Bool
	{
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null)
			return bankDoc.matchesLoanChecklistItem(item);

		var paper = Std.downcast(doc, PrinterPaperDocument);
		if (paper != null)
			return paper.matchesLoanChecklistItem(item);

		return false;
	}

	static function isChecklistDocument(doc:DeskDocument):Bool
	{
		var bankDoc = Std.downcast(doc, BankDocument);
		if (bankDoc != null && bankDoc.getVariant() == BankDocumentVariant.LoanChecklist)
			return true;

		var paper = Std.downcast(doc, PrinterPaperDocument);
		return paper != null && paper.isLoanChecklistCopy();
	}
}
