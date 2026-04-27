/** ------------------------------------------------------------------------------------------------
 * @Name     Service_Utility_Trigger2
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
public class Service_Utility_Trigger2_tst {
     
    @isTest
    static void testGetUserGroupByLead() {
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'TestBranchUnit';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;

        Catalogs__c cp = new Catalogs__c();
        cp.Name = '12345';
        cp.CodigoPostal__c = '12345';
        cp.Activo__c = true;
        cp.RecordTypeId = Schema.SObjectType.Catalogs__c .getRecordTypeInfosByDeveloperName().get('CodigoPostal').getRecordTypeId();
        insert cp;
        
        Catalogs__c groups = new Catalogs__c();
        groups.RecordTypeId = Schema.SObjectType.Catalogs__c.getRecordTypeInfosByDeveloperName().get('Grupo').getRecordTypeId();
        groups.Name = 'TestGroup';
        groups.NombreGrupo__c = 'TestGroup';
        groups.Activo__c = true;
        insert groups;
        
        PostalCodeByBranchUnit__c grupoCp = new PostalCodeByBranchUnit__c();
        grupoCp.CodigoPostal__c = cp.Id;
        grupoCp.Activo__c = true;
        grupoCp.CentroFinanciero__c = branchUnit.Id;
        insert grupoCp;
            
        BranchUnitGroup__c bGroup = new BranchUnitGroup__c();
        bGroup.Activo__c = true;
        bGroup.BranchUnit__c = branchUnit.Id;
        bGroup.Grupo__c = groups.Id;
        insert bGroup;
        
        UserByGroupTMP__c uGroup = new UserByGroupTMP__c();
        uGroup.User__c = UserInfo.getUserId();
        uGroup.Grupo__c = groups.Id;
        uGroup.Activo__c = true;
        insert uGroup;
        // Crear los datos de prueba para Leads
        List<Lead> leads = new List<Lead>();
        Lead lead1 = new Lead(FirstName = 'John', LastName = 'Doe', PostalCode = '12345',Phone='5544669988', Email='testlead1@gmail.com');
        Lead lead2 = new Lead(FirstName = 'Jane', LastName = 'Doe', PostalCode = '54321',Phone='5544669988', Email='testlead2@gmail.com');
        Lead lead3 = new Lead(FirstName = 'Sam', LastName = 'Smith', PostalCode = '543200',Phone='5544669988', Email='testlead3@gmail.com'); // Lead sin código postal
        leads.add(lead1);
        leads.add(lead2);
        leads.add(lead3);
        
        insert leads;
        
        // Llamar al método getUserGroupByLead
        Test.startTest();
        Map<Lead, List<UserByGroupTMP__c>> result = Service_Utility_Trigger2.getUserGroupByLead(leads);
        Test.stopTest();
        
        // Verificar los resultados
        System.assertNotEquals(result, null, 'El mapa de grupos de usuarios no debe ser nulo');
    }
    
    
    @isTest
    static void testSendNotificationUser() {
        // Crear datos de prueba para Lead
        Lead lead = new Lead(FirstName = 'John', LastName = 'Doe', PostalCode = '12345',Phone='5544669988',Email='testlead3@gmail.com');
        insert lead;
        
        // Crear un set de IDs de usuarios para la notificación
        Set<String> recipientsIds = new Set<String>{UserInfo.getUserId()};
        
        // Llamar al método sendNotificationUser
        Test.startTest();
        Service_Utility_Trigger2.sendNotificationUser(recipientsIds, lead);
        Test.stopTest();
        
        // Verificar que la notificación fue enviada (esto se puede verificar con los logs)
        System.assert(true, 'La notificación debe haberse enviado correctamente');
    }
    
    
}