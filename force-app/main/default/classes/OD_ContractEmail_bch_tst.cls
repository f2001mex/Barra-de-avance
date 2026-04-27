/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Description       :   Clase test de la clase OD_ContractEmailCleaner_cls. 
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         22-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_ContractEmail_bch_tst {
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

    @IsTest 
    static void testContractEmailBatch(){
        
        Test.startTest();
        OD_ContractEmailCleaner_bch contractBatch = new OD_ContractEmailCleaner_bch();
        Database.executeBatch(contractBatch, 5);
        Test.stopTest();
        
    }
}