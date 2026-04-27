public class ASL_LeadsAssignmentChannel_cls {
    public static Boolean bypassTriggerExecution = false;
    public static String LABEL_POSTAL_CODE = 'PostalCode';
    public static String LABEL_GROUP       = 'Group';
    public static String LABEL_DEFAULT     = 'Default';
    public static void selectChannelAssignament(Lead[] lstLeads){
        Map<String,Object> mapValidatedLeads   = new Map<String,Object>();
        Map<String,List<Lead>> mapLeadsTypeAssignament = new Map<String,List<Lead>>();
        ConfiguracionActinver__c objConfigLeadPatrimonial = getLeadAssignmentSettings();
        
        // validamos por que via se hará la asignación de los leads
        Boolean blnValidateFilters           = objConfigLeadPatrimonial != null && objConfigLeadPatrimonial.Activo__c && (objConfigLeadPatrimonial.PorGrupo__c || objConfigLeadPatrimonial.PorCodigoPostal__c);
        Boolean blnAssignamentByDefaultGroup = objConfigLeadPatrimonial == null || (objConfigLeadPatrimonial != null && !objConfigLeadPatrimonial.Activo__c && !objConfigLeadPatrimonial.PorGrupo__c && !objConfigLeadPatrimonial.PorCodigoPostal__c);
        Boolean blnAssignamentByGroup        = objConfigLeadPatrimonial != null && objConfigLeadPatrimonial.PorGrupo__c;
        Boolean blnAssignamentByPostalCode   = objConfigLeadPatrimonial != null && objConfigLeadPatrimonial.PorCodigoPostal__c;
        
        System.debug('##·· blnValidateFilters:' + blnValidateFilters);
        System.debug('##·· blnAssignamentByDefaultGroup:' + blnAssignamentByDefaultGroup);
        System.debug('##·· blnAssignamentByGroup:' + blnAssignamentByGroup);
        System.debug('##·· blnAssignamentByPostalCode:' + blnAssignamentByPostalCode);
        
        if(blnValidateFilters) mapValidatedLeads   = ASL_ApexConditionalManagement_cls.validateFiltersAssignment(lstLeads,blnAssignamentByGroup,blnAssignamentByPostalCode,objConfigLeadPatrimonial.Grupo__r.NombreGrupo__c);
        if(blnAssignamentByDefaultGroup) assignamentByGroup(LABEL_DEFAULT,lstLeads,false,New Map<String,Object>());
        if(blnAssignamentByGroup)        assignamentByGroup(objConfigLeadPatrimonial.Grupo__r.NombreGrupo__c,lstLeads,blnValidateFilters,mapValidatedLeads);
        if(blnAssignamentByPostalCode)   mapLeadsTypeAssignament = getLeadsTypeAssignament(lstLeads,blnValidateFilters,mapValidatedLeads);
        if(blnAssignamentByPostalCode && mapLeadsTypeAssignament.get(LABEL_POSTAL_CODE) != null) assignamentByPostalCode(mapLeadsTypeAssignament.get(LABEL_POSTAL_CODE));
        if(blnAssignamentByPostalCode && mapLeadsTypeAssignament.get(LABEL_GROUP) != null)       assignamentByGroup(LABEL_DEFAULT,mapLeadsTypeAssignament.get(LABEL_GROUP),blnValidateFilters,mapValidatedLeads); 
    }
    public static Map<String,List<Lead>> getLeadsTypeAssignament(Lead[] lstLeads, Boolean blnValidateFilters, Map<String,Object> mapValidatedLeads){
        Lead[] lstEvaluateLeads                = new List<Lead>();
        Map<String,Lead> mapLeadsInsideFilter  = (Map<String,Lead>) mapValidatedLeads.get('mapLeadsInsideFilter');
        Map<String,Lead> mapLeadsOutsideFilter = (Map<String,Lead>) mapValidatedLeads.get('mapLeadsOutsideFilter');
        System.debug('lstLeads: '+lstLeads.size());
        System.debug('mapLeadsOutsideFilter: '+ (mapLeadsOutsideFilter != null? mapLeadsOutsideFilter.values().size():null));
        System.debug('mapLeadsInsideFilter: '+ (mapLeadsInsideFilter != null ? mapLeadsInsideFilter.values().size(): null));
        //if(blnValidateFilters && mapLeadsOutsideFilter != null && mapLeadsOutsideFilter.values().size() > 0 ) System.debug('Asigno a Grupo Default y no cumplio filtros');//assignamentByDefaultGroup(LABEL_DEFAULT,mapLeadsOutsideFilter.values());

        lstEvaluateLeads = blnValidateFilters ? (mapLeadsInsideFilter != null && mapLeadsInsideFilter.values().size() > 0 ? mapLeadsInsideFilter.values() : new List<Lead>() )  : lstLeads;
        Map<String,List<Lead>> mapResponse = new Map<String,List<Lead>>();
        for(Lead objLead : lstEvaluateLeads){
            String strMapKey = !String.isblank(objLead.Postalcode) ? LABEL_POSTAL_CODE : LABEL_GROUP;
            Lead[] currentLead = mapResponse.get(strMapKey) != null ? mapResponse.get(strMapKey) : new List<Lead>();
            currentLead.add(objLead);
            mapResponse.put(strMapKey,currentLead);
        } 
        return mapResponse;
    }
    public static void assignamentByGroup(String strGroup, Lead[] lstLeads, Boolean blnValidateFilters, Map<String,Object> mapValidatedLeads){
        Map<String,Lead> mapLeadsInsideFilter  = (Map<String,Lead>) mapValidatedLeads.get('mapLeadsInsideFilter');
        Map<String,Lead> mapLeadsOutsideFilter = (Map<String,Lead>) mapValidatedLeads.get('mapLeadsOutsideFilter');
        System.debug('lstLeads: '+lstLeads.size());
        System.debug('mapLeadsOutsideFilter: '+ (mapLeadsOutsideFilter != null? mapLeadsOutsideFilter.values().size():null));
        System.debug('mapLeadsInsideFilter: '+ (mapLeadsInsideFilter != null ? mapLeadsInsideFilter.values().size(): null));
        System.debug('assignamentByGroup: '+strGroup);
        if(blnValidateFilters && mapLeadsInsideFilter != null && mapLeadsInsideFilter.values().size() > 0 ){  
            System.debug('Asignar: Grupo y cumplio filtros');
            Service_Utility_Trigger2.setDefaultUsersGroup(mapLeadsInsideFilter.values(),strGroup);
        }
        if(blnValidateFilters && mapLeadsOutsideFilter != null && mapLeadsOutsideFilter.values().size() > 0 ){
            System.debug('Asignar: Grupo Default y no cumplio filtros');
            Service_Utility_Trigger2.setDefaultUsersGroup(mapLeadsOutsideFilter.values(),LABEL_DEFAULT);
        } 
        if(!blnValidateFilters){
            System.debug('Asignar: Grupo determinado o Defaul y N/A filtros');
            Service_Utility_Trigger2.setDefaultUsersGroup(lstLeads,strGroup);
        } 
       
    }
    public static void assignamentByPostalCode(Lead[] lstLeads){
        System.debug('assignamentByPostalCode: ' + lstLeads.size());
        postalCodeAssigment(lstLeads);
    }
    public static ConfiguracionActinver__c getLeadAssignmentSettings(){
        ConfiguracionActinver__c response = new ConfiguracionActinver__c();
        try{        
            response=  [SELECT Activo__c
                        ,DeveloperName__c
                        ,PorGrupo__c
                        ,PorCodigoPostal__c 
                        ,Grupo__r.NombreGrupo__c
                        ,JSONConfiguracion__c
                        FROM ConfiguracionActinver__c
                        WHERE DeveloperName__c = 'ConfiguracionLeadPatrimonial'
                        AND RecordType.DeveloperName = 'AsignacionLeadsPatrimonial'
                        LIMIT 1];
            return response;
        }catch(QueryException e){
            system.debug('ERROR en metodo [getLeadAssignmentSettings]: '+e);
            return null;
        }
    }
    public static void postalCodeAssigment(List<Lead> newList){
        if (bypassTriggerExecution) {
            system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN LEADS');
            return;
        }
        Map<Lead,List<UserByGroupTMP__c>> mapIdLeadByGroupUser = Service_Utility_Trigger2.getUserGroupByLead(newList); 
        if (!mapIdLeadByGroupUser.isEmpty()) Service_Utility_Trigger2.setOwnerIdsToLead(mapIdLeadByGroupUser,newList);
    }   
}