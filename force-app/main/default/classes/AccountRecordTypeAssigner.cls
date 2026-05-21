public class AccountRecordTypeAssigner {

    public static void apply(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        // 1) OwnerIds
        Set<Id> ownerIds = new Set<Id>();
        for (Account a : newList) {
            if (a.OwnerId != null) ownerIds.add(a.OwnerId);
        }
        if (ownerIds.isEmpty()) return;

        // 2) Users -> ID_ASESOR__c
        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, ID_ASESOR__c
            FROM User
            WHERE Id IN :ownerIds
        ]);

        // 3) Nominas
        Set<String> nominas = new Set<String>();
        for (User u : usersById.values()) {
            if (String.isNotBlank(u.ID_ASESOR__c)) nominas.add(u.ID_ASESOR__c.trim());
        }

        // 4) Bankers por ExternalId__c (nomina)
        Map<String, Banker> bankerByNomina = new Map<String, Banker>();
        if (!nominas.isEmpty()) {
            for (Banker b : [
                SELECT ExternalId__c, Division__c
                FROM Banker
                WHERE ExternalId__c IN :nominas
            ]) {
                bankerByNomina.put(b.ExternalId__c, b);
            }
        }

        // 5) Caches CMDT
        Map<String, String> divisionToDev = getDivisionToRtDevName();
        Map<String, String> defaults = getDefaults();
        Map<String, Id> rtIds = getAccountRtIds();

        for (Account a : newList) {
            Account oldA = (oldMap == null ? null : oldMap.get(a.Id));

        Boolean shouldRecalc =
        oldMap == null ||                // insert
        a.RecordTypeId == null ||        // sin RT
        (oldA != null && a.OwnerId != oldA.OwnerId) ||                // cambió owner
        (oldA != null && a.ID_ASESOR__c != oldA.ID_ASESOR__c);        // ✅ cambió asesor

            if (!shouldRecalc) continue;

            User u = usersById.get(a.OwnerId);
            String nomina = (u != null) ? u.ID_ASESOR__c : null;

            String targetDevName;

            // División
            if (String.isNotBlank(nomina)) {
                Banker b = bankerByNomina.get(nomina.trim());
                if (b != null && String.isNotBlank(b.Division__c)) {
                    targetDevName = divisionToDev.get(b.Division__c.trim());
                }
            }

            // Fallback
            if (String.isBlank(targetDevName)) {
                String key = a.IsPersonAccount ? 'DEFAULT_PERSON' : 'DEFAULT_BUSINESS';
                targetDevName = defaults.get(key);
            }

            Id rtId = rtIds.get(targetDevName);
            if (rtId != null) {
                a.RecordTypeId = rtId;
            }
        }
    }

    private static Map<String, String> getDivisionToRtDevName() {
        Map<String, String> m = new Map<String, String>();
        for (AdvisorDivision_RecordType__mdt r : [
            SELECT Division__c, RecordTypeDeveloperName__c
            FROM AdvisorDivision_RecordType__mdt
        ]) {
            if (String.isNotBlank(r.Division__c)) {
                m.put(r.Division__c.trim(), r.RecordTypeDeveloperName__c);
            }
        }
        return m;
    }

    private static Map<String, String> getDefaults() {
        Map<String, String> m = new Map<String, String>();
        for (Account_RecordType_Config__mdt r : [
            SELECT Key__c, RecordTypeDeveloperName__c
            FROM Account_RecordType_Config__mdt
        ]) {
            m.put(r.Key__c, r.RecordTypeDeveloperName__c);
        }
        return m;
    }

    private static Map<String, Id> getAccountRtIds() {
        Map<String, Id> m = new Map<String, Id>();
        for (Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfos()) {
            if (rti.isAvailable()) {
                m.put(rti.getDeveloperName(), rti.getRecordTypeId());
            }
        }
        return m;
    }
}
