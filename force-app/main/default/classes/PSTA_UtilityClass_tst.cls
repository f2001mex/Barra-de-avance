/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_UtilityClass
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     21-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class PSTA_UtilityClass_tst {

    @isTest
    static void test_splitValuesMultiPickList() {
        String multiPickVal = 'Valor1; Valor2; Valor3';
        Set<String> result = PSTA_UtilityClass.splitValuesMultiPickList(multiPickVal);
        System.assertEquals(3, result.size());
        System.assert(result.contains('Valor1'));
        System.assert(result.contains('Valor2'));
        System.assert(result.contains('Valor3'));
    }

    @isTest
    static void test_agregarDiasLaborales_y_diasLaboralesEntreFechas() {
        Id bhId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;

        Date hoy = Date.today();
        Integer diasSolicitados = 3;

        Date fechaCalculada = PSTA_UtilityClass.agregarDiasLaborales(hoy, diasSolicitados, bhId);
        System.assertNotEquals(null, fechaCalculada, 'La fecha devuelta no debe ser null');

        Long diasCalculados = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(hoy, fechaCalculada, bhId);
        System.assert(diasCalculados >= diasSolicitados, 'Días laborales deben ser al menos los que se pidieron');
    }
}