/****************************************************************************************************
    Desarrollado por: Isaac Canche
    Proyecto        : Actinver - Asignacion de Leads
    Descripción     : Clase que de pruebas para la clase ASL_LeadAssignmentChannel_cls. y ASL_ApexConditionalManagement_cls.
*/
@isTest
public class ASL_LeadsAssignmentChannel_tst {
    @TestSetup
    static void setup() {
        // Crear configuración de prueba
        Catalogs__c catalogo = new Catalogs__c(
            Name = 'Prueba1', 
            Activo__c = true, 
            RecordTypeId = Schema.SObjectType.Catalogs__c.getRecordTypeInfosByDeveloperName().get('Grupo').getRecordTypeId(),
            NombreGrupo__c = 'Prueba1'
        );
        
        insert catalogo;

        ConfiguracionActinver__c config = new ConfiguracionActinver__c(
            DeveloperName__c = 'ConfiguracionLeadPatrimonial',
            RecordTypeId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('AsignacionLeadsPatrimonial').getRecordTypeId(),
            Activo__c = true,
            PorGrupo__c = true,
            PorCodigoPostal__c = false,
            Grupo__c = catalogo.Id,
            JSONConfiguracion__c = '{"inputLogicValue":"1 AND 2","conditionsData":[["PostalCode|1",{"id":1,"apiName":"PostalCode","operator":"==","type":"STRING","searchTerm":"Código postal","value":"11320"}],["FinServ__ExpressedInterest__c|2",{"id":2,"apiName":"FinServ__ExpressedInterest__c","operator":"==","type":"PICKLIST","searchTerm":"Interés expresado","value":"Banca Patrimonial"}]]}'
        );
        insert config;
        
        List<TipoDatosApex__mdt> requiredMetadata = new List<TipoDatosApex__mdt>{
            TipoDatosApex__mdt.getInstance('STRING'),
            TipoDatosApex__mdt.getInstance('BOOLEAN'),
            TipoDatosApex__mdt.getInstance('EMAIL')
        };

        
    }
    
    @isTest
    static void testSelectChannelAssignament() {
     
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        
        
        List<Lead> leads = new List<Lead>{objLead};

        insert leads;

        objLead = [SELECT Id, Name, OwnerId FROM Lead WHERE Id = :leads[0].Id];
        Test.startTest();
        
        ASL_LeadsAssignmentChannel_cls.selectChannelAssignament(leads);
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGetLeadsTypeAssignament_WithPostalCode() {
        // Configurar datos de prueba
        
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        List<Lead> leads = new List<Lead>();
        leads.add(objLead);
        
        
        insert leads;
        objLead = [SELECT Id, Name, PostalCode FROM Lead WHERE Id = :leads[0].Id];

        
        Test.startTest();
        Map<String, List<Lead>> result = ASL_LeadsAssignmentChannel_cls.getLeadsTypeAssignament(
            new List<Lead>{objLead},
            false,
            new Map<String, Object>()
        );
        Test.stopTest();
    }
    
    
    @isTest
    static void testAssignamentByGroup_WithValidationFilters() {
        // Configurar datos de prueba
        
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        List<Lead> leads = new List<Lead>();
        leads.add(objLead);
        
        
        insert leads;
        
        objLead = [SELECT Id, Name, OwnerId FROM Lead WHERE Id = :leads[0].Id];

        // Preparar mapas de validación
        Map<String, Object> mapValidatedLeads = new Map<String, Object>{
            'mapLeadsInsideFilter' => new Map<String, Lead>{objLead.Id => objLead},
            'mapLeadsOutsideFilter' => new Map<String, Lead>{objLead.Id => objLead}
        };
        
        Test.startTest();
        ASL_LeadsAssignmentChannel_cls.assignamentByGroup(
            'GrupoTest',
            new List<Lead>{objLead},
            true,
            mapValidatedLeads
        );
        Test.stopTest();
        
    }
    
    @isTest
    static void testAssignamentByPostalCode() {
        // Configurar datos de prueba
        
        Lead objLead = LeadTrigger_Utility.createLeadRTGeneral();
        List<Lead> leads = new List<Lead>();
        leads.add(objLead);
        
        
        insert leads;

        objLead = [SELECT Id, Name, OwnerId,PostalCode FROM Lead WHERE Id = :leads[0].Id];
        Test.startTest();

        ASL_LeadsAssignmentChannel_cls.assignamentByPostalCode(new List<Lead>{objLead});
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetLeadAssignmentSettings() {
        Test.startTest();
        ConfiguracionActinver__c result = ASL_LeadsAssignmentChannel_cls.getLeadAssignmentSettings();
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testPostalCodeAssigment_WithBypass() {
        ASL_LeadsAssignmentChannel_cls.bypassTriggerExecution = true;
        
        Test.startTest();
        ASL_LeadsAssignmentChannel_cls.postalCodeAssigment(new List<Lead>());
        Test.stopTest();
        
    }
    
    @isTest
    static void testHelperMethods() {
        Test.startTest();
        String randomStr = ASL_ApexConditionalManagement_cls.generateRandomString(10);
        
        String containsCondition = ASL_ApexConditionalManagement_cls.getConditionByfunction('var1', 'var2', 'contains');
        
        String stringValue = ASL_ApexConditionalManagement_cls.getStringTypeValue('test');
        
        String dateValue = ASL_ApexConditionalManagement_cls.getDateTypeValue('2023-01-01');
        
        String datetimeValue = ASL_ApexConditionalManagement_cls.getDateTimeTypeValue('2023-01-01 10:00:00');
        Test.stopTest();
    }
    
    @isTest
    static void testGetLeadAssignmentSettingsError() {
        delete [SELECT JSONConfiguracion__c FROM ConfiguracionActinver__c LIMIT 1];
        Test.startTest();
        ConfiguracionActinver__c result = ASL_LeadsAssignmentChannel_cls.getLeadAssignmentSettings();
        ConfiguracionActinver__c config = ASL_ApexConditionalManagement_cls.getLeadAssignmentSettings();
        Test.stopTest();
    }


}