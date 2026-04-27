/**
 * ACTCompleteCadenceForAccounts
 * Invocable Apex to complete ActionCadenceTracker records for Contacts under given Account Ids
 * when business rules require setting State = 'Complete' for a specific ActionCadenceId.
 *
 * Specs confirmed by user:
 * - Object: standard ActionCadenceTracker (not __c)
 * - Fields: State (picklist), TargetId (lookup to Contact)
 * - Filter: only trackers with ActionCadenceId = '77Cdp0000000L7hEAE'
 * - Update rule: for the Account whose Avance_FAC__c reached 100 (handled by Flow),
 *                complete all trackers with State != 'Complete' for Contacts of that Account.
 * - Invocation: from a Record-Triggered Flow on Account (After Save), passing Account Ids
 *
 * Design:
 * - Bulkified processing
 * - with sharing to respect sharing rules
 * - SOQL with WITH SECURITY_ENFORCED
 * - DML using Database.update with AccessLevel.USER_MODE
 * - No SOQL/DML in loops; use collections
 * - Clear per-account summary suitable for Flow consumption
 */
public with sharing class ACTCompleteCadenceForAccounts {

    // CONSTANTS
    public static final String TARGET_ACTION_CADENCE_ID = '77Cdp0000000L7hEAE';
    public static final String STATE_COMPLETE = 'Complete';

    // Invocable input
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    // Per-account aggregated outcome for Flow visibility
    public class PerAccountResult {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public Integer trackersFound;

        @InvocableVariable
        public Integer updatedToComplete;

        @InvocableVariable
        public Integer alreadyComplete;

        @InvocableVariable
        public String errorMessage;
    }

    // Top-level response (single element list returned to Flow)
    public class Response {
        @InvocableVariable
        public List<PerAccountResult> perAccountResults;

        @InvocableVariable
        public Integer totalFound;

        @InvocableVariable
        public Integer totalUpdated;

        @InvocableVariable
        public Integer totalAlreadyComplete;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(
        label='Complete Ficha de Afinidad Cadence for Accounts'
        description='For provided Account Ids, completes ActionCadenceTracker records (State = "Complete") tied to Contacts under those Accounts where ActionCadenceId = TARGET and State != "Complete".'
    )
    public static List<Response> completeForAccounts(List<Request> requests) {
        List<Response> out = new List<Response>();
        Response summary = new Response();
        summary.perAccountResults = new List<PerAccountResult>();
        summary.totalFound = 0;
        summary.totalUpdated = 0;
        summary.totalAlreadyComplete = 0;

        // Validate input
        if (requests == null || requests.isEmpty()) {
            out.add(summary);
            return out;
        }

        // Collect Account Ids
        Set<Id> accountIds = new Set<Id>();
        for (Request r : requests) {
            if (r != null && r.accountId != null) {
                accountIds.add(r.accountId);
            }
        }
        if (accountIds.isEmpty()) {
            summary.errorMessage = 'No valid Account Ids provided.';
            out.add(summary);
            return out;
        }

        // Fetch Contacts for the Accounts
        // SECURITY: enforce FLS/sharing
        Map<Id, List<Id>> contactIdsByAccount = new Map<Id, List<Id>>();
        for (Contact c : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
            WITH SECURITY_ENFORCED
        ]) {
            if (c.AccountId == null) continue;
            List<Id> bucket = contactIdsByAccount.get(c.AccountId);
            if (bucket == null) {
                bucket = new List<Id>();
                contactIdsByAccount.put(c.AccountId, bucket);
            }
            bucket.add(c.Id);
        }

        // Build a flat set of all contact Ids
        Set<Id> allContactIds = new Set<Id>();
        for (List<Id> ids : contactIdsByAccount.values()) {
            allContactIds.addAll(ids);
        }

        if (allContactIds.isEmpty()) {
            // No contacts, so no trackers to complete
            for (Id accId : accountIds) {
                PerAccountResult par = new PerAccountResult();
                par.accountId = accId;
                par.trackersFound = 0;
                par.updatedToComplete = 0;
                par.alreadyComplete = 0;
                summary.perAccountResults.add(par);
            }
            out.add(summary);
            return out;
        }

        // Query relevant ActionCadenceTracker records for those Contacts and target Cadence
        // Note: Standard object API names and fields per user confirmation:
        // - Object: ActionCadenceTracker
        // - Fields: State, TargetId (points to Contact), ActionCadenceId
        List<ActionCadenceTracker> trackers = [
            SELECT Id, State, TargetId, ActionCadenceId
            FROM ActionCadenceTracker
            WHERE TargetId IN :allContactIds
              AND ActionCadenceId = :TARGET_ACTION_CADENCE_ID
            WITH SECURITY_ENFORCED
        ];

        // Group trackers by Account via TargetId(Contact.AccountId)
        Map<Id, List<ActionCadenceTracker>> trackersByAccount = new Map<Id, List<ActionCadenceTracker>>();
        if (!trackers.isEmpty()) {
            // Preload Contact.AccountId for mapping without extra SOQL:
            // We'll query a minimal map ContactId -> AccountId for the subset of TargetIds found
            Set<Id> trackerContactIds = new Set<Id>();
            for (ActionCadenceTracker t : trackers) {
                if (t.TargetId != null) trackerContactIds.add(t.TargetId);
            }
            Map<Id, Id> contactToAccount = new Map<Id, Id>();
            if (!trackerContactIds.isEmpty()) {
                for (Contact c2 : [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id IN :trackerContactIds
                    WITH SECURITY_ENFORCED
                ]) {
                    contactToAccount.put(c2.Id, c2.AccountId);
                }
            }

            for (ActionCadenceTracker t : trackers) {
                Id accId = contactToAccount.get(t.TargetId);
                if (accId == null) continue;
                List<ActionCadenceTracker> bucket = trackersByAccount.get(accId);
                if (bucket == null) {
                    bucket = new List<ActionCadenceTracker>();
                    trackersByAccount.put(accId, bucket);
                }
                bucket.add(t);
            }
        }

        // Prepare updates and per-account tallies
        List<ActionCadenceTracker> toUpdate = new List<ActionCadenceTracker>();
        for (Id accId : accountIds) {
            PerAccountResult par = new PerAccountResult();
            par.accountId = accId;
            par.trackersFound = 0;
            par.updatedToComplete = 0;
            par.alreadyComplete = 0;

            List<ActionCadenceTracker> accTrackers = trackersByAccount.get(accId);
            if (accTrackers != null && !accTrackers.isEmpty()) {
                par.trackersFound = accTrackers.size();
                for (ActionCadenceTracker t : accTrackers) {
                    if (t.State == STATE_COMPLETE) {
                        par.alreadyComplete++;
                    } else {
                        ActionCadenceTracker upd = new ActionCadenceTracker(
                            Id = t.Id,
                            State = STATE_COMPLETE
                        );
                        toUpdate.add(upd);
                        par.updatedToComplete++;
                    }
                }
            }

            summary.perAccountResults.add(par);
        }

        // DML in USER_MODE with partial success handling
        if (!toUpdate.isEmpty()) {
            try {
                List<Database.SaveResult> srList = Database.update(toUpdate, false, AccessLevel.USER_MODE);
                Integer failures = 0;
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) failures++;
                }
                Integer successes = srList.size() - failures;
                summary.totalUpdated += successes;
                if (failures > 0) {
                    summary.errorMessage = 'Some trackers failed to update. Failures: ' + String.valueOf(failures);
                }
            } catch (Exception e) {
                summary.errorMessage = 'Update failed: ' + e.getMessage();
                out.add(summary);
                return out;
            }
        }

        // Global counters
        for (PerAccountResult par : summary.perAccountResults) {
            summary.totalFound += (par.trackersFound == null ? 0 : par.trackersFound);
            summary.totalAlreadyComplete += (par.alreadyComplete == null ? 0 : par.alreadyComplete);
        }

        out.add(summary);
        return out;
    }
}
