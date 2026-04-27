@isTest
public class ActualizarContratosBatchTest {
    
    @testSetup
    static void setupData() {
        // Crear un registro de Account necesario para el Contract
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contract> contratos = new List<Contract>();
        // Insertar 20 registros de prueba con BusinessUnitNumber__c = '1'
        // (Asegúrate de insertar la cantidad que necesites para la prueba)
        for (Integer i = 0; i < 20; i++) {
            contratos.add(new Contract(
                BusinessUnitNumber__c = '1',   // Se asigna como cadena, como requiere el query
                Source__c = 'Inicial',         // Valor inicial que se espera actualizar
                AccountId = testAccount.Id,
                StartDate = Date.today()
            ));
        }
        insert contratos;
    }
    
    // Prueba la ejecución del batch (start y execute)
    @isTest
    static void testBatchWithData() {
        // Instanciar la clase batch
        ActualizarContratosBatch batchJob = new ActualizarContratosBatch();
        
        // Consultar la cantidad de registros que cumplen la condición, 
        // de modo que el batch size sea exactamente igual a esa cantidad
        Integer totalRecords = [SELECT COUNT() FROM Contract WHERE BusinessUnitNumber__c = '1'];
        
        Test.startTest();
            // Ejecutar el batch usando totalRecords como tamaño del lote para asegurar una sola invocación
            ID batchId = Database.executeBatch(batchJob, totalRecords);
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'El batch debe haberse encolado correctamente.');
        
        // Consultar los registros para confirmar que el campo Source__c se actualizó a "Contrato de Banco"
        List<Contract> contratosActualizados = [
            SELECT Id, Source__c 
            FROM Contract 
            WHERE BusinessUnitNumber__c = '1'
        ];
        for (Contract c : contratosActualizados) {
            System.assertEquals('Contrato de Banco', c.Source__c,
                'El campo Source__c debe haberse actualizado a "Contrato de Banco".');
        }
    }
    
    // Prueba el método finish invocándolo directamente con un contexto simulado
    @isTest
    static void testFinishMethod() {
        ActualizarContratosBatch batchJob = new ActualizarContratosBatch();
        DummyBatchableContext dummyContext = new DummyBatchableContext();
        Test.startTest();
            batchJob.finish(dummyContext);
        Test.stopTest();
    }
    
    // Clase interna para simular el contexto batch, implementando los métodos requeridos
    private class DummyBatchableContext implements Database.BatchableContext {
        public String getJobId() {
            return 'dummyJobId';
        }
        public Id getChildJobId() {
            return null;
        }
    }
}