public with sharing class ActionCadenceTrackerFlowService {
    public class Request {
        @InvocableVariable(required=true)
        public Id trackerId;
    }

    public class Response {
        @InvocableVariable
        public Id trackerId;

        @InvocableVariable
        public String state;

        @InvocableVariable
        public Boolean found;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Action Cadence Tracker State'
        description='Returns the State value for each ActionCadenceTracker Id provided.'
    )
    public static List<Response> getState(List<Request> requests) {
        List<Response> outputs = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return outputs;
        }

        Set<Id> trackerIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.trackerId != null) {
                trackerIds.add(req.trackerId);
            }
        }

        Map<Id, ActionCadenceTracker> trackersById = new Map<Id, ActionCadenceTracker>();
        if (!trackerIds.isEmpty()) {
            for (ActionCadenceTracker tracker : [
                SELECT Id, State
                FROM ActionCadenceTracker
                WHERE Id IN :trackerIds
            ]) {
                trackersById.put(tracker.Id, tracker);
            }
        }

        for (Request req : requests) {
            Response res = new Response();
            res.found = false;

            if (req == null || req.trackerId == null) {
                res.errorMessage = 'trackerId is required.';
                outputs.add(res);
                continue;
            }

            res.trackerId = req.trackerId;
            ActionCadenceTracker tracker = trackersById.get(req.trackerId);

            if (tracker == null) {
                res.errorMessage = 'ActionCadenceTracker not found or not accessible.';
            } else {
                res.state = tracker.State;
                res.found = true;
            }

            outputs.add(res);
        }

        return outputs;
    }
}