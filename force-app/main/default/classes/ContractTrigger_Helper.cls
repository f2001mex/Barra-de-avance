/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     ContractTrigger_Helper
 * @Author   luis.felipe.ortiz@pwc.com
 * @Date     Created: 03/11/2021
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the contract trigger
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 03/11/2021 luis.felipe.ortiz@pwc.com
 *             Class creation.
 * 
 * 24/10/2023 ivan.mora@pwc.com
 * 				Add conditions to populate field: Lead.Monto_Minimo_Requerido__c
 *   ------------------------------------------------------------------------------------------------
 **/
public without sharing class ContractTrigger_Helper {
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final Map<string, string> that contains a list with the active users
	 * ------------------------------------------------------------------------------------------------**/
	private static final Map<string, string> USER_LIST;
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the name of the default owner
	 **/
	private static final String DEFAULT_USER_NAME = 'IntegrationUser';
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final List<String> that contains the accepted types to calculate the consolidated balance
	 **/
	private static final List<String> CB_CONTRACT_TYPES = new List<String>{ '01', '02', '03', '08', '09' };
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static User that contains default owner
	 * ------------------------------------------------------------------------------------------------**/
	private static User defaultOwner;

	private static F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_ContractTrigger);
	/** ------------------------------------------------------------------------------------------------
	 * Static initialization block for USER_LIST
	 * ------------------------------------------------------------------------------------------------**/
	static {
		USER_LIST = fillUserMap();
	}
	/** ------------------------------------------------------------------------------------------------
	 * Class as a Singleton. Prevents instantiation
	 * ------------------------------------------------------------------------------------------------**/
	@TestVisible
	private ContractTrigger_Helper() {
	}
	
	/** ------------------------------------------------------------------------------------------------
	 * @Description: Static final String that contains the minimun deposit amount
	 **/
	//New Line IMH
	private static final Decimal MINIMUM_DEPOSIT_AMOUNT = Decimal.valueOf(System.label.F4_Minimum_Deposit_Amount);
	
	/** -----------------------------------------------------------------------------
	 * @Description change the owner of the contract based on the field "ID_ASESOR__c"
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param    list<Contract> contractNew
	 * @return   void
	 * @example  ContractTrigger_Helper.changeOwner(contractNew)
	 **/
	public static void changeOwner(Contract newContract, Contract oldContract) {
		if (
			oldContract == null ||
			(triggerMetadata.F3_Run_For_All_Changes__c == true ||
			newContract.ID_ASESOR__c != oldContract.ID_ASESOR__c)
		) {
			newContract.OwnerId = USER_LIST.get(newContract.ID_ASESOR__c) != null
				? USER_LIST.get(newContract.ID_ASESOR__c)
				: defaultOwner.Id;
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description change the owner of the contract based on the field "ID_ASESOR__c"
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param    list<Contract> contractNew
	 * @return   void
	 * @example  ContractTrigger_Helper.changeOwner(contractNew)
	 **/
	public static void setContractBalances(Contract newContract, Contract oldContract) {
		if (oldContract != null && newContract.Saldo_contrato__c != newContract.F3_Posicion_dia_anterior__c) {
			newContract.F3_Posicion_dia_anterior__c = oldContract.Saldo_contrato__c;
		}
		if (
			newContract.F3_Posicion_Maxima_Historica__c == null ||
			newContract.Saldo_contrato__c > newContract.F3_Posicion_Maxima_Historica__c
		) {
			newContract.F3_Posicion_Maxima_Historica__c = newContract.Saldo_contrato__c;
		}
	}

	/** -----------------------------------------------------------------------------
	 * @Description orchestrator to update related objects (account, lead)
	 *--------------------------------------------------------------------------------
	 * @author   luis.felipe.ortiz@pwc.com
	 * @date     03/11/2021
	 * @param    list<Contract> contractNew
	 * @param    Map<id, Contract> contractOldMap
	 * @return   void
	 * @example  ContractTrigger_Helper.updateRelatedObjects(contractNew, contractOldMap)
	 **/
	public static void updateRelatedObjects(list<Contract> contractNew, Map<id, Contract> contractOldMap) {
		Set<Id> accountsToProcess = new Set<Id>();
		List<Lead> leadsToProcess = new List<Lead>();
		List<Opportunity> oppsToProcess = new List<Opportunity>();
		if (contractOldMap == null) {
			for (Contract newContract : contractNew) {
				accountsToProcess.add(newContract.AccountId);
				if (newContract.F3_prospecto_origen__c != null) {
					Double saldo = newContract.Saldo__c == null ? 0 : Double.valueOf(newContract.Saldo__c);
					
					Boolean depositReceived =
						newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c != null &&
						newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c > 0;
					Boolean minimunDeposit = 
						newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c > MINIMUM_DEPOSIT_AMOUNT || saldo > MINIMUM_DEPOSIT_AMOUNT;

					leadsToProcess.add(
						new Lead(
							Id = newContract.F3_prospecto_origen__c,
							CHR_GoogleAds_Fecha_Primer_Deposito__c = newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c,
							CHR_Monto_primer_deposito_global__c = newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c,
							F3_Primer_Deposito_Recibido__c = depositReceived,
							Monto_Minimo_Requerido__c = minimunDeposit
						)
					);
				}
				if (newContract.F3_Source_Opportunity__c != null) {
					Boolean depositReceived =
						newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c != null &&
						newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c > 0;
					oppsToProcess.add(
						new Opportunity(
							Id = newContract.F3_Source_Opportunity__c,
							CHR_GoogleAds_Fecha_Primer_Deposito__c = newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c,
							CHR_Monto_primer_deposito_global__c = newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c,
							F3_Primer_Deposito_Recibido__c = depositReceived
						)
					);
				}
			}
		} else {
			for (Contract newContract : contractNew) {
				if (
					triggerMetadata.F3_Run_For_All_Changes__c == true ||
					((newContract.OwnerId != contractOldMap.get(newContract.id).OwnerId) ||
					(newContract.Saldo__c != contractOldMap.get(newContract.id).Saldo__c) ||
					(newContract.Status__c != contractOldMap.get(newContract.id).Status__c) ||
					(newContract.TypeOfContract__c != contractOldMap.get(newContract.id).TypeOfContract__c) ||
					(newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c != contractOldMap.get(newContract.id).CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c) ||
					(newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c != contractOldMap.get(newContract.id).CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c))
				)
				{
					accountsToProcess.add(newContract.AccountId);
					Double saldo = newContract.Saldo__c == null ? 0 : Double.valueOf(newContract.Saldo__c);
					Boolean depositReceived =
						newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c != null &&
						newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c > 0;
					Boolean minimunDeposit = 
						newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c > MINIMUM_DEPOSIT_AMOUNT || saldo > MINIMUM_DEPOSIT_AMOUNT;
					
					if (newContract.F3_prospecto_origen__c != null) {
						leadsToProcess.add(
							new Lead(
								Id = newContract.F3_prospecto_origen__c,
								CHR_GoogleAds_Fecha_Primer_Deposito__c = newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c,
								CHR_Monto_primer_deposito_global__c = newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c,
								F3_Primer_Deposito_Recibido__c = depositReceived,
								Monto_Minimo_Requerido__c = minimunDeposit
							)
						);
					}
					if (newContract.F3_Source_Opportunity__c != null) {
						oppsToProcess.add(
							new Opportunity(
								Id = newContract.F3_Source_Opportunity__c,
								CHR_GoogleAds_Fecha_Primer_Deposito__c = newContract.CHR_GoogleAds_FECHA_PRIMER_DEPOSITO__c,
								CHR_Monto_primer_deposito_global__c = newContract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c,
								F3_Primer_Deposito_Recibido__c = depositReceived
							)
						);
					}
				}
			}
		}

		updateAccount(accountsToProcess);
		if (!leadsToProcess.isEmpty()) {
			update leadsToProcess;
		}
		if (!oppsToProcess.isEmpty()) {
			update oppsToProcess;
		}
	}

	/** -----------------------------------------------------------------------------
    * @Description change the owner of the account based on the summary of "SALDOS" in 
                   contracts per executive
    *--------------------------------------------------------------------------------
    * @author   luis.felipe.ortiz@pwc.com
    * @date     03/11/2021
    * @param    list<Contract> contractNew
    * @return   void
    * @example  ContractTrigger_Helper.changeOwner(contractNew)
    **/
	private static void updateAccount(Set<Id> accountsToProcess) {
		if (!accountsToProcess.isEmpty()) {
			List<Account> accountsToUpdate = addNewValuesToAccount(getContractsPerAccount(accountsToProcess));
			if (!accountsToUpdate.isEmpty()) {
				update accountsToUpdate;
			}
		}
	}

	/** ------------------------------------------------------------------------------------------------
    * @Description validate if the ID_ASESOR__c value exists on the users of the org and put it as the 
                   owner, if not, it assigns the default owner.
    *   ------------------------------------------------------------------------------------------------
    * @author   luis.felipe.ortiz@pwc.com
    * @date     03/11/2021
    * @param    Contract newContract
    * @return   void
    * @example  assignOwner(newContract)
    * ------------------------------------------------------------------------------------------------**/
	private static Map<Account, List<Contract>> getContractsPerAccount(Set<Id> accountsToProcess) {
		List<Account> accountWithContracts = [
			SELECT
				Id,
				F3_Tipo_de_Contrato__c,
				OwnerId,
				(SELECT Saldo__c, CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c, TypeOfContract__c, OwnerId, Owner.isActive FROM Contracts)
			FROM Account
			WHERE Id IN :accountsToProcess
		];
		Map<Account, List<Contract>> contractsPerAccount = new Map<Account, List<Contract>>();
		for (Account processedAccount : accountWithContracts) {
			contractsPerAccount.put(processedAccount, processedAccount.Contracts);
		}
		return contractsPerAccount;
	}

	/** ------------------------------------------------------------------------------------------------
    * @Description validate if the ID_ASESOR__c value exists on the users of the org and put it as the 
                   owner, if not, it assigns the default owner.
    *   ------------------------------------------------------------------------------------------------
    * @author   luis.felipe.ortiz@pwc.com
    * @date     03/11/2021
    * @param    Contract newContract
    * @return   void
    * @example  assignOwner(newContract)
    * ------------------------------------------------------------------------------------------------**/
	private static List<Account> addNewValuesToAccount(Map<Account, List<Contract>> contractsPerAccount) {
		List<Account> accountsToUpdate = new List<Account>();
		List<Lead> leadsToUpdate = new List<Lead>();
		for (Account processedAccount : contractsPerAccount.keySet()) {
			List<ExecutiveWrapper> executivesSummaryWrapper = new List<ExecutiveWrapper>();
			String highestSumExecutive = null;
			Map<String, Object> contractValues = getContractValues(contractsPerAccount.get(processedAccount));
			executivesSummaryWrapper = ((Map<Id, ExecutiveWrapper>) contractValues.get('executivesSummary')).values();
			executivesSummaryWrapper.sort();
			for (ExecutiveWrapper executive : executivesSummaryWrapper) {
				if (executive.executiveId == defaultOwner.id) {
					continue;
				}
				highestSumExecutive = executive.executiveId;
				break;
			}
			accountsToUpdate.add(
				new Account(
					Id = processedAccount.Id,
					OwnerId = highestSumExecutive == null ? defaultOwner.id : highestSumExecutive,
					Mas_de_un_asesor__c = (Boolean) contractValues.get('moreThanOneExecutive'),
					F3_Posicion_Global__c = (Double) contractValues.get('amountGrandTotal'),
					F3_Tipo_de_Contrato__c = (String) contractValues.get('contractTypes'),
					Saldo_Consolidado__c = (Double) contractValues.get('consolidatedBalance'),
					CHR_Monto_primer_deposito_global__c = (Decimal) contractValues.get('consolidatedFirstDeposit')
				)
			);
		}
		return accountsToUpdate;
	}

	private static Map<String, Object> getContractValues(List<Contract> contractsToProcess) {
		Double amountGrandTotal = 0;
		Map<Id, ExecutiveWrapper> executivesSummary = new Map<Id, ExecutiveWrapper>();
		Double consolidatedBalance = 0;
		Decimal consolidatedFirstDeposit = 0;
		Set<Id> contractOwners = new Set<Id>();
		Set<String> contractTypes = new Set<String>();
		for (Contract contract : contractsToProcess) {
			Double balance = contract.Saldo__c == null ? 0 : Double.valueOf(contract.Saldo__c);
			Double firstDeposit = contract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c == null
				? 0
				: contract.CHR_GoogleAds_MONTO_PRIMER_DEPOSITO__c;
			amountGrandTotal = amountGrandTotal + balance;
			consolidatedBalance = CB_CONTRACT_TYPES.contains(contract.TypeOfContract__c)
				? consolidatedBalance + balance
				: consolidatedBalance;
			consolidatedFirstDeposit = consolidatedFirstDeposit + firstDeposit;
			contractTypes.add(contract.TypeOfContract__c);
			if (contract.Owner.IsActive == true) {
				contractOwners.add(contract.OwnerId);
				executivesSummary.put(
					contract.OwnerId,
					executivesSummary.get(contract.OwnerId) == null
						? new ExecutiveWrapper(contract.OwnerId, balance)
						: new ExecutiveWrapper(contract.OwnerId, balance + executivesSummary.get(contract.OwnerId).balanceSummary)
				);
			}
		}
		contractTypes.remove(null);
		contractOwners.remove(null);
		return new Map<String, Object>{
			'amountGrandTotal' => amountGrandTotal,
			'executivesSummary' => executivesSummary,
			'consolidatedBalance' => consolidatedBalance,
			'moreThanOneExecutive' => contractOwners.size() == 1 ? false : true,
			'contractTypes' => String.join(new List<String>(contractTypes), ';'),
			'consolidatedFirstDeposit' => consolidatedFirstDeposit
		};
	}

    public static void UpdateAccountStatus(List<Contract> contracts, Map<id, Contract> contractOldMap){
        system.debug('contracts: ' + contracts);
        system.debug('contractOldMap: ' + contractOldMap);
        set<Id> accIds = new set<Id>();
        for(Contract c : contracts){
            if(contractOldMap == null || c.Status != contractOldMap.get(c.Id).Status){
                accIds.add(c.AccountId);
            }
        }
        if(!accIds.isEmpty()){
            List<Account> accs = [Select Id, FinServ__Status__c, (Select Id, Status from Contracts order by CreatedDate) from Account where Id in: AccIds];
            Map<string, integer> priority = new Map<string, integer>();
            priority.put('Cancelado', 1);
            priority.put('Cerrado', 2);
            priority.put('Bloqueado', 3);
            priority.put('Registrado Bursanet', 4);
            priority.put('En proceso de validación', 5);
            priority.put('Nuevo', 6);
            priority.put('Aprobado', 7);
            
            for(Account acc : accs){
                integer currentPriority = 0;
                acc.FinServ__Status__c = 'Inactive';
                if(!acc.Contracts.isEmpty()){
                    for(Contract c : acc.Contracts){
                        if(c.Status == 'Cancelado'){
                            if(currentPriority < priority.get('Cancelado')){
                                acc.FinServ__Status__c = 'Inactive';
                                currentPriority = priority.get('Cancelado');
                            }
	                    }
                        if(c.Status == 'Cerrado'){
                            if(currentPriority < priority.get('Cerrado')){
                                acc.FinServ__Status__c = 'Closed';
                                currentPriority = priority.get('Cerrado');
                            }
	                    }
                        if(c.Status == 'Bloqueado'){
                            if(currentPriority < priority.get('Bloqueado')){
                                acc.FinServ__Status__c = 'Blocked';
                                currentPriority = priority.get('Bloqueado');
                            }
	                    }
                        if(c.Status == 'Registrado Bursanet'){
                            if(currentPriority < priority.get('Registrado Bursanet')){
                                acc.FinServ__Status__c = 'Prospect';
                                currentPriority = priority.get('Registrado Bursanet');
                            }
	                    }
                        if(c.Status == 'En proceso de validación'){
                            if(currentPriority < priority.get('En proceso de validación')){
                                acc.FinServ__Status__c = 'Prospect';
                                currentPriority = priority.get('En proceso de validación');
                            }
	                    }
                        if(c.Status == 'Nuevo'){
                            if(currentPriority < priority.get('Nuevo')){
                                acc.FinServ__Status__c = 'Active';
                                currentPriority = priority.get('Nuevo');
                            }
	                    }
                        if(c.Status == 'Aprobado'){
                            if(currentPriority < priority.get('Aprobado')){
                                acc.FinServ__Status__c = 'Active';
                                currentPriority = priority.get('Aprobado');
                            }
	                    }
	                }
                }
            }
            update accs;
        }
    }
    
	/** ------------------------------------------------------------------------------------------------
    * @Description retrieves the active users on the org and puts them on a map that 
                   allows .get() based on the ID_ASESOR__c custom field and populate
                   the default owner static variable
    *   ------------------------------------------------------------------------------------------------
    * @author   luis.felipe.ortiz@pwc.com
    * @date     03/11/2021
    * @param    
    * @return   Map<string, string>
    * @example  fillUserMap()
    * ------------------------------------------------------------------------------------------------**/
	private static Map<string, string> fillUserMap() {
		Map<string, string> userList = new Map<string, string>();
		final List<User> users = [
			SELECT Id, ID_ASESOR__c, Name
			FROM user
			WHERE IsActive = TRUE AND (ID_ASESOR__c != NULL OR Name = :DEFAULT_USER_NAME)
		];
		for (User selectedUser : users) {
			userList.put(selectedUser.ID_ASESOR__c, selectedUser.id);
			if (selectedUser.Name == DEFAULT_USER_NAME) {
				defaultOwner = selectedUser;
			}
		}
		return userList;
	}

	public class ExecutiveWrapper implements Comparable {
		public Id executiveId;
		public Double balanceSummary;
		public ExecutiveWrapper(Id executiveId, Double balanceSummary) {
			this.executiveId = executiveId;
			this.balanceSummary = balanceSummary;
		}
		public Integer compareTo(Object compareTo) {
			ExecutiveWrapper compareToEmp = (ExecutiveWrapper) compareTo;
			if (balanceSummary == compareToEmp.balanceSummary) {
				return 0;
			}
			if (balanceSummary > compareToEmp.balanceSummary) {
				return -1;
			}
			return 1;
		}
	}
}