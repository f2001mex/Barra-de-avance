@isTest
public class Service_Utility_TriggerTest {

    @testSetup
    static void setup() {
        // Configuración inicial de datos de prueba
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        
        List<User> users = new List<User>{
            new User(Alias = 'usr1', Email='user1@test.com', Username='userx1@test.com', LastName='User1', ID_ASESOR__c='1001', isActive=true,TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id),
            new User(Alias = 'usr2', Email='user2@test.com', Username='userx2@test.com', LastName='User2', ID_ASESOR__c='1002', isActive=true,TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id),
            new User(Alias = 'usr3', Email='user3@test.com', Username='userx3@test.com', LastName='User3', ID_ASESOR__c='B12345', isActive=true,TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id)
        };
        insert users;
        OD_Account_cls.bypassTriggerExecution = true;
        Account accWM = new Account(Name = 'Test Account', Client_ID__c = '12345',Second_LastName__c = 'NoMiddleName',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Wealth Management').getRecordTypeId());
        insert accWM;
        
        Account accP = new Account(Name = 'Test Account2', Client_ID__c = '12347',Second_LastName__c = 'NoMiddleName',RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Privada').getRecordTypeId());
        insert accP;
        OD_Account_cls.bypassTriggerExecution = false;
        
        Contact con = new Contact(FirstName = 'TestC', LastName = 'Contact', AccountId = accWM.Id);
        insert con;
        Banker banker = new Banker(Name = 'Test Banker',CurrentBranchId = branchUnit.Id,OD_IdCentroFinanciero__c = '37' , ExternalId__c = 'B12345',JobCode ='B12345',UserOrContactId = users[2].Id);
        insert banker;
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName='Contact1', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Banquero sin licencia').getRecordTypeId(), NumeroNomina__c='1001'),
            new Contact(LastName='Contact2', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Banquero sin licencia').getRecordTypeId(), NumeroNomina__c='1002')
        };
        insert contacts;

        List<BranchUnit> b = [SELECT Id FROM BranchUnit LIMIT 100];
        System.debug('tamaño lista ' + b.size());

        
        Service_Utility_Trigger.isCorrectRecordTypeId(accWM);
    }


    @isTest
    static void testGetBrUnBuMeByExternalIdAndNomina() {
        Set<String> uniqueFindBUBM = new Set<String>{'BUBM1', 'BUBM2'};
        
        Test.startTest();
        Map<String, BranchUnitBusinessMember> result = Service_Utility_Trigger.getBrUnBuMeByExternalIdAndNomina(uniqueFindBUBM);
        Test.stopTest();
        
        //System.assert(result.containsKey('BUBM1'), 'El resultado debe contener el BUBM1');
        //System.assert(result.containsKey('BUBM2'), 'El resultado debe contener el BUBM2');
    }

    @isTest
    static void testGetContactsByNomina() {
        Set<String> uniqueAdvisorIds = new Set<String>{'1001', '1002'};
        
        Test.startTest();
        Map<String, Contact> result = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
        Test.stopTest();
        
        System.assert(result.containsKey('1001'), 'El resultado debe contener el contacto con Nomina 1001');
        System.assert(result.containsKey('1002'), 'El resultado debe contener el contacto con Nomina 1002');
    }

    @isTest
    static void testGetUsersByOwnerIds() {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        
        Test.startTest();
        Map<Id, User> result = Service_Utility_Trigger.getUsersByOwnerIds(userIds);
        Test.stopTest();
        
        System.assert(result.containsKey(UserInfo.getUserId()), 'El resultado debe contener el usuario actual');
    }

    @isTest
    static void testGetUsersByNomina() {
        Set<String> uniqueAdvisorIds = new Set<String>{'1001', '1002'};
        
        Test.startTest();
        Map<String, User> result = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
        Test.stopTest();
        
        System.assert(result.containsKey('1001'), 'El resultado debe contener el usuario con Nomina 1001');
        System.assert(result.containsKey('1002'), 'El resultado debe contener el usuario con Nomina 1002');
    }

    @isTest
    static void testGetBranchUnits() {
        Set<String> branchIds = new Set<String>{'BUBM1BI', 'BUBM2BI'};
        
        Test.startTest();
        Map<String, BranchUnit> result = Service_Utility_Trigger.getBranchUnits(branchIds);
        Test.stopTest();
    }

    @isTest
    static void testGetUsersByIds() {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        
        Test.startTest();
        Map<Id, String> result = Service_Utility_Trigger.getUsersByIds(userIds);
        Test.stopTest();
        
        System.assert(result.containsKey(UserInfo.getUserId()), 'El resultado debe contener el usuario actual');
    }

    @isTest
    static void testGetBankerByNumNomina() {
        Set<String> nominaIds = new Set<String>{'1001', '1002'};
        
        Test.startTest();
        Map<String, Banker> result = Service_Utility_Trigger.getBankerByNumNomina(nominaIds);
        Test.stopTest();
    }

    @isTest
    static void testGetMapBranchUnitsBusinessMember() {
        List<BranchUnitBusinessMember> branchUnitBusinessMembers = [SELECT Id, ExternalId__c FROM BranchUnitBusinessMember];
        
        Test.startTest();
        Map<String, String> result = Service_Utility_Trigger.getMapBranchUnitsBusinessMember(branchUnitBusinessMembers);
        Test.stopTest();
        
        System.assert(result.containsKey(branchUnitBusinessMembers[0].ExternalId__c), 'El resultado debe contener el Branch Unit Business Member 1');
    }
    
    @isTest
    static void testGetBranchUnitByCFYJobCode2(){
        Set<String> bIds = new Set<String>{'B12345'};
        Service_Utility_Trigger.getBranchUnitByCFYJobCode2(bIds);
        
        Service_Utility_Trigger.getBranchUnitByCFYJobCode(bIds);
        
    }
}