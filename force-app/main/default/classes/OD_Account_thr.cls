/**
* @File Name : OD_Account_thr.cls
* @Description :Clase Handler del Trigger AccountTrigger.apxt
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Account_thr {
    public static void onBeforeInsert(List<Account> newListAccount){
        system.debug('*********************BEFORE INSERT ACCOUNT*********************');
        OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,null);
        OD_Account_cls.createAccounts(newListAccount);
        OD_Account_cls.checkTotalPercent(newListAccount);
        OD_Account_cls.convertMappingLeadToAccount(newListAccount);
    }
    public static void onBeforeUpdate(List<Account> newListAccount,Map<Id,Account> oldMapAccount){
        system.debug('*********************BEFORE UPDATE ACCOUNT*********************');
        OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,oldMapAccount);
        OD_Account_cls.checkTotalPercent(newListAccount);
    }
}