/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase 		    :   OD_ContractEmail_thr
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         22-Dic-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_ContractEmailThr_test {
    @testSetup
    static void testSetup() {
        OD_Account_cls.bypassTriggerExecution = true;
        
        Account objAcc = new Account();
        objAcc.FirstName = 'Test';
        objAcc.MiddleName = 'Test';
        objAcc.LastName = 'Test';
        objAcc.F3_CURP__c = 'TESTING1';
        objAcc.Client_ID__c = '02030';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert objAcc;
        
        OD_Contract_cls.bypassTriggerExecution = true;

        Contract objContract = new Contract();
        objContract.AccountId = objAcc.Id;
        objContract.ContractNumber__c = '142536';
        objContract.Status__c = 'Aprobado.';
        objContract.IDSap__c = '142536';
        insert objContract;

        Correo_de_Contrato__c objEmails = BIT_UtilityDataTest.createEmails(objContract);

        Correo_de_Contrato__c objEmailNoContract = new Correo_de_Contrato__c();
        objEmailNoContract.Name = 'Test2';
        objEmailNoContract.Contract_email__c = 'test@mail.com';
        objEmailNoContract.Principal__c = false;
        insert objEmailNoContract;

        Correo_de_Contrato__c objEmailNoStructure = new Correo_de_Contrato__c();
        objEmailNoStructure.Name = 'Test3';
        objEmailNoStructure.Contract_email__c = 'testcom';
        objEmailNoStructure.Principal__c = false;
        insert objEmailNoStructure;
    }

    @isTest
    static void testBeforeInsert() {
        // Probar el mapa de Ladas
        Test.startTest();
        	OD_ContractEmail_thr.beforeInsert(new List<Correo_de_Contrato__c>());
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdateBypass() {
        // Probar el mapa de Ladas
        Test.startTest();
        OD_ContractEmail_thr.bypassTriggerBeforeInsertExecution = true;
        	OD_ContractEmail_thr.beforeUpdate(new List<Correo_de_Contrato__c>(),new Map<Id, Correo_de_Contrato__c>());
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate() {
        // Desactivar el bypass de ejecución si está activado
        Test.startTest();
        OD_ContractEmail_thr.bypassTriggerBeforeInsertExecution = false;

        // Recuperar el registro insertado en testSetup
        Correo_de_Contrato__c correo = [SELECT Id, Contract_email__c, NUM_CONTRATO__c FROM Correo_de_Contrato__c LIMIT 1];

        // Crear una versión antigua para simular Trigger.oldMap
        Map<Id, Correo_de_Contrato__c> oldMap = new Map<Id, Correo_de_Contrato__c>();
        oldMap.put(correo.Id, correo.clone(false, true)); // Clonar sin ID y con valores originales

        // Modificar los campos para activar el trigger
        correo.Contract_email__c = 'nuevo.correo@ejemplo.com';

        List<Correo_de_Contrato__c> triggerNew = new List<Correo_de_Contrato__c>{correo};

        // Llamar al método antes de la actualización
        OD_ContractEmail_thr.beforeUpdate(triggerNew, oldMap);
        Test.stopTest();

    }

}