class IdCardLayouts
{
	static var LORIAN_FIELD_DEFS:Array<{label:String, kind:IdCardFieldKind}> = [
		{label: "Name", kind: Name},
		{label: "National ID", kind: NationalId},
		{label: "Birth date", kind: BirthDate},
		{label: "Sex", kind: Sex}
	];

	static var KETHRAN_FIELD_DEFS:Array<{label:String, kind:IdCardFieldKind}> = [
		{label: "National ID", kind: NationalId},
		{label: "Name", kind: Name},
		{label: "Sex", kind: Sex},
		{label: "Birth date", kind: BirthDate}
	];

	static var OSTMARK_FIELD_DEFS:Array<{label:String, kind:IdCardFieldKind}> = [
		{label: "National ID", kind: NationalId},
		{label: "Name", kind: Name},
		{label: "Birth date", kind: BirthDate},
		{label: "Sex", kind: Sex}
	];

	public static function allVariants():Array<IdCardVariant>
	{
		return [Lorian, Kethran, Ostmark, Meridian];
	}

	public static function defaultDeskVariants():Array<IdCardVariant>
	{
		return [Lorian, Kethran, Ostmark];
	}

	public static function get(variant:IdCardVariant):IdCardLayout
	{
		switch (variant)
		{
			case Lorian:
				return lorian();
			case Kethran:
				return kethran();
			case Ostmark:
				return ostmark();
			case Meridian:
				return meridian();
		}
	}

	public static function fieldValue(citizen:Citizen, kind:IdCardFieldKind):String
	{
		var doc = citizen.idCardDoc;
		switch (kind)
		{
			case Name:
				return doc.lastName + ", " + doc.firstName;
			case NationalId:
				return doc.nationalId;
			case BirthDate:
				return doc.dateOfBirth;
			case Sex:
				return doc.sex;
		}
	}

	static function titledFields(defs:Array<{label:String, kind:IdCardFieldKind}>, x:Float, startY:Float, lineSpacing:Float):Array<{label:String, kind:IdCardFieldKind, x:Float, y:Float}>
	{
		var fields:Array<{label:String, kind:IdCardFieldKind, x:Float, y:Float}> = [];
		for (i in 0...defs.length)
		{
			var def = defs[i];
			fields.push({
				label: def.label,
				kind: def.kind,
				x: x,
				y: startY + lineSpacing * i
			});
		}
		return fields;
	}

	static function meridianValueFields():Array<{label:String, kind:IdCardFieldKind, x:Float, y:Float}>
	{
		return [
			{label: "", kind: NationalId, x: 50, y: 165},
			{label: "", kind: Name, x: 50, y: 230},
			{label: "", kind: Sex, x: 50, y: 295},
			{label: "", kind: BirthDate, x: 50, y: 360}
		];
	}

	static function lorian():IdCardLayout
	{
		return {
			closeupPath: "static/closeup_loria_ID.png",
			photoX: 38,
			photoY: 96,
			photoW: 176,
			photoH: 218,
			fields: titledFields(LORIAN_FIELD_DEFS, 225, 90, 52),
			showFieldTitles: true,
			labelColor: 0xFF1A4FA8,
			valueColor: 0xFF1A1A1A,
			fieldValueGap: 4,
			valueFontSize: null,
			emblem: {
				path: "static/lorian_emblem.png",
				width: 88 * 1.7,
				height: 65 * 1.7,
				marginRight: 130,
				marginBottom: 28 + 65 * 1.3,
				angle: 15.0
			},
			nationality: {
				xOffset: -36,
				yExtra: 34,
				color: 0xFFFFFFFF
			}
		};
	}

	static function kethran():IdCardLayout
	{
		return {
			closeupPath: "static/closeup_kethran_ID.png",
			photoX: 42,
			photoY: 128,
			photoW: 170,
			photoH: 227,
			fields: titledFields(KETHRAN_FIELD_DEFS, 225, 120, 50),
			showFieldTitles: true,
			labelColor: 0xFF1A3052,
			valueColor: 0xFF1A1A1A,
			fieldValueGap: 4,
			valueFontSize: 9,
			emblem: null,
			nationality: null
		};
	}

	static function ostmark():IdCardLayout
	{
		return {
			closeupPath: "static/closeup_ostmark_ID.png",
			photoX: 412,
			photoY: 157,
			photoW: 160,
			photoH: 200,
			fields: titledFields(OSTMARK_FIELD_DEFS, 45, 125, 56),
			showFieldTitles: true,
			labelColor: 0xFF0A2038,
			valueColor: 0xFF1A1A1A,
			fieldValueGap: 4,
			valueFontSize: 9,
			emblem: null,
			nationality: null
		};
	}

	static function meridian():IdCardLayout
	{
		return {
			closeupPath: "static/closeup_meridian_ID.png",
			photoX: 421,
			photoY: 141,
			photoW: 155,
			photoH: 206,
			fields: meridianValueFields(),
			showFieldTitles: false,
			labelColor: 0xFF1A3052,
			valueColor: 0xFF1A3052,
			fieldValueGap: 0,
			valueFontSize: null,
			emblem: null,
			nationality: null
		};
	}
}
