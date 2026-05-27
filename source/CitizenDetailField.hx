package;

typedef CitizenDetailField = {
	var path:String;
	var label:String;
	var value:String;
	@:optional var choices:Array<String>;
	@:optional var digitsOnly:Bool;
	@:optional var dateField:Bool;
}
