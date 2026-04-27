@isTest
public class OD_EliminarCuentasSinContrato_test {

    @isTest
    static void testBatchExecution() {
        // Crear un usuario de prueba con el nombre 'Yesica Navarro Gómez'
        User testUser = new User(
            Username = 'user123@domain.com',
            Email = 'testuser@domain.com',
            Alias = 'testuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FirstName = 'Yesica',
            LastName = 'Navarro Gómez',
            CompanyName = 'Test Company');
        insert testUser;

        // Crear cuentas asociadas al usuario de prueba
        Account accountWithContract = new Account(Name = 'Cuenta con contrato', OwnerId = testUser.Id);
        Account accountWithoutContractOld = new Account(Name = 'Cuenta sin contrato antigua', OwnerId = testUser.Id);
        Account accountWithoutContractNew = new Account(Name = 'Cuenta sin contrato reciente', OwnerId = testUser.Id);
        insert new List<Account>{ accountWithContract, accountWithoutContractOld, accountWithoutContractNew };
        
        // Modificar las fechas de creación para las cuentas
        Test.setCreatedDate(accountWithoutContractOld.Id, System.now().addDays(-10)); // Cuenta antigua
        Test.setCreatedDate(accountWithoutContractNew.Id, System.now().addDays(-3));  // Cuenta reciente

        // Crear un contrato asociado a la primera cuenta
        OD_Contract_cls.bypassTriggerExecution = true;
        Contract contrato = new Contract(AccountId = accountWithContract.Id, Status__c = 'C01'); //ContractTerm = 12);
        insert contrato;
        OD_Contract_cls.bypassTriggerExecution = false;
		String chron = '0 0 23 * * ?'; 
        
		Opportunity objOpportunity = new Opportunity();
        objOpportunity.name = 'test';
        objOpportunity.AccountId = accountWithoutContractOld.Id;
        objOpportunity.CloseDate= system.today();
        objOpportunity.StageName = 'Contactado';
        objOpportunity.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('Wealth_Management').getRecordTypeId();
        insert objOpportunity;
        // Ejecutar el Batch
        Test.startTest();
            objOpportunity.StageName = 'Cerrada Ganada';
            update objOpportunity;
            OD_EliminarCuentasSinContrato_sch val = new OD_EliminarCuentasSinContrato_sch ();//Database.executeBatch(new OD_EliminarCuentasSinContrato_bch(), 200);
            system.schedule('Test Schedule', chron, val);
        Test.stopTest();
    }
}