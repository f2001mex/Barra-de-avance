# PSTA_RegistroResumenGlobal_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo de `PSTA_RegistroResumenGlobal_sch` en fullcopy. El proceso construye o actualiza un resumen global por banquero/miembro de negocio a partir de `BranchUnitBusinessMember`, cuentas priorizadas y reglas de dias habiles. Su impacto principal es sobre `ResumenGlobalPostventa__c`.

- Schedule Job: `PSTA_RegistroResumenGlobal`
- CronExpression: `0 0 4 ? * 2,3,4,5,6,7`
- TimesTriggered: `1`
- NextFireTime UTC: `2026-03-14T10:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Resumen_Global_Registros = 200`
- ACT_BatchConfig__mdt: `PSTA_RegistroResumenGlobal -> BusinessHoursName__c = Postventa`

## 2. Resumen ejecutivo del flujo
1. El scheduler consulta `ACT_BatchConfig__mdt` para `PSTA_RegistroResumenGlobal`.
2. Si `ACT_BusinessHoursHelper_cls` determina que el dia es habil segun `BusinessHours Postventa`, ejecuta `PSTA_RegistroResumenGlobal_bch`.
3. El batch obtiene desde `PSTA_Consultas__mdt` la query `PSTA_Query_Registro_Resumen_Global` para consultar `BranchUnitBusinessMember`.
4. Por cada `BranchUnitBusinessMember`, el codigo castea `BusinessUnitMember` a `Banker` y toma `ExternalId__c`.
5. `PSTA_RegistroResumenGlobal_cls.getMetaByAccount()` cuenta cuentas `Account` por asesor donde `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = true` y `EstatusContacto__c = 'Pendiente'`.
6. `PSTA_RegistroResumenGlobal_cls.getUserIds()` mapea `Banker.ExternalId__c` a `User.Id` activo usando `User.ID_ASESOR__c`.
7. El batch construye `ResumenGlobalPostventa__c` con `Name`, `Fecha__c`, `Banker__c`, `OwnerId`, `ExternalId_Nomina__c`, `Contactados__c = 0` y `Meta__c`.
8. La persistencia se hace con `Database.upsert(lstRecords, ResumenGlobalPostventa__c.ExternalId_Nomina__c, false)`.
9. Existe una lectura adicional de `getResumenesActuales()`, pero el mapa retornado no se usa despues dentro del flujo observado.

## 3. Diagrama del flujo completo
```text
PSTA_RegistroResumenGlobal_sch.execute(ctx)
  -> ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
         'PSTA_RegistroResumenGlobal',
         new PSTA_RegistroResumenGlobal_bch(),
         Label.PSTA_Resumen_Global_Registros)

PSTA_RegistroResumenGlobal_bch.start(bc)
  -> si Test.isRunningTest(): query hardcodeada
  -> si no: PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'
  -> Database.query(query)

PSTA_RegistroResumenGlobal_bch.execute(bc, scope)
  -> scope = List<BranchUnitBusinessMember>
  -> obtiene lista de ExternalId__c de banker
  -> PSTA_RegistroResumenGlobal_cls.getMetaByAccount(lstBanqueros)
     -> Aggregate sobre Account agrupando por ID_Asesor__c
  -> PSTA_RegistroResumenGlobal_cls.getResumenesActuales()
     -> SELECT Id, ExternalId_Nomina__c, Meta__c, Contactados__c FROM ResumenGlobalPostventa__c
     -> mapa no usado despues
  -> PSTA_RegistroResumenGlobal_cls.getUserIds()
     -> Banker.ExternalId__c -> User.ID_ASESOR__c -> User.Id
  -> por cada BBM crea ResumenGlobalPostventa__c
     -> Name = banker.Name
     -> Fecha__c = hoy
     -> Banker__c = BranchUnitBusinessMember.Id
     -> OwnerId = User.Id mapeado
     -> ExternalId_Nomina__c = banker.ExternalId__c
     -> Contactados__c = 0
     -> Meta__c = conteo de cuentas pendientes/priorizadas
  -> PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert)
     -> Database.upsert(lstRecords, ExternalId_Nomina__c, false)
     -> EventLogger.error(...) si hay errores
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_RegistroResumenGlobal_sch
1. Implementa `Schedulable`.
2. `execute()` delega a `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay('PSTA_RegistroResumenGlobal', new PSTA_RegistroResumenGlobal_bch(), Integer.valueOf(System.Label.PSTA_Resumen_Global_Registros))`.
3. No hace DML directo.

### 4.2 ACT_BusinessHoursHelper_cls en este flujo
1. Lee `ACT_BatchConfig__mdt` con `DeveloperName = PSTA_RegistroResumenGlobal`.
2. Recupera `BusinessHoursName__c = Postventa`.
3. Resuelve el `BusinessHours.Id`.
4. Valida si la fecha actual es dia habil con `BusinessHours.nextStartDate(...)`.
5. Solo si la validacion es positiva ejecuta el batch.

### 4.3 PSTA_RegistroResumenGlobal_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` usa una query hardcodeada solo cuando `Test.isRunningTest()`.
3. En runtime real usa `PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM()`.
4. `execute()` castea el scope a `List<BranchUnitBusinessMember>`.
5. Recorre el scope y extrae `Banker.ExternalId__c` desde `BusinessUnitMember`.
6. Llama tres metodos de servicio:
7. `getMetaByAccount(lstBanqueros)`.
8. `getResumenesActuales()`.
9. `getUserIds()`.
10. Luego construye la lista `lstResumenesUpsert`.
11. Finalmente llama `PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert)`.
12. `finish()` solo deja debug.

