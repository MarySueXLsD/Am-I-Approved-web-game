package;

typedef PassportFieldSlot = {
	var kind:PassportFieldKind;
	var x:Float;
	var y:Float;
	var width:Null<Float>;
	var fontSize:Null<Int>;
}

typedef PassportLayout = {
	var openPath:String;
	var photoX:Float;
	var photoY:Float;
	var photoW:Float;
	var photoH:Float;
	var fields:Array<PassportFieldSlot>;
	var valueColor:Int;
}
