# PSTA_ResetearEstatusContacto_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo completo de `PSTA_ResetearEstatusContacto_sch` en fullcopy. El nivel de detalle cubre scheduler, helper de business hours, batch principal, batch encadenado, metadata, objetos impactados, campos tocados y efectos colaterales por trigger.

A diferencia de `PSTA_SegmentacionClientes_sch`, este scheduler no ejecuta el batch directamente. Usa `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(...)`, lo que significa que el proceso solo se lanza si la configuracion del batch y el calendario habil lo permiten.

- Schedule Job: `PSTA_ResetearEstatusContacto`
- CronExpression: `0 0 1 ? * 2,3,4,5,6,7`
- TimesTriggered: `1`
- NextFireTime UTC: `2026-03-14T07:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Reinicio_Estatus_Registros = 200`
- ACT_BatchConfig__mdt: `PSTA_ResetearEstatusContacto -> BusinessHoursName__c = Postventa`

## 2. Resumen ejecutivo del flujo
1. El scheduler lee `ACT_BatchConfig__mdt` para el proceso `PSTA_ResetearEstatusContacto`.
2. `ACT_BusinessHoursHelper_cls` valida si el dia actual es habil segun `BusinessHours Postventa`.
3. Solo si el dia es habil ejecuta `PSTA_ResetearEstatusContacto_bch` con tamano tomado del label `PSTA_Reinicio_Estatus_Registros`.
4. `PSTA_ResetearEstatusContacto_bch.start()` obtiene desde metadata la query `PSTA_Query_Reinicio_Estatus_Contacto`.
5. `PSTA_ResetearEstatusContacto_cls.resetEstatus()` revisa cada cuenta y, cuando `FechaSiguienteContacto__c` ya vencio y el estatus no es `Pendiente`, prepara un update parcial sobre `Account`.
6. Los campos directos que modifica esta clase son exactos: `EstatusContacto__c = 'Pendiente'` y `PriorizacionContacto__c = false`.
7. `finish()` encadena `PSTA_AgrupacionPriorizacionDiaria_bch`, que reconstruye la lista diaria de contacto marcando `PriorizacionContacto__c = true` a un subconjunto controlado por configuracion y por limite de clientes por banquero.

## 3. Diagrama del flujo completo
```text
PSTA_ResetearEstatusContacto_sch.execute(ctx)
  -> ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
         'PSTA_ResetearEstatusContacto',
         new PSTA_ResetearEstatusContacto_bch(),
         Label.PSTA_Reinicio_Estatus_Registros)
  -> helper lee ACT_BatchConfig__mdt
  -> helper obtiene BusinessHours 'Postventa'
  -> helper evalua si hoy es dia habil
  -> si es habil: Database.executeBatch(...)
  -> si no es habil: no ejecuta batch

PSTA_ResetearEstatusContacto_bch.start(bc)
  -> PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'
  -> QueryLocator de Account

PSTA_ResetearEstatusContacto_bch.execute(bc, scope)
  -> PSTA_ResetearEstatusContacto_cls.resetEstatus(scope)
     -> si FechaSiguienteContacto__c != null
     -> y EstatusContacto__c != 'Pendiente'
     -> y hoy >= FechaSiguienteContacto__c
        prepara Account(Id)
        set EstatusContacto__c = 'Pendiente'
        set PriorizacionContacto__c = false
  -> updateRecords(values, map)
     -> Database.update(records, false)
     -> EventLogger.error(...) si hay errores
     -> dispara AccountTrigger

PSTA_ResetearEstatusContacto_bch.finish(bc)
  -> Database.executeBatch(new PSTA_AgrupacionPriorizacionDiaria_bch())

PSTA_AgrupacionPriorizacionDiaria_bch.start/execute
  -> PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria()
  -> lee PSTA_Query_Priorizacion_Diaria
  -> PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(...)
     -> por cada cuenta elegible calcula PriorizacionContacto__c
     -> respeta limite ClientesContactarPorDia__c por segmento y banquero
  -> Database.update(records, false)
  -> dispara AccountTrigger
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_ResetearEstatusContacto_sch
1. Implementa `Schedulable`.
2. `execute(SchedulableContext sc)` no ejecuta el batch directamente.
3. Invoca `ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay('PSTA_ResetearEstatusContacto', new PSTA_ResetearEstatusContacto_bch(), Integer.valueOf(System.Label.PSTA_Reinicio_Estatus_Registros))`.
4. Su unica responsabilidad es delegar al helper la validacion de dia habil y el disparo del batch.

### 4.2 ACT_BusinessHoursHelper_cls en este flujo
1. `getConfiguredBusinessHoursName(configDeveloperName)` consulta `ACT_BatchConfig__mdt` y obtiene `BusinessHoursName__c`.
2. `getConfiguredBusinessHoursId(configDeveloperName)` consulta `BusinessHours` por nombre.
3. `isConfiguredBusinessDay(configDeveloperName)` toma `System.now().date()`, crea el inicio del dia y usa `BusinessHours.nextStartDate(bhId, startOfDay)`.
4. La regla exacta es: el proceso corre si el siguiente inicio habil cae en la misma fecha actual.
5. `executeBatchIfConfiguredBusinessDay(...)` solo llama `Database.executeBatch(...)` si la validacion anterior regresa `true`.
6. En este scheduler la configuracion encontrada en fullcopy es `BusinessHoursName__c = Postventa`.

### 4.3 PSTA_ResetearEstatusContacto_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` retorna `Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas())`.
3. `execute()` castea el scope a `List<Account>`.
4. Llama `PSTA_ResetearEstatusContacto_cls.resetEstatus(lstClientes)`.
5. Si el mapa de cuentas a actualizar no esta vacio, llama `PSTA_ResetearEstatusContacto_cls.updateRecords(...)`.
6. `finish()` escribe un debug y ejecuta `Database.executeBatch(new PSTA_AgrupacionPriorizacionDiaria_bch())` sin tamano explicito, por lo que usa el default de Salesforce para batches.

