/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 07-02-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : 
**/
global class BIT_AdultoMayor_bch implements Database.Batchable<sObject> {
	@testVisible
	private static Boolean isTestException = false;
	public Database.QueryLocator start (Database.BatchableContext bc) {
		String query =  Test.isRunningTest() ? System.Label.BIT_AdultoMayorSelector_test : System.Label.BIT_AdultoMayor_selector;
		return Database.getQueryLocator(query);
	}
	public void execute (Database.BatchableContext bc, list<Account> accounts) {
		List<Account> accs2Update = new List<Account>();
		for (Account acc: accounts) {
			Integer age = Date.today().year() - acc.PersonBirthdate.year();
			if (acc.PersonBirthdate.day() >= Date.today().day() && acc.PersonBirthdate.month() >= Date.today().month() && age >= 65) {
				acc.Persona_Vulnerable__c = true;
				if (acc.Tipo_de_Persona_Vulnerable__c == null) {
					acc.Tipo_de_Persona_Vulnerable__c = 'Personas adultas mayores;';
				} else if (!acc.Tipo_de_Persona_Vulnerable__c.contains('Personas adultas mayores')) {
					acc.Tipo_de_Persona_Vulnerable__c += ';Personas adultas mayores';
				}
				accs2Update.add(acc);
			}
		}
		if (!accs2Update.isEmpty()) {
			Map<String, String> mapErrors = BIT_AdultoMayor_Helper.updateAccounts(accs2Update);
			if (isTestException && Test.isRunningTest()) {
				mapErrors.put('test', 'testError');
			}
			if(!mapErrors.isEmpty()){
				BIT_AdultoMayor_Helper.saveLogError(mapErrors, 'Error al actualizar clientes', 'ERROR_BATCH_ADULTOMAYOR_001');
			}
		}
	}
	public void finish (Database.BatchableContext bc) {}
}