### 4.4 PSTA_RegistroResumenGlobal_cls
1. `getResumenesActuales()` consulta todos los `ResumenGlobalPostventa__c` con campos `Id`, `ExternalId_Nomina__c`, `Meta__c`, `Contactados__c`.
2. Crea un mapa `ExternalId_Nomina__c -> SObject`.
3. En la version fullcopy analizada, ese mapa no se reutiliza despues dentro de `execute()`. Es una lectura redundante o reservada para futura logica.
4. `getMetaByAccount(List<String> lstAsesores)` hace un `AggregateResult` sobre `Account` agrupando por `ID_Asesor__c`.
5. La condicion exacta del aggregate es:
6. `ID_Asesor__c IN :lstAsesores`.
7. `ID_Asesor__c != null`.
8. `ContactoPriorizadoEsteMes__c = true`.
9. `PriorizacionContacto__c = true`.
10. `EstatusContacto__c = 'Pendiente'`.
11. El valor resultante se guarda como `Meta__c` del resumen.
12. `getAllDivisions()` consulta `ConfiguracionActinver__c` donde `ClientesContactarPorDia__c != null` y arma un mapa `Segmento__c -> ClientesContactarPorDia__c`; en el flujo observado este metodo no es usado por el batch.
13. `getUserIds()` consulta todos los `Banker` con `ExternalId__c != null`, arma un set de external ids y luego consulta `User` activos donde `ID_ASESOR__c IN :externalIdsBankers`.
14. El resultado final es un mapa `ExternalId__c -> User.Id`.
15. `upsertRecords(List<SObject>)` ejecuta `Database.upsert(lstRecords, ResumenGlobalPostventa__c.ExternalId_Nomina__c, false)`.
16. Si algun registro falla, registra el error con `EventLogger.error(...)`.
### 4.5 PSTA_SegmentacionClientesSelector_cls en este flujo
1. Aunque su nombre refiere segmentacion, la clase expone `getQueryAllBBM()`.
2. Ese metodo consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Registro_Resumen_Global`.
3. La query recuperada en fullcopy usa `TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END`.
4. Esa estructura permite leer atributos propios del `Banker` dentro de la consulta de `BranchUnitBusinessMember`.

## 5. Como consulta metadata y como la utiliza
### 5.1 ACT_BatchConfig__mdt
1. El scheduler usa la clave `PSTA_RegistroResumenGlobal`.
2. El helper recupera `BusinessHoursName__c = Postventa`.
3. Ese valor controla si el batch corre o se inhibe.

### 5.2 PSTA_Consultas__mdt
1. `getQueryAllBBM()` obtiene `PSTA_Query_Registro_Resumen_Global`.
2. La query trabaja sobre `BranchUnitBusinessMember` y usa `TYPEOF BusinessUnitMember` para traer datos del `Banker`.
3. Cambiar esa metadata cambia el universo de miembros de negocio procesados sin despliegue.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'
```

