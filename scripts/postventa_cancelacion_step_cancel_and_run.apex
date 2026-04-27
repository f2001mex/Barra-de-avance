OD_Contract_cls.bypassTriggerExecution = true;
Contract contractRecord = [
    SELECT Id, Status__c, AccountId
    FROM Contract
    WHERE Id = '800dp00000S6qlOAAR'
    LIMIT 1
];
contractRecord.Status__c = 'C02';
update contractRecord;
OD_Contract_cls.bypassTriggerExecution = false;

List<ContractHistory> histories = [
    SELECT Id, Field, OldValue, NewValue, CreatedDate
    FROM ContractHistory
    WHERE ContractId = :contractRecord.Id
    ORDER BY CreatedDate DESC
];

Id jobId = Database.executeBatch(new PSTA_PostCargaPostventa_bch(), 1);

System.debug('POSTVENTA_CANCELACION_STEP_CANCEL=' + JSON.serialize(new Map<String, Object>{
    'contractId' => contractRecord.Id,
    'accountId' => contractRecord.AccountId,
    'jobId' => jobId,
    'historyCount' => histories.size()
}));
