/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Helper
 * @Author   andres.hernandez@vasscompany.com
 * @Date     Created: 03/03/2025
 * @Group    VASS
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the lead trigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         03/03/2025      Andres Hernandez 			       Class creation.
*--------------------------------------------------------------------------
 **/
public with sharing class Round_Robin_Utils {
    public static UserByGroupTMP__c ASLAssignment(List<UserByGroupTMP__c> lstUsersByGroup) {
        UserByGroupTMP__c userGroupUser = new UserByGroupTMP__c();
        Integer minIndice = 2147483647;
        
        if (lstUsersByGroup.isEmpty()) {
            return null;
        }

                
        for (UserByGroupTMP__c userGroup : lstUsersByGroup) {
            
            if (userGroup.Indice_Round__c < minIndice) {
                minIndice = Integer.valueOf(userGroup.Indice_Round__c);
                userGroupUser = userGroup;
            }
        }
        
        if (userGroupUser != null) {
            userGroupUser.Indice_Round__c++;  
            update userGroupUser;
        }
        
        return userGroupUser;
    }
}