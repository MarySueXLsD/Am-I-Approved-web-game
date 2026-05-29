package;

#if js
import js.Browser;
#end
import haxe.Json;
import openfl.utils.Assets;
import StringTools;

class CitizenRegistry
{
	public static var all(default, null):Array<Citizen> = [];

	static var SAVE_KEY = "modified_citizens";

	public static function load():Void
	{
		if (all.length > 0)
			return;

		var raw:String = null;

		#if js
		try
		{
			var storage = Browser.getLocalStorage();
			if (storage != null)
			{
				var stored = storage.getItem(SAVE_KEY);
				if (stored != null && stored.length > 2)
					raw = stored;
			}
		}
		catch (e:Dynamic) {}
		#end

		if (raw == null)
			raw = Assets.getText("static/citizens.json");

		parseCitizensJson(raw);
	}

	public static function reload():Void
	{
		all = [];
		load();
	}

	public static function saveAllToStorage():Void
	{
		var citizenData:Array<Dynamic> = [];
		for (c in all)
			citizenData.push(serializeCitizen(c));

		var json = Json.stringify({citizens: citizenData});

		#if js
		try
		{
			var storage = Browser.getLocalStorage();
			if (storage != null)
				storage.setItem(SAVE_KEY, json);
		}
		catch (e:Dynamic) {}
		#end
	}

	static function parseCitizensJson(raw:String):Void
	{
		var data:Dynamic = Json.parse(raw);
		all = [];
		for (entry in (data.citizens : Array<Dynamic>))
		{
			var addr:Dynamic = entry.address;
			var emergency:Dynamic = entry.emergencyContact;
			var passportDoc:Dynamic = entry.passportDoc;
			var idCardDoc:Dynamic = entry.idCardDoc;
			var employmentContractDoc:Dynamic = entry.employmentContractDoc;
			var idCardAddress:Dynamic = idCardDoc != null ? idCardDoc.address : null;
			var flags:Array<String> = [];
			if (entry.bankRiskFlags != null)
			{
				for (flag in (entry.bankRiskFlags : Array<Dynamic>))
					flags.push(Std.string(flag));
			}

			all.push({
				registryId: entry.registryId,
				passportId: entry.passportId,
				nationalId: entry.nationalId,
				taxId: entry.taxId,
				firstName: entry.firstName,
				lastName: entry.lastName,
				passportName: entry.passportName,
				country: entry.country,
				countryFullName: entry.countryFullName,
				nationality: entry.nationality,
				dateOfBirth: entry.dateOfBirth,
				placeOfBirth: entry.placeOfBirth,
				sex: entry.sex,
				maritalStatus: entry.maritalStatus,
				occupation: entry.occupation,
				averageAnnualSalary: entry.averageAnnualSalary,
				salaryCurrency: entry.salaryCurrency,
				address: {
					street: addr != null ? addr.street : "",
					city: addr != null ? addr.city : "",
					region: addr != null ? addr.region : "",
					postalCode: addr != null ? addr.postalCode : "",
					country: addr != null ? addr.country : ""
				},
				phone: entry.phone,
				email: entry.email,
				bloodType: entry.bloodType,
				heightCm: entry.heightCm,
				eyeColor: entry.eyeColor,
				passportIssued: entry.passportIssued,
				passportExpires: entry.passportExpires,
				voterRegistered: voterFromJson(entry.voterRegistered),
				militaryService: entry.militaryService,
				emergencyContact: {
					name: emergency != null ? emergency.name : "",
					relationship: emergency != null ? emergency.relationship : "",
					phone: emergency != null ? emergency.phone : ""
				},
				bankRiskFlags: flags,
				criminalRecord: entry.criminalRecord,
				yearsAtAddress: entry.yearsAtAddress,
				dependents: Std.string(entry.dependents),
				passportDoc: {
					passportId: passportDoc != null ? passportDoc.passportId : "",
					nationalId: passportDoc != null ? passportDoc.nationalId : "",
					firstName: passportDoc != null ? passportDoc.firstName : "",
					lastName: passportDoc != null ? passportDoc.lastName : "",
					dateOfBirth: passportDoc != null ? passportDoc.dateOfBirth : "",
					sex: passportDoc != null ? passportDoc.sex : "",
					placeOfBirth: passportDoc != null ? passportDoc.placeOfBirth : "",
					issuingAuthority: passportDoc != null ? passportDoc.issuingAuthority : "",
					dateOfExpiration: passportDoc != null ? passportDoc.dateOfExpiration : "",
					issuedDate: passportDoc != null ? passportDoc.issuedDate : ""
				},
				idCardDoc: {
					nationalId: idCardDoc != null ? idCardDoc.nationalId : entry.nationalId,
					firstName: idCardDoc != null ? idCardDoc.firstName : entry.firstName,
					lastName: idCardDoc != null ? idCardDoc.lastName : entry.lastName,
					dateOfBirth: idCardDoc != null ? idCardDoc.dateOfBirth : entry.dateOfBirth,
					sex: idCardDoc != null ? idCardDoc.sex : entry.sex,
					address: {
						street: idCardAddress != null ? idCardAddress.street : (addr != null ? addr.street : ""),
						city: idCardAddress != null ? idCardAddress.city : (addr != null ? addr.city : ""),
						region: idCardAddress != null ? idCardAddress.region : (addr != null ? addr.region : ""),
						postalCode: idCardAddress != null ? idCardAddress.postalCode : (addr != null ? addr.postalCode : ""),
						country: idCardAddress != null ? idCardAddress.country : (addr != null ? addr.country : "")
					}
				},
				employmentContractDoc: {
					firstName: employmentContractDoc != null ? employmentContractDoc.firstName : entry.firstName,
					lastName: employmentContractDoc != null ? employmentContractDoc.lastName : entry.lastName,
					occupation: employmentContractDoc != null ? employmentContractDoc.occupation : entry.occupation,
					annualSalary: employmentContractDoc != null ? employmentContractDoc.annualSalary : entry.averageAnnualSalary,
					salaryCurrency: employmentContractDoc != null ? employmentContractDoc.salaryCurrency : entry.salaryCurrency
				}
			});
		}
	}

