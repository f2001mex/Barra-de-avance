/** ------------------------------------------------------------------------------------------------
 * @Name     Round_Robin_Utils
 * @Author   andres.hernandez@vasscompany.com
 * @Date     Created: 08/03/2025
 * @Group    VASS
 *   ------------------------------------------------------------------------------------------------
 * @Description Helper class for the lead trigger
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         08/03/2025      Andres Hernandez 			       Class creation.
*--------------------------------------------------------------------------
 **/
@isTest
public class Round_Robin_Utils_tst {
       @isTest
    static void testASLAssignment() {
        UserByGroupTMP__c user1 = new UserByGroupTMP__c(Indice_Round__c = 1);
        UserByGroupTMP__c user2 = new UserByGroupTMP__c(Indice_Round__c = 2);
        UserByGroupTMP__c user3 = new UserByGroupTMP__c(Indice_Round__c = 3);
        
        insert new List<UserByGroupTMP__c>{user1, user2, user3};
        
        List<UserByGroupTMP__c> lstUsersByGroup = [SELECT Id, Indice_Round__c FROM UserByGroupTMP__c];
        
        Test.startTest();
        UserByGroupTMP__c result = Round_Robin_Utils.ASLAssignment(lstUsersByGroup);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Se esperaba que se devolviera un usuario.');
        System.assertEquals(2, result.Indice_Round__c, 'El índice del usuario seleccionado no se incrementó correctamente.');
        
        UserByGroupTMP__c updatedUser1 = [SELECT Indice_Round__c FROM UserByGroupTMP__c WHERE Id = :user1.Id LIMIT 1];
        System.assertEquals(2, updatedUser1.Indice_Round__c, 'El índice de user1 no se actualizó correctamente.');
    }
    
    @isTest
    static void testEmptyList() {
        Test.startTest();
        UserByGroupTMP__c result = Round_Robin_Utils.ASLAssignment(new List<UserByGroupTMP__c>());
        Test.stopTest();
        
        System.assertEquals(null, result, 'Se esperaba que el resultado fuera nulo al pasar una lista vacía.');
    }
    
    @isTest
    static void testSingleUserInList() {
        UserByGroupTMP__c user1 = new UserByGroupTMP__c(Indice_Round__c = 1);
        
        insert user1;
        
        List<UserByGroupTMP__c> lstUsersByGroup = [SELECT Id, Indice_Round__c FROM UserByGroupTMP__c];
        Test.startTest();
        UserByGroupTMP__c result = Round_Robin_Utils.ASLAssignment(lstUsersByGroup);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Se esperaba que se devolviera un usuario.');
        System.assertEquals(2, result.Indice_Round__c, 'El índice del usuario no se incrementó correctamente.');
        
        UserByGroupTMP__c updatedUser1 = [SELECT Indice_Round__c FROM UserByGroupTMP__c WHERE Id = :user1.Id LIMIT 1];
        System.assertEquals(2, updatedUser1.Indice_Round__c, 'El índice de user1 no se actualizó correctamente.');
    }
}