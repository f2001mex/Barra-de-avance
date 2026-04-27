/**
 * Tests for ACTCompleteCadenceForAccounts
 *
 * Scenarios covered:
 * - Updates trackers (State != 'Complete') to 'Complete' for Contacts under given Account(s)
 * - Filters by ActionCadenceId = TARGET (77Cdp0000000L7hEAE)
 * - Leaves already-completed trackers unchanged
 * - Handles accounts without contacts/trackers
 * - Bulk processing for multiple accounts
 *
 * Notes:
 * - Uses Test.startTest/stopTest
 * - No SeeAllData
 * - Minimal test data creation for isolation
 */
@IsTest
private class ACTCompleteCadenceForAccountsTest {

    private static final String TARGET_ACTION_CADENCE_ID = '77Cdp0000000L7hEAE';
    private static final String OTHER_ACTION_CADENCE_ID = '77Cdp0000000XXXXEAE';
    private static final String STATE_COMPLETE = 'Complete';

    @TestSetup
    static void setupData() {
        // Accounts
        Account a1 = new Account(Name = 'Acct One');
        Account a2 = new Account(Name = 'Acct Two');
        Account a3 = new Account(Name = 'Acct Three (no contacts/trackers)');
        insert new List<Account>{ a1, a2, a3 };

        // Contacts for a1 and a2
        Contact c11 = new Contact(FirstName = 'C11', LastName = 'Test', AccountId = a1.Id);
        Contact c12 = new Contact(FirstName = 'C12', LastName = 'Test', AccountId = a1.Id);
        Contact c21 = new Contact(FirstName = 'C21', LastName = 'Test', AccountId = a2.Id);
        insert new List<Contact>{ c11, c12, c21 };

        // Trackers for a1 (target cadence):
        // - one not complete
        // - one already complete
        ActionCadenceTracker t11 = new ActionCadenceTracker(
            TargetId = c11.Id,
            ActionCadenceId = TARGET_ACTION_CADENCE_ID,
            State = 'In Progress'
        );
        ActionCadenceTracker t12 = new ActionCadenceTracker(
            TargetId = c12.Id,
            ActionCadenceId = TARGET_ACTION_CADENCE_ID,
            State = STATE_COMPLETE
        );

        // Tracker for a1 but different cadence (should be ignored)
        ActionCadenceTracker t13 = new ActionCadenceTracker(
            TargetId = c12.Id,
            ActionCadenceId = OTHER_ACTION_CADENCE_ID,
            State = 'In Progress'
        );

        // Trackers for a2 (target cadence), all not complete
        ActionCadenceTracker t21 = new ActionCadenceTracker(
            TargetId = c21.Id,
            ActionCadenceId = TARGET_ACTION_CADENCE_ID,
            State = 'Not Started'
        );

        insert new List<ActionCadenceTracker>{ t11, t12, t13, t21 };
    }

    @IsTest
    static void testSingleAccountUpdatesOnlyTargetCadence() {
        // Arrange
        Account a1 = [SELECT Id FROM Account WHERE Name = 'Acct One' LIMIT 1];

        ACTCompleteCadenceForAccounts.Request req = new ACTCompleteCadenceForAccounts.Request();
        req.accountId = a1.Id;

        Test.startTest();
        List<ACTCompleteCadenceForAccounts.Response> respList =
            ACTCompleteCadenceForAccounts.completeForAccounts(new List<ACTCompleteCadenceForAccounts.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, respList.size(), 'Should return one response summary');
        ACTCompleteCadenceForAccounts.Response resp = respList[0];
        System.assertNotEquals(null, resp.perAccountResults, 'Should include per-account results');
        System.assertEquals(1, resp.perAccountResults.size(), 'One per-account result expected');

        ACTCompleteCadenceForAccounts.PerAccountResult par = resp.perAccountResults[0];
        System.assertEquals(a1.Id, par.accountId, 'Account should match');
        // For a1, we had two trackers in target cadence (t11 not complete, t12 complete)
        System.assertEquals(2, par.trackersFound, 'Two trackers for target cadence under a1 contacts');
        System.assertEquals(1, par.updatedToComplete, 'One should be updated to Complete');
        System.assertEquals(1, par.alreadyComplete, 'One already complete should be counted');

        // Validate DB changes:
        Map<Id, ActionCadenceTracker> reloaded = new Map<Id, ActionCadenceTracker>([
            SELECT Id, State, ActionCadenceId, TargetId
            FROM ActionCadenceTracker
            WHERE ActionCadenceId IN :new Set<String>{ TARGET_ACTION_CADENCE_ID, OTHER_ACTION_CADENCE_ID }
        ]);
        for (ActionCadenceTracker t : reloaded.values()) {
            if (t.ActionCadenceId == TARGET_ACTION_CADENCE_ID) {
                System.assertEquals(STATE_COMPLETE, t.State, 'All target-cadence trackers under a1 should now be Complete except unrelated accounts (handled in bulk test)');
            }
        }
    }

