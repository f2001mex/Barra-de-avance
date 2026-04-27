/**
 * @author Tate Shi
 * @date 10/28/2021
 * @description Test Trigger : LeadTrigger and LeadHandler
 */
@isTest
public with sharing class LeadTriggerTest {
	@TestSetup
	static void makeData() {
		List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'Advisor'];
		//insert User
		User testUser1 = new User(
			FirstName = 'testUser',
			LastName = '1',
			UserName = 'tttt1@163.com',
			Email = 'test1@163.com',
			Alias = 't1',
			TimeZoneSidKey = 'America/Mexico_City',
			LocaleSidKey = 'es_MX',
			EmailEncodingKey = 'UTF-8',
			ProfileId = lstProfile[0].Id,
			LanguageLocaleKey = 'es_MX'
		);
		insert testUser1;

		//insert Account : Account.OwnerId lookup(User)
		Account testAccount = new Account(FirstName = 'testAccount', LastName = '1', OwnerId = testUser1.Id);
		insert testAccount;

		//insert Opportunity : OwnerId AccountId lookup(User), AccountId lookup(Account) *OwnerId == AccountId.OwnerId
		Opportunity objOpp1 = new Opportunity(
			Name = 'TestOpp',
			StageName = 'Contacto inicial',
			CloseDate = Date.today(),
			OwnerId = testUser1.Id,
			AccountId = testAccount.Id
		);
		insert objOpp1;
        Profile wealtManagementProfile = [SELECT Id FROM Profile WHERE Name = 'Banquero Wealth Management' LIMIT 1];
		//insert User
		User testUserWM = new User(
			FirstName = 'WealtManagement',
			LastName = 'WealtManagement',
			UserName = 'WealtManagement@WM.com',
			Email = 'WealtManagement@WM.com',
			Alias = 't1',
			TimeZoneSidKey = 'America/Mexico_City',
			LocaleSidKey = 'es_MX',
			EmailEncodingKey = 'UTF-8',
			ProfileId = wealtManagementProfile.Id,
			LanguageLocaleKey = 'es_MX',
            ID_ASESOR__c = '000160371'
		);
        insert testUserWM;
        BranchUnit objBranchUnit = new BranchUnit();
        objBranchUnit.ExternalId__c = '001';
        objBranchUnit.ExternalIdBI__c ='1';
        objBranchUnit.Name = 'CF 001';
        insert objBranchUnit;
        
        Banker objBanker = new Banker();
        objBanker.Name = 'test';
        objBanker.CurrentBranchId = objBranchUnit.Id;
        objBanker.UserOrContactId = testUserWM.Id;
        objBanker.Disponible__c = true;
        objBanker.ExternalId__c = '000160371';
        insert objBanker;
        
        BranchUnitBusinessMember objBUBM =[SELECT Id,BranchUnit.ExternalId__c FROM BranchUnitBusinessMember WHERE BranchUnit.ExternalId__c =: objBranchUnit.ExternalId__c];
        objBUBM.ExternalId__c = '0001000160371';
        update objBUBM;
	}

	//Since the 53 limit is now deprecated (New limit 50,000), we only validate here that the 55 leads assigned in the test are inserted with success
	@isTest
	static void preventAssignedLeadLargerThan53TestHandlerTest() {
		Test.startTest();
		// List<User> lstUser = [SELECT Id, Name FROM User WHERE Name = 'Advisor Shi' OR Name = 'Manager Shi' OR Name = 'testUser 1'];
		List<User> lstUser = [SELECT Id, Name FROM User WHERE Name = 'testUser 1'];
		// User objBankerUser;
		// User objManagerUser;
		User objTestUser1;
		for (User objUser : lstUser) {
			if (objUser.Name == 'testUser 1') {
				objTestUser1 = objUser;
			}
		}

		List<Lead> lstLead = new List<Lead>();
		for (Integer i = 0; i < 55; i++) {
			lstLead.add(
				new Lead(
					Firstname = 'testLead',
					LastName = String.valueOf(i + 1),
					OwnerId = objTestUser1.Id,
					PostalCode = '29002',
					FinServ__ReferredByUser__c = objTestUser1.Id
				)
			);
		}
		// insert lstLead; This will fire the Trigger : LeadTrigger
		Database.SaveResult[] srList = Database.insert(lstLead, false);

		List<Lead> lstLeadResult = [SELECT Id, Name FROM Lead WHERE Id != NULL AND Firstname='testLead' LIMIT 10000];
		Test.stopTest();

		//max 53 Lead - 1 opp = 52
		System.assertEquals(
			55,
			lstLeadResult.size(),
			'As a business request, The limit changed from 53 to 50000, in order to get it back to the original limit, change the The_Max_Manual_Capacity label to 53 '
		);
		// System.assertEquals(false, srList[54].isSuccess());
		// System.assertEquals(false, srList[52].isSuccess());
		// System.assertEquals(true, srList[51].isSuccess());
		// System.assertEquals('You Can\'t have more than 53 Leads or Opportunities', srList[53].getErrors()[0].getMessage());
	}

	@isTest
	static void removeIntegrationUserLimitHandlerTest() {
		Test.startTest();
		// List<User> lstUser = [SELECT Id, Name FROM User WHERE Name = 'Advisor Shi' OR Name = 'Manager Shi' OR Name = 'testUser 1'];

		String strIntegrationUser = 'Integration User';
		if (Label.Integration_User != null) {
			strIntegrationUser = Label.Integration_User;
		}
		List<User> lstUser = [SELECT Id, Name FROM User WHERE Name = :strIntegrationUser];
		User objIntegrationUser;
		for (User objUser : lstUser) {
			if (objUser.Name == strIntegrationUser) {
				objIntegrationUser = objUser;
			}
		}

		List<Lead> lstLead = new List<Lead>();
		for (Integer i = 0; i < 55; i++) {
			lstLead.add(
				new Lead(
					Firstname = 'testLead2',
					LastName = String.valueOf(i + 1),
					OwnerId = objIntegrationUser.Id,
					PostalCode = '29002',
					FinServ__ReferredByUser__c = objIntegrationUser.Id
				)
			);
		}
		// insert lstLead; This will fire the Trigger : LeadTrigger
		Database.SaveResult[] srList = Database.insert(lstLead, false);

		List<Lead> lstLeadResult = [SELECT Id, Name FROM Lead WHERE Id != NULL AND FirstName = 'testLead2' LIMIT 10000];
		Test.stopTest();

		//max 53 Lead - 1 opp = 52
		system.debug(lstLeadResult.size());
		System.assertEquals(55, lstLeadResult.size());
		System.assertEquals(true, srList[54].isSuccess());
		System.assertEquals(true, srList[52].isSuccess());
		System.assertEquals(true, srList[51].isSuccess());
		// System.assertEquals('You Can\'t have more than 53 Leads or Opportunities', srList[53].getErrors()[0].getMessage());
	}

	@isTest
	static void TestConversionDate() {
		List<contact> lstContact = new List<Contact>();
		lstContact.add(new Contact(FirstName = 'test', LastName = 'Contact'));
		insert lstContact;
		Lead newLead = new Lead();
		newLead.FirstName = 'Test';
		newLead.LastName = 'Lead';
		newLead.PostalCode = '30000';
		newLead.Status = 'Asignado';
		newLead.FinServ__ExpressedInterest__c = 'Banca Soluciones';
		newLead.FinServ__ReferredByContact__c = lstContact[0].Id;
		newLead.F3_Consecutivo_ID__c = 'CRMPR-00000002';
		insert newLead;
		Assert.areEqual(null, newLead.CR_Rep_ConversionDate__c);
		newLead.Status = 'Cerrada Ganada';
		update newLead;
		Date conversionDate = [SELECT CR_Rep_ConversionDate__c FROM Lead WHERE Id = :newLead.id LIMIT 1].CR_Rep_ConversionDate__c;
		Assert.areEqual(System.today(), conversionDate);
	}
    @isTest
    static void testUpdateOpportunity() {
        Id recordTypeIdWM = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('WealthManagement').getRecordTypeId(); 
        User testUserWM = [SELECT Id FROM USER WHERE ID_ASESOR__c = '000160371' LIMIT 1];  
                Lead newLead = new Lead();
        System.runAs(testUserWM) {     
                newLead.FirstName = 'Test';
                newLead.LastName = 'Perez';
                newLead.Suffix = 'Mendoza';
                newLead.OportunidadDeProspecto__c = true;
                newLead.LeadSource = 'Referenciado Cliente';
                newLead.F3_Nacionalidad__c = 'MX';
                newLead.Pais_Nacimiento__c = 'MX';
                newLead.F3_CURP__c = 'MOCV780623HDFSRC02';
                newLead.F3_RFC__c = 'MOCV780623';
                newLead.Email = 'josue.per@vasscompany.com';
                newLead.ClienteCreadoDeProspecto__c = true;
                newLead.Status = 'Contactado';
                newLead.Estado_Nacimiento__c = 'CHS';
                newLead.Prioridad__c = 'Baja';
                newLead.MobilePhone = '5544332299';
                newLead.Clasificacion_Persona__c = '4';
                newLead.MontoEstimadoDeInversion__c = 123;
                newLead.FechaEstimadaDeCierre__c = System.today().addDays(1);
                newLead.F3_Estado_Civil__c = '2';
                newLead.Fecha_Nacimiento_Prospecto__c = System.today().addyears(-40);
                newLead.Gender__c = '1';
                newLead.Tipo_de_Persona__c = '1';
                newLead.RecordTypeId = recordTypeIdWM;
                //newLead.OwnerId = testUserWM.Id;
                newLead.F3_Consecutivo_ID__c = 'CRMPR-00000099';
                insert newLead;
        }
        //Lead updateLead = [SELECT Id, F3_Consecutivo_ID__c FROM Lead WHERE F3_Consecutivo_ID__c = 'CRMPR-00000099' LIMIT 1];
        //System.debug('########### updateLead'+newLead);
		Test.startTest();
        try{
        	LeadTrigger_Helper.updateOpportunity(newLead);
        }catch(Exception ex){
            System.debug('Error controlado en test: ' +ex);
            System.debug('Error inesperado: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
 
        }
        Test.stopTest();
    }
	@isTest
    static void testUpdateLead() {
        Id recordTypeIdWM = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('WealthManagement').getRecordTypeId(); 
        User testUserWM = [SELECT Id FROM USER WHERE ID_ASESOR__c = '000160371' LIMIT 1];
                Lead newLead = new Lead();
        System.runAs(testUserWM) {       
                newLead.FirstName = 'Test';
                newLead.LastName = 'Perez';
                newLead.Suffix = 'Mendoza';
                newLead.OportunidadDeProspecto__c = true;
                newLead.LeadSource = 'Referenciado Cliente';
                newLead.F3_Nacionalidad__c = 'MX';
                newLead.Pais_Nacimiento__c = 'MX';
                newLead.F3_CURP__c = 'MOCV780623HDFSRC02';
                newLead.F3_RFC__c = 'MOCV780623';
                newLead.Email = 'josue.per@vasscompany.com';
                newLead.ClienteCreadoDeProspecto__c = true;
                newLead.Status = 'Contactado';
                newLead.Estado_Nacimiento__c = 'CHS';
                newLead.Prioridad__c = 'Baja';
                newLead.MobilePhone = '5544332299';
                newLead.Clasificacion_Persona__c = '4';
                newLead.MontoEstimadoDeInversion__c = 123;
                newLead.FechaEstimadaDeCierre__c = System.today().addDays(1);
                newLead.F3_Estado_Civil__c = '2';
                newLead.Fecha_Nacimiento_Prospecto__c = System.today().addyears(-40);
                newLead.Gender__c = '1';
                newLead.Tipo_de_Persona__c = '1';
                newLead.RecordTypeId = recordTypeIdWM;
                //newLead.OwnerId = testUserWM.Id;
                newLead.F3_Consecutivo_ID__c = 'CRMPR-00000099';
                insert newLead;
        }
        //Lead updateLead = [SELECT Id, F3_Consecutivo_ID__c FROM Lead WHERE F3_Consecutivo_ID__c = 'CRMPR-00000099' LIMIT 1];
        //System.debug('########### updateLead'+updateLead);
        String[] leadIds = new List<String>{newLead.Id};
		Test.startTest();
        try{
        	LeadTrigger_Helper.updateLead(leadIds);
        }catch(Exception ex){
            System.debug('Error controlado en test: ' +ex);
            System.debug('Error inesperado: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
 
        }
        Test.stopTest();
    }
    
	@isTest
    static void testGetAccountByLead() {
		Test.startTest();
        try{
        	LeadTrigger_Helper.getAccountByLead(new List<String>());
        }catch(Exception ex){
            System.debug('Error controlado en test: ' +ex);
            System.debug('Error inesperado: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
 
        }
        Test.stopTest();

    }
    
	@isTest
    static void testGetOpportunityByAccount() {
		Test.startTest();
        try{
        	LeadTrigger_Helper.getOpportunityByAccount('');
        }catch(Exception ex){
            System.debug('Error controlado en test: ' +ex);
            System.debug('Error inesperado: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());

        }
        Test.stopTest();

    }
    
	@isTest
    static void testInsertLeadWM() {
        Id recordTypeIdWM = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('WealthManagement').getRecordTypeId(); 
        User testUserWM = [SELECT Id FROM USER WHERE ID_ASESOR__c = '000160371' LIMIT 1];
        System.runAs(testUserWM) {       
                Lead newLead = new Lead();
                newLead.FirstName = 'Test';
                newLead.LastName = 'Perez';
                newLead.Suffix = 'Mendoza';
                newLead.OportunidadDeProspecto__c = true;
                newLead.LeadSource = 'Referenciado Cliente';
                newLead.F3_Nacionalidad__c = 'MX';
                newLead.Pais_Nacimiento__c = 'MX';
                newLead.F3_CURP__c = 'MOCV780623HDFSRC02';
                newLead.F3_RFC__c = 'MOCV780623';
                newLead.Email = 'josue.per@vasscompany.com';
                newLead.ClienteCreadoDeProspecto__c = true;
                newLead.Status = 'Contactado';
                newLead.Estado_Nacimiento__c = 'CHS';
                newLead.Prioridad__c = 'Baja';
                newLead.MobilePhone = '5544332299';
                newLead.Clasificacion_Persona__c = '4';
                newLead.MontoEstimadoDeInversion__c = 123;
                newLead.FechaEstimadaDeCierre__c = System.today().addDays(1);
                newLead.F3_Estado_Civil__c = '2';
                newLead.Fecha_Nacimiento_Prospecto__c = System.today().addyears(-40);
                newLead.Gender__c = '1';
                newLead.Tipo_de_Persona__c = '1';
                newLead.RecordTypeId = recordTypeIdWM;
                //newLead.OwnerId = testUserWM.Id;
                newLead.F3_Consecutivo_ID__c = 'CRMPR-00000099';
                insert newLead;
        }
    }
}