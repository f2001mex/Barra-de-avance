/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_Account_thr
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     15-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class PSTA_Account_thr_tst {
    
    @isTest
    static void test_onBeforeUpdate() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc = new Account(
            Name = 'Cliente de Prueba',
            saldointegral__c = 1000,
            FechaNoRequiereSerContacto__c = Date.today(),
            FechaSiguienteContacto__c = Date.today(),
            FechaSiguienteVisita__c = Date.today(),
            FechaUltimaVisita__c = Date.today().addDays(-10),
            EstatusContacto__c = 'Contacto efectivo exitoso'
        );
        insert acc;

        acc = [SELECT Id, Name, saldointegral__c, FechaNoRequiereSerContacto__c, 
                      FechaSiguienteContacto__c, FechaSiguienteVisita__c, FechaUltimaVisita__c, EstatusContacto__c,  BanqueroAsignado__c, Owner.Id
               FROM Account
               WHERE Id = :acc.Id];

        Account updatedAcc = new Account(
            Id = acc.Id,
            saldointegral__c = 2000,
            FechaNoRequiereSerContacto__c = acc.FechaNoRequiereSerContacto__c,
            FechaSiguienteContacto__c = acc.FechaSiguienteContacto__c,
            FechaSiguienteVisita__c = acc.FechaSiguienteVisita__c,
            FechaUltimaVisita__c = acc.FechaUltimaVisita__c,
            EstatusContacto__c = acc.EstatusContacto__c,
            BanqueroAsignado__c = acc.BanqueroAsignado__c
        );

        List<Account> newList = new List<Account>{ updatedAcc };
        Map<Id, Account> oldMap = new Map<Id, Account>{ acc.Id => acc };

        ConfiguracionActinver__c config = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        Test.startTest();
        PSTA_Account_thr.onBeforeUpdate(newList, oldMap);
        Test.stopTest();
    }
}