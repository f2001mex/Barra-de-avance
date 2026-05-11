@isTest
private class PV_GenTarPerSelX_Test {
    @isTest
    static void testGetAccountsWithValidContracts() {
        Set<Id> result = PV_GenerarTareasPeriodicasSelector_cls.getAccountsWithValidContracts(
            new Set<Id>{ Id.valueOf('001000000000001AAA') },
            new Set<String>{ '01' },
            new Set<String>{ 'Nuevo' }
        );
        System.assertNotEquals(null, result);

        System.assertEquals(
            0,
            PV_GenerarTareasPeriodicasSelector_cls.getAccountsWithValidContracts(
                null,
                new Set<String>{ '01' },
                new Set<String>{ 'Nuevo' }
            ).size()
        );

        System.assertEquals(
            0,
            PV_GenerarTareasPeriodicasSelector_cls.getAccountsWithValidContracts(
                new Set<Id>{ Id.valueOf('001000000000001AAA') },
                new Set<String>(),
                new Set<String>{ 'Nuevo' }
            ).size()
        );
    }
}
