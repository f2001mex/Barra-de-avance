@isTest
public class ACT_UpdateContractPhonesBatchTest {

    @testSetup
    static void data() {
        List<Telefono_de_Contrato__c> testPhones = new List<Telefono_de_Contrato__c>();
        for (Integer i = 0; i < 10; i++) {
            testPhones.add(new Telefono_de_Contrato__c(
                Name = 'Test ' + i,
                Phone__c = '5512345678',
                Lada__c = '55',
                Area_Code__c = '52'
            ));
        }
        insert testPhones;
    }

    @isTest
    static void testBatchExecution_singleInvoke() {
        Test.startTest();
        Id jobId = Database.executeBatch(new ACT_UpdateContractPhonesBatch(), 200);
        Test.stopTest();

        // Asserts
        List<Telefono_de_Contrato__c> updated = [
            SELECT Id, ACT_Contract_Phone__c
            FROM Telefono_de_Contrato__c
        ];
        System.assertEquals(10, updated.size());
        for (Telefono_de_Contrato__c t : updated) {
            System.assertNotEquals(null, t.ACT_Contract_Phone__c);
        }
    }
}