	static function serializeCitizen(c:Citizen):Dynamic
	{
		return {
			registryId: c.registryId,
			passportId: c.passportId,
			nationalId: c.nationalId,
			taxId: c.taxId,
			firstName: c.firstName,
			lastName: c.lastName,
			passportName: c.passportName,
			country: c.country,
			countryFullName: c.countryFullName,
			nationality: c.nationality,
			dateOfBirth: c.dateOfBirth,
			placeOfBirth: c.placeOfBirth,
			sex: c.sex,
			maritalStatus: c.maritalStatus,
			occupation: c.occupation,
			averageAnnualSalary: c.averageAnnualSalary,
			salaryCurrency: c.salaryCurrency,
			address: {
				street: c.address.street,
				city: c.address.city,
				region: c.address.region,
				postalCode: c.address.postalCode,
				country: c.address.country
			},
			phone: c.phone,
			email: c.email,
			bloodType: c.bloodType,
			heightCm: c.heightCm,
			eyeColor: c.eyeColor,
			passportIssued: c.passportIssued,
			passportExpires: c.passportExpires,
			voterRegistered: c.voterRegistered,
			militaryService: c.militaryService,
			emergencyContact: {
				name: c.emergencyContact.name,
				relationship: c.emergencyContact.relationship,
				phone: c.emergencyContact.phone
			},
			bankRiskFlags: c.bankRiskFlags,
			criminalRecord: c.criminalRecord,
			yearsAtAddress: c.yearsAtAddress,
			dependents: c.dependents,
			passportDoc: {
				passportId: c.passportDoc.passportId,
				nationalId: c.passportDoc.nationalId,
				firstName: c.passportDoc.firstName,
				lastName: c.passportDoc.lastName,
				dateOfBirth: c.passportDoc.dateOfBirth,
				sex: c.passportDoc.sex,
				placeOfBirth: c.passportDoc.placeOfBirth,
				issuingAuthority: c.passportDoc.issuingAuthority,
				dateOfExpiration: c.passportDoc.dateOfExpiration,
				issuedDate: c.passportDoc.issuedDate
			},
			idCardDoc: {
				nationalId: c.idCardDoc.nationalId,
				firstName: c.idCardDoc.firstName,
				lastName: c.idCardDoc.lastName,
				dateOfBirth: c.idCardDoc.dateOfBirth,
				sex: c.idCardDoc.sex,
				address: {
					street: c.idCardDoc.address.street,
					city: c.idCardDoc.address.city,
					region: c.idCardDoc.address.region,
					postalCode: c.idCardDoc.address.postalCode,
					country: c.idCardDoc.address.country
				}
			},
			employmentContractDoc: {
				firstName: c.employmentContractDoc.firstName,
				lastName: c.employmentContractDoc.lastName,
				occupation: c.employmentContractDoc.occupation,
				annualSalary: c.employmentContractDoc.annualSalary,
				salaryCurrency: c.employmentContractDoc.salaryCurrency
			}
		};
	}

