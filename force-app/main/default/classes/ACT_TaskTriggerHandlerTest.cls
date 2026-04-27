@isTest
private class ACT_TaskTriggerHandlerTest {

    @isTest
    static void testInsertNewPhoneSuccess() {
        Contact contact = makeTestPersonAccount();
        Task t = new Task(
            CallType = 'Inbound',
            ACT_Authenticated_Customer__c = true,
            ACT_Caller_Phone_Number__c = '5511223344',
            WhoId = contact.Id,
            Subject = 'Test Call'
        );
        insert t;

        List<ACT_Genesys_Phone__c> phones = [
            SELECT Id, ACT_Genesys_Phone_Number__c, ACT_Customer__c
            FROM ACT_Genesys_Phone__c
            WHERE ACT_Genesys_Phone_Number__c = '5511223344'
        ];

        System.assertEquals(1, phones.size(), 'Debe haberse creado un número telefónico');
    }

    @isTest
    static void testDuplicatePhoneIsIgnored() {
        Contact contact = makeTestPersonAccount();
        Task t1 = new Task(
            CallType = 'Inbound',
            ACT_Authenticated_Customer__c = true,
            ACT_Caller_Phone_Number__c = '5511223345',
            WhoId = contact.Id,
            Subject = 'First Call'
        );
        insert t1;

        Task t2 = new Task(
            CallType = 'Inbound',
            ACT_Authenticated_Customer__c = true,
            ACT_Caller_Phone_Number__c = '5511223345',
            WhoId = contact.Id,
            Subject = 'Duplicate Call'
        );
        insert t2;

        List<ACT_Genesys_Phone__c> phones = [
            SELECT Id FROM ACT_Genesys_Phone__c
            WHERE ACT_Genesys_Phone_Number__c = '5511223345'
        ];

        System.assertEquals(1, phones.size(), 'No debe haber duplicados para el mismo número');
    }

    @isTest
    static void testUnauthenticatedIsIgnored() {
        Contact contact = makeTestPersonAccount();
        Task t = new Task(
            CallType = 'Inbound',
            ACT_Authenticated_Customer__c = false, // No autenticado
            ACT_Caller_Phone_Number__c = '5588776655',
            WhoId = contact.Id,
            Subject = 'Call no auth'
        );
        insert t;

        List<ACT_Genesys_Phone__c> phones = [
            SELECT Id FROM ACT_Genesys_Phone__c
            WHERE ACT_Genesys_Phone_Number__c = '5588776655'
        ];

        System.assertEquals(0, phones.size(), 'No se debe insertar si no está autenticado');
    }

    // Método auxiliar reutilizable: crea un Person Account y devuelve su Contacto
    private static Contact makeTestPersonAccount() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(
            RecordTypeId = getPersonAccountRecordTypeId(),
            LastName = 'Test Account',
            OwnerId = UserInfo.getUserId()
        );
        insert acc;

        // El Contacto se crea automáticamente
        return [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
    }

    // Obtiene dinámicamente el RecordTypeId de Person Account
    private static Id getPersonAccountRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    }
}