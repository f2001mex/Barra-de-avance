/****************************************************************************************************
    Desarrollado por: Salvador Ramírez López (salvador.ramirez@vasscompany.com)
    Proyecto        : Actinver - Reingeniería scheduler
    Descripción     : Clase que contiene los métodos que serán utilizados para el uso desde omniscript

    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
    1.0     2024-11-25      Salvador Ramírez	    Creación de la Clase.
*/
public class SCH_SchedulerFunctions_cls  {
    public class MyException extends Exception {}
    public static wpDataClient validarCuentaExistente(String strFilter){
        wpDataClient wpResult = new wpDataClient();
        List<Account> lstAccount = [SELECT ID, NAME, 
                                    (SELECT ID, CONTRACTNUMBER__C, CreatedDate, 
                                    (SELECT ID, PRINCIPAL__C, Phone__c, CreatedDate FROM Telefono_de_Contratos__R WHERE PRINCIPAL__C = TRUE OR PHONE_TYPE__C = 'CELULAR'), 
                                    (SELECT Contract_email__c, PRINCIPAL__C, CREATEDDATE FROM contrato__r ) 
                                    FROM CONTRACTS ORDER BY CreatedDate DESC LIMIT 1) 
                                    FROM ACCOUNT WHERE Client_ID__c = :strFilter];
        if(lstAccount.isEmpty()){
            List<Contract> lstContract = [SELECT ID, ContractNumber__c, AccountId, Account.Name, 
                                        (SELECT ID, PRINCIPAL__C, Phone__c, CreatedDate FROM Telefono_de_Contratos__R WHERE PRINCIPAL__C = TRUE OR PHONE_TYPE__C = 'CELULAR'), 
                                        (SELECT Contract_email__c, PRINCIPAL__C, CREATEDDATE FROM contrato__r )  
                                        FROM CONTRACT WHERE CONTRACTNUMBER__C = :strFilter];
            if(!lstContract.isEmpty()){
                wpResult.objContract = lstContract[0];
                wpResult.objAcc = null;
                wpResult.blnEncontradoPorContrato = true;
            } else wpResult.objContract = null;
        } else {
            wpResult.objAcc = lstAccount[0];
            wpResult.objContract = null;
            wpResult.blnEncontradoPorCuenta = true;
        }
        return wpResult;
    }
    public static Map<Object,List<String>> getDependentPicklistValues( Schema.sObjectField dependToken ){
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if ( controlToken == null ) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = ( control.getType() == Schema.DisplayType.Boolean ? null : control.getPicklistValues());
        if(controlEntries.isEmpty())  throw new MyException('This Field Don\'t Have Controlling Field!');
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues() ){
            if ( entry.isActive() ){
                List<String> base64chars =
                String.valueOf( ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )).split( '' );
                if(base64chars.isEmpty()) throw new MyException('This Picklist Value Don\'t Have Controlling Value!');
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ ){
                    Object controlValue =( controlEntries == null? (Object) (index == 1): (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getValue() : null));
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                    if(bitIndex >= base64chars.size()) continue;
                    if ( controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0) continue;
                    if ( !dependentPicklistValues.containsKey( String.valueOf(controlValue )) ){
                        dependentPicklistValues.put( String.valueOf(controlValue), new List<String>() );
                    }
                    dependentPicklistValues.get( String.valueOf(controlValue) ).add( entry.getValue() );
                }
            }
        }
        return dependentPicklistValues;
    }
    public static DateTime getDateTimeWithOffset(String strTimeZoneSidKey, Datetime dtTimeToConvert){
        TimeZone tz = TimeZone.getTimeZone(strTimeZoneSidKey);
        Double offset = tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
        Datetime format = dtTimeToConvert + offset;
        return format;
    }
    public class wpDataClient{
        public Account objAcc;
        public Contract objContract;
        public Boolean blnEncontradoPorCuenta;
        public Boolean blnEncontradoPorContrato;
        public wpDataClient(){
            objAcc = new Account();
            objContract = new Contract();
            blnEncontradoPorCuenta = false;
            blnEncontradoPorContrato = false;
        }
    }
}