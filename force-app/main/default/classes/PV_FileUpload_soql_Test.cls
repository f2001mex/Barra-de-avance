@isTest
public class PV_FileUpload_soql_Test {

    @testSetup
    static void setup() {
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
        contactWithOutLicense.NumeroNomina__c = '0001';
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
        bankerContact.JobCode = '0001';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = contactWithOutLicense.Id;
        insert bankerContact;
        
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

        // Crear Contract
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.Source__c = 'Contrato de Banco';
        contract.ContractNumber__c = '142536';
        contract.Status__c = 'Fondeado';
        contract.ID_ASESOR__c = '0001';
        contract.OwnerId = [SELECT Id FROM User WHERE Name = 'IntegrationUser'].Id;
        contract.IDSap__c = '142536';
        insert contract;

        // Crear Task
        Task t = new Task(
            Subject = 'Tarea de prueba',
            WhoId = account.PersonContactId,
            Status = 'Not Started',
            DeveloperName__c = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA,
            ClienteNoQuiereSerContactado__c = false
        );
        insert t;

        // Crear ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Archivo Prueba',
            PathOnClient = 'archivo.pdf',
            VersionData = Blob.valueOf('contenido de prueba')
        );
        insert cv;

        // Obtener ContentDocumentId del ContentVersion
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    @isTest
    static void testGetTask() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        Task result = PV_FileUpload_soql.getTask(t.Id);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCadence() {
        String devName = PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA;
        Boolean requiere = PV_FileUpload_soql.getCadence(devName);
        System.assertEquals(false, requiere);
    }

    @isTest
    static void testGetContract() {
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        Contract result = PV_FileUpload_soql.getContract(c.Id);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetVersionFile() {
        Id docId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        ContentVersion cv = PV_FileUpload_soql.getVersionFile(docId);
        System.assertNotEquals(null, cv);
    }

    @isTest
    static void testGetDocument() {
        Id docId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        ContentDocument doc = PV_FileUpload_soql.getDocument(docId);
        System.assertNotEquals(null, doc);
    }

    @isTest
    static void testGetListContractAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contract> contratos = PV_FileUpload_soql.getListContractAccount(
            acc.Id, 
            PSTA_UtilityClass.DEVELOPERNAME_PLANEACION_FINANCIERA
        );
        System.assert(contratos.size() > 0, 'Debe devolver al menos un contrato');
    }
    
    @isTest
    static void testGetListContractAccount2() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contract> contratos = PV_FileUpload_soql.getListContractAccount(
            acc.Id, 
            PSTA_UtilityClass.DEVELOPERNAME_PROPUESTA_INVERSION
        );
        System.assert(contratos.size() > 0, 'Debe devolver al menos un contrato');
    }
}