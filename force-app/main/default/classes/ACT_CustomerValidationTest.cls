@isTest
public with sharing class ACT_CustomerValidationTest {
    
    @TestSetup
    static void prepareData(){
        Lead lead = new Lead(
            RecordTypeId = getLeadProspectoRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Lead',
            Telephone__c = '+525599887766',
            OwnerId = UserInfo.getUserId()
        );
        insert lead;

        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(
            RecordTypeId = getPersonAccountRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Account',
            Client_ID__c = '1111',
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        Task leadTask = new Task(
            Subject = 'Call',
            ACT_ConversationId__c = 'dddd7dd3-168c-42b2-a212-3614c2420bc5',
            Status = 'Completed',
            Priority = 'Normal'
        );
        insert leadTask;

        Task accountTask = new Task(
            Subject = 'Email',
            ACT_ConversationId__c = '44f31a16-b149-4ecc-a6f6-27763ca2111b',
            Status = 'Completed',
            Priority = 'Normal'
        );
        insert accountTask;
    }

    @IsTest
    static void testMatchAccountSuccess(){
        String interactionId = '44f31a16-b149-4ecc-a6f6-27763ca2111b';
        String phone = '+525599887766';
        String numeroCliente = '1111';
        Boolean authenticated = true;

        Test.startTest();
        MostrarCuentaVerificadaController.verificarCuenta(interactionId, phone, authenticated, numeroCliente);
        Test.stopTest();

        Task task = [SELECT Id, WhoId, Status, OwnerId, CreatedDate, WhatId, ACT_Client_Identifier__c FROM Task WHERE ACT_ConversationId__c = :interactionId];
        Assert.areEqual(task.ACT_Client_Identifier__c, numeroCliente, 'Los datos coinciden - Cliente Unico Actualizado');
    }

    @IsTest
    static void testMatchAccountFailed(){
        String interactionId = '44f31a16-b149-4ecc-a6f6-27763ca2111b';
        String phone = '+525599887766';
        String numeroCliente = '2222';
        Boolean authenticated = true;

        Test.startTest();
        MostrarCuentaVerificadaController.verificarCuenta(interactionId, phone, authenticated, numeroCliente);
        Test.stopTest();

        Task task = [SELECT Id, WhoId, Status, OwnerId, CreatedDate, WhatId, ACT_Client_Identifier__c FROM Task WHERE ACT_ConversationId__c = :interactionId];
        Assert.areNotEqual(task.ACT_Client_Identifier__c, numeroCliente, 'Los datos no coinciden - Cliente Unico No Actualizado');
    }

    @IsTest
    static void testMatchLeadSuccess(){
        String interactionId = 'dddd7dd3-168c-42b2-a212-3614c2420bc5';
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        String phone = '525599887766';

        Test.startTest();

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = lead.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        ValidarBusquedaController.validarBusqueda(interactionId, phone);

        Test.stopTest();

        Task task = [SELECT Id, WhoId, Status, OwnerId, CreatedDate, WhatId FROM Task WHERE ACT_ConversationId__c = :interactionId];
        Assert.areEqual(task.WhoId, lead.Id, 'Los datos coinciden - Lead relacionado');
    }

    @IsTest
    static void testMatchLeadMultipleSuccess(){
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(
            RecordTypeId = getPersonAccountRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Account 2',
            Client_ID__c = '2222',
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        ACT_Genesys_Phone__c genesysPhone = new ACT_Genesys_Phone__c(
            ACT_Genesys_Phone_Number__c = '+525599887766',
            ACT_Customer__c = acc.Id
        );
        insert genesysPhone;

        Telefono_de_Contrato__c contractPhone = new Telefono_de_Contrato__c(
            Name = 'Test Contract Phone',
            Area_Code__c = '52',
            Lada__c = '55',
            Phone__c = '99887766',
            ACT_Contract_Phone__c = '+525599887766'
        );
        insert contractPhone;

        String interactionId = 'dddd7dd3-168c-42b2-a212-3614c2420bc5';
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        String phone = '525599887766';

        Test.startTest();

        Id [] fixedSearchResults= new Id[3];
        fixedSearchResults[0] = genesysPhone.Id;
        fixedSearchResults[1] = contractPhone.Id;
        fixedSearchResults[2] = lead.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        ValidarBusquedaController.validarBusqueda(interactionId, phone);

        Test.stopTest();
    }

    @IsTest
    static void testMatchLeadFailed(){
        String interactionId = 'dddd7dd3-168c-42b2-a212-3614c2420bc5';
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        String phone = '525599887755';

        Test.startTest();

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = lead.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        ValidarBusquedaController.validarBusqueda(interactionId, phone);

        Test.stopTest();

        Task task = [SELECT Id, WhoId, Status, OwnerId, CreatedDate, WhatId FROM Task WHERE ACT_ConversationId__c = :interactionId];
        Assert.areEqual(task.WhoId, lead.Id, 'Los datos coinciden - Lead relacionado');
    }

    // Obtiene dinámicamente el RecordTypeId de Person Account
    private static Id getPersonAccountRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    }

    // Obtiene dinámicamente el RecordTypeId de Prospecto
    private static Id getLeadProspectoRecordTypeId() {
        return Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Prospecto').getRecordTypeId();
    }

}