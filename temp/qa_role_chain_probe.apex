Set<Id> roleIds = new Set<Id>{'00EWP000001YI6x2AG','00EWP000001YI862AG','00E7V000001exahUAA','00EWP000001YI8W2AW'};
List<UserRole> roles = [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id IN :roleIds OR ParentRoleId IN :roleIds ORDER BY Name];
System.debug('ROLES=' + JSON.serializePretty(roles));
for (UserRole r : [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id IN :roleIds]) {
    List<String> chain = new List<String>();
    UserRole cur = r;
    Integer guard = 0;
    while (cur != null && guard < 10) {
        chain.add(cur.Name + ' (' + cur.Id + ')');
        cur = cur.ParentRoleId == null ? null : [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id = :cur.ParentRoleId LIMIT 1];
        guard++;
    }
    System.debug('CHAIN ' + r.Name + ' = ' + String.join(chain, ' <- '));
}
