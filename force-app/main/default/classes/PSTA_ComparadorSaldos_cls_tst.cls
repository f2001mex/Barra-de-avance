/***************************************************************************************
Desarrollado por:        VASS México
Autor:                   Jessica Salazar 
Proyecto:                Actinver Postventa
Descripción:             Clase test para PSTA_ComparadorSaldos_cls
------------------------------------------------------------------------------------------
No.        Fecha               Autor                             Descripción
------  ----------  -----------------------------    -------------------------------------
1.0     14-07-2025        Jessica Salazar                         Creación
*******************************************************************************************/
@IsTest
public class PSTA_ComparadorSaldos_cls_tst {

    @isTest
    static void test_compare_accounts() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc1 = new Account(Name = 'Cuenta Alta', saldointegral__c = 1000);
        Account acc2 = new Account(Name = 'Cuenta Media', saldointegral__c = 500);
        Account acc3 = new Account(Name = 'Cuenta Baja', saldointegral__c = 100);
        insert new List<Account>{ acc1, acc2, acc3 };

        List<Account> accounts = new List<Account>{ acc2, acc3, acc1 };
        accounts.sort(new PSTA_ComparadorSaldos_cls());
    }

    @isTest
    static void test_compare_equal_saldos() {
        OD_Account_cls.bypassTriggerExecution = true;
        Account acc1 = new Account(Name = 'Cuenta A', saldointegral__c = 300);
        Account acc2 = new Account(Name = 'Cuenta B', saldointegral__c = 300);
        insert new List<Account>{ acc1, acc2 };

        List<Account> accounts = new List<Account>{ acc2, acc1 };
        accounts.sort(new PSTA_ComparadorSaldos_cls());

    }
}