package;

typedef ClientConvStep = {
	type:Int,
	text:String,
	?choices:Array<String>,
	?altSteps:Array<ClientConvStep>,
}
