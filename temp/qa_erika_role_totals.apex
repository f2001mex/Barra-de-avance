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
List<User> users = [SELECT Id, Name, ID_ASESOR__c, UserRoleId FROM User WHERE UserRoleId IN :roleIds AND IsActive = true AND ID_ASESOR__c != null];
Set<String> advisorIds = new Set<String>();
for (User u : users) advisorIds.add(u.ID_ASESOR__c.trim());
Id rtId = [SELECT Id FROM RecordType WHERE SObjectType='Task' AND DeveloperName='Anti_Churn' LIMIT 1].Id;
AggregateResult[] ars = [SELECT Account.ID_ASESOR__c aid, Count(Id) total FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.ID_ASESOR__c IN :advisorIds GROUP BY Account.ID_ASESOR__c ORDER BY Count(Id) DESC LIMIT 50];
System.debug('ROLE_USER_COUNT=' + users.size());
System.debug('ROLE_ADVISORS=' + JSON.serializePretty(users));
System.debug('ROLE_TASK_COUNTS=' + JSON.serializePretty(ars));
