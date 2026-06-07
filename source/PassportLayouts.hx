package;

class PassportLayouts
{
	public static function lorian():PassportLayout
	{
		return {
			openPath: "static/lorian_open_passport.png",
			photoX: 42,
			photoY: 80,
			photoW: 108,
			photoH: 112,
			fields: [
				{kind: Name, x: 170, y: 120, width: 105, fontSize: null},
				{kind: Nationality, x: 170, y: 165, width: 105, fontSize: null},
				{kind: BirthDate, x: 170, y: 208, width: 105, fontSize: null},
				{kind: PlaceOfBirth, x: 170, y: 251, width: 105, fontSize: null},
				{kind: Issued, x: 34, y: 330, width: 62, fontSize: null},
				{kind: Expires, x: 104, y: 330, width: 72, fontSize: null},
				{kind: Authority, x: 189, y: 330, width: 84, fontSize: 8}
			],
			valueColor: 0xFF1A1A1A
		};
	}

	public static function fieldValue(citizen:Citizen, kind:PassportFieldKind):String
	{
		var doc = citizen.passportDoc;
		switch (kind)
		{
			case Name:
				return citizen.passportName != "" ? citizen.passportName : doc.lastName + ", " + doc.firstName;
			case Nationality:
				return citizen.nationality;
			case BirthDate:
				return formatPassportDate(doc.dateOfBirth != "" ? doc.dateOfBirth : citizen.dateOfBirth);
			case PlaceOfBirth:
				return doc.placeOfBirth != "" ? doc.placeOfBirth : citizen.placeOfBirth;
			case Issued:
				return formatPassportDate(citizen.passportIssued != "" ? citizen.passportIssued : doc.issuedDate);
			case Expires:
				return formatPassportDate(citizen.passportExpires != "" ? citizen.passportExpires : doc.dateOfExpiration);
			case Authority:
				return doc.issuingAuthority;
		}
	}

	static function formatPassportDate(iso:String):String
	{
		if (iso == null || iso == "")
			return "";
		var parts = iso.split("-");
		if (parts.length != 3)
			return iso;
		return parts[2] + "." + parts[1] + "." + parts[0];
	}
}
