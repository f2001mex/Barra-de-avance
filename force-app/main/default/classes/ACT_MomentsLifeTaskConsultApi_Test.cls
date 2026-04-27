/**
 * @description       : 
 * @author            : JC Cruz
 * @group             : 
 * @last modified on  : 10-19-2023
 * @last modified by  : JC Cruz
**/
@isTest
public class ACT_MomentsLifeTaskConsultApi_Test {
    @TestSetup
    static void makeData(){
        
        Account accMoral = new Account(
            FirstName = 'Test',
            LastName = 'Moral',
            Client_ID__c = '9876',
            Person_Type__c = 'MORAL'
        );
        insert accMoral;


        Account accFisica = new Account(
            FirstName = 'FISICA TEST',
            LastName = 'FISICA',
            Client_ID__c = '1234',
            Person_Type__c = 'FISICA'
            , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        insert accFisica;

        List<Contact> cts = new List<Contact>([Select Id From Contact Where FirstName =: 'FISICA TEST']);

        system.assertEquals(1, cts.size(), String.valueOf(cts.size()));

        //Create Event PersonLife
        PersonLifeEvent newPersonEvent = new PersonLifeEvent();
        newPersonEvent.Name = 'Test Event';
        newPersonEvent.EventType = 'Nacimiento';
        newPersonEvent.EventDescription = 'description test';
        newPersonEvent.eventDate = system.now().date();
        newPersonEvent.primaryPersonId = cts[0].Id;
        newPersonEvent.ExpirationDate = system.now().date();
        Insert newPersonEvent;

        //Create event milestone
        BusinessMilestone businessMilestone = new BusinessMilestone();
        businessMilestone.Name = 'Bancarrota';
        businessMilestone.MilestoneDescription = 'Description';
        businessMilestone.MilestoneDate = System.now().date();
        businessMilestone.PrimaryAccountId = accMoral.Id;
        businessMilestone.MilestoneType = 'Bancarrota';
        businessMilestone.ExpirationDate = system.now().date();
        insert businessMilestone;
    }

    @istest
    static void getResultsGr(){
        ACT_MomentsLifeGroupsConsultAPI.objtask params = new ACT_MomentsLifeGroupsConsultAPI.objtask();

        //Get FISICA
        params.BP = '1234';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = '';
        params.EndDate = '';

        List<ACT_MomentsLifeGroupsConsultAPI.ResultTask> result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = '';
        params.EndDate = '';

        result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
    @istest
    static void getResultsGrAmb(){
        ACT_MomentsLifeGroupsConsultAPI.objtask params = new ACT_MomentsLifeGroupsConsultAPI.objtask();
        Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = dateString;
        params.EndDate = dateString;

        List<ACT_MomentsLifeGroupsConsultAPI.ResultTask> result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = dateString;
        params.EndDate = dateString;

        result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
    
        @istest
    static void getResultsGrEnd(){
        ACT_MomentsLifeGroupsConsultAPI.objtask params = new ACT_MomentsLifeGroupsConsultAPI.objtask();
        Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = '';
        params.EndDate = dateString;

        List<ACT_MomentsLifeGroupsConsultAPI.ResultTask> result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = '';
        params.EndDate = dateString;

        result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }

        @istest
    static void getResultsGrStart(){
        ACT_MomentsLifeGroupsConsultAPI.objtask params = new ACT_MomentsLifeGroupsConsultAPI.objtask();
        Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = dateString;
        params.EndDate = '';

        List<ACT_MomentsLifeGroupsConsultAPI.ResultTask> result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = dateString;
        params.EndDate = '';

        result = ACT_MomentsLifeGroupsConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }    
        @istest
    static void getResults(){
        ACT_MomentsLifeTaskConsultAPI.objtask params = new ACT_MomentsLifeTaskConsultAPI.objtask();

        //Get FISICA
        params.BP = '1234';
        params.GrupoEvento = 'Nacimiento';
        params.RecordTypeAcc = 'FISICA';

        List<ACT_MomentsLifeTaskConsultAPI.ResultTask> result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.GrupoEvento = 'Bancarrota';
        params.RecordTypeAcc = 'MORAL';

        result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
    
    @istest
    static void getResultsAmb(){
        ACT_MomentsLifeTaskConsultAPI.objtask params = new ACT_MomentsLifeTaskConsultAPI.objtask();
		Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.GrupoEvento = 'Nacimiento';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = dateString;
        params.EndDate = dateString;

        List<ACT_MomentsLifeTaskConsultAPI.ResultTask> result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.GrupoEvento = 'Bancarrota';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = dateString;
        params.EndDate = dateString;

        result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
    
        @istest
    static void getResultsEnd(){
        ACT_MomentsLifeTaskConsultAPI.objtask params = new ACT_MomentsLifeTaskConsultAPI.objtask();
		Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.GrupoEvento = 'Nacimiento';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = '';
        params.EndDate = dateString;

        List<ACT_MomentsLifeTaskConsultAPI.ResultTask> result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.GrupoEvento = 'Bancarrota';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = '';
        params.EndDate = dateString;

        result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
    
            @istest
    static void getResultsStart(){
        ACT_MomentsLifeTaskConsultAPI.objtask params = new ACT_MomentsLifeTaskConsultAPI.objtask();
		Date currentDate = System.now().date();
        String dateString = String.valueOf(currentDate);
        //Get FISICA
        params.BP = '1234';
        params.GrupoEvento = 'Nacimiento';
        params.RecordTypeAcc = 'FISICA';
        params.StartDate = dateString;
        params.EndDate = '';

        List<ACT_MomentsLifeTaskConsultAPI.ResultTask> result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for FISICA.');


        //Get Moral
        params.BP = '9876';
        params.GrupoEvento = 'Bancarrota';
        params.RecordTypeAcc = 'MORAL';
        params.StartDate = dateString;
        params.EndDate = '';

        result = ACT_MomentsLifeTaskConsultAPI.ResultTask.getTaskList(params);

        System.assertNotEquals(0, result.size(), 'Expected results for MORAL.');
    }
}