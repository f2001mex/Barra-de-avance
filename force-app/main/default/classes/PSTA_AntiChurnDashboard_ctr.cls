public with sharing class PSTA_AntiChurnDashboard_ctr {

    private static final String RESULT_POSITIVE = 'Contactado Retenido';
    private static final String RESULT_NEGATIVE = 'Contactado No Retenido';
    private static final String RESULT_NO_CONTACT = 'Cliente no responde';
    private static final String RESULT_PENDING = 'Pendiente';
    private static final String REPORT_FOLDER_NAME = 'Anti Churn';
    private static final String SCOPE_ALL = 'ALL';
    private static final String SCOPE_ADVISOR = 'ADVISOR';
    private static final String SCOPE_TEAM = 'TEAM';
    private static final String SCOPE_BRANCH = 'BRANCH';
    private static final String SCOPE_NONE = 'NONE';
    private static final Set<String> DASHBOARD_PROFILE_NAMES = new Set<String>{
        'Director',
        'Subdirector',
        'Director Privada',
        'Subdirector Privada',
        'Director Wealth Management',
        'Subdirector Wealth Management',
        'System Administrator',
        'Administrador del sistema'
    };

    public class MotivoSlice {
        @AuraEnabled public String label;
        @AuraEnabled public Integer count;
        @AuraEnabled public Decimal percentage;
    }

    public class DashboardResponse {
        @AuraEnabled public Date generatedDate;
        @AuraEnabled public Integer totalPilotClients;
        @AuraEnabled public Integer totalActivities;
        @AuraEnabled public Integer highRiskClientsWithActivity;
        @AuraEnabled public Decimal highRiskAssignedPct;
        @AuraEnabled public Integer positiveActivities;
        @AuraEnabled public Integer negativeActivities;
        @AuraEnabled public Integer noContactActivities;
        @AuraEnabled public Integer pendingActivities;
        @AuraEnabled public Decimal avgContactDays;
        @AuraEnabled public Decimal effectiveContactRate;
        @AuraEnabled public Decimal churnVariationPct;
        @AuraEnabled public String pilotPopulationDefinition;
        @AuraEnabled public Id highRiskReportId;
        @AuraEnabled public Id activitiesReportId;
        @AuraEnabled public Boolean hasDashboardAccess;
        @AuraEnabled public List<MotivoSlice> motivoFuga;
    }

    private class UserScope {
        public String scopeType = SCOPE_ALL;
        public String advisorId;
        public Set<String> advisorIds;
        public Id branchUnitId;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardResponse getDashboardData() {
        String currentProfileName = getCurrentUserProfileName();
        if (!Test.isRunningTest() && !DASHBOARD_PROFILE_NAMES.contains(currentProfileName)) {
            DashboardResponse restrictedResponse = new DashboardResponse();
            restrictedResponse.hasDashboardAccess = false;
            return restrictedResponse;
        }

        Id antiChurnRecordTypeId = getAntiChurnTaskRecordTypeId();
        UserScope userScope = getCurrentUserScope();

        DashboardResponse response = new DashboardResponse();
        response.hasDashboardAccess = true;
        response.generatedDate = System.today();
        response.pilotPopulationDefinition =
            'Clientes del piloto = cuentas distintas con actividad Anti-Churn abierta o completada y AccountId informado.';
        response.totalPilotClients = getDistinctAccountCount(antiChurnRecordTypeId, null, userScope);
        response.totalActivities = getTaskCount(antiChurnRecordTypeId, userScope);
        response.highRiskClientsWithActivity = getDistinctAccountCount(antiChurnRecordTypeId, 'Alto', userScope);
        response.highRiskAssignedPct = calculatePercentage(
            response.highRiskClientsWithActivity,
            response.totalPilotClients
        );

        Map<String, Integer> countsByResult = getCountsByResult(antiChurnRecordTypeId, userScope);
        response.positiveActivities = countsByResult.get(RESULT_POSITIVE);
        response.negativeActivities = countsByResult.get(RESULT_NEGATIVE);
        response.noContactActivities = countsByResult.get(RESULT_NO_CONTACT);
        response.pendingActivities = countsByResult.get(RESULT_PENDING);
        response.avgContactDays = getAverageContactDays(antiChurnRecordTypeId, userScope);
        response.effectiveContactRate = calculatePercentage(
            response.positiveActivities + response.negativeActivities,
            response.totalPilotClients
        );

        // Requirement provided as generated / retained * 100.
        response.churnVariationPct = calculatePercentage(
            response.totalActivities,
            response.positiveActivities
        );
        response.motivoFuga = getMotivoSlices(antiChurnRecordTypeId, userScope);

        Map<String, Id> reportIdsByDeveloperName = getReportIdsByDeveloperName(new Set<String>{
            'Clientes_con_alto_riesgo_de_fuga_hh1',
            'Clientes_con_alto_riesgo_de_fuga_ANM'
        });
        response.highRiskReportId = reportIdsByDeveloperName.get('Clientes_con_alto_riesgo_de_fuga_hh1');
        response.activitiesReportId = reportIdsByDeveloperName.get('Clientes_con_alto_riesgo_de_fuga_ANM');
        return response;
    }

    private static String getCurrentUserProfileName() {
        return [
            SELECT Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].Profile.Name;
    }

    private static Id getAntiChurnTaskRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task'
                AND DeveloperName = 'Anti_Churn'
            LIMIT 1
        ].Id;
    }

    private static Integer getDistinctAccountCount(Id recordTypeId, String riskLevel, UserScope userScope) {
        if (userScope.scopeType == SCOPE_NONE) {
            return 0;
        }

        AggregateResult[] results;
        if (userScope.scopeType == SCOPE_ADVISOR && String.isBlank(riskLevel)) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
            ];
        } else if (userScope.scopeType == SCOPE_ADVISOR) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
                    AND Account.Indicador_de_Riesgo_Churn__c = :riskLevel
            ];
        } else if (userScope.scopeType == SCOPE_TEAM && String.isBlank(riskLevel)) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
            ];
        } else if (userScope.scopeType == SCOPE_TEAM) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
                    AND Account.Indicador_de_Riesgo_Churn__c = :riskLevel
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH && String.isBlank(riskLevel)) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
                    AND Account.Indicador_de_Riesgo_Churn__c = :riskLevel
            ];
        } else if (String.isBlank(riskLevel)) {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
            ];
        } else {
            results = [
                SELECT COUNT_DISTINCT(AccountId) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.Indicador_de_Riesgo_Churn__c = :riskLevel
            ];
        }

        return toInteger(results[0].get('total'));
    }

    private static Integer getTaskCount(Id recordTypeId, UserScope userScope) {
        if (userScope.scopeType == SCOPE_NONE) {
            return 0;
        }

        AggregateResult[] results;
        if (userScope.scopeType == SCOPE_ADVISOR) {
            results = [
                SELECT COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
            ];
        } else if (userScope.scopeType == SCOPE_TEAM) {
            results = [
                SELECT COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH) {
            results = [
                SELECT COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
            ];
        } else {
            results = [
                SELECT COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
            ];
        }

        return toInteger(results[0].get('total'));
    }

    private static Map<String, Integer> getCountsByResult(Id recordTypeId, UserScope userScope) {
        Map<String, Integer> counts = new Map<String, Integer>{
            RESULT_POSITIVE => 0,
            RESULT_NEGATIVE => 0,
            RESULT_NO_CONTACT => 0,
            RESULT_PENDING => 0
        };

        if (userScope.scopeType == SCOPE_NONE) {
            return counts;
        }

        List<AggregateResult> groupedResults;
        if (userScope.scopeType == SCOPE_ADVISOR) {
            groupedResults = [
                SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
                GROUP BY Resultado_de_Gestion__c
            ];
        } else if (userScope.scopeType == SCOPE_TEAM) {
            groupedResults = [
                SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
                GROUP BY Resultado_de_Gestion__c
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH) {
            groupedResults = [
                SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
                GROUP BY Resultado_de_Gestion__c
            ];
        } else {
            groupedResults = [
                SELECT Resultado_de_Gestion__c resultValue, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                GROUP BY Resultado_de_Gestion__c
            ];
        }

        for (AggregateResult groupedResult : groupedResults) {
            String resultValue = (String) groupedResult.get('resultValue');
            if (counts.containsKey(resultValue)) {
                counts.put(resultValue, toInteger(groupedResult.get('total')));
            }
        }

        return counts;
    }

    private static Decimal getAverageContactDays(Id recordTypeId, UserScope userScope) {
        if (userScope.scopeType == SCOPE_NONE) {
            return 0;
        }

        AggregateResult[] results;
        if (userScope.scopeType == SCOPE_ADVISOR) {
            results = [
                SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Tiempo_promedio_de_contacto_CHURN__c != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
            ];
        } else if (userScope.scopeType == SCOPE_TEAM) {
            results = [
                SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
                    AND Tiempo_promedio_de_contacto_CHURN__c != null
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH) {
            results = [
                SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Tiempo_promedio_de_contacto_CHURN__c != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
            ];
        } else {
            results = [
                SELECT AVG(Tiempo_promedio_de_contacto_CHURN__c) averageDays
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Tiempo_promedio_de_contacto_CHURN__c != null
            ];
        }

        return toDecimal(results[0].get('averageDays'));
    }

    private static List<MotivoSlice> getMotivoSlices(Id recordTypeId, UserScope userScope) {
        if (userScope.scopeType == SCOPE_NONE) {
            return new List<MotivoSlice>();
        }

        List<AggregateResult> groupedResults;
        if (userScope.scopeType == SCOPE_ADVISOR) {
            groupedResults = [
                SELECT Motivo_de_fuga__c reason, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Motivo_de_fuga__c != null
                    AND Account.ID_ASESOR__c = :userScope.advisorId
                GROUP BY Motivo_de_fuga__c
                ORDER BY COUNT(Id) DESC, Motivo_de_fuga__c ASC
            ];
        } else if (userScope.scopeType == SCOPE_TEAM) {
            groupedResults = [
                SELECT Motivo_de_fuga__c reason, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Account.ID_ASESOR__c IN :userScope.advisorIds
                    AND Motivo_de_fuga__c != null
                GROUP BY Motivo_de_fuga__c
            ];
        } else if (userScope.scopeType == SCOPE_BRANCH) {
            groupedResults = [
                SELECT Motivo_de_fuga__c reason, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Motivo_de_fuga__c != null
                    AND Account.BanqueroAsignado__r.BranchUnitId = :userScope.branchUnitId
                GROUP BY Motivo_de_fuga__c
                ORDER BY COUNT(Id) DESC, Motivo_de_fuga__c ASC
            ];
        } else {
            groupedResults = [
                SELECT Motivo_de_fuga__c reason, COUNT(Id) total
                FROM Task
                WHERE RecordTypeId = :recordTypeId
                    AND AccountId != null
                    AND Motivo_de_fuga__c != null
                GROUP BY Motivo_de_fuga__c
                ORDER BY COUNT(Id) DESC, Motivo_de_fuga__c ASC
            ];
        }

        Integer totalMotivos = 0;
        for (AggregateResult groupedResult : groupedResults) {
            totalMotivos += toInteger(groupedResult.get('total'));
        }

        List<MotivoSlice> slices = new List<MotivoSlice>();
        for (AggregateResult groupedResult : groupedResults) {
            MotivoSlice slice = new MotivoSlice();
            slice.label = (String) groupedResult.get('reason');
            slice.count = toInteger(groupedResult.get('total'));
            slice.percentage = calculatePercentage(slice.count, totalMotivos);
            slices.add(slice);
        }

        return slices;
    }

    private static UserScope getCurrentUserScope() {
        User currentUser = [
            SELECT Id, Profile.Name, UserRoleId, UserRole.Name, ID_ASESOR__c, F3_Sucursal__c, REQ36_Centro_Financiero__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        List<Banker> bankers = [
            SELECT Id, CurrentBranchId
            FROM Banker
            WHERE UserOrContactId = :currentUser.Id
            LIMIT 1
        ];

        UserScope userScope = new UserScope();
        Boolean isAdvisor = isAdvisorUser(
            currentUser.Profile != null ? currentUser.Profile.Name : null,
            currentUser.UserRole != null ? currentUser.UserRole.Name : null
        );
        Boolean isBranchScopedUser = isBranchScopedUser(
            currentUser.Profile != null ? currentUser.Profile.Name : null,
            currentUser.UserRole != null ? currentUser.UserRole.Name : null
        );

        if (isAdvisor && String.isNotBlank(currentUser.ID_ASESOR__c)) {
            userScope.scopeType = SCOPE_ADVISOR;
            userScope.advisorId = currentUser.ID_ASESOR__c.trim();
            return userScope;
        }

        Set<String> teamAdvisorIds = getAdvisorIdsFromRoleTree(currentUser.UserRoleId);
        if (!teamAdvisorIds.isEmpty() && isBranchScopedUser) {
            userScope.scopeType = SCOPE_TEAM;
            userScope.advisorIds = teamAdvisorIds;
            return userScope;
        }

        if (!bankers.isEmpty() && bankers[0].CurrentBranchId != null) {
            userScope.scopeType = SCOPE_BRANCH;
            userScope.branchUnitId = bankers[0].CurrentBranchId;
        } else {
            Id fallbackBranchUnitId = resolveBranchUnitIdFromUserFields(
                currentUser.F3_Sucursal__c,
                currentUser.REQ36_Centro_Financiero__c
            );
            if (fallbackBranchUnitId != null) {
                userScope.scopeType = SCOPE_BRANCH;
                userScope.branchUnitId = fallbackBranchUnitId;
            } else if (isBranchScopedUser) {
                userScope.scopeType = SCOPE_NONE;
            }
        }

        return userScope;
    }

    private static Boolean isAdvisorUser(String profileName, String roleName) {
        String normalizedProfile = profileName == null ? '' : profileName.trim().toUpperCase();
        String normalizedRole = roleName == null ? '' : roleName.trim().toUpperCase();
        return normalizedProfile.contains('ASESOR')
            || normalizedRole.contains('CONSULTOR')
            || normalizedRole.contains('ASESOR');
    }

    private static Boolean isBranchScopedUser(String profileName, String roleName) {
        String normalizedProfile = profileName == null ? '' : profileName.trim().toUpperCase();
        String normalizedRole = roleName == null ? '' : roleName.trim().toUpperCase();
        return normalizedProfile.contains('DIRECTOR')
            || normalizedProfile.contains('SUBDIRECTOR')
            || normalizedRole.contains('DIRECTOR')
            || normalizedRole.contains('SUBDIRECTOR');
    }

    private static Set<String> getAdvisorIdsFromRoleTree(Id rootRoleId) {
        Set<String> advisorIds = new Set<String>();
        if (rootRoleId == null) {
            return advisorIds;
        }

        Map<Id, List<Id>> childrenByParentRoleId = new Map<Id, List<Id>>();
        for (UserRole roleRecord : [
            SELECT Id, ParentRoleId
            FROM UserRole
            WHERE ParentRoleId != null
        ]) {
            if (!childrenByParentRoleId.containsKey(roleRecord.ParentRoleId)) {
                childrenByParentRoleId.put(roleRecord.ParentRoleId, new List<Id>());
            }
            childrenByParentRoleId.get(roleRecord.ParentRoleId).add(roleRecord.Id);
        }

        Set<Id> roleIds = new Set<Id>{ rootRoleId };
        List<Id> pendingRoleIds = new List<Id>{ rootRoleId };
        while (!pendingRoleIds.isEmpty()) {
            Id currentRoleId = pendingRoleIds.remove(pendingRoleIds.size() - 1);
            for (Id childRoleId : childrenByParentRoleId.containsKey(currentRoleId)
                ? childrenByParentRoleId.get(currentRoleId)
                : new List<Id>()) {
                if (roleIds.add(childRoleId)) {
                    pendingRoleIds.add(childRoleId);
                }
            }
        }

        for (User roleUser : [
            SELECT ID_ASESOR__c
            FROM User
            WHERE IsActive = true
                AND UserRoleId IN :roleIds
                AND ID_ASESOR__c != null
        ]) {
            advisorIds.add(roleUser.ID_ASESOR__c.trim());
        }

        return advisorIds;
    }

    private static Id resolveBranchUnitIdFromUserFields(String branchFieldValue, String centerNameValue) {
        if (String.isBlank(branchFieldValue) && String.isBlank(centerNameValue)) {
            return null;
        }

        String normalizedBranchFieldValue = String.isBlank(branchFieldValue)
            ? null
            : branchFieldValue.trim();
        String normalizedCenterNameValue = String.isBlank(centerNameValue)
            ? null
            : centerNameValue.trim();

        List<BranchUnit> branchUnits = [
            SELECT Id, Name, BranchCode, ExternalId__c, ExternalIdBI__c
            FROM BranchUnit
            WHERE Name = :normalizedCenterNameValue
                OR BranchCode = :normalizedBranchFieldValue
                OR ExternalId__c = :normalizedBranchFieldValue
                OR ExternalIdBI__c = :normalizedBranchFieldValue
            LIMIT 1
        ];

        return branchUnits.isEmpty() ? null : branchUnits[0].Id;
    }

    private static Map<String, Id> getReportIdsByDeveloperName(Set<String> developerNames) {
        Map<String, Id> results = new Map<String, Id>();
        for (Report reportRecord : [
            SELECT Id, DeveloperName
            FROM Report
            WHERE FolderName = :REPORT_FOLDER_NAME
                AND DeveloperName IN :developerNames
        ]) {
            results.put(reportRecord.DeveloperName, reportRecord.Id);
        }

        return results;
    }

    private static Integer toInteger(Object value) {
        if (value == null) {
            return 0;
        }

        return Integer.valueOf(String.valueOf(value));
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return 0;
        }

        return Decimal.valueOf(String.valueOf(value)).setScale(2);
    }

    private static Decimal calculatePercentage(Decimal numerator, Decimal denominator) {
        if (denominator == null || denominator <= 0) {
            return 0;
        }

        Decimal safeNumerator = numerator == null ? 0 : numerator;
        return ((safeNumerator / denominator) * 100).setScale(2);
    }
}
