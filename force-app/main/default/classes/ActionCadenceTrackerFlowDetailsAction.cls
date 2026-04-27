public with sharing class ActionCadenceTrackerFlowDetailsAction {
    public class Request {
        @InvocableVariable(required=true label='Action Cadence Tracker Id')
        public Id actionCadenceTrackerId;
    }

    public class Response {
        @InvocableVariable(label='Completion Disposition')
        public String completionDisposition;

        @InvocableVariable(label='Completion Reason')
        public String completionReason;

        @InvocableVariable(label='State')
        public String state;
    }

    @InvocableMethod(
        label='Get Action Cadence Tracker Fields'
        description='Returns Completion Disposition, Completion Reason, and State from ActionCadenceTracker.'
    )
    public static List<Response> getFields(List<Request> requests) {
        List<Response> outputs = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return outputs;
        }

        Set<Id> trackerIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.actionCadenceTrackerId != null) {
                trackerIds.add(req.actionCadenceTrackerId);
            }
        }

        Map<Id, ActionCadenceTracker> trackersById = new Map<Id, ActionCadenceTracker>();
        if (!trackerIds.isEmpty()) {
            for (ActionCadenceTracker tracker : [
                SELECT Id, CompletionReason, CompletionDisposition, State
                FROM ActionCadenceTracker
                WHERE Id IN :trackerIds
            ]) {
                trackersById.put(tracker.Id, tracker);
            }
        }

        for (Request req : requests) {
            Response res = new Response();
            ActionCadenceTracker tracker = (req == null) ? null : trackersById.get(req.actionCadenceTrackerId);

            res.completionDisposition = (tracker == null) ? null : tracker.CompletionDisposition;
            res.completionReason = (tracker == null) ? null : tracker.CompletionReason;
            res.state = (tracker == null) ? null : tracker.State;

            outputs.add(res);
        }

        return outputs;
    }
}