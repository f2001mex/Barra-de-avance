Set<Id> userIds = new Set<Id>{
    '0055e0000060tTGAAY'
};
for (User u : [SELECT Id FROM User WHERE Name IN ('Blanca Estela Rodriguez Hernandez','Monica Sofia Tapia Camou','Ximena Jasso Rangel')]) {
    userIds.add(u.Id);
}
List<User> users = [
    SELECT Id, Name, Profile.Name, UserRoleId, UserRole.Name, ID_ASESOR__c, F3_Sucursal__c, REQ36_Centro_Financiero__c
    FROM User
    WHERE Id IN :userIds
    ORDER BY Name
];
System.debug('USERS=' + JSON.serializePretty(users));
Set<String> nominas = new Set<String>();
for (User u : users) if (String.isNotBlank(u.ID_ASESOR__c)) nominas.add(u.ID_ASESOR__c);
List<Banker> bankers = [SELECT Id, Name, ExternalId__c, CurrentBranchId, CurrentBranch.Name, UserOrContactId FROM Banker WHERE ExternalId__c IN :nominas OR UserOrContactId IN :userIds ORDER BY ExternalId__c];
System.debug('BANKERS=' + JSON.serializePretty(bankers));
Id rtId = [SELECT Id FROM RecordType WHERE SObjectType='Task' AND DeveloperName='Anti_Churn' LIMIT 1].Id;
for (User u : users) {
    Integer countAdvisor = String.isBlank(u.ID_ASESOR__c) ? 0 : [SELECT Count() FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.ID_ASESOR__c = :u.ID_ASESOR__c];
    System.debug('ADVISOR_COUNT ' + u.Name + ' = ' + countAdvisor);
}
