/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     UtilitiesDataTest
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 03/11/2021
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Class for utilities like creation of record.
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest(IsParallel=true)
public with sharing class UtilitiesDataTest {
	/**
    * --------------------------------------------------------------------------------------
    * @Description Method that creates a User
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param    Map<Schema.SObjectField, Object> mapFields If any additional data or change 
                in the values of the user is required, pass the field and the value on the map                
    * @return User
    * --------------------------------------------------------------------------------------
    **/
	public static User createUser(Map<Schema.SObjectField, Object> mapFields) {
		final Double random = Math.random();
		final User obj = new User(
			LastName = 'User' + random,
			Username = 'User' + random + '@user.com.u',
			Email = 'User' + random + 'user@u.com.u',
			EmailEncodingKey = 'ISO-8859-1',
			Alias = String.valueOf(random).substring(0, 3) + 'uAas2',
			IsActive = true,
			TimeZoneSidKey = 'America/Mexico_City',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'es',
			ID_ASESOR__c = '0001'
		);
		for (Schema.SObjectField sfield : mapFields.keySet()) {
			obj.put(sfield, mapFields.get(sfield));
		}
		insert obj;
		return obj;
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Method that creates contracts. Each contract has a different value on
                   DESC_CONTRATO__c 
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param    Integer numberOfContracts to create                
    * @return List<Contract>
    * --------------------------------------------------------------------------------------
    **/
	public static List<Contract> createContracts(Integer numberOfContracts, Map<Schema.SObjectField, Object> contractFields) {
		Account newAccount = new Account(LastName = 'Prueba');
		insert newAccount;
		List<Contract> contracts = new List<Contract>();
		for (Integer i = 0; i < numberOfContracts; i++) {
			Contract newContract = new Contract(
				AccountId = newAccount.Id,
				Status = 'En proceso de validación',
				DESC_CONTRATO__c = '000' + i
			);
			if (contractFields != null && !contractFields.isEmpty()) {
				for (Schema.SObjectField sfield : contractFields.keySet()) {
					newContract.put(sfield, contractFields.get(sfield));
				}
			}
			contracts.add(newContract);
		}
		return contracts;
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Method that creates credits. Each contract has a different value on
                   DESC_CREDITO__c and  ID_Credito__c
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param    Integer numberOfContracts to create                
    * @return List<Credito__c>
    * --------------------------------------------------------------------------------------
    **/
	public static List<Credito__c> createCredits(Integer numberOfCredits, Map<Schema.SObjectField, Object> creditFields) {
		Account newAccount = new Account(LastName = 'Prueba');
		insert newAccount;
		List<Credito__c> credits = new List<Credito__c>();
		for (Integer i = 0; i < numberOfCredits; i++) {
			Credito__c newCredit = new Credito__c(
				NUM_CLIENTE__c = newAccount.Id,
				ID_Credito__c = '0000000' + i,
				DESC_CREDITO__c = '000' + i
			);
			if (creditFields != null && !creditFields.isEmpty()) {
				for (Schema.SObjectField sfield : creditFields.keySet()) {
					newCredit.put(sfield, creditFields.get(sfield));
				}
			}
			credits.add(newCredit);
		}
		return credits;
	}

	/**
    * --------------------------------------------------------------------------------------
    * @Description Method that creates accounts with contracts. Each contract has a different value on
                   DESC_CONTRATO__c 
    * --------------------------------------------------------------------------------------
    * @Author   luis.felipe.ortiz@pwc.com
    * @Date     Created: 03/11/2021
    * @param    Integer numberOfAccounts to create                
    * @param    Integer contractsPerAccount to create                
    * @param    String AsesorId                
    * @param    String randomId to create batches with more than one asesor              
    * @return Map<String, List<SObject>
    * --------------------------------------------------------------------------------------
    **/
	public static Map<String, List<SObject>> createAccountContracts(
		Integer numberOfAccounts,
		Integer contractsPerAccount,
		Map<Schema.SObjectField, Object> accountMapFields,
		Map<Schema.SObjectField, Object> contractMapFields
	) {
		List<Account> accounts = new List<Account>();
		List<Contract> contracts = new List<Contract>();
		for (Integer i = 0; i < numberOfAccounts; i++) {
			Account newAccount = new Account(LastName = 'Prueba ' + i);
			if (accountMapFields != null && !accountMapFields.isEmpty()) {
				for (Schema.SObjectField sfield : accountMapFields.keySet()) {
					newAccount.put(sfield, accountMapFields.get(sfield));
				}
			}
			accounts.add(newAccount);
		}
		insert accounts;
		for (Integer i = 0; i < numberOfAccounts; i++) {
			for (Integer j = 0; j < contractsPerAccount; j++) {
				Contract newContract = new Contract(
					AccountId = accounts[i].Id,
					Status = 'En proceso de validación',
					DESC_CONTRATO__c = '000' + j,
					Saldo__c = '0'
				);
				if (contractMapFields != null && !contractMapFields.isEmpty()) {
					for (Schema.SObjectField sfield : contractMapFields.keySet()) {
						newContract.put(sfield, contractMapFields.get(sfield));
					}
				}
				contracts.add(newContract);
			}
		}
		Map<String, List<SObject>> AccountContract = new Map<String, List<SObject>>{ 'Account' => accounts, 'Contract' => contracts };
		return AccountContract;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Method that creates Figuras_Relacionadas__c.
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 18/03/2022
	 * @param    Integer numberOfContracts to create
	 * @param    Integer figurasPerContract to create
	 * @return List<Figuras_Relacionadas__c>
	 * --------------------------------------------------------------------------------------
	 **/
	public static List<Figuras_Relacionadas__c> createFigurasRelacionadas(Integer figurasPerContract, Integer numberOfContracts) {
		Account masterAccount = new Account(LastName = 'Prueba');
		insert masterAccount;
		List<Contract> contracts = new List<Contract>();
		for (Integer i = 0; i < numberOfContracts; i++) {
			Contract newContract = new Contract(
				AccountId = masterAccount.Id,
				Status = 'En proceso de validación',
				DESC_CONTRATO__c = '000' + 1
			);
			contracts.add(newContract);
		}
		insert contracts;
		List<Figuras_Relacionadas__c> figuras = new List<Figuras_Relacionadas__c>();
		for (Integer i = 0; i < contracts.size(); i++) {
			for (Integer j = 0; j < figurasPerContract; j++) {
				Figuras_Relacionadas__c newFigura = new Figuras_Relacionadas__c(
					Num_Contrato__c = contracts[i].Id,
					FullName__c = 'Prueba ' + i
				);
				figuras.add(newFigura);
			}
		}
		return figuras;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Method that creates accounts with opportunities.
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 03/11/2021
	 * @param    Integer numberOfAccounts to create
	 * @param    Integer opportunitiesPerAccount to create
	 * @return Map<String, List<SObject>
	 * --------------------------------------------------------------------------------------
	 **/
	public static Map<String, List<SObject>> createAccountOpportunities(
		Integer numberOfAccounts,
		Integer opportunitiesPerAccount,
		Map<Schema.SObjectField, Object> accountMapFields,
		Map<Schema.SObjectField, Object> oppsMapFields
	) {
		List<Account> accounts = new List<Account>();
		List<Opportunity> opportunities = new List<Opportunity>();
		for (Integer i = 0; i < numberOfAccounts; i++) {
			Account newAccount = new Account(LastName = 'Prueba ' + i, Client_Id__c = '000000' + i);
			if (accountMapFields != null && !accountMapFields.isEmpty()) {
				for (Schema.SObjectField sfield : accountMapFields.keySet()) {
					newAccount.put(sfield, accountMapFields.get(sfield));
				}
			}
			accounts.add(newAccount);
		}
		insert accounts;
		for (Integer i = 0; i < numberOfAccounts; i++) {
			for (Integer j = 0; j < opportunitiesPerAccount; j++) {
				Opportunity newOpportunity = new Opportunity(
					Name = 'Test Opportunity ' + i,
					AccountId = accounts[i].Id,
					StageName = 'En proceso de validación',
					CloseDate = System.today()
				);
				if (oppsMapFields != null && !oppsMapFields.isEmpty()) {
					for (Schema.SObjectField sfield : oppsMapFields.keySet()) {
						newOpportunity.put(sfield, oppsMapFields.get(sfield));
					}
				}
				opportunities.add(newOpportunity);
			}
		}
		Map<String, List<SObject>> AccountOpportunity = new Map<String, List<SObject>>{
			'Account' => accounts,
			'Opportunity' => opportunities
		};
		return AccountOpportunity;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Method that creates leads.
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 03/11/2021
	 * @param    Integer numberOfContracts to create
	 * @return List<Lead>
	 * --------------------------------------------------------------------------------------
	 **/
	public static List<Lead> createLeads(Integer numberOfLeads, Map<Schema.SObjectField, Object> leadMapFields) {
		List<Lead> leads = new List<Lead>();
		Contact newContact = new Contact(FirstName = 'test', LastName = 'Contact ');
		insert newContact;
		for (Integer i = 0; i < numberOfLeads; i++) {
			Lead newLead = new Lead();
			newLead.FirstName = 'Test';
			newLead.LastName = 'Lead ' + i;
			newLead.PostalCode = '30000';
			newLead.Status = 'Asignado';
			newLead.FinServ__ExpressedInterest__c = 'Banca Soluciones';
			newLead.FinServ__ReferredByContact__c = newContact.id;
			if (leadMapFields != null && !leadMapFields.isEmpty()) {
				for (Schema.SObjectField sfield : leadMapFields.keySet()) {
					newLead.put(sfield, leadMapFields.get(sfield));
				}
			}
			leads.add(newLead);
		}
		return leads;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Method that creates branch units.
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 29/11/2022
	 * @param    Integer numberOfBranches to create
	 * @return List<BranchUnit>
	 * --------------------------------------------------------------------------------------
	 **/
	public static List<BranchUnit> createBranches(Integer numberOfBranches, Map<Schema.SObjectField, Object> branchFields) {
		List<BranchUnit> branches = new List<BranchUnit>();
		for (Integer i = 0; i < numberOfBranches; i++) {
			BranchUnit newBranch = new BranchUnit(
				BranchCode = 'PRB_000' + i,
				IsActive = true,
				Name = 'Test Branch ' + i,
				Type = 'Physical'
			);
			if (branchFields != null && !branchFields.isEmpty()) {
				for (Schema.SObjectField sfield : branchFields.keySet()) {
					newBranch.put(sfield, branchFields.get(sfield));
				}
			}
			branches.add(newBranch);
		}
		return branches;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description Method that creates banker units.
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 29/11/2022
	 * @param    Integer numberOfBankers to create
	 * @return List<Banker>
	 * --------------------------------------------------------------------------------------
	 **/
	public static List<Banker> createBankers(Integer numberOfBankers, Map<Schema.SObjectField, Object> bankerFields) {
		List<Banker> bankers = new List<Banker>();
		for (Integer i = 0; i < numberOfBankers; i++) {
			Banker newBanker = new Banker(Name = 'Test Banker ' + i, Disponible__c = true, Level = '1');
			if (bankerFields != null && !bankerFields.isEmpty()) {
				for (Schema.SObjectField sfield : bankerFields.keySet()) {
					newBanker.put(sfield, bankerFields.get(sfield));
				}
			}
			bankers.add(newBanker);
		}
		return bankers;
	}

	/**
	 * --------------------------------------------------------------------------------------
	 * @Description method that generates a random string with the designed length
	 * --------------------------------------------------------------------------------------
	 * @Author   luis.felipe.ortiz@pwc.com
	 * @Date     Created: 18/03/2022
	 * @param    Integer length
	 * @return void
	 * --------------------------------------------------------------------------------------
	 **/
	public static String generateRandomString(Integer length) {
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String randStr = '';
		while (randStr.length() < length) {
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			randStr += chars.substring(idx, idx + 1);
		}
		return randStr;
	}
}