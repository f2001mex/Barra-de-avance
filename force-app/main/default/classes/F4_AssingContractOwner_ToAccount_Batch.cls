/**
 *   ------------------------------------------------------------------------------------------------
 * @Name     F4_AssingContractOwner_ToAccount_Batch
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 18/06/2024
 * @Group    PWC
 * ------------------------------------------------------------------------------------------------
 * @Description Class that is used to re-assign accounts owned by Integration User
 * ------------------------------------------------------------------------------------------------
 * @Changes
 * 18/06/2024 ivan.mora@pwc.com
 *             Class creation.
 * ------------------------------------------------------------------------------------------------
 **/
public without sharing class F4_AssingContractOwner_ToAccount_Batch implements Database.Batchable<sObject>{
    String query;
    Set<Id> accountIds;
    Map<String, Object> variablesBind;
    Map<String, Id> userIdMap;
    Set<String> integrationUserNames;
    List<Contract> filteresContracts;
    List<Account> lstAccountsToUpdate;
    List<Account> conversionAccountStatuses;

    public F4_AssingContractOwner_ToAccount_Batch(String query, Map<String, Object> variablesBind) {
        this.query = query;
        this.variablesBind = variablesBind;
        this.accountIds = new Set<Id>();
        this.userIdMap = new Map<String, Id>();
        this.filteresContracts = new List<Contract>();
        this.lstAccountsToUpdate = new List<Account>();
        this.conversionAccountStatuses = new List<Account>();
        this.integrationUserNames = new Set<String>{'IntegrationUser', 'Integration User'};
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocatorWithBinds(query, variablesBind, AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Contract> lstContracts = (List<Contract>) scope;
        if(lstContracts.size() > 0){
            for(Contract cn : lstContracts){
                if(!accountIds.contains(cn.AccountId)){
                    if(integrationUserNames.contains(cn.Owner.Name)){
                        userIdMap.put(cn.ID_ASESOR__c, null);
                        filteresContracts.add(cn);
                    } else {
                        lstAccountsToUpdate.add(new Account(
                            Id = cn.AccountId,
                            OwnerId = cn.OwnerId
                        ));
                    }
                    accountIds.add(cn.AccountId);
                }
            }

            for(User u: [SELECT Id, ID_ASESOR__c FROM User WHERE ID_ASESOR__c IN:userIdMap.keySet()]){
                userIdMap.put(u.ID_ASESOR__c, u.Id);
            }

            for(Contract cn : filteresContracts){
                if(userIdMap.containsKey(cn.ID_ASESOR__c)){
                    cn.OwnerId = userIdMap.get(cn.ID_ASESOR__c);
                    lstAccountsToUpdate.add(new Account(
                        Id = cn.AccountId,
                        OwnerId = userIdMap.get(cn.ID_ASESOR__c)
                    ));
                }
            }

            if(lstAccountsToUpdate.size() > 0){
                Database.SaveResult[] results = Database.update(lstAccountsToUpdate, false);
                for(Database.SaveResult sr : results){
                    if(!sr.isSuccess()){
                        conversionAccountStatuses.add(new Account(
                            Id = sr.getId(),
                            Batch_Conversion_Errors__c = 'Error al actualizar Cliente: ' + sr.getErrors()[0].getMessage()
                        ));
                    } else {
                        conversionAccountStatuses.add(new Account(
                            Id = sr.getId(),
                            Batch_Conversion_Errors__c = 'Success'
                        ));
                    }
                }
            }

            if(filteresContracts.size() > 0){
                Database.SaveResult[] results2 = Database.update(filteresContracts, false);
                for(Database.SaveResult sr : results2){
                    if(!sr.isSuccess()){
                        System.debug('Error al actualizar Contrato: ' + sr.getErrors()[0].getMessage());
                    }
                }
            }

            if(conversionAccountStatuses.size() > 0){
                update conversionAccountStatuses;
            }
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug('F4_AssingContractOwner_ToAccount_Batch finished');
    }
}