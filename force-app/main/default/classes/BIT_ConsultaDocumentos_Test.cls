/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 14-02-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : Clase test para BIT_ConsultaDocumentos_ctr
**/
@isTest
public class BIT_ConsultaDocumentos_Test {
	@TestSetup
	static void makeData() {
         String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        User user = new User();
        user.LastName = 'User1';
        user.Username = 'User1@user.com.u';
        user.Email = 'Useruser@u.com.u';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas2';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '1234';
        user.ProfileId = adminProfileId;
        insert user;
        
		BranchUnit branchUnit = new BranchUnit();
		branchUnit.ExternalId__c = '001';
		branchUnit.ExternalIdBI__c ='1';
		branchUnit.Name = 'CF 001';
		insert branchUnit;
		Banker banker = new Banker();
		banker.Name = 'test';
		banker.CurrentBranchId = branchUnit.Id;
		banker.UserOrContactId = user.Id;
		banker.Disponible__c = true;
		banker.ExternalId__c = '1234';
		banker.JobCode = '1234';
		insert banker;
		BranchUnitBusinessMember businessMember =[SELECT Id,BranchUnit.ExternalId__c,Name,ExternalIdBI__c FROM BranchUnitBusinessMember WHERE BranchUnit.ExternalId__c =: branchUnit.ExternalId__c];
		businessMember.ExternalId__c = '0011234';
		businessMember.ExternalIdBI__c = '11234';
		update businessMember;
        
        System.runAs(user){
            BIT_UtilityDataTest.createPhones(
                BIT_UtilityDataTest.createContract(
                    BIT_UtilityDataTest.createAccount()
                )
            );
        }
	}
	@IsTest
	static void testGetOTPSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"status": 200}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testOTP = BIT_ConsultaDocumentos_ctr.getOTP('142536', false);
		Assert.isNotNull(testOTP);
		Test.stopTest();
	}
	@IsTest
	static void testGetOTPServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(500, 'Internal Server Error', '{"errorCode": "500"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testOTP = BIT_ConsultaDocumentos_ctr.getOTP('142536', false);
		Assert.isNotNull(testOTP);
		Test.stopTest();
	}
	@IsTest
	static void testGetOTPPhoneError() {
		Telefono_de_Contrato__c phoneRecord = [SELECT Id, Phone__c FROM Telefono_de_Contrato__c LIMIT 1];
		phoneRecord.Phone__c = null;
		update phoneRecord;
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(412, 'Precondition Failed', '{"errorCode": "2001"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testOTP = BIT_ConsultaDocumentos_ctr.getOTP('142536', false);
		Assert.isNotNull(testOTP);
		Test.stopTest();
	}
	@IsTest
	static void testGetOTPExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(412, 'Precondition Failed', '{"errorCode": "2001"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testOTP = BIT_ConsultaDocumentos_ctr.getOTP('Error', false);
		Assert.isNotNull(testOTP);
		Test.stopTest();
	}
	@IsTest
	static void testGetTokenCFSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"status": "200", "accessToken": "stringToken"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testTokenCF = BIT_ConsultaDocumentos_ctr.getTokenCF('142536', 'otpCode');
		System.debug ('tok=>>' + testTokenCF);
		Assert.isNotNull(testTokenCF);
		Test.stopTest();
	}
	@IsTest
	static void testGetTokenCFServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(500, 'Internal Server Error', '{"errorCode": "500"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testTokenCF = BIT_ConsultaDocumentos_ctr.getTokenCF('142536', 'otpCode');
		Assert.isNotNull(testTokenCF);
		Test.stopTest();
	}
	@IsTest
	static void testGetTokenCFExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"dummy": "value"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testTokenCF = BIT_ConsultaDocumentos_ctr.getTokenCF('Error', 'otpCode');
		Assert.isNotNull(testTokenCF);
		Test.stopTest();
	}
	@IsTest
	static void testGetConstanciesSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"payload": {"date": "dummy"}}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.GetConstancies('142536');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testGetConstanciesServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(401, 'Unauthorized', '{"errorCode": "401"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.GetConstancies('142536');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testGetConstanciesExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"dummy": "value"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.GetConstancies('Error');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testSendConstancieSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"status": 200}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
        
        User objUser = [SELECT Id FROM User WHERE ID_ASESOR__c = '1234' LIMIT 1];
        System.runAs(objUser){
            String testConstancies = BIT_ConsultaDocumentos_ctr.SendConstancie('142536', 'period', 'passwordDummy');
            Assert.isNotNull(testConstancies);
            }
		Test.stopTest();
	}
	@IsTest
	static void testSendConstancieServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(404, 'Not Found', '{"status": 404}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.SendConstancie('142536', 'period', 'passwordDummy');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testSendConstancieExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"dummy": value"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.SendConstancie('Error', 'period', 'passwordDummy');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testGetStatementsSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"payload": {"date": [{"month": 6, "year": 2000, "yearExercise": "2020", "type": "typeDummy"}]}}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testConstancies = BIT_ConsultaDocumentos_ctr.GetStatements('142536');
		Assert.isNotNull(testConstancies);
		Test.stopTest();
	}
	@IsTest
	static void testGetStatementsServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(412, 'Precondition Failed', '{"status": 412}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testStatements = BIT_ConsultaDocumentos_ctr.GetStatements('142536');
		Assert.isNotNull(testStatements);
		Test.stopTest();
	}
	@IsTest
	static void testGetStatementsExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"dummy": value"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testStatements = BIT_ConsultaDocumentos_ctr.GetStatements('Error');
		Assert.isNotNull(testStatements);
		Test.stopTest();
	}
	@IsTest
	static void testSendStatementsSuccess() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"status": 200}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
        
        User objUser = [SELECT Id FROM User WHERE ID_ASESOR__c = '1234' LIMIT 1];
        System.runAs(objUser){
			String testStatements = BIT_ConsultaDocumentos_ctr.SendStatements('142536', new List<String>{'2022'}, 'passwordDummy');
        	Assert.isNotNull(testStatements);
            }
		Test.stopTest();
	}
	@IsTest
	static void testSendStatementsServiceError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(400, 'Bad Request', '{"status": 400}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testStatements = BIT_ConsultaDocumentos_ctr.SendStatements('142536', new List<String>(), 'passwordDummy');
		Assert.isNotNull(testStatements);
		Test.stopTest();
	}
	@IsTest
	static void testSendStatementsExecuteError() {
		Test.startTest();
		HTTPMockFactory mock = new HTTPMockFactory(200, 'OK', '{"dummy": value"}', new Map<String, String>());
		Test.setMock(HttpCalloutMock.class, mock);
		String testStatements = BIT_ConsultaDocumentos_ctr.SendStatements('Error', new List<String>(), 'passwordDummy');
		Assert.isNotNull(testStatements);
		Test.stopTest();
	}
	@IsTest
	static void testgetPrincipalPhone() {
		List<Telefono_de_Contrato__c> phoneList = [SELECT Id, principal__c FROM Telefono_de_Contrato__c];
		phoneList[0].principal__c = true;
		update phoneList;
		Test.startTest();
		Telefono_de_Contrato__c testPhone = BIT_ConsultaDocumentos_ctr.getPrincipalPhone(phoneList);
		Assert.isNotNull(testPhone);
		Test.stopTest();
	}
}