    @IsTest
    static void testBulkMultipleAccounts() {
        // Arrange
        Account a1 = [SELECT Id FROM Account WHERE Name = 'Acct One' LIMIT 1];
        Account a2 = [SELECT Id FROM Account WHERE Name = 'Acct Two' LIMIT 1];
        Account a3 = [SELECT Id FROM Account WHERE Name = 'Acct Three (no contacts/trackers)' LIMIT 1];

        List<ACTCompleteCadenceForAccounts.Request> reqs = new List<ACTCompleteCadenceForAccounts.Request>();
        for (Account a : new List<Account>{ a1, a2, a3 }) {
            ACTCompleteCadenceForAccounts.Request r = new ACTCompleteCadenceForAccounts.Request();
            r.accountId = a.Id;
            reqs.add(r);
        }

        Test.startTest();
        List<ACTCompleteCadenceForAccounts.Response> respList =
            ACTCompleteCadenceForAccounts.completeForAccounts(reqs);
        Test.stopTest();

        System.assertEquals(1, respList.size(), 'Single aggregated response expected');
        ACTCompleteCadenceForAccounts.Response resp = respList[0];
        System.assertEquals(3, resp.perAccountResults.size(), 'Three per-account results expected');

        // Verify per-account
        Map<Id, ACTCompleteCadenceForAccounts.PerAccountResult> byAcc = new Map<Id, ACTCompleteCadenceForAccounts.PerAccountResult>();
        for (ACTCompleteCadenceForAccounts.PerAccountResult par : resp.perAccountResults) {
            byAcc.put(par.accountId, par);
        }

        // a1: had 2 target-cadence (1 already complete, 1 updated), plus 1 different cadence ignored
        System.assertEquals(2, byAcc.get(a1.Id).trackersFound, 'a1 target trackers found');
        System.assertEquals(1, byAcc.get(a1.Id).updatedToComplete, 'a1 updated count');
        System.assertEquals(1, byAcc.get(a1.Id).alreadyComplete, 'a1 already complete count');

        // a2: had 1 target-cadence, not complete -> should be updated
        System.assertEquals(1, byAcc.get(a2.Id).trackersFound, 'a2 target trackers found');
        System.assertEquals(1, byAcc.get(a2.Id).updatedToComplete, 'a2 updated count');
        System.assertEquals(0, byAcc.get(a2.Id).alreadyComplete, 'a2 already complete count');

        // a3: no contacts/trackers
        System.assertEquals(0, byAcc.get(a3.Id).trackersFound, 'a3 target trackers found should be 0');
        System.assertEquals(0, byAcc.get(a3.Id).updatedToComplete, 'a3 updated should be 0');
        System.assertEquals(0, byAcc.get(a3.Id).alreadyComplete, 'a3 already complete should be 0');

        // DB assertions: all target-cadence trackers now Complete
        for (ActionCadenceTracker t : [
            SELECT Id, State, ActionCadenceId
            FROM ActionCadenceTracker
            WHERE ActionCadenceId = :TARGET_ACTION_CADENCE_ID
        ]) {
            System.assertEquals(STATE_COMPLETE, t.State, 'All target-cadence trackers should be Complete');
        }
        // Non-target cadence remains unchanged
        for (ActionCadenceTracker t : [
            SELECT Id, State, ActionCadenceId
            FROM ActionCadenceTracker
            WHERE ActionCadenceId = :OTHER_ACTION_CADENCE_ID
        ]) {
            System.assertNotEquals(STATE_COMPLETE, t.State, 'Non-target cadence should be unaffected');
        }
    }

    @IsTest
    static void testNoValidInputsGraceful() {
        Test.startTest();
        List<ACTCompleteCadenceForAccounts.Response> respList1 =
            ACTCompleteCadenceForAccounts.completeForAccounts(new List<ACTCompleteCadenceForAccounts.Request>());
        List<ACTCompleteCadenceForAccounts.Response> respList2 =
            ACTCompleteCadenceForAccounts.completeForAccounts(null);
        Test.stopTest();

        System.assertEquals(1, respList1.size(), 'Empty list should return one empty summary');
        System.assertEquals(1, respList2.size(), 'Null list should return one empty summary');
    }
}
