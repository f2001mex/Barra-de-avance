System.debug('POSTVENTA_CONTRACT_HISTORY_TRACKING=' + JSON.serialize(new Map<String, Object>{
    'contractHistoryEnabled' => Schema.SObjectType.Contract.getDescribe().isEnableHistory(),
    'statusHistoryTracked' => Schema.SObjectType.Contract.fields.Status__c.getDescribe().isFieldHistoryTracked(),
    'ownerHistoryTracked' => Schema.SObjectType.Contract.fields.OwnerId.getDescribe().isFieldHistoryTracked(),
    'advisorHistoryTracked' => Schema.SObjectType.Contract.fields.ID_ASESOR__c.getDescribe().isFieldHistoryTracked()
}));
