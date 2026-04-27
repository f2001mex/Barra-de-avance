/**
* @File Name : OD_Contract_cls.cls
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
public class OD_Contract_tst {
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
        
        Banker bankerContact2 = new Banker();
        bankerContact2.Name = 'TestBankerContact';
        bankerContact2.JobCode = '0001';
        bankerContact2.ExternalId__c = '0001';
        bankerContact2.OD_IdCentroFinanciero__c = '37';
        bankerContact2.CurrentBranchId = branchUnit.Id;
        bankerContact2.UserOrContactId = user.Id;
        insert bankerContact2;
        
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact';
        bankerContact.JobCode = '0002';
        bankerContact.ExternalId__c = '0002';
        bankerContact.OD_IdCentroFinanciero__c = '37';
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
    static void findContact() {
        Contract contract = new Contract();
        contract.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        contract.ContractNumber__c = '142536';
        contract.Status__c = 'Aprobado';
        contract.ID_ASESOR__c = '0001';
        contract.IDSap__c = '142536';
        insert contract;
    }
    @isTest
    static void findUser() {
        Contract contract = new Contract();
        contract.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
        contract.ContractNumber__c = '142536';
        contract.Status__c = 'Aprobado';
        contract.ID_ASESOR__c = '0001';
        contract.IDSap__c = '142536';
        insert contract;
    }
    @isTest
    static void notFound() {
        Contract contractUpdate = [
            SELECT Id,AccountId,ContractNumber__c,ID_ASESOR__c FROM Contract WHERE ID_ASESOR__c = '0003'
        ];
        contractUpdate.ID_ASESOR__c = '0001';
        contractUpdate.Status = 'Aprobado';
        update contractUpdate;
    }
}