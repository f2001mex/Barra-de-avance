@IsTest
private without sharing class F4_SchedulerCalendar_WorkTypes_Test {
    @TestSetup
    private static void makeData(){
        OperatingHours objOperatingHours = new OperatingHours();
        objOperatingHours.TimeZone = 'America/Mexico_City';
        objOperatingHours.Name = 'Horario Laboral Scheduler CAT';
        insert objOperatingHours;
        
        ServiceTerritory objServiceTerritory = new ServiceTerritory();
            objServiceTerritory.IsActive = true;
            objServiceTerritory.Name     = 'CD MX MONTES URALES';
            objServiceTerritory.ExternalID__c = '300000003813421';
            objServiceTerritory.OperatingHoursId = objOperatingHours.Id;
        insert objServiceTerritory;
        
        BranchUnit objBranchUnit = new BranchUnit();
        	objBranchUnit.ServiceTerritoryId = objServiceTerritory.Id;
            objBranchUnit.ExternalID__c  = '300000003813421';
            objBranchUnit.Name           ='CD MX MONTES URALES';
            objBranchUnit.IsActive = true;
        insert objBranchUnit;
        
        WorkTypeGroup testWorkGroup = new WorkTypeGroup(
            IsActive = true,
            Name = 'TestWork Group',
            Description = 'TestWork Group'
        );
        insert testWorkGroup;

        WorkTypeGroup testWorkGroup2 = new WorkTypeGroup(
            IsActive = true,
            Name = 'TestWork Group2',
            Description = 'TestWork Group2',
            Is_new_product_scheduler__c = true
        );
        insert testWorkGroup2;
        
        Account objAcc = new Account();
        objAcc.FirstName = 'Test';
        objAcc.MiddleName = 'Test';
        objAcc.LastName = 'Test';
        objAcc.F3_CURP__c = 'TESTING1';
        objAcc.Client_ID__c = '123456789';
        objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        insert objAcc;
        
        Contract objContract = new Contract();
        objContract.AccountId = objAcc.Id;
        objContract.ContractNumber__c = '142536';
        objContract.Status__c = 'Aprobado.';
        objContract.IDSap__c = '142536';
        insert objContract;
        
        Telefono_de_Contrato__c objTel = new Telefono_de_Contrato__c();
        objTel.Name = 'Test';
        objTel.IDSap__c = objContract.Id;
        objTel.Phone_Type__c = 'CELULAR';
        objTel.Phone__c = '2711768347';
        objTel.principal__c = false;
        insert objTel;
        
        Correo_de_Contrato__c objEmail = new Correo_de_Contrato__c();
        objEmail.Name = 'Test';
        objEmail.NUM_CONTRATO__c = objContract.Id;
        objEmail.Contract_email__c = 'test@mail.com';
        objEmail.Principal__c = false;
        insert objEmail;
    }
    
    
    @IsTest
    private static void testMethod_picklist_and_Lead() {
        String extensionClass = 'F4_SchedulerCalendar_SelectWorkTypes';
        Callable extension = (Callable) Type.forName(extensionClass).newInstance();
        Callable extension2 = (Callable) Type.forName(extensionClass).newInstance();

        Map<String, Object> outMap = new Map<String, Object>();

        extension.call('PopulatePicklist', new Map<String, Object> {
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        });
        
        extension.call('validateParentRecord_Lead', new Map<String, Object> {
            'input' => new Map<String, Object>{
                'numero_telefono' => '5555555555',
                'lead_firstname' => 'Test',
                'lead_lastname' => 'Lead',
                'lead_suffix' => 'LastName',
                'lead_email' => 'test@test.com',
                'lead_company' => 'Independent'
            },

            'output' => outMap,
            'options' => new Map<String, Object>()
        });
        
		ServiceTerritory objServiceTerritory = [SELECT Id FROM ServiceTerritory WHERE ExternalId__c= '300000003813421' LIMIT 1];
        extension.call('createServiceAppointment', new Map<String, Object> {
            'input' => new Map<String, Object>{
                'schedStartTime' => '2024-05-25T06:00:00.000+0000',
                'schedEndTime' => '2024-05-25T07:00:00.000+0000',
                'subject' => 'Test Subject',
                'recordId' => String.valueOf(outMap.get('recordId')),
                'email' => 'test@test.com',
                'description' => 'Test Description',
                'motivo' => 'Información y Solicitudes',
                'submotivo' => 'Estado de Cuenta / CF',
                'tipo' => 'Cliente',
                'quienAtiende'=>'Anfitrión',
                'resourceOwnerId' => UserInfo.getUserId(),
                'phoneAppointment' => '5555555555',
                'locationAddress' => 'Test location',
                'additionalInformation' => 'Test additional information',
                'commentsAppointment' => 'Test comments',
                'parentRecordType' => 'Lead',    
                'serviceTerritoryId' => objServiceTerritory.Id,       
                'name' => 'testName',         
                'lastName' => 'testLastName',         
                'suffix' => 'testSuffix'    
            },

            
            
            
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        });

        extension2.call('PopulatePicklist_Product', new Map<String, Object> {
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        });
        
        extension.call('validateParentRecord_Account', new Map<String, Object> {
            'input' => new Map<String, Object>{
                'numero_telefono' => '2711768347',
                'correo' => 'test@mail.com'
            },

            'output' => outMap,
            'options' => new Map<String, Object>()
        });
    }
    
    @IsTest
    private static void testMethod_ValidateAccount() {
        String extensionClass = 'F4_SchedulerCalendar_SelectWorkTypes';
        Callable extension = (Callable) Type.forName(extensionClass).newInstance();
        

        Map<String, Object> outMap = new Map<String, Object>();
        
		extension.call('validateParentRecord_Account', new Map<String, Object> {
            'input' => new Map<String, Object>{
                'numero_telefono' => '2711768347',
                'correo' => 'test@mail.com'
            },

            'output' => outMap,
            'options' => new Map<String, Object>()
        });
        ServiceTerritory objServiceTerritory = [SELECT Id FROM ServiceTerritory WHERE ExternalId__c= '300000003813421' LIMIT 1];
        extension.call('createServiceAppointment', new Map<String, Object> {
            'input' => new Map<String, Object>{
                'schedStartTime' => '2024-05-25T06:00:00.000+0000',
                'schedEndTime' => '2024-05-25T07:00:00.000+0000',
                'subject' => 'Test Subject',
                'recordId' => String.valueOf(outMap.get('recordId')),
                'email' => 'test@test.com',
                'description' => 'Test Description',
                'motivo' => 'Información y Solicitudes',
                'submotivo' => 'Estado de Cuenta / CF',
                'tipo' => 'Cliente',
                'quienAtiende'=>'Anfitrión',
                'resourceOwnerId' => UserInfo.getUserId(),
                'phoneAppointment' => '5555555555',
                'locationAddress' => 'Test location',
                'additionalInformation' => 'Test additional information',
                'commentsAppointment' => 'Test comments',
                'parentRecordType' => 'Account',  
                'serviceTerritoryId' => objServiceTerritory.Id,       
                'name' => 'testName',         
                'lastName' => 'testLastName',         
                'suffix' => 'testSuffix'  
            },

            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        });
        
        
    }
}