	public static function search(query:String):Array<Citizen>
	{
		var q = query.toLowerCase().split(" ").join("");
		if (q.length == 0)
			return all;

		return all.filter(function(c)
		{
			return searchHaystack(c).indexOf(q) >= 0;
		});
	}

	static function searchHaystack(c:Citizen):String
	{
		var flags = c.bankRiskFlags.length == 0 ? "" : c.bankRiskFlags.join("");
		return (
			c.firstName
			+ c.lastName
			+ c.passportName
			+ c.passportId
			+ c.nationalId
			+ c.registryId
			+ c.taxId
			+ c.country
			+ c.countryFullName
			+ c.nationality
			+ c.occupation
			+ c.email
			+ c.phone
			+ flags
		).toLowerCase().split(" ").join("");
	}

	public static function displayName(c:Citizen):String
	{
		return '${c.firstName} ${c.lastName}';
	}

	public static function listLine(c:Citizen):String
	{
		return '${displayName(c)}  |  ${c.nationalId}';
	}

	static function sexDisplay(raw:String):String
	{
		return switch (raw)
		{
			case "M": "Male";
			case "F": "Female";
			default: raw;
		}
	}

	static function sexStore(display:String):String
	{
		return switch (display)
		{
			case "Male": "M";
			case "Female": "F";
			default: display;
		}
	}

	static var DATE_FORMAT = ~/^\d{4}-\d{2}-\d{2}$/;

	public static function isValidDateFormat(value:String):Bool
	{
		return value.length == 10 && DATE_FORMAT.match(value);
	}

	static function voterFromJson(raw:Dynamic):String
	{
		if (raw == true)
			return "YES";
		if (raw == false)
			return "NO";
		var s = Std.string(raw);
		if (s == "true")
			return "YES";
		if (s == "false")
			return "NO";
		return s;
	}

