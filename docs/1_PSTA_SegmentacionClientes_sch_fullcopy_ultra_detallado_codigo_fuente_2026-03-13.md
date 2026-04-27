# PSTA_SegmentacionClientes_sch - Analisis ultra detallado
Ambiente: fullcopy | Fecha de elaboracion: 2026-03-13

## 1. Alcance y ejecucion en fullcopy
Este documento describe el flujo completo de `PSTA_SegmentacionClientes_sch` en fullcopy con el mayor nivel de detalle funcional y tecnico. El objetivo es explicar que hace cada clase, batch y metodo relevante, como consulta metadata/configuracion, que objetos toca, que campos modifica y que efectos indirectos produce por trigger.

En fullcopy este scheduler sigue ejecutando el batch directamente con `Database.executeBatch`; no usa `ACT_BusinessHoursHelper_cls`. Por lo tanto, el criterio de ejecucion depende solo del cron del Scheduled Job y no de una validacion previa de dia habil.

- Schedule Job: `PSTA_SegmentacionClientes`
- CronExpression: `0 0 0 1 */1 ?`
- TimesTriggered: `2`
- NextFireTime UTC: `2026-04-01T06:00:00.000+0000`
- State: `WAITING`
- Label usado: `PSTA_Segmentacion_Registros_Batch = 200`

## 2. Resumen ejecutivo del flujo
1. `PSTA_SegmentacionClientes_sch` ejecuta `PSTA_SegmentacionClientes_bch` con el tamano de lote tomado del Custom Label `PSTA_Segmentacion_Registros_Batch`.
2. `PSTA_SegmentacionClientes_bch.start()` obtiene la query base desde `PSTA_Consultas__mdt` usando `DeveloperName = PSTA_Query_Segmentacion`.
3. `execute()` toma el scope, vuelve a consultar `Account` con subquery de `Contract` y delega el calculo a `PSTA_SegmentacionClientes_cls`.
4. `PSTA_SegmentacionClientes_cls` usa `PSTA_FechaPrimerContacto_cls` y `PSTA_Segmentacion_cls` para calcular segmento, saldo integral, antiguedad y fechas base de contacto/visita.
5. La actualizacion se hace con `Database.update(records, false)`, por lo que el proceso admite errores parciales.
6. Cada `update Account` dispara `AccountTrigger` en `before update`, agregando impactos indirectos sobre fechas siguientes, record type, owner, banquero y otros campos derivados.
7. `finish()` encadena `PSTA_AgrupacionPriorizacionMensual_bch`, que reconstruye `ContactoPriorizadoEsteMes__c` y `PriorizacionVisita__c`.

## 3. Diagrama del flujo completo
```text
PSTA_SegmentacionClientes_sch.execute(ctx)
  -> lee Label.PSTA_Segmentacion_Registros_Batch
  -> Database.executeBatch(new PSTA_SegmentacionClientes_bch(), batchSize)

PSTA_SegmentacionClientes_bch.start(bc)
  -> PSTA_SegmentacionClientesSelector_cls.getQueryString()
  -> SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'
  -> Database.getQueryLocator(query)

PSTA_SegmentacionClientes_bch.execute(bc, scope)
  -> recolecta Ids del scope
  -> PSTA_SegmentacionClientesSelector_cls.getContractAccounts(ids)
  -> consulta Account + subquery Contracts
  -> PSTA_SegmentacionClientes_cls.segmentacionClientes(accounts)
      -> PSTA_FechaPrimerContacto_cls.agregaDatosSegmentacion(...)
         -> PSTA_Segmentacion_cls.getSegmentByBanker(...)
         -> PSTA_SegmentacionClientesSelector_cls.getConfigContracts()
         -> usa ConfiguracionActinver__c para tipos/estatus de contrato
         -> calcula Segmento__c, SaldoIntegral__c, FechaAntiguedad__c
         -> si faltan fechas de ultimo contacto/visita, usa contrato valido mas antiguo
         -> resetea ContactoPriorizadoEsteMes__c y PriorizacionVisita__c a false
      -> updateRecords(accounts)
         -> Database.update(accounts, false)
         -> EventLogger.error(...) si hay errores
         -> dispara AccountTrigger

AccountTrigger (before update)
  -> OD_Account_thr
  -> PSTA_Account_thr
      -> PSTA_ListadoClientes_cls.actualizarFechasSiguienteContacto(...)
      -> PSTA_Segmentacion_cls.getSegmentByBanker(...)
  -> AccountRecordTypeAssigner

PSTA_SegmentacionClientes_bch.finish(bc)
  -> Database.executeBatch(new PSTA_AgrupacionPriorizacionMensual_bch(), batchSize)

PSTA_AgrupacionPriorizacionMensual_bch.start/execute
  -> PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual(...)
  -> lee PSTA_Query_Priorizacion_Mensual y ConfiguracionActinver__c ContactoPostventa
  -> PSTA_PriorizacionMensual_cls.agruparPriorizacionMensual(...)
  -> update Account con ContactoPriorizadoEsteMes__c y PriorizacionVisita__c
  -> AccountTrigger vuelve a ejecutarse
```

