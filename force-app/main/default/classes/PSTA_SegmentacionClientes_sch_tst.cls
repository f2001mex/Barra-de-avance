/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
* Project           :   Post Venta
* Clase principal   :   PSTA_SegmentacionClientes_sch
*******************************************************************************/
@isTest
public class PSTA_SegmentacionClientes_sch_tst {
    @isTest
    static void test_execute(){
        Id rtId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();

        ConfiguracionActinver__c configContratos = new ConfiguracionActinver__c(
            Name = 'Config Contratos Test',
            RecordTypeId = rtId
        );
        insert configContratos;
        Test.startTest();
        PSTA_SegmentacionClientes_sch sch = new PSTA_SegmentacionClientes_sch();
        sch.execute(null);
        Test.stopTest();
    }
}