public without sharing class PSTA_ReasignacionAsesorPostventa_cls {

    @TestVisible
    static Boolean bypassRegistration = false;

    public static void registrarCambiosAsesor(List<Account> newAccounts, Map<Id, Account> oldMap) {
        if (bypassRegistration == true ||
            newAccounts == null ||
            newAccounts.isEmpty() ||
            oldMap == null ||
            oldMap.isEmpty()) {
            return;
        }

        List<PSTA_ReasignacionAsesorPostventa__c> recordsToUpsert = new List<PSTA_ReasignacionAsesorPostventa__c>();
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldMap.get(newAccount.Id);
            if (oldAccount == null) {
                continue;
            }

            Boolean ownerChanged = oldAccount.OwnerId != newAccount.OwnerId;
            Boolean advisorChanged = oldAccount.ID_Asesor__c != newAccount.ID_Asesor__c;
            if (!ownerChanged && !advisorChanged) {
                continue;
            }

            recordsToUpsert.add(new PSTA_ReasignacionAsesorPostventa__c(
                ClaveCuenta__c = String.valueOf(newAccount.Id),
                Account__c = newAccount.Id,
                CambioOwner__c = ownerChanged,
                CambioAsesor__c = advisorChanged,
                OwnerAnterior__c = oldAccount.OwnerId,
                OwnerNuevo__c = newAccount.OwnerId,
                AsesorAnterior__c = oldAccount.ID_Asesor__c,
                AsesorNuevo__c = newAccount.ID_Asesor__c,
                FechaCambio__c = System.now(),
                EstatusProceso__c = 'Pendiente',
                DetalleProceso__c = null,
                UltimaEjecucion__c = null,
                Intentos__c = 0
            ));
        }

        if (!recordsToUpsert.isEmpty()) {
            Database.upsert(
                recordsToUpsert,
                PSTA_ReasignacionAsesorPostventa__c.Fields.ClaveCuenta__c,
                false
            );
        }
    }
}
