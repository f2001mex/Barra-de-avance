/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_PriorizacionSelector_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     21-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class PSTA_PriorizacionSelector_cls_tst {

    @isTest
    static void test_selectorMethods() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'ConfiguracionActinver__c' AND DeveloperName = 'ContactoPostventa' LIMIT 1];

        ConfiguracionActinver__c config = new ConfiguracionActinver__c(
            Name = 'Config Test',
            Segmento__c = 'Premier',                    
            RangoMontoMinimo__c = 1000.0,                  
            RangoMontoMaximo__c = 5000.0,                  
            FrecReinicioNoReqContacto__c = '10',           
            Rol__c = 'Farmer Patrimonial',
            FrecuenciaContacto__c = 7,                     
            FrecuenciaVisita__c = 30,                      
            ClientesContactarPorDia__c = 5,                
   			RecordTypeId = rt.Id
        );
        insert config;

        Test.startTest();
        String queryMensual = PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual('');
        String queryDiaria = PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria();
        List<ConfiguracionActinver__c> configuraciones = PSTA_PriorizacionSelector_cls.getConfiguracionContacto();
        
        Id idBusinessHours;
        try {
            idBusinessHours = PSTA_PriorizacionSelector_cls.getDiasLaborales();
            System.assertNotEquals(null, idBusinessHours);
        } catch (Exception e) {
            System.debug('BusinessHours "Postventa" no existe: ' + e.getMessage());
        }
        Test.stopTest();
    }
}