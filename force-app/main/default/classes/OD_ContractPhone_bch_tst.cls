/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Description       :   Clase test de la clase OD_ContractPhoneCleaner_bch. 
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         22-Dic-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_ContractPhone_bch_tst {
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

        Telefono_de_Contrato__c objTel = new Telefono_de_Contrato__c();
        objTel.Name = 'Test';
        objTel.IDSap__c = objContract.Id;
        objTel.Phone_Type__c = 'CELULAR';
        objTel.Area_Code__c = '52';
        objTel.Lada__c = '473';
        objTel.Phone__c = '1768347';
        objTel.principal__c = false;
        insert objTel;

        Telefono_de_Contrato__c objTel1 = new Telefono_de_Contrato__c();
        objTel1.Name = 'Test2';
        objTel1.IDSap__c = objContract.Id;
        objTel1.Phone_Type__c = 'CELULAR';
        objTel1.Area_Code__c = '052';
        objTel1.Lada__c = '0473';
        objTel1.Phone__c = '1768347';
        objTel1.principal__c = false;
        insert objTel1;
    }

    @IsTest 
    static void testContractEmailBatch(){
        
        Test.startTest();
        OD_ContractPhoneCleaner_bch contractBatch = new OD_ContractPhoneCleaner_bch();
        Database.executeBatch(contractBatch, 5);
        Test.stopTest();
        
    }
    
}