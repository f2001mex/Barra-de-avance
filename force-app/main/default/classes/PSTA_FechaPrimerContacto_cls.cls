/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   PSTA_FechaPrimerContacto_cls_tst
* Description       :   Clase helper que actualiza la fecha de ultimo contacto de la cuenta en caso de no tener con la fecha de apertura del primer contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_FechaPrimerContacto_cls {

    public static List<Account> procesarFechas(List<Account> lstCuentas) {

        
        for(Account cuenta : lstCuentas) {
            System.debug('#Contratos: '+cuenta.contracts.size());
            
            Banker banker = (Banker)cuenta.BanqueroAsignado__r.BusinessUnitMember;
            if (PSTA_Segmentacion_cls.determinarSegmento(banker) == null) {
                continue;
            }

            cuenta.Segmento__c = PSTA_Segmentacion_cls.determinarSegmento(banker);
            if(cuenta.contracts.size() > 0) {
                Decimal saldoTotal = 0;
                for(Contract contrato : cuenta.contracts) {
                    saldoTotal += Decimal.valueOf(contrato.Saldo__c);
                }

                cuenta.SaldoIntegral__c = saldoTotal;
            

                Date fechaMasAntigua = cuenta.contracts[0].AccountOpeningDate__c;
                cuenta.FechaAntiguedad__c = fechaMasAntigua;

                if(cuenta.FechaUltimoContacto__c == null) {
                    cuenta.FechaUltimoContacto__c   = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimoContacto__c;
                    cuenta.FechaUltimaVisita__c     = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimaVisita__c;
                }
                
            }


            cuenta.ContactoPriorizadoEsteMes__c = false;
            cuenta.PriorizacionContacto__c      = false;
            cuenta.PriorizacionVisita__c        = false;

        }
        return lstCuentas;
    }
    
    

}