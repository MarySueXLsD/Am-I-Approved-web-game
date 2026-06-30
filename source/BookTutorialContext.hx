package;

typedef BookTutorialContext =
{
	scanActive:Bool,
	paperOnPrinter:Bool,
	docOnDesk:Bool,
	printedOnClientTable:Bool,
	printedOnEmployerDesk:Bool,
	draggingPrintedRecord:Bool,
	printedHighlight:Null<TutorialGuideRect>,
	clientHighlight:TutorialGuideRect,
	scanHintHighlight:Null<TutorialGuideRect>,
	questionHighlight:Null<TutorialGuideRect>,
	hasPrintedSelection:Bool,
	hasBookQuestionSelection:Bool,
	hasClientSelection:Bool,
	actionReady:Bool,
	bookOnEmployerTable:Bool,
	bookSlideComplete:Bool,
	bookSlideAnimating:Bool,
	onQuestionsSpread:Bool,
	bookFrameHighlight:Null<TutorialGuideRect>,
	tocQuestionsHighlight:Null<TutorialGuideRect>,
	shredderHighlight:Null<TutorialGuideRect>,
}
