package;

typedef BankDocumentTextBlock = {
	var text:String;
	var x:Float;
	var y:Float;
	var width:Float;
	var fontSize:Null<Int>;
	var bold:Bool;
	var color:Null<Int>;
	var leading:Null<Int>;
	var align:Null<String>;
	var ?wordWrap:Bool;
}

typedef BankDocumentFieldSlot = {
	var kind:BankDocumentFieldKind;
	var x:Float;
	var y:Float;
	var width:Null<Float>;
	var fontSize:Null<Int>;
}

typedef BankDocumentLayout = {
	var documentPath:String;
	var title:BankDocumentTextBlock;
	var formBody:BankDocumentTextBlock;
	var disclaimer:BankDocumentTextBlock;
	var fields:Array<BankDocumentFieldSlot>;
	var valueColor:Int;
}
