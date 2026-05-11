User u = [SELECT Id, Name, Profile.Name, UserRole.Name, ID_ASESOR__c, F3_Sucursal__c, REQ36_Centro_Financiero__c FROM User WHERE Id = '0055e0000060tTGAAY' LIMIT 1];
System.debug('USER=' + JSON.serializePretty(u));
List<Banker> bankers = [SELECT Id, Name, CurrentBranchId, CurrentBranch.Name, ExternalId__c, UserOrContactId FROM Banker WHERE UserOrContactId = :u.Id LIMIT 5];
System.debug('BANKERS=' + JSON.serializePretty(bankers));
List<BranchUnit> branches = [SELECT Id, Name, BranchCode, ExternalId__c, ExternalIdBI__c FROM BranchUnit WHERE Name = :u.REQ36_Centro_Financiero__c OR BranchCode = :u.F3_Sucursal__c OR ExternalId__c = :u.F3_Sucursal__c OR ExternalIdBI__c = :u.F3_Sucursal__c LIMIT 5];
System.debug('BRANCHES=' + JSON.serializePretty(branches));
Id rtId = [SELECT Id FROM RecordType WHERE SObjectType='Task' AND DeveloperName='Anti_Churn' LIMIT 1].Id;
Id branchId = branches.isEmpty() ? null : branches[0].Id;
Integer countCurrent = branchId == null ? -1 : [SELECT Count() FROM Task WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.BanqueroAsignado__r.BranchUnitId = :branchId];
System.debug('COUNT_CURRENT_FILTER=' + countCurrent);
if (branchId != null) {
    AggregateResult[] advisors = [
        SELECT Account.ID_ASESOR__c aid, Count(Id) total
        FROM Task
        WHERE RecordTypeId=:rtId AND IsClosed=false AND AccountId != null AND Account.BanqueroAsignado__r.BranchUnitId = :branchId
        GROUP BY Account.ID_ASESOR__c
        ORDER BY Count(Id) DESC
        LIMIT 20
    ];
    System.debug('ADVISORS_CURRENT_FILTER=' + JSON.serializePretty(advisors));
    List<Account> sample = [SELECT Id, Name, ID_ASESOR__c, BanqueroAsignado__c, BanqueroAsignado__r.BranchUnitId, BanqueroAsignado__r.BusinessUnitMemberId FROM Account WHERE BanqueroAsignado__r.BranchUnitId = :branchId LIMIT 10];
    System.debug('SAMPLE_ACCOUNTS_CURRENT_FILTER=' + JSON.serializePretty(sample));
}
