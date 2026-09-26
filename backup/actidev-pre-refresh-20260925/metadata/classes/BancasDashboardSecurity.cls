public with sharing class BancasDashboardSecurity {
    public static final String PROFILE_NAME = 'PM - Ejecutivo Personas Morales';
    private static final String ROLE_ADMIN = 'Administrativo_PM';
    private static final String ROLE_BANKER = 'Banquero_Institucional';
    private static final Set<String> PM_PERMISSION_SETS = new Set<String>{
        'PS_Acceso_Dashboards_Bancas',
        'PM_GestionComercial',
        'PM_Director',
        'PM_Head',
        'PM_Administrativo'
    };
    private static final Set<String> FULL_SCOPE_PERMISSION_SETS = new Set<String>{
        'PM_Head',
        'PM_Administrativo'
    };
    @TestVisible private static Boolean permissionOverride;
    @TestVisible private static Boolean profileOverride;
    @TestVisible private static Set<Id> ownerScopeOverride;
    private static Set<Id> visibleOwnerIds;
    private static Boolean scopeInitialized = false;

    @TestVisible
    private static void resetScope() {
        visibleOwnerIds = null;
        scopeInitialized = false;
        ownerScopeOverride = null;
    }

    public static void assertAuthorized() {
        Boolean hasPermission = Test.isRunningTest() && permissionOverride != null
            ? permissionOverride : FeatureManagement.checkPermission('Acceso_Dashboards_Bancas');
        if (!hasPermission) {
            throw new AuraHandledException('No tiene autorización para consultar los dashboards de Personas Morales.');
        }
    }
    public static Boolean isPmExecutive() {
        if (Test.isRunningTest() && profileOverride != null) return profileOverride;
        return [SELECT Name FROM Profile WHERE Id=:UserInfo.getProfileId()].Name==PROFILE_NAME;
    }

    public static Set<Id> getVisibleOwnerIds() {
        if (Test.isRunningTest() && ownerScopeOverride != null) return ownerScopeOverride;
        if (!scopeInitialized) initializeOwnerScope();
        return visibleOwnerIds;
    }

    public static Id validateOwner(Id requestedOwnerId) {
        Set<Id> allowed = getVisibleOwnerIds();
        if (allowed == null) return requestedOwnerId;
        if (requestedOwnerId != null && !allowed.contains(requestedOwnerId)) {
            throw new AuraHandledException('El ejecutivo seleccionado no pertenece a su alcance de consulta.');
        }
        if (requestedOwnerId == null && allowed.size() == 1) return allowed.iterator().next();
        return requestedOwnerId;
    }

    private static void initializeOwnerScope() {
        scopeInitialized = true;
        visibleOwnerIds = null;
        User currentUser = [
            SELECT Id, UserRoleId, UserRole.DeveloperName, Profile.PermissionsModifyAllData
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        Set<String> assignedPmPermissionSets = new Set<String>();
        for (PermissionSetAssignment assignment : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUser.Id AND PermissionSet.Name IN :PM_PERMISSION_SETS
        ]) assignedPmPermissionSets.add(assignment.PermissionSet.Name);
        Set<String> fullScopeAssignments = assignedPmPermissionSets.clone();
        fullScopeAssignments.retainAll(FULL_SCOPE_PERMISSION_SETS);

        if (currentUser.Profile.PermissionsModifyAllData ||
            !fullScopeAssignments.isEmpty() ||
            (currentUser.UserRoleId != null && currentUser.UserRole.DeveloperName == ROLE_ADMIN)) {
            return;
        }

        if (currentUser.UserRoleId == null) {
            visibleOwnerIds = new Set<Id>{currentUser.Id};
            return;
        }

        // Los banqueros son pares dentro del mismo rol. Su alcance debe ser
        // exclusivamente propio, no todos los usuarios que comparten el rol.
        if (currentUser.UserRole.DeveloperName == ROLE_BANKER) {
            visibleOwnerIds = new Set<Id>{currentUser.Id};
            return;
        }

        Set<Id> roleIds = new Set<Id>();
        if (currentUser.UserRole.DeveloperName == ROLE_ADMIN) {
            for (User item : [
                SELECT Id
                FROM User
                WHERE IsActive = true AND Profile.Name = :PROFILE_NAME
            ]) visibleOwnerIds = visibleOwnerIds == null
                ? new Set<Id>{item.Id} : addOwner(visibleOwnerIds, item.Id);
            if (visibleOwnerIds == null) visibleOwnerIds = new Set<Id>{currentUser.Id};
            return;
        }

        roleIds.add(currentUser.UserRoleId);
        List<UserRole> roles = [SELECT Id, ParentRoleId FROM UserRole];
        Boolean added = true;
        while (added) {
            added = false;
            for (UserRole role : roles) {
                if (role.ParentRoleId != null && roleIds.contains(role.ParentRoleId) && !roleIds.contains(role.Id)) {
                    roleIds.add(role.Id);
                    added = true;
                }
            }
        }
        visibleOwnerIds = new Set<Id>();
        Set<Id> eligibleUserIds = getEligibleUserIds();
        for (User item : [
            SELECT Id
            FROM User
            WHERE IsActive = true AND Id IN :eligibleUserIds AND UserRoleId IN :roleIds
        ]) visibleOwnerIds.add(item.Id);
        visibleOwnerIds.add(currentUser.Id);
    }

    public static Set<Id> getEligibleUserIds() {
        Set<Id> result = new Set<Id>();
        for (User item : [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = :PROFILE_NAME]) {
            result.add(item.Id);
        }
        for (PermissionSetAssignment assignment : [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name IN :PM_PERMISSION_SETS AND Assignee.IsActive = true
        ]) result.add(assignment.AssigneeId);
        return result;
    }

    private static Set<Id> addOwner(Set<Id> target, Id ownerId) {
        target.add(ownerId);
        return target;
    }
}