/**
* @File Name : OD_AssignUserOwners_cls.cls
* @Description :Clase que recibe ya sean Contratos o Cuentas para procesar y asignar su Owner en caso de que el 
*  ID_ASESOR__c encontrado en User ya tenga licencia
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : December 6, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 6, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_AssignUserOwners_cls {
    public static final Set<String> excludedStatus = new Set<String>(Label.StatusContract.split(';'));
    
    public static void processRecords(List<SObject> records) {
        system.debug('************EJECUCIÓN DE CLASE AssignUserOwners**********');
        //DECLARACIÓN DE VARIABLES
        Map<String,BranchUnitBusinessMember> bankersBranchUnitMap = new Map<String,BranchUnitBusinessMember>();
        Map<String,User> usersByNominaMap = new Map<String,User>();
        List<sObject> listToUpdate = new List<sObject>();
        Set<String> uniqueAdvisorIds = new Set<String>();

        //RECORREMOS LOS REGISTROS Y OBTENEMOS EL PARA CUENTAS Y CONTRATOS ID_ASESOR__c
        for (SObject record : records) {
            //VALIDAMOS EL TIPO DE OBJECTO QUE SE RECIBE (CONTRACTO - CUENTA)
            if (record.getSObjectType() == Contract.sObjectType) {
                system.debug('************ENTRO POR CONTRATO**********');
                //PARSEA A CONTRATO
                Contract contract = (Contract) record;
                
                // SOLO PROCESA CONTRATOS QUE NO ESTÉN CANCELADOS (DENTRO DE LA LABEL ASIGNADA).
                if(!excludedStatus.contains(contract.Status)){  
                    system.debug('************GUARDA REGISTRO CONTRATO**********');
                    uniqueAdvisorIds.add(contract.ID_ASESOR__c);
                }
            } else if (record.getSObjectType() == Account.sObjectType) {
                system.debug('************ENTRO POR CUENTA**********');
                //PARSEA A CUENTA
                Account account = (Account) record;
                system.debug(account.RecordTypeId);
                // SOLO PROCESA CUENTAS CON CIERTOS TIPOS DE REGISTROS
                if(Service_Utility_Trigger.isCorrectRecordTypeId(account)){
                    system.debug('************OBTENER IDASESOR**********');
                    uniqueAdvisorIds.add(account.ID_ASESOR__c);
                }
            }
        }
        // SI EL CONJUNTO DE IDS DE ASESORES NO ESTÁ VACÍO, SE CONSULTAN LOS USUARIOS
        if(!uniqueAdvisorIds.isEmpty()){
            // LLAMA A MÉTODOS DE UTILIDAD PARA OBTENER LOS USUARIOS Y CONTACTOS CORRESPONDIENTES AL ID DEL ASESOR.
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            bankersBranchUnitMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode(uniqueAdvisorIds);
        }        
        //RECORREMOS LOS REGISTROS NUEVAMENTE Y ASIGNAMOS EL OWNERID SI ENCONTRAMOS EL USUARIO 
        //SEGUN SEA EL CASO DEL OBJETO EN TURNO
        for (SObject record : records) {
            if (record.getSObjectType() == Contract.sObjectType) {
                Contract contract = (Contract) record;
                if (usersByNominaMap.containsKey(contract.ID_ASESOR__c)) {  
                    system.debug('************SE ENCONTRO USUARIO PARA ASIGNAR CONTRATO**********');
                    OD_Contract_cls.bypassTriggerExecution = true;
                    contract.OwnerId = usersByNominaMap.get(contract.ID_ASESOR__c).Id;
                    if(bankersBranchUnitMap.containskey(contract.ID_ASESOR__c)){
                        contract.BanqueroAsignado__c = bankersBranchUnitMap.get(contract.ID_ASESOR__c).Id;              
                    }else{
                        System.debug(LoggingLevel.ERROR, 'No se encontro el Branch Unit relacionado del Id Asesor');
                    }
                    listToUpdate.add(contract);
                }
            } else if (record.getSObjectType() == Account.sObjectType) {
                Account account = (Account) record;
                if (usersByNominaMap.containsKey(account.ID_ASESOR__c)) {  
                    system.debug('************SE ENCONTRO USUARIO PARA ASIGNAR CUENTA**********');
                    OD_Account_cls.bypassTriggerExecution = true;
                    account.OwnerId = usersByNominaMap.get(account.ID_ASESOR__c).Id;
                    if(bankersBranchUnitMap.containskey(account.ID_ASESOR__c)){
                        account.BanqueroAsignado__c = bankersBranchUnitMap.get(account.ID_ASESOR__c).Id;              
                    }else{
                        System.debug(LoggingLevel.ERROR, 'No se encontro el Branch Unit relacionado del Id Asesor');
                    }
                    listToUpdate.add(account);
                }
            }
        }
        
        //SE VALIDA LA LISTA VENGA LLENA PARA PODERA REALIZAR LA ACTUALIZACIÓN DE REGISTROS
        if(!listToUpdate.isEmpty()){
            system.debug('*********+*****REGISTROS PARA ACTUALIZAR***********');
            update listToUpdate;
        }
        OD_Contract_cls.bypassTriggerExecution = false;
        OD_Account_cls.bypassTriggerExecution = false;

    }
}