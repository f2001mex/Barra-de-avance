/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : Actinver - Bitácora
Descripción      : Clase test para la clase EventLogger
*/
@isTest
public class EventLogger_tst {

    @isTest
    static void testErrorWithoutValues() {
        // Configurar datos de prueba
        Map<String, String> logErrorMap = new Map<String, String>();
        logErrorMap.put('type', 'Medallia');
        logErrorMap.put('message', 'Test error message');
        logErrorMap.put('request', 'Test request data');
        logErrorMap.put('contextId', '001000000000001');
        logErrorMap.put('errorCode', '404');
        
        // Ejecutar el método que se está probando
        Test.startTest();
        EventLogger.error(logErrorMap);
        Test.stopTest();
        
        // Verificar los resultados
        List<WebServiceTrackingLog__c> logs = [SELECT Id, Name, Message__c, Request__c, Type__c, Class__c, Method__c, Line__c, Visita__c, Code__c FROM WebServiceTrackingLog__c];       
    }
    
    @isTest
    static void testErrorWithValues() {
        // Configurar datos de prueba
        Map<String, String> logErrorMap = new Map<String, String>();
        logErrorMap.put('type', 'Medallia');
        logErrorMap.put('message', 'Test error message with values');
        logErrorMap.put('request', 'Test request data');
        logErrorMap.put('contextId', '001000000000001');
        logErrorMap.put('errorCode', '500');
        
        List<Object> values = new List<Object>{'Value1', 'Value2'};
        
        // Ejecutar el método que se está probando
        Test.startTest();
        EventLogger.error(logErrorMap, values);
        Test.stopTest();
        
        // Verificar los resultados
        List<WebServiceTrackingLog__c> logs = [SELECT Id, Name, Message__c, Request__c, Type__c, Class__c, Method__c, Line__c, Visita__c, Code__c FROM WebServiceTrackingLog__c];
    }

    @isTest
    static void getRecordTypeId() {
        // Configurar datos de prueba
        String developerName = 'Medallia';
        
        // Ejecutar el método que se está probando
        Id recordTypeId = EventLogger.getRecordTypeId(developerName);
    }
}