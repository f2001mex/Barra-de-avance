/**
* @description       : Class controller for Lead Object
* @author            : Dalila Conti
* @group             : 
* @last modified on  : 12-18-2023
* @last modified by  : JC Cruz
**/

public without sharing class ACT_Controller_Lead implements Interface_Handle_Lead {
    
    private static final String RT_DEVELOPERNAME_GENERAL = 'General'; 
    private static final String RT_DEVELOPERNAME_CASA_DE_BOLSA = 'Casa_de_Bolsa_Posibilidad';
    private static final String RT_DEVELOPERNAME_PLANES_BENEFICIO_FISCAL = 'Planes_Beneficio_Fiscal';
    private static final String RT_DEVELOPERNAME_SEGUROS = 'Seguros';
    
    public static Data_Structure_Handle_Lead.ResultWithLeads createLead(Data_Structure_Handle_Lead.LeadObject leadsRecords) {
        Data_Structure_Handle_Lead.ResultWithLeads result = new Data_Structure_Handle_Lead.ResultWithLeads();
        
        try {
            if(String.isBlank(leadsRecords.tipoDeLead)){
                result = createPitchbookLead(leadsRecords);
            } else if(leadsRecords.tipoDeLead == 'Posibilidad'){
                result = createPosibilidadLead(leadsRecords);
            } 
            
        } catch (Exception e) {
            result.result = false;
            result.message = e.getMessage();
        }
        
        return result;
    }
    
    private static Data_Structure_Handle_Lead.ResultWithLeads createPitchbookLead (Data_Structure_Handle_Lead.LeadObject leadsRecords){
        Data_Structure_Handle_Lead.ResultWithLeads result = new Data_Structure_Handle_Lead.ResultWithLeads();
        
        List<User> usuarios = [SELECT Id, ID_ASESOR__c FROM User WHERE ID_ASESOR__c = :leadsRecords.claveAsesor];
        
        if (usuarios.isEmpty()) {
            result.result = false;
            result.message = 'There is no Asesor with that Clave Asesor.';
            return result;
        } else {
            
            if (String.isBlank(leadsRecords.MotherLastName)) {
                result.message = 'The field Mother Last Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadsRecords.FatherLastName)) {
                result.message = 'The field Father Last Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadsRecords.Name)) {
                result.message = 'The field Lead Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadsRecords.phone)) {
                result.message = 'The field Mobile Phone is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadsRecords.email)) {
                result.message = 'The field Email is required.';
                result.result = false;
                return result;
            }
            
            Lead newLead = new Lead();
            newLead.FirstName = leadsRecords.Name;
            newLead.LastName = leadsRecords.FatherLastName;
            newLead.suffix = leadsRecords.MotherLastName;
            newLead.Phone = leadsRecords.Phone;
            newLead.Email = leadsRecords.email;
            
            
            if (String.isNotBlank(leadsRecords.PostalCode)) {
                newLead.postalcode = leadsRecords.postalCode;
            }else {
                newLead.postalcode = '00000';
            }
            
            if (Lead.SObjectType.getDescribe().isCreateable()) {
                Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId();
                newLead.RecordTypeId = recordTypeId;
                newLead.OwnerId = usuarios[0].Id;
                insert newLead;
                
                Lead leadInserted = [Select Id, Name, F3_Consecutivo_ID__c From Lead where Id =: newLead.Id limit 1];
                
                Data_Structure_Handle_Lead.datosLead dLead = new Data_Structure_Handle_Lead.datosLead();
                dLead.LeadName = leadInserted.Name;
                dLead.LeadConsecutiveId = leadInserted.F3_Consecutivo_ID__c;
                dLead.LeadId = newLead.Id;
                dLead.LeadEmail = newLead.Email;
                
                
                result.lead = dLead;
                result.result = true;
                result.message = newLead.Id;
                return result;
            } else {
                result.result = false;
                result.message = 'User does not have access to create a Lead record.';
                return result;
            }
        }
    }
    
    private static Data_Structure_Handle_Lead.ResultWithLeads createPosibilidadLead(Data_Structure_Handle_Lead.LeadObject leadRecord){
        
        Data_Structure_Handle_Lead.ResultWithLeads result = new Data_Structure_Handle_Lead.ResultWithLeads();
        
        try{
            
            if (String.isBlank(leadRecord.claveAsesor)) {
                result.result = false;
                result.message = 'The field Clave Asesor is required.';
                return result;
            }
            
            if (String.isBlank(leadRecord.salution)) {
                result.message = 'The field Salution is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.MotherLastName)) {
                result.message = 'The field Mother Last Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.FatherLastName)) {
                result.message = 'The field Father Last Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.Name)) {
                result.message = 'The field Lead Name is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.phone) && String.isBlank(leadRecord.email)) {
                result.message = 'The field Mobile Phone or the Email are required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.postalCode)) {
                result.message = 'The field Postal Code is required.';
                result.result = false;
                return result;
            }
            if (String.isBlank(leadRecord.recordType)) {
                result.message = 'The field Record Type is required.';
                result.result = false;
                return result;
            }
            
            List<User> usuarios = [SELECT Id, ID_ASESOR__c FROM User WHERE ID_ASESOR__c = :leadRecord.claveAsesor];
            
            if (usuarios.isEmpty()) {
                result.result = false;
                result.message = 'There is no Asesor with that Clave Asesor.';
                return result;
            }
            
            Lead lead = new Lead();
            
            lead.OwnerId = usuarios[0].Id;
            lead.Salutation = leadRecord.salution; //Tratamiento
            lead.FirstName = leadRecord.Name; //Nombre
            if(!String.isBlank(leadRecord.middleName)){
                lead.MiddleName = leadRecord.middleName; //Segundo Nombre
            }
            lead.LastName = leadRecord.FatherLastName; //Apellido Paterno
            lead.suffix = leadRecord.MotherLastName; //Apellido Materno
            if(!String.isBlank(leadRecord.phone)){
                lead.Phone = leadRecord.Phone;
            }
            if(!String.isBlank(leadRecord.email)){
                lead.Email = leadRecord.email;
            }
            lead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(leadRecord.recordType).getRecordTypeId();
            
            lead.postalcode = leadRecord.postalCode;
            
            if(!String.isBlank(leadRecord.lineaDeAccion)){
            	lead.Campaign__c = leadRecord.lineaDeAccion; //Linea de accion
            }
            if(!String.isBlank(leadRecord.montoAlternaES)){
            	lead.Monto_Alterna_ES__c = Decimal.valueOf(leadRecord.montoAlternaES); //Alterna ES
            }
            if(!String.isBlank(leadRecord.montoAlternaUS)){
            	lead.Monto_Alterna_US__c = Decimal.valueOf(leadRecord.montoAlternaUS); //Alterna US
            }
            if(!String.isBlank(leadRecord.montoAlternaMX)){
                lead.Monto_Actinver_MX__c = Decimal.valueOf(leadRecord.montoAlternaMX); //Alterna MX
            }
            if(!String.isBlank(leadRecord.fechaProbableDeCierre)){
            	lead.Fecha_probable_de_cierre__c = Date.valueOf(leadRecord.fechaProbableDeCierre); //Fecha probable de cierre
            }
            
            insert lead;
                                
            Lead leadInserted = [Select Id, Name, F3_Consecutivo_ID__c, Email From Lead where Id =: lead.Id limit 1];
                    
            Data_Structure_Handle_Lead.datosLead dLead = new Data_Structure_Handle_Lead.datosLead();
            dLead.LeadName = leadInserted.Name;
            dLead.LeadConsecutiveId = leadInserted.F3_Consecutivo_ID__c;
            dLead.LeadId = leadInserted.Id;
            dLead.LeadEmail = leadInserted.Email;
            
            result.lead = dLead;
            result.result = true;
            result.message = leadInserted.Id;
            
            return result;
            
        } catch(Exception e){
            result.result = false;
            result.message = e.getMessage();    
            return result;
        }
    }
    
    public static Data_Structure_Handle_Lead.ResponseWithRelatedLead consultLead(string leadName, String id_Asesor) {
        Data_Structure_Handle_Lead.ResponseWithRelatedLead result = new Data_Structure_Handle_Lead.ResponseWithRelatedLead();
        
        List<User> users = new list<User>([SELECT Id,UserRoleId FROM User WHERE ID_ASESOR__c =: id_Asesor]);
        
        
        if(users.size() > 0){
            User u = users[0];
            String searchStr1 = leadName.replace('+', ' ');
            System.debug(searchStr1);
            String searchQuery = 'FIND \'' + searchStr1 + '\' RETURNING Lead(Id, Name, F3_Consecutivo_ID__c, Phone, Email, owner.Name, Owner.UserRoleId, postalCode) LIMIT 20';
            System.debug('searchQuery... ' + searchQuery);
            List<List<sObject>> searchList = search.query(searchQuery);
            List<Lead> candidatos = (List<Lead>)searchList[0];
            List<Lead> leadsVisble = new List<Lead>();
            Set<ID> setleadVisible = new Set<Id>();
            Set<ID> filterLeads = new Set<Id>();
            
            for(Lead l: candidatos){
                filterLeads.add(l.Id);
            }
            
          
            for(UserRecordAccess ul: [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess WHERE UserId =: u.Id AND RecordId IN: filterLeads]){
                if(ul.HasReadAccess ){
                    setleadVisible.add(ul.RecordId);
                }
            }
            
            for(Lead l: candidatos){
                if(u.UserRoleId.equals(l.Owner.UserRoleId))
                    setleadVisible.add(l.Id);
            }
            
            
            if(setleadVisible.size() > 0){
                for (Lead candidato : candidatos) {
                    if(setleadVisible.contains(candidato.Id)){
                        leadsVisble.add(candidato);
                    }
                }
                result.result = true;
                result.candidatos = leadsVisble;
            }else{
                result.result = false;
                result.message = 'No lead found!';
                result.candidatos = null;
            }
        }else{
            result.result = false;
            result.message = 'Id Asesor does not exists!';
        }
        System.debug('result... ' + result);
        return result;
    }
        
}