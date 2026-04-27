/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Martín Martínez
* Project           :   Post venta
* Clase test		:   
* Description       :   Clase selector que contiene todas las SOQL o DML del batch para crear nuevas tareas por periodicidad.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         19-Jun-2025       Martín Martínez              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class PV_GenerarTareasPeriodicasSelector_cls {

    public static final Id idConfigPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ConfiguracionPeriodicidadTareas').getRecordTypeId();

    public static String getQueryAccounts(){
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Generar_Tareas'].Consulta__c ;
        return consulta;
        
            
    }

    /* public static String getQueryAccounts(){
        return 'SELECT Id, Name,' +
                    'FechaUltimoContacto__c, ' +
                    'EnrolamientoBiometricos__c, ' +
                    'EnrolamientoActivo__c, ' +
                    'FichaAfinidadCompletada__c, ' +
                    'PersonContactId, ' +
                    'BanqueroAsignado__r.BusinessUnitMemberId ' +
                'FROM Account ' +
                'WHERE CreatedDate = TODAY' +//Id IN (\'001dz0000078XvfAAE\', \'001dz000006wr5JAAQ\', \'001dz000007BDsMAAW\') ';
                ' AND SaldoIntegral__c != null AND IsPersonAccount = TRUE AND BanqueroAsignado__c != null';
    } */

    public static List<ActionCadence> getCadence() {
        return [SELECT Id,
                    Name,
                    Tipo_de_actividad__c,
                    Periodicidad__c,
                    DeveloperName__c,
                    TareaUnicaPorContrato__c, 
                    TareaUnicaPorCuenta__c
                FROM ActionCadence
                WHERE State ='Active'];
    }   

    public static List<Contract> getContratosClienteNoContactar(Set<Id> accountIds) {
        return [SELECT AccountId, FLAG_MARKETING__c, FLAG_MARKETING_ACTINVER__c, FLAG_EVENTS_INVITATIONS__c
                FROM Contract
                WHERE AccountId IN :accountIds
                AND (FLAG_MARKETING__c != null 
                    AND FLAG_MARKETING_ACTINVER__c != null 
                    AND FLAG_EVENTS_INVITATIONS__c != null)
            ];
    } 

    public static Set<Id> getAccountsWithValidContracts(Set<Id> accountIds, Set<String> validContractTypes, Set<String> validContractStatuses) {
        Set<Id> validAccountIds = new Set<Id>();
        if (accountIds == null || accountIds.isEmpty() || validContractTypes == null || validContractTypes.isEmpty() ||
            validContractStatuses == null || validContractStatuses.isEmpty()) {
            return validAccountIds;
        }

        for (AggregateResult result : [
            SELECT AccountId accountId
            FROM Contract
            WHERE AccountId IN :accountIds
                AND TypeOfContract__c IN :validContractTypes
                AND Status__c IN :validContractStatuses
            GROUP BY AccountId
        ]) {
            validAccountIds.add((Id) result.get('accountId'));
        }

        return validAccountIds;
    }

    public static List<Banker> getBankerByBusinessMemberId(Set<Id> setBMemberId){
        return [SELECT ID, UserOrContactId, ExternalId__c FROM BANKER WHERE ID IN: setBMemberId];
    }

    public static Id getDiasLaborales(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
    }

    public static List<ActionCadenceTracker> validateCadenceActive(Set<Id> accountIds, String developerNameCadencia, Boolean cadenciaUnicaPorCuenta) {
        String baseQuery = 'SELECT ActionCadence.DeveloperName__c, TargetId ' +
                        'FROM ActionCadenceTracker ' +
                        'WHERE ActionCadence.DeveloperName__c = :developerNameCadencia ';

        /*Boolean esCadenciaEspecial = 
            developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BIOMETRICOS || 
            developerNameCadencia == PSTA_UtilityClass.DEVELOPERNAME_BANCA_ELECTRONICA;

        if (!esCadenciaEspecial || !cadenciaUnicaPorCuenta) {*/
            baseQuery += 'AND State = \'Running\' ';
        //}


        baseQuery += 'AND TargetId IN :accountIds';

        return Database.query(baseQuery);
    }

    public static List<Contract> getContratosNoPropuestaPlaneacion(Set<Id> accountIds) {
        return [
            SELECT Id, AccountId, Account.PersonContactId, PlaneacionFinancieraCompletada__c, PropuestaInversionCompletada__c
            FROM Contract
            WHERE AccountId IN :accountIds
            AND (PlaneacionFinancieraCompletada__c = false
            OR PropuestaInversionCompletada__c = false)
        ];
    }

    public static List<Task> getTask(Set<Id> accountIds, String developerNameCadencia) {
        Integer mesesFiltro;
        try {
            mesesFiltro = Integer.valueOf(Label.MesesFiltroTareas);
        } catch(Exception e) {
            mesesFiltro = 6;
        }

        Date fechaLimite = Date.today().addMonths(-mesesFiltro);
        return [
            SELECT AccountId, CreatedDate, DeveloperName__c
            FROM Task
            WHERE DeveloperName__c = :developerNameCadencia
              AND AccountId IN :accountIds
              AND DeveloperName__c != null
              AND CreatedDate >= :fechaLimite
            ORDER BY AccountId, CreatedDate DESC
        ];
    }

}
