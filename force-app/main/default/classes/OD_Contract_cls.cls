/**
* @File Name : OD_Contract_cls.cls
* @Description : Clase service para el trigger de Banker OD_Contract_thr.apxc
* @Author : Andrés Hernandez Rios
* @Last Modified By : 
* @Last Modified On : November 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 8, 2024 | Andrés Hernández Ríos | Initial Version
**/
public without sharing class OD_Contract_cls {
    public static Boolean bypassTriggerExecution = false;
    public static final Set<String> excludedStatus = new Set<String>(Label.StatusContract.split(';'));
    
    // MÉTODO QUE PROCESA UNA LISTA DE CONTRATOS (CONTRACT) PARA CAMBIAR EL PROPIETARIO (OWNERID) Y LLENAR EL CAMPO BANQUERO.
    public static void processToChangeOwnerContract(List<Contract> newListContract) {
        
        // MAPAS PARA ALMACENAR INFORMACIÓN RELACIONADA CON LOS ASESORES, USUARIOS, CUENTAS Y CONTACTOS.
        Map<String,BranchUnitBusinessMember> bankersBranchUnitMap = new Map<String,BranchUnitBusinessMember>();
        Map<String,User> usersByNominaMap = new Map<String,User>();
        Map<String,Contact> contactsByNominaMap = new Map<String,Contact>();
        
        // CONJUNTOS PARA ALMACENAR LOS IDs DE LAS CUENTAS A PROCESAR.
        Set<String> uniqueAdvisorIds = new Set<String>();
        
        // SI EL FLAG BYPASS ESTÁ ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN LOS CONTRATOS.
        if (bypassTriggerExecution) {
            system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN CONTRATOS');
            return;
        }
        
        // ITERA SOBRE LOS CONTRATOS RECIBIDOS EN LA LISTA NUEVA (newListContract).
        for(Contract ctc : newListContract){
            
            // SOLO PROCESA CONTRATOS QUE NO ESTÉN CANCELADOS (DENTRO DE LA LABEL ASIGNADA).
            System.debug ('contains=>>' + !excludedStatus.contains(ctc.Status));
			System.debug ('status=>>' + ctc.Status);
			System.debug ('excluded=>>' + excludedStatus);
			System.debug ('idAsesor=>>' + ctc.ID_ASESOR__c);
            if(!excludedStatus.contains(ctc.Status)){                   
                
                // VERIFICA SI EL CAMPO ID_ASESOR__c NO ESTÁ VACÍO Y LO AGREGA AL CONJUNTO DE IDS DE ASESORES.
                if(String.isNotBlank(ctc.ID_ASESOR__c)){
                    system.debug('*************ID_ASESOR__c: '+ctc.ID_ASESOR__c);
                    uniqueAdvisorIds.add(ctc.ID_ASESOR__c);
                }
            }
        }
        
        // SI EL CONJUNTO DE IDS DE ASESORES NO ESTÁ VACÍO, SE CONSULTAN LOS USUARIOS, CONTACTOS Y BRANCH UNITS.
        if(!uniqueAdvisorIds.isEmpty()){
            // LLAMA A MÉTODOS DE UTILIDAD PARA OBTENER LOS USUARIOS Y CONTACTOS CORRESPONDIENTES AL ID DEL ASESOR.
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
            bankersBranchUnitMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode(uniqueAdvisorIds);
        }
        
        // PROCESA NUEVAMENTE LA LISTA DE CONTRATOS PARA REALIZAR LA REASIGNACIÓN DEL PROPIETARIO.
        for(Contract ctc : newListContract){
            
            // SOLO PROCESA CONTRATOS QUE NO ESTÉN CANCELADOS (DENTRO DE LA LABEL ASIGNADA).
            if(!excludedStatus.contains(ctc.Status)){
                System.debug ('users=>>' + usersByNominaMap.containsKey(ctc.ID_ASESOR__c));
				System.debug ('contacts=>>' + contactsByNominaMap.containsKey(ctc.ID_ASESOR__c));
                
                // SI SE ENCUENTRA EL USUARIO EN EL MAPA DE USUARIOS, SE REASIGNA EL PROPIETARIO DEL CONTRATO.
                if(usersByNominaMap.containsKey(ctc.ID_ASESOR__c)){
                    system.debug('*************ENCUENTRA EL USUARIO CON EL ID_ASESOR*************');
                    ctc.OwnerId = usersByNominaMap.get(ctc.ID_ASESOR__c).Id;
                    // SI SE ENCUENTRA LA BRANCHUNITBUSINESS ASOCIADA AL ASESOR, SE ASIGNA Y CAMBIA EL PROPIETARIO.
                    if(bankersBranchUnitMap.containskey(ctc.ID_ASESOR__c)){
                        ctc.BanqueroAsignado__c = bankersBranchUnitMap.get(ctc.ID_ASESOR__c).Id;              
                    }else{
                        // SI NO SE ENCUENTRA LA BRANCH UNIT RELACIONADA, SE AGREGA UN ERROR AL CONTRATO.
                        ctc.adderror('Hay un error en Banker ó no hay relación Id Asesor, favor de verificar');                
                    }                   
                }
                
                // SI NO SE ENCUENTRA EL USUARIO, SE VERIFICA SI EXISTE EL CONTACTO ASOCIADO AL ASESOR.
                else if(contactsByNominaMap.containsKey(ctc.ID_ASESOR__c)){
                    system.debug('*************ENCUENTRE EL CONTACTO SIN LICENCIA CON EL ID_ASESOR*************');   
                    ctc.OwnerId = usersByNominaMap.get(Service_Utility_Trigger.DEFAULT_USER_NAME).Id;                    
                    // SI SE ENCUENTRA LA BRANCHUNITBUSINESS ASOCIADA AL ASESOR, SE ASIGNA Y CAMBIA EL PROPIETARIO.
                    if(bankersBranchUnitMap.containsKey(ctc.ID_ASESOR__c)){
                        ctc.BanqueroAsignado__c = bankersBranchUnitMap.get(ctc.ID_ASESOR__c).Id;
                    }else{
                        // SI NO SE ENCUENTRA LA BRANCH UNIT RELACIONADA, SE AGREGA UN ERROR AL CONTRATO.
                        ctc.adderror('Hay un error en Banker ó no hay relación Id Asesor, favor de verificar (Contacto Temporal)');                
                    }
                }
                
                // SI NO SE ENCUENTRA NI EL USUARIO NI EL CONTACTO, SE AGREGA UN ERROR AL CONTRATO.
                else{
                    ctc.adderror('No se encontro el usuario ni el contacto en algún contrato');                
                }   
            }            
        }
    }  
}