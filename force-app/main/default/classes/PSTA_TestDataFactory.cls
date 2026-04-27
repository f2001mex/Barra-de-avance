/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Description       :   Clase helper que crea registros para pruebas de postventa
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         23-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/

public class PSTA_TestDataFactory {
    public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
    public static final Id idConfigContratosPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();
    // Método para crear configuración personalizada
    public static ConfiguracionActinver__c createConfiguracionContratosActinver() {
        ConfiguracionActinver__c config = new ConfiguracionActinver__c(
            Name = 'Configuración Test',
            TipoContratos__c = '01;02',
            EstatusContrato__c = 'Nuevo',
            RecordTypeId = idConfigContratosPostVentaRecordType
        );
        insert config;
        return config;
    }
    public static ConfiguracionActinver__c createConfiguracionContactoActinver() {
        ConfiguracionActinver__c config = new ConfiguracionActinver__c(
            Name = 'Configuración privada',
            Segmento__c ='Privada',
            RangoMontoMaximo__c = 20000,
            RangoMontoMinimo__c = 0,
            FrecuenciaContacto__c = 20,
            FrecuenciaVisita__c = 120,
            FrecReinicioNoReqContacto__c = '120',
            ClientesContactarPorDia__c = 5,
            RecordTypeId = idConfigContactoPostVentaRecordType
        );
        insert config;
        return config;
    }

    public static ConfiguracionActinver__c createConfiguracionPatrimonialReactivoActinver() {
        ConfiguracionActinver__c config = new ConfiguracionActinver__c(
            Name = 'Configuración patrimonial reactivo',
            Segmento__c ='Patrimonial reactivo',
            Rol__c = 'Farmer',
            RangoMontoMaximo__c = 200000,
            RangoMontoMinimo__c = 0,
            FrecuenciaContacto__c = 20,
            FrecuenciaVisita__c = 120,
            FrecReinicioNoReqContacto__c = '120',
            ClientesContactarPorDia__c = 5,
            RecordTypeId = idConfigContactoPostVentaRecordType
        );
        insert config;
        return config;
    }

    public static User createUser(){
        String adminProfileId = [SELECT Id FROM Profile WHERE name IN ('System Administrator', 'Administrador del sistema')].Id;
        User user = new User();
        user.LastName = 'User1';
        user.Username = 'User1@user.com.u';
        user.Email = 'Useruser@u.com.u';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.Alias = 'uAas2';
        user.IsActive = true;
        user.TimeZoneSidKey = 'America/Mexico_City';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'es';
        user.ID_ASESOR__c = '00045';
        user.ProfileId = adminProfileId;
        insert user;
        return user;
    }


    public static BranchUnit createBranchUnit(){
        BranchUnit branchUnit = new BranchUnit();
        branchUnit.Name = 'Test';
        branchUnit.IsActive = true;
        branchUnit.BranchCode = '10000012345';
        branchUnit.ExternalIdBI__c = '37';
        branchUnit.ExternalId__c = '10000012345';
        insert branchUnit;
        return branchUnit;
    }

    public static Banker createBanker(Id branchUnitId, Id userId){
        Banker bankerContact = new Banker();
        bankerContact.Name = 'TestBankerContact1';
        bankerContact.JobCode = '00045';
        bankerContact.ExternalId__c = '00045';
        bankerContact.Division__c = 'Privada';
        bankerContact.CurrentBranchId = branchUnitId;
        bankerContact.UserOrContactId = userId;
        insert bankerContact;
        return bankerContact;
    }


    public static BranchUnitBusinessMember getBranchUnitBusinessMember(Id idBanker, Id idBranchUnit){
        return [SELECT Id, ExternalId__c FROM BranchUnitBusinessMember WHERE BranchUnitId =: idBranchUnit AND BusinessUnitMemberId =: idBanker AND IsActive = true LIMIT 1];
    }
    
    

    // Método para crear cuentas
    public static List<Account> createAccounts(Integer numCuentas,Id idBanquero, Boolean doInsert) {
        List<Account> cuentas = new List<Account>();
        for(Integer i = 0; i < numCuentas; i++) {
            cuentas.add(new Account(
                Name = 'Cuenta Test ' + i,
                InstitucionFinancieraPrincipal__c = 'Banorte',
                PorqueIndentInteres__c = 'Prueba',
                Conquetipodeseguroscuentas__c = 'Seguro de Auto',
                CuandoVence__c = System.today(),
                Conqueempresaestasasegurado__c = 'Mapfre',
                MesPreferenteInversion_o_ahorrar__c = 'Febrero',
                Cuantos_hijos_tienes__c = '1',
                Viajas_recurrentemente__c = 'No',
                FamiliarqueseaclienteenActinver__c = 'No',
                Frecuencia_para_ser_contactado__c = 'El cliente prefiere contactarse con nosotros',
                MedioPreferidoContacto__c = 'Mail',
                BanqueroAsignado__c = idBanquero,
                Person_Type__c = 'FISICA',
                ID_Asesor__c = '00045'
            ));
        }
        if(doInsert) {
            OD_Account_cls.bypassTriggerExecution = true;
            insert cuentas;
        }
        return cuentas;
    }

    // Método para crear cuentas
    public static List<Account> createAccountsPriorizacion(Integer numCuentas,Id idBanquero, Boolean doInsert) {
        List<Account> cuentas = new List<Account>();
        for(Integer i = 0; i < numCuentas; i++) {
            cuentas.add(new Account(
                Name = 'Cuenta Test ' + i,
                InstitucionFinancieraPrincipal__c = 'Banorte',
                PorqueIndentInteres__c = 'Prueba',
                Conquetipodeseguroscuentas__c = 'Seguro de Auto',
                CuandoVence__c = System.today(),
                Conqueempresaestasasegurado__c = 'Mapfre',
                MesPreferenteInversion_o_ahorrar__c = 'Febrero',
                Cuantos_hijos_tienes__c = '1',
                Viajas_recurrentemente__c = 'No',
                FamiliarqueseaclienteenActinver__c = 'No',
                Frecuencia_para_ser_contactado__c = 'El cliente prefiere contactarse con nosotros',
                MedioPreferidoContacto__c = 'Mail',
                BanqueroAsignado__c = idBanquero,
                Segmento__c = 'Privada',
                FechaSiguienteContacto__c = System.today().addDays(-i * 10),
                ContactoPriorizadoEsteMes__c = true
            ));
        }
        if(doInsert) {
            OD_Account_cls.bypassTriggerExecution = true;
            insert cuentas;
        }
        return cuentas;
    }

    // Método para crear contratos
    public static List<Contract> createContracts(List<Id> accountIds, String idAsesor, Boolean doInsert,Id banqueroAsignado) {
        List<Contract> contratos = new List<Contract>();
        List<String> tiposContrato = new List<String>{'01', '02', '03'};
        List<String> estatus = new List<String>{'Aprobado', 'En proceso de validación', 'Cancelado'};
        for(Integer i = 0; i < accountIds.size(); i++) {
            Integer daysAgo = (i + 1) * 30;
            contratos.add(new Contract(
                AccountId = accountIds[i],
                TypeOfContract__c = '01',
                Status__c = 'Nuevo',
                AccountOpeningDate__c = Date.today().addDays(-daysAgo),
                Saldo__c = ''+i+1+'00',
                ID_ASESOR__c = idAsesor,
                BanqueroAsignado__c = banqueroAsignado
            ));
        }
        
        if(doInsert) {
            OD_Contract_cls.bypassTriggerExecution = true;
            insert contratos;
        }
        return contratos;
    }

}