	public static function buildDetailEntries(c:Citizen):Array<CitizenDetailEntry>
	{
		var flags = c.bankRiskFlags.length == 0 ? "" : c.bankRiskFlags.join(", ");
		var voter = c.voterRegistered;
		var a = c.address;
		var e = c.emergencyContact;
		var sexChoices = ["Male", "Female", "Other", "No data"];
		var currencyChoices = ["LOR", "VAL", "KTH", "MRD", "OST", "No data"];
		var countryChoices = [
			"Rep. of Loria", "Kd. of Valdoria",
			"Kethran Fed", "Meridian Comm.",
			"Ostmark Conc.", "No data"
		];
		var nationalityChoices = countryChoices;
		var voterChoices = ["YES", "NO", "No data"];
		var militaryChoices = ["none", "completed", "exempt", "active", "No data"];
		var criminalChoices = ["none", "minor", "major", "pending", "No data"];
		var maritalChoices = ["single", "married", "divorced", "widowed", "No data"];
		var dependentsChoices = ["1", "2", "3", "4", "5", "No data"];

		return [
			Single({path: "registryId", label: "Registry ID", value: c.registryId}),
			Pair(
				{path: "passportId", label: "Passport ID", value: c.passportId},
				{path: "nationalId", label: "National ID", value: c.nationalId}
			),
			Pair(
				{path: "taxId", label: "Tax ID", value: c.taxId},
				{path: "passportName", label: "Passport Name", value: c.passportName}
			),
			Pair(
				{path: "dateOfBirth", label: "Date of Birth", value: c.dateOfBirth, dateField: true},
				{path: "sex", label: "Sex", value: sexDisplay(c.sex), choices: sexChoices}
			),
			Single({path: "placeOfBirth", label: "Place of Birth", value: c.placeOfBirth}),
			Pair(
				{path: "nationality", label: "Nationality", value: c.nationality, choices: nationalityChoices},
				{path: "maritalStatus", label: "Marital Status", value: c.maritalStatus, choices: maritalChoices}
			),
			Pair(
				{path: "occupation", label: "Occupation", value: c.occupation},
				{path: "dependents", label: "Dependents", value: c.dependents, choices: dependentsChoices}
			),
			Pair(
				{path: "averageAnnualSalary", label: "Annual Salary", value: Std.string(c.averageAnnualSalary), digitsOnly: true},
				{path: "salaryCurrency", label: "Salary Currency", value: c.salaryCurrency, choices: currencyChoices}
			),
			Pair(
				{path: "address.country", label: "Address Country", value: a.country, choices: countryChoices},
				{path: "country", label: "Country Code", value: c.country}
			),
			Pair(
				{path: "address.region", label: "Region", value: a.region},
				{path: "address.city", label: "City", value: a.city}
			),
			Single({path: "address.street", label: "Street", value: a.street}),
			Pair(
				{path: "address.postalCode", label: "Postal Code", value: a.postalCode, digitsOnly: true},
				{path: "yearsAtAddress", label: "Years at Address", value: Std.string(c.yearsAtAddress), digitsOnly: true}
			),
			Pair(
				{path: "phone", label: "Phone", value: c.phone},
				{path: "email", label: "Email", value: c.email}
			),
			Pair(
				{path: "passportIssued", label: "Passport Issued", value: c.passportIssued, dateField: true},
				{path: "passportExpires", label: "Passport Expires", value: c.passportExpires, dateField: true}
			),
			Pair(
				{path: "voterRegistered", label: "Voter Registered", value: voter, choices: voterChoices},
				{path: "militaryService", label: "Military Service", value: c.militaryService, choices: militaryChoices}
			),
			Pair(
				{path: "criminalRecord", label: "Criminal Record", value: c.criminalRecord, choices: criminalChoices},
				{path: "bankRiskFlags", label: "Bank Risk Flags", value: flags}
			),
			Pair(
				{path: "emergencyContact.name", label: "Emergency Name", value: e.name},
				{path: "emergencyContact.relationship", label: "Emergency Relat.", value: e.relationship}
			),
			Single({path: "emergencyContact.phone", label: "Emergency Phone", value: e.phone})
		];
	}

	public static function fieldLabel(entries:Array<CitizenDetailEntry>, path:String):String
	{
		for (entry in entries)
		{
			switch (entry)
			{
				case Single(field):
					if (field.path == path)
						return field.label;
				case Pair(left, right):
					if (left.path == path)
						return left.label;
					if (right.path == path)
						return right.label;
			}
		}
		return path;
	}

