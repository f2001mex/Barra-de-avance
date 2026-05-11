Id rootRoleId = '00EWP000001YI6x2AG';
Map<Id, List<Id>> childrenByParent = new Map<Id, List<Id>>();
for (UserRole r : [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId != null]) {
    if (!childrenByParent.containsKey(r.ParentRoleId)) childrenByParent.put(r.ParentRoleId, new List<Id>());
    childrenByParent.get(r.ParentRoleId).add(r.Id);
}
Set<Id> roleIds = new Set<Id>{rootRoleId};
List<Id> stack = new List<Id>{rootRoleId};
while (!stack.isEmpty()) {
    Id current = stack.remove(stack.size()-1);
    for (Id childId : childrenByParent.containsKey(current) ? childrenByParent.get(current) : new List<Id>()) {
        if (roleIds.add(childId)) stack.add(childId);
    }
}
Set<String> advisorIds = new Set<String>();
for (User u : [SELECT ID_ASESOR__c FROM User WHERE UserRoleId IN :roleIds AND IsActive = true AND ID_ASESOR__c != null]) {
    advisorIds.add(u.ID_ASESOR__c.trim());
}
Id rtId = [SELECT Id FROM RecordType WHERE SObjectType='Task' AND DeveloperName='Anti_Churn' LIMIT 1].Id;
System.debug('TOTAL=' + [SELECT Count() FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.ID_ASESOR__c IN :advisorIds]);
for (AggregateResult ar : [SELECT Resultado_de_Gestion__c r, Count(Id) t FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.ID_ASESOR__c IN :advisorIds GROUP BY Resultado_de_Gestion__c]) {
    System.debug('RESULT=' + ar.get('r') + ' TOTAL=' + ar.get('t'));
}
for (AggregateResult ar : [SELECT Account.ID_ASESOR__c aid, Count(Id) t FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.ID_ASESOR__c IN :advisorIds GROUP BY Account.ID_ASESOR__c ORDER BY Count(Id) DESC]) {
    System.debug('ADVISOR=' + ar.get('aid') + ' TOTAL=' + ar.get('t'));
}
