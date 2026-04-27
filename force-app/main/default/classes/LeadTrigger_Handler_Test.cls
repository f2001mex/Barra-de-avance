/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Helper_Test
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     08/04/2025
 * @Group    VASS Latam
 *   ------------------------------------------------------------------------------------------------
 * @Description Clase test de la clase LeadTrigger_Handler y trigger LeadTrigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         08/04/2025       salvador.ramirez@vasscompany.com   Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class LeadTrigger_Handler_Test {
    @isTest
    static void test_beforeInsert_and_afterInsert() {
        Lead newLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            PostalCode = '54987',
            Status = 'Asignado',
            Email = 'test@hotmail.com'
        );

        Test.startTest();
        insert newLead;
        Test.stopTest();

        Lead insertedLead = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE Id = :newLead.Id LIMIT 1];
        System.assertNotEquals(null, insertedLead, 'El lead debería haber sido insertado');
    }

    @isTest
    static void test_beforeUpdate_and_afterUpdate() {
        Lead leadToUpdate = new Lead(
            FirstName = 'Test',
            LastName = 'Update',
            Company = 'Initial Company',
            PostalCode = '54987',
            Status = 'Asignado',
            Email = 'test@hotmail.com'
        );
        insert leadToUpdate;

        leadToUpdate.Company = 'Updated Company';
        leadToUpdate.Status = 'Convertido';

        Test.startTest();
        update leadToUpdate;
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Company, Status FROM Lead WHERE Id = :leadToUpdate.Id LIMIT 1];
        System.assertEquals('Updated Company', updatedLead.Company, 'La compañía debería haber sido actualizada');
    }

    // Caso: número > 10 dígitos, ya en formato internacional
    @IsTest
    static void testNumberGreaterThan10Digits() {
        Lead lead = new Lead(FirstName='Juan', LastName='Perez', Phone='+5212345678901', Lada__c=123);
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals('+5212345678901', lead.Telephone__c, 'Debe conservar el número con +');
    }

    // Caso: número de 10 dígitos, se agrega +52
    @IsTest
    static void testNumber10Digits() {
        Lead lead = new Lead(FirstName='Ana', LastName='Lopez', Phone='1234567890', Lada__c=456);
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals('+521234567890', lead.Telephone__c, 'Debe agregar +52 al número de 10 dígitos');
    }

    // Caso: número de 7 dígitos y lada válida, agrega +52 + últimos 3 dígitos de lada
    @IsTest
    static void testNumber7DigitsWithLada() {
        Lead lead = new Lead(FirstName='Luis', LastName='Martinez', Phone='7654321', Lada__c=12345);
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals('+523457654321', lead.Telephone__c, 'Debe formar número con lada y +52');
    }

    // Caso: número con caracteres inválidos, debe poner Telephone__c null y generar error
    @IsTest
    static void testInvalidCharacters() {
        Lead lead = new Lead(FirstName='Marta', LastName='Gomez', Phone='12A-4567');
        Test.startTest();
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        Test.stopTest();
        System.assertEquals(null, lead.Telephone__c, 'Debe ser null por caracteres inválidos');
    }

    // Caso: formato inválido (ni 7, ni 10, ni >10), debe poner null y error
    @IsTest
    static void testInvalidFormat() {
        Lead lead = new Lead(FirstName='Pedro', LastName='Sanchez', Phone='1234');
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals(null, lead.Telephone__c, 'Debe ser null por formato inválido');
    }

    // Caso: sin Phone ni Numero_Telefono__c, no debe modificar ni generar error
    @IsTest
    static void testEmptyPhoneFields() {
        Lead lead = new Lead(FirstName='Lucia', LastName='Diaz');
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals(null, lead.Telephone__c, 'Debe quedar null si no hay número');
    }

    // Caso: con Numero_Telefono__c válido de 10 dígitos
    @IsTest
    static void testNumeroTelefonoFieldValid() {
        Lead lead = new Lead(FirstName='Carlos', LastName='Rojas', Numero_Telefono__c='9876543210', Lada__c=789);
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals('+529876543210', lead.Telephone__c, 'Debe convertir Número_Telefono__c válido');
    }

    // Caso: con Numero_Telefono__c inválido (caracteres no numéricos)
    @IsTest
    static void testNumeroTelefonoFieldInvalid() {
        Lead lead = new Lead(FirstName='Laura', LastName='Vargas', Numero_Telefono__c='ABC123');
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead });
        System.assertEquals(null, lead.Telephone__c, 'Debe ser null por caracteres inválidos en Numero_Telefono__c');
    }

    // Caso: Verificar que se envía correo cuando hay errores
    @IsTest
    static void testErrorNotificationSent() {
        Lead lead1 = new Lead(FirstName='Error', LastName='Uno', Phone='ABC123');
        Lead lead2 = new Lead(FirstName='Error', LastName='Dos', Phone='1234');

        Test.startTest();
        ACT_LeadTriggerHandler.processLeadPhones(new List<Lead>{ lead1, lead2 });
        Test.stopTest();

        System.assertEquals(null, lead1.Telephone__c, 'Debe ser null por error');
        System.assertEquals(null, lead2.Telephone__c, 'Debe ser null por error');
    }
}