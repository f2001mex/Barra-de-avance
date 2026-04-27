public class ASL_ApexConditionalManagement_cls {
    public static String LABEL_CONDITION_VALUE  = 'inputLogicValue';
    public static String LABEL_CONDITIONS       = 'conditionsData';
    public static String LABEL_ID               = 'id';
    public static String LABEL_DEFAULT          = 'Default';
    public static String LABEL_POSTAL_CODE      = 'PostalCode';
    public static String LABEL_GROUP            = 'Group';
    public static String[] OPERATORS_FUNCTION   = new List<String>{'contains','startsWith','endsWith'};
        
    public static Map<String,Object> validateFiltersAssignment(List<Lead> leadNew, Boolean blnAssignamentByGroup, Boolean blnAssignamentByPostalCode, String strGroup){
        ConfiguracionActinver__c objConfigLeadPatrimonial   = getLeadAssignmentSettings();
        String strJSON                                      = objConfigLeadPatrimonial.JSONConfiguracion__c;
        Map<String,Object> mapProcessConditional            = getEntryConditions(strJSON);
        String strConditionLogicOriginal                    = (String) mapProcessConditional.get(LABEL_CONDITION_VALUE);
        String strNewConditionLogic = strConditionLogicOriginal;
        Map<String, Map<String, Object>> mapEntryConditions = (Map<String,Map<String,Object>>) mapProcessConditional.get(LABEL_CONDITIONS);
        Map<String,Object> mapSentences                     = generateSentence(mapEntryConditions);
        Map<String,Map<String,String>> mapSentenceCondition = (Map<String,Map<String,String>>) mapSentences.get('mapSentenceCondition');
        Map<String,String> mapLogicCondition                = (Map<String,String>) mapSentences.get('mapLogicCondition');
        Map<String,Lead> mapLeadsInsideFilter  = new Map<String,Lead>();
        Map<String,Lead> mapLeadsOutsideFilter = new Map<String,Lead>();
        Map<String,String> mapTernaryForConsole  = new Map<String,String>();
        Map<String,Object> mapResponse         = new Map<String,Object>();
        for(Lead objLead :leadNew){
            sObject sObjLead = (sObject) objLead;
            Map<String, Object> mapDataLead = sObjLead.getPopulatedFieldsAsMap();
            String ternarySentence = 'Boolean result = ';
            String strConditionLogic = strConditionLogicOriginal;
            String variableSentence = '';
            Map<String, String> mapTernary = new Map<String, String>();
            String strCompare = '';
            for(String strMapKey :mapLogicCondition.keySet()){
                String strApiName = strMapKey.split('\\|')[0];
               // if(mapDataLead.get(strApiName) != null){  // OAG_30May2025:descomentar para disminuir el  # de callouts; implicación: No validaria valores nulos 
                    String strSequenceSentence      = mapLogicCondition.get(strMapKey);
                    Map<String,String> mapCondition = mapSentenceCondition.get(strSequenceSentence);
                    String strDataType = mapCondition.get('strDataType');
                    String strPrefix   = mapCondition.get('strPrefix');
                    String strSufix    = generateRandomString(5);
                    String strType     = mapCondition.get('strType');
                    String strSentence = mapCondition.get('strSentence');
                    String strIndex    = mapCondition.get('strIndex');
                    String strOperator = mapCondition.get('operator');
                    String strVariable = mapCondition.get('strVariable');
                    String strVariableCurrent = '';
                           strVariableCurrent = strPrefix + strApiName.replace('__c','').replace('_','') + '_' + strSufix;
                    String strValue    = mapDataLead.get(strApiName) != null ? String.valueOf(mapDataLead.get(strApiName)) : '';
                    strValue    = strType == 'MULTIPICKLIST' ? strValue.replace('(','').replace(')','') : strValue;
                    String strSentenceCurrent = '';
                    strSentenceCurrent += strDataType;
                    strSentenceCurrent += ' ';
                    strSentenceCurrent += strVariableCurrent;
                    strSentenceCurrent += ' = ';
                    strSentenceCurrent += strDataType == 'String' ? getStringTypeValue(strValue) : (strDataType == 'Date' ? getDateTypeValue(strValue) : (strDataType == 'DateTime' ? getDateTimeTypeValue(strValue) : strValue));
                    strSentenceCurrent += ';';
                    variableSentence += strSentenceCurrent;
                    variableSentence += strSentence;
                    strCompare = OPERATORS_FUNCTION.contains(strOperator) ? getConditionByfunction(strVariableCurrent,strVariable,strOperator): strVariableCurrent + ' ' + strOperator + ' ' + strVariable;
                    mapTernary.put(strIndex,strCompare);
                //}// OAG_30May2025; implicación: No validaria valores nulos
                //if(mapDataLead.get(strApiName) == null) mapLeadsOutsideFilter.put(objLead.Id,objLead); implicación: No validaria valores nulos
            }
            if(mapLeadsOutsideFilter.get(objLead.Id) == null){
                strConditionLogic = strConditionLogic.replace('AND','&&');
                strConditionLogic = strConditionLogic.replace('OR','||');
                //String[] chars = strNewConditionLogic.split('');
                //for(String strChar :chars){
                //    String strTMPCompare = mapTernary.get(strChar);
                //    if(strTMPCompare != null && strChar.isNumeric()) strConditionLogic = strConditionLogic.replace(strChar,strTMPCompare);
                //}
                // Normaliza operadores
                ////strConditionLogic = strConditionLogic.replace('AND', '&&');
                ////strConditionLogic = strConditionLogic.replace('OR',  '||');

                // Reemplaza tokens numéricos completos (10, 1, 2, etc.)
                ////Pattern p = Pattern.compile('\\d+');
                ////Matcher m = p.matcher(strConditionLogic);
                strConditionLogic = applyLogicReplacements(strConditionLogic, mapTernary);

                //while (m.find()) {
                    //String idx = m.group(0);
                    // Si por alguna razón falta el índice, lo volvemos false para no tronar
                    //String repl = mapTernary.containsKey(idx)
                    //? '(' + mapTernary.get(idx) + ')'
                    //: 'false';

                   //strConditionLogic = strConditionLogic.replace(idx, repl);
                //}
                //termina corrección
                ternarySentence += strConditionLogic + ';';
                variableSentence += ternarySentence;    
                variableSentence += 'System.debug(LoggingLevel.Error, result);';
                System.debug('#### variableSentence: ' + variableSentence);
                mapLeadsInsideFilter.put(objLead.Id,objLead);
                mapTernaryForConsole.put(objLead.Id,variableSentence);
            }
        }
        mapResponse.put('mapLeadsOutsideFilter',mapLeadsOutsideFilter);
        String jsonLeads = JSON.serialize(mapLeadsInsideFilter);
        String jsonVariableSentence = JSON.serialize(mapTernaryForConsole);
        if (mapLeadsInsideFilter.size() > 0 && !Test.isRunningTest()) {
            liningEvaluatorInConsole(jsonLeads, jsonVariableSentence, blnAssignamentByGroup, blnAssignamentByPostalCode, strGroup);
        }
        return mapResponse;
    }
    @future(Callout = true)
    public static void liningEvaluatorInConsole(String jsonLeads, String jsonVariableSentence, Boolean blnAssignamentByGroup, Boolean blnAssignamentByPostalCode, String strGroup){
        Map<String,Object> mapLeadsValidate = (Map<String,Object>) JSON.deserializeUntyped(jsonLeads);
        Map<String,Object> mapTernaryForConsole = (Map<String,Object>) JSON.deserializeUntyped(jsonVariableSentence);
        Map<String,List<Lead>> mapLeadsTypeAssignament = new Map<String,List<Lead>>();
        
        Map<String,Lead> mapLeadsInsideFilter  = new Map<String,Lead>();
        Map<String,Lead> mapLeadsOutsideFilter = new Map<String,Lead>();
        for(String strLeadId :mapTernaryForConsole .keySet()){
            String jsonLead = JSON.serialize(mapLeadsValidate.get(strLeadId));
            Lead objLead = (Lead)JSON.deserialize(jsonLead, Lead.class);
            boolean output = ASL_LiningEvaluatorInConsole_cls.evalBoolean((String)mapTernaryForConsole.get(strLeadId));
            System.debug('#### objLead: ' + objLead.F3_ConsecutivoProsp__c + ' : '+output);     
            if(output)  mapLeadsInsideFilter.put(objLead.Id,objLead);
            if(!output) mapLeadsOutsideFilter.put(objLead.Id,objLead);
        }
        if(mapLeadsOutsideFilter != null) ASL_LeadsAssignmentChannel_cls.assignamentByGroup(LABEL_DEFAULT,mapLeadsOutsideFilter.Values(),false,New Map<String,Object>());
        if(blnAssignamentByGroup && mapLeadsInsideFilter != null && mapLeadsInsideFilter.values().size() > 0)      ASL_LeadsAssignmentChannel_cls.assignamentByGroup(strGroup,mapLeadsInsideFilter.Values(),false,New Map<String,Object>());
        if(blnAssignamentByPostalCode && mapLeadsInsideFilter != null && mapLeadsInsideFilter.values().size() > 0) mapLeadsTypeAssignament = ASL_LeadsAssignmentChannel_cls.getLeadsTypeAssignament(mapLeadsInsideFilter.Values(),false,New Map<String,Object>());
        if(blnAssignamentByPostalCode && mapLeadsTypeAssignament.get(LABEL_POSTAL_CODE) != null) ASL_LeadsAssignmentChannel_cls.assignamentByPostalCode(mapLeadsTypeAssignament.get(LABEL_POSTAL_CODE));
        if(blnAssignamentByPostalCode && mapLeadsTypeAssignament.get(LABEL_GROUP) != null)       ASL_LeadsAssignmentChannel_cls.assignamentByGroup(LABEL_DEFAULT,mapLeadsTypeAssignament.get(LABEL_GROUP),false,New Map<String,Object>()); 
    }
    public static Map<String,Object> generateSentence(Map<String, Map<String, Object>> mapEntryConditions){
        Map<String,Map<String,String>> mapSentenceCondition = New Map<String,Map<String,String>>();
        Map<String,String> mapLogicCondition                = New Map<String,String>();
        Map<String,Object> response                         = New Map<String,Object>();
        Map<String, TipoDatosApex__mdt> mdtTipoDatosApex    = TipoDatosApex__mdt.getAll(); 
        for(String strKey :mapEntryConditions.keySet()){
            Map<String, Object> mapCondition = mapEntryConditions.get(strKey);
            String strType     = String.valueof(mapCondition.get('type'));
            String strPrefix   = mdtTipoDatosApex.get(strType).PreFijo__c;
            String strSufix    = generateRandomString(5);
            String strDataType = mdtTipoDatosApex.get(strType).TipoDatoCampo__c;
            String strApiName  = String.valueof(mapCondition.get('apiName'));
            String strId       = String.valueof(mapCondition.get('id'));
            String strOperator = String.valueof(mapCondition.get('operator'));
            String strValue    = String.valueof(mapCondition.get('value'));
            String strVariable = strPrefix + strApiName.replace('__c','').replace('_','')+strSufix;
            strValue = strType == 'MULTIPICKLIST' ? strValue.replace('(','').replace(')','') : strValue;
            String strSentence = '';
            strSentence += strDataType;
            strSentence += ' ';
            strSentence += strVariable;
            strSentence += ' = ';
            strSentence += strDataType == 'String' ? getStringTypeValue(strValue) : (strDataType == 'Date' ? getDateTypeValue(strValue) : (strDataType == 'DateTime' ? getDateTimeTypeValue(strValue) : strValue));
                strSentence += ';';
            Map<String,String> mapTMP = New Map<String,String>();
            mapTMP.put('operator',strOperator);
            mapTMP.put('strSentence',strSentence);
            mapTMP.put('strDataType',strDataType);
            mapTMP.put('strPrefix',strPrefix);
            mapTMP.put('strType',strType);
            mapTMP.put('strVariable',strVariable);
            mapTMP.put('strIndex',strId);
            mapLogicCondition.put(strApiName+'|'+strId,strId);
            mapSentenceCondition.put(strId,mapTMP);
        } 
        response.put('mapLogicCondition',mapLogicCondition);
        response.put('mapSentenceCondition',mapSentenceCondition);
        return response;
    }
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    public static String getConditionByfunction(String strVariableCurrent, String strVariable, String strOperator){
        String response;
        if(strOperator == 'contains')   response = strVariableCurrent+'.contains('+strVariable+')';
        if(strOperator == 'startsWith') response = strVariableCurrent+'.startsWith('+strVariable+')';
        if(strOperator == 'endsWith')   response = strVariableCurrent+'.endsWith('+strVariable+')';
        return response;
    }
    public static String getDateTimeTypeValue(String strValue){
        return 'DateTime.valueOf(\''+strValue+'\')';
    }
    public static String getDateTypeValue(String strValue){
        return 'date.valueOf(\''+strValue+'\')';
    }
    public static String getStringTypeValue(String strValue){
        return '\''+strValue+'\'';
    }
    public static Map<String,Object> getEntryConditions(String strJSON){
        Map<String, Object> response   = New Map<String, Object>();
        Map<String, Object> mapConfig  = (Map<String, Object>) JSON.deserializeUntyped(strJSON);
        String strConditionLogic       = (String) mapConfig.get(LABEL_CONDITION_VALUE);
        Object[] lstSetEntryConditions = (List<Object>) mapConfig.get(LABEL_CONDITIONS);
        Map<String,Map<String,Object>> mapEntryConditions  = new Map<String,Map<String,Object>>();
        for(Object obj :lstSetEntryConditions){
            Object[] valuesCondition           = (List<Object>) obj;
            Map<String, Object> mapConditions  = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(valuesCondition[1]));
            mapEntryConditions.put(String.valueOf(mapConditions.get(LABEL_ID)),mapConditions);
        }
        response.put(LABEL_CONDITION_VALUE,strConditionLogic);
        response.put(LABEL_CONDITIONS,mapEntryConditions);
        
        return response;
    }
    public static ConfiguracionActinver__c getLeadAssignmentSettings(){
    
        if (Test.isRunningTest()) {
            return new ConfiguracionActinver__c(
                JSONConfiguracion__c =
                    '{"inputLogicValue":"1","conditionsData":[[null,{"id":"1","apiName":"PostalCode","type":"STRING","operator":"=","value":"12345"}]]}'
            );
        }
    
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
    
    @TestVisible
    private static String applyLogicReplacements(String logic, Map<String,String> mapTernary) {
        if (String.isBlank(logic)) return logic;

        // Normaliza operadores
        String out = logic.replace('AND', '&&').replace('OR', '||');

        // Detecta tokens numéricos completos: 1,2,10,11...
        Pattern p = Pattern.compile('\\d+');
        Matcher m = p.matcher(out);

        // Guardamos índices únicos encontrados
        Set<String> found = new Set<String>();
        Integer maxLen = 0;
        while (m.find()) {
            String idx = m.group(0);
            found.add(idx);
            if (idx.length() > maxLen) maxLen = idx.length();
        }

        // Reemplaza por longitud descendente: primero 2+ dígitos (10) y luego 1 dígito (1)
        for (Integer len = maxLen; len >= 1; len--) {
            for (String idx : found) {
                if (idx.length() != len) continue;

                String repl = (mapTernary != null && mapTernary.containsKey(idx))
                    ? '(' + mapTernary.get(idx) + ')'
                    : 'false';

                out = out.replace(idx, repl);
            }
        }

    return out;
    }    
}