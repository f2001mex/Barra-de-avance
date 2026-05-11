/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase TriggerActionCadanceStepTracker
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
trigger TriggerActionCadanceStepTracker on ActionCadenceStepTrackerChangeEvent (after insert) {
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.CadenceStepTracker);
    if (triggerIsActive != null && triggerIsActive.IsActive__c){
        if(Trigger.isInsert && Trigger.isAfter) TriggerActionCadenceStepTracker_thr.onAfterInsert(Trigger.new);
    }
}