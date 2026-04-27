/** ---------------------------------------------------------------------------------------------------
    * @Description: Test class for F3_SendDataToSAP_Handler and Helper classes
    *   ------------------------------------------------------------------------------------------------
    Author                  Date                Version                 Changes
    Victor Galvan           20/02/2023          1.0                     Class creation
* ------------------------------------------------------------------------------------------------**/
@isTest
public class F3_SendDataToSAP_Test {
	static List<String> lstLeads = new List<String>();
	static List<String> lstOpps = new List<String>();

	@TestSetup
	static void makeData() {
		String recordTypeID = ((SObject) Type.forName('Schema', 'Lead').newInstance())
			.getSObjectType()
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Prospecto')
			.getRecordTypeId();
		Lead lead = new Lead();
		lead.RecordTypeId = recordTypeID;
		lead.FirstName = 'Test';
		lead.LastName = 'Lead';
        lead.Email = lead.FirstName+lead.LastName+'@testlead.com';
		lead.PostalCode = '20000';
		lead.Fecha_Nacimiento_Prospecto__c = Date.today().addDays(-7200);
		insert lead;

		Account acc = new Account();
		acc.Name = 'Test Account';
		acc.Client_ID__c = '12560002';
		insert acc;
		Opportunity op = new Opportunity();
		op.Name = 'Test Opportunity';
		op.AccountId = acc.Id;
		op.StageName = 'Contacto inicial';
		op.CloseDate = Date.today();
		insert op;
	}
	@IsTest
	public static void testSendLeads() {
		Lead lead = [SELECT Id FROM Lead WHERE FirstName = 'Test'][0];
		lstLeads.add(lead.Id);
		F3_Integration_Service__mdt testMetadata = createMetadataSendLeads();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
		F3_SendDataToSAP_Handler.sendLeads(lstLeads, true,'crearClienteContrato',System.Label.crearClienteContrato_Fields);
		//verify service response
		/*System.debug('###Response: ' + response);
		system.assert(response.contains('"Status":"success"'), 'Response is not success');
		system.assert(response.contains('"serviceCode":"200"'), 'serviceCode different than 200');*/

		String response2 = F3_SendDataToSAP_Controller.createClientSAP(lstLeads, true);
		system.assert(response2.contains('"Status":"success"'), 'Response is not success');
		system.assert(response2.contains('"serviceCode":"200"'), 'serviceCode different than 200');
		System.debug('###response2: ' + response2);
	}

	@isTest
	public static void testSendOpps() {
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'][0];
		lstOpps.add(opp.Id);
		F3_Integration_Service__mdt testMetadata = createMetadataSendOpps();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
		String response = F3_SendDataToSAP_Handler.sendOpps(lstOpps);
		//verify service response
		System.debug('###Response: ' + response);
		system.assert(response.contains('"Status":"success"'), 'Response is not success');
		system.assert(response.contains('"serviceCode":"200"'), 'serviceCode different than 200');

		String response2 = F3_SendDataToSAP_Controller.createContractSAP(lstOpps);
		system.assert(response2.contains('"Status":"success"'), 'Response is not success');
		system.assert(response2.contains('"serviceCode":"200"'), 'serviceCode different than 200');
		System.debug('###response2: ' + response2);
	}

	@isTest
	public static void testGetAccount() {
		Account acc = [SELECT Id, Name, Client_ID__c FROM Account WHERE Name = 'Test Account'][0];
		/*F3_Integration_Service__mdt testMetadata = createMetadataGetAccount();
        F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(F3_URL__c = 'testService.com', F3_Enable_Log__c = true, F3_Service_Type__c = 'ApexRest');
        Integration_Service.testSettings = new Map<String, Object>{'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings};
        //Integration_Service.ServiceResponse response = Integration_Service.calloutService('crearClienteContrato', null);
        String response = F3_SendDataToSAP_Handler.getAccount(acc.Client_ID__c);
        //verify service response
        System.debug('###Response: '+response);
        //system.assert(response.contains('"serviceCode":"200"'), 'serviceCode different than 200');

        String response2 = F3_SendDataToSAP_Controller.retrieveClientSAP(acc.Client_ID__c);
        //system.assert(response2.contains('"Status":"success"'),'Response is not success');
        //system.assert(response2.contains('"serviceCode":"200"'), 'serviceCode different than 200');
        */
		F3_SendDataToSAP_Controller.getAccountFrom(acc.Name);
	}

	@isTest
	public static void testGetPortafolio() {
		F3_Integration_Service__mdt testMetadata = createMetadataGetPortfolio();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
		String response = F3_SendDataToSAP_Handler.getPortfolio('012345678', '2535');
		//verify service response
		System.debug('###Response: ' + response);
		system.assert(response.contains('"serviceCode":"200"'), 'serviceCode different than 200');

		String response2 = F3_SendDataToSAP_Controller.getContractPortfolio('012345678', '2535');
		system.assert(response2.contains('"serviceCode":"200"'), 'serviceCode different than 200');
		System.debug('###response2: ' + response2);
	}