## 4. Detalle por clase y metodo
### 4.1 PSTA_SegmentacionClientes_sch
1. Implementa `Schedulable`.
2. `execute(SchedulableContext sc)` toma `System.Label.PSTA_Segmentacion_Registros_Batch`.
3. Convierte el valor a `Integer`.
4. Ejecuta `Database.executeBatch(new PSTA_SegmentacionClientes_bch(), batchSize)`.
5. No consulta `ACT_BatchConfig__mdt` ni `BusinessHours`.
6. No hace DML directo sobre objetos funcionales.

### 4.2 PSTA_SegmentacionClientes_bch
1. Implementa `Database.Batchable<SObject>`.
2. `start()` llama `PSTA_SegmentacionClientesSelector_cls.getQueryString()`.
3. Ese selector consulta `PSTA_Consultas__mdt` y regresa la `Consulta__c` del registro `PSTA_Query_Segmentacion`.
4. `execute()` castea el scope a `List<Account>`, toma sus Ids y consulta las cuentas detalladas con sus contratos.
5. El recalculo funcional no se hace aqui; se delega a `PSTA_SegmentacionClientes_cls.segmentacionClientes()`.
6. `finish()` encadena `PSTA_AgrupacionPriorizacionMensual_bch` usando el mismo label de tamano de lote.

### 4.3 PSTA_SegmentacionClientesSelector_cls
1. Centraliza las lecturas del flujo.
2. `getQueryString()` consulta `PSTA_Consultas__mdt` y devuelve `Consulta__c` de `PSTA_Query_Segmentacion`.
3. `getContractAccounts(Set<Id>)` consulta `Account` con la subquery `Contracts` para las cuentas del scope.
4. `getConfigContracts()` consulta `ConfiguracionActinver__c` del record type `PSTA_ConfiguracionContratosPostventa`.
5. De esa configuracion obtiene `TipoContratos__c = 01;02;03;08` y `EstatusContrato__c = C05;CC05`.
6. La misma clase tambien expone metodos reutilizados por otros procesos, por ejemplo `getQueryStatusCuentas()` y `getQueryAllBBM()`.

### 4.4 PSTA_SegmentacionClientes_cls
1. `segmentacionClientes(List<Account>)` actua como orquestador.
2. No hace todos los calculos por si mismo; delega la transformacion a `PSTA_FechaPrimerContacto_cls`.
3. `updateRecords(List<Account>)` ejecuta `Database.update(records, false)`.
4. Recorre `SaveResult[]` para detectar errores parciales.
5. Si algun registro falla, llama `EventLogger.error(...)` y termina insertando `WebServiceTrackingLog__c`.
6. No hace `insert`, `upsert` ni `delete` sobre `Account` o `Contract`; solo `update Account`.

