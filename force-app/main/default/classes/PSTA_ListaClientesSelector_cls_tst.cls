/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_ListaClientesSelector_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@isTest(SeeAllData=true)
public class PSTA_ListaClientesSelector_cls_tst {

     @isTest
     static void test_getDiasLaborales() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Postventa' LIMIT 1];

        Test.startTest();
        Id result = PSTA_ListaClientesSelector_cls.getDiasLaborales();
        Test.stopTest();
    }

    @isTest
    static void test_getConfiguracionPostVenta() {
        Id recordTypeId = Schema.SObjectType.ConfiguracionActinver__c
            .getRecordTypeInfosByDeveloperName()
            .get('ContactoPostventa')
            .getRecordTypeId();

        Test.startTest();
        List<ConfiguracionActinver__c> result = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Test.stopTest();
    }
}