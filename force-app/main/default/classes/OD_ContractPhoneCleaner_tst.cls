/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Organizacion de Datos
* Clase 		:   OD_ContractPhoneCleaner_cls
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         22-Dic-2024       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class OD_ContractPhoneCleaner_tst {
    
    @testSetup
    static void testSetup() {
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

        Telefono_de_Contrato__c objTel = new Telefono_de_Contrato__c();
        objTel.Name = 'Test';
        objTel.IDSap__c = objContract.Id;
        objTel.Phone_Type__c = 'CELULAR';
        objTel.Area_Code__c = '52';
        objTel.Lada__c = '473';
        objTel.Phone__c = '1768347';
        objTel.principal__c = false;
        insert objTel;

        Telefono_de_Contrato__c objTel1 = new Telefono_de_Contrato__c();
        objTel1.Name = 'Test2';
        objTel1.IDSap__c = objContract.Id;
        objTel1.Phone_Type__c = 'CELULAR';
        objTel1.Area_Code__c = '00052';
        objTel1.Lada__c = '473';
        objTel1.Phone__c = '1768347';
        objTel1.principal__c = false;
        insert objTel1;

        Telefono_de_Contrato__c objTelNoData = new Telefono_de_Contrato__c();
        objTelNoData.Name = 'TestNoData';
        objTelNoData.Phone_Type__c = 'CELULAR';
        objTelNoData.principal__c = true;
        insert objTelNoData;

        Telefono_de_Contrato__c objTelNoArea = new Telefono_de_Contrato__c();
        objTelNoArea.Name = 'TestNoArea';
        objTelNoArea.IDSap__c = objContract.Id;
        objTelNoArea.Phone_Type__c = 'CELULAR';
        objTelNoArea.Area_Code__c = '00000';
        objTelNoArea.Lada__c = '0000473';
        objTelNoArea.Phone__c = '00001768347';
        objTelNoArea.principal__c = false;
        insert objTelNoArea;

        Telefono_de_Contrato__c objTelNoLada = new Telefono_de_Contrato__c();
        objTelNoLada.Name = 'TestNoArea';
        objTelNoLada.IDSap__c = objContract.Id;
        objTelNoLada.Phone_Type__c = 'CELULAR';
        objTelNoLada.Area_Code__c = '52';
        objTelNoLada.Lada__c = '000999';
        objTelNoLada.Phone__c = '001768347';
        objTelNoLada.principal__c = false;
        insert objTelNoLada;

        Telefono_de_Contrato__c objTelNoPhone = new Telefono_de_Contrato__c();
        objTelNoPhone.Name = 'TestNoArea';
        objTelNoPhone.IDSap__c = objContract.Id;
        objTelNoPhone.Phone_Type__c = 'CELULAR';
        objTelNoPhone.Area_Code__c = '0052';
        objTelNoPhone.Lada__c = '999';
        objTelNoPhone.Phone__c = '001768347';
        objTelNoPhone.principal__c = false;
        insert objTelNoPhone;

    }

    @isTest
    static void testValidateExistingRelatedContract() {
        // Obtener un registro existente para probar
        Telefono_de_Contrato__c telefono = [SELECT IDSap__c FROM Telefono_de_Contrato__c WHERE IDSap__c != null LIMIT 1];

        // Validar contrato relacionado
        Boolean result = OD_ContractPhoneCleaner_cls.ValidateExistingRelatedContract(telefono);
        System.assert(result, 'El contrato relacionado debe ser válido');

        // Probar caso sin IDSap__c
        telefono.IDSap__c = null;
        result = OD_ContractPhoneCleaner_cls.ValidateExistingRelatedContract(telefono);
        System.assert(!result, 'El contrato relacionado no debe ser válido');
    }

    @isTest
    static void testValidateAndUpdateRecords() {
        // Obtener registros para validar y actualizar
        List<Telefono_de_Contrato__c> lstTelefonos = [
            SELECT IDSap__c, Area_Code__c, Lada__c, Phone__c, DatoContactoNoValido__c 
            FROM Telefono_de_Contrato__c
        ];

        // Validar y actualizar registros
        List<Telefono_de_Contrato__c> lstTelefonosToUpdate = OD_ContractPhoneCleaner_cls.ValidateAndUpdateRecords(lstTelefonos);

        // Verificar resultados
        System.assert(lstTelefonosToUpdate.size() > 0, 'Debe haber registros que necesiten actualización');

        for (Telefono_de_Contrato__c telefono : lstTelefonosToUpdate) {
            if (telefono.IDSap__c == null) {
                System.assert(telefono.DatoContactoNoValido__c, 'Debe marcarse como contacto no válido');
            }

            if (telefono.Area_Code__c == null) {
                System.assert(telefono.DatoCodigoAreaNoValido__c, 'Debe marcarse como código de área no válido');
            }
        }
    }

    @isTest
    static void testGetLadasMap() {
        // Probar el mapa de Ladas
        Test.startTest();
        Map<String, ConfiguracionTelefonicaRegional__mdt> mapLadas = OD_ContractPhoneCleaner_cls.getLadasMap();
        Test.stopTest();
    }

    @isTest
    static void testGetPaisByTotalDigitosMap() {
        // Probar el mapa de códigos de país por dígitos totales
        Test.startTest();
        Map<String, Integer> mapPais = OD_ContractPhoneCleaner_cls.getPaisByTotalDigitosMap();
        Test.stopTest();
    }

    @isTest
    static void testVerifyLadaStringInKeyMap() {
        Test.startTest();
        Map<String, ConfiguracionTelefonicaRegional__mdt> mapLadas = OD_ContractPhoneCleaner_cls.getLadasMap();

        ConfiguracionTelefonicaRegional__mdt config = OD_ContractPhoneCleaner_cls.VerifyLadaStringInKeyMap(mapLadas, '999');
        Test.stopTest();
    }

    @isTest
    static void testVerifyAreaCodeStringInKeyMap() {
        Test.startTest();
        Map<String, Integer> mapPais = OD_ContractPhoneCleaner_cls.getPaisByTotalDigitosMap();

        Integer digits = OD_ContractPhoneCleaner_cls.VerifyAreaCodeStringInKeyMap(mapPais, '52');
        
        Test.stopTest();
    }

    @isTest
    static void testVerifyPhoneStructure() {
        Test.startTest();

        String regex = '^[a-zA-Z0-9]+$';

        System.assertEquals(true, OD_ContractPhoneCleaner_cls.VerifyPhoneStructure(regex, 'abc123'), 'Cadena alfanumérica válida');
        
        Test.stopTest();
    }
}