### 5.3 ConfiguracionActinver__c
1. En este flujo no es necesaria para crear el resumen principal.
2. Existe `getAllDivisions()` que la consulta por `ClientesContactarPorDia__c`, pero el batch actual no la usa.
3. Por lo tanto, `ConfiguracionActinver__c` es una dependencia disponible en la clase, no una dependencia efectiva del flujo ejecutado por el scheduler.

### 5.4 Custom Labels
1. `PSTA_Resumen_Global_Registros = 200` controla el tamano del batch.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_RegistroResumenGlobal_sch` -> `ACT_BatchConfig__mdt` -> Read -> `BusinessHoursName__c` via helper.
- `ACT_BusinessHoursHelper_cls` -> `BusinessHours` -> Read -> `Name = Postventa`, `Id`.
- `PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Registro_Resumen_Global`.
- `PSTA_RegistroResumenGlobal_bch` -> `BranchUnitBusinessMember` -> Read -> `Id`, `BusinessUnitMemberId`, `TYPEOF BusinessUnitMember`.
- `PSTA_RegistroResumenGlobal_cls.getMetaByAccount` -> `Account` -> Aggregate Read -> `ID_Asesor__c`, conteo de cuentas con `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = true`, `EstatusContacto__c = 'Pendiente'`.
- `PSTA_RegistroResumenGlobal_cls.getResumenesActuales` -> `ResumenGlobalPostventa__c` -> Read -> `Id`, `ExternalId_Nomina__c`, `Meta__c`, `Contactados__c`.
- `PSTA_RegistroResumenGlobal_cls.getUserIds` -> `Banker` -> Read -> `ExternalId__c`, `Division__c`, `Cargo__c`.
- `PSTA_RegistroResumenGlobal_cls.getUserIds` -> `User` -> Read -> `Id`, `Name`, `ID_ASESOR__c`, `IsActive`.
- `PSTA_RegistroResumenGlobal_bch` -> `ResumenGlobalPostventa__c` -> Prepare upsert -> `Name`, `Fecha__c`, `Banker__c`, `OwnerId`, `ExternalId_Nomina__c`, `Contactados__c`, `Meta__c`.
- `PSTA_RegistroResumenGlobal_cls` -> `ResumenGlobalPostventa__c` -> Upsert -> llave externa `ExternalId_Nomina__c`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.

## 7. Registros creados, actualizados o no modificados
1. Inserta `ResumenGlobalPostventa__c` si no existe un registro con la misma `ExternalId_Nomina__c`.
2. Actualiza `ResumenGlobalPostventa__c` si ya existe un registro con esa llave externa.
3. No actualiza `Account`, `Contract` ni `BranchUnitBusinessMember` en el flujo principal observado.
4. Inserta `WebServiceTrackingLog__c` solo en caso de error.
5. `getResumenesActuales()` realiza lectura de `ResumenGlobalPostventa__c`, pero esa lectura hoy no cambia el comportamiento observable del upsert.

## 8. Riesgos, observaciones y puntos de auditoria
1. `getResumenesActuales()` es un hallazgo tecnico: hoy consulta datos que luego no utiliza el batch.
2. La llave externa `ExternalId_Nomina__c` es critica. Si hay mala calidad de datos, el upsert puede insertar duplicados funcionales o actualizar el resumen equivocado.
3. La meta (`Meta__c`) no viene de metadata sino de un conteo vivo sobre `Account`; por eso el resultado depende del estado real de priorizacion al momento de correr el batch.
4. El helper de business hours puede impedir la ejecucion real aunque el job exista en `CronTrigger`.
5. La query base esta en metadata; cambios en `PSTA_Query_Registro_Resumen_Global` alteran el conjunto de banqueros procesados sin despliegue.

## 9. Anexo de codigo fuente completo
Esta seccion agrega el codigo fuente completo de todos los artefactos que participan en el proceso analizado.

### classes/PSTA_RegistroResumenGlobal_sch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_RegistroResumenGlobal_sch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test        :   PSTA_RegistroResumenGlobal_sch_tst
* Description       :   Clase exclusiva para el registro de resumen global
*-------------------------------------------------------------------------- 
* No.            Date              Author                    Description
* 1.0         16-Jul-2025       Canche Isaac                 Creación
* 1.1         20-Jan-2026       Francisco Ortega             Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_RegistroResumenGlobal_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_RegistroResumenGlobal',
            new PSTA_RegistroResumenGlobal_bch(),
            Integer.valueOf(System.Label.PSTA_Resumen_Global_Registros)
        );
    }
}
```

