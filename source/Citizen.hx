package;

typedef CitizenAddress = {
	var street:String;
	var city:String;
	var region:String;
	var postalCode:String;
	var country:String;
}

typedef CitizenEmergencyContact = {
	var name:String;
	var relationship:String;
	var phone:String;
}

typedef Citizen = {
	var registryId:String;
	var passportId:String;
	var nationalId:String;
	var taxId:String;
	var firstName:String;
	var lastName:String;
	var passportName:String;
	var country:String;
	var countryFullName:String;
	var nationality:String;
	var dateOfBirth:String;
	var placeOfBirth:String;
	var sex:String;
	var maritalStatus:String;
	var occupation:String;
	var averageAnnualSalary:Int;
	var salaryCurrency:String;
	var address:CitizenAddress;
	var phone:String;
	var email:String;
	var bloodType:String;
	var heightCm:Int;
	var eyeColor:String;
	var passportIssued:String;
	var passportExpires:String;
	var voterRegistered:Bool;
	var militaryService:String;
	var emergencyContact:CitizenEmergencyContact;
	var bankRiskFlags:Array<String>;
	var criminalRecord:String;
	var yearsAtAddress:Int;
	var dependents:Int;
}
