/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase Task_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     18-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public class Task_thr {
    public static void onAfterUpdate(List<Task> newListTask, Map<Id, Task> mapOldTask){
        PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(newListTask, mapOldTask);
        Task_Helper.publishEventToComponent(newListTask, mapOldTask);
    }
}