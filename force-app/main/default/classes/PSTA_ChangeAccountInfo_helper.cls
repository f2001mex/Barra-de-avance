/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_helper
------------------------------------------------------------------------------------------
No.        Fecha               Autor                      Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez        Clase PSTA_ChangeAccountInfo_helper
*******************************************************************************************/
public class PSTA_ChangeAccountInfo_helper {
    public static void initProcessChangeStatusAccount(List<Task> lstTask, Map<Id, Task> mapOldTask){
        System.debug('**********function initPracess');
        Map<String, Object> mapSets = generateSets(lstTask);
        Set<Id> setIdAcc = (Set<Id>) mapSets.get('setIdAcc');
        Set<String> setDevName = (Set<String>) mapSets.get('setDevName');
        Map<Id, Account> mapAccount = new Map<Id, Account>(PSTA_ChangeAccountInfo_soql.getAccountsInfo(setIdAcc));
        Map<String, ActionCadence> mapConfig = createMapWithConfigs(PSTA_ChangeAccountInfo_soql.lstConfigByCadences(setDevName));
        TaskReview(lstTask, mapOldTask, mapAccount, mapConfig);
    }
    public static Map<String, Object> changeContacAndDatetStatus(Task objTask, Task objOldTask, ActionCadence objConfig, Account objAcc){
        System.debug('**************** changeContactAndDateStatus');
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            if( objTask.El_cliente_fue_contactado__c != null && objTask.El_cliente_fue_contactado__c != objOldTask.El_cliente_fue_contactado__c && objTask.Status == 'Completado' && (objConfig != null && objConfig.GeneraContacto__c) || (objTask.WhatId != null && String.valueOf(objTask.WhatId).startsWith('006'))){
                System.debug('Entró');
                if(objConfig != null && objConfig.RequiereCargaEvidencia__c && objTask.RefenciaOpenText__c == null){
                    objTask.addError('No es posible cambiar el estatus de contacto a cliente ya que no se ha cargado evidencia.');
                } else {
                    objAcc.FechaUltimoContacto__c = System.today();
                    if(objTask.ClienteNoQuiereSerContactado__c){
                        objAcc.FechaNoRequiereSerContacto__c = System.today();
                        objAcc.EstatusContacto__c = 'Cliente no quiere ser contactado';
                    } else {
                        objAcc.EstatusContacto__c = objTask.El_cliente_fue_contactado__c == 'Si' ? 'Contacto efectivo exitoso' : 'Contacto no exitoso';
                    }
                    mapResult.put('Account', objAcc);
                }
            }
            /*if(objTask.ClienteNoQuiereSerContactado__c && objTask.ClienteNoQuiereSerContactado__c != objOldTask.ClienteNoQuiereSerContactado__c){
                publicarEvento(objTask.Id, System.UserInfo.getUserId());
            }*/
        } catch(Exception e){
            System.debug('Error al actualizar cuenta desde trigger: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
            mapResult.put('Error', 'Error al actualizar la cuenta: ' + e.getMessage());
        }
        return mapResult;
    }
    public static void taskReview(List<Task> lstTask, Map<Id, Task> mapOldTask, Map<Id, Account> mapAccount, Map<String, ActionCadence> mapConfig){
        System.debug('********* funcion taskreview');
        List<Account> lstAccToUpdate = new List<Account>();
        Set<Id> setTaskUpdate = new Set<Id>();
        Set<Id> setIdTasksWithErrors = new Set<Id>();
        Map<Id, Id> mapTaskByAccount = new Map<Id, Id>();
        try{
            System.debug('********* Lista de tareas: ' + lstTask.size());
            for(Task objTask : lstTask){
                System.debug('********* Entra a la lista de tareas');
                System.debug('********* Objeto tarea: ' + objTask);
                if(objTask.AccountId != null && mapAccount.containsKey(objTask.AccountId)){
                    System.debug('******* Mapa de configuración: ' + mapConfig);
                    Map<String, Object> mapResult = changeContacAndDatetStatus(objTask, mapOldTask.get(objTask.Id), mapConfig.get(objTask.DeveloperName__c), mapAccount.get(objTask.AccountId));
                    if(mapResult.containsKey('Account')){
                        Account objAcc = (Account)mapResult.get('Account');
                        lstAccToUpdate.add(objAcc);
                        if(!mapTaskByAccount.containsKey(objAcc.Id)) mapTaskByAccount.put(objAcc.Id, objTask.Id);
                    } else {
                        if(mapResult.containsKey('Error')) objTask.addError((String)mapResult.get('Error'));
                    }
                }
            }
            System.debug('********* Finaliza recorrido de tareas');
            Map<String, Object> mapResult = updateAccountAndGetTasks(lstAccToUpdate, mapTaskByAccount);
            setTaskUpdate = (Set<Id>) mapResult.get('success');
            setIdTasksWithErrors = (Set<Id>) mapResult.get('Errors');
            Map<Id, String> mapErrors = (Map<Id, String>) mapResult.get('ErrorMsgs');
            if(setIdTasksWithErrors.size() > 0){
                for(Task objTask : lstTask){
                    if(setIdTasksWithErrors.contains(objTask.Id)) objTask.addError('Error al actualizar la información del cliente: ' + mapErrors.get(objTask.Id));
                }
            }
            if(setTaskUpdate.size() > 0) PSTA_EnvioEncuestaMedallia_cls.sendSurvey(setTaskUpdate);
        } catch (Exception e){
            System.debug('************ Error al actualizar en taskreview: ' + e.getMessage() + '. Línea: ' + e.getLineNumber());
        }
    }
    public static Map<String, Object> generateSets(List<Task> lstTask){
        Set<Id> setIdAcc = new Set<Id>();
        Set<String> setDevName = new Set<String>();
        for(Task objTask : lstTask){
            if(objTask.AccountId != null) setIdAcc.add(objTask.AccountId);
            if(objTask.DeveloperName__c != null) setDevName.add(objTask.DeveloperName__c);
        }
        return new Map<String, Object>{'setIdAcc' => setIdAcc, 'setDevName' => setDevName};
    }
    public static Map<String, Object> updateAccountAndGetTasks(List<Account> lstAccToUpdate, Map<Id, Id> mapTaskByAccount){
        OD_Account_cls.bypassTriggerExecution = true;
        Set<Id> setIdTasks = new Set<Id>();
        Set<Id> setIdTasksWithErrors = new Set<Id>();
        String strError = '';
        Map<String, Object> mapResult = new Map<String, Object>();
        Map<Id, String> mapErrors = new Map<Id, String>();
        List<Database.SaveResult> saveResult = Database.update(lstAccToUpdate, false);
        for(Database.SaveResult result : saveResult){
            if(result.isSuccess()) setIdTasks.add(mapTaskByAccount.get(result.getId())); else {
                for(Database.Error error : result.getErrors()){
                    strError += error.getMessage() + '; ';
                    setIdTasksWithErrors.add(mapTaskByAccount.get(result.getId()));
                }
                if(!mapErrors.containsKey(mapTaskByAccount.get(result.getId()))) mapErrors.put(mapTaskByAccount.get(result.getId()), strError);
            }
        }
        mapResult.put('Errors', setIdTasksWithErrors);
        mapResult.put('success', setIdTasks);
        mapResult.put('ErrorMsgs', mapErrors);
        return mapResult;
    }
    public static Map<String, ActionCadence> createMapWithConfigs(List<ActionCadence> lstConfig){
        Map<String, ActionCadence> mapConfig = new Map<String, ActionCadence>();
        for(ActionCadence objConfig : lstConfig){
            mapConfig.put(objConfig.DeveloperName__c, objConfig);
        }
        return mapConfig;
    }
    public static void publicarEvento(Id idTask, Id idUser){
        EventoComponente__e event = new EventoComponente__e(TaskId__c = idTask, UserId__c = idUser);
        Database.SaveResult sr = EventBus.publish(event);
        System.debug('*******Resultado de publicación: ' + sr.isSuccess());
    }
}