	@isTest
	public static void testVistaContrato() {
		F3_Integration_Service__mdt testMetadata = createMetadataVistaContrato();
		F3_Integration_Service_Settings__c testSettings = new F3_Integration_Service_Settings__c(
			F3_URL__c = 'testService.com',
			F3_Enable_Log__c = true,
			F3_Service_Type__c = 'ApexRest'
		);
		Integration_Service.testSettings = new Map<String, Object>{ 'serviceMetadata' => testMetadata, 'serviceSettings' => testSettings };
		String response = F3_SendDataToSAP_Handler.getContractList('2023-03-01', '2023-03-15', UserInfo.getUserId());
		//verify service response
		System.debug('###Response: ' + response);
		system.assert(response.contains('"serviceCode":"200"'), 'serviceCode different than 200');

		String response2 = F3_SendDataToSAP_Controller.getExecutiveContracts(Date.today().addDays(-30), Date.today(), UserInfo.getUserId());
		system.assert(response2.contains('"serviceCode":"200"'), 'serviceCode different than 200');
		System.debug('###response2: ' + response2);
	}

	//Methods to create metadata
	private static F3_Integration_Service__mdt createMetadataSendLeads() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'crearClienteContrato';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'crearClienteContrato';
		return serviceMetadata;
	}

	private static F3_Integration_Service__mdt createMetadataSendOpps() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'crearActualizarContrato';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'crearActualizarContrato';
		return serviceMetadata;
	}

	private static F3_Integration_Service__mdt createMetadataGetAccount() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c =
			'{"clientes": [{"NUM_CLIENTE_PK": "12560764",' +
			+'"PROSPECTOID": "CRMPR-00000580",' +
			+'"NOMBRE": "Fer","APELLIDO_PATERNO": "Rojas",' +
			+'"APELLIDO_MATERNO": "Ejemplo","GENERO": "Ejemplo",' +
			+'"CIUDAD_NACIMIENTO": "Ejemplo","CURP": "Ejemplo",' +
			+'"NACIONALIDAD": "Ejemplo","FECHA_NACIMIENTO": "01/01/2000",' +
			+'"FECHA_ALTA": "01/01/2022","RFC": "Ejemplo","RAZON_SOCIAL": "Ejemplo",' +
			+'"TIPO_PERSONA": "Ejemplo","CLASIFICACION_PERSONA": "Ejemplo",' +
			+'"ESTADO_CIVIL": "Ejemplo","ACTIVIDAD_ECONOMICA": "Ejemplo",' +
			+'"PAIS_NACIMIENTO": "Ejemplo","ES_EMPLEADO": true,"TIPO_CLIENTE_SERVICIO": "Ejemplo",' +
			+'"SUB_TIPO_CLIENTE_SERVICIO": "Ejemplo","PERFIL_INVERSION": "Ejemplo","OCUPACION": "Ejemplo"}]}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'solicitarCliente';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'solicitarCliente';
		return serviceMetadata;
	}

	private static F3_Integration_Service__mdt createMetadataCrearActualizarCliente() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'crearActualizarCliente';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'solicitarCliente';
		return serviceMetadata;
	}

	private static F3_Integration_Service__mdt createMetadataGetPortfolio() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'PortafolioContrato';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'solicitarCliente';
		return serviceMetadata;
	}

	private static F3_Integration_Service__mdt createMetadataVistaContrato() {
		F3_Integration_Service__mdt serviceMetadata = new F3_Integration_Service__mdt();
		serviceMetadata.F3_Mock_Response__c = '{"Status":"success"}';
		serviceMetadata.F3_Retrive_Mock__c = true;
		serviceMetadata.F3_Mock_Status_Code__c = 200;
		serviceMetadata.F3_Query_String_Input_Template__c = '';
		serviceMetadata.F3_Named_Credential__c = null;
		serviceMetadata.F3_Service_Setting__c = 'VistaContrato';
		serviceMetadata.F3_Headers__c = '{"Content-Length":"0"}';
		serviceMetadata.F3_HTTP_Method__c = 'GET';
		serviceMetadata.F3_JSON_Input_Template__c = '{"parameter":"#change#","delete":"#delete#"}';
		serviceMetadata.F3_Authorization_Service__c = 'TestAuth';
		serviceMetadata.F3_Authorization_Class__c = 'F3_AccessToken_Utility';
		serviceMetadata.DeveloperName = 'solicitarCliente';
		return serviceMetadata;
	}
}