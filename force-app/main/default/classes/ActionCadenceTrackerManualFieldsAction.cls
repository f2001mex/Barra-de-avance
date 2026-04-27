public with sharing class ActionCadenceTrackerManualFieldsAction {
    public class Request {
        @InvocableVariable(label='Completion Disposition')
        public String completionDisposition;

        @InvocableVariable(label='Completion Reason')
        public String completionReason;

        @InvocableVariable(label='State')
        public String state;
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
        label='Set Manual Cadence Fields'
        description='Pass-through action for manual Flow values: Completion Disposition, Completion Reason, and State.'
    )
    public static List<Response> setManualFields(List<Request> requests) {
        List<Response> outputs = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return outputs;
        }

        for (Request req : requests) {
            Response res = new Response();
            res.completionDisposition = (req == null) ? null : req.completionDisposition;
            res.completionReason = (req == null) ? null : req.completionReason;
            res.state = (req == null) ? null : req.state;
            outputs.add(res);
        }

        return outputs;
    }
}