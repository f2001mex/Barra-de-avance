/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase utilidad del proyecto de post venta.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_UtilityClass {
    
    public static final String DEVELOPERNAME_PROPUESTA_INVERSION = Label.PropuestaInversion_DN;
    public static final String DEVELOPERNAME_PLANEACION_FINANCIERA = Label.PlaneacionFinanciera_DN;
    public static final String DEVELOPERNAME_BIOMETRICOS = Label.RemediacionBiometricos_DN;
    public static final String DEVELOPERNAME_BANCA_ELECTRONICA = Label.EnrolamientoBancaElectronica_DN;
    

    public static Set<String> splitValuesMultiPickList(String strMultiPickList) {
        Set<String> values = new Set<String>();
        if(String.isNotBlank(strMultiPickList)) {
            strMultiPickList = strMultiPickList.replaceAll(' ', '');
            values.addAll(strMultiPickList.split(';'));
        }
        return values;
    }

    public static Date agregarDiasLaborales(Date fechaInicio, Integer diasAAgregar, Id businessHoursId) {
        Datetime fechaActual = DateTime.newInstance(
            fechaInicio.year(), 
            fechaInicio.month(), 
            fechaInicio.day(), 
            12, 0, 0 // Hora del mediodía
        );
        
        Integer diasAgregados = 0;
        
        while(diasAgregados < diasAAgregar) {
            fechaActual = fechaActual.addDays(1);
            
            if(BusinessHours.isWithin(businessHoursId, fechaActual)) {
                diasAgregados++;
            }
            
            if(diasAgregados > 365) break;
        }
        
        
        return fechaActual.date();
    }

    public static Long obtenerDiasLaboralesEntreFechas(Date startDate, Date endDate, Id businessHoursId) {
            
        Datetime startDt = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDt = Datetime.newInstance(endDate, Time.newInstance(0, 0, 0, 0));
        
        Long diffMillisec = BusinessHours.diff(businessHoursId, startDt, endDt);
        return diffMillisec / (8 * 60 * 60 * 1000);
    }
}