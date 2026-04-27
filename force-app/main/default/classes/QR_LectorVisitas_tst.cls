/**
* @File Name : QR_LectorVisitas_tst.cls
* @Description :Clase test de QR_LectorVisitas_ctr
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
public class QR_LectorVisitas_tst {
    @isTest
    static void testSaveData() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account objAcc = new Account();
        objAcc.FirstName = 'Test';
        objAcc.MiddleName = 'Test';
        objAcc.LastName = 'Test';
        objAcc.F3_CURP__c = 'TESTING1';
        objAcc.Client_ID__c = '02030';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert objAcc;
        OD_Account_cls.bypassTriggerExecution = false;
        OD_Contract_cls.bypassTriggerExecution = true;
        Contract objContract = new Contract();
        objContract.AccountId = objAcc.Id;
        objContract.ContractNumber__c = '142536';
        objContract.Status__c = 'Aprobado.';
        objContract.IDSap__c = '142536';
        insert objContract;
        OD_Contract_cls.bypassTriggerExecution = false;

        BranchUnit branchUnit = new BranchUnit(Name = 'Test Branch', ExternalId__c = 'Branch001', isActive = true);
        insert branchUnit;
        
        Map<String, Object> parameters = new Map<String, Object>();
        parameters.put('cfId', branchUnit.Id);
        parameters.put('firstName', 'John');
        parameters.put('lastName1', 'Doe');
        parameters.put('lastName2', 'Smith');
        parameters.put('reason', 'Tercero');
        parameters.put('subReason', 'Movimientos en Ventanilla');
        parameters.put('bp', 'BP123');
        parameters.put('isChecked', false);
        parameters.put('contractNumber', '142536');
        
        List<BranchUnit> branchs = QR_LectorVisitas_ctr.getBranchUnits();
        System.assertEquals(branchs.size() > 0, false);
        
        QR_LectorVisitas_ctr.Respond result = QR_LectorVisitas_ctr.saveData(parameters);
        System.assertEquals(result.success, true);
        System.assertEquals(result.message, QR_LectorVisitas_ctr.MESSAGEEXIT);
        
        List<Visita__c> createdVisita = [SELECT Id, Nombre__c FROM Visita__c WHERE Name = :result.visitId LIMIT 1];
        System.assertNotEquals(createdVisita.isEmpty(), null);

        Servicio__c createdService = [SELECT Id, Motivo__c, TipoVisita__c FROM Servicio__c WHERE Visita__c = :createdVisita LIMIT 1];
        System.assertNotEquals(createdVisita.isEmpty(), null);
    }    
}