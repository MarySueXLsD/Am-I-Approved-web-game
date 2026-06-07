package;

typedef JobContractRegionScan = {
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
	@:optional var pad:Null<Float>;
}

typedef JobContractLayout = {
	var documentPath:String;
	var nameScan:JobContractRegionScan;
	var salaryScan:JobContractRegionScan;
}
