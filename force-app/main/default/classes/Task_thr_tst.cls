/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para Task_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     15-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class Task_thr_tst {

    @isTest
    static void testOnAfterUpdate() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(Name = 'Cuenta Test');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Nombre',
            LastName = 'Apellido',
            AccountId = acc.Id,
            Email = 'test@example.com'
        );
        insert con;

        Task t = new Task(
            Subject = 'Tarea de prueba',
            Status = 'Not Started',
            Priority = 'Normal',
            WhoId = con.Id
        );
        insert t;

        t.Status = 'Completed';
        update t;

        List<Task> newList = [
    		SELECT Id, Status, WhoId, AccountId, DeveloperName__c, ClienteNoQuiereSerContactado__c
    		FROM Task 
    		WHERE Id = :t.Id
		];
        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => t };

        Test.startTest();
        Task_thr.onAfterUpdate(newList, oldMap);
        Test.stopTest();
    }
}