### 4.5 PSTA_FechaPrimerContacto_cls
1. Recorre cada `Account` con sus `Contracts` relacionados.
2. Filtra contratos validos usando la configuracion de `TipoContratos__c` y `EstatusContrato__c`.
3. Calcula `SaldoIntegral__c` a partir de los contratos validos.
4. Determina `FechaAntiguedad__c` usando el contrato valido mas antiguo.
5. Si `FechaUltimoContacto__c` o `FechaUltimaVisita__c` estan vacias, usa la fecha del contrato valido mas antiguo como baseline.
6. Invoca `PSTA_Segmentacion_cls` para resolver `Segmento__c`.
7. Resetea `ContactoPriorizadoEsteMes__c = false`.
8. Resetea `PriorizacionVisita__c = false`.
9. Devuelve la lista preparada para persistencia.
### 4.6 PSTA_Segmentacion_cls
1. Resuelve el segmento de negocio a partir del banker asignado.
2. Lee atributos de `Banker`, en especial `Division__c`, `Rol__c` y `ExternalId__c`.
3. Mapea la division a segmentos funcionales como `Privada`, `Patrimonial` y `Wealth Management`.
4. Aplica la excepcion de `Patrimonial reactivo` cuando la configuracion de `ConfiguracionActinver__c` indica `Rol__c = CONSULTOR/A FARMER DIGITAL`.
5. Esta clase tambien se reutiliza desde trigger para recalcular `Segmento__c` cuando cambia owner o banquero.

### 4.7 PSTA_AgrupacionPriorizacionMensual_bch
1. Es el batch encadenado al final del de segmentacion.
2. `start()` toma la query base `PSTA_Query_Priorizacion_Mensual` desde `PSTA_Consultas__mdt`.
3. Esa query contiene un placeholder `{0}`.
4. El batch arma dinamicamente las condiciones por segmento y reemplaza `{0}` con base en la configuracion `ContactoPostventa`.
5. `execute()` consulta las cuentas elegibles y delega el calculo a `PSTA_PriorizacionMensual_cls`.
6. Su objetivo es reconstruir las banderas mensuales despues del reseteo hecho por `PSTA_FechaPrimerContacto_cls`.

