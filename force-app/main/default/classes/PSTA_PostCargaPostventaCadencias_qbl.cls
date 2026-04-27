public without sharing class PSTA_PostCargaPostventaCadencias_qbl
implements Queueable, Database.AllowsCallouts {

    @TestVisible private static String sessionIdOverride;
    @TestVisible private static Boolean skipFlowInvocation = false;
    @TestVisible private static List<PV_GenerarTareasPeriodicas_Request> lastGeneratedRequests = new List<PV_GenerarTareasPeriodicas_Request>();

    private List<PSTA_PostCargaPostventa_Request> instructions;

    public PSTA_PostCargaPostventaCadencias_qbl(List<PSTA_PostCargaPostventa_Request> instructions) {
        this.instructions = instructions == null ? new List<PSTA_PostCargaPostventa_Request>() : instructions;
    }

    public void execute(QueueableContext context) {
        if (instructions.isEmpty()) {
            return;
        }

        Set<Id> trackerIds = new Set<Id>();
        for (PSTA_PostCargaPostventa_Request instruction : instructions) {
            if (instruction != null && instruction.trackerId != null) {
                trackerIds.add(instruction.trackerId);
            }
        }

        if (trackerIds.isEmpty()) {
            return;
        }

        String sessionId = Test.isRunningTest() && !String.isBlank(sessionIdOverride)
            ? sessionIdOverride
            : UserInfo.getSessionId();

        if (String.isBlank(sessionId) && !Test.isRunningTest()) {
            return;
        }

        Set<Id> removedTrackerIds = removeTrackers(
            PSTA_PostCargaPostventa_soql.getTrackersByIds(trackerIds),
            sessionId
        );

        List<PV_GenerarTareasPeriodicas_Request> reassignmentRequests = new List<PV_GenerarTareasPeriodicas_Request>();
        for (PSTA_PostCargaPostventa_Request instruction : instructions) {
            if (instruction == null || !instruction.shouldReassign || instruction.userId == null) {
                continue;
            }

            if (removedTrackerIds.contains(instruction.trackerId)) {
                reassignmentRequests.add(new PV_GenerarTareasPeriodicas_Request(
                    String.valueOf(instruction.cadenceId),
                    String.valueOf(instruction.accountId),
                    String.valueOf(instruction.userId)
                ));
            }
        }

        if (Test.isRunningTest()) {
            lastGeneratedRequests = reassignmentRequests;
            if (skipFlowInvocation) {
                return;
            }
        }

        if (!reassignmentRequests.isEmpty()) {
            System.enqueueJob(new PV_EjecutarAsignacionCadencias_Queueable(reassignmentRequests, 0));
        }
    }

    @TestVisible
    private static Set<Id> removeTrackers(List<ActionCadenceTracker> trackers, String sessionId) {
        if (trackers == null || trackers.isEmpty()) {
            return new Set<Id>();
        }

        List<Object> inputs = new List<Object>();
        List<Id> trackerIds = new List<Id>();
        for (ActionCadenceTracker tracker : trackers) {
            trackerIds.add(tracker.Id);
            inputs.add(new Map<String, Object>{
                'actionCadenceTrackerId' => tracker.Id,
                'completionReasonCode' => 'ManuallyRemoved',
                'shouldApplyUserContext' => false
            });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v66.0/actions/standard/removeTargetFromSalesCadence');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'inputs' => inputs }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            return new Set<Id>();
        }

        Set<Id> successfulTrackerIds = new Set<Id>();
        List<Object> rawResults = (List<Object>) JSON.deserializeUntyped(res.getBody());
        for (Integer i = 0; i < rawResults.size() && i < trackerIds.size(); i++) {
            Map<String, Object> result = (Map<String, Object>) rawResults[i];
            if ((Boolean) result.get('isSuccess')) {
                successfulTrackerIds.add(trackerIds[i]);
            }
        }

        return successfulTrackerIds;
    }
}
