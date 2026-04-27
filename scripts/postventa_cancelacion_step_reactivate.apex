OD_Contract_cls.bypassTriggerExecution = true;
Contract contractRecord = [
    SELECT Id, Status__c
    FROM Contract
    WHERE Id = '800dp00000S6qlOAAR'
    LIMIT 1
];
contractRecord.Status__c = 'Nuevo';
update contractRecord;
OD_Contract_cls.bypassTriggerExecution = false;
System.debug('POSTVENTA_CANCELACION_STEP_REACTIVATE=' + contractRecord.Id);
