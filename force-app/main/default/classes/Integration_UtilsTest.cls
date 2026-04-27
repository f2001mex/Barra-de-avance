@isTest
public class Integration_UtilsTest {
    @isTest
    static void tryMethods() {
        Test.startTest();
        String resultado = Integration_Utils.obtenerValorApi('Opportunity', 'StageName', 'Identificar Necesidades');
        resultado = Integration_Utils.obtenerValorApi('Opportunity', 'StageName', 'Inexistente');
        Test.stopTest();
    }
}