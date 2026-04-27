/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_SegmentacionClientesSelector_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     21-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class PSTA_SegmentacionClientesSel_cls_tst {

    @isTest
    static void testGetConfiguracionContratosPostventa() {
        Id rtId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();

        ConfiguracionActinver__c configContratos = new ConfiguracionActinver__c(
            Name = 'Config Contratos Test',
            RecordTypeId = rtId
        );
        insert configContratos;
        ConfiguracionActinver__c result = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
    }

    @isTest
    static void testGetConfiguracionContacto() {
        Id rtId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();

        ConfiguracionActinver__c configContacto = new ConfiguracionActinver__c(
            Name = 'Config Contacto Test',
            Segmento__c = 'Premier',
            RangoMontoMaximo__c = 10000,
            RangoMontoMinimo__c = 1000,
            FrecReinicioNoReqContacto__c = '10',
            Rol__c = 'Farmer Patrimonial',
            FrecuenciaContacto__c = 7,
            FrecuenciaVisita__c = 30,
            ClientesContactarPorDia__c = 5,
            RecordTypeId = rtId
        );
        insert configContacto;
        List<ConfiguracionActinver__c> result = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContacto();
    }

    @isTest
    static void testGetConfiguracionPatrimonialReactivo() {
        Id rtId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();

        ConfiguracionActinver__c configReactivo = new ConfiguracionActinver__c(
            Name = 'Config Patrimonial Reactivo',
            Segmento__c = 'Patrimonial reactivo',
            RangoMontoMaximo__c = 15000,
            RangoMontoMinimo__c = 1500,
            FrecReinicioNoReqContacto__c = '7',
            Rol__c = 'Farmer Patrimonial',
            FrecuenciaContacto__c = 8,
            FrecuenciaVisita__c = 25,
            ClientesContactarPorDia__c = 4,
            RecordTypeId = rtId
        );
        insert configReactivo;

        ConfiguracionActinver__c result = PSTA_SegmentacionClientesSelector_cls.getConfiguracionPatrimonialReactivo();

        System.assertNotEquals(null, result);
        System.assertEquals('Patrimonial reactivo', result.Segmento__c);
    }
    
    @isTest
    static void testGetQueryStatusCuentas() {
        
	
        String result = PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas();

    }
    @isTest
    static void test_getStringQuery(){
        Test.startTest();
        PSTA_SegmentacionClientesSelector_cls.getStringQuery(new List<String>{'1','2','3'});
        Test.stopTest();
    }
    @isTest
    static void test_getQueryAllBBM(){
        Test.startTest();
        PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM();
        Test.stopTest();
    }
    @isTest
    static void test_getQueryCuentas(){
        Test.startTest();
        PSTA_SegmentacionClientesSelector_cls.getQueryCuentas();
        Test.stopTest();
    }
}