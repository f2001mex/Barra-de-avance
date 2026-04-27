/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_GestionTareas_Helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
1.1     11-08-2025      Salvador Ramírez López                  Modificación para hacer un update sobre la tarea generada desde la cadencia y no generar nuevas tareas.
*******************************************************************************************/
public class PSTA_GestionTareas_Helper {
    public static Boolean bypassTriggerExecution = false;
    public static void createTaskWithCloseCadence(List<ActionCadenceStepTrackerChangeEvent> lstStepTracker){
        if (bypassTriggerExecution) return; List<String> recordIds = new List<String>();
        for(ActionCadenceStepTrackerChangeEvent event : lstStepTracker){ EventBus.ChangeEventHeader header = event.ChangeEventHeader; recordIds.addAll(header.getRecordIds());
        }
        List<ActionCadenceStepTracker> stepTrackers = PSTA_GestionTareas_soql.getStepTrackers(recordIds); if(stepTrackers.size() > 0 && stepTrackers != null) createTasks(stepTrackers);
    }
    public static List<Task> updateTasksCadence( List<ActionCadenceStepTracker> stepTrackers){
        Map<Id,ActionCadenceStepTracker> mapActionCadence = new Map<Id,ActionCadenceStepTracker>();
        for(ActionCadenceStepTracker objActionCadenceStepTracker :stepTrackers) mapActionCadence.put(objActionCadenceStepTracker.Id,objActionCadenceStepTracker);
        Task[] tasks = PSTA_GestionTareas_soql.getTaskUsingIdsTracker(mapActionCadence.keySet());
        for(Task objTask : tasks){
            ActionCadenceStepTracker stepTracker = mapActionCadence.get(objTask.ActionCadenceStepTrackerId); objTask.Subject = stepTracker.ActionCadenceName; objTask.Status = 'Completado'; objTask.Type = stepTracker.ActionCadence.Tipo_de_actividad__c;
            objTask.DeveloperName__c = stepTracker.ActionCadence.DeveloperName__c; objTask.Description = 'Contacto efectivo ' + stepTracker.ActionCadence.Name + ' ' + objTask.Account.Client_ID__c + ' ' + objTask.Account.Name;
            objTask.PV_ExternalID__c = createExternalIdTask(stepTracker.ActionCadence.DeveloperName__c, objTask.Account.Client_ID__c, objTask.Account.ID_Asesor__c); objTask.RecordTypeId = ACTINVER_UtilityFactory_utils.getRecodType('Task', 'Postventa');

        }
        return tasks;
    }
    public static void createTasks(List<ActionCadenceStepTracker> stepTrackers){
        Set<Id> setContactId = generateSetIdContact(stepTrackers);
        Map<String, Object> mapReferences = createMapsToReference(setContactId);
        Map<Id, Banker> mapBankerAccount = getMapBankerAccount((Set<Id>)mapReferences.get('setBMemberId'), (Map<Id, Contact>)mapReferences.get('mapContact'));
        List<Task> lstTareas = updateTasksCadence(stepTrackers);
        if(lstTareas.size() > 0) update lstTareas;
        publishEvent(lstTareas, (Map<Id, Contact>)mapReferences.get('mapAccountByContact'));
    }
    public static Map<Id, Banker> getMapBankerAccount(Set<Id> setBMemberId, Map<Id, Contact> mapContact){
        Map<Id, Banker> mapBankerAccount = new Map<Id, Banker>();
        if(!Test.isRunningTest()){for(Banker bank : PSTA_GestionTareas_soql.getBankerByBusinessMemberId(setBMemberId)){if(mapContact.containsKey(bank.Id)) if(!mapBankerAccount.containsKey(mapContact.get(bank.Id).Id)) mapBankerAccount.put(mapContact.get(bank.Id).Id, bank);
            }   
        }
        return mapBankerAccount;
    }
    public static Set<Id> generateSetIdContact(List<ActionCadenceStepTracker> stepTrackers){
        Set<Id> setContactId = new Set<Id>();
        for(ActionCadenceStepTracker stepTracker : stepTrackers) setContactId.add(stepTracker.TargetId);
        return setContactId;
    }
    public static Map<String, Object> createMapsToReference(Set<Id> setContactId){
        Map<Id, Contact> mapContact = new Map<Id, Contact>();
        Map<Id, Contact> mapAccountByContact = new Map<Id, Contact>();
        Set<Id> setBMemberId = new Set<Id>();
        Map<String, Object> mapResult = new Map<String, Object>();
        for(Contact con : PSTA_GestionTareas_soql.getAccountsByContactIds(setContactId)){setBMemberId.add(con.Account.BanqueroAsignado__r.BusinessUnitMemberId);if(!mapContact.containsKey(con.Account.BanqueroAsignado__r.BusinessUnitMemberId)) mapContact.put(con.Account.BanqueroAsignado__r.BusinessUnitMemberId, con);if(!mapAccountByContact.containsKey(con.Id)) mapAccountByContact.put(con.Id, con);
        }
        mapResult.put('mapContact', mapContact);
        mapResult.put('setBMemberId', setBMemberId);
        mapResult.put('mapAccountByContact', mapAccountByContact);
        return mapResult;
    }
    public static String createExternalIdTask(String strTarea, String ClientBP, String ExternalIdBanquero){ return strTarea + '-' + ClientBP + '-' + ExternalIdBanquero + '-' + ACTINVER_UtilityFactory_utils.formatDate(System.today(), false);
    }
    public static void publishEvent(List<Task> lstTask, Map<Id, Contact> mapAccountByContact){
        List<PV_FinalizacionCadencia__e> lstEvent = new List<PV_FinalizacionCadencia__e>();
        for(Task objTask : lstTask){PV_FinalizacionCadencia__e event = new PV_FinalizacionCadencia__e(); event.TaskId__c = objTask.Id; event.AccountId__c = mapAccountByContact.get(objTask.WhoId).Account.Id;event.UserId__c = objTask.OwnerId;lstEvent.add(event);
        }
        List<Database.SaveResult> results = EventBus.publish(lstEvent);
        System.debug('Resultado publish: ' + results);
    }
}