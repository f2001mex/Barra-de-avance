/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class F4_AssingContractOwner_Account_BatchTest {
    static Profile pfAdmin= [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    static List<Account> newAccounts = new List<Account>();
    static List<Contract> newContracts = new List<Contract>();

    @TestSetup
    static void setup() {
        User integrationUser = new User(
            LastName = 'IntegrationUser',    
            Username = 'integration@test.com.prod',
            Email = 'test@test.com',
            IsActive = true,
            EmailEncodingKey = 'ISO-8859-1',
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            Alias = 'alias1',
            ProfileId = pfAdmin.Id
        );
        insert integrationUser;

        User asesorUser = new User(
            LastName = 'asesorUser',    
            Username = 'asesor@test.com.prod',
            Email = 'test2@test.com',
            IsActive = true,
            EmailEncodingKey = 'ISO-8859-1',
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'es',
            Alias = 'alias2',
            ID_ASESOR__c = 'ASESORT',
            ProfileId = pfAdmin.Id
        );
        insert asesorUser;

        for (Integer i=0; i<2; i++) {
            newAccounts.add(new Account(
                FirstName = 'Test',
                LastName = 'Acc' + i,
                F3_Posicion_Global__c = 101000,
                OwnerId = integrationUser.Id
            ));
        }
        insert newAccounts;

        for (Integer j=0; j<2; j++) {
            newContracts.add(new Contract(
                AccountId = newAccounts[j].Id,
                StartDate = Date.today(),
                ContractTerm = 3,
                ID_ASESOR__c = j== 0 ? 'ASESORT' : 'ASESORI'
            ));
        }
        insert newContracts;
    }


    @isTest
    static void batchUnitTest() {
        Test.startTest();
            Set<String> integrationUsernames = new Set<String>{'IntegrationUser', 'Integration User'};
            Set<Id> accountIds = new Set<Id>();
            for(Contract c: [SELECT Id, Owner.Name, Status, AccountId, Saldo_contrato__c, OwnerId, ID_ASESOR__c, Account.Owner.Name FROM Contract ORDER BY AccountId, Saldo_contrato__c DESC NULLS LAST]){
                System.debug(c.Account.Owner.Name);
            }
            

            Map<String, Object> variablesBind = new Map<String, Object>{
                'integrationUsernames' => integrationUsernames
            };

            String query = 'SELECT Id, Owner.Name, AccountId, Status, Saldo_contrato__c, OwnerId, ID_ASESOR__c FROM Contract'+
                            ' WHERE Account.Owner.Name IN:integrationUsernames AND ID_ASESOR__c  != null'+
                            ' ORDER BY AccountId, Saldo_contrato__c DESC NULLS LAST LIMIT 10';
            Database.executeBatch(new F4_AssingContractOwner_ToAccount_Batch(query, variablesBind), 5);
        Test.stopTest();
    }
}