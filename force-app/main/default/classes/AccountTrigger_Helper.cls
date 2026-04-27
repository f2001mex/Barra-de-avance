public with sharing class AccountTrigger_Helper {
	public static void createAccounts(List<Account> accts) {
		for (Account a : accts) {
			if (a.Person_Type__c == 'MORAL') {
				a.Name = a.BusinessName__c;
				a.PersonBirthdate = null;
				System.debug(JSON.serializePretty(a));
			}
			if (a.Person_Type__c == 'FISICA') {
				if (a.Nombre_Completo_Actinver__c != null) {
					a.FirstName = a.Nombre_Completo_Actinver__c.length() >= 40
						? a.Nombre_Completo_Actinver__c.substring(0, 39)
						: a.Nombre_Completo_Actinver__c;
				}
			}
		}
	}

	/**
	 * Check if the total percentage is above 100%
	 */
	public static void checkTotalPercent(List<Account> accts) {
		Decimal decActinverMexico = 0;
		Decimal decActinverMadrid = 0;
		Decimal decActinverSecurities = 0;
		Decimal decInstitucionesNacionales = 0;
		Decimal decInstitucionesInternaciononales = 0;

		for (Account accObj : accts) {
			// if all the fields are null, skip the check
			if (
				accObj.Actinver_Mexico__c == null &&
				accObj.Actinver_Madrid__c == null &&
				accObj.Actinver_Securities__c == null &&
				accObj.Instituciones_Nacionales__c == null &&
				accObj.Instituciones_Internaciononales__c == null
			) {
				continue;
			}

			// Only persona accout need this check
			if (accObj.IsPersonAccount) {
				decActinverMexico = (accObj.Actinver_Mexico__c == null) ? 0 : accObj.Actinver_Mexico__c;
				decActinverMadrid = (accObj.Actinver_Madrid__c == null) ? 0 : accObj.Actinver_Madrid__c;
				decActinverSecurities = (accObj.Actinver_Securities__c == null) ? 0 : accObj.Actinver_Securities__c;
				decInstitucionesNacionales = (accObj.Instituciones_Nacionales__c == null) ? 0 : accObj.Instituciones_Nacionales__c;
				decInstitucionesInternaciononales = (accObj.Instituciones_Internaciononales__c == null)
					? 0
					: accObj.Instituciones_Internaciononales__c;

				if (
					(decActinverMexico +
					decActinverMadrid +
					decActinverSecurities +
					decInstitucionesNacionales +
					decInstitucionesInternaciononales) != 100
				) {
					accObj.addError(Label.CheckTotalPercent);
				}
			}
		}
	}
}