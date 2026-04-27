/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Salvador Ramirez Lopez 
Proyecto:                Actinver Postventa
Descripción:             Clase test de trigger TriggerActionCadanceStepTracker
------------------------------------------------------------------------------------------
No.        Fecha               Autor                           Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     19-06-2025      Salvador Ramirez Lopez                  Creación
*******************************************************************************************/
@isTest
private class TriggerActionCadenceStepTracker_tst {
    @isTest static void testCadenceStepTrackerCreateAndComplete() {
        
        Test.enableChangeDataCapture();
        
        // Create mock CREATE change event
        EventBus.ChangeEventHeader createHeader = new EventBus.ChangeEventHeader();
        createHeader.recordIds = new List<String>{ '8HFR00000005BfAOAU' };
        createHeader.changeType='CREATE';
        createHeader.entityName='ActionCadence';
        createHeader.changeOrigin='user1-wsl';
        createHeader.transactionKey = 'key';
        createHeader.commitUser = 'user1';
        ActionCadenceStepTrackerChangeEvent createEvent = new ActionCadenceStepTrackerChangeEvent();
        createEvent.changeEventHeader = createHeader;
        createEvent.put('ActionCadenceId', '77CR0000000ENXAMA4');
        createEvent.put('ActionCadenceStepId', '8C8R00000001rerKAA');
        createEvent.put('State', 'Active');
        createEvent.put('StepType', 'SendAnEmail');
        createEvent.put('StepTitle', 'Email');
        EventBus.publish(createEvent);
        Test.getEventBus().deliver();
        
        // Create mock UPDATE change event
        EventBus.ChangeEventHeader updateHeader = new EventBus.ChangeEventHeader();
        updateHeader.recordIds = new List<String>{ '8HFR00000005BfAOAU' };
        updateHeader.changeType='UPDATE';
        updateHeader.entityName='ActionCadence';
        updateHeader.changeOrigin='user1-wsl';
        updateHeader.transactionKey = 'key';
        updateHeader.commitUser = 'user1';
        ActionCadenceStepTrackerChangeEvent updateEvent = new ActionCadenceStepTrackerChangeEvent();
        updateEvent.changeEventHeader = updateHeader;
        updateEvent.put('State', 'Completed');
        EventBus.publish(updateEvent);
        Test.getEventBus().deliver();
     
    }
}