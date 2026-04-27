@IsTest(SeeAllData=true)
public class AccountTrigger_Test {

    @IsTest
    static void test_insert_and_update_trigger_on() {
        // Verifica que exista el registro CMDT que el trigger busca
        String devName = System.Label.AccountTrigger;

        Trigger_Management__mdt mdt = Trigger_Management__mdt.getInstance(devName);
        System.assertNotEquals(null, mdt,
            'No existe Trigger_Management__mdt con DeveloperName=' + devName +
            '. Debes desplegarlo en DevOps/metadata antes del test.'
        );
        System.assertEquals(true, mdt.IsActive__c,
            'El trigger está apagado (IsActive__c=false). Enciéndelo en metadata para que el test cubra lógica.'
        );

        Account acc = new Account();
        acc.Person_Type__c = 'FISICA';
        acc.FirstName = 'Gerardo TEST';
        acc.LastName  = 'Bautista';
        acc.ID_ASESOR__c = '62141';

        Test.startTest();
        insert acc;

        acc.LastName = 'Bautista UPD';
        acc.ID_ASESOR__c = '99999';
        update acc;
        Test.stopTest();

        Account a = [
            SELECT Id, RecordTypeId, LastName, ID_ASESOR__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('Bautista UPD', a.LastName);
        System.assertEquals('99999', a.ID_ASESOR__c);
        System.assertNotEquals(null, a.RecordTypeId);
    }
}