String suffix = String.valueOf(Datetime.now().getTime());
User currentUser = [
    SELECT Id, ID_Asesor__c
    FROM User
    WHERE Id = :UserInfo.getUserId()
];

Map<String, Object> result = new Map<String, Object>();

try {
    BranchUnit branchUnit = new BranchUnit(
        Name = 'PV Cancelacion ' + suffix,
        IsActive = true,
        BranchCode = ('9' + suffix).left(11),
        ExternalIdBI__c = suffix.right(2),
        ExternalId__c = ('8' + suffix).left(11)
    );
    insert branchUnit;

    Banker banker = new Banker(
        Name = 'PV Banker ' + suffix,
        JobCode = String.isBlank(currentUser.ID_Asesor__c) ? '99999' : currentUser.ID_Asesor__c,
        ExternalId__c = String.isBlank(currentUser.ID_Asesor__c) ? '99999' : currentUser.ID_Asesor__c,
        Division__c = 'Privada',
        CurrentBranchId = branchUnit.Id,
        UserOrContactId = currentUser.Id
    );
    insert banker;

    BranchUnitBusinessMember bankerBbm = [
        SELECT Id
        FROM BranchUnitBusinessMember
        WHERE BranchUnitId = :branchUnit.Id
        AND BusinessUnitMemberId = :banker.Id
        AND IsActive = true
        LIMIT 1
    ];

    OD_Account_cls.bypassTriggerExecution = true;
    Account accountRecord = new Account(
        Name = 'PV Cancelacion Cuenta ' + suffix,
        InstitucionFinancieraPrincipal__c = 'Banorte',
        PorqueIndentInteres__c = 'Prueba cancelacion contrato',
        Conquetipodeseguroscuentas__c = 'Seguro de Auto',
        CuandoVence__c = System.today().addDays(30),
        Conqueempresaestasasegurado__c = 'Mapfre',
        MesPreferenteInversion_o_ahorrar__c = 'Febrero',
        Cuantos_hijos_tienes__c = '1',
        Viajas_recurrentemente__c = 'No',
        FamiliarqueseaclienteenActinver__c = 'No',
        Frecuencia_para_ser_contactado__c = 'El cliente prefiere contactarse con nosotros',
        MedioPreferidoContacto__c = 'Mail',
        BanqueroAsignado__c = bankerBbm.Id,
        Person_Type__c = 'FISICA',
        OwnerId = currentUser.Id,
        ID_Asesor__c = String.isBlank(currentUser.ID_Asesor__c) ? '99999' : currentUser.ID_Asesor__c,
        Segmento__c = 'Privada',
        ContactoPriorizadoEsteMes__c = true,
        PriorizacionContacto__c = true,
        PriorizacionVisita__c = true,
        FechaSiguienteContacto__c = Date.today(),
        FechaSiguienteVisita__c = Date.today()
    );
    insert accountRecord;
    OD_Account_cls.bypassTriggerExecution = false;

    Contact contactRecord = new Contact(
        FirstName = 'PV',
        LastName = 'Cancelacion ' + suffix,
        AccountId = accountRecord.Id
    );
    insert contactRecord;

    Task taskRecord = new Task(
        Subject = 'PV Cancelacion Task ' + suffix,
        Status = 'Abierto',
        WhatId = accountRecord.Id,
        WhoId = contactRecord.Id,
        OwnerId = currentUser.Id
    );
    insert taskRecord;

    Opportunity opportunityRecord = new Opportunity(
        Name = 'PV Cancelacion Opp ' + suffix,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(15),
        AccountId = accountRecord.Id,
        OwnerId = currentUser.Id
    );
    insert opportunityRecord;

    OD_Contract_cls.bypassTriggerExecution = true;
    Contract contractRecord = new Contract(
        AccountId = accountRecord.Id,
        TypeOfContract__c = '01',
        Status__c = 'Nuevo',
        AccountOpeningDate__c = Date.today().addDays(-30),
        Saldo__c = '1000',
        ID_ASESOR__c = String.isBlank(currentUser.ID_Asesor__c) ? '99999' : currentUser.ID_Asesor__c,
        BanqueroAsignado__c = bankerBbm.Id
    );
    insert contractRecord;
    contractRecord.Status__c = 'C02';
    update contractRecord;
    OD_Contract_cls.bypassTriggerExecution = false;

    Id jobId = Database.executeBatch(new PSTA_PostCargaPostventa_bch(), 1);

    result.put('jobId', jobId);
    result.put('accountId', accountRecord.Id);
    result.put('contactId', contactRecord.Id);
    result.put('taskId', taskRecord.Id);
    result.put('opportunityId', opportunityRecord.Id);
    result.put('contractId', contractRecord.Id);
    result.put('cadenceSetupNote', 'ActionCadenceTracker no es insertable por Apex anonimo en org; prueba enfocada en flags, task y opportunity.');
    result.put('suffix', suffix);

    List<ContractHistory> histories = [
        SELECT Id, Field, OldValue, NewValue, CreatedDate
        FROM ContractHistory
        WHERE ContractId = :contractRecord.Id
        ORDER BY CreatedDate DESC
    ];
    result.put('contractHistoryRows', histories.size());
} catch (Exception ex) {
    result.put('error', ex.getMessage());
    result.put('stack', ex.getStackTraceString());
}

System.debug('POSTVENTA_CANCELACION_TEST=' + JSON.serialize(result));
