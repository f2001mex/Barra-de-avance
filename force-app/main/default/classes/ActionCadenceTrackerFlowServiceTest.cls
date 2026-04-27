@IsTest
private class ActionCadenceTrackerFlowServiceTest {
    @IsTest
    static void returnsEmptyWhenNoRequests() {
        Test.startTest();
        List<ActionCadenceTrackerFlowService.Response> result =
            ActionCadenceTrackerFlowService.getState(new List<ActionCadenceTrackerFlowService.Request>());
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void handlesNullAndMissingTracker() {
        ActionCadenceTrackerFlowService.Request nullIdReq = new ActionCadenceTrackerFlowService.Request();

        ActionCadenceTrackerFlowService.Request missingReq = new ActionCadenceTrackerFlowService.Request();
        missingReq.trackerId = Id.valueOf('0qB000000000001AAA');

        Test.startTest();
        List<ActionCadenceTrackerFlowService.Response> result =
            ActionCadenceTrackerFlowService.getState(
                new List<ActionCadenceTrackerFlowService.Request>{ nullIdReq, missingReq }
            );
        Test.stopTest();

        System.assertEquals(2, result.size());

        System.assertEquals(false, result[0].found);
        System.assert(result[0].errorMessage != null && result[0].errorMessage.contains('required'));

        System.assertEquals(missingReq.trackerId, result[1].trackerId);
        System.assertEquals(false, result[1].found);
        System.assert(result[1].errorMessage != null && result[1].errorMessage.contains('not found'));
    }
}