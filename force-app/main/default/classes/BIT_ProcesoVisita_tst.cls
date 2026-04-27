/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : Actinver - Bitácora
Descripción      : Clase test para la clase BIT_ProcesoVisita
*/
@isTest
public class BIT_ProcesoVisita_tst {
	
    @isTest
    static void getDisabledFields() {
        // Datos de prueba
        String fieldSetEnabled = 'BIT_PageLayoutNuevoServicioEnabled';
        String fieldSetDisabled = 'BIT_PageLayoutNuevoServicioDisabled';
        String objectName = 'Servicio__c';

        Test.startTest();
        Map<String, Object> mapParams = new Map<String, Object>{
            'strFieldsetEnabled' => fieldSetEnabled,
            'strFieldsetDisabled' => fieldSetDisabled,
            'strObjectApiName' => objectName
        };
        
        // Llamada al método a probar
        Map<String, Object> response = BIT_ProcesoVisita_ctr.getDisabledFields(mapParams);

        Test.stopTest();
    }
     @isTest
     static void getFieldsToUpdate() {
        Account acc = BIT_UtilityDataTest.createAccount();
        //insert acc;

        Contract contract = new Contract(Name = 'Test Contract', AccountId = acc.Id);
        insert contract;

        BranchUnit branchUnit = new BranchUnit(Name = 'Test Branch Unit',ExternalId__c = '300000003813594',IsActive=true);
        insert branchUnit;

        // Crear un registro de Visita__c
        Visita__c testRecord = createVisita(acc, contract, branchUnit);
        String recordId = testRecord.Id;
        Map<String, Object> mapFields = new Map<String, Object>{
            'HoraSalida__c' => '2024-09-05 10:00:00'
        };

        Test.startTest();
        BIT_ProcesoVisita_ctr.getFieldsToUpdate(recordId, mapFields);
        BIT_ProcesoVisita_ctr.changeStageVisitToStart(recordId);

        // Obtener el registro actualizado
        Visita__c updatedRecord = [SELECT HoraSalida__c FROM Visita__c WHERE Id = :recordId];
        Test.stopTest();
    }

    // Metodo para crear un registro de Visita__c
    public static Visita__c createVisita(Account objAcc, Contract objContract, BranchUnit objSuc){
        Visita__c objVisita = new Visita__c();
        objVisita.RecordTypeId = Schema.SObjectType.Visita__c.getRecordTypeInfosByName().get('Tercero').getRecordTypeId();
        objVisita.CentroFinanciero__c = objSuc.Id;
        objVisita.Nombre__c = 'a';
        objVisita.ApellidoMaterno__c = 'a';
        objVisita.ApellidoPaterno__c = 'a';
            
        insert objVisita;
        return objVisita;
    }
}