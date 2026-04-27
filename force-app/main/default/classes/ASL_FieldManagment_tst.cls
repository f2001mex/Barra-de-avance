@isTest
public class ASL_FieldManagment_tst {
    @isTest
    static void testInitValues() {
        // Crear un registro de ConfiguracionActinver__c para la prueba
        ConfiguracionActinver__c confAct = new ConfiguracionActinver__c(
            DeveloperName__c = 'ConfiguracionLeadPatrimonial',
            recordTypeId = ASL_FieldManagment_ctr.recordTypeId,
            JSONConfiguracion__c = '{"key":"value"}'
        );
        insert confAct;
        
        // Llamar al método que estamos probando
        Test.startTest();
        String result = ASL_FieldManagment_ctr.initValues();
        Test.stopTest();
        
        // Verificar que el resultado es el JSON esperado
        System.assertEquals('{"key":"value"}', result, 'El valor JSON no es el esperado.');
    }
    
    @isTest
    static void testSaveConditionsData() {
        // Preparar datos de prueba
        String jsonData = '{"newKey":"newValue"}';
        
        // Llamar al método saveConditionsData
        Test.startTest();
        ASL_FieldManagment_ctr.saveConditionsData(jsonData);
        Test.stopTest();
        
        // Verificar que el registro fue creado o actualizado correctamente
        ConfiguracionActinver__c confAct = [SELECT JSONConfiguracion__c FROM ConfiguracionActinver__c WHERE DeveloperName__c = :ASL_FieldManagment_ctr.NameRecord LIMIT 1];
        System.assertEquals('{"newKey":"newValue"}', confAct.JSONConfiguracion__c, 'El JSON guardado no es el esperado.');
    }
    
    @isTest
    static void testGetLeadFields() {
        // Llamar al método que estamos probando
        Test.startTest();
        List<ASL_FieldManagment_ctr.FieldInfo> fields = ASL_FieldManagment_ctr.getLeadFields();
        Test.stopTest();
        
        // Verificar que se devolvieron campos
        System.assertNotEquals(0, fields.size(), 'Se esperaba al menos un campo de Lead.');
        
        // Comprobar que se devolvieron campos con nombres y etiquetas
        System.assertNotEquals(null, fields[0].apiName, 'El campo no tiene un apiName.');
        System.assertNotEquals(null, fields[0].label, 'El campo no tiene una etiqueta.');
    }
    
    @isTest
    static void testSearchRecords() {
        // Crear algunos registros de prueba para buscar
        Account acc1 = new Account(Name = 'Test Account 1');
        insert acc1;
        Account acc2 = new Account(Name = 'Test Account 2');
        insert acc2;
        
        // Llamar al método que estamos probando
        Test.startTest();
        List<Map<String, Object>> results = ASL_FieldManagment_ctr.searchRecords('Account', 'Test');
        Test.stopTest();
        
        // Verificar que se devolvieron registros
        System.assertEquals(2, results.size(), 'Se esperaba que se devolvieran 2 cuentas.');
        
        // Verificar los valores de los registros
        System.assertEquals('Test Account 1', results[0].get('label'), 'El nombre de la cuenta no es el esperado.');
    }

    @isTest
    static void testIsAutoNumber() {
        // Verificar si un campo auto número es correctamente identificado
        Schema.SObjectField field = Lead.FirstName;
        Boolean result = ASL_FieldManagment_ctr.isAutoNumber(field);
        System.assertEquals(false, result, 'FirstName no es un campo auto número.');
    }
    
    @isTest
    static void testIsFormula() {
        // Verificar si un campo fórmula es correctamente identificado
        Schema.SObjectField field = Lead.AnnualRevenue;
        Boolean result = ASL_FieldManagment_ctr.isFormula(field);
        System.assertEquals(false, result, 'AnnualRevenue no es un campo fórmula.');
    }
}