/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class PV_EnvioEncuestaMedallia_Action_cls_tst {
        public static final Id idTaskRecordType = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Postventa').getRecordTypeId(); 

    @isTest
    static void test_callSendMedallia(){
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(Name = 'Cuenta de Prueba');
        insert acc;
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
            ClienteNoQuiereSerContactado__c = false,
            Genere_una_oportunidad__c = opp.Id,
            Por_que_no_se_genero_una_oportunidad__c = 'test',
            DeveloperName__c = 'TestCadence',
            RecordTypeId = idTaskRecordType
        );
        insert task;
        PV_EnvioEncuestaMedallia_Action_cls objeto = new PV_EnvioEncuestaMedallia_Action_cls();
        PV_EnvioEncuestaMedallia_Action_cls.Parameters params = new PV_EnvioEncuestaMedallia_Action_cls.Parameters();
        List<PV_EnvioEncuestaMedallia_Action_cls.Parameters> lstParams = new List<PV_EnvioEncuestaMedallia_Action_cls.Parameters>();
        params.idTask = task.Id;
        lstParams.add(params);
        Test.starttest();
        PV_EnvioEncuestaMedallia_Action_cls.calloutMedallia(lstParams);
        Test.stopTest();
    }
}