### 4.8 PSTA_PriorizacionMensual_cls
1. Lee `ConfiguracionActinver__c` del record type `ContactoPostventa`.
2. De ahi toma `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `ClientesContactarPorDia__c`, `Segmento__c` y `Rol__c`.
3. Consulta `BusinessHours` con `Name = Postventa` a traves del selector.
4. Calcula dias habiles entre fechas usando utilerias y `BusinessHours`.
5. Marca `ContactoPriorizadoEsteMes__c = true` cuando la cuenta debe entrar a la lista de contacto del mes.
6. Marca `PriorizacionVisita__c = true` cuando ya requiere visita por frecuencia.
7. Persiste con `Database.update(records, false)`.
8. Registra errores con `EventLogger.error(...)`.

### 4.9 PSTA_PriorizacionSelector_cls
1. `getQueryCuentasPriorizacionMensual(String strConditionsBySegment)` consulta `PSTA_Consultas__mdt` con `DeveloperName = PSTA_Query_Priorizacion_Mensual`.
2. Usa `String.format(baseQuery, new List<String>{strConditionsBySegment})` para insertar el filtro dinamico por segmento.
3. `getQueryCuentasPriorizacionDiaria()` tambien lee metadata, aunque corresponde al batch diario y no al mensual de este scheduler.
4. `getConfiguracionContacto()` consulta `ConfiguracionActinver__c` con record type `ContactoPostventa`.
5. `getDiasLaborales()` consulta `BusinessHours` donde `Name = Postventa`.

### 4.10 AccountTrigger y clases indirectas
1. Cada `update Account` del batch dispara `AccountTrigger` porque `Trigger_Management__mdt` indica `AccountTrigger = true`.
2. `OD_Account_thr` y `OD_Account_cls` ejecutan reglas generales de cuenta relacionadas con owner, banquero, mapeos y validaciones.
3. `PSTA_Account_thr` llama `PSTA_ListadoClientes_cls` para recalcular `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c` y reglas de reinicio de contacto.
4. `PSTA_Account_thr` tambien reutiliza `PSTA_Segmentacion_cls` para recalcular `Segmento__c` si hay cambios relevantes.
5. `AccountRecordTypeAssigner` puede reasignar `RecordTypeId` segun owner, division, metadata y configuracion del modelo operativo.
6. El impacto real sobre `Account` es mayor que el update directo visible desde el batch.

## 5. Como consulta metadata y como la utiliza
### 5.1 PSTA_Consultas__mdt
1. `PSTA_SegmentacionClientesSelector_cls.getQueryString()` consulta `PSTA_Consultas__mdt`.
2. Usa `DeveloperName = PSTA_Query_Segmentacion`.
3. El valor recuperado en fullcopy filtra `Account` por `BanqueroAsignado__c != null`, `Person_Type__c = 'FISICA'` e `ID_Asesor__c IN (...)`.
4. La query esta fuera del codigo, por lo que cambiar metadata cambia el universo procesado sin despliegue.

```sql
SELECT Consulta__c
FROM PSTA_Consultas__mdt
WHERE DeveloperName = 'PSTA_Query_Segmentacion'
```

### 5.2 ConfiguracionActinver__c para contratos
1. Se consulta el record type `PSTA_ConfiguracionContratosPostventa`.
2. `TipoContratos__c` define que tipos de contrato se consideran en saldo y antiguedad.
3. `EstatusContrato__c` define que estatus de contrato entran al calculo.
4. En fullcopy los valores recuperados son `01;02;03;08` y `C05;CC05`.

### 5.3 ConfiguracionActinver__c para contacto postventa
1. Se consulta el record type `ContactoPostventa`.
2. La metadata trae parametros por segmento: `FrecuenciaContacto__c`, `FrecuenciaVisita__c`, `FrecReinicioNoReqContacto__c`, `ClientesContactarPorDia__c`, `RangoMontoMinimo__c`, `RangoMontoMaximo__c` y `Rol__c`.
3. La clase de segmentacion usa `Rol__c` para detectar `Patrimonial reactivo`.
4. La clase de priorizacion mensual usa las frecuencias y volumen diario para definir que cuentas entran al mes y cuales requieren visita.

### 5.4 Custom Labels
1. `PSTA_Segmentacion_Registros_Batch = 200` define el tamano del batch principal.
2. El mismo tamano se reutiliza para el batch mensual encadenado.
3. El tamano no esta hardcodeado; se toma en runtime.

## 6. Matriz exacta clase -> objeto -> operacion -> campos
- `PSTA_SegmentacionClientes_sch` -> Ninguno -> Sin DML -> lee `PSTA_Segmentacion_Registros_Batch`.
- `PSTA_SegmentacionClientes_bch` -> `Account` -> Read -> Ids del scope y recarga detallada.
- `PSTA_SegmentacionClientesSelector_cls` -> `PSTA_Consultas__mdt` -> Read -> `Consulta__c`.
- `PSTA_SegmentacionClientesSelector_cls` -> `ConfiguracionActinver__c` -> Read -> `TipoContratos__c`, `EstatusContrato__c`.
- `PSTA_SegmentacionClientesSelector_cls` -> `Account` -> Read -> campos de cuenta usados para segmentacion y fechas.
- `PSTA_SegmentacionClientesSelector_cls` -> `Contract` -> Read -> campos del contrato usados para saldo y antiguedad.
- `PSTA_FechaPrimerContacto_cls` -> `Account` -> Prepare update -> `Segmento__c`, `SaldoIntegral__c`, `FechaAntiguedad__c`, `FechaUltimoContacto__c`, `FechaUltimaVisita__c`, `ContactoPriorizadoEsteMes__c`, `PriorizacionVisita__c`.
- `PSTA_Segmentacion_cls` -> `Banker` -> Read -> `Division__c`, `Rol__c`, `ExternalId__c`.
- `PSTA_SegmentacionClientes_cls` -> `Account` -> Update -> campos preparados por `PSTA_FechaPrimerContacto_cls`.
- `EventLogger` -> `WebServiceTrackingLog__c` -> Insert solo en error -> detalle tecnico del fallo.
- `PSTA_AgrupacionPriorizacionMensual_bch` -> `PSTA_Consultas__mdt` -> Read -> `PSTA_Query_Priorizacion_Mensual`.
- `PSTA_PriorizacionSelector_cls` -> `ConfiguracionActinver__c` -> Read -> frecuencias y volumen por segmento.
- `PSTA_PriorizacionSelector_cls` -> `BusinessHours` -> Read -> `Name = Postventa`.
- `PSTA_PriorizacionMensual_cls` -> `Account` -> Update -> `ContactoPriorizadoEsteMes__c`, `PriorizacionVisita__c`.
- `AccountTrigger` y clases relacionadas -> `Account` -> Before update indirecto -> `FechaSiguienteContacto__c`, `FechaSiguienteVisita__c`, `FechaNoRequiereSerContacto__c`, `Segmento__c`, `OwnerId`, `BanqueroAsignado__c`, `RecordTypeId` y otros derivados.

## 7. Registros creados, actualizados o no modificados
1. Actualiza `Account` de manera directa en `PSTA_SegmentacionClientes_cls.updateRecords(...)`.
2. Actualiza `Account` nuevamente en `PSTA_PriorizacionMensual_cls.updateRecords(...)`.
3. Inserta `WebServiceTrackingLog__c` solo cuando hay error de DML.
4. No inserta `Account` nuevas.
5. No actualiza `Contract`.
6. El `before update` de `AccountTrigger` puede ampliar el conjunto de campos modificados en la misma cuenta.

## 8. Riesgos, observaciones y puntos de auditoria
1. El scheduler no valida dia habil. Si el cron dispara en un dia no operativo, el proceso corre de todos modos.
2. La query dinamica vive en metadata; cambios en `PSTA_Consultas__mdt` cambian el universo de cuentas sin despliegue.
3. `Database.update(..., false)` permite avance parcial. Para auditoria es obligatorio revisar `WebServiceTrackingLog__c`.
4. El impacto final depende tambien de `AccountTrigger`, no solo del batch.
5. El batch mensual encadenado asume que las banderas fueron reseteadas correctamente por el batch principal; si `finish()` no corre, la priorizacion puede quedar inconsistente.

## 9. Anexo de codigo fuente completo
Esta seccion agrega el codigo fuente completo de todos los artefactos que participan en el proceso analizado.

### classes/PSTA_SegmentacionClientes_sch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_SegmentacionClientes_sch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_sch_tst
* Description       :   Clase exclusiva para la periodicidad de la segmentacion de clientes
*--------------------------------------------------------------------------
* No.            Date              Author             Description
* 1.0         06-Jun-2025       Canche Isaac           Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_SegmentacionClientes_sch implements Schedulable {
    
    global void execute(SchedulableContext sc) {

        Id batchJobId = Database.executeBatch(new PSTA_SegmentacionClientes_bch(),Integer.valueOf(System.Label.PSTA_Segmentacion_Registros_Batch));
    }
    
}
```