### 4.4 PSTA_ResetearEstatusContacto_cls
1. `resetEstatus(List<Account> lstCuentas)` crea un `Map<Id, Account>` con updates parciales.
2. Para cada cuenta evalua tres condiciones exactas:
3. `cuenta.FechaSiguienteContacto__c != null`.
4. `cuenta.EstatusContacto__c != 'Pendiente'`.
5. `System.today() >= cuenta.FechaSiguienteContacto__c`.
6. Si todas se cumplen, construye `new Account(Id = cuenta.Id)`.
7. Asigna exactamente dos campos: `EstatusContacto__c = 'Pendiente'` y `PriorizacionContacto__c = false`.
8. No toca `FechaSiguienteContacto__c`, `FechaUltimoContacto__c` ni `FechaNoRequiereSerContacto__c` de manera directa.
9. `updateRecords(List<SObject> lstRecords, Map<Id, Account> mapRecords)` ejecuta `Database.update(lstRecords, false)`.
10. En error arma `mapErrors` con el mensaje y el nombre del registro fallido.
11. `saveLogError(...)` llama `EventLogger.error(...)`, que inserta `WebServiceTrackingLog__c`.
### 4.5 PSTA_AgrupacionPriorizacionDiaria_bch
1. Implementa `Database.Batchable<SObject>, Database.Stateful`.
2. En el constructor inicializa `mapAsesorPorNumCuentas` y `mapConfigPorSegmento`.
3. `mapConfigPorSegmento` viene de `PSTA_PriorizacionDiaria_cls.obtenerSegmentoPorConfig()`.
4. `start()` retorna `Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria())`.
5. `execute()` llama `PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapConfigPorSegmento, this.mapAsesorPorNumCuentas)`.
6. El metodo devuelve dos cosas: `lstCuentasParaActualizar` y el mapa stateful de numero de cuentas ya asignadas por asesor.
7. Si la lista a actualizar no esta vacia, llama `PSTA_PriorizacionDiaria_cls.updateRecords(lstClientesActualizar)`.
8. `finish()` solo deja trazas de debug.

### 4.6 PSTA_PriorizacionDiaria_cls
1. Tiene `defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales()`.
2. Tiene `hoy = Date.today()`.
3. `obtenerSegmentoPorConfig()` consulta `ConfiguracionActinver__c` desde `PSTA_PriorizacionSelector_cls.getConfiguracionContacto()` y mapea por `Segmento__c`.
4. `agrupacionBanqueroPorCuentas(...)` recorre cuentas, localiza la configuracion del segmento y toma `ClientesContactarPorDia__c` como limite por asesor.
5. Solo procesa cuentas donde `BanqueroAsignado__r.BusinessUnitMember` sea instancia de `Banker`.
6. Si el asesor aun no rebasa su limite, calcula `cuenta.PriorizacionContacto__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Integer.valueOf(config.FrecuenciaContacto__c), hoy)`.
7. El metodo `debePriorizarContacto(...)` usa `PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(FechaInicio, hoy, defaultBusinessHoursId)`.
8. La regla exacta actual es `lngDiasEntreFechas >= 0`; el parametro `intFrecuencia` se recibe pero no se usa en la condicion final.
9. Si `PriorizacionContacto__c` resulta `true`, agrega la cuenta a update y aumenta el contador del asesor.
10. `updateRecords()` hace `Database.update(records, false)` y registra errores via `EventLogger.error(...)`.

### 4.7 PSTA_PriorizacionSelector_cls en este flujo
1. `getQueryCuentasPriorizacionDiaria()` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Priorizacion_Diaria`.
2. `getConfiguracionContacto()` consulta `ConfiguracionActinver__c` record type `ContactoPostventa` y lee: `Segmento__c`, `RangoMontoMaximo__c`, `RangoMontoMinimo__c`, `FrecReinicioNoReqContacto__c`, `Rol__c`, `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `ClientesContactarPorDia__c`.
3. `getDiasLaborales()` consulta `BusinessHours` donde `Name = 'Postventa'`.

### 4.8 AccountTrigger y efectos indirectos
1. El update directo de `EstatusContacto__c` y `PriorizacionContacto__c` dispara `AccountTrigger`.
2. El segundo update de priorizacion diaria tambien dispara `AccountTrigger`.
3. Por ello el impacto final puede incluir cambios indirectos en `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `Segmento__c`, `RecordTypeId`, `OwnerId`, `BanqueroAsignado__c` y derivados, segun la logica activa del trigger.
4. El batch principal no toca esos campos de forma explicita, pero el trigger si puede hacerlo en la misma transaccion.

## 5. Como consulta metadata y como la utiliza
### 5.1 ACT_BatchConfig__mdt
1. El scheduler usa el nombre logico `PSTA_ResetearEstatusContacto`.
2. `ACT_BusinessHoursHelper_cls` consulta ese registro en `ACT_BatchConfig__mdt`.
3. En fullcopy el valor recuperado es `BusinessHoursName__c = Postventa`.
4. Ese dato decide si el batch corre o se inhibe en la fecha actual.

### 5.2 PSTA_Consultas__mdt
1. El batch principal obtiene `PSTA_Query_Reinicio_Estatus_Contacto`.
2. El batch encadenado obtiene `PSTA_Query_Priorizacion_Diaria`.
3. La query de reinicio filtra cuentas con `FechaSiguienteContacto__c <= TODAY` y otras condiciones funcionales definidas en metadata.
4. La query diaria filtra cuentas con `ContactoPriorizadoEsteMes__c = true`, `PriorizacionContacto__c = false`, `EstatusContacto__c = 'Pendiente'` y otras condiciones del universo de postventa.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'

SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'
```

### 5.3 ConfiguracionActinver__c
1. `PSTA_PriorizacionDiaria_cls` usa la configuracion `ContactoPostventa`.
2. Por segmento toma el limite `ClientesContactarPorDia__c`.
3. Tambien lee `FrecuenciaContacto__c`, aunque hoy el metodo `debePriorizarContacto()` no la aplica en su condicion final.
4. Este hallazgo es importante: la frecuencia se transporta por codigo pero no restringe la decision diaria en la implementacion actual.

