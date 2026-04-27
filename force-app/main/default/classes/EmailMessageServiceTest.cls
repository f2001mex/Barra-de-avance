@isTest
public class EmailMessageServiceTest {

    @isTest
    public static void testSendEmails() {
        try {
            // Preparar los datos
            Folder emailFolder = [SELECT Id FROM Folder WHERE Name = 'Wealth Management' LIMIT 1];
            String adminProfileId = [SELECT Id FROM Profile WHERE Name LIKE '%Banquero W%' LIMIT 1].Id;

            // Crear usuario Asesor
            User ASESOR1 = createTestUser(adminProfileId);

            // Crear registros de prueba dentro de runAs
            EmailTemplate emailTemplate;
            Account testAccount;
            Contact testContact;
            Opportunity testOpp; // Declarar fuera de runAs para que esté accesible fuera

            System.runAs(ASESOR1) {
                // Crear los registros relacionados (Account, Contact, Opportunity)
                testAccount = createTestAccount();
                testContact = createTestContact(testAccount.Id);
                testOpp = createTestOpportunity(testAccount.Id, testContact.Id);

                // Crear la plantilla de correo
                emailTemplate = createTestEmailTemplate(emailFolder.Id);
            }

            // Crear entradas para el método invocable
            List<EmailMessageService.EmailInput> emailInputs = new List<EmailMessageService.EmailInput>();
            emailInputs.add(createEmailInput(testOpp.Id,null, emailTemplate.Id, 'owner@example.com', 'client@example.com'));

            // Llamar al método invocable
            Test.startTest();
            EmailMessageService.sendEmails(emailInputs);
            Test.stopTest();

            // Validar que los correos fueron enviados correctamente
            List<EmailMessage> sentEmails = [SELECT Id, ToAddress, Subject, FromAddress, RelatedToId, FromId FROM EmailMessage];
            System.assertEquals(2, sentEmails.size(), 'Debe haber dos correos enviados');
            System.assertEquals('client@example.com', sentEmails[0].ToAddress, 'El correo del destinatario no coincide');
            System.assertEquals('client@example.com', sentEmails[1].ToAddress, 'El correo del destinatario no coincide');
        } catch (Exception ex) {
            System.debug('Error inesperado al enviar correo: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
        }
    }

    @isTest
    public static void testSendEmailsLead() {
        // Preparar datos para el método invocable
        List<EmailMessageService.EmailInput> emailInputs = new List<EmailMessageService.EmailInput>();
        String adminProfileId = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Administrador del sistema') LIMIT 1].Id;

        User ASESOR1 = createTestUser(adminProfileId);
        ASESOR1.Email = 'testcontact@example.com';
        update ASESOR1;

        EmailTemplate emailTemplate;
        Lead testLead; // Declarar fuera de runAs para que esté accesible

        System.runAs(ASESOR1) {
            Folder emailFolder = [SELECT Id FROM Folder WHERE Name = 'Wealth Management' AND Type = 'Email' LIMIT 1];
            emailTemplate = createTestEmailTemplate(emailFolder.Id);

            // Crear registros relacionados
            testLead = createTestLead();
            System.debug('testLead: ' + testLead);
            emailInputs.add(createEmailInput(null,testLead.Id, emailTemplate.Id, ASESOR1.Email, 'client@example.com'));
        }

        // Llamar al método invocable
        Test.startTest();
        EmailMessageService.sendEmails(emailInputs);
        Test.stopTest();
    }

    @isTest
    public static void testSendEmailsWithMissingData() {
        // Validar que no se envían correos cuando faltan datos
        List<EmailMessageService.EmailInput> emailInputs = new List<EmailMessageService.EmailInput>();

        // Caso sin plantilla de correo
        EmailMessageService.EmailInput inputNoTemplate = new EmailMessageService.EmailInput();
        inputNoTemplate.relatedId = null;
        inputNoTemplate.emailTemplateId = null;
        inputNoTemplate.ownerEmail = 'owner@example.com';
        inputNoTemplate.clientEmail = 'client@example.com';
        emailInputs.add(inputNoTemplate);

        Test.startTest();
        EmailMessageService.sendEmails(emailInputs);
        Test.stopTest();

        // Validar que no se han creado correos
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, sentEmails.size(), 'No debería haberse enviado ningún correo sin plantilla');
    }

    // Métodos auxiliares para optimizar la creación de registros
    private static User createTestUser(String profileId) {
        Map<Schema.SObjectField, Object> mapFields = new Map<Schema.SObjectField, Object>{
            User.LastName => 'ASESOR1',
            User.ProfileId => profileId,
            User.ID_ASESOR__c => '0001'
        };
        return UtilitiesDataTest.createUser(mapFields);
    }

    private static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            ID_ASESOR__c = '0001'
        );
        insert acc;
        return acc;
    }

    private static Contact createTestContact(Id accountId) {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = accountId
        );
        insert con;
        return con;
    }

    private static Opportunity createTestOpportunity(Id accountId, Id contactId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accountId,
            ContactId = contactId
        );
        insert opp;
        return opp;
    }

    private static Lead createTestLead() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            PostalCode = '12345',
            Email = 'testlead@example.com',
            Status = 'Open - Not Contacted'
        );
        insert lead;
        return lead;
    }

    private static EmailMessageService.EmailInput createEmailInput(Id relatedId, Id leadId, Id emailTemplateId, String ownerEmail, String clientEmail) {
        EmailMessageService.EmailInput input = new EmailMessageService.EmailInput();
        input.relatedId = relatedId;
        input.leadId = leadId;
        input.emailTemplateId = emailTemplateId;
        input.ownerEmail = ownerEmail;
        input.clientEmail = clientEmail;
        return input;
    }

    private static EmailTemplate createTestEmailTemplate(Id folderId) {
        EmailTemplate emailTemplate = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            Subject = 'Test Email Subject',
            HtmlValue = '<html><body><h1>Test Email</h1></body></html>',
            Body = 'Test Email Body',
            FolderId = folderId,
            TemplateType = 'custom'
        );
        insert emailTemplate;
        return emailTemplate;
    }
}