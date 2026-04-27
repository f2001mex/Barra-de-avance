/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
* Project           :   Bitácora anfitrión.
* Description       :   Clase test de la clase BIT_FinalizarVisitas_Helper
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         10-Ene-2025       Salvador Ramírez           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@isTest
public class BIT_FinalizarVisitas_Helper_Test {
    @TestSetup
    static void makeData(){
        BranchUnit objSuc = BIT_UtilityDataTest.createBranchUnit();
        Visita__c visita = new Visita__c(Etapa__c = 'Iniciado', 
                                        CentroFinanciero__c = objSuc.Id,
                                        Telefono__c = '2711768347',
                                        Nombre__c = 'Pruebas',
                                        ApellidoPaterno__c = 'Test',
                                        RecordTypeId = Schema.getGlobalDescribe().get('Visita__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Prospecto').getRecordTypeId());
        insert visita;
    }
    @isTest
    static void test_getServicios(){
        Visita__c objVisita = [SELECT ID, Name, Telefono__c, RecordTypeId, Correo__c FROM Visita__c LIMIT 1];
        test.startTest();
        List<Servicio__c> lstServ = BIT_FinalizarVisitas_Helper.getServicios(new Set<Id>{objVisita.Id});
        test.stopTest();
    }
    @isTest
    static void test_updateRecords(){
        Visita__c objVisita = [SELECT ID, Name, Telefono__c, RecordTypeId, Correo__c FROM Visita__c LIMIT 1];
        objVisita.Telefono__c = null;
        objVisita.Correo__c = null;
        objVisita.Candidato__c = null;
        List<Visita__c> lstVisita = new List<Visita__c>{objVisita};
        Map<Id, String> mapRecords = new Map<Id, String>{objVisita.Id => objVisita.Name};
        Test.startTest();
        BIT_FinalizarVisitas_Helper.updateRecords(lstVisita, mapRecords);
        Test.stopTest();
    }
}