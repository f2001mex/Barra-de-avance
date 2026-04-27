/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase PSTA_ChangeAccountInfo_ctr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     16-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public with sharing class PSTA_ChangeAccountInfo_ctr {
    public static boolean byPassTriggerExecution = false;
    public static void changeContactAndDateStatus(List<Task> lstTask, Map<Id, Task> mapOldTask){
        if (bypassTriggerExecution) return;
        PSTA_ChangeAccountInfo_helper.initProcessChangeStatusAccount(lstTask, mapOldTask);
    }
}