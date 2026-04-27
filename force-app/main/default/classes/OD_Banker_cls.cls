/**
* @File Name : OD_Banker_cls.cls
* @Description : Clase service para el trigger de Banker OD_Banker_thr.apxc
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 19, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 19, 2024 | Andrés Hernández Ríos | Initial Version
**/
public without sharing class OD_Banker_cls {

    // BANDERA PARA BYPASSAR LA EJECUCIÓN DEL TRIGGER EN ALGUNOS CASOS
    public static Boolean bypassExecutionTriggerBanker = false;

    // BANDERA PARA CREAR UN NUEVO BRANCHUNITBUSINESSMEMBER
    public static Boolean createBranchUnitBusinessMember = false;
    public static Boolean isUser = false;
    public static Boolean isFile = false;

    // OBJETO DE BRANCHUNIT GENERAL
    public static BranchUnit branchGeneral;
        
    // MÉTODO PARA CREAR UN NUEVO BRANCHUNITBUSINESSMEMBER
    public static void createBranchUnitBusinessMember(List<Banker> newListBanker, Map<Id, Banker> oldMap) {
        // MAPA PARA ALMACENAR LA RELACIÓN ENTRE CENTROS FINANCIEROS Y BRANCHUNITBUSINESSMEMBER
        Map<String, Map<String, BranchUnitBusinessMember>> brunitBussMemberMap = new Map<String, Map<String, BranchUnitBusinessMember>>();

        // CONJUNTOS PARA ALMACENAR IDS ÚNICOS DE CENTROS FINANCIEROS, ASESORES, ETC.
        Set<String> uniqueFinancialCenterIds = new Set<String>();
        Set<String> uniqueCFIds = new Set<String>();
        Set<String> uniqueAdvisorIds = new Set<String>();
        
        // RECORRE LOS BANQUEROS EN LA NUEVA LISTA PARA OBTENER LOS IDS NECESARIOS
        for (Banker banker : newListBanker) {
            system.debug('banker.UserOrContactId.getSObjectType():'+banker.UserOrContactId.getSObjectType());
            system.debug('User.sObjectType'+User.sObjectType);
            system.debug('branchGeneral:'+branchGeneral);
            if (banker.UserOrContactId.getSObjectType() == User.sObjectType) {
                system.debug('Es usuario');
                isUser = true;                  
            }
            // SI NO SE HA DEFINIDO UN CENTRO DE SUCURSAL GENERAL, SE PROCESAN LOS CENTROS FINANCIEROS
            if (branchGeneral == null) {
                // COMPARACIÓN DE LOS CENTROS FINANCIEROS Y CAMBIO DE BRANCHID
                if((isUser && String.isNotBlank(banker.CurrentBranchId) && oldMap.get(banker.Id).CurrentBranchId == banker.CurrentBranchId)){
                    return ;
                }
                if (String.isNotBlank(banker.CurrentBranchId) && oldMap.get(banker.Id).CurrentBranchId != banker.CurrentBranchId) {
                    uniqueFinancialCenterIds.add(banker.CurrentBranchId);
                } else if (String.isNotBlank(banker.OD_IdCentroFinanciero__c)) {
                    uniqueCFIds.add(banker.OD_IdCentroFinanciero__c);
                }
            }

            // AÑADE EL ID DEL ASESOR AL CONJUNTO DE ASESORES
            if (String.isNotBlank(banker.ExternalId__c)) {
                uniqueAdvisorIds.add(banker.ExternalId__c);
            }
        }

        // SI HAY CENTROS FINANCIEROS ÚNICOS, SE OBTIENE LA INFORMACIÓN DE LAS SUCURSALES
        if (!uniqueFinancialCenterIds.isEmpty() || (!uniqueCFIds.isEmpty() && uniqueCFIds != null)) {
            branchGeneral = [SELECT Id, Name, ExternalId__c, ExternalIdBI__c FROM BranchUnit WHERE Id IN: uniqueFinancialCenterIds OR (ExternalId__c IN: uniqueCFIds OR ExternalIdBI__c IN: uniqueCFIds)];
        }
        // SI HAY ASESORES ÚNICOS, SE OBTIENE EL MAPEADO DE SUCURSALES POR ASESOR
        if (!uniqueAdvisorIds.isEmpty()) {
            brunitBussMemberMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode2(uniqueAdvisorIds);
        }
        
        // PROCESO PARA CADA BANQUERO EN LA LISTA
        for (Banker banker : newListBanker) {
            if (branchGeneral != null) {
                // COMPARACIÓN Y CAMBIO DE BRANCHUNITBUSSINESSMEMBER SEGÚN LOS CAMBIOS DE SUCURSAL
                if (isUser && oldMap.get(banker.Id).CurrentBranchId != null && banker.CurrentBranchId != null && oldMap.get(banker.Id).CurrentBranchId != banker.CurrentBranchId && brunitBussMemberMap.containsKey(banker.ExternalId__c)) {
                    system.debug('*************ENTRO MANERA MANUAL*********');
                    createBranchUnitBusinessMember = true;
                    banker.CurrentBranchId = null;
                    banker.ExternalId__c = banker.JobCode;
                } else if (oldMap.get(banker.Id).OD_IdCentroFinanciero__c != null && banker.OD_IdCentroFinanciero__c != null && oldMap.get(banker.Id).OD_IdCentroFinanciero__c != banker.OD_IdCentroFinanciero__c && brunitBussMemberMap.containsKey(banker.ExternalId__c)) {
                    system.debug('*************ENTRO MANERA ARCHIVO*********');
                    createBranchUnitBusinessMember = true;
                    isFile = true;
                    banker.CurrentBranchId = null;
                }
                
                String externalId = branchGeneral.ExternalId__c + banker.ExternalId__c;
                String externalIdBI = branchGeneral.ExternalIdBI__c + banker.ExternalId__c;
                // CREACIÓN DE UN NUEVO BRANCHUNITBUSINESSMEMBER SI NO EXISTE
                if ((brunitBussMemberMap.containsKey(banker.ExternalId__c) && isUser) ||
                   (brunitBussMemberMap.containsKey(banker.ExternalId__c) && isFile)) {
                    Map<String, BranchUnitBusinessMember> branchMap = brunitBussMemberMap.get(banker.ExternalId__c);
                    if (!branchMap.containsKey(externalId) && !branchMap.containsKey(externalIdBI)) {
                        system.debug('*************CREANDO BRANCHUNITBUSSINESSMEMBER*************');
                        BranchUnitBusinessMember branchUnitBusinessMember = new BranchUnitBusinessMember();
                        branchUnitBusinessMember.BusinessUnitMemberId = banker.Id;
                        branchUnitBusinessMember.BranchUnitId = branchGeneral.Id;
                        
                        insert branchUnitBusinessMember;
                    }
                }                                
            }
        }
    }

    // MÉTODO PARA PROCESAR LOS NUEVOS PROPIETARIOS EN LEADS Y CONTRACTS
    public static void processToRelatedNewOwner(List<Banker> newListBanker, Map<Id, Banker> oldMap) {

        // MAPAS Y CONJUNTOS PARA ALMACENAR LOS ID Y LOS OBJETOS RELACIONADOS
        Map<String, Map<String, BranchUnitBusinessMember>> brunitBussMemberMap = new Map<String, Map<String, BranchUnitBusinessMember>>();
        Map<String, User> usersByNominaMap = new Map<String, User>();
        Map<String, Contact> contactsByNominaMap = new Map<String, Contact>();
        Map<String, BranchUnit> branchUnitsMap = new Map<String, BranchUnit>();
        
        Map<String, Lead> leadsMap;
        Map<String, Contract> contractsMap;
        Map<Id, BranchUnitBusinessMember> brunitKeysMap;
        
        List<Banker> newListBankerCopy = new List<Banker>();

        // CONJUNTOS PARA ALMACENAR LOS IDS ÚNICOS
        Set<String> uniqueFinancialCenterIds = new Set<String>();
        Set<String> uniqueAdvisorIds = new Set<String>();
        
        // SI EL BYPASS ESTÁ ACTIVADO, NO SE EJECUTA EL TRIGGER
        if (bypassExecutionTriggerBanker) {
            system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN BANKER');
            return;
        }
        
        // RECORRE LOS BANQUEROS EN LA LISTA NUEVA Y RECOPILA LOS IDs NECESARIOS
        for (Banker banker : newListBanker) {    
            if (String.isNotBlank(banker.OD_IdCentroFinanciero__c)) {
                system.debug('*************CENTRO FINANCIERO: ' + banker.OD_IdCentroFinanciero__c);
                uniqueFinancialCenterIds.add(banker.OD_IdCentroFinanciero__c);
            }
            if (String.isNotBlank(banker.ExternalId__c)) {
                system.debug('*************ID ASESOR: ' + banker.ExternalId__c);
                uniqueAdvisorIds.add(banker.ExternalId__c);
            }
        }
        
        // SI HAY CENTROS FINANCIEROS ÚNICOS, SE OBTIENEN LOS DATOS DE SUCURSALES
        if (!uniqueFinancialCenterIds.isEmpty()) {
            branchUnitsMap = Service_Utility_Trigger.getBranchUnits(uniqueFinancialCenterIds);
        }

        // SI HAY ASESORES ÚNICOS, SE OBTIENE INFORMACIÓN RELACIONADA
        if (!uniqueAdvisorIds.isEmpty()) {
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
            brunitBussMemberMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode2(uniqueAdvisorIds);
        }

        // SE PROCESA CADA BANQUERO INDIVIDUALMENTE
        for (Banker banker : newListBanker) {
            if ((isUser && createBranchUnitBusinessMember) || (isFile && createBranchUnitBusinessMember)) {
                if(usersByNominaMap.containsKey(banker.ExternalId__c)){
                    system.debug('*************USUARIO ENCONTRADO ASIGNANDO OWNERID*************');
                    if (brunitBussMemberMap.containsKey(banker.ExternalId__c)) {
                        system.debug('*************TIENE BRANCHUNITBUSSINESS*************');
                        Map<String, BranchUnitBusinessMember> branchMap = brunitBussMemberMap.get(banker.ExternalId__c);
                        
                        // ACTUALIZA EL BANQUERO CON INFORMACIÓN DE USUARIO O CONTACTO
                        updateBankerUserOrContact(banker, usersByNominaMap, branchUnitsMap, branchMap);
                    } else {
                        banker.addError('No encuentra BranchUnitBusinessMember');
                    }
                    
                    // ELIMINA EL CONTACTO SIN LICENCIA SI ES QUE EXISTE
                    if (contactsByNominaMap.containsKey(banker.ExternalId__c)) {
                        deleteRecordsIfExists(banker, contactsByNominaMap);
                    }
                }else{
                    banker.addError('No existe usuario con Id de Asesor, Validar ExternalId de Banker tenga relación algún usuario');
                }                                
            } 
        }                
    }

    // MÉTODO PRINCIPAL PARA PROCESAR LOS CAMBIOS DE BANQUEROS
    public static void processToChangeBankers(List<Banker> newListBanker) {

        // MAPAS Y CONJUNTOS PARA ALMACENAR LA INFORMACIÓN RELACIONADA
        Map<String, User> usersByNominaMap = new Map<String, User>();
        Map<String, Contact> contactsByNominaMap = new Map<String, Contact>();
        Map<String, BranchUnit> branchUnitsMap = new Map<String, BranchUnit>();
        
        Set<String> uniqueFinancialCenterIds = new Set<String>();
        Set<String> uniqueAdvisorIds = new Set<String>();

        // RECOPILAR IDS DE CENTROS FINANCIEROS Y ASESORES
        for (Banker banker : newListBanker) {
            if (String.isNotBlank(banker.OD_IdCentroFinanciero__c)) {
                system.debug('*************CENTRO FINANCIERO: ' + banker.OD_IdCentroFinanciero__c);
                uniqueFinancialCenterIds.add(banker.OD_IdCentroFinanciero__c);
            }
            if (String.isNotBlank(banker.ExternalId__c)) {
                system.debug('*************ID ASESOR: ' + banker.ExternalId__c);
                uniqueAdvisorIds.add(banker.ExternalId__c);
            }
        }

        // OBTENER INFORMACIÓN DE SUCURSALES Y ASESORES
        if (!uniqueFinancialCenterIds.isEmpty()) {
            branchUnitsMap = Service_Utility_Trigger.getBranchUnits(uniqueFinancialCenterIds);
        }
        if (!uniqueAdvisorIds.isEmpty()) {
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
        }

        // PROCESAR CADA BANQUERO INDIVIDUALMENTE
        for (Banker banker : newListBanker) {
            banker.ExternalId__c = banker.JobCode;
            if(!uniqueFinancialCenterIds.isEmpty() && !uniqueAdvisorIds.isEmpty()){
                processBanker(banker, branchUnitsMap, usersByNominaMap, contactsByNominaMap);
            }
        }
    }

    // MÉTODO PARA PROCESAR CADA BANQUERO INDIVIDUALMENTE
    private static void processBanker(Banker banker, Map<String, BranchUnit> branchUnitsMap, Map<String, User> usersByNominaMap, Map<String, Contact> contactsByNominaMap) {
        // ACTUALIZAR BANQUERO CON INFORMACIÓN DE USUARIO O CONTACTO
        if (usersByNominaMap.containsKey(banker.ExternalId__c)) {
            system.debug('*************ENCUENTRA EL USUARIO CON EL ID_ASESOR*************');
            updateBankerWithUserInfo(banker, usersByNominaMap, branchUnitsMap, contactsByNominaMap);
        }
        else if (contactsByNominaMap.containsKey(banker.ExternalId__c)) {
            system.debug('*************ENCUENTRE EL CONTACTO SIN LICENCIA CON EL ID_ASESOR*************');
            updateBankerWithContactInfo(banker, contactsByNominaMap, branchUnitsMap);
        }
        else {
            system.debug('*************NO SE ENCUENTRA NI USUARIO NI CONTACTO*************');
            createAndAssignNewContact(banker, branchUnitsMap);
        }
    }

    // ACTUALIZAR BANQUERO CON LA INFORMACIÓN DEL USUARIO ENCONTRADO
    private static void updateBankerWithUserInfo(Banker banker, Map<String, User> usersByNominaMap, Map<String, BranchUnit> branchUnitsMap, Map<String, Contact> contactsByNominaMap) {
        User user = usersByNominaMap.get(banker.ExternalId__c);
        assignBranchUnitToBanker(banker, branchUnitsMap);
        
        banker.JobCode = banker.ExternalId__c;
        banker.UserOrContactId = user.Id;
    }

    // ACTUALIZAR EL BANQUERO CON LA INFORMACIÓN DEL CONTACTO EN CASO DE ENCONTRARLO
    private static void updateBankerWithContactInfo(Banker banker, Map<String, Contact> contactsByNominaMap, Map<String, BranchUnit> branchUnitsMap) {
        Contact contact = contactsByNominaMap.get(banker.ExternalId__c);

        assignBranchUnitToBanker(banker, branchUnitsMap);

        banker.JobCode = banker.ExternalId__c;
        banker.UserOrContactId = contact.Id;
    }

    // CREAR UN CONTACTO SI NO ENCUENTRA EL USUARIO O EL CONTACTO
    private static void createAndAssignNewContact(Banker banker, Map<String, BranchUnit> branchUnitsMap) {
        Contact newContact = createTemporaryContact(banker);

        assignBranchUnitToBanker(banker, branchUnitsMap);

        banker.JobCode = banker.ExternalId__c;
        banker.UserOrContactId = newContact.Id;
    }

    // ASIGNAR LA UNIDAD DE SUCURSAL AL BANQUERO (EXISTENTE O NUEVO)
    private static void assignBranchUnitToBanker(Banker banker, Map<String, BranchUnit> branchUnitsMap) {
        BranchUnit branchUnit;
        
        // SI SE ENCUENTRA UNA SUCURSAL, SE ASIGNA AL BANQUERO
        if (branchUnitsMap.containsKey(banker.OD_IdCentroFinanciero__c)) {
            system.debug('*************SE ENCUENTRA BRANCH UNIT*************');
            branchUnit = branchUnitsMap.get(banker.OD_IdCentroFinanciero__c);
        } else {
            system.debug('*************NO SE ENCUENTRA BRANCH UNIT*************');
            branchUnit = createBranchUnit(banker);
        }

        banker.CurrentBranchId = branchUnit.Id;
    }

    // CREAR UN NUEVO CENTRO FINANCIERO
    private static BranchUnit createBranchUnit(Banker banker) {
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = banker.OD_NombreCentroFinanciero__c;
        branchUnit.IsActive = true;
        branchUnit.ExternalIdBI__c = banker.OD_IdCentroFinanciero__c;
        branchUnit.BranchCode = banker.OD_IdCentroFinanciero__c;
        insert branchUnit;
        return branchUnit;
    }

    // CREAR UN CONTACTO TEMPORAL SIN LICENCIA
    private static Contact createTemporaryContact(Banker banker) {
        // CREAR EL NOMBRE EN PARTES
        String[] nameParts = banker.Name.split(' ');
        String firstName = '';
        String middleName = '';
        String lastName = 'N/P';
        
        // ASIGNAR LOS COMPONENTES DEL NOMBRE
        if (nameParts.size() == 1) {
            lastName = nameParts[0];
        } else if (nameParts.size() == 2) {
            firstName = nameParts[0];
            lastName = nameParts[1];
        } else if (nameParts.size() == 3) {
            firstName = nameParts[0];
            middleName = nameParts[1];
            lastName = nameParts[2];
        } else if (nameParts.size() > 3) {
            firstName = nameParts[0];
            middleName = nameParts[1];
            lastName = nameParts[2] + ' ' + nameParts[3];
        }

        // CREAR Y RETORNAR EL CONTACTO
        Contact contact = new Contact();
        contact.FirstName = firstName;
        contact.MiddleName = middleName;
        contact.LastName = lastName;
        contact.NumeroNomina__c = banker.ExternalId__c;
        contact.EmpleadoSinLicenciaSFDC__c = true;
        contact.RecordTypeId = Service_Utility_Trigger.rtBankerWithoutLicense;
        insert contact;

        return contact;
    }

    // ELIMINAR EL CONTACTO EN CASO DE EXISTIR
    private static void deleteRecordsIfExists(Banker banker, Map<String, Contact> contactsByNominaMap) {        
        Contact deleteContact = contactsByNominaMap.get(banker.ExternalId__c);
        delete deleteContact;        
    }

    // ACTUALIZAR EL BANQUERO Y SU INFORMACIÓN DE BRANCHUNITBUSINESSMEMBER
    private static void updateBankerUserOrContact(Banker banker, Map<String, User> usersByNominaMap, Map<String, BranchUnit> branchUnitsMap, Map<String, BranchUnitBusinessMember> branchMap) {
        system.debug('********ENTRO A updateBankerUserOrContact');
        bypassExecutionTriggerBanker = true;

        // ACTUALIZAR EL BANQUERO CON EL NUEVO USUARIO O CONTACTO Y SU BRANCHUNITBUSINESSMEMBER
        BranchUnitBusinessMember branchUnitBusinessMember = new BranchUnitBusinessMember();
        String externalId = branchGeneral.ExternalId__c + banker.ExternalId__c;
        String externalIdBI = branchGeneral.ExternalIdBI__c + banker.ExternalId__c;
        
        // SE ACTUALIZA EL BANQUERO PARA QUE TOME EN CUENTA AL USUARIO EN EL OBJETO BRANCHUNITBUSSINESSMEMBER
        Banker bankerNull = new Banker();
        bankerNull.Id = banker.Id;
        bankerNull.UserOrContactId = usersByNominaMap.get(banker.ExternalId__c).Id;
        bankerNull.CurrentBranchId = null;
        update bankerNull; 

        // PROCESAR LA CREACIÓN O ACTUALIZACIÓN DE BRANCHUNITBUSINESSMEMBER
        if (createBranchUnitBusinessMember) {
            system.debug('*************HAY CAMBIO DE BRANCHUNIT*************');
            if (branchMap.containsKey(externalId) || branchMap.containsKey(externalIdBI)) {
                for (BranchUnitBusinessMember b : branchMap.values()) {
                    if (externalId == b.ExternalId__c || externalIdBI == b.ExternalIdBI__c) {
                        system.debug('*************ACTIVANDO BRANCHUNITBUSSINESSMEMBER*************' + b.Name);
                        b.IsActive = true;
                    }
                    update b;
                }
            }
        }

        // ACTUALIZAR EL BANQUERO CON SU NUEVO BRANCHUNIT
        Banker bankerBranchUnit = new Banker();
        bankerBranchUnit.Id = banker.Id;
        bankerBranchUnit.UserOrContactId = usersByNominaMap.get(banker.ExternalId__c).Id;
        bankerBranchUnit.CurrentBranchId = createBranchUnitBusinessMember ? branchGeneral.Id : branchUnitsMap.get(banker.OD_IdCentroFinanciero__c).Id;
        update bankerBranchUnit;

        createBranchUnitBusinessMember = false;
    }
}