### 5.4 Custom Labels
1. `PSTA_Reinicio_Estatus_Registros = 200` controla el tamano del batch principal.
2. El batch encadenado no recibe tamano explicito en `finish()`.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_ResetearEstatusContacto_sch` -> `ACT_BatchConfig__mdt` -> Read -> `BusinessHoursName__c` via helper.
- `ACT_BusinessHoursHelper_cls` -> `BusinessHours` -> Read -> `Name = Postventa`, `Id`.
- `PSTA_ResetearEstatusContacto_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Reinicio_Estatus_Contacto`.
- `PSTA_ResetearEstatusContacto_cls` -> `Account` -> Update -> `EstatusContacto__c = 'Pendiente'`, `PriorizacionContacto__c = false`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.
- `PSTA_AgrupacionPriorizacionDiaria_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Priorizacion_Diaria`.
- `PSTA_PriorizacionDiaria_cls` -> `ConfiguracionActinver__c` -> Read -> `ClientesContactarPorDia__c`, `FrecuenciaContacto__c`, `Segmento__c` y demas parametros.
- `PSTA_PriorizacionDiaria_cls` -> `BusinessHours` -> Read -> `Postventa`.
- `PSTA_PriorizacionDiaria_cls` -> `Account` -> Update -> `PriorizacionContacto__c`.
- `AccountTrigger` y clases relacionadas -> `Account` -> Before update indirecto -> `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `Segmento__c`, `RecordTypeId` y derivados.

## 7. Registros creados, actualizados o no modificados
1. Actualiza `Account` en el batch de reinicio de estatus.
2. Actualiza `Account` nuevamente en el batch encadenado de priorizacion diaria.
3. Inserta `WebServiceTrackingLog__c` solo en caso de error.
4. No crea `Task`, `Contract` ni `ResumenGlobalPostventa__c` en este flujo.
5. No modifica metadata; solo la consulta.

## 8. Riesgos, observaciones y puntos de auditoria
1. El job programado puede existir y dispararse por cron, pero el helper puede impedir que corra el batch si el dia no es habil.
2. La logica real de elegibilidad depende de queries en metadata; un cambio en `PSTA_Query_Reinicio_Estatus_Contacto` altera el universo procesado sin despliegue.
3. `PSTA_PriorizacionDiaria_cls.debePriorizarContacto()` recibe `intFrecuencia`, pero hoy no lo usa para filtrar; la condicion real es `diasHabiles >= 0`.
4. `finish()` encadena priorizacion diaria sin una segunda validacion de business hours.
5. Al usar `Database.update(..., false)`, la consistencia final exige revisar `WebServiceTrackingLog__c`.

## 9. Anexo de codigo fuente completo
Esta seccion agrega el codigo fuente completo de todos los artefactos que participan en el proceso analizado.

