/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 10-10-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(urlMapping='/ACT_MomentsLifeGroupsConsult/*')
global with sharing  class ACT_MomentsLifeGroupsConsultAPI {
    @HttpPost
    
    global static list<ResultTask> getTaskList(objtask records) {
        List<ResultTask> ltsInsert = new List<ResultTask>();
        
        ResultTask resultado=new ResultTask ();
        List<listEvenGroupAcc> taskEveAcc = new List<listEvenGroupAcc>();
        
        try{
            Date startDateTime = null;
            Date EndDateTime = null;
            Date fechaExpirationDate = null;
            Time horaExpirationDate = null;
            Datetime  ExpirationDateTime = null;
            
            
            List<PersonLifeEvent> personEvent = new List<PersonLifeEvent>();
            List<BusinessMilestone> BussEvent = new List<BusinessMilestone>();
            List<Account> Acct = [SELECT Id, Client_ID__c FROM Account WHERE Client_ID__c = :records.BP ];// debo relacionarlo a la cuenta y a tipo de registro con evento

            Map<String, Date> mostRecentDates = new Map<String, Date>();

            if (!Acct.isEmpty()) {
                Account Acc = Acct[0];
                if((!String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))){
                    System.debug('Ambos');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState, CreatedDate
                                   from PersonLifeEvent 
                                   WHERE PrimaryPerson.Account.Id =:Acc.Id and EventDate >=: startDateTime and EventDate <=: EndDateTime];
                    
                }else if ((String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))) {
                    System.debug('end');
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState, CreatedDate
                                   from PersonLifeEvent 
                                   WHERE PrimaryPerson.Account.Id =:Acc.Id and EventDate <=: EndDateTime];
                }
                else if((!String.isBlank(records.StartDate)) && (String.isBlank(records.EndDate))){
                    System.debug('Start');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState, CreatedDate
                                   from PersonLifeEvent 
                                   WHERE PrimaryPerson.Account.Id =:Acc.Id and EventDate >=: startDateTime];
                }else{
                    personEvent = [select id,Name,OwnerId,PrimaryPersonId,EventType,PrimaryPerson.Account.Person_Type__c,PrimaryPerson.Account.Client_ID__c,RelatedPerson.Account.Id,PrimaryPerson.Account.Name, EventDate,EventDescription,RelatedPersonId,ExpirationDate,ExpirationDescription,EventLocation,EventLocationStreet, EventLocationPostalCode, EventLocationCity, EventLocationCountry, EventLocationState, CreatedDate
                                   from PersonLifeEvent 
                                   WHERE PrimaryPerson.Account.Id =:Acc.Id];
                }
                
                if(personEvent != null && records.RecordTypeAcc == 'FISICA'){
                    Map<String, Integer> eventTypeCount = new Map<String, Integer>();
                    
                    for (PersonLifeEvent event : personEvent) {
                        String eventType = event.EventType;
                        Date eventDate = Date.valueOf(event.EventDate);

                        if (!mostRecentDates.containsKey(eventType) || mostRecentDates.get(eventType) < eventDate) {
                            mostRecentDates.put(eventType, eventDate);
                        }

                        if (eventTypeCount.containsKey(eventType)) {
                            eventTypeCount.put(eventType, eventTypeCount.get(eventType) + 1);
                        } else {
                            eventTypeCount.put(eventType, 1);
                        }
                    }
                    
                    String objeto = 'PersonLifeEvent'; 
                    String campo = 'EventType'; 
                    
                    SObjectField field = Schema.getGlobalDescribe().get(objeto).getDescribe().fields.getMap().get(campo);
                    Schema.DescribeFieldResult fieldResult = field.getDescribe();
                    
                    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
                    
                    for (Schema.PicklistEntry entry : picklistValues) {
                        String eventType = entry.getValue();
                        Integer count = eventTypeCount.get(eventType);
                        if (count == null) {
                            eventTypeCount.put(eventType, 0);
                        }
                        
                        System.debug('Valor: ' + entry.getValue());
                        System.debug('Etiqueta: ' + entry.getLabel());
                    }
                    
                    /*List<AggregateResult> allEventTypes = [SELECT EventType, COUNT(Id)
                    FROM PersonLifeEvent
                    GROUP BY EventType];


                    for (AggregateResult aggregate : allEventTypes) {
                    String eventType = (String)aggregate.get('EventType');
                    Integer count = eventTypeCount.get(eventType);
                    if (count == null) {
                    eventTypeCount.put(eventType, 0);
                    }
                    }*/
                    
                    List<Map<String, String>> groupedEvents = new List<Map<String, String>>();
                    for (String eventType : eventTypeCount.keySet()) {
                        Integer count = eventTypeCount.get(eventType);
                        Map<String, String> eventGroup = new Map<String, String>();
                        eventGroup.put('GroupNom', eventType);
                        eventGroup.put('GroupNo', String.valueOf(count));
                        groupedEvents.add(eventGroup);
                    }
                    
                    
                    for (Map<String, String> groupedEvent : groupedEvents) {
                        listEvenGroupAcc eventGroupAcc = new listEvenGroupAcc();
                        eventGroupAcc.GroupNom = groupedEvent.get('GroupNom');
                        eventGroupAcc.GroupNo = groupedEvent.get('GroupNo');
                        eventGroupAcc.MostRecentEventCreatedDate = mostRecentDates.get(groupedEvent.get('GroupNom'));
                        taskEveAcc.add(eventGroupAcc);
                    }
                    
                    System.debug('groupedEvents' + groupedEvents);
                    resultado.result = true;
                    resultado.message = 'Grupo de Eventos encontrados';
                    resultado.GroupEventsLife = taskEveAcc;
                    ltsInsert.add(resultado);
                    System.debug('ltsInsert' + ltsInsert);
                    /*          
                    Map<String, Integer> countMap = new Map<String, Integer>();

                    for (PersonLifeEvent perRec : personEvent) {
                    String groupName = perRec.EventType;
                    Boolean groupExists = false;
                    for (listEvenGroupAcc acc : taskEveAcc) {
                    if (acc.GroupName == groupName) {
                    groupExists = true;
                    break;
                    }
                    }
                    if (!groupExists) {
                    listEvenGroupAcc acc = new listEvenGroupAcc();
                    acc.GroupName = groupName;
                    taskEveAcc.add(acc);
                    }
                    if (countMap.containsKey(groupName)) {
                    countMap.put(groupName, countMap.get(groupName) + 1);
                    } else {
                    countMap.put(groupName, 1);
                    }
                    }
                    for (listEvenGroupAcc acc : taskEveAcc) {
                    acc.GroupName += '[' + countMap.get(acc.GroupName) + ']';
                    }
                    resultado.result = true;
                    resultado.message = 'Grupo de Eventos encontrados';
                    resultado.GroupEventsLife = taskEveAcc;
                    ltsInsert.add(resultado);*/
                }
                if((!String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))){
                    // if((records.StartDate != null && records.StartDate != '') && (records.EndDate != '' && records.EndDate != null)){
                    System.debug('Ambos');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    
                    BussEvent = [select id, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,MilestoneSiteId, CreatedDate
                                 from BusinessMilestone 
                                 WHERE PrimaryAccountId =:Acc.Id and MilestoneDate >=: startDateTime and MilestoneDate <=: EndDateTime];
                    
                }else if ((String.isBlank(records.StartDate)) && (!String.isBlank(records.EndDate))) {
                    System.debug('end');
                    //Fecha de Fin
                    EndDateTime = Date.valueOf(records.EndDate);
                    System.debug('LOG CCO: '+EndDateTime);
                    BussEvent = [select id, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,MilestoneSiteId, CreatedDate
                                 from BusinessMilestone 
                                 WHERE PrimaryAccountId =:Acc.Id and MilestoneDate <=: EndDateTime];
                    System.debug(BussEvent.size());
                }
                else if((!String.isBlank(records.StartDate)) && (String.isBlank(records.EndDate))){
                    System.debug('Start');
                    //Fecha de inicio
                    startDateTime = Date.valueOf(records.StartDate);
                    
                    BussEvent = [select id, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,MilestoneSiteId, CreatedDate
                                 from BusinessMilestone 
                                 WHERE PrimaryAccountId =:Acc.Id and MilestoneDate >=: startDateTime];
                }else{
                    BussEvent = [select id, Name,OwnerId,PrimaryAccountId,MilestoneType,PrimaryAccount.Client_ID__c,PrimaryAccount.Name,MilestoneDate,MilestoneDescription,ExpirationDate,ExpirationDescription,MilestoneSiteId, CreatedDate
                                 from BusinessMilestone 
                                 WHERE PrimaryAccountId =:Acc.Id];
                }
                
                if(BussEvent != null && records.RecordTypeAcc == 'MORAL'){
                    Map<String, Integer> eventTypeCount = new Map<String, Integer>();
                    
                    for (BusinessMilestone event : BussEvent) {
                        String eventType = event.MilestoneType;
                        Date eventDate = Date.valueOf(event.MilestoneDate);

                        if (!mostRecentDates.containsKey(eventType) || mostRecentDates.get(eventType) < eventDate) {
                            mostRecentDates.put(eventType, eventDate);
                        }
                        if (eventTypeCount.containsKey(eventType)) {
                            eventTypeCount.put(eventType, eventTypeCount.get(eventType) + 1);
                        } else {
                            eventTypeCount.put(eventType, 1);
                        }
                    }
                    
                    String objeto = 'BusinessMilestone'; 
                    String campo = 'MilestoneType'; 
                    
                    SObjectField field = Schema.getGlobalDescribe().get(objeto).getDescribe().fields.getMap().get(campo);
                    Schema.DescribeFieldResult fieldResult = field.getDescribe();
                    
                    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
                    
                    for (Schema.PicklistEntry entry : picklistValues) {
                        String eventType = entry.getValue();
                        Integer count = eventTypeCount.get(eventType);
                        if (count == null) {
                            eventTypeCount.put(eventType, 0);
                        }
                        
                        System.debug('Valor: ' + entry.getValue());
                        System.debug('Etiqueta: ' + entry.getLabel());
                    }
                    
                    /*  List<AggregateResult> allEventTypes = [SELECT MilestoneType, COUNT(Id)
                        FROM BusinessMilestone
                        GROUP BY MilestoneType];


                        for (AggregateResult aggregate : allEventTypes) {
                        String eventType = (String)aggregate.get('MilestoneType');
                        Integer count = eventTypeCount.get(eventType);
                        if (count == null) {
                        eventTypeCount.put(eventType, 0);
                        }
                        }
                    */
                    
                    List<Map<String, String>> groupedEvents = new List<Map<String, String>>();
                    for (String eventType : eventTypeCount.keySet()) {
                        Integer count = eventTypeCount.get(eventType);
                        Map<String, String> eventGroup = new Map<String, String>();
                        eventGroup.put('GroupNom', eventType);
                        eventGroup.put('GroupNo', String.valueOf(count));
                        groupedEvents.add(eventGroup);
                    }
                    
                    
                    for (Map<String, String> groupedEvent : groupedEvents) {
                        listEvenGroupAcc eventGroupAcc = new listEvenGroupAcc();
                        eventGroupAcc.GroupNom = groupedEvent.get('GroupNom');
                        eventGroupAcc.GroupNo = groupedEvent.get('GroupNo');
                        eventGroupAcc.MostRecentEventCreatedDate = mostRecentDates.get(groupedEvent.get('GroupNom')); // Nueva línea
                        taskEveAcc.add(eventGroupAcc);
                    }
                    
                    System.debug('groupedEvents' + groupedEvents);
                    resultado.result = true;
                    resultado.message = 'Grupo de Eventos encontrados';
                    resultado.GroupEventsLife = taskEveAcc;
                    ltsInsert.add(resultado);
                }
                
                
                
                    /*  Map<String, Integer> countMap = new Map<String, Integer>();

                        for (BusinessMilestone BussRec : BussEvent) {
                        String groupName = BussRec.MilestoneType;
                        Boolean groupExists = false;
                        for (listEvenGroupAcc acc : taskEveAcc) {
                        if (acc.GroupName == groupName) {
                        groupExists = true;
                        break;
                        }
                        }
                        if (!groupExists) {
                        listEvenGroupAcc acc = new listEvenGroupAcc();
                        acc.GroupName = groupName;
                        taskEveAcc.add(acc);
                        }
                        if (countMap.containsKey(groupName)) {
                        countMap.put(groupName, countMap.get(groupName) + 1);
                        } else {
                        countMap.put(groupName, 1);
                        }
                        }
                        for (listEvenGroupAcc acc : taskEveAcc) {
                        acc.GroupName += '[' + countMap.get(acc.GroupName) + ']';
                        }
                        resultado.result = true;
                        resultado.message = 'Grupo de Eventos encontrados';
                        resultado.GroupEventsLife = taskEveAcc;
                        ltsInsert.add(resultado);
                    */
                
            }else{
                resultado.result = False;
                resultado.message = 'No se encontraron Clientes';
                ltsInsert.add(resultado);
                return ltsInsert;
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
        global String BP;
        global String RecordTypeAcc;
        global String StartDate;
        global String EndDate;
    }
    
    global class ResultTask {
        global Boolean result;
        global String message;
        global List<listEvenGroupAcc> GroupEventsLife {get; set;}
    }
    
    global class listEvenGroupAcc{
        global String  GroupNom;
        global String  GroupNo;
        global Date  MostRecentEventCreatedDate;
        
    }
    
}