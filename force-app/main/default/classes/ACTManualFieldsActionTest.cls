@IsTest
private class ACTManualFieldsActionTest {
    @IsTest
    static void returnsEmptyForNoRequests() {
        Test.startTest();
        List<ActionCadenceTrackerManualFieldsAction.Response> result =
            ActionCadenceTrackerManualFieldsAction.setManualFields(
                new List<ActionCadenceTrackerManualFieldsAction.Request>()
            );
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void echoesInputValues() {
        ActionCadenceTrackerManualFieldsAction.Request req =
            new ActionCadenceTrackerManualFieldsAction.Request();
        req.completionDisposition = 'Meeting Booked';
        req.completionReason = 'NoMoreSteps';
        req.state = 'Complete';

        Test.startTest();
        List<ActionCadenceTrackerManualFieldsAction.Response> result =
            ActionCadenceTrackerManualFieldsAction.setManualFields(
                new List<ActionCadenceTrackerManualFieldsAction.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Meeting Booked', result[0].completionDisposition);
        System.assertEquals('NoMoreSteps', result[0].completionReason);
        System.assertEquals('Complete', result[0].state);
    }
}