/**
 * @developed by      : VASS México
 * @author            : erik.romero@vasscompany.com
 * @last modified on  : 03-03-2025
 * @last modified by  : erik.romero@vasscompany.com
 * @description       : Clase test para BIT_ConsultaDocumentos_soql
**/
@isTest
public class BIT_ConsultaDocumentos_soql_Test {
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
	static void testContractQuery() {
		Test.startTest();
		List<Contract> lstTest = BIT_ConsultaDocumentos_soql.getContractInfo('142536');
		Test.stopTest();
		
	}
	@IsTest
	static void testCFQuery() {
		Test.startTest();
        User objUser = [SELECT Id FROM User WHERE ID_ASESOR__c = '1234' LIMIT 1];
        System.runAs(objUser){
            String resultStr = BIT_ConsultaDocumentos_soql.getCFEnvio();
        }
		Test.stopTest();
		
	}
}