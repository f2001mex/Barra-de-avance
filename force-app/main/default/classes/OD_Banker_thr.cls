/**
* @File Name : OD_Banker_thr.cls
* @Description :Clase Handler del Trigger BankerTrigger.apxt
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Banker_thr {
    public static void onBeforeInsert(List<Banker> newListBanker){
        system.debug('*********************BEFORE INSERT BANKER*********************');
        OD_Banker_cls.processToChangeBankers(newListBanker);
    }
    public static void onBeforeUpdate(List<Banker> newListBanker,Map<Id,Banker> oldMap){
        system.debug('*********************BEFORE UPDATE BANKER*********************');
        OD_Banker_cls.createBranchUnitBusinessMember(newListBanker,oldMap);
    }
    public static void onAfterInsert(List<Banker> newListBanker){
        system.debug('*********************AFTER INSERT BANKER*********************');
    }
    
    public static void onAfterUpdate(List<Banker> newListBanker,Map<Id,Banker> oldMap){
        system.debug('*********************AFTER UPDATE BANKER*********************');  
        OD_Banker_cls.processToRelatedNewOwner(newListBanker,oldMap);
    }
}