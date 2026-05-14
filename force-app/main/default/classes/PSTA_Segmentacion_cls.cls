/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase helper que asigna una division o segmento a un cliente
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_Segmentacion_cls {
    
    public static Boolean bypassTriggerExecution = false;

    public static final ConfiguracionActinver__c objConfigPatrimonialReactivo   = PSTA_SegmentacionClientesSelector_cls.getConfiguracionPatrimonialReactivo();

    
    public static void procesarSegmentoPorCambioAsesor(List<Account> lstCuentas, Map<Id, Account> oldCuentas) {

        if (bypassTriggerExecution) {
            system.debug('bypassTriggerExecution true');
            return;
        }

        // 1. Recopilar todos los IDs de BusinessUnitMember (Bankers)
        Set<Id> bankerIds = new Set<Id>();
        for(Account cuentaNueva : lstCuentas) {
            Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
            
            boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
            boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
            
            if((cambioBanquero || cambioOwner) && 
            cuentaNueva.BanqueroAsignado__r != null && 
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
                
                bankerIds.add(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);
            }
        }

        if(bankerIds.isEmpty()) return;

        // 2. Hacer una sola consulta para todos los Bankers
        Map<Id, Banker> bankersMap = new Map<Id, Banker>([
            SELECT Id, Cargo__c, Division__c 
            FROM Banker 
            WHERE Id IN :bankerIds
        ]);
        
        for(Account cuentaNueva : lstCuentas) {
            Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
            
            boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
            boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
        
            if( (cambioBanquero || cambioOwner) && 
            cuentaNueva.BanqueroAsignado__r != null && 
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {

                
                Banker banker = bankersMap.get(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);

                //Banker banker = (Banker)cuentaNueva.BanqueroAsignado__r.BusinessUnitMember;
                String nuevoSegmento = determinarSegmento(banker);
                
                if(nuevoSegmento != null && nuevoSegmento != cuentaOld.Segmento__c) {

                    cuentaNueva.Segmento__c = nuevoSegmento;
                }
            }
        }
        
    }
    
    public static String determinarSegmento(Banker banquero) {

        if (banquero == null) {
            return null;
        }

        String cargoBanquero = banquero.Cargo__c != null ? banquero.Cargo__c.replaceAll(' ', '') : '';
        Set<String> rolesValidosReactivo = objConfigPatrimonialReactivo == null
            ? new Set<String>()
            : PSTA_UtilityClass.splitValuesMultiPickList(objConfigPatrimonialReactivo.Rol__c);
        String resultado;
        
        if (banquero.Division__c != null) {
            resultado = objConfigPatrimonialReactivo != null && rolesValidosReactivo.contains(cargoBanquero)
                ? objConfigPatrimonialReactivo.Segmento__c
                : banquero.Division__c;
            return resultado;
        }
        
        resultado = objConfigPatrimonialReactivo != null && rolesValidosReactivo.contains(cargoBanquero)
            ? objConfigPatrimonialReactivo.Segmento__c
            : null;
        return resultado;

    }

}
