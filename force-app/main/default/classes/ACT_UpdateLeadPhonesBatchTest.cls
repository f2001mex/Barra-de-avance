@isTest
public class ACT_UpdateLeadPhonesBatchTest {

    @testSetup
    static void setupLeads() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Test ' + i,
                Company = 'Test Company',
                Phone = '5512345678',
                Lada__c = 55
            ));
        }
        insert leads;
    }

    @isTest
    static void testBatchExecution_withJobId() {
        Test.startTest();
        // Ejecutar el batch y obtener el JobId
        Id jobId = Database.executeBatch(new ACT_UpdateLeadPhonesBatch(), 200);
        Test.stopTest();
        // Validar que se obtuvo un JobId válido (simboliza que el batch fue aceptado)
        System.assertNotEquals(null, jobId, 'El batch JobId no debería ser null');
        // Validar que los leads fueron actualizados (Telephone__c poblado)
        List<Lead> updatedLeads = [
            SELECT Id, Telephone__c
            FROM Lead
            WHERE Telephone__c != null
        ];
        System.assertEquals(10, updatedLeads.size(), 'Todos los Leads deberían tener Telephone__c poblado');
    }
}