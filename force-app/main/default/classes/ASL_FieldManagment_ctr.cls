/**
* @File Name : ASL_FieldManagment_ctr.cls
* @Description :Clase controller para el LWV de configuracion de campos
* @Author :Andres Hernandez Rios
* @Last Modified By :
* @Last Modified On : Enero 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Enero 15, 2025 |  Andres Hernandez Rios | Initial Version
**/

public without sharing class ASL_FieldManagment_ctr {
	private static final String ASSIGNPATRIMONIAL = 'AsignacionLeadsPatrimonial';
    public static final String NameRecord = 'ConfiguracionLeadPatrimonial'; 
    public static final String recordTypeId = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get(ASSIGNPATRIMONIAL).getRecordTypeId();
    
    @AuraEnabled(cacheable=true)
    public static String initValues(){
        List<ConfiguracionActinver__c> getRecords = [
            SELECT Id,DeveloperName__c,JSONConfiguracion__c FROM ConfiguracionActinver__c 
            WHERE recordTypeId =:recordTypeId AND DeveloperName__c =:NameRecord LIMIT 1
        ];
        return getRecords.size() > 0 ? getRecords[0].JSONConfiguracion__c : '';
    }
    
    @AuraEnabled
    public static void saveConditionsData(String jsonData){
        ConfiguracionActinver__c confActver = new ConfiguracionActinver__c ();
        confActver.recordTypeId = recordTypeId;
        confActver.DeveloperName__c = NameRecord;
        confActver.JSONConfiguracion__c = jsonData;
        
        upsert confActver DeveloperName__c;
        
    }
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getLeadFields() {
        Schema.DescribeSObjectResult describeResult = Lead.SObjectType.getDescribe();        
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

        Integer formulaStringCount = 0;
        
        List<FieldInfo> fields = new List<FieldInfo>();
        for (Schema.SObjectField field : fieldsMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if(!isAutoNumber(field) && !isFormula(field) && fieldDescribe.getType() != Schema.DisplayType.ID){
                
                if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
                    List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                    List<PicklistValue> picklistValues = new List<PicklistValue>();
                    for (Schema.PicklistEntry entry : picklistEntries) {
                        picklistValues.add(new PicklistValue(entry.getValue(), entry.getLabel()));
                    }
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name(), picklistValues,null));
                }else if(fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST){
                    List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                    List<PicklistValue> multiPicklistValues = new List<PicklistValue>();
                    for (Schema.PicklistEntry entry : picklistEntries) {
                        multiPicklistValues.add(new PicklistValue(entry.getValue(), entry.getLabel()));
                    }
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name(),multiPicklistValues,null));
                }else if(fieldDescribe.getType() == Schema.DisplayType.STRING){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.BOOLEAN){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){
                    List<String> supportedReferences = new List<String>();
                    for(Schema.SObjectType reference : fieldDescribe.getReferenceTo()) {
                        Schema.DescribeSObjectResult referenceDescribe = reference.getDescribe();
                        if (referenceDescribe.isAccessible() && referenceDescribe.getName() != 'Individual' && referenceDescribe.getName() != 'ActivityMetric') { 
                            supportedReferences.add(referenceDescribe.getName());
                        }
                    }
                    
                    if (!supportedReferences.isEmpty()) {
                        fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name(),null,supportedReferences));
                    }
                }else if(fieldDescribe.getType() == Schema.DisplayType.DATE){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.PERCENT){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.CURRENCY){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.EMAIL){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.PHONE){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.TEXTAREA){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.DOUBLE){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.INTEGER){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }else if(fieldDescribe.getType() == Schema.DisplayType.URL){
                    fields.add(new FieldInfo(fieldDescribe.getName(), fieldDescribe.getLabel(), fieldDescribe.getType().name()));
                }
            }            
        }
        return fields;
    }
    @AuraEnabled
    public static List<Map<String, Object>> searchRecords(String objectName, String filterValue) {
        if (String.isEmpty(objectName) || String.isEmpty(filterValue)) {
            throw new AuraHandledException('Object name or filter value is missing.');
        }
        String searchTerm = '%' + filterValue + '%'; 
        
        system.debug('filterValue:'+filterValue);

        String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Name LIKE :searchTerm LIMIT 5';
        System.debug('Consulta ejecutada: ' + query);

        List<SObject> results = Database.query(query);

        List<Map<String, Object>> resultMap = new List<Map<String, Object>>();
        for (SObject record : results) {
            resultMap.add(new Map<String, Object>{
                'value' => record.Id,
                'label' => (String)record.get('Name')
            });
        }

        return resultMap;
    }
    public static Boolean isAutoNumber(SObjectField field){
        return field.getDescribe().isAutoNumber();
    }
    public static Boolean isFormula(SObjectField field){
        return field.getDescribe().isCalculated();
    }
    
    public class PicklistValue {
        @AuraEnabled public String value;
        @AuraEnabled public String label;

        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    public class FieldInfo {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public List<PicklistValue> picklistValues;
        @AuraEnabled public List<String> sObjects;

        public FieldInfo(String apiName, String label, String type) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.picklistValues = new List<PicklistValue>();
            this.sObjects = new List<String>();
        }

        public FieldInfo(String apiName, String label, String type, List<PicklistValue> picklistValues,List<String> sObjects) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.picklistValues = picklistValues;
            this.sObjects = sObjects;
        }
    }
}