@IsTest
private class ACTFlowDetailsActionTest {
    @IsTest
    static void returnsEmptyForNoRequests() {
        Test.startTest();
        List<ActionCadenceTrackerFlowDetailsAction.Response> result =
            ActionCadenceTrackerFlowDetailsAction.getFields(new List<ActionCadenceTrackerFlowDetailsAction.Request>());
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void returnsNullsWhenNotFound() {
        ActionCadenceTrackerFlowDetailsAction.Request req = new ActionCadenceTrackerFlowDetailsAction.Request();
        req.actionCadenceTrackerId = Id.valueOf('0qB000000000001AAA');

        Test.startTest();
        List<ActionCadenceTrackerFlowDetailsAction.Response> result =
            ActionCadenceTrackerFlowDetailsAction.getFields(
                new List<ActionCadenceTrackerFlowDetailsAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(null, result[0].completionReason);
        System.assertEquals(null, result[0].completionDisposition);
        System.assertEquals(null, result[0].state);
    }
}