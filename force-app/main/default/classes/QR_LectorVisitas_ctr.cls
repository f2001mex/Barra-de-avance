/**
* @File Name : QR_LectorVisitas_ctr.cls
* @Description :Clase que genera los registros de Servicio y Visita desde un formulario en LWC
* @Author : Andrés Hernández Ríos
* @Last Modified By :
* @Last Modified On : October 17, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 17, 2024 |Andrés Hernández Ríos| Initial Version
**/

public without sharing class QR_LectorVisitas_ctr {
    //DECLARAMOS CUSTOM LABELS
    public static final Set<String> excludedStatus = new Set<String>(Label.StatusContract.split(';'));
    public static final String MESSAGEEXIT = System.Label.Mensaje_exito;
    public static final String ERRORCONTRACT = System.Label.Not_Found_Contract;
    public static final String MINUTES = System.Label.Time_to_create_visit;
    public static final String MESSAGETIMELASTVISIT = System.Label.Time_Since_Last_Visit;
    public static final String CLIENTE = 'Cliente';
    public static final String TERCERO = 'Tercero';
    public static final String VENTANILLA = 'Ventanilla';
    public static final String FINALIZADO = 'Finalizado';
    public static final String ANFITRION = 'Anfitrion';
    public class Respond{
        @AuraEnabled public Boolean success;        
        @AuraEnabled public String message;
        @AuraEnabled public String visitId;
    }
    //METODO PARA GUARDAR LOS DATOS DEL FORMULARIO
    @AuraEnabled
    public static Respond saveData(Map<String, Object> parameters) {
        Respond respond = new Respond();
        String cf = (String) parameters.get('cfId');
        String firstName = (String) parameters.get('firstName');
        String lastName1 = (String) parameters.get('lastName1');
        String lastName2 = (String) parameters.get('lastName2');
        String reason = (String) parameters.get('reason');
        String subReason = (String) parameters.get('subReason');
        String bp = (String) parameters.get('bp');
        Boolean isChecked = (Boolean) parameters.get('isChecked');
        String contractNumber = (String) parameters.get('contractNumber');
        List<Account> accountList = new List<Account>();
        List<Contract> contractList = new List<Contract>();       	
        
        List<RecordType> vRecordsTypes = [
            SELECT Id,Name FROM RecordType 
            WHERE Name =: CLIENTE OR Name =: TERCERO
        ]; 
        
        if(String.isNotBlank(contractNumber)){
            contractList = [
                SELECT Id,AccountId FROM Contract WHERE ContractNumber__c =: contractNumber AND Status__c NOT IN:excludedStatus
            ];
        }
        if(contractList.isEmpty()){
            respond.success = false;
            respond.message = ERRORCONTRACT;
            return respond;
        }
        
        if(String.isNotBlank(bp)){
            accountList = [
                SELECT Id FROM Account WHERE Client_ID__c =: bp AND
                (RecordTypeId =: Service_Utility_Trigger.rtPersonAccount OR
                 RecordTypeId =: Service_Utility_Trigger.rtPrivadaAccount OR
                 RecordTypeId =: Service_Utility_Trigger.rtWealthManagmentAccount)
            ];
        }
                      
        Map<String, Object> result = canCreateNewRecord(contractList, isChecked);        
        if((Boolean)result.get('isWithinTimeLimit')){
            respond.success = false;
            respond.message = String.format(MESSAGETIMELASTVISIT, 
                               new List<String>{
                                   String.valueOf((Long) result.get('timeDifferenceInMinutes')),
                                   MINUTES
                               });
            return respond;
        }
               

        Visita__c insertVisita = new Visita__c();
        insertVisita.CentroFinanciero__c = cf;
        insertVisita.HoraEntradaVisita__c = System.now();
        insertVisita.recordTypeId = isChecked ? vRecordsTypes[0].Id : vRecordsTypes[1].Id;
        insertVisita.Nombre__c = firstName;
        insertVisita.ApellidoPaterno__c = lastName1;
        insertVisita.ApellidoMaterno__c = lastName2;
        insertVisita.Etapa__c = FINALIZADO;
        insertVisita.Cuenta__c = (!accountList.isEmpty()) ? accountList[0].Id : contractList[0].AccountId;
        insertVisita.Contrato__c = (!contractList.isEmpty()) ? contractList[0].Id : null;
        insert insertVisita;
        
        Servicio__c insertService = new Servicio__c();
        insertService.Visita__c = insertVisita.Id;
        insertService.TiempoAtencionStartDateTime__c = System.now();
        insertService.Motivo__c = reason;
        insertService.Submotivo__c = subReason;
        insertService.TipoVisita__c = isChecked ? CLIENTE : TERCERO;
        insertService.QuienAtiende__c = VENTANILLA;
        insertService.Etapa__c = FINALIZADO;
        insertService.RecordTypeId = Schema.SObjectType.Servicio__c.getRecordTypeInfosByDeveloperName().get(ANFITRION).getRecordTypeId();
        insert insertService;

        respond.success = true;
        respond.message = MESSAGEEXIT;
        respond.visitId = [SELECT Id,Name FROM Visita__c WHERE Id =: insertVisita.Id].Name;
        
        return respond;        
    }
    //OBTENEMOS LOS CENTRO FINANCIEROS PARA MOSTRARLOS EN PANTALLA
	@AuraEnabled(cacheable=true)
    public static List<BranchUnit> getBranchUnits() {
        Set<String> setTerritoryId = new Set<String>();
        
        for(ServiceTerritory st : [SELECT ExternalID__c FROM ServiceTerritory WHERE isActive = TRUE]){
            setTerritoryId.add(st.ExternalID__c);
        }
        List<BranchUnit> branchs = [SELECT Id, Name FROM BranchUnit WHERE isActive = TRUE AND ExternalId__c IN:setTerritoryId ORDER BY Name ASC];

        return branchs;
    }
    //VALIDAMOS LOS REGISTROS CREADOS POR TIEMPOS 
    public static Map<String, Object> canCreateNewRecord(List<Contract>contractList,Boolean isCheked) {
        system.debug('contractList'+contractList);
        Boolean isWithinTimeLimit = false;
        Long timeDifferenceInMinutes = 0;
        List<Visita__c> listVisitFound = new List<Visita__c>();
        if(!contractList.isEmpty()){
            listVisitFound = [
                SELECT CreatedDate FROM Visita__c WHERE Contrato__c =: contractList ORDER BY CreatedDate DESC LIMIT 1
            ];
        }                
        if(!listVisitFound.isEmpty()){
            DateTime currentTime = System.now();
            timeDifferenceInMinutes = currentTime.getTime() - listVisitFound[0].CreatedDate.getTime();
            timeDifferenceInMinutes = timeDifferenceInMinutes / (1000 * 60);
            isWithinTimeLimit = timeDifferenceInMinutes < Integer.valueOf(MINUTES);
            
        }

        
        Map<String, Object> result = new Map<String, Object>();
        result.put('timeDifferenceInMinutes', timeDifferenceInMinutes);
        result.put('isWithinTimeLimit', isWithinTimeLimit);
        
        return result;
    }
}