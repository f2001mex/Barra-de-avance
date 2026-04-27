/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
* Project           :   Post Venta
* Clase principal   :   PSTA_RegistroResumenGlobal_sch
*******************************************************************************/
@isTest
public  class PSTA_RegistroResumenGlobal_sch_tst {
    @isTest
    static void test_execute(){
        Test.startTest();
        PSTA_RegistroResumenGlobal_sch sch = new PSTA_RegistroResumenGlobal_sch();
        sch.execute(null);
        Test.stopTest();
    }
}