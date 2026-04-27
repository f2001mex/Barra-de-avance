System.debug('CONTRACT_HISTORY=' + JSON.serialize(new Map<String, Object>{
    'statusHistoryTracked' => Contract.Status__c.getDescribe().isFieldHistoryTracked(),
    'ownerHistoryTracked' => Contract.OwnerId.getDescribe().isFieldHistoryTracked(),
    'advisorHistoryTracked' => Contract.ID_ASESOR__c.getDescribe().isFieldHistoryTracked()
}));
