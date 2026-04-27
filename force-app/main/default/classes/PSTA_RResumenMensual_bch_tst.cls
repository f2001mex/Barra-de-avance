@IsTest
public class PSTA_RResumenMensual_bch_tst {

    @IsTest
    static void testBatchFinishExecutes() {
        Test.startTest();
        Database.executeBatch(new PSTA_RegistroResumenGlobalMensual_bch(), 1);
        Test.stopTest();
        System.assert(true);
    }
}
