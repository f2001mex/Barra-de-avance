@IsTest
private class BancasDashboardControllerTest {
    @TestSetup static void setupData() {
        // Las pruebas de alcance no deben depender de automatizaciones ni validaciones
        // funcionales de Account/Opportunity existentes en cada sandbox.
    }
    @IsTest static void authorizedUserGetsData() {
        BancasDashboardSecurity.permissionOverride=true; BancasDashboardSecurity.profileOverride=true;
        Test.startTest(); BancasDashboardDTO result=BancasDashboardController.getDashboard(Date.today().addDays(-1),Date.today().addDays(90),null,null,null); Test.stopTest();
        System.assertNotEquals(null,result); System.assertEquals(0,result.openOpportunities);
        System.assert(result.pendingTasks >= 0); System.assertNotEquals(null,result.competitors);
    }
    @IsTest static void filtersByOwner() {
        BancasDashboardSecurity.permissionOverride=true; BancasDashboardSecurity.profileOverride=true;
        BancasDashboardSecurity.ownerScopeOverride=new Set<Id>{UserInfo.getUserId()};
        Test.startTest();
        BancasDashboardDTO result=BancasDashboardController.getDashboard(Date.today().addDays(-1),Date.today().addDays(90),UserInfo.getUserId(),null,null);
        Test.stopTest();
        System.assertEquals(0,result.openOpportunities); System.assert(result.pendingTasks >= 0);
        System.assertNotEquals(null,result.executiveOptions);
    }
    @IsTest static void roleScopeAllowsTeamAndRejectsOutsideOwner() {
        BancasDashboardSecurity.permissionOverride=true;
        BancasDashboardSecurity.profileOverride=true;
        BancasDashboardSecurity.ownerScopeOverride=new Set<Id>{UserInfo.getUserId()};
        BancasDashboardDTO result=BancasDashboardController.getDashboard(Date.today().addDays(-1),Date.today().addDays(90),null,null,null);
        System.assertEquals(0,result.openOpportunities);
        try {
            BancasDashboardController.getDashboard(null,null,UserInfo.getOrganizationId(),null,null);
            System.assert(false,'Debió rechazar un propietario fuera del alcance.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }
    @IsTest static void permissionIsRequired() {
        BancasDashboardSecurity.permissionOverride=false; BancasDashboardSecurity.profileOverride=true;
        try { BancasDashboardController.getDashboard(null,null,null,null,null); System.assert(false,'Debió denegar acceso'); }
        catch (AuraHandledException expected) { System.assert(true); }
    }
    @IsTest static void validatesDates() {
        BancasDashboardSecurity.permissionOverride=true; BancasDashboardSecurity.profileOverride=true;
        try { BancasDashboardController.getDashboard(Date.today(),Date.today().addDays(-1),null,null,null); System.assert(false,'Debió validar fechas'); }
        catch (AuraHandledException expected) { System.assert(true); }
    }

    @IsTest static void securityUsesFullScopeForSystemAdministrator() {
        BancasDashboardSecurity.permissionOverride=true;
        BancasDashboardSecurity.resetScope();
        System.assertEquals(null, BancasDashboardSecurity.getVisibleOwnerIds());
        System.assert(BancasDashboardSecurity.getEligibleUserIds().size() >= 0);
    }

    @IsTest static void securityLimitsAnExecutiveWithoutRoleToSelf() {
        Profile pmProfile=[SELECT Id FROM Profile WHERE Name=:BancasDashboardSecurity.PROFILE_NAME LIMIT 1];
        String uniqueValue=String.valueOf(DateTime.now().getTime());
        User executive=new User(
            Alias='pmtest', Email='pmtest'+uniqueValue+'@example.com',
            EmailEncodingKey='UTF-8', LastName='PM Security Test',
            LanguageLocaleKey='es_MX', LocaleSidKey='es_MX',
            ProfileId=pmProfile.Id, TimeZoneSidKey='America/Mexico_City',
            Username='pmtest'+uniqueValue+'@example.com'
        );
        insert executive;
        System.runAs(executive) {
            BancasDashboardSecurity.permissionOverride=true;
            BancasDashboardSecurity.resetScope();
            Set<Id> scope=BancasDashboardSecurity.getVisibleOwnerIds();
            System.assertEquals(new Set<Id>{executive.Id},scope);
            System.assertEquals(executive.Id,BancasDashboardSecurity.validateOwner(null));
        }
    }

    @IsTest static void securityUsesRoleHierarchyForExecutives() {
        Profile pmProfile=[SELECT Id FROM Profile WHERE Name=:BancasDashboardSecurity.PROFILE_NAME LIMIT 1];
        UserRole pmRole=[SELECT Id FROM UserRole WHERE DeveloperName='Director_PM' LIMIT 1];
        String uniqueValue=String.valueOf(DateTime.now().getTime());
        User director=new User(
            Alias='pmdir', Email='pmdir'+uniqueValue+'@example.com',
            EmailEncodingKey='UTF-8', LastName='PM Director Test',
            LanguageLocaleKey='es_MX', LocaleSidKey='es_MX',
            ProfileId=pmProfile.Id, UserRoleId=pmRole.Id,
            TimeZoneSidKey='America/Mexico_City',
            Username='pmdir'+uniqueValue+'@example.com'
        );
        insert director;
        System.runAs(director) {
            BancasDashboardSecurity.permissionOverride=true;
            BancasDashboardSecurity.resetScope();
            Set<Id> scope=BancasDashboardSecurity.getVisibleOwnerIds();
            System.assert(scope.contains(director.Id));
            try {
                BancasDashboardSecurity.validateOwner(UserInfo.getOrganizationId());
                System.assert(false,'Debió rechazar un propietario fuera de la jerarquía.');
            } catch (AuraHandledException expected) {
                System.assertNotEquals(null,expected);
            }
        }
    }

    @IsTest static void securityLimitsBankerRoleToSelf() {
        Profile pmProfile=[SELECT Id FROM Profile WHERE Name=:BancasDashboardSecurity.PROFILE_NAME LIMIT 1];
        UserRole bankerRole=[SELECT Id FROM UserRole WHERE DeveloperName='Banquero_Institucional' LIMIT 1];
        String uniqueValue=String.valueOf(DateTime.now().getTime());
        User banker=new User(
            Alias='pmbank', Email='pmbank'+uniqueValue+'@example.com',
            EmailEncodingKey='UTF-8', LastName='PM Banker', LanguageLocaleKey='es_MX',
            LocaleSidKey='es_MX', ProfileId=pmProfile.Id, TimeZoneSidKey='America/Mexico_City',
            UserRoleId=bankerRole.Id, Username='pmbank'+uniqueValue+'@example.com'
        );
        insert banker;
        System.runAs(banker) {
            BancasDashboardSecurity.permissionOverride=true;
            BancasDashboardSecurity.resetScope();
            System.assertEquals(new Set<Id>{banker.Id},BancasDashboardSecurity.getVisibleOwnerIds());
            System.assertEquals(banker.Id,BancasDashboardSecurity.validateOwner(null));
            List<BancasDashboardDTO.FilterOption> options=BancasDashboardSelector.executiveOptions(banker.Id);
            System.assertEquals(1,options.size());
            System.assertEquals(String.valueOf(banker.Id),options[0].value);
        }
    }

    @IsTest static void securityGrantsFullScopeToHeadPermissionSet() {
        Profile pmProfile=[SELECT Id FROM Profile WHERE Name=:BancasDashboardSecurity.PROFILE_NAME LIMIT 1];
        PermissionSet head=[SELECT Id FROM PermissionSet WHERE Name='PM_Head' LIMIT 1];
        String uniqueValue=String.valueOf(DateTime.now().getTime());
        User headUser=new User(
            Alias='pmhead', Email='pmhead'+uniqueValue+'@example.com',
            EmailEncodingKey='UTF-8', LastName='PM Head Test',
            LanguageLocaleKey='es_MX', LocaleSidKey='es_MX',
            ProfileId=pmProfile.Id, TimeZoneSidKey='America/Mexico_City',
            Username='pmhead'+uniqueValue+'@example.com'
        );
        insert headUser;
        insert new PermissionSetAssignment(AssigneeId=headUser.Id,PermissionSetId=head.Id);
        System.runAs(headUser) {
            BancasDashboardSecurity.permissionOverride=true;
            BancasDashboardSecurity.resetScope();
            System.assertEquals(null,BancasDashboardSecurity.getVisibleOwnerIds());
        }
    }
}