List<Id> oppIds = new List<Id>{
    '006dp00000FKinRAAT',
    '006dp00000FKkZ7AAL'
};

List<Opportunity> opps = [
    SELECT Id, Name, StageName, RecordType.DeveloperName, PatrimExcluirFlow__c
    FROM Opportunity
    WHERE Id IN :oppIds
];

System.debug('=== BEFORE ===');
for (Opportunity o : opps) {
    System.debug(o.Id + ' | ' + o.Name + ' | ' + o.StageName + ' | ' + o.RecordType.DeveloperName + ' | Excluir=' + o.PatrimExcluirFlow__c);
}

for (Opportunity o : opps) {
    o.PatrimExcluirFlow__c = false;
}
Database.SaveResult[] step1 = Database.update(opps, false);
System.debug('=== STEP 1 (set false) ===');
for (Integer i = 0; i < step1.size(); i++) {
    if (step1[i].isSuccess()) {
        System.debug('OK FALSE -> ' + opps[i].Id);
    } else {
        for (Database.Error e : step1[i].getErrors()) {
            System.debug('ERR FALSE -> ' + opps[i].Id + ' | ' + e.getStatusCode() + ' | ' + e.getMessage());
        }
    }
}

opps = [
    SELECT Id, Name, StageName, RecordType.DeveloperName, PatrimExcluirFlow__c
    FROM Opportunity
    WHERE Id IN :oppIds
];
for (Opportunity o : opps) {
    o.PatrimExcluirFlow__c = true;
}
Database.SaveResult[] step2 = Database.update(opps, false);
System.debug('=== STEP 2 (set true) ===');
for (Integer i = 0; i < step2.size(); i++) {
    if (step2[i].isSuccess()) {
        System.debug('OK TRUE -> ' + opps[i].Id);
    } else {
        for (Database.Error e : step2[i].getErrors()) {
            System.debug('ERR TRUE -> ' + opps[i].Id + ' | ' + e.getStatusCode() + ' | ' + e.getMessage());
        }
    }
}

List<Opportunity> afterOpps = [
    SELECT Id, Name, StageName, PatrimExcluirFlow__c
    FROM Opportunity
    WHERE Id IN :oppIds
];
System.debug('=== AFTER ===');
for (Opportunity o : afterOpps) {
    System.debug(o.Id + ' | ' + o.Name + ' | ' + o.StageName + ' | Excluir=' + o.PatrimExcluirFlow__c);
}
