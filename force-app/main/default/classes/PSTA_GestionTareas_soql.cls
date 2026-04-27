/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_GestionTareas_soql
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public  class PSTA_GestionTareas_soql {
    public static List<ActionCadenceStepTracker> getStepTrackers(List<String> recordIds){
        return [SELECT  Id,
                        ActionCadenceStepId,
                        ActionCadenceName,
                        TargetId,
                        StepType,
                        StepTitle,
                        ActionCadence.Tipo_de_actividad__c,
                        ActionCadence.DeveloperName__c,
                        ActionCadence.Name
                FROM ActionCadenceStepTracker
                WHERE Id IN :recordIds AND State = 'Completed'  AND ActionCadenceTracker.State = 'Complete'];
    }
    public static List<Contact> getAccountsByContactIds(Set<Id> setContactId){
        return [SELECT ID, AccountId, Account.BanqueroAsignado__r.BusinessUnitMemberId, Account.Client_ID__c, Account.Name
                FROM CONTACT WHERE Id IN :setContactId AND AccountId != NULL];
    }
    public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
        return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
    }
    public static List<Task> getTaskUsingIdsTracker(Set<Id> setTrackersId){
        return [SELECT Id,ActionCadenceStepTrackerId,Account.Client_ID__c,Account.Name, Account.ID_Asesor__c, WhoId, OwnerId FROM Task WHERE ActionCadenceStepTrackerId IN :setTrackersId];
    }
}