### classes/PSTA_ResetearEstatusContacto_sch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ResetearEstatusContacto_sch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test        :   PSTA_ResetearEstatusContacto_sch_tst
* Description       :   Clase exclusiva para el reinicio de estatus de contacto de clientes
*-------------------------------------------------------------------------- 
* No.            Date              Author                Description
* 1.0         16-Jul-2025       Canche Isaac             Creación
* 1.1         20-Jan-2026       Francisco Ortega         Ejecución de BusinessHours vía ACT_PSTA_BusinessHoursHelper_cls
*-------------------------------------------------------------------------- 
*******************************************************************************/
global class PSTA_ResetearEstatusContacto_sch implements Schedulable {

    global void execute(SchedulableContext sc) {

        ACT_BusinessHoursHelper_cls.executeBatchIfConfiguredBusinessDay(
            'PSTA_ResetearEstatusContacto',                        // DeveloperName en ACT_BatchConfig__mdt
            new PSTA_ResetearEstatusContacto_bch(),                // Batch original
            Integer.valueOf(System.Label.PSTA_Reinicio_Estatus_Registros)
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

### classes/PSTA_ResetearEstatusContacto_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ResetearEstatusContacto_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post venta
* Clase test    :   
* Description       :   Batch para el reseteo de estatus de contacto
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Gallegos Alan          Creación
* 2.0         15-Jul-2025       Gallegos Alan          Se agrega el reset de las banderas de contacto diario
*--------------------------------------------------------------------------
*******************************************************************************/

global class PSTA_ResetearEstatusContacto_bch implements Database.Batchable<sObject>{

    //Se obtiene la lista de cuentas por banker
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryStatusCuentas());
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        
        List<Account> lstClientes = (List<Account>) scope;

        //Se manda la lista de cuentas por resetear.
        Map<Id,Account> lstClientesToUpdate = PSTA_ResetearEstatusContacto_cls.resetEstatus(lstClientes);

        //Si se tienen cuentas para actualizar, se ejecuta el update.
        if (!lstClientesToUpdate.values().isEmpty()) {
            PSTA_ResetearEstatusContacto_cls.updateRecords(lstClientesToUpdate.values(), lstClientesToUpdate);
        } 
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch reinicio estatus finalizado');
        PSTA_AgrupacionPriorizacionDiaria_bch newBchAPD = new PSTA_AgrupacionPriorizacionDiaria_bch();
        Database.executeBatch(newBchAPD);
    }
}
```

### classes/PSTA_ResetearEstatusContacto_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ResetearEstatusContacto_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Gallegos Alan
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para el reseteo del estatus de contacto
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Gallegos Alan              Creación
* 2.0         15-Jul-2025       Gallegos Alan          Se agrega el reset de las banderas de contacto diario
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_ResetearEstatusContacto_cls {

    //Método para resetear el estatus a 'Pendiente'
    public static Map<Id,Account> resetEstatus(List<Account> lstCuentas) {

        Map<Id,Account> mapCuentasParaActualizar = new Map<Id, Account>();

        for(Account cuenta : lstCuentas) {
            if(cuenta.FechaSiguienteContacto__c != null && cuenta.EstatusContacto__c != 'Pendiente'){

                Boolean resetStatus =  System.today() >= cuenta.FechaSiguienteContacto__c  ?  true : false; 

                if(resetStatus) {

                    Account cuentaActualizada = mapCuentasParaActualizar.get(cuenta.Id);

                    if(cuentaActualizada == null) {
                        cuentaActualizada = new Account(Id = cuenta.Id);
                        mapCuentasParaActualizar.put(cuenta.Id,cuentaActualizada);
                    }
                    cuentaActualizada.EstatusContacto__c = 'Pendiente';
                    cuentaActualizada.PriorizacionContacto__c = false;
                }
            }
        }

        return mapCuentasParaActualizar;

    }

    //Método para ejecutar el update de los registros de cuenta
    public static void updateRecords(List<SObject> lstRecords, Map<Id, Account> mapRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    mapErrors.put('Registro', mapRecords.get(saveResult.getId()).Name);
                    intCount++;
                }
                if(!mapErrors.isEmpty()){
                    saveLogError(mapErrors, 'Error durante Actualizacion de segmento de cuenta', 'ERROR_BATCH_SEGMENTACION_001', '');
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

### classes/PSTA_AgrupacionPriorizacionDiaria_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_AgrupacionPriorizacionDiaria_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_bch_tst
* Description       :   Clase para agrupar los clientes con asesores para la priorizacion diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_AgrupacionPriorizacionDiaria_bch implements Database.Batchable<sObject>, Database.Stateful{
    global Map<Id, Integer> mapAsesorPorNumCuentas;
    global Map<String, ConfiguracionActinver__c> mapConfigPorSegmento; 

    global PSTA_AgrupacionPriorizacionDiaria_bch() {
        this.mapAsesorPorNumCuentas = new Map<Id, Integer>();
        this.mapConfigPorSegmento   = PSTA_PriorizacionDiaria_cls.obtenerSegmentoPorConfig();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionDiaria());
    }

    global void execute(Database.BatchableContext BC, List<Account> lstClientes) {
        System.debug('mapAsesorPorNumCuentas en BATCH: ' + mapAsesorPorNumCuentas);
        Account[] lstClientesActualizar = new List<Account>();
        Map<String,Object> response  = PSTA_PriorizacionDiaria_cls.agrupacionBanqueroPorCuentas(lstClientes,this.mapConfigPorSegmento,this.mapAsesorPorNumCuentas);
        lstClientesActualizar = (List<Account>)response.get('lstCuentasParaActualizar');
        this.mapAsesorPorNumCuentas = ( Map<Id, Integer> )response.get('mapAsesorPorNumCuentas');

        System.debug('lstClientesActualizar: ' + lstClientesActualizar.size());
        if(!lstClientesActualizar.isEmpty()) PSTA_PriorizacionDiaria_cls.updateRecords(lstClientesActualizar);
    }

    global void finish(Database.BatchableContext BC) {
       System.debug('finalizó ejecución batch PSTA_AgrupacionPriorizacionDiaria_bch');
       System.debug('mapAsesorPorNumCuentas: ' + mapAsesorPorNumCuentas);
    }
}
```

### classes/PSTA_PriorizacionDiaria_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_PriorizacionDiaria_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionDiaria_bch_tst
* Description       :   Clase controlador para la priorizacion diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         14-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_PriorizacionDiaria_cls {
    
    public static Id defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();
    public static Date hoy = Date.today();

    public static Map<String,Object> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones, Map<Id, Integer> mapAsesorPorNumCuentas) {
        Map<Id,List<Account>> mapCuentasPorAsesor = new Map<Id,List<Account>>();
        List<Account> lstCuentasParaActualizar = new List<Account>();
        System.debug('mapAsesorPorNumCuentas en FUNCION: ' + mapAsesorPorNumCuentas);
        Map<String,Object> response = new Map<String,Object>();
        for(Account cuenta : lstCuentas) {
            if(!mapConfiguraciones.containsKey(cuenta.Segmento__c)) continue;
            ConfiguracionActinver__c config = mapConfiguraciones.get(cuenta.Segmento__c);
            Integer limiteClientes          = (Integer) config.ClientesContactarPorDia__c;
            if( cuenta.BanqueroAsignado__r != null && 
                cuenta.BanqueroAsignado__r.BusinessUnitMember != null &&
                cuenta.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {

                Banker asesor               = (Banker)cuenta.BanqueroAsignado__r.BusinessUnitMember;
                System.debug('asesor: ' + asesor);
                Integer intNumCuentasAsesor = mapAsesorPorNumCuentas.containsKey(asesor.Id) ? mapAsesorPorNumCuentas.get(asesor.Id) : 0;
				System.debug('Cuenta: ' + cuenta);
                if(intNumCuentasAsesor < limiteClientes){
                    cuenta.PriorizacionContacto__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Integer.valueOf(config.FrecuenciaContacto__c), hoy);
                    System.debug('PriorizacionContacto__c ' + cuenta.PriorizacionContacto__c);

                    if(cuenta.PriorizacionContacto__c){
                        lstCuentasParaActualizar.add(cuenta);
                        mapAsesorPorNumCuentas.put(asesor.Id, intNumCuentasAsesor + 1);
                    } 
                }  
            }
        }
        response.put('lstCuentasParaActualizar',lstCuentasParaActualizar);
        response.put('mapAsesorPorNumCuentas',mapAsesorPorNumCuentas);
        return response;
    }

    public static Boolean debePriorizarContacto(Date FechaInicio, Integer intFrecuencia, Date hoy) {
        
        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(FechaInicio, hoy, defaultBusinessHoursId);
        System.debug('lngDiasEntreFechas: ' + lngDiasEntreFechas);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= 0;        
        return cumpleFrecuencia;
    }

    public static Map<String,ConfiguracionActinver__c> obtenerSegmentoPorConfig() {
        Map<String, ConfiguracionActinver__c> mapConfiguraciones = new Map<String, ConfiguracionActinver__c>();
        List<ConfiguracionActinver__c> lstConfiguraciones = PSTA_PriorizacionSelector_cls.getConfiguracionContacto();

        for (ConfiguracionActinver__c configuracion : lstConfiguraciones) {
            if (String.isNotBlank(configuracion.Segmento__c)) {
                mapConfiguraciones.put(configuracion.Segmento__c.trim(), configuracion);
            }
        }

        return mapConfiguraciones;
    }

    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Error' + intCount, error.getMessage());
                    intCount++;
                }
            }
        }
        if(!mapErrors.isEmpty()){
            saveLogError(mapErrors, 'Error durante Actualizacion de priorizacion mensual de cuenta', 'ERROR_BATCH_PRIORIZACION_MENSUAL_001', '');
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

### classes/PSTA_PriorizacionSelector_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_PriorizacionSelector_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionSelecto_cls_tst
* Description       :   Clase de consultas para la priorizacion mensual y diaria.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         14-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_PriorizacionSelector_cls {
    
    public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();

    public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
        
        String baseQuery = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Mensual'].Consulta__c ;
        
        // Reemplazar el placeholder {0} con las condiciones dinámicas
        return String.format(baseQuery, new List<String>{strConditionsBySegment});
            
        
    }

    /* public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'FechaSiguienteContacto__c, ' +
                  'FechaSiguienteVisita__c, ' +
                  'BanqueroAsignado__c, ' +
                  'SaldoIntegral__c, ' +
                  'ContactoPriorizadoEsteMes__c, ' +
                  'PriorizacionVisita__c, ' +
                  'Segmento__c, ' +
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
                  'END ' +
                  'FROM Account ' +
                  'WHERE Segmento__c != null AND SaldoIntegral__c != null AND FechaSiguienteContacto__c != null AND ContactoPriorizadoEsteMes__c = false AND FechaSiguienteVisita__c != null AND Person_Type__c = \'FISICA\' ' + 
            	  strConditionsBySegment + ' AND ((FechaSiguienteContacto__c <= THIS_MONTH ) OR (FechaSiguienteVisita__c  <= THIS_MONTH ))';
    } */

    public static String getQueryCuentasPriorizacionDiaria() {
        // Obtener la consulta base de la Custom Label
        String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'].Consulta__c ;
        return consulta;
    }

    /* public static String getQueryCuentasPriorizacionDiaria() {
        return 'SELECT Id, ' +
                  'FechaUltimoContacto__c, ' +
                  'BanqueroAsignado__c, ' +
                  'SaldoIntegral__c, ' +
                  'FechaSiguienteContacto__c, ' +
                  'FechaSiguienteVisita__c, ' +
                  'ContactoPriorizadoEsteMes__c, ' +
                  'PriorizacionContacto__c, ' +
                  'PriorizacionVisita__c, ' +
                  'Segmento__c, ' +
                  'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
                  'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
                  'END ' +
                  'FROM Account ' +
                  'WHERE ContactoPriorizadoEsteMes__c = true AND PriorizacionContacto__c = false AND EstatusContacto__c = \'Pendiente\' AND FechaSiguienteContacto__c != null AND Segmento__c != null AND SaldoIntegral__c != null AND Person_Type__c = \'FISICA\' ORDER BY SaldoIntegral__c DESC';
    } */

    public static List<ConfiguracionActinver__c> getConfiguracionContacto() {
        return [
            SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c 
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
        ];
    }

    public static Id getDiasLaborales(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
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

### triggers/AccountTrigger.trigger
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\triggers\AccountTrigger.trigger
```text
/**
 *   ------------------------------------------------------------------------------------------------
 *  Name     AccountTrigger
 *  Author   Tate Shi
 *  Date     Created: 12/09/2021
 *  Group    PWC
 *   ------------------------------------------------------------------------------------------------
 *  Description Account trigger.
 *   ------------------------------------------------------------------------------------------------
 *  Changes
 *  12/09/2021 Tate Shi
 *             Class creation.
 *  03/10/2022 luis.felipe.ortiz@pwc.com
 *             Addition of ON/OFF behavior based on metadata.
 *  13/11/2024 andres.hernandez@vasscompany.com
 *             Realiza mejora framework en Trigger Contract agregando nueva Metadata
 *  23/06/2025 isaac.alonzo@vasscompany.com
 *             Se agrega la actualizacion de la fecha de siguiente contacto y visita para POSTVENTA      
 *  14/01/2026 Se agrega actualizacion de RecordType usando Metadata para evitar Código duro (Gerardo Bautista)
 *   ------------------------------------------------------------------------------------------------
 **/
trigger AccountTrigger on Account(before insert, before update, After insert, After update) {
    
    /*F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_AccountTrigger);
    if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
        new AccountTrigger_Handler().run();
    }*/
    //Llamado de metadata para validar si esta activo el trigger que se va ejecutar
    Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.AccountTrigger);
    if (triggerIsActive != null && triggerIsActive.IsActive__c) {
        if (Trigger.isUpdate && Trigger.isBefore) {
            OD_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
            PSTA_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
            // Nuevo llamado para extraer el recordType
            AccountRecordTypeAssigner.apply(Trigger.new, Trigger.oldMap);
            
        }
        if (Trigger.isInsert && Trigger.isBefore) {
            OD_Account_thr.onBeforeInsert(Trigger.new);
            // Nuevo llamado para extraer el recordType
            AccountRecordTypeAssigner.apply(Trigger.new, null);
        }        
    }
}
```

### classes/PSTA_Account_thr.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_Account_thr.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para el control de acciones sobre el trigger de cuentas para procesos de POSTVENTA
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         12-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public  class PSTA_Account_thr {
   public static void onBeforeUpdate(List<Account> newListAccount, Map<Id,Account> oldMapAccount){
        system.debug('*********************START BEFORE UPDATE ACCOUNT PSTA*********************');
        PSTA_ListadoClientes_cls.actualizarFechaSiguienteContacto(newListAccount,oldMapAccount);
        PSTA_ListadoClientes_cls.actualizarFechaSiguienteVisita(newListAccount,oldMapAccount);
        PSTA_ListadoClientes_cls.actualizarFechaNoQuiereSerContactado(newListAccount,oldMapAccount);
        PSTA_Segmentacion_cls.procesarSegmentoPorCambioAsesor(newListAccount, oldMapAccount);
        system.debug('*********************END BEFORE UPDATE ACCOUNT PSTA*********************');
    }
}
```

### classes/PSTA_ListadoClientes_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ListadoClientes_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase que ejecuta
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         12-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_ListadoClientes_cls {

    public static Boolean bypassTriggerExecution = false;


    public static final String ESTATUS_PENDIENTE                    = 'Pendiente';
    public static final String ESTATUS_CONTACTO_NO_EXITOSO          = 'Contacto no exitoso';
    public static final String ESTATUS_NO_QUIERE_SER_CONTACTADO     = 'Cliente no quiere ser contactado';
    public static final String ESTATUS_CONTACTO_EFECTIVO_EXITOSO    = 'Contacto efectivo exitoso';


    private static Id businessHoursId = PSTA_ListaClientesSelector_cls.getDiasLaborales();

    public static void actualizarFechaSiguienteContacto(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }
        
        Map<String, Integer> mapSegmentoByFrecuenciaContacto = getMapSegmentoByFrecuenciaContacto();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);

            if(cuentaNueva.FechaUltimoContacto__c != null  && cuentaVieja.FechaUltimoContacto__c != cuentaNueva.FechaUltimoContacto__c)  {
                
                Integer frecuencia = mapSegmentoByFrecuenciaContacto.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
                    cuentaNueva.FechaUltimoContacto__c,
                    frecuencia,
                    businessHoursId
                 );
                
                
            }
        }
        
    }

    public static void actualizarFechaSiguienteVisita(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }

        Map<String, Integer> mapSegmentoByFrecuenciaVisita = getMapSegmentoByFrecuenciaVisita();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);

            if(cuentaVieja.FechaUltimaVisita__c != cuentaNueva.FechaUltimaVisita__c) {
                
                Integer frecuencia = mapSegmentoByFrecuenciaVisita.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteVisita__c = PSTA_UtilityClass.agregarDiasLaborales(
                    cuentaNueva.FechaUltimaVisita__c,
                    frecuencia,
                    businessHoursId
                 );
                
            }
        }
    }

    public static void actualizarFechaNoQuiereSerContactado(List<Account> lstClientes, Map<Id, Account> oldMap) {

        if(bypassTriggerExecution == true) {
            return;
        }
        
        Map<String, Integer> mapSegmentoByFrecuenciaNoContacto = getMapSegmentoByFrecuenciaNoContacto();
        
        for(Account cuentaNueva : lstClientes) {
            Account cuentaVieja = oldMap.get(cuentaNueva.Id);
            
            
            if(cuentaVieja.EstatusContacto__c != cuentaNueva.EstatusContacto__c && cuentaNueva.EstatusContacto__c == ESTATUS_NO_QUIERE_SER_CONTACTADO && cuentaVieja.FechaNoRequiereSerContacto__c != cuentaNueva.FechaNoRequiereSerContacto__c) {
                
                Integer frecuencia = mapSegmentoByFrecuenciaNoContacto.get(cuentaNueva.Segmento__c);
                cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
                    System.today(),
                    frecuencia,
                    businessHoursId
                );
                
                cuentaNueva.FechaUltimoContacto__c = System.today();
                
            }
        }
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaContacto() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecuenciaContacto__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaVisita() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecuenciaVisita__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }

    public static Map<String,Integer> getMapSegmentoByFrecuenciaNoContacto() {
        List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
        Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
        for(ConfiguracionActinver__c config : lstConfigPostventa) {
            mapMapSegmentoByFrecuencia.put(
                config.Segmento__c, 
                Integer.valueOf(config.FrecReinicioNoReqContacto__c)
            );
        }

        return mapMapSegmentoByFrecuencia;
    }
}
```

### classes/PSTA_ListaClientesSelector_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_ListaClientesSelector_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase SOQL para la segmentacion de clientes
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_ListaClientesSelector_cls {

    public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();

    public static Id getDiasLaborales(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
    }

    public static List<ConfiguracionActinver__c> getConfiguracionPostVenta() {
        return [
            SELECT Segmento__c, FrecReinicioNoReqContacto__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
            FROM ConfiguracionActinver__c
            WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
        ];
    }


}
```

### classes/OD_Account_thr.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\OD_Account_thr.cls
```text
/**
* @File Name : OD_Account_thr.cls
* @Description :Clase Handler del Trigger AccountTrigger.apxt
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Account_thr {
    public static void onBeforeInsert(List<Account> newListAccount){
        system.debug('*********************BEFORE INSERT ACCOUNT*********************');
        OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,null);
        OD_Account_cls.createAccounts(newListAccount);
        OD_Account_cls.checkTotalPercent(newListAccount);
        OD_Account_cls.convertMappingLeadToAccount(newListAccount);
    }
    public static void onBeforeUpdate(List<Account> newListAccount,Map<Id,Account> oldMapAccount){
        system.debug('*********************BEFORE UPDATE ACCOUNT*********************');
        OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,oldMapAccount);
        OD_Account_cls.checkTotalPercent(newListAccount);
    }
}
```

### classes/OD_Account_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\OD_Account_cls.cls
```text
/**
* @File Name : OD_Account_cls.cls
* @Description :Clase service para el trigger de Account OD_Account_thr.apxc
* @Author : Andrés Hernandez Rios
* @Last Modified By :
* @Last Modified On : November 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
**/
public without sharing class OD_Account_cls {
    public static Boolean bypassTriggerExecution = false;
  
    // MÉTODO QUE PROCESA UNA LISTA DE CUENTAS (ACCOUNT) PARA CAMBIAR EL PROPIETARIO (OWNERID) Y LLENAR EL CAMPO BANQUERO.
    public static void processToChangeOwnerFromAccount(List<Account> newListAccount,Map<Id,Account> oldMapAccount) {
        // MAPAS PARA ALMACENAR DATOS RELACIONADOS CON USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER DE LOS BANQUEROS.
        Map<String,BranchUnitBusinessMember> bankersBranchUnitMap = new Map<String,BranchUnitBusinessMember> ();
        Map<String,BranchUnitBusinessMember> bankersBranchUnitOwnerMap = new Map<String,BranchUnitBusinessMember> ();
        Map<String,User> usersByNominaMap = new Map<String,User>();
        Map<String,Contact> contactsByNominaMap = new Map<String,Contact>();
        Map<Id,User> usersByIdMap = new Map<Id,User>();
        
        // CONJUNTOS PARA ALMACENAR LOS ID ÚNICOS DE ASESORES Y PROPIETARIOS.
        Set<String> uniqueAdvisorIds = new Set<String>();
        Set<Id> uniqueOwnerIds = new Set<Id>();
        
        
        // SI EL FLAG BYSPASS ESTÁ ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN LOS CONTRATOS.
        if (bypassTriggerExecution) {
            system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN CUENTAS');
            return;
        }
        
        // ITERAMOS SOBRE CADA CUENTA EN LA LISTA PROPORCIONADA
        for(Account acc : newListAccount){
            // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
            system.debug(Service_Utility_Trigger.isCorrectRecordTypeId(acc));
            if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){
                system.debug(acc.ID_ASESOR__c);
                // AGREGAMOS AL CONJUNTO DE ASESORES ÚNICOS SI TIENE EL ID_ASESOR
                if(String.isNotBlank(acc.ID_ASESOR__c)){
                    uniqueAdvisorIds.add(acc.ID_ASESOR__c);
                } 
                // AGREGAMOS AL CONJUNTO DE PROPIETARIOS ÚNICOS SI TIENE EL OWNERID
                if(String.isNotBlank(acc.OwnerId)){
                    uniqueOwnerIds.add(acc.OwnerId);
                }
            }                
        }
        
        // SI HAY PROPIETARIOS ÚNICOS, OBTENEMOS LOS USUARIOS CORRESPONDIENTES.
        if(!uniqueOwnerIds.isEmpty()){
            usersByIdMap = Service_Utility_Trigger.getUsersByOwnerIds(uniqueOwnerIds);
            bankersBranchUnitOwnerMap = Service_Utility_Trigger.getBranchUnitByOwnerId(uniqueOwnerIds);
        }
        
        // SI HAY ASESORES ÚNICOS, OBTENEMOS LOS USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER.
        if(!uniqueAdvisorIds.isEmpty()){
            usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
            contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
            bankersBranchUnitMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode(uniqueAdvisorIds);
        }
        system.debug('bankersBranchUnitOwnerMap'+bankersBranchUnitOwnerMap);
        system.debug('bankersBranchUnitMap:'+bankersBranchUnitMap);
        // PROCESAMOS CADA CUENTA NUEVAMENTE PARA CAMBIAR EL PROPIETARIO Y REALIZAR VALIDACIONES.
        for(Account acc : newListAccount){
            
            // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
            if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){
                // SI ENCONTRAMOS EL USUARIO CON EL ID_ASESOR, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
                if(usersByNominaMap.containsKey(acc.ID_ASESOR__c)){

                    if(oldMapAccount != null && oldMapAccount.containsKey(acc.Id) && oldMapAccount.get(acc.Id).OwnerId != acc.OwnerId){
                        system.debug('*************ENCUENTRA EL USUARIO PERO HAY CAMBIO PROPIETARIO*************');
                        acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id; 
                        if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
                            acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
                        }else{
                            acc.addError('Hay un error en Banker ó no hay relación en el cambio de Propietario, favor de verificar');
                        }
                    }else{
                        system.debug('*************ENCUENTRA EL USUARIO CON EL ID_ASESOR*************'+usersByNominaMap.get(acc.ID_ASESOR__c).Name);
                        acc.OwnerId = usersByNominaMap.get(acc.ID_ASESOR__c).Id;  
                        if(bankersBranchUnitMap.containskey(acc.ID_Asesor__c)){
                            acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;              
                        }else{
                            acc.addError('Hay un error en Banker ó no hay relación en la actualización de Id Asesor, favor de verificar');
                        }
                    }
                }   
                
                // SI ENCONTRAMOS EL CONTACTO CON EL ID_ASESOR PERO NO EL USUARIO, VERIFICAMOS SI HAY UNA UNIDAD DE SUCURSAL.
                else if(contactsByNominaMap.containsKey(acc.ID_ASESOR__c)){
                    system.debug('*************ENCUENTRE EL CONTACTO SIN LICENCIA CON EL ID_ASESOR*************');                
                    // SI HAY UNA UNIDAD DE SUCURSAL RELACIONADA CON EL ASESOR, ACTUALIZAMOS LA CUENTA.
                    if(bankersBranchUnitMap.containsKey(acc.ID_ASESOR__c)){
                        acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;
                        acc.OwnerId = usersByNominaMap.get(Service_Utility_Trigger.DEFAULT_USER_NAME).Id;                    
                    } else {
                        // SI NO SE ENCUENTRA LA UNIDAD DE SUCURSAL, AGREGAMOS UN ERROR.
                        acc.addError('Hay un error en Banker ó no hay relación Id Asesor, favor de verificar (Contacto Temporal)');
                    }
                }
                
                // SI ENCONTRAMOS EL USUARIO CON EL OWNERID ORIGINAL, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
                else if(usersByIdMap.containsKey(acc.OwnerId)){
                    system.debug('*************ENCUENTRA EL USUARIO CON EL OWNERID*************');
                    acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id;
                    if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
                        acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
                    }else{
                        acc.addError('Hay un error en Banker ó no hay relación Propietario, favor de verificar');
                    }             
                }
                
                // SI NO SE ENCUENTRA NI EL USUARIO NI EL CONTACTO RELACIONADO, AGREGAMOS UN ERROR.
                else {
                    acc.adderror('No se encontró el usuario ni el contacto de alguna cuenta');                
                }
            }            
        }  
         bypassTriggerExecution = true;
    }
    /**
	 * Check if the total percentage is above 100%
	 */
	public static void checkTotalPercent(List<Account> newListAccount) {
		Decimal decActinverMexico = 0;
		Decimal decActinverMadrid = 0;
		Decimal decActinverSecurities = 0;
		Decimal decInstitucionesNacionales = 0;
		Decimal decInstitucionesInternaciononales = 0;

		for (Account accObj : newListAccount) {
			// if all the fields are null, skip the check
			if (
				accObj.Actinver_Mexico__c == null &&
				accObj.Actinver_Madrid__c == null &&
				accObj.Actinver_Securities__c == null &&
				accObj.Instituciones_Nacionales__c == null &&
				accObj.Instituciones_Internaciononales__c == null
			) {
				continue;
			}

			// Only persona accout need this check
			if (accObj.IsPersonAccount) {
				decActinverMexico = (accObj.Actinver_Mexico__c == null) ? 0 : accObj.Actinver_Mexico__c;
				decActinverMadrid = (accObj.Actinver_Madrid__c == null) ? 0 : accObj.Actinver_Madrid__c;
				decActinverSecurities = (accObj.Actinver_Securities__c == null) ? 0 : accObj.Actinver_Securities__c;
				decInstitucionesNacionales = (accObj.Instituciones_Nacionales__c == null) ? 0 : accObj.Instituciones_Nacionales__c;
				decInstitucionesInternaciononales = (accObj.Instituciones_Internaciononales__c == null)
					? 0
					: accObj.Instituciones_Internaciononales__c;

				if (
					(decActinverMexico +
					decActinverMadrid +
					decActinverSecurities +
					decInstitucionesNacionales +
					decInstitucionesInternaciononales) != 100
				) {
					accObj.addError(Label.CheckTotalPercent);
				}
			}
		}
	}
    public static void createAccounts(List<Account> newListAccount) {
        for (Account a : newListAccount) {
            if (a.Person_Type__c == 'MORAL') {
                a.Name = a.BusinessName__c;
                a.PersonBirthdate = null;
                System.debug(JSON.serializePretty(a));
            }
            if (a.Person_Type__c == 'FISICA') {
                if (a.Nombre_Completo_Actinver__c != null) {
                    a.FirstName = a.Nombre_Completo_Actinver__c.length() >= 40
                        ? a.Nombre_Completo_Actinver__c.substring(0, 39)
                        : a.Nombre_Completo_Actinver__c;
                }
            }
        }
    }
    public static void convertMappingLeadToAccount(List<Account> newListAccount) {
        system.debug('############### convertMappingLeadToAccount ###################');
        Map<String,Lead> mapAccountIdByLeads = new Map<String,Lead>();
        Set<String> setAccountIds = new Set<String>();
        Lead[] lstLead = new List<Lead>();
        for(Account objAccount : newListAccount)  setAccountIds.add(objAccount.ExternalIdLead__c);

        system.debug('#### setAccountIds: '+setAccountIds);
        setAccountIds.remove(null);
        if(!setAccountIds.isEmpty()) lstLead = getLeadByExternalId(setAccountIds);

        if(!lstLead.isEmpty()){
            for(Lead objLead :lstLead) mapAccountIdByLeads.put(objLead.F3_Consecutivo_ID__c,objLead);
            for(Account objAccount : newListAccount) setValuesOfConvertLead(mapAccountIdByLeads, objAccount);
        } 
    }
    public static Lead[] getLeadByExternalId(Set<String> setAccountIds) {
        Lead[] lstLead = [SELECT Id
                    , toLabel(F3_Estado_Civil__c)   //objAccount.MaritalStatus__c
                    , toLabel(Estado_Nacimiento__c) //objAccount.Birth_City__c
                    , toLabel(Gender__c)            //objAccount.Gender__c
                    , toLabel(F3_Nacionalidad__c)   //objAccount.Nationality__c
                    , toLabel(Pais_Nacimiento__c)   //objAccount.Country_Birth__c
                    , toLabel(Tipo_de_Persona__c)   //objAccount.Person_Type__c
                    , F3_Consecutivo_ID__c
                    , Fecha_Nacimiento_Prospecto__c 
                FROM Lead 
                WHERE F3_Consecutivo_ID__c IN :setAccountIds];

        system.debug('#### lstLead: '+lstLead.size());
        return lstLead;
    }
    public static void setValuesOfConvertLead(Map<String,Lead> mapAccountIdByLeads,Account objAccount) {
            Lead objLead = mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) != null ? mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) : new Lead();
            objAccount.MaritalStatus__c = objLead.F3_Estado_Civil__c;
            objAccount.Birth_City__c    = objLead.Estado_Nacimiento__c;
            objAccount.Nationality__c   = objLead.F3_Nacionalidad__c;
            objAccount.Country_Birth__c = objLead.Pais_Nacimiento__c;
            objAccount.Person_Type__c   = objLead.Tipo_de_Persona__c;
            if(objAccount.IsPersonAccount) objAccount.PersonBirthdate = objLead.Fecha_Nacimiento_Prospecto__c;
    }
}
```

### classes/AccountRecordTypeAssigner.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\AccountRecordTypeAssigner.cls
```text
public class AccountRecordTypeAssigner {

