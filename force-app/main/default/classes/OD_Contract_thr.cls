/**
* @File Name : OD_Contract_thr.cls
* @Description :Clase Handler del Trigger ContractTrigger.apxt
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 8, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Contract_thr {
    public static void onBeforeInsert(List<Contract> newListContract){
        system.debug('*********************BEFORE INSERT CONTRACT*********************');         
        OD_Contract_cls.processToChangeOwnerContract(newListContract);
    }
    public static void onBeforeUpdate(List<Contract> newListContract){
        system.debug('*********************BEFORE UPDATE CONTRACT*********************');                
        OD_Contract_cls.processToChangeOwnerContract(newListContract);
    }
}