/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Helper
 * @Author   luis.andres.hernandez@vasscompany.com
 * @Date     Created: 03/03/2025
 * @Group    VASS
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the lead trigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         03/03/2025      Andres Hernandez 			       Class creation.
*--------------------------------------------------------------------------
 **/
public without sharing class Service_Utility_Trigger2 {
    public static String MSG_WITH_ERROR_RELATION = 'ERROR: Hay un erro en la relacion de "C.P.",Consulte a su Administrador';
    public static String MSG_WITHOUT_POSTALCODE = 'ERROR: El Lead no contiene un Código Postal, favor se asignarle uno';
    public static String CUSTOM_NOTIFICATION_ASL = 'Asignacion_de_Lead';
    public static String LABEL_CN_TITLE = Label.ASL_CN_Title;
    public static String LABEL_CN_BODY = Label.ASL_CN_Body;
    public static Map<Lead,List<UserByGroupTMP__c>> getUserGroupByLead(List<Lead> newList){
        Map<Lead,String> mapIdLeadByCode = new Map<Lead,String>();        
        Map<Lead,String> mapIdLeadByPostalCode = new Map<Lead,String>();
        Map<Lead,String> mapIdLeadByBranchGroup = new Map<Lead,String>();
        Map<Lead,List<UserByGroupTMP__c>> mapIdLeadByGroupUser = new Map<Lead,List<UserByGroupTMP__c>>();
        List<Lead> lstLeadsWithoutCP = new List<Lead>();
        system.debug('******************INICIA ASIGNACION C.P.******************');

        for (Lead lead : newList) {
            system.debug('************LEAD*********'+lead);
            if (String.isEmpty(lead.PostalCode)) {
                lead.addError(MSG_WITHOUT_POSTALCODE); 
            } else {
                mapIdLeadByCode.put(lead,lead.PostalCode);
            }
        }
        
        if (!mapIdLeadByCode.isEmpty()) {
            system.debug('**************mapIdLeadByCode KEYSET********'+mapIdLeadByCode.keySet());
            system.debug('**************mapIdLeadByCode VALUES********'+mapIdLeadByCode.values());
            List<PostalCodeByBranchUnit__c> lstPostaCodes = [
                SELECT Id, CentroFinanciero__r.ExternalId__c,CodigoPostal__r.CodigoPostal__c FROM 
                PostalCodeByBranchUnit__c WHERE CodigoPostal__r.CodigoPostal__c IN :mapIdLeadByCode.values()
                AND Activo__c = true
            ];
            system.debug('lstPostaCodes:' + lstPostaCodes);
            if(!lstPostaCodes.isEmpty()){
                for(PostalCodeByBranchUnit__c p:lstPostaCodes){
                    for(Lead lead : mapIdLeadByCode.keySet()){
                        if(p.CodigoPostal__r.CodigoPostal__c == mapIdLeadByCode.get(lead)){
                            mapIdLeadByPostalCode.put(lead,p.CentroFinanciero__r.ExternalId__c);
                        }else{
                            lstLeadsWithoutCP.add(lead);
                        }
                    }
                }
            }else{
                lstLeadsWithoutCP.addAll(mapIdLeadByCode.keySet());                
            }
            if(!lstLeadsWithoutCP.isEmpty()){
                system.debug('**************ENTRO DEFAULT********');
                setDefaultUsersGroup(lstLeadsWithoutCP,'Default');
            }           
        }
        
        if (!mapIdLeadByPostalCode.isEmpty()) {
            system.debug('**************mapIdLeadByPostalCode KEYSET********'+mapIdLeadByPostalCode.keySet());
            system.debug('**************mapIdLeadByPostalCode VALUES********'+mapIdLeadByPostalCode.values());            
            List<BranchUnitGroup__c> lstBranchGroups =[
                SELECT Id,Grupo__c,BranchUnit__r.ExternalId__c FROM BranchUnitGroup__c
                WHERE BranchUnit__r.ExternalId__c IN :mapIdLeadByPostalCode.values()
                AND Activo__c = true
            ];
            if(!lstBranchGroups.isEmpty()){
                for(BranchUnitGroup__c b :lstBranchGroups){
                    for(Lead lead : mapIdLeadByPostalCode.keySet()){
                        if(b.BranchUnit__r.ExternalId__c == mapIdLeadByPostalCode.get(lead)){
                            mapIdLeadByBranchGroup.put(lead,b.Grupo__c);
                        }
                    }
                }
            }
        }
        
        if (!mapIdLeadByBranchGroup.isEmpty()) {
            system.debug('**************mapIdLeadByBranchGroup KEYSET********'+mapIdLeadByBranchGroup.keySet());
            system.debug('**************mapIdLeadByBranchGroup VALUES********'+mapIdLeadByBranchGroup.values());
            List<UserByGroupTMP__c> lstUserGroups = [
                SELECT Id,Grupo__c,User__c,Indice_Round__c,User__r.Name FROM UserByGroupTMP__c
                WHERE Grupo__c IN: mapIdLeadByBranchGroup.values() AND Activo__c = true
            ];

            if(!lstUserGroups.isEmpty()){
                for(UserByGroupTMP__c u:lstUserGroups){
                    for(Lead lead : mapIdLeadByBranchGroup.keySet()){
                        if(u.Grupo__c == mapIdLeadByBranchGroup.get(lead)){
                            if (!mapIdLeadByGroupUser.containsKey(lead)) {
                                mapIdLeadByGroupUser.put(lead, new List<UserByGroupTMP__c>());
                            }
                            mapIdLeadByGroupUser.get(lead).add(u);
                        }
                    }
                } 
            }  
            system.debug('**************mapIdLeadByGroupUser KEYSET********'+mapIdLeadByGroupUser.keySet());
            system.debug('**************mapIdLeadByGroupUser VALUES********'+mapIdLeadByGroupUser.values());
        }
        return mapIdLeadByGroupUser;
    }
    public static void setOwnerIdsToLead(Map<Lead,List<UserByGroupTMP__c>> mapIdLeadByGroupUser,List<Lead> newList){
        List<Lead> lstToUpdateLeads = new List<Lead>();
        Set<String> setIdsNotifications = new Set<String>();
        for (Lead lead : newList) { 
            if(mapIdLeadByGroupUser.containskey(lead)){
                system.debug('************UserByGroupTMP__c*********'+mapIdLeadByGroupUser);   
                UserByGroupTMP__c userGroupUser = Round_Robin_Utils.ASLAssignment(mapIdLeadByGroupUser.get(lead));
                
                if(userGroupUser == null){
                    lead.addError(MSG_WITH_ERROR_RELATION);
                    return;
                }              
                
                Lead leadNew = new Lead();
                leadNew.Id = lead.Id;
                leadNew.OwnerId = userGroupUser.User__c;
                lstToUpdateLeads.add(leadNew);
                setIdsNotifications.add(leadNew.OwnerId);
                
                sendNotificationUser(setIdsNotifications, lead);
            }                
        }
        if(!lstToUpdateLeads.isEmpty()){
            update lstToUpdateLeads;
            LeadTrigger_Helper.bypassTriggerExecution = true;
        }
    }
    public static void setDefaultUsersGroup(List<Lead> newList,String option){
        Map<Lead,String> mapIdLeadByCode = new Map<Lead,String>();    
        Map<Lead,List<UserByGroupTMP__c>> mapIdLeadByGroupUser = new Map<Lead,List<UserByGroupTMP__c>>();
        UserByGroupTMP__c userGroupUser = new UserByGroupTMP__c();
        
        for(Lead lead:newList){
            mapIdLeadByCode.put(lead,option);
        }
        if(!mapIdLeadByCode.isEmpty()){
            List<UserByGroupTMP__c> lstGroupUsers = [
                SELECT Id,User__r.Name,User__c,Indice_Round__c,Grupo__r.NombreGrupo__c FROM UserByGroupTMP__c
                WHERE Grupo__r.NombreGrupo__c IN:mapIdLeadByCode.values() AND Activo__c = true
            ];
            if(!lstGroupUsers.isEmpty()){
                for(UserByGroupTMP__c u:lstGroupUsers){
                    for(Lead lead : mapIdLeadByCode.keySet()){                        
                        if(u.Grupo__r.NombreGrupo__c == mapIdLeadByCode.get(lead)){
                            if (!mapIdLeadByGroupUser.containsKey(lead)) {
                                mapIdLeadByGroupUser.put(lead, new List<UserByGroupTMP__c>());
                            }
                            mapIdLeadByGroupUser.get(lead).add(u);
                        }
                    } 
                }
            }
            system.debug('*************mapIdLeadByGroupUser KEYSET************'+mapIdLeadByGroupUser.keySet());
            system.debug('*************mapIdLeadByGroupUser VALUES************'+mapIdLeadByGroupUser.values());
            
            setOwnerIdsToLead(mapIdLeadByGroupUser,newList);
        }
    }
    public static void sendNotificationUser(Set<String> recipientsIds, Lead leadTarget){
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: CUSTOM_NOTIFICATION_ASL
        ];
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        String bodyMessage = String.format(LABEL_CN_BODY, new Object[] {leadTarget.FirstName});

        notification.setTitle(LABEL_CN_TITLE);
        notification.setBody(bodyMessage);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(leadTarget.Id);
        
        try {
            notification.send(recipientsIds);
            system.debug(LoggingLevel.INFO,'Se envío notificación');
        }
        catch (Exception e) {
            system.debug(LoggingLevel.ERROR,'Problemas en el envío de notificación:'+ e.getMessage());
        }
    }
}