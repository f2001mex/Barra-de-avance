/****************************************************************************************************
Desarrollado por : VASS MÉXICO
Proyecto         : Actinver - Bitácora
Descripción      : Clase test para la clase ACTINVER_UtilityFactory_utils
*/
@isTest
public class ACTINVER_UtilityFactory_utils_tst {
    @isTest
    static void getValueFieldSet() {
        ACTINVER_UtilityFactory_utils.getRecodType('Lead', 'WealthManagement');
        List<ACTINVER_UtilityFactory_utils.WrapperValueFieldSet> result = ACTINVER_UtilityFactory_utils.getValueFieldSet('MandatoryFieldsToIntegrateSAP', 'Lead');
    }
    @isTest
    static void test_formatDate(){
        ACTINVER_UtilityFactory_utils.formatDate(System.today(), true);
    }
    @isTest
    static void test_formatTime(){
        ACTINVER_UtilityFactory_utils.formatTime(System.today());
    }
    @isTest
    static void test_calcularEdad(){
        ACTINVER_UtilityFactory_utils.calcularEdad(System.today().addYears(-30));
    }
}