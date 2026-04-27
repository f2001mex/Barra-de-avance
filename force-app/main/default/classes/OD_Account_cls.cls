/**
* @File Name : OD_Account_cls.cls
* @Description :Clase service para el trigger de Account OD_Account_thr.apxc
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Account_cls {
    public static Boolean bypassTriggerExecution = false;

    private static Boolean shouldProcessOwnerChange(Account acc, Map<Id,Account> oldMapAccount) {
        if (oldMapAccount == null || !oldMapAccount.containsKey(acc.Id)) {
            return true;
        }

        Account oldAccount = oldMapAccount.get(acc.Id);
        return oldAccount.OwnerId != acc.OwnerId || oldAccount.ID_ASESOR__c != acc.ID_ASESOR__c;
    }
  
    // MÉTODO QUE PROCESA UNA LISTA DE CUENTAS (ACCOUNT) PARA CAMBIAR EL PROPIETARIO (OWNERID) Y LLENAR EL CAMPO BANQUERO.
    public static void processToChangeOwnerFromAccount(List<Account> newListAccount,Map<Id,Account> oldMapAccount) {
        // MAPAS PARA ALMACENAR DATOS RELACIONADOS CON USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER DE LOS BANQUEROS.
        Map<String,BranchUnitBusinessMember> bankersBranchUnitMap = new Map<String,BranchUnitBusinessMember> ();
        Map<String,BranchUnitBusinessMember> bankersBranchUnitOwnerMap = new Map<String,BranchUnitBusinessMember> ();
        Map<String,User> usersByNominaMap = new Map<String,User>();
        Map<String,Contact> contactsByNominaMap = new Map<String,Contact>();
        Map<Id,User> usersByIdMap = new Map<Id,User>();
        
        // CONJUNTOS PARA ALMACENAR LOS ID ÚNICOS DE ASESORES Y PROPIETARIOS.
        Set<String> uniqueAdvisorIds = new Set<String>();
        Set<Id> uniqueOwnerIds = new Set<Id>();
        
        
        // SI EL FLAG BYSPASS ESTÁ ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN LOS CONTRATOS.
        if (bypassTriggerExecution) {
            system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN CUENTAS');
            return;
        }
        
        // ITERAMOS SOBRE CADA CUENTA EN LA LISTA PROPORCIONADA
        for(Account acc : newListAccount){
            // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
            system.debug(Service_Utility_Trigger.isCorrectRecordTypeId(acc));
            if(Service_Utility_Trigger.isCorrectRecordTypeId(acc) && shouldProcessOwnerChange(acc, oldMapAccount)){
                system.debug(acc.ID_ASESOR__c);
                // AGREGAMOS AL CONJUNTO DE ASESORES ÚNICOS SI TIENE EL ID_ASESOR
                if(String.isNotBlank(acc.ID_ASESOR__c)){
                    uniqueAdvisorIds.add(acc.ID_ASESOR__c);
                } 
                // AGREGAMOS AL CONJUNTO DE PROPIETARIOS ÚNICOS SI TIENE EL OWNERID
                if(String.isNotBlank(acc.OwnerId)){
                    uniqueOwnerIds.add(acc.OwnerId);
                }
            }                
        }
        
        // SI HAY PROPIETARIOS ÚNICOS, OBTENEMOS LOS USUARIOS CORRESPONDIENTES.
        if(!uniqueOwnerIds.isEmpty()){
            usersByIdMap = Service_Utility_Trigger.getUsersByOwnerIds(uniqueOwnerIds);
            bankersBranchUnitOwnerMap = Service_Utility_Trigger.getBranchUnitByOwnerId(uniqueOwnerIds);
        }
        
        // SI HAY ASESORES ÚNICOS, OBTENEMOS LOS USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER.
        if(!uniqueAdvisorIds.isEmpty()){
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
            bankersBranchUnitMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode(uniqueAdvisorIds);
        }
        system.debug('bankersBranchUnitOwnerMap'+bankersBranchUnitOwnerMap);
        system.debug('bankersBranchUnitMap:'+bankersBranchUnitMap);
        // PROCESAMOS CADA CUENTA NUEVAMENTE PARA CAMBIAR EL PROPIETARIO Y REALIZAR VALIDACIONES.
        for(Account acc : newListAccount){
            
            // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
            if(Service_Utility_Trigger.isCorrectRecordTypeId(acc) && shouldProcessOwnerChange(acc, oldMapAccount)){
                // SI ENCONTRAMOS EL USUARIO CON EL ID_ASESOR, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
                if(usersByNominaMap.containsKey(acc.ID_ASESOR__c)){

                    if(oldMapAccount != null && oldMapAccount.containsKey(acc.Id) && oldMapAccount.get(acc.Id).OwnerId != acc.OwnerId){
                        system.debug('*************ENCUENTRA EL USUARIO PERO HAY CAMBIO PROPIETARIO*************');
                        acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id; 
                        if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
                            acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
                        }else{
                            acc.addError('Hay un error en Banker ó no hay relación en el cambio de Propietario, favor de verificar');
                        }
                    }else{
                        system.debug('*************ENCUENTRA EL USUARIO CON EL ID_ASESOR*************'+usersByNominaMap.get(acc.ID_ASESOR__c).Name);
                        acc.OwnerId = usersByNominaMap.get(acc.ID_ASESOR__c).Id;  
                        if(bankersBranchUnitMap.containskey(acc.ID_Asesor__c)){
                            acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;              
                        }else{
                            acc.addError('Hay un error en Banker ó no hay relación en la actualización de Id Asesor, favor de verificar');
                        }
                    }
                }   
                
                // SI ENCONTRAMOS EL CONTACTO CON EL ID_ASESOR PERO NO EL USUARIO, VERIFICAMOS SI HAY UNA UNIDAD DE SUCURSAL.
                else if(contactsByNominaMap.containsKey(acc.ID_ASESOR__c)){
                    system.debug('*************ENCUENTRE EL CONTACTO SIN LICENCIA CON EL ID_ASESOR*************');                
                    // SI HAY UNA UNIDAD DE SUCURSAL RELACIONADA CON EL ASESOR, ACTUALIZAMOS LA CUENTA.
                    if(bankersBranchUnitMap.containsKey(acc.ID_ASESOR__c)){
                        acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;
                        acc.OwnerId = usersByNominaMap.get(Service_Utility_Trigger.DEFAULT_USER_NAME).Id;                    
                    } else {
                        // SI NO SE ENCUENTRA LA UNIDAD DE SUCURSAL, AGREGAMOS UN ERROR.
                        acc.addError('Hay un error en Banker ó no hay relación Id Asesor, favor de verificar (Contacto Temporal)');
                    }
                }
                
                // SI ENCONTRAMOS EL USUARIO CON EL OWNERID ORIGINAL, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
                else if(usersByIdMap.containsKey(acc.OwnerId)){
                    system.debug('*************ENCUENTRA EL USUARIO CON EL OWNERID*************');
                    acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id;
                    if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
                        acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
                    }else{
                        acc.addError('Hay un error en Banker ó no hay relación Propietario, favor de verificar');
                    }             
                }
                
                // SI NO SE ENCUENTRA NI EL USUARIO NI EL CONTACTO RELACIONADO, AGREGAMOS UN ERROR.
                else {
                    acc.adderror('No se encontró el usuario ni el contacto de alguna cuenta');                
                }
            }            
        }  
         bypassTriggerExecution = true;
    }
    /**
	 * Check if the total percentage is above 100%
	 */
	public static void checkTotalPercent(List<Account> newListAccount) {
		Decimal decActinverMexico = 0;
		Decimal decActinverMadrid = 0;
		Decimal decActinverSecurities = 0;
		Decimal decInstitucionesNacionales = 0;
		Decimal decInstitucionesInternaciononales = 0;

		for (Account accObj : newListAccount) {
			// if all the fields are null, skip the check
			if (
				accObj.Actinver_Mexico__c == null &&
				accObj.Actinver_Madrid__c == null &&
				accObj.Actinver_Securities__c == null &&
				accObj.Instituciones_Nacionales__c == null &&
				accObj.Instituciones_Internaciononales__c == null
			) {
				continue;
			}

			// Only persona accout need this check
			if (accObj.IsPersonAccount) {
				decActinverMexico = (accObj.Actinver_Mexico__c == null) ? 0 : accObj.Actinver_Mexico__c;
				decActinverMadrid = (accObj.Actinver_Madrid__c == null) ? 0 : accObj.Actinver_Madrid__c;
				decActinverSecurities = (accObj.Actinver_Securities__c == null) ? 0 : accObj.Actinver_Securities__c;
				decInstitucionesNacionales = (accObj.Instituciones_Nacionales__c == null) ? 0 : accObj.Instituciones_Nacionales__c;
				decInstitucionesInternaciononales = (accObj.Instituciones_Internaciononales__c == null)
					? 0
					: accObj.Instituciones_Internaciononales__c;

				if (
					(decActinverMexico +
					decActinverMadrid +
					decActinverSecurities +
					decInstitucionesNacionales +
					decInstitucionesInternaciononales) != 100
				) {
					accObj.addError(Label.CheckTotalPercent);
				}
			}
		}
	}
    public static void createAccounts(List<Account> newListAccount) {
        for (Account a : newListAccount) {
            if (a.Person_Type__c == 'MORAL') {
                a.Name = a.BusinessName__c;
                a.PersonBirthdate = null;
                System.debug(JSON.serializePretty(a));
            }
            if (a.Person_Type__c == 'FISICA') {
                if (a.Nombre_Completo_Actinver__c != null) {
                    a.FirstName = a.Nombre_Completo_Actinver__c.length() >= 40
                        ? a.Nombre_Completo_Actinver__c.substring(0, 39)
                        : a.Nombre_Completo_Actinver__c;
                }
            }
        }
    }
    public static void convertMappingLeadToAccount(List<Account> newListAccount) {
        system.debug('############### convertMappingLeadToAccount ###################');
        Map<String,Lead> mapAccountIdByLeads = new Map<String,Lead>();
        Set<String> setAccountIds = new Set<String>();
        Lead[] lstLead = new List<Lead>();
        for(Account objAccount : newListAccount)  setAccountIds.add(objAccount.ExternalIdLead__c);

        system.debug('#### setAccountIds: '+setAccountIds);
        setAccountIds.remove(null);
        if(!setAccountIds.isEmpty()) lstLead = getLeadByExternalId(setAccountIds);

        if(!lstLead.isEmpty()){
            for(Lead objLead :lstLead) mapAccountIdByLeads.put(objLead.F3_Consecutivo_ID__c,objLead);
            for(Account objAccount : newListAccount) setValuesOfConvertLead(mapAccountIdByLeads, objAccount);
        } 
    }
    public static Lead[] getLeadByExternalId(Set<String> setAccountIds) {
        Lead[] lstLead = [SELECT Id
                    , toLabel(F3_Estado_Civil__c)   //objAccount.MaritalStatus__c
                    , toLabel(Estado_Nacimiento__c) //objAccount.Birth_City__c
                    , toLabel(Gender__c)            //objAccount.Gender__c
                    , toLabel(F3_Nacionalidad__c)   //objAccount.Nationality__c
                    , toLabel(Pais_Nacimiento__c)   //objAccount.Country_Birth__c
                    , toLabel(Tipo_de_Persona__c)   //objAccount.Person_Type__c
                    , F3_Consecutivo_ID__c
                    , Fecha_Nacimiento_Prospecto__c 
                FROM Lead 
                WHERE F3_Consecutivo_ID__c IN :setAccountIds];

        system.debug('#### lstLead: '+lstLead.size());
        return lstLead;
    }
    public static void setValuesOfConvertLead(Map<String,Lead> mapAccountIdByLeads,Account objAccount) {
            Lead objLead = mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) != null ? mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) : new Lead();
            objAccount.MaritalStatus__c = objLead.F3_Estado_Civil__c;
            objAccount.Birth_City__c    = objLead.Estado_Nacimiento__c;
            objAccount.Nationality__c   = objLead.F3_Nacionalidad__c;
            objAccount.Country_Birth__c = objLead.Pais_Nacimiento__c;
            objAccount.Person_Type__c   = objLead.Tipo_de_Persona__c;
            if(objAccount.IsPersonAccount) objAccount.PersonBirthdate = objLead.Fecha_Nacimiento_Prospecto__c;
    }
}
