package;

class MonitorDetailEntryRow
{
	static inline var COL_GAP = 8;

	public var left:MonitorDetailFieldRow;
	public var right:MonitorDetailFieldRow;
	var isPair = false;

	public function new()
	{
		left = new MonitorDetailFieldRow();
		right = new MonitorDetailFieldRow();
		right.visible = false;
	}

	public function setupSingle(def:CitizenDetailField, value:String):Void
	{
		isPair = false;
		left.setup(def.path, def.label, value, def.choices, def.digitsOnly, def.dateField, def.required, def.readOnly, def.allowDecimal);
		right.visible = false;
	}

	public function setupPair(leftDef:CitizenDetailField, leftValue:String, rightDef:CitizenDetailField,
			rightValue:String):Void
	{
		isPair = true;
		left.setup(leftDef.path, leftDef.label, leftValue, leftDef.choices, leftDef.digitsOnly, leftDef.dateField, leftDef.required,
			leftDef.readOnly, leftDef.allowDecimal);
		right.setup(rightDef.path, rightDef.label, rightValue, rightDef.choices, rightDef.digitsOnly, rightDef.dateField,
			rightDef.required, rightDef.readOnly, rightDef.allowDecimal);
	}

	public function getFieldRow(path:String):Null<MonitorDetailFieldRow>
	{
		if (left.path == path)
			return left;
		if (isPair && right.path == path)
			return right;
		return null;
	}

	public function tryFocusPath(mx:Float, my:Float):Null<String>
	{
		if (left.overlaps(mx, my))
			return left.path;
		if (isPair && right.overlaps(mx, my))
			return right.path;
		return null;
	}

	public function layout(x:Float, y:Float, w:Float, textSize:Int, focusedPath:String):Void
	{
		if (!isPair)
		{
			left.layout(x, y, w, textSize, focusedPath == left.path);
			return;
		}

		var halfW = (w - COL_GAP) * 0.5;
		left.layout(x, y, halfW, textSize, focusedPath == left.path);
		right.layout(x + halfW + COL_GAP, y, halfW, textSize, focusedPath == right.path);
		right.visible = true;
	}

	public static function contentHeight(textSize:Int):Int
	{
		return MonitorDetailFieldRow.contentHeight(textSize);
	}

	public static function rowHeight(textSize:Int):Int
	{
		return MonitorDetailFieldRow.rowHeight(textSize);
	}

	public static function visibleRowCount(panelH:Float, textSize:Int):Int
	{
		return MonitorDetailFieldRow.visibleRowCount(panelH, textSize);
	}

	public var visible(get, set):Bool;

	function get_visible():Bool
	{
		return left.visible;
	}

	function set_visible(v:Bool):Bool
	{
		left.visible = v;
		if (isPair)
			right.visible = v;
		else
			right.visible = false;
		return v;
	}

	public function addToDisplay(labelLayer:flixel.group.FlxGroup, inputLayer:flixel.group.FlxGroup):Void
	{
		labelLayer.add(left.labelText);
		labelLayer.add(left.valueText);
		labelLayer.add(right.labelText);
		labelLayer.add(right.valueText);
		inputLayer.add(left.box);
		inputLayer.add(left.hit);
		inputLayer.add(right.box);
		inputLayer.add(right.hit);
	}
}