### classes/PSTA_SegmentacionClientes_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_SegmentacionClientes_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_SegmentacionClientes_bch_tst
* Description       :   Batch para la segmentacion de clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_SegmentacionClientes_bch implements Database.Batchable<sObject>{
    global static ConfiguracionActinver__c config = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
    public Database.QueryLocator start(Database.BatchableContext BC) {


        return Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryCuentas());
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('#### PSTA_SegmentacionClientes_bch[execute]: '+scope.size());
        String[] setStatusValidos  = config.EstatusContrato__c.split(';');
        String[] setTipoContratoValidos   = config.TipoContratos__c.split(';');
        List<Account> lstClientes  = [SELECT Id, 
                                        FechaUltimoContacto__c,
                                        FechaUltimaVisita__c,
                                        BanqueroAsignado__c, 
                                        SaldoIntegral__c, 
                                        Segmento__c, 
                                        (SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c 
                                        FROM Contracts 
                                        WHERE Status__c IN :setStatusValidos AND TypeOfContract__c IN :setTipoContratoValidos AND Saldo__c != null AND AccountOpeningDate__c != null ORDER BY AccountOpeningDate__c ASC), 
                                        TYPEOF BanqueroAsignado__r.BusinessUnitMember 
                                        WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c 
                                        END
                                    FROM Account 
                                    WHERE Id IN :scope];

        List<Account> lstClientesToUpdate = PSTA_SegmentacionClientes_cls.segmentacionClientes(lstClientes);

        if (!lstClientesToUpdate.isEmpty()) {
            PSTA_SegmentacionClientes_cls.updateRecords(lstClientesToUpdate);
        } 
    }

    public void finish(Database.BatchableContext BC) {
        PSTA_AgrupacionPriorizacionMensual_bch batch = new PSTA_AgrupacionPriorizacionMensual_bch();
        if(!Test.isRunningTest()) Database.executeBatch(batch);
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

### classes/PSTA_SegmentacionClientes_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_SegmentacionClientes_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase para la segmentacion de clientes
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public without sharing class PSTA_SegmentacionClientes_cls {

    public static List<Account> segmentacionClientes(List<Account> lstClientes) {

        List<Account> lstClientesParaActualizar        =  PSTA_FechaPrimerContacto_cls.procesarFechas(lstClientes);

        return lstClientesParaActualizar;

    }

    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Numero de errores: ' + intCount, error.getMessage());
                    intCount++;
                }
            }
        }
        if(!mapErrors.isEmpty()){
            saveLogError(mapErrors, 'Error durante Actualizacion de segmento de cuenta', 'ERROR_BATCH_SEGMENTACION_001', '');
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

### classes/PSTA_FechaPrimerContacto_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_FechaPrimerContacto_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   PSTA_FechaPrimerContacto_cls_tst
* Description       :   Clase helper que actualiza la fecha de ultimo contacto de la cuenta en caso de no tener con la fecha de apertura del primer contrato
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_FechaPrimerContacto_cls {

    public static List<Account> procesarFechas(List<Account> lstCuentas) {

        
        for(Account cuenta : lstCuentas) {
            System.debug('#Contratos: '+cuenta.contracts.size());
            
            Banker banker = (Banker)cuenta.BanqueroAsignado__r.BusinessUnitMember;
            if (PSTA_Segmentacion_cls.determinarSegmento(banker) == null) {
                continue;
            }

            cuenta.Segmento__c = PSTA_Segmentacion_cls.determinarSegmento(banker);
            if(cuenta.contracts.size() > 0) {
                Decimal saldoTotal = 0;
                for(Contract contrato : cuenta.contracts) {
                    saldoTotal += Decimal.valueOf(contrato.Saldo__c);
                }

                cuenta.SaldoIntegral__c = saldoTotal;
            

                Date fechaMasAntigua = cuenta.contracts[0].AccountOpeningDate__c;
                cuenta.FechaAntiguedad__c = fechaMasAntigua;

                if(cuenta.FechaUltimoContacto__c == null) {
                    cuenta.FechaUltimoContacto__c   = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimoContacto__c;
                    cuenta.FechaUltimaVisita__c     = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimaVisita__c;
                }
                
            }


            cuenta.ContactoPriorizadoEsteMes__c = false;
            cuenta.PriorizacionContacto__c      = false;
            cuenta.PriorizacionVisita__c        = false;

        }
        return lstCuentas;
    }
    
    

}
```

### classes/PSTA_Segmentacion_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_Segmentacion_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post Venta
* Clase test		:   
* Description       :   Clase helper que asigna una division o segmento a un cliente
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         16-Jun-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_Segmentacion_cls {
    
    public static Boolean bypassTriggerExecution = false;

    public static final ConfiguracionActinver__c objConfigPatrimonialReactivo   = PSTA_SegmentacionClientesSelector_cls.getConfiguracionPatrimonialReactivo();

    
    public static void procesarSegmentoPorCambioAsesor(List<Account> lstCuentas, Map<Id, Account> oldCuentas) {

        if (bypassTriggerExecution) {
            system.debug('bypassTriggerExecution true');
            return;
        }

        // 1. Recopilar todos los IDs de BusinessUnitMember (Bankers)
        Set<Id> bankerIds = new Set<Id>();
        for(Account cuentaNueva : lstCuentas) {
            Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
            
            boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
            boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
            
            if((cambioBanquero || cambioOwner) && 
            cuentaNueva.BanqueroAsignado__r != null && 
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
                
                bankerIds.add(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);
            }
        }

        if(bankerIds.isEmpty()) return;

        // 2. Hacer una sola consulta para todos los Bankers
        Map<Id, Banker> bankersMap = new Map<Id, Banker>([
            SELECT Id, Cargo__c, Division__c 
            FROM Banker 
            WHERE Id IN :bankerIds
        ]);
        
        for(Account cuentaNueva : lstCuentas) {
            Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
            
            boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
            boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
        
            if( (cambioBanquero || cambioOwner) && 
            cuentaNueva.BanqueroAsignado__r != null && 
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
            cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {

                
                Banker banker = bankersMap.get(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);

                //Banker banker = (Banker)cuentaNueva.BanqueroAsignado__r.BusinessUnitMember;
                String nuevoSegmento = determinarSegmento(banker);
                
                if(nuevoSegmento != null && nuevoSegmento != cuentaOld.Segmento__c) {

                    cuentaNueva.Segmento__c = nuevoSegmento;
                }
            }
        }
        
    }
    
    public static String determinarSegmento(Banker banquero) {

        String cargoBanquero = banquero.Cargo__c != null ? banquero.Cargo__c.replaceAll(' ', '') : '';
        Set<String> rolesValidosReactivo = PSTA_UtilityClass.splitValuesMultiPickList(objConfigPatrimonialReactivo.Rol__c);
        String resultado;
        
        if (banquero.Division__c != null) {
            resultado = rolesValidosReactivo.contains(cargoBanquero) ? objConfigPatrimonialReactivo.Segmento__c : banquero.Division__c;
            return resultado;
        }
        
        resultado = rolesValidosReactivo.contains(cargoBanquero) ? objConfigPatrimonialReactivo.Segmento__c : null;
        return resultado;

    }

}
```

### classes/PSTA_AgrupacionPriorizacionMensual_bch.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_AgrupacionPriorizacionMensual_bch.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_AgrupacionPriorizacionMensual_bch_tst
* Description       :   Batch para la priorizacion mensual de clientes.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         08-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>{
    public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento;
    public String strConditions;
    global PSTA_AgrupacionPriorizacionMensual_bch() {
        this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        this.strConditions = PSTA_PriorizacionMensual_cls.getClausuleQueryBySegmento(this.mapConfigPorSegmento);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual(this.strConditions));
    }

    global void execute(Database.BatchableContext BC, List<Account> lstClientes) {
        System.debug('scope: ' + lstClientes);
        List<Account> lstClientesActualizar = PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapConfigPorSegmento);
        System.debug('Clientes a actualizar: ' + lstClientesActualizar);
        if(lstClientesActualizar.size() > 0) PSTA_PriorizacionMensual_cls.updateRecords(lstClientesActualizar);
    }

    global void finish(Database.BatchableContext BC) {

        /*PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
        Database.executeBatch(batch);*/
        System.debug('Finaliza batch PSTA_AgrupacionPriorizacionMensual_bch');
    }
}
/*global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>, Database.Stateful{
    
    public Map<Id, List<Account>> mapAsesorPorCuentas;
    public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento; 

    global PSTA_AgrupacionPriorizacionMensual_bch() {
        this.mapAsesorPorCuentas = new Map<Id, List<Account>>();
        this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return null;//Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual());
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Account> lstClientes = (List<Account>) scope;

        //PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapAsesorPorCuentas);
            
    }

    global void finish(Database.BatchableContext BC) {

        PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
        Database.executeBatch(batch);
    }
}*/
```

### classes/PSTA_PriorizacionMensual_cls.cls
Ruta absoluta: C:\Users\fortega\Downloads\SFACT\Post Venta\Barra de avance\Barra de avance\force-app\main\default\classes\PSTA_PriorizacionMensual_cls.cls
```text
/******************************************************************************* 
* Developed by      :   VASS México
* Author            :   Canche Isaac
* Project           :   Post venta
* Clase test		:   PSTA_PriorizacionMensual_cls_tst
* Description       :   Clase controlador para la priorizacion mensual.
*--------------------------------------------------------------------------
* No.            Date              Author                Description
* 1.0         09-Jul-2025       Canche Isaac              Creación
*--------------------------------------------------------------------------
*******************************************************************************/
public class PSTA_PriorizacionMensual_cls {

