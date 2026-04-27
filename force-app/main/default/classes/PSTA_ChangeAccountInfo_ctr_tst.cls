/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_ChangeAccountInfo_ctr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@isTest
public class PSTA_ChangeAccountInfo_ctr_tst {
    
@isTest
    static void test_changeContactAndDateStatus_executesSuccessfully() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id);
        insert con;

        Task task = new Task(
            Subject = 'Follow up',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = acc.Id,
            WhoId = con.Id
        );
        insert task;

        Task oldTask = task.clone();
        oldTask.Status = 'Completed';

        List<Task> taskList = new List<Task>{ task };
        Map<Id, Task> oldTaskMap = new Map<Id, Task>{ task.Id => oldTask };

        Test.startTest();
        PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(taskList, oldTaskMap);
        Test.stopTest();
    }

    @isTest
    static void test_changeContactAndDateStatus_bypass() {
        Task task = new Task(Subject = 'Dummy', Status = 'Not Started');
        List<Task> taskList = new List<Task>{ task };
        Map<Id, Task> oldTaskMap = new Map<Id, Task>();

        // Activar el bypass
        PSTA_ChangeAccountInfo_ctr.byPassTriggerExecution = true;

        Test.startTest();
        PSTA_ChangeAccountInfo_ctr.changeContactAndDateStatus(taskList, oldTaskMap);
        Test.stopTest();
    }
}