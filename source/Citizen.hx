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

typedef CitizenPassportDocument = {
	var passportId:String;
	var nationalId:String;
	var firstName:String;
	var lastName:String;
	var dateOfBirth:String;
	var sex:String;
	var placeOfBirth:String;
	var issuingAuthority:String;
	var dateOfExpiration:String;
	var issuedDate:String;
}

typedef CitizenIdCardDocument = {
	var nationalId:String;
	var firstName:String;
	var lastName:String;
	var dateOfBirth:String;
	var sex:String;
	var address:CitizenAddress;
}

typedef CitizenEmploymentContractDocument = {
	var firstName:String;
	var lastName:String;
	var occupation:String;
	var annualSalary:Int;
	var salaryCurrency:String;
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
	var voterRegistered:String;
	var militaryService:String;
	var emergencyContact:CitizenEmergencyContact;
	var bankRiskFlags:Array<String>;
	var criminalRecord:String;
	var yearsAtAddress:Int;
	var dependents:String;
	var passportDoc:CitizenPassportDocument;
	var idCardDoc:CitizenIdCardDocument;
	var employmentContractDoc:CitizenEmploymentContractDocument;
}
