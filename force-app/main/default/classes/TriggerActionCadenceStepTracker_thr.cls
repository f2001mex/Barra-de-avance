/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase TriggerActionCadenceStepTracker_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
public class TriggerActionCadenceStepTracker_thr {
    public static void onAfterInsert(List<ActionCadenceStepTrackerChangeEvent> lstNewRecords){
        PSTA_GestionTareas_Helper.createTaskWithCloseCadence(lstNewRecords);
    }
}