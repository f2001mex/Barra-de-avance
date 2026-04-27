/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Description       :   Clase test de la clase OD_ContractEmailCleaner_cls. 
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         22-Nov-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_ContractEmailCleaner_tst {
    
    @TestSetup
    static void setupTestData() {
        // Crear registros de para usar en las pruebas
        /* Profile perfil = [SELECT Id FROM Profile WHERE Name='Administrador del sistema' OR Name='System Administrator']; 
        User usuarioAdministrador = new User(Alias = 'userTest', Email='useradmin.actvasspro@actinver.com', 
                                                       EmailEncodingKey='UTF-8', FirstName= 'John',LastName='Blein', LanguageLocaleKey='en_US', 
                                                       LocaleSidKey='en_US', ProfileId = perfil.Id, 
                                                       TimeZoneSidKey='America/Los_Angeles', UserName='useradmin.actvasspro@actinver.com',
                                                       ID_ASESOR__c = '02030'); */

        OD_Account_cls.bypassTriggerExecution = true;
        
        Account objAcc = new Account();
        objAcc.FirstName = 'Test';
        objAcc.MiddleName = 'Test';
        objAcc.LastName = 'Test';
        objAcc.F3_CURP__c = 'TESTING1';
        objAcc.Client_ID__c = '02030';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert objAcc;
        
        OD_Contract_cls.bypassTriggerExecution = true;

        Contract objContract = new Contract();
        objContract.AccountId = objAcc.Id;
        objContract.ContractNumber__c = '142536';
        objContract.Status__c = 'Aprobado.';
        objContract.IDSap__c = '142536';
        insert objContract;

        Correo_de_Contrato__c objEmails = BIT_UtilityDataTest.createEmails(objContract);

        Correo_de_Contrato__c objEmailNoContract = new Correo_de_Contrato__c();
        objEmailNoContract.Name = 'Test2';
        objEmailNoContract.Contract_email__c = 'test@mail.com';
        objEmailNoContract.Principal__c = false;
        insert objEmailNoContract;

        Correo_de_Contrato__c objEmailNoStructure = new Correo_de_Contrato__c();
        objEmailNoStructure.Name = 'Test3';
        objEmailNoStructure.Contract_email__c = 'testcom';
        objEmailNoStructure.Principal__c = false;
        insert objEmailNoStructure;

    }

    @IsTest
    static void testValidateExistingRelatedContract() {
        // Recuperar datos de prueba
        Correo_de_Contrato__c correoConContrato = [SELECT Id, NUM_CONTRATO__c FROM Correo_de_Contrato__c WHERE NUM_CONTRATO__c != null LIMIT 1];
        Correo_de_Contrato__c correoSinContrato = [SELECT Id, NUM_CONTRATO__c FROM Correo_de_Contrato__c WHERE NUM_CONTRATO__c = null LIMIT 1];

        // Validar caso con contrato relacionado
        System.assertEquals(true, OD_ContractEmailCleaner_cls.ValidateExistingRelatedContract(correoConContrato), 
            'El método debería devolver true para un correo con contrato relacionado.');

        // Validar caso sin contrato relacionado
        System.assertEquals(false, OD_ContractEmailCleaner_cls.ValidateExistingRelatedContract(correoSinContrato), 
            'El método debería devolver false para un correo sin contrato relacionado.');
    }

    @IsTest
    static void testValidateAndUpdateRecords() {

        List<String> restrictedWords = Label.PalabrasRestringidas.split(',');

        // Crear correos electrónicos de prueba en función del contenido de la etiqueta
        
        String invalidEmail = restrictedWords.isEmpty() ? 
                              'scamuser@example.com' : 
                              restrictedWords[0] + 'user@example.com';
        
        Correo_de_Contrato__c objEmailRestricted = new Correo_de_Contrato__c();
        objEmailRestricted.Name = 'TestMail';
        objEmailRestricted.Contract_email__c = invalidEmail;
        objEmailRestricted.Principal__c = false;
        insert objEmailRestricted;

        // Recuperar todos los correos creados
        List<Correo_de_Contrato__c> correos = [SELECT Id, Contract_email__c, NUM_CONTRATO__c, DatoContactoNoValido__c, DatoPalabraRestringida__c FROM Correo_de_Contrato__c];

        // Validar y actualizar registros
        List<Correo_de_Contrato__c> correosToUpdate = OD_ContractEmailCleaner_cls.ValidateAndUpdateRecords(correos);

        // Comprobar los resultados esperados
        System.assert(!correosToUpdate.isEmpty(), 'La lista de correos a actualizar no debería estar vacía.');

        // Verificar que los registros inválidos sean marcados correctamente
        for (Correo_de_Contrato__c correo : correosToUpdate) {
            if (correo.Contract_email__c == invalidEmail) {
                System.assertEquals(true, correo.DatoPalabraRestringida__c, 'El correo con palabras restringidas debería ser marcado.');
            }
            if (correo.Contract_email__c == 'testcom') {
                System.assertEquals(true, correo.DatoContactoNoValido__c, 'El correo con estructura inválida debería ser marcado.');
            }
        }
    }
}