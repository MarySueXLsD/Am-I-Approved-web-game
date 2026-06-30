package;

typedef LoanFolderTutorialContext =
{
	folderVisible:Bool,
	folderSpreadOpen:Bool,
	chefIdOnClientTable:Bool,
	chefIdDragging:Bool,
	chefIdOnPrinter:Bool,
	printerCanAccept:Bool,
	idCopyOnPrinter:Bool,
	hasIdCopy:Bool,
	hasChecklistCopy:Bool,
	hasFormCopy:Bool,
	folderComplete:Bool,
	folderApprovalRequested:Bool,
	computerHighlight:TutorialGuideRect,
	printerHighlight:Null<TutorialGuideRect>,
	folderArrowHighlight:Null<TutorialGuideRect>,
	folderStorageHighlight:Null<TutorialGuideRect>,
}
