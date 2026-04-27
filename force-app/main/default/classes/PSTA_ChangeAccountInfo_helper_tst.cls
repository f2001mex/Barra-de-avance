/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_ChangeAccountInfo_helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                            Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                        Creación
*******************************************************************************************/
@isTest
public class PSTA_ChangeAccountInfo_helper_tst {
    public static ActionCadence cadence = new ActionCadence(Name = 'Cadencia No Contacto', DeveloperName__c = 'NoContact', GeneraContacto__c = true);
    public static final Id idTaskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Postventa').getRecordTypeId(); 
    @TestSetup
    static void makeData(){
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(Name = 'Cuenta de Prueba');
        insert acc;
    }
    @isTest
    static void test_initProcessChangeStatusAccount() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad de Prueba',
            StageName = 'Prospecto',
            CloseDate = Date.today(),
            AccountId = acc.Id

        );
        insert opp;
        Task task = new Task(
            Subject = 'Llamada de prueba',
            Status = 'Completado',
            Priority = 'Normal',
            WhatId = acc.Id,
            El_cliente_fue_contactado__c = 'Si',
            Genere_una_oportunidad__c = opp.Id,
            Por_que_no_se_genero_una_oportunidad__c = 'test',
            ClienteNoQuiereSerContactado__c = false,
            DeveloperName__c = 'TestCadence',
            RecordTypeId = idTaskRecordType
        );
        insert task;

        Task oldTask = task.clone(false, true, false, false);
        oldTask.El_cliente_fue_contactado__c = null;

        List<Task> lstTask = new List<Task>{ task };
        Map<Id, Task> mapOldTask = new Map<Id, Task>{ task.Id => oldTask };

        Test.startTest();
        PSTA_ChangeAccountInfo_helper.initProcessChangeStatusAccount(lstTask, mapOldTask);
        Test.stopTest();
    }

    @isTest
    static void test_changeContacAndDatetStatus_contactNotWanted() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        Task oldTask = new Task(
            Subject = 'Tarea anterior',
            Status = 'Pendiente',
            WhatId = acc.Id,
            El_cliente_fue_contactado__c = null,
            DeveloperName__c = 'NoContact'
        );
        insert oldTask;

        Task task = [SELECT Id, AccountId, El_cliente_fue_contactado__c, ClienteNoQuiereSerContactado__c, Status, DeveloperName__c FROM Task WHERE Id = :oldTask.Id];
        task.El_cliente_fue_contactado__c = 'No';
        task.ClienteNoQuiereSerContactado__c = true;
        task.Status = 'Completado';

        Map<String, Object> result = PSTA_ChangeAccountInfo_helper.changeContacAndDatetStatus(
            task,
            oldTask,
            cadence,
            acc
        );
        System.debug('Resultado: ' + result);
    }
    @isTest
    static void test_changeContacAndDatetStatus_ClienteContactado(){
        Account acc = [SELECT ID, EstatusContacto__c FROM ACCOUNT LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad de Prueba',
            StageName = 'Prospecto',
            CloseDate = Date.today(),
            AccountId = acc.Id

        );
        insert opp;
        Task oldTask = new Task(
            Subject = 'Llamada de prueba',
            Status = 'Completado',
            Priority = 'Normal',
            WhatId = acc.Id,
            El_cliente_fue_contactado__c = 'Si',
            ClienteNoQuiereSerContactado__c = false,
            Genere_una_oportunidad__c = opp.Id,
            Por_que_no_se_genero_una_oportunidad__c = 'test',
            Fecha_de_contactacion__c = System.Today(),
            DeveloperName__c = 'TestCadence',
            RecordTypeId = idTaskRecordType
        );
        insert oldTask;
        Task task = [SELECT Id, AccountId, El_cliente_fue_contactado__c, ClienteNoQuiereSerContactado__c, Status, DeveloperName__c FROM Task WHERE Id = :oldTask.Id];
        task.El_cliente_fue_contactado__c = 'No';
        task.ClienteNoQuiereSerContactado__c = false;
        task.Status = 'Completado';
        Test.startTest();
        Map<String, Object> result = PSTA_ChangeAccountInfo_helper.changeContacAndDatetStatus(
            task,
            oldTask,
            cadence,
            acc
        );
        Test.stopTest();
    }
    @isTest
    static void test_publicarEvento(){
        Account acc = [SELECT ID, EstatusContacto__c FROM ACCOUNT LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad de Prueba',
            StageName = 'Prospecto',
            CloseDate = Date.today(),
            AccountId = acc.Id

        );
        insert opp;
        Task oldTask = new Task(
            Subject = 'Llamada de prueba',
            Status = 'Completado',
            Priority = 'Normal',
            WhatId = acc.Id,
            El_cliente_fue_contactado__c = 'Si',
            Genere_una_oportunidad__c = opp.Id,
            Por_que_no_se_genero_una_oportunidad__c = 'test',
            ClienteNoQuiereSerContactado__c = false,
            DeveloperName__c = 'TestCadence',
            RecordTypeId = idTaskRecordType

        );
        insert oldTask;
        Test.startTest();
        PSTA_ChangeAccountInfo_helper.publicarEvento(oldTask.Id, System.UserInfo.getUserId());
        Test.stopTest();
    }
}