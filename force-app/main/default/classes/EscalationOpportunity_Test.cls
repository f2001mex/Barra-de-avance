/** ------------------------------------------------------------------------------------------------
 *   ------------------------------------------------------------------------------------------------
 * @Name     EscalationOpportunity_Test
 * @Author   ivan.mora@pwc.com
 * @Date     Created: 04/04/2024
 * @Group    PWC
 *   ------------------------------------------------------------------------------------------------
 * @Description Test for all the apex classes related to Opportunity Escalation Rules 
 *   ------------------------------------------------------------------------------------------------
 * @Changes
 * 04/04/2024 ivan.mora@pwc.com
 *             Class creation.
 *   ------------------------------------------------------------------------------------------------
 **/
@isTest
public class EscalationOpportunity_Test {
	public static String CRON_EXP = '0 0 0 15 3 ? 2042';
    public static Id ASESOR_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'Asesor Soluciones'].Id;
    public static List<Profile> DIRECTOR_PROFILE_LIST = [SELECT Id FROM Profile WHERE Name IN ('Subdirector','System Administrator')];
    public static Id META_FINANCIERA_RT = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' 
                                           AND IsActive = TRUE AND DeveloperName ='WalletShareOpportunity' LIMIT 1].Id;
    public static Id RETIRO_RT = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' 
                                           AND IsActive = TRUE AND DeveloperName ='Planes_Beneficio_Fiscal' LIMIT 1].Id;
    
    public static String META_FINANCIERA_TITLE = 'Diagnostico Patrimonial';
    public static String RETIRO_TITLE = 'Cross-Sell Retiro Asalariado';
            
    public static User mc_crm_user = [SELECT Id FROM User WHERE Name = 'MC Connect-CRM'];
    
    @TestSetup
    public static void setup() { 
        List<User> newTestUsers = new List<User>();
        List<Banker> newBankers = new List<Banker>();
        List<Account> newAccounts = new List<Account>();
        List<BranchUnitBusinessMember> branchMembers = new List<BranchUnitBusinessMember>();
        
        for(Integer i = 1; i<=6; i++){
            newTestUsers.add(new User(
                FirstName = 'Test',
                LastName = i != 5 ? 'Asesor_'+i : 'DCF',    
                Username = i+'@test.com.prod',
                Email = 'test@test.com',    
                IsActive = TRUE,
                EmailEncodingKey = 'ISO-8859-1',
                TimeZoneSidKey = 'America/Mexico_City',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'es',
                Alias = i < 5 ? 'asesorA' + i : i==5 ? 'dcf1' : 'pat1',
                ProfileId = i != 5 ? ASESOR_PROFILE_ID : DIRECTOR_PROFILE_LIST[0].Id
            ));
        }
        insert newTestUsers;
        
        BranchUnit patrimonial = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{ BranchUnit.BranchCode => 'PRB_0004', BranchUnit.Name => 'Patrimonial' }
		)[0];
		insert patrimonial;
        
        BranchUnit division = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{ 
                BranchUnit.BranchCode => 'PRB_0003', 
                BranchUnit.Name => 'Division',
                BranchUnit.ParentBranchUnitId => patrimonial.Id
            }
		)[0];
		insert division;
        
		BranchUnit region = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{
				BranchUnit.BranchCode => 'PRB_0002',
				BranchUnit.Name => 'Region',
				BranchUnit.ParentBranchUnitId => division.Id
			}
		)[0];
		insert region;
		BranchUnit sucursal = UtilitiesDataTest.createBranches(
			1,
			new Map<Schema.SObjectField, Object>{
				BranchUnit.BranchCode => 'PRB_0001',
				BranchUnit.Name => 'Sucursal',
				BranchUnit.ParentBranchUnitId => region.Id
			}
		)[0];
		insert sucursal;

        for(User u: newTestUsers){
            Banker bank = new Banker();
            bank.Disponible__c = TRUE;
            bank.JobCode = u.Alias;
            bank.Level = '1';
            bank.Name = u.Alias;
            bank.UserOrContactId = u.Id;
            
            if(u.Alias == 'asesorA1'){
                bank.CurrentBranchId = sucursal.Id;
                newAccounts.add(new Account(
                	FirstName = 'Test',
                    LastName = 'Acc1',
                    F3_Posicion_Global__c = 101000,
                    Suffix = 'Acc1',
                    OwnerId = u.Id
                ));
                
            } else if (u.Alias == 'asesorA2'){
                bank.CurrentBranchId = sucursal.Id;
                newAccounts.add(new Account(
                	FirstName = 'Test',
                    LastName = 'Acc2',
                    F3_Posicion_Global__c = 5001,
                    Suffix = 'Acc2',
                    OwnerId = u.Id
                ));
            } else if (u.Alias == 'asesorA3'){
                bank.CurrentBranchId = sucursal.Id;
                	newAccounts.add(new Account(
                	FirstName = 'Test',
                    LastName = 'Acc3',
                    F3_Posicion_Global__c = 500001,
                    Suffix = 'Acc3',
                    OwnerId = u.Id
                ));
            }
            
            newBankers.add(bank);
        }
        
        TriggerHandler.bypass('F3_BankerTrigger_Handler');
        	insert newBankers;
            for (Banker banker : newBankers) {
                if(banker.JobCode != 'asesorA1' && banker.JobCode != 'asesorA2' && banker.JobCode != 'asesorA3'){
                	branchMembers.add(new BranchUnitBusinessMember(BranchUnitId = sucursal.id, BusinessUnitMemberId = banker.id, IsActive = true));
                }
            }
        
            insert branchMembers;
        	for (Banker banker : newBankers) {
                if(banker.JobCode == 'dcf1'){
                    sucursal.BranchManagerId = banker.Id;
                }
                
                else if(banker.JobCode == 'pat1'){
                    patrimonial.BranchManagerId = banker.Id;
                }
            }
        
        update patrimonial;
        update sucursal;
        TriggerHandler.clearBypass('F3_BankerTrigger_Handler');
        newAccounts.add(new Account(
            FirstName = 'Test',
            LastName = 'Acc10',
            F3_Posicion_Global__c = 5001,
            Suffix = 'Acc10'
        ));
        insert newAccounts;
    }
    
    @IsTest
    public static void escalationRules_Test_success_exceptions() {
        List<Account> myTestAccList = [SELECT Id, Name FROM Account];
        List<Opportunity> myNewOpps = new List<Opportunity>();
        List<Opportunity> oppToUpdateList = new List<Opportunity>();
        
        if(myTestAccList.size() > 0){
            for(Account a : myTestAccList){
                Opportunity opp = new Opportunity ();
                opp.StageName = 'Identificar Necesidades';
                opp.LeadSource = a.Name != 'Test Acc3'? 'Email': 'Website';
                opp.AccountId = a.Id;
                opp.Inversion_Inicial__c = 'Mas de $1,500,000';
                opp.RecordTypeId = a.Name == 'Test Acc1'? META_FINANCIERA_RT : RETIRO_RT;
                opp.Name = a.Name == 'Test Acc1'? META_FINANCIERA_TITLE: RETIRO_TITLE;
                opp.MKT_Ahorro_Mensual__c = 5000;
                opp.MKT_ahorro_extra__c = 1300;
                opp.CloseDate = Date.today();
                opp.Productos_ofertados__c = a.Name == 'Test Acc1'? 'UpSell': 'PPR';
                
                if(a.Name == 'Test Acc1'){
                    opp.MKT_Tipo_Meta_Financiera__c = 'Auto';
                    opp.MKT_Monto_Objetivo__c = 12532.40;
                    opp.MKT_Plazo_Objetivo__c = 30.5;
                    
                } else {
                    opp.Unidad_de_Negocio__c = '1';
                    opp.Monto_M_ximo_a_Deducir__c = 2500;
                    opp.MKT_Beneficio_Fiscal__c = 1267.23;
                    opp.MKT_Edad__c = 18;
                    opp.MKT_ahorro_PPR_actinver__c = 766.33;
                }
                System.debug(opp);
                myNewOpps.add(opp);
            }
        }
        
        System.runAs(mc_crm_user) {
            Database.SaveResult[] lsr = Database.insert(myNewOpps, false);
            for (Database.SaveResult sr : lsr) {
                if (sr.isSuccess()) {
                    System.debug(sr.getId());
                } else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        //System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        //System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
    			}
			}
        }
        
        //Update related opportunities
        for(Opportunity opp : myNewOpps){
            if(opp.Id != null){
                opp.Last_Escalation_Date__c = Date.today()-4;
                oppToUpdateList.add(opp);
            }
            
            if(opp.LeadSource == 'Website'){
                opp.Total_Escalations__c = 1;
            }
        }
        
        update oppToUpdateList;
        
        Test.startTest();
        	System.schedule('ScheduledApexTest', CRON_EXP, new EscalationOpportunity_Scheduler());
        Test.stopTest();
    }
}