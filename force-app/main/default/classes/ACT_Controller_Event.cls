/**
 * @description       : 
 * @author            : JC Cruz
 * @group             : 
 * @last modified on  : 01-09-2024
 * @last modified by  : JC Cruz
**/
public without sharing class ACT_Controller_Event implements Interface_Handle_Event {
    
    public static Data_Structure_Handle_Task.ResultTask createEvent(Data_Structure_Handle_Task.EventObject taskEvent){
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        try{
            if(String.isBlank(taskEvent.bp)){
                result.message = 'BP is required.';
                result.result = false;
            } else{
                List<Account> listacc = [SELECT Id, Person_Type__c FROM Account WHERE Client_ID__c =: taskevent.bp];

                if(listacc.size() > 0 ){
                    Account acc = listacc[0];
                    if(acc.Person_Type__c ==  'FISICA'){
               
                        PersonLifeEvent newPersonEvent = new PersonLifeEvent();
                        newPersonEvent.Name = taskEvent.eventName;
                        newPersonEvent.EventType = taskEvent.eventType;
                        newPersonEvent.EventDescription = (taskEvent.description == null)? '' : taskEvent.description;
                        newPersonEvent.eventDate = taskEvent.eventDate;
                        
                        if(String.isBlank(taskEvent.primaryPersonId)){
                            Contact contacto = [SELECT Id, Name FROM Contact WHERE AccountId =: acc.Id LIMIT 1];
                            newPersonEvent.primaryPersonId = contacto.Id ;
                        } else{
                            newPersonEvent.primaryPersonId = taskEvent.primaryPersonId;
                        }
                        
                        if(taskEvent.expirationDate != null){
                            newPersonEvent.ExpirationDate = taskEvent.expirationDate;
                        }
                        
                        if(String.valueOf(taskEvent.relatedPersonId) != ''){
                            newPersonEvent.relatedPersonId = taskEvent.relatedPersonId;
                        }
                        
                        if(taskEvent.eventLocation != null){
                            newPersonEvent.EventLocationStreet = taskEvent.eventLocation.street;
                            newPersonEvent.EventLocationState = taskEvent.eventLocation.state;
                            if(taskEvent.eventLocation.postalCode != null){
                                newPersonEvent.EventLocationPostalCode = taskEvent.eventLocation.postalCode;
                            }
                            newPersonEvent.EventLocationCountry = taskEvent.eventLocation.country;
                            newPersonEvent.EventLocationCity = taskEvent.eventLocation.city;
                        }
                        
                        if(PersonLifeEvent.SObjectType.getDescribe().isCreateable()){
                            insert newPersonEvent;
                            
                            result.result = true;
                            result.message = newPersonEvent.Id;
                        }
                        
                    } else if(acc.Person_Type__c ==  'MORAL') {
                        BusinessMilestone businessMilestone = new BusinessMilestone();
                        businessMilestone.Name = taskEvent.eventName;
                        businessMilestone.MilestoneDescription = (taskEvent.description == null)? '' : taskEvent.description;
                        businessMilestone.MilestoneDate = taskEvent.eventDate;
                        businessMilestone.PrimaryAccountId = (String.isBlank(taskEvent.primaryAccountId))? acc.Id : taskEvent.primaryAccountId;
                        businessMilestone.MilestoneType = taskEvent.eventType;
                        
                        if(taskEvent.expirationDate != null){
                            businessMilestone.ExpirationDate = taskEvent.expirationDate;
                        }
                        
                        if(taskEvent.eventLocation != null){
                            businessMilestone.EventLocation__Street__s = (taskEvent.eventLocation.street == null)? '' : taskEvent.eventLocation.street;
                            businessMilestone.EventLocation__StateCode__s = (taskEvent.eventLocation.state == null)? '' : taskEvent.eventLocation.state;
                            businessMilestone.EventLocation__PostalCode__s = (taskEvent.eventLocation.postalCode == null)? '' : taskEvent.eventLocation.postalCode;
                            businessMilestone.EventLocation__CountryCode__s = (taskEvent.eventLocation.country == null)? '' : taskEvent.eventLocation.country;
                            businessMilestone.EventLocation__City__s = (taskEvent.eventLocation.city == null)? '' : taskEvent.eventLocation.city;
                        }
                        
                        insert businessMilestone;
                        
                        result.result = true;
                        result.message = businessMilestone.Id;
                    }
                }else{
                    result.result = false;
                    result.message = 'BP is not assigned to an Account';
                }
            }
        }catch(Exception ex){
            result.result = false;
            result.message = ex.getMessage();
        }
        return result;
    }
    
    public static Data_Structure_Handle_Task.ResultTask changeEventStatus(Data_Structure_Handle_Task.TaskObject taskEvent){
        // Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        
        // try{
        //     Task newTask = new Task();
        //     newTask.Id = taskEvent.id;
        //     newTask.Status = (taskEvent.isClosed)? 'Completado':'Abierto';
        
        //     if(Task.SObjectType.getDescribe().isUpdateable()){
        //         update newTask;
        
        //         result.result = true;
        //         result.message = (taskEvent.isClosed)? 'Evento Completado':'Evento Abierto';
        //     }else{
        //         result.result = false;
        //         result.message = 'The user does not have access to the Task Object!';
        //     }
        // }catch(Exception ex){
        //     result.result = false;
        //     result.message = ex.getMessage() + ' : ' + ex.getStackTraceString();
        // }
        
        // return result;
        
        return null;
    }
    
    public static Data_Structure_Handle_Task.ResponseWithEvent getEventDetails(Id eventId){
        
        Data_Structure_Handle_Task.ResponseWithEvent result = new Data_Structure_Handle_Task.ResponseWithEvent();
        Data_Structure_Handle_Task.Location eventLocation = new Data_Structure_Handle_Task.Location();
        
        Map<String, Object> eventToReturn = new Map<String, Object>();
        
        String objectToQuery = String.valueOf(eventId.getSObjectType());
        
        if(objectToQuery == 'PersonLifeEvent'){
            
            List<PersonLifeEvent> eventoVidaPersonas = [SELECT Id, Name, EventType, EventDescription, EventDate, PrimaryPersonId, EventLocationStreet, EventLocationState, EventLocationCity, EventLocationPostalCode, EventLocationCountry, ExpirationDate FROM PersonLifeEvent WHERE Id = :eventId LIMIT 1];
            
            if(eventoVidaPersonas.isEmpty()){
                result.result = false;
                result.message = 'There is no event with such ID';
            } else{
                result.result = true;
                
                eventToReturn.put('Id', eventoVidaPersonas[0].Id);
                eventToReturn.put('EventName', eventoVidaPersonas[0].Name);
                eventToReturn.put('EventType', eventoVidaPersonas[0].EventType);
                eventToReturn.put('EventDate', eventoVidaPersonas[0].EventDate);
                eventToReturn.put('PrimaryPersonId', eventoVidaPersonas[0].PrimaryPersonId);
                eventToReturn.put('Description', eventoVidaPersonas[0].EventDescription);
                eventToReturn.put('Street', eventoVidaPersonas[0].EventLocationStreet);
                eventToReturn.put('City', eventoVidaPersonas[0].EventLocationCity);
                eventToReturn.put('State', eventoVidaPersonas[0].EventLocationState);
                eventToReturn.put('PostalCode', eventoVidaPersonas[0].EventLocationPostalCode);
                eventToReturn.put('Country', eventoVidaPersonas[0].EventLocationCountry);
                eventToReturn.put('ExpirationDate', eventoVidaPersonas[0].ExpirationDate);
                
                result.message = 'Event details return successfully.';
                result.event = eventToReturn; 
            }
            
        } else if(objectToQuery == 'BusinessMilestone'){
            List<BusinessMilestone> eventoClaveComercial = [SELECT Id, Name, MilestoneType, MilestoneDescription, MilestoneDate, PrimaryAccountId, EventLocation__Street__s, EventLocation__StateCode__s, EventLocation__PostalCode__s, EventLocation__CountryCode__s, EventLocation__City__s, ExpirationDate FROM BusinessMilestone WHERE Id = :eventId LIMIT 1];
            if(eventoClaveComercial.isEmpty()){
                result.result = false;
                result.message = 'There is no event with such ID';
                
            } else{
                result.result = true;
                eventToReturn.put('Id', eventoClaveComercial[0].Id);
                eventToReturn.put('EventName', eventoClaveComercial[0].Name);
                eventToReturn.put('EventType', eventoClaveComercial[0].MilestoneType);
                eventToReturn.put('EventDate', eventoClaveComercial[0].MilestoneDate);
                eventToReturn.put('PrimaryAccountId', eventoClaveComercial[0].PrimaryAccountId);
                eventToReturn.put('Description', eventoClaveComercial[0].MilestoneDescription);
                eventToReturn.put('Street', eventoClaveComercial[0].EventLocation__Street__s);
                eventToReturn.put('City', eventoClaveComercial[0].EventLocation__City__s);
                eventToReturn.put('Country', eventoClaveComercial[0].EventLocation__CountryCode__s);
                eventToReturn.put('State', eventoClaveComercial[0].EventLocation__StateCode__s);
                eventToReturn.put('PostalCode', eventoClaveComercial[0].EventLocation__PostalCode__s);
                eventToReturn.put('ExpirationDate', eventoClaveComercial[0].ExpirationDate);
                
                result.message = 'Event details return successfully.';
                result.event = eventToReturn;
            }
        } else{
            result.message = 'The ID does not correspond to a record in the event object.';
            result.result = false;
        }
        
        
        return result;
    }
    
    public static Data_Structure_Handle_Task.ResultTask editEventById(Id eventId, Data_Structure_Handle_Task.EventObject taskEvent){
        
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
        Data_Structure_Handle_Task.Location eventLocation = new Data_Structure_Handle_Task.Location();
                
        try{
            String objectToQuery = String.valueOf(eventId.getSObjectType());
            
            if(objectToQuery == 'PersonLifeEvent'){
                
                PersonLifeEvent newPersonEvent = new PersonLifeEvent();
                newPersonEvent.Id = eventId;
                if(!String.isBlank(taskEvent.eventName)){
                    newPersonEvent.Name = taskEvent.eventName;
                }
                if(!String.isBlank(taskEvent.description)){
                    newPersonEvent.EventDescription = taskEvent.description;
                }
                if(taskEvent.eventDate != null){
                    newPersonEvent.eventDate = taskEvent.eventDate;
                }    
                if(!String.isBlank(taskEvent.relatedPersonId)){
                    newPersonEvent.relatedPersonId = taskEvent.relatedPersonId;
                }
                
                if(taskEvent.expirationDate != null){
                        newPersonEvent.ExpirationDate = taskEvent.expirationDate;
                    }
                
                if(taskEvent.eventLocation != null){
                    if(!String.isBlank(taskEvent.eventLocation.street)){
                        newPersonEvent.EventLocationStreet = taskEvent.eventLocation.street;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.state)){
                        newPersonEvent.EventLocationState = taskEvent.eventLocation.state;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.postalCode)){
                        newPersonEvent.EventLocationPostalCode = taskEvent.eventLocation.postalCode;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.country)){
                        newPersonEvent.EventLocationCountry = taskEvent.eventLocation.country;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.city)){
                        newPersonEvent.EventLocationCity = taskEvent.eventLocation.city;
                    }
                }
                
                if(PersonLifeEvent.SObjectType.getDescribe().isCreateable()){
                    upsert newPersonEvent;
                    
                    result.result = true;
                    result.message = 'The event was update successfully.';
                }
                
            } else if(objectToQuery == 'BusinessMilestone'){
                
                BusinessMilestone businessMilestone = new BusinessMilestone();
                businessMilestone.Id = eventId;
                if(!String.isBlank(taskEvent.eventName)){
                    businessMilestone.Name = taskEvent.eventName;
                }
                if(!String.isBlank(taskEvent.description)){
                    businessMilestone.MilestoneDescription = taskEvent.description;
                }
                if(taskEvent.eventDate != null){
                    businessMilestone.MilestoneDate = taskEvent.eventDate;
                }
                
                if(taskEvent.expirationDate != null){
                    businessMilestone.ExpirationDate = taskEvent.expirationDate;
                }
                
                if(taskEvent.eventLocation != null){
                    if(!String.isBlank(taskEvent.eventLocation.street)){
                        businessMilestone.EventLocation__Street__s = taskEvent.eventLocation.street;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.state)){
                        businessMilestone.EventLocation__StateCode__s = taskEvent.eventLocation.state;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.postalCode)){
                        businessMilestone.EventLocation__PostalCode__s = taskEvent.eventLocation.postalCode;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.country)){
                        businessMilestone.EventLocation__CountryCode__s = taskEvent.eventLocation.country;
                    }
                    if(!String.isBlank(taskEvent.eventLocation.city)){
                        businessMilestone.EventLocation__City__s = taskEvent.eventLocation.city;
                    }
                }        
                upsert businessMilestone;
                
                result.result = true;
                result.message = 'The event was update successfully.';  
                
            } else{
                result.message = 'The ID does not correspond to a record in the event object.';
                result.result = false;
            }
            
            return result;
            
        } catch(Exception e){
            result.message = 'An error occurred during the process.';
            result.result = false;
            return result;
        }     
    }
    
    public static Data_Structure_Handle_Task.ResultTask deleteEventById(Id eventId){
        Data_Structure_Handle_Task.ResultTask result = new Data_Structure_Handle_Task.ResultTask();
                
        try{
            String objectToQuery = String.valueOf(eventId.getSObjectType());
            
            if(objectToQuery == 'PersonLifeEvent'){
                
                PersonLifeEvent event = [SELECT Id FROM PersonLifeEvent WHERE Id =: eventId LIMIT 1];
                delete event;
                
                result.result = true;
                result.message = 'The event was delete successfully.'; 
                
            } else if(objectToQuery == 'BusinessMilestone'){

                BusinessMilestone event = [SELECT Id FROM BusinessMilestone WHERE Id =: eventId LIMIT 1];
                delete event;
                
                result.result = true;
                result.message = 'The event was delete successfully.'; 
                
            } else{
                result.message = 'The ID does not correspond to a record in the event object.';
                result.result = false;
            }
            
            return result;
            
        } catch(Exception e){
            result.message = 'An error occurred during the process.';
            result.result = false;
            return result;
        }
    }    

    public static Data_Structure_Handle_Task.ResponseWithRelatedPerson consultRelatedPerson(string contactName) {
        Data_Structure_Handle_Task.ResponseWithRelatedPerson result = new Data_Structure_Handle_Task.ResponseWithRelatedPerson();
        //String soqlQuery = 'SELECT Id, Name FROM Contact WHERE Name LIKE \'%' +  contactName.replace('+',' ')  + '%\' LIMIT 20';
        String searchStr1 = '*'+contactName.replace('+', ' ')+'*';
        String searchQuery = 'FIND \'' + searchStr1 + '\' IN ALL FIELDS RETURNING Contact(Id,name)';
       
          List<List<sObject>> searchList = search.query(searchquery);
          List<Contact> contactos = (list<Contact>)searchList[0];
        if(contactos.isEmpty()){
            result.result = false;
            result.message = 'No contact found ' + contactName.replace('+',' ');
        } else {
            result.result = true;
            result.contactos = contactos;
        }
        return result;
    }
}