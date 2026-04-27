/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase test de la clase SCH_ObtieneMotivoVisita_cls

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2025-01-13      Salvador Ramírez	    Creación de la Clase.
*/
@IsTest
public class SCH_ObtieneMotivoVisita_Test {
    @isTest
    static void test_obtieneMotivoDeSubmotivo(){
        SCH_ObtieneMotivoVisita_cls.data obj = new SCH_ObtieneMotivoVisita_cls.data();
        List<SCH_ObtieneMotivoVisita_cls.data> lstData = new List<SCH_ObtieneMotivoVisita_cls.data>();
        obj.submotivo = 'Información general';
        lstData.add(obj);
        test.startTest();
        Object res = SCH_ObtieneMotivoVisita_cls.obtieneMotivoDeSubmotivo(lstData);
        test.stopTest();
    }
    @isTest
    static void test_obtieneMotivoDeSubmotivo2(){
        SCH_ObtieneMotivoVisita_cls.data obj = new SCH_ObtieneMotivoVisita_cls.data();
        List<SCH_ObtieneMotivoVisita_cls.data> lstData = new List<SCH_ObtieneMotivoVisita_cls.data>();
        obj.submotivo = 'Pruebas';
        lstData.add(obj);
        test.startTest();
        Object res = SCH_ObtieneMotivoVisita_cls.obtieneMotivoDeSubmotivo(lstData);
        test.stopTest();
    }
}