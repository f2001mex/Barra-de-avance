/**
* @File Name : OD_AssignUserOwner_tst.cls
* @Description :Clase test de OD_AssignUserOwner_tst para la programación de Accounts,Contracts
*				asi como sus clases batch OD_BatchAssignAccounts_bch OD_BatchAssignContracts_bch
* @Author : Andrés Hernández Ríos
* @Last Modified By :
* @Last Modified On : December 11, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 11, 2024 |Andrés Hernández Ríos| Initial Version
**/
@isTest
public class OD_AssignUserOwner_tst {
    @testSetup static void setup() {
        String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        User user = new User();
        user.LastName = 'User1';
        user.Username = 'User1@user.com.u';
        user.Email = 'Useruser@u.com.u';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas2';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '0001';
        user.ProfileId = adminProfileId;
        insert user;        
        
        Contact contactWithOutLicense = new Contact();
        contactWithOutLicense.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
        contactWithOutLicense.FirstName = 'TestName';
        contactWithOutLicense.LastName = 'TestApp';
        contactWithOutLicense.EmpleadoSinLicenciaSFDC__c = true;
        contactWithOutLicense.NumeroNomina__c = '0002';
        insert contactWithOutLicense;
        
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact';
        bankerContact.JobCode = '0002';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = contactWithOutLicense.Id;
        insert bankerContact;
        
        OD_Account_cls.bypassTriggerExecution = true;
        Account account = new Account();
        account.FirstName = 'TestName';
        account.MiddleName = 'TestMiddle';
        account.LastName = 'TestApp';
        account.F3_CURP__c = 'TESTING1';
        account.Client_ID__c = '02030';
        account.ID_Asesor__c = '0001';
        account.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert account;
        OD_Account_cls.bypassTriggerExecution = false;  
        
        OD_Contract_cls.bypassTriggerExecution = true;
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.ContractNumber__c = '142536';
        contract.Status__c = 'Fondeado';
        contract.ID_ASESOR__c = '0001';
        contract.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
        contract.IDSap__c = '142536';
        insert contract;
        system.debug(contract);
        OD_Contract_cls.bypassTriggerExecution = false;
        
    }
    
    @isTest static void testSchedulableJobAccounts() {
        
        String cronograma = '59 23 * * 1-5 ?';
        OD_AssignOwnerToAccounts_sch schedulerJob = new OD_AssignOwnerToAccounts_sch();
        
        Test.startTest();
        String jobID = System.schedule('Test Assign Owners Accounts', cronograma, schedulerJob);
        Test.stopTest();
        
        CronTrigger[] scheduledJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobID];
        System.assertEquals(1, scheduledJobs.size(), 'El trabajo programado no fue creado');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'El estado del trabajo programado no es el esperado');
    }
    
    @isTest static void testSchedulableJobContracts() {
        
        String cronograma = '59 23 * * 1-5 ?';  
        OD_AssignOwnerToContracts_sch schedulerJob = new OD_AssignOwnerToContracts_sch();
        
        Test.startTest();
        String jobID = System.schedule('Test Assign Owners Contracts', cronograma, schedulerJob);
        Test.stopTest();
        
        CronTrigger[] scheduledJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobID];
        System.assertEquals(1, scheduledJobs.size(), 'El trabajo programado no fue creado');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'El estado del trabajo programado no es el esperado');
    }
    
}