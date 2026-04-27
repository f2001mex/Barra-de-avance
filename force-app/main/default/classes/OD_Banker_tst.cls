/**
* @File Name : OD_Banker_cls.cls
* @Description :Clase test de todo trigger Contract
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
public class OD_Banker_tst {
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
        user.ID_ASESOR__c = '00045';
        user.ProfileId = adminProfileId;
        insert user;
        
        User user2 = new User();
        user2.LastName = 'User2';
        user2.Username = 'User2@user.com.u';
        user2.Email = 'Useruser2@u.com.u';
        user2.EmailEncodingKey = 'ISO-8859-1';
        user2.Alias = 'uAas22';
        user2.IsActive = true;
        user2.TimeZoneSidKey = 'America/Mexico_City';
        user2.LocaleSidKey = 'en_US';
        user2.LanguageLocaleKey = 'es';
        user2.ID_ASESOR__c = '00046';
        user2.ProfileId = adminProfileId;
        insert user2;
        
        Contact contactWithOutLicense = new Contact();
        contactWithOutLicense.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
        contactWithOutLicense.FirstName = 'TestName';
        contactWithOutLicense.LastName = 'TestApp';
        contactWithOutLicense.EmpleadoSinLicenciaSFDC__c = true;
        contactWithOutLicense.NumeroNomina__c = '00046';
        insert contactWithOutLicense;
        
        Contact contactWithOutLicense2 = new Contact();
        contactWithOutLicense2.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
        contactWithOutLicense2.FirstName = 'TestName';
        contactWithOutLicense2.LastName = 'TestApp';
        contactWithOutLicense2.EmpleadoSinLicenciaSFDC__c = true;
        contactWithOutLicense2.NumeroNomina__c = '000200';
        insert contactWithOutLicense2;
        
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        
        BranchUnit branchUnit2 = new BranchUnit();
        branchUnit2.Name = 'TestBranchUnit2';
        branchUnit2.IsActive = true;
        branchUnit2.BranchCode = '10000012346';
        branchUnit2.ExternalIdBI__c = '38';
        branchUnit2.ExternalId__c = '10000012346';        
        insert branchUnit2;
        
        BranchUnit branchUnit3 = new BranchUnit();
        branchUnit3.Name = 'Test Branch Unit3';
        branchUnit3.IsActive = true;
        branchUnit3.BranchCode = '10000012347';
        branchUnit3.ExternalIdBI__c = '39';
        branchUnit3.ExternalId__c = '10000012347';        
        insert branchUnit3;
        
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact';
        bankerContact.JobCode = '00045';
        bankerContact.ExternalId__c = '00045';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = contactWithOutLicense2.Id;
        insert bankerContact;
        
        Banker bankerContact2 = new Banker();
        bankerContact2.Name = 'TestBankerContact2';
        bankerContact2.JobCode = '00046';
        bankerContact2.ExternalId__c = '00046';
        bankerContact2.CurrentBranchId = branchUnit2.Id;
        bankerContact2.UserOrContactId = user2.Id;
        insert bankerContact2;
        
        OD_Account_cls.bypassTriggerExecution = true;
        Account account = new Account();
        account.FirstName = 'TestName';
        account.MiddleName = 'TestMiddle';
        account.LastName = 'TestApp';
        account.F3_CURP__c = 'TESTING1';
        account.Client_ID__c = '02030';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert account;
        OD_Account_cls.bypassTriggerExecution = false;
        
        OD_Contract_cls.bypassTriggerExecution = true;
        Contract contract = new Contract();
        contract.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        contract.ContractNumber__c = '142536';
        contract.Status__c = 'Fondeado';
        contract.ID_ASESOR__c = '0003';
        contract.IDSap__c = '142536';
        insert contract;
        OD_Contract_cls.bypassTriggerExecution = false;
        
    }
    
    @isTest
    static void createAllRecordsNew() {
        Banker banker = new Banker();
        banker.Name = 'Testing Test';
        banker.ExternalId__c = '000100';
        banker.OD_IdCentroFinanciero__c = '987654321';
        banker.OD_NombreCentroFinanciero__c = 'Test Vass';
        upsert banker;
    }
    @isTest
    static void findContact() {
        Banker banker = new Banker();
        banker.Name = 'Testing Test 2';
        banker.ExternalId__c = '000200';
        banker.OD_IdCentroFinanciero__c = '987654321';
        banker.OD_NombreCentroFinanciero__c = 'Test Vass';
        upsert banker;
    }
    @isTest
    static void findUser() {
        Banker banker = new Banker();
        banker.Name = 'Testing Test 3';
        banker.ExternalId__c = '0001';
        banker.OD_IdCentroFinanciero__c = '987654321';
        banker.OD_NombreCentroFinanciero__c = 'Test Vass';
        upsert banker;
    }
    @isTest
    static void notChangeBranch() {
        Banker objBanker = [SELECT Id,Name,ExternalId__c,CurrentBranchId,OD_IdCentroFinanciero__c,UserOrContactId FROM Banker WHERE JobCode = '00046' LIMIT 1];
        Map<Id,Banker> mapBanker = New Map<Id,Banker>();
        Banker[] lstBanker = new List<Banker>();
        lstBanker.add(objBanker);
        mapBanker.put(objBanker.Id,objBanker);
        OD_Banker_cls.createBranchUnitBusinessMember(lstBanker,mapBanker);
    }
    
    @isTest
    static void ChangeBranch() {
        Banker objBanker  = [SELECT Id,Name,ExternalId__c,JobCode,CurrentBranchId,OD_IdCentroFinanciero__c,UserOrContactId FROM Banker WHERE JobCode = '00046' LIMIT 1];
        Banker objBanker2 = [SELECT Id,Name,ExternalId__c,JobCode,CurrentBranchId,OD_IdCentroFinanciero__c,UserOrContactId FROM Banker WHERE JobCode = '00046' LIMIT 1];
        BranchUnit objBranchUnit = [SELECT Id FROM BranchUnit WHERE ExternalIdBI__c = '37' LIMIT 1];
        
        
        Map<Id,Banker> mapBanker = New Map<Id,Banker>();
        Banker[] lstBanker = new List<Banker>();
        lstBanker.add(objBanker);
        
        objBanker2.CurrentBranchId = objBranchUnit.Id;
        mapBanker.put(objBanker2.Id,objBanker2);
        OD_Banker_cls.processToRelatedNewOwner(lstBanker,mapBanker);
        
        try{
        	update objBanker2;
        } catch(Exception e) {} 
    }
    
}