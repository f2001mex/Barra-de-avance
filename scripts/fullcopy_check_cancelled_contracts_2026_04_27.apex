List<Contract> contracts = [
    SELECT Id, AccountId, Account.Name, Status__c, TypeOfContract__c, LastModifiedDate
    FROM Contract
    WHERE Id IN ('8007V000002W1B2QAK','8007V000002W0baQAC','8007V000002Ucw9QAC')
    ORDER BY Id
];
System.debug('CONTRACTS=' + JSON.serializePretty(contracts));

List<ContractHistory> historyRows = [
    SELECT ContractId, Field, OldValue, NewValue, CreatedDate
    FROM ContractHistory
    WHERE ContractId IN ('8007V000002W1B2QAK','8007V000002W0baQAC','8007V000002Ucw9QAC')
    ORDER BY CreatedDate DESC
];
System.debug('HISTORY=' + JSON.serializePretty(historyRows));

List<AsyncApexJob> jobs = [
    SELECT Id, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate
    FROM AsyncApexJob
    WHERE ApexClass.Name = 'PSTA_PostCargaPostventa_bch'
    ORDER BY CreatedDate DESC
    LIMIT 10
];
System.debug('BATCHES=' + JSON.serializePretty(jobs));