    public static Id defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();

    public static List<Account> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones) {
        List<Account> lstToUpdate = new List<Account>();
        for(Account cuenta : lstCuentas) {
            if( cuenta.BanqueroAsignado__r != null && 
                cuenta.BanqueroAsignado__r.BusinessUnitMember != null &&
                cuenta.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
                if (!mapConfiguraciones.containsKey(cuenta.Segmento__c)) continue;
                ConfiguracionActinver__c config = mapConfiguraciones.get(cuenta.Segmento__c);
                cuenta.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Date.today());
                cuenta.PriorizacionVisita__c = debePriorizarContacto(cuenta.FechaSiguienteVisita__c, Date.today());
                if(cuenta.PriorizacionVisita__c || cuenta.ContactoPriorizadoEsteMes__c) lstToUpdate.add(cuenta);
                
            }
        }
        return lstToUpdate;
    }

    

    public static List<Account> priorizarCuentas(List<Id> lstAsesores,Map<Id, List<Account>> mapCuentasPorAsesor, Map<String, ConfiguracionActinver__c> mapConfiguraciones){
        List<Account> lstCuentasParaActualizar = new List<Account>();
        Date hoy = Date.today();
        for (Id asesor : lstAsesores) {
            List<Account> clientes = mapCuentasPorAsesor.get(asesor);
            if (clientes == null || clientes.isEmpty()) continue;
            
            // Obtenemos el segmento del primer cliente (todos tienen mismo asesor y segmento)
            String segmentoAsesor = clientes[0].Segmento__c;
            if (!mapConfiguraciones.containsKey(segmentoAsesor)) continue;
            
            ConfiguracionActinver__c config = mapConfiguraciones.get(segmentoAsesor);
            
            for (Account cliente : clientes) {
                cliente.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cliente, config, hoy);
                lstCuentasParaActualizar.add(cliente);
            }
        }

        return lstCuentasParaActualizar;
    }
	public static Boolean debePriorizarContacto( Date dtFechaSiguiente, Date dtFechaEjecucion) {
        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(dtFechaSiguiente, dtFechaEjecucion, defaultBusinessHoursId);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= 0;
        return cumpleFrecuencia;
    }
    public static Boolean debePriorizarContacto(Account cliente, ConfiguracionActinver__c config, Date hoy) {
        

        Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(cliente.FechaSiguienteContacto__c, hoy, defaultBusinessHoursId);
        Boolean cumpleFrecuencia = lngDiasEntreFechas >= config.FrecuenciaContacto__c;
        
        return /*contactoEnMesActual || */cumpleFrecuencia;
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
	public static String getClausuleQueryBySegmento(Map<String, ConfiguracionActinver__c> mapConfiguraciones){
        Map<String, ConfiguracionActinver__c> mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
        String cadena = 'AND (';
        String strOr = '';
        Integer intTamanio = 0;
        for(String segmento : mapConfigPorSegmento.keySet()){
            strOr += '(Segmento__c = \'' + segmento + '\' AND SaldoIntegral__c >= ' + mapConfigPorSegmento.get(segmento).RangoMontoMinimo__c;
            strOr += ' AND SaldoIntegral__c <= ' + + mapConfigPorSegmento.get(segmento).RangoMontoMaximo__c + ')';
            system.debug('contador: ' + intTamanio);
            if(intTamanio < (mapConfigPorSegmento.keySet().size() - 1)){
                strOr += ' OR ';
                intTamanio++;
            }
        }
        cadena += strOr + ')';
        System.debug('cadena: ' + cadena);
        return cadena;
    }
    public static void updateRecords(List<SObject> lstRecords){
        Map<String, String> mapErrors = new Map<String, String>();
        Database.SaveResult[] updateList = Database.update(lstRecords, false);
        for(Database.SaveResult saveResult : updateList){
            if(!saveResult.isSuccess()){
                mapErrors = new Map<String, String>();
                Integer intCount = 0;
                for(Database.Error error : saveResult.getErrors()){
                    mapErrors.put('Numero de errores:' + intCount, error.getMessage());
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