	public static function getFieldValue(c:Citizen, path:String):String
	{
		return switch (path)
		{
			case "registryId": c.registryId;
			case "passportId": c.passportId;
			case "nationalId": c.nationalId;
			case "taxId": c.taxId;
			case "firstName": c.firstName;
			case "lastName": c.lastName;
			case "passportName": c.passportName;
			case "dateOfBirth": c.dateOfBirth;
			case "placeOfBirth": c.placeOfBirth;
			case "sex": sexDisplay(c.sex);
			case "maritalStatus": c.maritalStatus;
			case "countryFullName": c.countryFullName;
			case "country": c.country;
			case "nationality": c.nationality;
			case "occupation": c.occupation;
			case "averageAnnualSalary": Std.string(c.averageAnnualSalary);
			case "salaryCurrency": c.salaryCurrency;
			case "address.street": c.address.street;
			case "address.city": c.address.city;
			case "address.region": c.address.region;
			case "address.postalCode": c.address.postalCode;
			case "address.country": c.address.country;
			case "yearsAtAddress": Std.string(c.yearsAtAddress);
			case "phone": c.phone;
			case "email": c.email;
			case "passportIssued": c.passportIssued;
			case "passportExpires": c.passportExpires;
			case "heightCm": Std.string(c.heightCm);
			case "eyeColor": c.eyeColor;
			case "bloodType": c.bloodType;
			case "voterRegistered": c.voterRegistered;
			case "militaryService": c.militaryService;
			case "dependents": c.dependents;
			case "criminalRecord": c.criminalRecord;
			case "bankRiskFlags": c.bankRiskFlags.length == 0 ? "" : c.bankRiskFlags.join(", ");
			case "emergencyContact.name": c.emergencyContact.name;
			case "emergencyContact.relationship": c.emergencyContact.relationship;
			case "emergencyContact.phone": c.emergencyContact.phone;
			default: "";
		}
	}

	public static function setFieldValue(c:Citizen, path:String, value:String):Void
	{
		switch (path)
		{
			case "registryId": c.registryId = value;
			case "passportId": c.passportId = value;
			case "nationalId": c.nationalId = value;
			case "taxId": c.taxId = value;
			case "firstName": c.firstName = value;
			case "lastName": c.lastName = value;
			case "passportName": c.passportName = value;
			case "dateOfBirth": c.dateOfBirth = value;
			case "placeOfBirth": c.placeOfBirth = value;
			case "sex": c.sex = sexStore(value);
			case "maritalStatus": c.maritalStatus = value;
			case "countryFullName": c.countryFullName = value;
			case "country": c.country = value;
			case "nationality": c.nationality = value;
			case "occupation": c.occupation = value;
			case "averageAnnualSalary":
				var salary = Std.parseInt(value);
				c.averageAnnualSalary = salary != null ? salary : 0;
			case "salaryCurrency": c.salaryCurrency = value;
			case "address.street": c.address.street = value;
			case "address.city": c.address.city = value;
			case "address.region": c.address.region = value;
			case "address.postalCode": c.address.postalCode = value;
			case "address.country": c.address.country = value;
			case "yearsAtAddress":
				var years = Std.parseInt(value);
				c.yearsAtAddress = years != null ? years : 0;
			case "phone": c.phone = value;
			case "email": c.email = value;
			case "passportIssued": c.passportIssued = value;
			case "passportExpires": c.passportExpires = value;
			case "heightCm":
				var height = Std.parseInt(value);
				c.heightCm = height != null ? height : 0;
			case "eyeColor": c.eyeColor = value;
			case "bloodType": c.bloodType = value;
			case "voterRegistered": c.voterRegistered = value;
			case "militaryService": c.militaryService = value;
			case "dependents": c.dependents = value;
			case "criminalRecord": c.criminalRecord = value;
			case "bankRiskFlags":
				c.bankRiskFlags = [];
				for (part in value.split(","))
				{
					var trimmed = StringTools.trim(part);
					if (trimmed.length > 0)
						c.bankRiskFlags.push(trimmed);
				}
			case "emergencyContact.name": c.emergencyContact.name = value;
			case "emergencyContact.relationship": c.emergencyContact.relationship = value;
			case "emergencyContact.phone": c.emergencyContact.phone = value;
			default:
		}

		saveAllToStorage();
	}
}
