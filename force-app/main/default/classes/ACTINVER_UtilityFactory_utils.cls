/**
**/
public with sharing class ACTINVER_UtilityFactory_utils {
    /** @description: Obtener el getValueFieldSet de un FieldSet de un objeto determinado
    * @param:	fieldSetName            API Name del fieldSet
    * @param:	objectName              API Name del objeto
    * 
    * @return   Devuelve una lista de valores de tipo FIELD SET (It's wrapper)
    */
    public static List<WrapperValueFieldSet> getValueFieldSet(String fieldSetName, String objectName){
        WrapperValueFieldSet [] lstWrapperValueFieldSet = new List<WrapperValueFieldSet>();
        List<Schema.FieldSetMember> fieldSetMemberList  =  readFieldSet(fieldSetName, objectName);
        
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            WrapperValueFieldSet wrapperValueFieldSet = new WrapperValueFieldSet(String.valueOf(fieldSetMemberObj.getLabel()) ,
                                                                                 String.valueOf(fieldSetMemberObj.getFieldPath())
                                                                                );
            lstWrapperValueFieldSet.add(wrapperValueFieldSet);
        }
        return lstWrapperValueFieldSet;
    }
    /** @description:  Obtener los campos de un FieldSet de un determinado objeto
    * @param:	fieldSetName            API Name del fieldSet
    * @param:   objectName              API Name del objeto
    * 
    * @return   Devuelve una lista de campos de tipo Schema.FieldSetMember
    */
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String objectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap       = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj                       = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj   = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj                             = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        List<Schema.FieldSetMember> fieldSetMemberList          = fieldSetObj.getFields();
        
        return fieldSetObj.getFields();
    }
    public static String formatDate(DateTime dt, Boolean blnIncluirGuiones){
        String strDay = dt.day() < 10 ? '0' + dt.day() : String.valueOf(dt.day());
        String strMonth = dt.month() < 10 ? '0' + dt.month() : String.valueOf(dt.month());
        return dt.year() + (blnIncluirGuiones ? '-' : '') + strMonth + (blnIncluirGuiones ? '-' : '') + strDay;
    }
    public static string formatTime(Datetime dt){
        String strHour = dt.hour() < 10 ? '0' + dt.hour() : String.valueOf(dt.hour());
        String strMinute = dt.minute() < 10 ? '0' + dt.minute() : String.valueOf(dt.minute());
        return strHour + ':' + strMinute;
    }
    public static Integer calcularEdad(Date dtBirthDate){
        return Integer.valueOf(dtBirthDate.daysBetween(System.today()));
    }
    /** 
    *@description: Obtener ID de un tipo de registro
    * @param   strObjectType
    * @param   nameRecordType
    * 
    * @return  Id Tipo de registro
    */
    public static Id getRecodType(String strObjectType, String recordTypeDeveloperName){	
        return Schema.getGlobalDescribe().get(strObjectType).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
}
    /** @description:   Wrapper class to hold Columns with headers - Exclusive to FIELSET
     * 				    Create and set three variables label, fieldname and type as required by the lightning componet
     * */
    public class WrapperValueFieldSet{
        @AuraEnabled
        public String           label               {get;set;}
        @AuraEnabled       
        public String           fieldName           {get;set;}
        
        public WrapperValueFieldSet(String label, String fieldName){
            this.label 		    = label;
            this.fieldName 	    = fieldName;
        }
    } 
}