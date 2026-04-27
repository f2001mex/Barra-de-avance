/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase test de la clase factory de postventa
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         23-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
@IsTest
public class PSTA_TestDataFactory_tst {
    @IsTest
    static void testCreateConfiguracionContratosActinver() {
        Test.startTest();
        ConfiguracionActinver__c config = PSTA_TestDataFactory.createConfiguracionContratosActinver();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateConfiguracionContactoActinver() {
        Test.startTest();
        ConfiguracionActinver__c config = PSTA_TestDataFactory.createConfiguracionContactoActinver();
        Test.stopTest();
      
    }
    
    @IsTest
    static void testCreateConfiguracionPatrimonialReactivoActinver() {
        Test.startTest();
        ConfiguracionActinver__c config = PSTA_TestDataFactory.createConfiguracionPatrimonialReactivoActinver();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateUser() {
        Test.startTest();
        User user = PSTA_TestDataFactory.createUser();
        Test.stopTest();
       
    }
    
    @IsTest
    static void testCreateBranchUnit() {
        Test.startTest();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testCreateBanker() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        
        Test.startTest();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
        Test.stopTest();
     
    }
    
    @IsTest
    static void testGetBranchUnitBusinessMember() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
        
        Test.startTest();
        BranchUnitBusinessMember member = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);
        Test.stopTest();
        

    }
    
    @IsTest
    static void testCreateAccounts() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
                BranchUnitBusinessMember member = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        Test.startTest();
        List<Account> accounts = PSTA_TestDataFactory.createAccounts(3, member.Id, true);
        Test.stopTest();
    
    }
    
    @IsTest
    static void testCreateAccountsPriorizacion() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
        BranchUnitBusinessMember member = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);
        
        Test.startTest();
        List<Account> accounts = PSTA_TestDataFactory.createAccountsPriorizacion(3, member.Id, true);
        Test.stopTest();
        
      
    }
    
    
    
    @IsTest
    static void testCreateAccountsWithoutInsert() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
        
        Test.startTest();
        List<Account> accounts = PSTA_TestDataFactory.createAccounts(3, banker.Id, false);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateContractsWithoutInsert() {
        // Crear datos previos necesarios
        User user = PSTA_TestDataFactory.createUser();
        BranchUnit branchUnit = PSTA_TestDataFactory.createBranchUnit();
        Banker banker = PSTA_TestDataFactory.createBanker(branchUnit.Id, user.Id);
                BranchUnitBusinessMember member = PSTA_TestDataFactory.getBranchUnitBusinessMember(banker.Id, branchUnit.Id);

        List<Account> accounts = PSTA_TestDataFactory.createAccounts(3, member.Id, true);
        
        List<Id> accountIds = new List<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        List<Contract> contracts = PSTA_TestDataFactory.createContracts(accountIds, '00045', false, banker.Id);
        Test.stopTest();
        
        
    }
}