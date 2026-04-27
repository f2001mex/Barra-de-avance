/****************************************************************************************************
    Modificado por  : Isaac Canche (isaac.alonzo@vasscompany.com)
    Proyecto        : Actinver - Bitácora anfitrión
    Descripción     : Clase que generará data de pruebas para clases testse utiliza por el omniscript del scheduler
    
    Cambios (Versiones)
    -----------------------------------------------------------------------------------------------------
    No.     Fecha           Autor                   Descripción
    -----   ----------      --------------------    -----------------------------------------------------
	1.0.    2024-09-24      Desconocido.            Creo la clase
    2.0     2024-09-24      Canche Isaac            Se modifico la clase original para crear service appointment de Accounts.    
    2.1     2024-09-25      Canche Isaac            integro metodo savePreRegistrationVisit,saveServiceByVisit,getBranchUnit para relacionar Cita con Visita
*/

global without sharing class F4_SchedulerCalendar_SelectWorkTypes implements omnistudio.VlocityOpenInterface, Callable { 
    public class OmniscriptException extends Exception {}
    public List<WorkTypeGroup> workTypeGroups;
    public String query = 'SELECT Id, Name FROM WorkTypeGroup WHERE IsActive = TRUE ';

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
     }

     public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        try {
            if (methodName.equals('PopulatePicklist')){
                PopulatePicklist(inputMap, outMap, options);
            } else if (methodName.equals('createServiceAppointment')){
                createServiceAppointment(inputMap, outMap, options);
            } else if(methodName.equals('validateParentRecord_Lead')){
                validateParentRecordLead(inputMap, outMap, options);
            }  else if(methodName.equals('PopulatePicklist_Product')){
                PopulatePicklist_Product(inputMap, outMap, options);
            }  else if(methodName.equals('validateParentRecord_Account')){
                validateParentRecordAccount(inputMap, outMap, options);
            } 

        } catch(Exception e) {
            throw new OmniscriptException('Exception: ' + 
                e.getMessage() + ' ' +
                e.getStackTraceString()
            );
         }
         return true;
     }
    
    // add the map under options to populate the picklist
    private List<Map<String, Object>> PopulatePicklist(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options){
        
        List<Map<String, Object>> optionList = new List<Map<String, Object>>();
        query += ' ORDER BY Name ASC';
        workTypeGroups = Database.query(query);

        if(workTypeGroups.size() > 0){
            for (WorkTypeGroup acc : workTypeGroups){
                Map<String, Object> option = new Map<String, Object>();
                
                option.put('name', acc.Id);
                option.put('value',acc.Name);
                optionList.add(option);
            }
            
            outMap.put('options', optionList);
        
        } else{
            outMap.put('options', 'No worktype found');
        }
        return optionList;
    }

    private List<Map<String, Object>> PopulatePicklist_Product(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options){
        List<Map<String, Object>> optionList = new List<Map<String, Object>>();
        query += ' AND Is_new_product_scheduler__c = TRUE ORDER BY Name ASC';

        workTypeGroups = Database.query(query);
        if(workTypeGroups.size() > 0){
            WorkTypeGroup acc = workTypeGroups[0];

            Map<String, Object> option = new Map<String, Object>();
            option.put('WorkTypeGroupSelect', acc.Id);

            outMap.put('WorkTypeSelection', option);
        
        } else{
            outMap.put('options', 'No worktype found');
        }
        return optionList;
    }
    
    private void createServiceAppointment(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options){
        ServiceAppointment newAppointment = new ServiceAppointment();
        Event calendarEvent = new Event();
        try {
            String startTime = String.valueOf(input.get('schedStartTime'));
            String endTime = String.valueOf(input.get('schedEndTime'));
            String subject = String.valueOf(input.get('subject'));
            String recordId = String.valueOf(input.get('recordId'));
            String description = String.valueOf(input.get('description'));
            String tipo = String.valueOf(input.get('tipo'));
            String motivo = String.valueOf(input.get('motivo'));
            String submotivo = String.valueOf(input.get('submotivo'));
            String motivoAbierto = String.valueOf(input.get('motivoAbierto'));
            String eventOwnerId = String.valueOf(input.get('resourceOwnerId'));
            String phone = String.valueOf(input.get('phoneAppointment'));
            String address = String.valueOf(input.get('locationAddress'));
            String additionalInformation = String.valueOf(input.get('additionalInformation'));
            String comments = String.valueOf(input.get('commentsAppointment'));
            String workTypeGroupId = String.valueOf(input.get('workTypeGroupId'));
            String serviceTerritoryId = String.valueOf(input.get('serviceTerritoryId'));
            String parentRecordType = String.valueOf(input.get('parentRecordType'));
            String quienAtiende = String.valueOf(input.get('quienAtiende'));
            
            newAppointment = new ServiceAppointment (
                SchedStartTime = (DateTime)Json.deserialize('"'+startTime+'"', DateTime.class),
                SchedEndTime = (DateTime)Json.deserialize('"'+endTime+'"', DateTime.class),
                Email = String.valueOf(input.get('email')),
                TipoVisita__c = tipo,
                MotivoVisita__c = motivo,
                Submotivo__c = submotivo,
                MotivoAbierto__c = motivoAbierto,
                QuienAtiende__c = quienAtiende,
                Subject = subject,
                Phone = phone,
                Street = address,
                AdditionalInformation = additionalInformation,
                Comments = comments,
                Description = description,
                ParentRecordId = recordId,
                WorkTypeGroupId__c = workTypeGroupId,
                AppointmentType = String.valueOf(input.get('appointmentType')),
                ServiceTerritoryId = serviceTerritoryId
                
            );

            calendarEvent = new Event(
                Subject = subject,
                Description = description,
                OwnerId = eventOwnerId,
                EndDateTime = (DateTime)Json.deserialize('"'+endTime+'"', DateTime.class),
                StartDateTime = (DateTime)Json.deserialize('"'+startTime+'"', DateTime.class)
            );

            if (parentRecordType != 'Lead' && parentRecordType != 'Contact') {
                calendarEvent.WhatId = recordId;
            }else {
                calendarEvent.WhoId = recordId;
            }

            

            insert newAppointment;
            insert calendarEvent;
        }catch (Exception e) {
            // Handling DML exception
            System.debug('DML Exception: ' + e.getMessage());
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_INSERT_SER_APPO_001', 'message'   => 'Error al insertar CITA', 'request'   => e.getMessage()});
        }
        Visita__c objVisita = savePreRegistrationVisit(newAppointment,input);
        saveServiceByVisit(objVisita,input);
        outMap.put(
            'ServiceAppointmentId', newAppointment.Id
        );
    }

    private void validateParentRecordLead(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options){
        String leadExternalPhone = String.valueOf(input.get('numero_telefono'));
        String leadFirstName = String.valueOf(input.get('lead_firstname'));
        String leadLastName = String.valueOf(input.get('lead_lastname'));
        String suffix = String.valueOf(input.get('lead_suffix'));
        String leadEmail = String.valueOf(input.get('lead_email'));
        String leadCompany = String.valueOf(input.get('lead_company'));

        Lead appointmentParentRecord;
        try{
            appointmentParentRecord = [SELECT Id FROM Lead 
                                    WHERE Numero_Telefono__c =:leadExternalPhone 
                                    OR Phone =:leadExternalPhone 
                                    OR Email =:leadEmail
                                    ORDER BY CreatedDate DESC LIMIT 1];
        } catch(QueryException qe){
            appointmentParentRecord = new Lead(
                Numero_Telefono__c = leadExternalPhone,
                Phone = leadExternalPhone,
                FirstName = leadFirstName,
                LastName = leadLastName,
                Suffix = suffix,
                Email = leadEmail,
                Company = leadCompany,
                PostalCode = '00000'
            );
            
            insert appointmentParentRecord;
        }

        outMap.put(
            'recordId', appointmentParentRecord.Id
        );
    }

    private void validateParentRecordAccount(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        String accountPhone = String.valueOf(input.get('numero_telefono'));
        String accountEmail = String.valueOf(input.get('correo'));

        Telefono_de_Contrato__c accountPhoneParentRecord = getTelefonoDeContrato(accountPhone);
        Correo_de_Contrato__c accountEmailParentRecord = getCorreoDeContrato(accountEmail);

        if (accountPhoneParentRecord != null) outMap.put('recordId', accountPhoneParentRecord.IDSap__r.AccountId);
        
        if (accountEmailParentRecord != null && accountPhoneParentRecord == null) outMap.put('recordId', accountEmailParentRecord.NUM_CONTRATO__r.AccountId);
        
        if (accountEmailParentRecord == null && accountPhoneParentRecord == null) outMap.put('noRecordId', 'Cliente no encontrado');
        
    }

    public Correo_de_Contrato__c getCorreoDeContrato(String strEmail) {
        try {
            Correo_de_Contrato__c accountEmailParentRecord = [SELECT NUM_CONTRATO__r.AccountId 
                                                              FROM Correo_de_Contrato__c 
                                                              WHERE Contract_email__c =:strEmail 
                                                              ORDER BY CreatedDate DESC LIMIT 1];
                                                            
            return accountEmailParentRecord;
        }
        catch (QueryException e) {
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_SOQL_EMAIL_CONTRACT_001', 'message'   => 'Error al consultar correo contrato', 'request'   => e.getMessage()});
            return null;
        } 
    } 

    public Telefono_de_Contrato__c getTelefonoDeContrato(String strTelefono) {
        try {
            Telefono_de_Contrato__c accountPhoneParentRecord = [SELECT IDSap__r.AccountId 
                                                              FROM Telefono_de_Contrato__c 
                                                              WHERE Phone__c =:strTelefono 
                                                              ORDER BY CreatedDate 
                                                              DESC LIMIT 1];
            return accountPhoneParentRecord;
        }
        catch (QueryException e) {
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_SOQL_TEL_CONTRACT_001', 'message'   => 'Error al consultar Telefono contrato', 'request'   => e.getMessage()});
            return null;
        } 
    } 
    
    public static Visita__c savePreRegistrationVisit(ServiceAppointment objServiceAppointment, Map<String, Object> input) {

        Visita__c objVisita = new Visita__c();
        try {
            Id strRecordId  = (Id)input.get('recordId');
            String strPhone = String.valueOf(input.get('phoneAppointment'));
            String strEmail = String.valueOf(input.get('email'));
            String strServiceTerritoryId = String.valueOf(input.get('serviceTerritoryId'));
            String strParentRecordType   = String.valueOf(input.get('parentRecordType'));
            String strName      = String.valueOf(input.get('name'));
            String strLastName  = String.valueOf(input.get('lastName'));
            String strSuffix    = String.valueOf(input.get('suffix'));

            String strDeveloperName = strParentRecordType != 'Account' ? 'Prospecto' : 'Cliente';
            Id strRecordTypeId      = Schema.SObjectType.Visita__c.getRecordTypeInfosByName().get(strDeveloperName).getRecordTypeId();
            BranchUnit objBranchUnit = getBranchUnit(strServiceTerritoryId); 

            objVisita.RecordTypeId = strRecordTypeId;
            objVisita.Etapa__c     = 'Pre-registro';
            objVisita.Cita__c      = objServiceAppointment.Id;
            objVisita.Correo__c    = strEmail;
            objVisita.Telefono__c  = strPhone;
            objVisita.CentroFinanciero__c = objBranchUnit.Id;
            objVisita.Nombre__c           = strName;
            objVisita.ApellidoPaterno__c  = strLastName;
            objVisita.ApellidoMaterno__c  = strSuffix;
            if(strParentRecordType == 'Lead')   objVisita.Candidato__c = strRecordId;
            if(strParentRecordType == 'Account') objVisita.Cuenta__c   = strRecordId;
            insert objVisita;

            return objVisita;
        }catch (DmlException e) {
            // Handling DML exception
            System.debug('DML Exception: ' + e.getMessage());
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_INSERT_VISIT_001', 'message'   => 'Error al insertar Pre Registro VISITA', 'request'   => e.getMessage()});
            return null;
        }
    } 
    
    public static void saveServiceByVisit(Visita__c objVisita, Map<String, Object> input) {
        Servicio__c objServicio = new Servicio__c();
        try {
            String strTipo          = String.valueOf(input.get('tipo'));
            String strMotivo        = String.valueOf(input.get('motivo'));
            String strSubmotivo     = String.valueOf(input.get('submotivo'));
            String strMotivoAbierto = String.valueOf(input.get('motivoAbierto'));
            String strQuienAtiende  = String.valueOf(input.get('quienAtiende'));
            Id strRecordTypeId      = Schema.SObjectType.Servicio__c.getRecordTypeInfosByName().get(strQuienAtiende).getRecordTypeId();
    
            objServicio.RecordTypeId     = strRecordTypeId;
            objServicio.Visita__c        = objVisita.Id;
            objServicio.Etapa__c         = 'Pre-registro';
            objServicio.TipoVisita__c    = strTipo;
            objServicio.Motivo__c        = strMotivo;
            objServicio.Submotivo__c     = strSubmotivo;
            objServicio.MotivoAbierto__c = strMotivoAbierto;
            objServicio.QuienAtiende__c  = strQuienAtiende;
            insert objServicio;
        }catch (DmlException e) {
            // Handling DML exception
            System.debug('DML Exception: ' + e.getMessage());
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_INSERT_SERVICE_002', 'message'   => 'Error al insertar Pre Registro SERVICIO de Visita', 'request'   => e.getMessage()});
        }
    } 

    public static BranchUnit getBranchUnit(String strServiceTerritoryId) {
        try {
            ServiceTerritory objServiceTerritory= [SELECT ExternalID__c FROM ServiceTerritory WHERE Id =:strServiceTerritoryId LIMIT 1];
            if(String.isBlank(objServiceTerritory.ExternalID__c))  throw new QueryException('El "ServiceTerritory" seleccionado no cuenta con un "código asignado"'); 
            BranchUnit objBranchUnit = [SELECT Id 
                                        FROM BranchUnit 
                                        WHERE ExternalId__c =:objServiceTerritory.ExternalID__c
                                        ORDER BY CreatedDate DESC LIMIT 1];
            if(objBranchUnit == null && String.isBlank(objBranchUnit.ExternalID__c))  throw new QueryException('El "ServiceTerritory" NO esta relacionado con una "BranchUnit"'); 
                 
            return objBranchUnit;
        }
        catch (QueryException e) {
            EventLogger.error(new Map<String, String>{'contextId' => null,'type' => '','errorCode' => 'ERR_SOQL_GET_BRANCH_001', 'message'   => 'Error al consultar BranchUnit a través de ServiceTerritory', 'request'   => e.getMessage()});
            return null;
        } 
    } 
}