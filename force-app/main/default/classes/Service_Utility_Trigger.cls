/**
* @File Name : Service_Utility_Trigger.cls
* @Description :
* @Author : Andrés Hernandez Rios
* @Last Modified By : erik.romero@vasscompany.com
* @Last Modified On : 24-01-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 08, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class Service_Utility_Trigger {
    private static final String PERSONACCOUNTRT = 'PersonAccount';
    private static final String WEALTHMANAGMENTACCOUNTRT = 'Wealth_Management_Account';
    private static final String PRIVADAACCOUNTRT = 'PrivateBankingClient';
    private static final String PATRIMONIAL_ACCOUNT_RT = 'PatrimonialBankingClient';
    private static final String BUSINESS_RT = 'IndustriesBusiness';
    public static final Id rtPersonAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PERSONACCOUNTRT).getRecordTypeId();
    public static final Id rtWealthManagmentAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(WEALTHMANAGMENTACCOUNTRT).getRecordTypeId();
    public static final Id rtPrivadaAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PRIVADAACCOUNTRT).getRecordTypeId();   
    public static final Id rtPatrimonialAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PATRIMONIAL_ACCOUNT_RT).getRecordTypeId();  
    public static final Id rtBusinessAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(BUSINESS_RT).getRecordTypeId();  
    private static final String RTCONTACTWOLICENSE = 'BanqueroLlicencia';
    public static final String DEFAULT_USER_NAME = 'IntegrationUser';
    public static final Id rtBankerWithoutLicense = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(RTCONTACTWOLICENSE).getRecordTypeId();
    
    // MÉTODO QUE VERIFICA SI EL TIPO DE REGISTRO DE UNA CUENTA ES VÁLIDO PARA PROCESARLA.
    public static Boolean isCorrectRecordTypeId(Account account){
        Boolean flag = false;       
        if(account.RecordTypeId == rtPersonAccount ||
           account.RecordTypeId == rtWealthManagmentAccount ||
           account.RecordTypeId == rtPrivadaAccount  ||
           account.RecordTypeId == rtPatrimonialAccount||
           account.RecordTypeId == rtBusinessAccount)
        {
            flag = true;
        }        
        return flag;
    }
    public static Map<String,BranchUnitBusinessMember>getBrUnBuMeByExternalIdAndNomina(Set<String> uniqueFindBUBM){
        Map<String,BranchUnitBusinessMember> brunitBussMemberMap = new Map<String,BranchUnitBusinessMember>();
        for(BranchUnitBusinessMember bu :[SELECT Id,ExternalId__c,ExternalIdBI__c FROM BranchUnitBusinessMember WHERE ExternalId__c IN:uniqueFindBUBM OR ExternalIdBI__c IN:uniqueFindBUBM]){
            brunitBussMemberMap.put(bu.ExternalId__c,bu);
            brunitBussMemberMap.put(bu.ExternalIdBI__c,bu);
        }
        return brunitBussMemberMap;
    }
    public static Map<String, Map<String, BranchUnitBusinessMember>> getBranchUnitByCFYJobCode2(Set<String> uniqueAdvisorIds) {
        Map<String, Map<String, BranchUnitBusinessMember>> brunitBussMemberMap = new Map<String, Map<String, BranchUnitBusinessMember>>();
        
        for (Banker bk : [SELECT Id, Name, CurrentBranch.BranchCode, ExternalId__c, 
                          (SELECT Id, Name, ExternalId__c, ExternalIdBI__c, IsActive,BranchUnitId 
                           FROM BranchUnitBusinessMembers) 
                          FROM Banker 
                          WHERE ExternalId__c IN :uniqueAdvisorIds]) {
                              if (!brunitBussMemberMap.containsKey(bk.ExternalId__c)) {
                                  brunitBussMemberMap.put(bk.ExternalId__c, new Map<String, BranchUnitBusinessMember>());
                              }
                              
                              for (BranchUnitBusinessMember bm : bk.BranchUnitBusinessMembers) {
                                  // Si el ExternalId__c no está en blanco y no existe ya en el mapa, agregarlo
                                  if (String.isNotBlank(bm.ExternalId__c) && !brunitBussMemberMap.get(bk.ExternalId__c).containsKey(bm.ExternalId__c)) {
                                      brunitBussMemberMap.get(bk.ExternalId__c).put(bm.ExternalId__c, bm);
                                  }
                                  
                                  // Si el ExternalIdBI__c no está en blanco y no existe ya en el mapa, agregarlo
                                  if (String.isNotBlank(bm.ExternalIdBI__c) && !brunitBussMemberMap.get(bk.ExternalId__c).containsKey(bm.ExternalIdBI__c)) {
                                      brunitBussMemberMap.get(bk.ExternalId__c).put(bm.ExternalIdBI__c, bm);
                                  }
                              }
                          }
        
        return brunitBussMemberMap;
    }
    public static Map<String,BranchUnitBusinessMember> getBranchUnitByOwnerId(Set<Id> setOwnerIds){
        Map<String,BranchUnitBusinessMember> brunitBussMemberMap = new Map<String,BranchUnitBusinessMember> ();
        for(Banker bk :[SELECT Id,UserOrContactId,Name,ExternalId__c,CurrentBranch.ExternalId__c,CurrentBranch.ExternalIdBi__c,(SELECT Id,Name,ExternalId__c,ExternalIdBI__c FROM BranchUnitBusinessMembers WHERE isActive = true) FROM Banker WHERE UserOrContactId IN: setOwnerIds]){
            for(BranchUnitBusinessMember bm :bk.BranchUnitBusinessMembers){  
                
                String externalId = bm != null ? bk.CurrentBranch.ExternalId__c + bk.ExternalId__c : null;
                String externalIdBI = bm != null ? bk.CurrentBranch.ExternalIdBi__c + bk.ExternalId__c : null;
                if(!String.isEmpty(externalId) && externalId.equalsIgnoreCase(bm.ExternalId__c) ||
                   !String.isEmpty(externalIdBI) && externalIdBI.equalsIgnoreCase(bm.ExternalIdBI__c)){
                    brunitBussMemberMap.put(bk.UserOrContactId,bm);
                }
            }
        }
        return brunitBussMemberMap;
    }
    public static Map<String,BranchUnitBusinessMember> getBranchUnitByCFYJobCode(Set<String> uniqueAdvisorIds){
        Map<String,BranchUnitBusinessMember> brunitBussMemberMap = new Map<String,BranchUnitBusinessMember> ();
        for(Banker bk :[SELECT Id,Name,ExternalId__c,CurrentBranch.ExternalId__c,CurrentBranch.ExternalIdBi__c,(SELECT Id,Name,ExternalId__c,ExternalIdBI__c FROM BranchUnitBusinessMembers WHERE isActive = true) FROM Banker WHERE ExternalId__c IN: uniqueAdvisorIds]){
            system.debug('EXTERNALID:' + bk.CurrentBranch.ExternalId__c + bk.ExternalId__c);
            for(BranchUnitBusinessMember bm :bk.BranchUnitBusinessMembers){  
                
                system.debug('EXTERNALIDBI:' + bk.CurrentBranch.ExternalIdBi__c + bk.ExternalId__c);
                
                String externalId = bm != null ? bk.CurrentBranch.ExternalId__c + bk.ExternalId__c : null;
                String externalIdBI = bm != null ? bk.CurrentBranch.ExternalIdBi__c + bk.ExternalId__c : null;
                if(!String.isEmpty(externalId) && externalId.equalsIgnoreCase(bm.ExternalId__c) ||
                   !String.isEmpty(externalIdBI) && externalIdBI.equalsIgnoreCase(bm.ExternalIdBI__c)){
                       
                    brunitBussMemberMap.put(bk.ExternalId__c,bm);
                }
            }
        }
        return brunitBussMemberMap;
    }
 
    public static Map<String,Contact> getContactsByNomina(Set<String> uniqueAdvisorIds){
        Map<String,Contact> contactsByNominaMap = new Map<String,Contact> ();
        for(Contact c :[SELECT Id,Name,NumeroNomina__c,(SELECT Id FROM BankerBM) FROM Contact WHERE RecordTypeId =: rtBankerWithoutLicense AND NumeroNomina__c IN: uniqueAdvisorIds]){
            contactsByNominaMap.put(c.NumeroNomina__c,c);
        }
        return contactsByNominaMap;
    }
    public static Map<Id,User> getUsersByOwnerIds(Set<Id> setUsersId){
        Map<Id,User> usersByNominaMap = new Map<Id,User>();        
        for(User usr :[SELECT Id FROM User WHERE isActive = TRUE AND Id IN :setUsersId]){
            usersByNominaMap.put(usr.Id,usr);
        }        
        return usersByNominaMap;
    }    
    public static Map<String,User> getUsersByNomina(Set<String> uniqueAdvisorIds){
        Map<String,User> usersByNominaMap = new Map<String,User> ();
        for(User usr :[SELECT Id,Name,ID_ASESOR__c  FROM User WHERE isActive = TRUE AND (ID_ASESOR__c IN: uniqueAdvisorIds OR Name = :DEFAULT_USER_NAME)]){            
            usersByNominaMap.put(usr.Name == DEFAULT_USER_NAME ? DEFAULT_USER_NAME : usr.ID_ASESOR__c,usr);
        }
        return usersByNominaMap;
    }
    public static Map<String,BranchUnit> getBranchUnits(Set<String> setIdBranchs){
        Map<String,BranchUnit> branchUnitsMap = new Map<String,BranchUnit> ();
        for(BranchUnit bu :[SELECT Id,Name,ExternalId__c,ExternalIdBI__c FROM BranchUnit WHERE (ExternalId__c IN: setIdBranchs OR ExternalIdBI__c IN:setIdBranchs)]){ 
            branchUnitsMap.put(bu.ExternalIdBI__c,bu);
            branchUnitsMap.put(bu.ExternalId__c,bu);
        }
        return branchUnitsMap;
    }

    /** 
    * @Description: Obtener registros User a través de Ids SF
    * @param   setUsersId: Set Ids usuarios Salesforce
    * @return  Map<Id,String>: Id User por numero de nomina
    */
    public static Map<Id,String> getUsersByIds(Set<Id> setUsersId){
        try{
            Map<Id,String> mapUserIdByNumNomina = new Map<Id,String>();
            for(User objUser :[SELECT ID_ASESOR__c FROM User WHERE isActive = TRUE AND Id IN :setUsersId]){
                mapUserIdByNumNomina.put(objUser.Id,objUser.ID_ASESOR__c);
            }
            return mapUserIdByNumNomina;
        }catch(QueryException e){
            return new Map<Id,String>();
        }
    }
    /** 
    * @Description: Obtener registros Banker a través del ExternalId__c(Numero de nómina) 
    * @param   setNumNomina: Set ExternalId__c(Número de nómina) 
    * @return  Map<String,Banker>: Mapa de Numero de nomina por registro Banker 
    */
    public static Map<String,Banker> getBankerByNumNomina(Set<String> setNumNomina){
        try{
            Map<String,Banker> mapNumNominaByBanker = new Map<String,Banker>();
            for(Banker objBanker :[SELECT ExternalId__c, CurrentBranch.ExternalId__c,(SELECT Id, ExternalId__c FROM BranchUnitBusinessMembers) FROM Banker WHERE ExternalId__c IN :setNumNomina]){
                mapNumNominaByBanker.put(objBanker.ExternalId__c,objBanker);
            }
            return mapNumNominaByBanker;
        }catch(QueryException e){
            return new Map<String,Banker>();
        }
    }
    /** 
    * @Description: Convierte una lista de BranchUnitBusinessMembers a External Id por Id de BranchUnitBusinessMembers
    * @param   lstBranchUnitBusinessMembers: Lista de BranchUnitBusinessMembers
    * @return  Map<String,String>: Mapa de External Id por Id de BranchUnitBusinessMembers
    */
    public static Map<String,String> getMapBranchUnitsBusinessMember(BranchUnitBusinessMember[] lstBranchUnitBusinessMembers) {
		Map<String,String> mapExternalIdByBranchUnitBusinessMemberId = new Map<String,String>();
		for(BranchUnitBusinessMember objBranchUnitBusinessMember :lstBranchUnitBusinessMembers){
			mapExternalIdByBranchUnitBusinessMemberId.put(objBranchUnitBusinessMember.ExternalId__c,objBranchUnitBusinessMember.Id);
		}
		
		return mapExternalIdByBranchUnitBusinessMemberId;
	}
}