    public static void apply(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        // 1) OwnerIds
        Set<Id> ownerIds = new Set<Id>();
        for (Account a : newList) {
            if (a.OwnerId != null) ownerIds.add(a.OwnerId);
        }
        if (ownerIds.isEmpty()) return;

        // 2) Users -> ID_ASESOR__c
        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, ID_ASESOR__c
            FROM User
            WHERE Id IN :ownerIds
        ]);

        // 3) Nominas
        Set<String> nominas = new Set<String>();
        for (User u : usersById.values()) {
            if (String.isNotBlank(u.ID_ASESOR__c)) nominas.add(u.ID_ASESOR__c.trim());
        }

        // 4) Bankers por ExternalId__c (nomina)
        Map<String, Banker> bankerByNomina = new Map<String, Banker>();
        if (!nominas.isEmpty()) {
            for (Banker b : [
                SELECT ExternalId__c, Division__c
                FROM Banker
                WHERE ExternalId__c IN :nominas
            ]) {
                bankerByNomina.put(b.ExternalId__c, b);
            }
        }

        // 5) Caches CMDT
        Map<String, String> divisionToDev = getDivisionToRtDevName();
        Map<String, String> defaults = getDefaults();
        Map<String, Id> rtIds = getAccountRtIds();

        for (Account a : newList) {
            Account oldA = (oldMap == null ? null : oldMap.get(a.Id));

        Boolean shouldRecalc =
        oldMap == null ||                // insert
        a.RecordTypeId == null ||        // sin RT
        (oldA != null && a.OwnerId != oldA.OwnerId) ||                // cambió owner
        (oldA != null && a.ID_ASESOR__c != oldA.ID_ASESOR__c);        // ✅ cambió asesor

            if (!shouldRecalc) continue;

            User u = usersById.get(a.OwnerId);
            String nomina = (u != null) ? u.ID_ASESOR__c : null;

            String targetDevName;

            // División
            if (String.isNotBlank(nomina)) {
                Banker b = bankerByNomina.get(nomina.trim());
                if (b != null && String.isNotBlank(b.Division__c)) {
                    targetDevName = divisionToDev.get(b.Division__c.trim());
                }
            }

            // Fallback
            if (String.isBlank(targetDevName)) {
                String key = a.IsPersonAccount ? 'DEFAULT_PERSON' : 'DEFAULT_BUSINESS';
                targetDevName = defaults.get(key);
            }

            Id rtId = rtIds.get(targetDevName);
            if (rtId != null) {
                a.RecordTypeId = rtId;
            }
        }
    }

    private static Map<String, String> getDivisionToRtDevName() {
        Map<String, String> m = new Map<String, String>();
        for (AdvisorDivision_RecordType__mdt r : [
            SELECT Division__c, RecordTypeDeveloperName__c
            FROM AdvisorDivision_RecordType__mdt
        ]) {
            if (String.isNotBlank(r.Division__c)) {
                m.put(r.Division__c.trim(), r.RecordTypeDeveloperName__c);
            }
        }
        return m;
    }

    private static Map<String, String> getDefaults() {
        Map<String, String> m = new Map<String, String>();
        for (Account_RecordType_Config__mdt r : [
            SELECT Key__c, RecordTypeDeveloperName__c
            FROM Account_RecordType_Config__mdt
        ]) {
            m.put(r.Key__c, r.RecordTypeDeveloperName__c);
        }
        return m;
    }

    private static Map<String, Id> getAccountRtIds() {
        Map<String, Id> m = new Map<String, Id>();
        for (Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfos()) {
            if (rti.isAvailable()) {
                m.put(rti.getDeveloperName(), rti.getRecordTypeId());
            }
        }
        return m;
    }
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
