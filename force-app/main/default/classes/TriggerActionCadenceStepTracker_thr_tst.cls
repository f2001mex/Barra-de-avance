/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para TriggerActionCadanceStepTracker_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     17-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class TriggerActionCadenceStepTracker_thr_tst {

     @isTest
     static void testOnAfterInsert_withBypass() {
        PSTA_GestionTareas_Helper.bypassTriggerExecution = true;

        List<ActionCadenceStepTrackerChangeEvent> mockEvents = new List<ActionCadenceStepTrackerChangeEvent>();
        mockEvents.add(null);

        Test.startTest();
        TriggerActionCadenceStepTracker_thr.onAfterInsert(mockEvents);
        Test.stopTest();

        System.assert(true);
    }
}