### classes/ACT_BusinessHoursHelper_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\ACT_BusinessHoursHelper_cls.cls
```text
/*******************************************************************************
* Developed by      :   Actinver Mexico
* Author            :   Francisco Ortega
* Project           :   Post venta
* Clase test        :   ACT_BusinessHoursHelper_cls_Test
* Description       :   Helper unificado para:
*                       - Leer CMDT ACT_BatchConfig__mdt
*                       - Resolver Business Hours (ej. 'Postventa')
*                       - Evaluar horario habil y dia habil
*                       - Ejecutar batches segun la regla requerida
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         18-Nov-2025       Francisco Ortega         Creacion (version PSTA)
* 1.1         20-Jan-2026       Francisco Ortega         Ejecutar Business Hours en una sola clase
* 1.2         11-Mar-2026       Francisco Ortega         Validar dia habil para schedulers nocturnos
*--------------------------------------------------------------------------
*******************************************************************************/
public with sharing class ACT_BusinessHoursHelper_cls {

    @TestVisible private static Boolean testOverrideIsWithinConfiguredBH;
    @TestVisible private static Boolean testOverrideIsConfiguredBusinessDay;

    private static String getConfiguredBusinessHoursName(String configDeveloperName) {
        if (String.isBlank(configDeveloperName)) {
            return null;
        }

        try {
            List<SObject> configs = Database.query(
                'SELECT BusinessHoursName__c ' +
                'FROM ACT_BatchConfig__mdt ' +
                'WHERE DeveloperName = :configDeveloperName ' +
                'LIMIT 1'
            );

            if (!configs.isEmpty()) {
                return (String)configs[0].get('BusinessHoursName__c');
            }
        } catch (Exception e) {
            return null;
        }

        return null;
    }

    private static Id getConfiguredBusinessHoursId(String configDeveloperName) {
        String businessHoursName = getConfiguredBusinessHoursName(configDeveloperName);
        if (String.isBlank(businessHoursName)) {
            return null;
        }

        try {
            BusinessHours bh = [
                SELECT Id
                FROM BusinessHours
                WHERE Name = :businessHoursName
                LIMIT 1
            ];
            return bh.Id;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Valida si System.now() esta dentro del horario habil configurado.
     * Si bhId es null, Salesforce usa el BH default del org.
     */
    public static Boolean isWithinConfiguredBH(String configDeveloperName) {
        if (Test.isRunningTest() && testOverrideIsWithinConfiguredBH != null) {
            return testOverrideIsWithinConfiguredBH;
        }

        Datetime nowDt = System.now();
        Id bhId = getConfiguredBusinessHoursId(configDeveloperName);

        try {
            return BusinessHours.isWithin(bhId, nowDt);
        } catch (Exception e) {
            return true;
        }
    }

    /**
     * Valida si el dia actual es dia habil segun la BH configurada.
     * Ignora la hora actual para permitir ejecuciones de madrugada.
     */
    public static Boolean isConfiguredBusinessDay(String configDeveloperName) {
        if (Test.isRunningTest() && testOverrideIsConfiguredBusinessDay != null) {
            return testOverrideIsConfiguredBusinessDay;
        }

        Date currentDate = System.now().date();
        Datetime startOfDay = Datetime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0));
        Id bhId = getConfiguredBusinessHoursId(configDeveloperName);

        try {
            Datetime nextStart = BusinessHours.nextStartDate(bhId, startOfDay);
            return nextStart != null && nextStart.date() == currentDate;
        } catch (Exception e) {
            return true;
        }
    }

    private static Id executeBatch(
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (scopeSize != null) {
            return Database.executeBatch(batchInstance, scopeSize);
        }
        return Database.executeBatch(batchInstance);
    }

    /**
     * Ejecuta batch solo si esta dentro de horario habil (regla estricta por hora).
     */
    public static Id executeBatchIfWithinConfiguredBH(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (!isWithinConfiguredBH(configDeveloperName)) {
            return null;
        }
        return executeBatch(batchInstance, scopeSize);
    }

    public static Id executeBatchIfWithinConfiguredBH(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance
    ) {
        return executeBatchIfWithinConfiguredBH(configDeveloperName, batchInstance, null);
    }

    /**
     * Ejecuta batch solo si el dia actual es habil (ignora hora).
     * Esta variante permite jobs nocturnos manteniendo bloqueo en dias inhabiles.
     */
    public static Id executeBatchIfConfiguredBusinessDay(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance,
        Integer scopeSize
    ) {
        if (!isConfiguredBusinessDay(configDeveloperName)) {
            return null;
        }
        return executeBatch(batchInstance, scopeSize);
    }

    public static Id executeBatchIfConfiguredBusinessDay(
        String configDeveloperName,
        Database.Batchable<SObject> batchInstance
    ) {
        return executeBatchIfConfiguredBusinessDay(configDeveloperName, batchInstance, null);
    }
}
```

