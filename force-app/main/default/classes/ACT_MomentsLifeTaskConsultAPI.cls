/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 11-21-2023
* @last modified by  : JC Cruz
**/
@RestResource(urlMapping='/ACT_MomentsLifeTaskConsult/*')
global with sharing  class ACT_MomentsLifeTaskConsultAPI {
    @HttpPost
    
    global static list<ResultTask> getTaskList(objtask records) {
        List<ResultTask> ltsInsert = new List<ResultTask>();
        
        ResultTask resultado=new ResultTask ();
        List<listEvenAcc> taskEveAcc = new List<listEvenAcc>();
        List<PersonLifeEvent> personEvent  =  new List<PersonLifeEvent>(); 
        List<BusinessMilestone> BussEvent =  new List<BusinessMilestone>();
        Try
        {
            Date startDateTime = null;
            Date EndDateTime = null;
            Date fechaExpirationDate = null;
            Time horaExpirationDate = null;
            Datetime  ExpirationDateTime = null;

            if(records.RecordTypeAcc == 'FISICA'){
               if((!String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))){
                   System.debug('Ambos');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    
                    personEvent = [select id,Name,OwnerId, PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState
                    from PersonLifeEvent 
                    WHERE PrimaryPerson.Account.Client_ID__c = :records.BP and EventType = :records.GrupoEvento and EventDate >=: startDateTime and EventDate <=: EndDateTime];
  
                }else if ((String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))) {
                     System.debug('end');
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState
                    from PersonLifeEvent 
                    WHERE PrimaryPerson.Account.Client_ID__c = :records.BP and EventType = :records.GrupoEvento and EventDate <=: EndDateTime];
                    
                }
                else if((!String.isBlank(records.StartDate)) && (String.isBlank(records.EndDate))){
                     System.debug('Start');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState
                    from PersonLifeEvent 
                    WHERE PrimaryPerson.Account.Client_ID__c = :records.BP and EventType = :records.GrupoEvento and EventDate >=: startDateTime];
                    
                }else{
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState
                                                     from PersonLifeEvent 
                                                     WHERE PrimaryPerson.Account.Client_ID__c = :records.BP and EventType = :records.GrupoEvento];
                }

                if(records.GrupoEvento != null){
                    If(personEvent != null){
                        for (PersonLifeEvent perRec : personEvent) {
                            listEvenAcc acc = new listEvenAcc();
                            acc.GrupoEventoVida = perRec.EventType;
                            acc.NombreEvento = perRec.Name;
                            acc.PersonaPrincipal = perRec.PrimaryPerson.Account.Name;
                           
                            
                            
                            Datetime  eventDateTime  = perRec.EventDate;
                            
                            Date fecha = eventDateTime.date();
                                String fechaString = fecha.format();
                            
                            Time hora = eventDateTime.time();
                            Integer horas = hora.hour();
                            Integer minutos = hora.minute();
                            Integer segundos = hora.second();
                            String horaComoString = horas.format() + ':' + minutos.format() + ':' + segundos.format();
                            
                            acc.FechaEvento = fechaString;
                            acc.HoraEvento = horaComoString;
                            acc.DescripcionEvento = perRec.EventDescription;
                            acc.PersonaRelacionada = perRec.RelatedPerson.Account.Id;
                            acc.IdUnicoEventoVida = perRec.Id;
                            
                            if(perRec.ExpirationDate != null){
                                ExpirationDateTime  = perRec.ExpirationDate;
                            
                                fechaExpirationDate = ExpirationDateTime.date();
                                    String fechaStringExpirationDate = fechaExpirationDate.format();
                                
                                horaExpirationDate = ExpirationDateTime.time();
                                Integer horasExpirationDate = horaExpirationDate.hour();
                                Integer minutosExpirationDate = horaExpirationDate.minute();
                                Integer segundosExpirationDate = horaExpirationDate.second();
                                String horaComoStringExpirationDate = horasExpirationDate.format() + ':' + minutosExpirationDate.format() + ':' + segundosExpirationDate.format();
                                
                                
                                acc.HoraVencimiento = horaComoStringExpirationDate;
                                acc.FechaVencimiento = fechaStringExpirationDate;      
                            }

                            acc.DescripcionVencimiento = perRec.ExpirationDescription;
                            acc.UbicacionEvento = perRec.EventLocationStreet;
                            acc.CalleNumero = perRec.EventLocationStreet;
                            acc.CodigoPostal = perRec.EventLocationPostalCode;
                            acc.Ciudad = perRec.EventLocationCity;
                            acc.estado = perRec.EventLocationState;
                            acc.Pais = perRec.EventLocationCountry;
                            acc.IdUnicoEventoVida = perRec.Id;
                            taskEveAcc.add(acc);
                        } 
                        resultado.result = true;
                        resultado.message = 'Eventos encontrados';
                        resultado.Event_Lst_result = taskEveAcc;
                        ltsInsert.add(resultado);
                    }
                }
            }
            
            If(records.RecordTypeAcc == 'MORAL'){
                
               if((!String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))){
                   System.debug('Ambos');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate).addDays(-1);
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate).addDays(1);
                    
                     BussEvent = [select id,EventLocation__Street__s,EventLocation__PostalCode__s,EventLocation__City__s,EventLocation__StateCode__s,EventLocation__CountryCode__s, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,EventLocation__c
                                                     from BusinessMilestone 
                                                     WHERE PrimaryAccount.Client_ID__c = :records.BP and MilestoneType = :records.GrupoEvento and MilestoneDate >=: startDateTime and MilestoneDate <=: EndDateTime];
                     
                                                     //'2023-10-26'
                                                     //SF => YYYY-MM-DDThh:mm:ss-hh:mm 2023-10-26T15:00:00.000+0000
                    
                }else if ((String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))) {
                     System.debug('end');
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate).addDays(1);
                    
                    BussEvent = [select id,EventLocation__Street__s,EventLocation__PostalCode__s,EventLocation__City__s,EventLocation__StateCode__s,EventLocation__CountryCode__s, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,EventLocation__c
                                                     from BusinessMilestone 
                                                     WHERE PrimaryAccount.Client_ID__c = :records.BP and MilestoneType = :records.GrupoEvento and MilestoneDate <=: EndDateTime ];
                    
                }
                else if((!String.isBlank(records.StartDate)) && (String.isBlank(records.EndDate))){
                     System.debug('Start');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate).addDays(-1);
                    
					BussEvent = [select id,EventLocation__Street__s,EventLocation__PostalCode__s,EventLocation__City__s,EventLocation__StateCode__s,EventLocation__CountryCode__s, Name,OwnerId, PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,EventLocation__c
                                                     from BusinessMilestone 
                                                     WHERE PrimaryAccount.Client_ID__c = :records.BP and MilestoneType = :records.GrupoEvento and MilestoneDate >=: startDateTime];
                    
                }else{
                    BussEvent = [select id,EventLocation__Street__s,EventLocation__PostalCode__s,EventLocation__City__s,EventLocation__StateCode__s,EventLocation__CountryCode__s, Name ,OwnerId, PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,EventLocation__c
                                                     from BusinessMilestone 
                                                     WHERE PrimaryAccount.Client_ID__c = :records.BP and MilestoneType = :records.GrupoEvento ];
                    
                    System.debug(BussEvent);
                }

                if(records.GrupoEvento != null){
                    If(BussEvent != null){
                        for (BusinessMilestone BussRec : BussEvent) {
                        listEvenAcc acc = new listEvenAcc();
                        acc.IDAsesor = BussRec.OwnerId;
                        acc.BP = BussRec.PrimaryAccount.Client_ID__c;
                        acc.IDPersonaMoral = BussRec.PrimaryAccount.Client_ID__c;
                        acc.GrupoEventoClave = BussRec.MilestoneType;
                        acc.NombreEvento = BussRec.Name;
                        acc.PersonaPrincipal = BussRec.PrimaryAccount.Name;
                        
                        if(BussRec.MilestoneDate != null){
                            Datetime  eventDateTime  = BussRec.MilestoneDate;
                            
                            Date fecha = eventDateTime.date();
                                String fechaString = fecha.format();
                            
                            Time hora = eventDateTime.time();
                            Integer horas = hora.hour();
                            Integer minutos = hora.minute();
                            Integer segundos = hora.second();
                            String horaComoString = horas.format() + ':' + minutos.format() + ':' + segundos.format();

                            acc.FechaEvento = fechaString;
                            acc.HoraEvento = horaComoString;
                        }
                        
                        acc.DescripcionEvento = BussRec.MilestoneDescription;
                        acc.PersonaRelacionada = BussRec.PrimaryAccount.Name;
                                            
                        if(BussRec.ExpirationDate != null){
                            ExpirationDateTime  = BussRec.ExpirationDate;
                        
                            fechaExpirationDate = ExpirationDateTime.date();
                        	String fechaStringExpirationDate = fechaExpirationDate.format();
                        
                            horaExpirationDate = ExpirationDateTime.time();
                        	Integer horasExpirationDate = horaExpirationDate.hour();
                            Integer minutosExpirationDate = horaExpirationDate.minute();
                            Integer segundosExpirationDate = horaExpirationDate.second();
                            String horaComoStringExpirationDate = horasExpirationDate.format() + ':' + minutosExpirationDate.format() + ':' + segundosExpirationDate.format();
                        
                        
                            acc.HoraVencimiento = horaComoStringExpirationDate;
                            acc.FechaVencimiento = fechaStringExpirationDate;  
                        }
                        
                        acc.DescripcionVencimiento = BussRec.ExpirationDescription;
                        acc.UbicacionEvento = BussRec.EventLocation__Street__s;
                        acc.CalleNumero = BussRec.EventLocation__Street__s;
                        acc.CodigoPostal = BussRec.EventLocation__PostalCode__s;
                        acc.Ciudad = BussRec.EventLocation__City__s;
                        acc.estado = BussRec.EventLocation__StateCode__s;
                        acc.Pais = BussRec.EventLocation__CountryCode__s;
                        acc.IdUnicoEventoVida = BussRec.Id;
                        taskEveAcc.add(acc);
                    }

                    resultado.result = true;
                    resultado.message = 'Eventos encontrados';
                    resultado.Event_Lst_result = taskEveAcc;
                    ltsInsert.add(resultado);
                }
            }
        }                     
        }catch(Exception ex){
            System.debug('Error en procesamiento de registro: '+ ex.getMessage()+ ' : ' + ex.getStackTraceString());
            resultado.message='Error en procesamiento de registro: '+ ex.getMessage() + ': ' + ex.getStackTraceString();
            resultado.result=false;
            ltsInsert.add(resultado);
            return ltsInsert;
            
        }

        return ltsInsert;
    }
    
    
    global class objtask {
        Public String BP;
        Public String RecordTypeAcc;
        Public String GrupoEvento;
        global String StartDate;
        global String EndDate;
    }
    
    global class ResultTask {
        Public Boolean result;
        Public String message;
        Public List<listEvenAcc> Event_Lst_result {get; set;}
    }
    
    global class listEvenAcc{
        
        public String  IDAsesor;
        public String  BP;
        public String  IDPersonaFisica;
        public String  IDPersonaMoral;
        public String  GrupoEventoClave;
        public String  GrupoEventoVida ;
        public String  NombreEvento;
        public String  PersonaPrincipal;
        public String  FechaEvento;
        public String  HoraEvento;
        public String  DescripcionEvento;
        public String  PersonaRelacionada;
        public String  FechaVencimiento;
        public String  HoraVencimiento;
        public String  DescripcionVencimiento;
        public String  UbicacionEvento;
        public String  CalleNumero;
        public String  CodigoPostal;
        public String  Ciudad;
        public String  estado;
        public String  Pais;
        public String  IdUnicoEventoVida;
        
    }
    
}