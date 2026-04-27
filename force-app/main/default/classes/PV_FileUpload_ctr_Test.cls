/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class PV_FileUpload_ctr_Test {

    @testSetup
    static void setupData() {
        Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
        ConfiguracionActinver__c objConfig = new ConfiguracionActinver__c(
            Segmento__c = 'Patrimonial reactivo',
            RangoMontoMaximo__c = 100000,
            RangoMontoMinimo__c = 0,
            FrecReinicioNoReqContacto__c = '90',
            Rol__c = 'CONSULTOR/A FARMER DIGITAL',
            FrecuenciaContacto__c = 30,
            FrecuenciaVisita__c = 240,
            RecordTypeId = idConfigContactoPostVentaRecordType
        );
        insert objConfig;
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
            WhatId = account.Id,
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
    static void testObtenerReferenciaOpenText() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        Test.startTest();
        PV_FileUpload_ctr.Resultado result = PV_FileUpload_ctr.obtenerReferenciaOpenText(t.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
    }
    
    @isTest
    static void testGetContractsByTaskId() {
        Task t = [SELECT Id FROM Task LIMIT 1];
        Test.startTest();
        PV_FileUpload_ctr.ContractResult result = PV_FileUpload_ctr.getContractsByTaskId(t.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
    }

    @isTest
    static void testEliminarArchivo() {
        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        Test.startTest();
        PV_FileUpload_ctr.Resultado result = PV_FileUpload_ctr.eliminarArchivo(cd.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.resultado != null || result.error != null, 'Debe haber resultado o error');
    }

    @isTest
    static void testEnviarArchivo() {
        // Preparar datos
        Task t = [SELECT Id, DeveloperName__c, AccountId, ClienteNoQuiereSerContactado__c,WhoId FROM Task LIMIT 1];
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];

        // Simular callout exitoso
        Test.setMock(HttpCalloutMock.class, new Mock_OpenText_Response_200());

        Test.startTest();
        PV_FileUpload_ctr.Resultado res = PV_FileUpload_ctr.enviarArchivo(t, c.Id, cv.ContentDocumentId, false);
        Test.stopTest();

        System.assertNotEquals(null, res, 'El resultado no debe ser null');
    }

    // Mock para callout
    public class Mock_OpenText_Response_200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'status' => 200,
                'payload' => new Map<String, Object>{
                    'status' => 'COMPLETED',
                    'referenceId' => 'REF-MOCK-001'
                },
                'result' => new Map<String, Object>{
                    'resultCode' => '0',
                    'resultType' => 'Success',
                    'resultMessage' => 'OK'
                }
            }));
            return res;
        }
    }
}