### classes/PSTA_RegistroResumenGlobal_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_RegistroResumenGlobal_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post venta
* Clase test    :   
* Description       :   Batch para la creación y actualización del objeto Resumen
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         24-Jun-2025       Gallegos Alan              Creación
*--------------------------------------------------------------------------
*******************************************************************************/

global class PSTA_RegistroResumenGlobal_bch implements Database.Batchable<sObject>{

    public List<BranchUnitBusinessMember> start(Database.BatchableContext BC) {
        String query;
        if (Test.isRunningTest()) {
            query = 'SELECT Id, Name, BusinessUnitMemberId, TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END FROM BranchUnitBusinessMember WHERE ExternalId__c != null';
        }else {
            query = PSTA_SegmentacionClientesSelector_cls.getQueryAllBBM();
        }
        return Database.query(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        List<BranchUnitBusinessMember> lstAllBBM    = (List<BranchUnitBusinessMember>) scope;
        List<String> lstBanqueros                   = new List<String>();
        
        System.debug('Lista de todos los BBM : '  + lstAllBBM);
        
        for (BranchUnitBusinessMember branchUnitBusinessMember : lstAllBBM) {
            Banker banquero = (Banker) branchUnitBusinessMember.BusinessUnitMember;
            lstBanqueros.add(banquero.ExternalId__c);
        }
        
        List<ResumenGlobalPostventa__c> lstResumenesUpsert = new List<ResumenGlobalPostventa__c>();
        
        Map<String, Integer> mapAsesorByMeta    = PSTA_RegistroResumenGlobal_cls.getMetaByAccount(lstBanqueros);
        Map<String, SObject> mapResExistentes   = PSTA_RegistroResumenGlobal_cls.getResumenesActuales();
        Map<String,String> mapaUserIds          = PSTA_RegistroResumenGlobal_cls.getUserIds();
        

        for(BranchUnitBusinessMember registroAsesor : lstAllBBM) {
            Banker banquero = (Banker) registroAsesor.BusinessUnitMember;

            Integer intMetaAsesor = mapAsesorByMeta.get(banquero.ExternalId__c);
            
            ResumenGlobalPostventa__c resumen = new ResumenGlobalPostventa__c();
            resumen.Name         = banquero.Name;
            resumen.Fecha__c     = System.today();
            resumen.Banker__c    = registroAsesor.Id;
            resumen.OwnerId      = mapaUserIds.containsKey(banquero.ExternalId__c) ? mapaUserIds.get(banquero.ExternalId__c) : null;
            resumen.ExternalId_Nomina__c = banquero.ExternalId__c;
            resumen.Contactados__c = 0;
            resumen.Meta__c = intMetaAsesor;
            
            lstResumenesUpsert.add(resumen);
            
        }

        PSTA_RegistroResumenGlobal_cls.upsertRecords(lstResumenesUpsert);

    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch objeto resumen finalizado');
    }
}
```

### classes/PSTA_RegistroResumenGlobal_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_RegistroResumenGlobal_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para la creación y actualización del objeto Resumen
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         24-Jun-2025       Gallegos Alan              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_RegistroResumenGlobal_cls {
     
    public static Map<String,SObject> getResumenesActuales() {

        List<SObject> lstResumenes = [SELECT Id,ExternalId_Nomina__c,Meta__c,Contactados__c FROM ResumenGlobalPostventa__c];
        Map<String,SObject> mapResumenesPorActualizar =  new Map<String,SObject>();

        for(SObject objectAux : lstResumenes){
            mapResumenesPorActualizar.put(String.valueOf( objectAux.get('ExternalId_Nomina__c') ), objectAux);
        }

        return mapResumenesPorActualizar;

    }

    public static Map<String,Integer> getMetaByAccount(List<String> lstAsesores) {
        Map<String,Integer> mapAsesorByMeta = new Map<String,Integer>();

        List<AggregateResult> resultados = [
            SELECT ID_Asesor__c asesorId, COUNT(Id) totalCuentas
            FROM Account 
            WHERE ID_Asesor__c IN :lstAsesores
                AND ID_Asesor__c != null 
                AND ContactoPriorizadoEsteMes__c = true 
                AND PriorizacionContacto__c = true 
                AND EstatusContacto__c = 'Pendiente'
            GROUP BY ID_Asesor__c
        ];

        for (AggregateResult ar : resultados) {
            String asesorId = (String)ar.get('asesorId');
            Integer totalCuentas = (Integer)ar.get('totalCuentas');
            mapAsesorByMeta.put(asesorId, totalCuentas);
        }

        return mapAsesorByMeta;
    }

    public static Map<String,Integer> getAllDivisions() {

        Map<String,Integer> mapaDivisionesMeta = new Map<String,Integer>();

        List<ConfiguracionActinver__c> lstMetasPorDia = [SELECT Id, Name, Segmento__c, ClientesContactarPorDia__c
                                                        FROM ConfiguracionActinver__c   
                                                        WHERE ClientesContactarPorDia__c != null];
        
        for(ConfiguracionActinver__c aux : lstMetasPorDia){
            mapaDivisionesMeta.put(aux.Segmento__c,Integer.valueOf( aux.ClientesContactarPorDia__c) );
        }
                                                  
        return mapaDivisionesMeta;

    }


    public static Map<String,String> getUserIds() {

        Map<String,String> mapIdAsesorIdUser = new Map<String,String>();
        Set<String> lstExternalIdsBankers = new Set<String>();

        List<Banker> lstBankers = [SELECT Id, Division__c, Cargo__c, ExternalId__c
                                  FROM Banker   
                                  WHERE ExternalId__c != null];

        for(Banker aux : lstBankers){
            lstExternalIdsBankers.add(aux.ExternalId__c);
        }
        
        
        // List<String> bnkIds = new List<Id>(new Map<Id, Banker>(lstBankers).keySet());

        List<User> listaUsers = [SELECT Id, Name, ID_ASESOR__c
                                FROM User WHERE ID_ASESOR__c IN :lstExternalIdsBankers AND IsActive = true];
        
        for(User aux : listaUsers){
            mapIdAsesorIdUser.put(aux.ID_ASESOR__c, aux.Id );
        }
                                                  
        return mapIdAsesorIdUser;

    }

    public static void upsertRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.UpsertResult[] upsertList = Database.upsert(lstRecords,ResumenGlobalPostventa__c.ExternalId_Nomina__c, false);
        for(Database.UpsertResult saveResult : upsertList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', saveResult.getId());
                    intCount++;
                }
                if(!mapErrors.isEmpty()){
                    saveLogError(mapErrors, 'Error durante la creacion del resumen global de contacto de asesor', 'ERROR_BATCH_RESUMENES_001', '');
                }
            }
        }
    }
    public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
        EventLogger.error(new Map<String, String>{'contextId' => null,
                                                    'type' => '',
                                                    'errorCode' => errorCode,
                                                    'message'   => message,
                                                    'request'   => JSON.serializePretty(mapErrors)});
    }



}
```

### classes/PSTA_SegmentacionClientesSelector_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_SegmentacionClientesSelector_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   
* Description       :   Clase selector que contiene todas las SOQL o DML del batch de la segmentacion de clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         12-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_SegmentacionClientesSelector_cls {

    public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
    public static final Id idConfigContratosPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();
    
    public static String getQueryCuentas( ) {
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'].Consulta__c ;
        
        return consulta;
    }
    /* public static String getQueryCuentas(String setStatusValidos, String setTipoContratoValidos ) {
        String[] lstAsesores = new List<String>{'65052','64505','64609','65401','6027','64066','65334','60357','60714','66432','52230','63703','22','66529','66531','68742','295','67272','65352','68741','66548','67526','51294','52425','64537','61230','50385','68492','60349','52335','50755','64073','66','63646','60376','5506','66805','64153','52458','67313','66568','65525','65172','10016','66557','61167','60308','64635','52471','64452','66666','62185','64737','66549','63845','67951','67875','67386','67359','68170','62525','52266','62299','60352','60368','67262','66530','60346','60353','64491','63658','63480','52287','62674','64461','68009','64458','62300','30007','52213','69004','64031','60420','98060','63174','67009','61373','64627','62847','62427','64591','64444','66447','63167','65280','65403','66436','66431','64964','67853','69181','67780','64441','66063','67387','67376','67358','63180','65010','128','60172','52603','67926','53728','69341','63601','64714','61108','63967','52557','62639','66965','68150'};
        String strAsesores  = PSTA_SegmentacionClientesSelector_cls.getStringQuery(lstAsesores);

        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'FechaUltimaVisita__c, ' +
                  'BanqueroAsignado__c, ' +
                  'SaldoIntegral__c, ' +
                  'Segmento__c, '+ 
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c ' +
                  'END ' +
                  'FROM Account WHERE BanqueroAsignado__c != null AND Person_Type__c = \'FISICA\' AND ID_Asesor__c != null' ;// AND Id_Asesor__c IN ' +strAsesores;
    } */


    public static ConfiguracionActinver__c getConfiguracionContratosPostventa(){
        return [SELECT TipoContratos__c, EstatusContrato__c 
                             FROM ConfiguracionActinver__c 
                             WHERE RecordTypeId =: idConfigContratosPostVentaRecordType 
                             LIMIT 1];
    }

    public static String getStringQuery(List<String> strConjunto){
        String strOr = '(';
        Integer intTamanio = 0;
        for(String elemento : strConjunto){
            strOr += '\'' + elemento + '\'';
            
            if(intTamanio < (strConjunto.size() - 1)){
                strOr += ',';
                intTamanio++;
            }
        }
        strOr += ')';
        return strOr;
    }

    public static List<ConfiguracionActinver__c> getConfiguracionContacto() {
        return [
            SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
        ];
    }


    public static ConfiguracionActinver__c getConfiguracionPatrimonialReactivo() {
        return [
            SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
            AND Segmento__c = 'Patrimonial reactivo'
            LIMIT 1
        ];
    }

    public static String getQueryAllBBM(){
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'].Consulta__c ;
        return consulta;
    }

    public static String getQueryStatusCuentas() {
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'].Consulta__c ;
        return consulta;
        
    }
    /* public static String getQueryAllBBM(){

       return 'SELECT Id, Name, BusinessUnitMemberId, TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END ' +
              'FROM BranchUnitBusinessMember ' +
              'WHERE ExternalId__c != null';
    }

    public static String getQueryStatusCuentas() {
        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'FechaSiguienteContacto__c, ' +
                  'Name,' +
                  'BanqueroAsignado__c,' +
                  'EstatusContacto__c,' +
                  'PriorizacionContacto__c,' +
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c ' +
                  'END ' +
                  'FROM Account ' +
                  'WHERE Person_Type__c = \'FISICA\' AND FechaSiguienteContacto__c != null AND FechaSiguienteContacto__c <= TODAY';
    } */
}
```

### classes/EventLogger.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\EventLogger.cls
```text
/****************************************************************************************************
Desarrollado por :  VASS MÉXICO
Proyecto         :  Actinver
Descripción      :  Clase para guardar registros de errores en eventos como WS o excepciones

Cambios (Versiones)
-----------------------------------------------------------------------------------------------------
No.     Fecha           Autor                   Descripción
-----   ----------      --------------------    -----------------------------------------------------
1.0     2024-08-14      VASS MÉXICO			    Creación de la Clase.            /survys?BR=001                            
*/
public without sharing class EventLogger {
    private static final String CLASSNAME = EventLogger.class.getName();
	private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');
    /**
	* @description: Logs an error associated to a map with error information. Result in a WebServiceTrackingLog__c record being inserted
	* @param Map<String String> logErrorMap 
	**/
	public static void error(Map<String, String> logErrorMap) {
		error(logErrorMap, new List<Object>());
	}
    /**
	* @description: Registra un error asociado a un mapa con información de error y una lista de información asociada. Resultado en la inserción de un registro WebServiceTrackingLog__c
	* @param Map<String String> logErrorMap 
	* @param List<Object> values 
	**/
	public static void error(Map<String, String> logErrorMap, List<Object> values) {
		String type = logErrorMap.get('type');
		WebServiceTrackingLog__c log = newLog(logErrorMap.get('message'), logErrorMap.get('request'), values, logErrorMap.get('contextId'), type);
		if(type == 'Medallia') {
			setMedalliaData(log, logErrorMap);
		}
        // if(type == 'Generico'){
		// 	setTransferData(log, logErrorMap);
		// }
		insertLogs(new List<WebServiceTrackingLog__c>{ log });
	}
	/**
	* @description: Add customized onboarding error information to new log
	* @param WebServiceTrackingLog__c log 
	* @param Map<String String> logErrorMap 
	* @param String type 
	* @return WebServiceTrackingLog__c 
	**/
	public static WebServiceTrackingLog__c setMedalliaData(WebServiceTrackingLog__c log, Map<String, String> logErrorMap) {
		log.RecordTypeId = getRecordTypeId('Medallia');
		if(logErrorMap.get('contextId') != null && logErrorMap.get('contextId') != '') {
			log.Visita__c = Id.valueOf(logErrorMap.get('contextId'));
		}
		log.Code__c = (logErrorMap.get('errorCode') != null && logErrorMap.get('errorCode') != '') ? logErrorMap.get('errorCode') : '';
		return log;
	}
	/**
	* @description: Crear nuevo registro con información básica
	* @param String message 
	* @param List<Object> values 
	* @param Id contextId 
	* @return WebServiceTrackingLog__c 
	**/
	public static WebServiceTrackingLog__c newLog(String message, String request, List<Object> values, Id contextId, String type) {
        WebServiceTrackingLog__c log = new WebServiceTrackingLog__c();
        log.Name        = 'Log ' + getTimestamp();
        log.Message__c  = (message != null && message != '') ? message + (!values.isEmpty() ? ' ; ' + cast(values) : '') : '';
        log.Request__c  = !String.isBlank(request) ? request : '';
        log.Type__c     = (type != null && type != '') ? type : '';
        populateLocation(log);
        return log;
    }
    /**
    * @description: Devuelve una marca de tiempo formateada
    * @return String 
    **/
    public static String getTimestamp() {
        return String.valueOf(System.now().format('dd/MM/yyyy HH:mm:ss'));
    }
     /**
    * @description: Lista de formato de información asociada
    * @param List<Object> values 
    * @return List<String> 
    **/
    public static List<String> cast(List<Object> values) {
        List<String> result = new List<String>();
		if(values != null) {
			for(Object value : values) {
				result.add(' ' + value);
			}
		}
        return result;
    }
    /**
    * @description: Agrega la ubicación del punto en el que ocurrió el error.
    * @param WebServiceTrackingLog__c log 
    **/
    public static void populateLocation(WebServiceTrackingLog__c log) {
        List<String> traceList = new DmlException().getStackTraceString().split('\n');
        for(String line : traceList) {
            Matcher matcher = STACK_LINE.matcher(line);
            if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.')) {
                log.Class__c = matcher.group(1);
                log.Method__c = getPrettyMethod(matcher.group(2));
                log.Line__c = Integer.valueOf(matcher.group(4));
                return;
            }
        }
    }
    /**
    * @description: Embellezca el campo del método para evitar nombres nulos o no deseados
    * @param String method 
    * @return String 
    **/
    public static String getPrettyMethod(String method) {
        return (method == null) ? 'anonymous' : method;
    }

    /**
    * @description: Inserta nuevos registros de error con la información proporcionada.
    * @param List<WebServiceTrackingLog__c> logsToInsert 
    **/
    public static void insertLogs(List<WebServiceTrackingLog__c> logsToInsert) {
		Database.SaveResult[] insertList = Database.insert (logsToInsert, false);
		for(Database.SaveResult saveResult : insertList) {
			if(!saveResult.isSuccess()) {
				System.debug('Unable to save Log: ' + saveResult.getErrors());
			}
		}
    }
     /**
    * @description : Obtener ID de tipo de registro por nombre de desarrollador
    * @param String developerName 
    * @return Id 
    **/
    public static Id getRecordTypeId(String developerName) {
        return Schema.SObjectType.WebServiceTrackingLog__c.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }
}
```
