typedef IdCardFieldSlot = {
	var label:String;
	var kind:IdCardFieldKind;
	var x:Float;
	var y:Float;
}

typedef IdCardEmblemLayout = {
	var path:String;
	var width:Float;
	var height:Float;
	var marginRight:Float;
	var marginBottom:Float;
	var angle:Float;
}

typedef IdCardNationalityLayout = {
	var xOffset:Float;
	var yExtra:Float;
	var color:Int;
}

typedef IdCardLayout = {
	var closeupPath:String;
	var photoX:Float;
	var photoY:Float;
	var photoW:Float;
	var photoH:Float;
	var fields:Array<IdCardFieldSlot>;
	var showFieldTitles:Bool;
	var labelColor:Int;
	var valueColor:Int;
	var fieldValueGap:Float;
	var valueFontSize:Null<Int>;
	var emblem:Null<IdCardEmblemLayout>;
	var nationality:Null<IdCardNationalityLayout>;
}
