/********************************************************************************************************************************
* Develop by	: VASS México
* Author		: Alvarez Oscar
* Project		: Wealth Management
* Description	: Test class for OppotunityTrigger_Helper
*
* Information about changes (versions)
* ===============================================================================================================================
* Version No. Request     Date                Author                      Description
* =========== =========== =================== =========================== =======================================================
* 1.0                     23-Dic-2024       Alvarez Oscar                 Created.
********************************************************************************************************************************/
@IsTest
public class OppotunityTriggerHelper_test {

    @testSetup static void setupMethod() {
        
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
        user.ID_ASESOR__c = '00045';
        user.ProfileId = adminProfileId;
        insert user;
        
        User user2 = new User();
        user2.LastName = 'User2';
        user2.Username = 'User2@user.com.u';
        user2.Email = 'Useruser2@u.com.u';
        user2.EmailEncodingKey = 'ISO-8859-1';
        user2.Alias = 'uAas22';
        user2.IsActive = true;
        user2.TimeZoneSidKey = 'America/Mexico_City';
        user2.LocaleSidKey = 'en_US';
        user2.LanguageLocaleKey = 'es';
        user2.ID_ASESOR__c = '00046';
        user2.ProfileId = adminProfileId;
        user2.NUM_NOMINA__c  = '00046';
        insert user2;
        
        Contact contactWithOutLicense = new Contact();
        contactWithOutLicense.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
        contactWithOutLicense.FirstName = 'TestName';
        contactWithOutLicense.LastName = 'TestApp';
        contactWithOutLicense.EmpleadoSinLicenciaSFDC__c = true;
        contactWithOutLicense.NumeroNomina__c = '00046';
        insert contactWithOutLicense;
        
        Contact contactWithOutLicense2 = new Contact();
        contactWithOutLicense2.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BanqueroLlicencia').getRecordTypeId();
        contactWithOutLicense2.FirstName = 'TestName';
        contactWithOutLicense2.LastName = 'TestApp';
        contactWithOutLicense2.EmpleadoSinLicenciaSFDC__c = true;
        contactWithOutLicense2.NumeroNomina__c = '000200';
        insert contactWithOutLicense2;
        
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        
        BranchUnit branchUnit2 = new BranchUnit();
        branchUnit2.Name = 'TestBranchUnit2';
        branchUnit2.IsActive = true;
        branchUnit2.BranchCode = '10000012346';
        branchUnit2.ExternalIdBI__c = '38';
        branchUnit2.ExternalId__c = '10000012346';        
        insert branchUnit2;
        
        BranchUnit branchUnit3 = new BranchUnit();
        branchUnit3.Name = 'Test Branch Unit3';
        branchUnit3.IsActive = true;
        branchUnit3.BranchCode = '10000012347';
        branchUnit3.ExternalIdBI__c = '39';
        branchUnit3.ExternalId__c = '10000012347';        
        insert branchUnit3;
        
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact';
        bankerContact.JobCode = '00045';
        bankerContact.ExternalId__c = '00045';
        bankerContact.CurrentBranchId = branchUnit.Id;
        bankerContact.UserOrContactId = contactWithOutLicense2.Id;
        insert bankerContact;
        
        Banker bankerContact2 = new Banker();
        bankerContact2.Name = 'TestBankerContact2';
        bankerContact2.JobCode = '00046';
        bankerContact2.ExternalId__c = '00046';
        bankerContact2.CurrentBranchId = branchUnit2.Id;
        bankerContact2.UserOrContactId = user2.Id;
        insert bankerContact2;
        
		Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(); 
		Id recordTypeIdWM = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Wealth_Management').getRecordTypeId(); 
        Account objAccountPrimary = new Account();
            objAccountPrimary.FirstName            = 'Test Class';
            objAccountPrimary.LastName             = 'test';
            objAccountPrimary.PersonEmail          = 'test@yopmail.com';
            objAccountPrimary.PersonMobilePhone    = '+52123456789';
            objAccountPrimary.ClienteCreadoDeProspecto__c = true;
            objAccountPrimary.RecordTypeId 		   = recordTypeId;
        	objAccountPrimary.OwnerId = user2.Id;
        insert objAccountPrimary;
		
        Opportunity objOpportunity = new Opportunity();
            objOpportunity.Name 	 = 'OnboardingTestClass';
            objOpportunity.AccountId = objAccountPrimary.Id;
            objOpportunity.CloseDate = System.today();
            objOpportunity.StageName = 'Contactado';
            objOpportunity.OportunidadCreadaDeUnProspecto__c = false;
            objOpportunity.F3_isCreatedInSAP__c = false;
            objOpportunity.RecordTypeId = recordTypeIdWM;
        	objOpportunity.OwnerId = user2.Id;
        	objOpportunity.RecordTypeId = recordTypeIdWM;
        System.debug('User Id:  ' + user2.Id);
        insert objOpportunity;
        
    }
    @isTest static void testExecuteMissingField() {
        ACTINVER_UtilityFactory_utils.WrapperValueFieldSet[] lstValueFieldSet = ACTINVER_UtilityFactory_utils.getValueFieldSet('MandatoryFieldsToIntegrateSAP', 'Opportunity');
        User testUser = [SELECT Id, FirstName, LastName, Username,NUM_NOMINA__c FROM User WHERE Username = 'User2@user.com.u'];
        Opportunity objOpportunity = [SELECT Id,Name,Owner.Id,Owner.NUM_NOMINA__c,RecordTypeId,StageName
                                      FROM Opportunity
                                      WHERE Name = 'OnboardingTestClass' 
                                      LIMIT 1];
        objOpportunity.StageName = 'Propuesta de inversión';
        objOpportunity.Unidad_de_Negocio__c = '2';
        objOpportunity.Productos_ofertados__c = '09';
        objOpportunity.OwnerId = testUser.Id;
        System.debug( '@@@ OPortunidad: - '+ objOpportunity);
        
        try{
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + testUser.NUM_NOMINA__c);
            List<String> opportunityListIds = new List<String> { objOpportunity.Id };
           
            List<Opportunity> opportunityList = [SELECT Id,Name,Owner.Id,Owner.NUM_NOMINA__c,RecordTypeId,StageName
                                      FROM Opportunity
                                      WHERE Name = 'OnboardingTestClass' 
                                      LIMIT 1];
            Map<Id, Opportunity> opportunityOldMap = new Map<Id, Opportunity>();
            sObject sObjOpportunity = (sObject) objOpportunity;
            Map<String, Object> mapDataSObjectOpportunity = sObjOpportunity.getPopulatedFieldsAsMap();
			for (Opportunity opp : opportunityList) {
                opp.StageName = 'Contactado';
    			opportunityOldMap.put(opp.Id, opp);
			}
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Name,OwnerId FROM Opportunity WHERE Id =: objOpportunity.Id]);
            System.debug('MAPA VIEJO ' + opportunityOldMap);
            System.debug('LISTA NUEVO ' + opportunityList);
            
            
            OppotunityTrigger_Helper.validateMandatoryFieldsIntegrateSAP(objOpportunity,mapDataSObjectOpportunity,lstValueFieldSet);
            //OppotunityTrigger_Helper.calloutSAPByContractBP(opportunityListIds);
            OppotunityTrigger_Helper.updateOpportunitySuccess(opportunityListIds);
            OppotunityTrigger_Helper.updateOpportunityError(opportunityListIds,'error');
            OppotunityTrigger_Helper.integrationWithSAP(opportunityList,opportunityOldMap);
            opportunityList.add(objOpportunity);
            OppotunityTrigger_Helper.branchUnitAssignment(opportunityList,opportunityMap);
            OppotunityTrigger_Helper.branchUnitAssignment(opportunityList);
            
            update objOpportunity;
            
        }catch(dmlException e){
            system.debug('Error controlado por campos mandatorios: '+e); 
        }
        
    }
}