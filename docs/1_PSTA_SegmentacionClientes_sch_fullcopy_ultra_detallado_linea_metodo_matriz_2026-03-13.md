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

## 10. Desglose por metodo con lineas y comportamiento
Esta seccion agrega un inventario metodo por metodo, con lineas de inicio/fin, foco funcional y rastreo de query, DML y side effects.

### classes/PSTA_SegmentacionClientes_sch.cls
- Metodo/Elemento: `execute`
- Lineas: `14-17`
- Firma: `global void execute(SchedulableContext sc) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Id batchJobId = Database.executeBatch(new PSTA_SegmentacionClientes_bch(),Integer.valueOf(System.Label.PSTA_Segmentacion_Registros_Batch));
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_SegmentacionClientes_bch.cls
- Metodo/Elemento: `start`
- Lineas: `14-18`
- Firma: `public Database.QueryLocator start(Database.BatchableContext BC) {`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `execute`
- Lineas: `20-44`
- Firma: `public void execute(Database.BatchableContext BC, List<Account> scope) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: List<Account> lstClientes  = [SELECT Id,; (SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `finish`
- Lineas: `46-49`
- Firma: `public void finish(Database.BatchableContext BC) {`
- Funcion tecnica: Cierra el proceso actual; puede encadenar batches, dejar trazas o completar efectos posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: if(!Test.isRunningTest()) Database.executeBatch(batch);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_SegmentacionClientesSelector_cls.cls
- Metodo/Elemento: `getQueryCuentas`
- Lineas: `17-21`
- Firma: `public static String getQueryCuentas( ) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguracionContratosPostventa`
- Lineas: `39-44`
- Firma: `public static ConfiguracionActinver__c getConfiguracionContratosPostventa(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT TipoContratos__c, EstatusContrato__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getStringQuery`
- Lineas: `46-59`
- Firma: `public static String getStringQuery(List<String> strConjunto){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguracionContacto`
- Lineas: `61-67`
- Firma: `public static List<ConfiguracionActinver__c> getConfiguracionContacto() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguracionPatrimonialReactivo`
- Lineas: `70-78`
- Firma: `public static ConfiguracionActinver__c getConfiguracionPatrimonialReactivo() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getQueryAllBBM`
- Lineas: `80-83`
- Firma: `public static String getQueryAllBBM(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getQueryStatusCuentas`
- Lineas: `85-89`
- Firma: `public static String getQueryStatusCuentas() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getQueryStatusCuentas`
- Lineas: `97-110`
- Firma: `public static String getQueryStatusCuentas() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return 'SELECT Id, ' +
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_SegmentacionClientes_cls.cls
- Metodo/Elemento: `segmentacionClientes`
- Lineas: `14-20`
- Firma: `public static List<Account> segmentacionClientes(List<Account> lstClientes) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `updateRecords`
- Lineas: `22-38`
- Firma: `public static void updateRecords(List<SObject> lstRecords){`
- Funcion tecnica: Metodo orientado a persistencia; aplica DML parcial o total sobre registros preparados previamente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.SaveResult[] updateList = Database.update(lstRecords, false);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `saveLogError`
- Lineas: `39-45`
- Firma: `public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){`
- Funcion tecnica: Metodo orientado a registro de errores, logging o persistencia auxiliar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: EventLogger.error(new Map<String, String>{'contextId' => null,

### classes/PSTA_FechaPrimerContacto_cls.cls
- Metodo/Elemento: `procesarFechas`
- Lineas: `14-52`
- Firma: `public static List<Account> procesarFechas(List<Account> lstCuentas) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_Segmentacion_cls.cls
- Metodo/Elemento: `procesarSegmentoPorCambioAsesor`
- Lineas: `19-76`
- Firma: `public static void procesarSegmentoPorCambioAsesor(List<Account> lstCuentas, Map<Id, Account> oldCuentas) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: SELECT Id, Cargo__c, Division__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `determinarSegmento`
- Lineas: `78-92`
- Firma: `public static String determinarSegmento(Banker banquero) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_AgrupacionPriorizacionMensual_bch.cls
- Metodo/Elemento: `PSTA_AgrupacionPriorizacionMensual_bch`
- Lineas: `15-18`
- Firma: `global PSTA_AgrupacionPriorizacionMensual_bch() {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `20-22`
- Firma: `global Database.QueryLocator start(Database.BatchableContext BC) {`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `execute`
- Lineas: `24-29`
- Firma: `global void execute(Database.BatchableContext BC, List<Account> lstClientes) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `finish`
- Lineas: `31-36`
- Firma: `global void finish(Database.BatchableContext BC) {`
- Funcion tecnica: Cierra el proceso actual; puede encadenar batches, dejar trazas o completar efectos posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.executeBatch(batch);*/
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `PSTA_AgrupacionPriorizacionMensual_bch`
- Lineas: `43-46`
- Firma: `global PSTA_AgrupacionPriorizacionMensual_bch() {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `start`
- Lineas: `48-50`
- Firma: `global Database.QueryLocator start(Database.BatchableContext BC) {`
- Funcion tecnica: Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `execute`
- Lineas: `52-57`
- Firma: `global void execute(Database.BatchableContext BC, List<sObject> scope) {`
- Funcion tecnica: Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `finish`
- Lineas: `59-63`
- Firma: `global void finish(Database.BatchableContext BC) {`
- Funcion tecnica: Cierra el proceso actual; puede encadenar batches, dejar trazas o completar efectos posteriores.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.executeBatch(batch);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_PriorizacionMensual_cls.cls
- Metodo/Elemento: `agrupacionBanqueroPorCuentas`
- Lineas: `16-31`
- Firma: `public static List<Account> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `priorizarCuentas`
- Lineas: `35-55`
- Firma: `public static List<Account> priorizarCuentas(List<Id> lstAsesores,Map<Id, List<Account>> mapCuentasPorAsesor, Map<String, ConfiguracionActinver__c> mapConfiguraciones){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `debePriorizarContacto`
- Lineas: `56-60`
- Firma: `public static Boolean debePriorizarContacto( Date dtFechaSiguiente, Date dtFechaEjecucion) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `debePriorizarContacto`
- Lineas: `61-68`
- Firma: `public static Boolean debePriorizarContacto(Account cliente, ConfiguracionActinver__c config, Date hoy) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `obtenerSegmentoPorConfig`
- Lineas: `70-81`
- Firma: `public static Map<String,ConfiguracionActinver__c> obtenerSegmentoPorConfig() {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getClausuleQueryBySegmento`
- Lineas: `82-99`
- Firma: `public static String getClausuleQueryBySegmento(Map<String, ConfiguracionActinver__c> mapConfiguraciones){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `updateRecords`
- Lineas: `100-116`
- Firma: `public static void updateRecords(List<SObject> lstRecords){`
- Funcion tecnica: Metodo orientado a persistencia; aplica DML parcial o total sobre registros preparados previamente.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.SaveResult[] updateList = Database.update(lstRecords, false);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `saveLogError`
- Lineas: `118-124`
- Firma: `public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){`
- Funcion tecnica: Metodo orientado a registro de errores, logging o persistencia auxiliar.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: EventLogger.error(new Map<String, String>{'contextId' => null,

### classes/PSTA_PriorizacionSelector_cls.cls
- Metodo/Elemento: `getQueryCuentasPriorizacionMensual`
- Lineas: `16-24`
- Firma: `public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String baseQuery = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Mensual'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getQueryCuentasPriorizacionDiaria`
- Lineas: `44-48`
- Firma: `public static String getQueryCuentasPriorizacionDiaria() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'].Consulta__c ;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguracionContacto`
- Lineas: `68-74`
- Firma: `public static List<ConfiguracionActinver__c> getConfiguracionContacto() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getDiasLaborales`
- Lineas: `76-78`
- Firma: `public static Id getDiasLaborales(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### triggers/AccountTrigger.trigger
- Metodo/Elemento: `AccountTrigger`
- Lineas: `22-44`
- Firma: `trigger AccountTrigger on Account(before insert, before update, After insert, After update) {`
- Funcion tecnica: Punto de entrada trigger; enruta el evento del objeto/plataforma a la clase manejadora.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: if (Trigger.isUpdate && Trigger.isBefore) {; OD_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);; PSTA_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);; AccountRecordTypeAssigner.apply(Trigger.new, Trigger.oldMap);; if (Trigger.isInsert && Trigger.isBefore) {

### classes/PSTA_Account_thr.cls
- Metodo/Elemento: `onBeforeUpdate`
- Lineas: `13-20`
- Firma: `public static void onBeforeUpdate(List<Account> newListAccount, Map<Id,Account> oldMapAccount){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_ListadoClientes_cls.cls
- Metodo/Elemento: `actualizarFechaSiguienteContacto`
- Lineas: `25-49`
- Firma: `public static void actualizarFechaSiguienteContacto(List<Account> lstClientes, Map<Id, Account> oldMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `actualizarFechaSiguienteVisita`
- Lineas: `51-73`
- Firma: `public static void actualizarFechaSiguienteVisita(List<Account> lstClientes, Map<Id, Account> oldMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `actualizarFechaNoQuiereSerContactado`
- Lineas: `75-100`
- Firma: `public static void actualizarFechaNoQuiereSerContactado(List<Account> lstClientes, Map<Id, Account> oldMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getMapSegmentoByFrecuenciaContacto`
- Lineas: `102-113`
- Firma: `public static Map<String,Integer> getMapSegmentoByFrecuenciaContacto() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getMapSegmentoByFrecuenciaVisita`
- Lineas: `115-126`
- Firma: `public static Map<String,Integer> getMapSegmentoByFrecuenciaVisita() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getMapSegmentoByFrecuenciaNoContacto`
- Lineas: `128-139`
- Firma: `public static Map<String,Integer> getMapSegmentoByFrecuenciaNoContacto() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/PSTA_ListaClientesSelector_cls.cls
- Metodo/Elemento: `getDiasLaborales`
- Lineas: `16-18`
- Firma: `public static Id getDiasLaborales(){`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getConfiguracionPostVenta`
- Lineas: `20-26`
- Firma: `public static List<ConfiguracionActinver__c> getConfiguracionPostVenta() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: SELECT Segmento__c, FrecReinicioNoReqContacto__c, FrecuenciaContacto__c, FrecuenciaVisita__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/OD_Account_thr.cls
- Metodo/Elemento: `onBeforeInsert`
- Lineas: `14-20`
- Firma: `public static void onBeforeInsert(List<Account> newListAccount){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `onBeforeUpdate`
- Lineas: `21-25`
- Firma: `public static void onBeforeUpdate(List<Account> newListAccount,Map<Id,Account> oldMapAccount){`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/OD_Account_cls.cls
- Metodo/Elemento: `processToChangeOwnerFromAccount`
- Lineas: `17-125`
- Firma: `public static void processToChangeOwnerFromAccount(List<Account> newListAccount,Map<Id,Account> oldMapAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: system.debug(Service_Utility_Trigger.isCorrectRecordTypeId(acc));; if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){; usersByIdMap = Service_Utility_Trigger.getUsersByOwnerIds(uniqueOwnerIds);; bankersBranchUnitOwnerMap = Service_Utility_Trigger.getBranchUnitByOwnerId(uniqueOwnerIds);; usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
- Metodo/Elemento: `checkTotalPercent`
- Lineas: `129-169`
- Firma: `public static void checkTotalPercent(List<Account> newListAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `createAccounts`
- Lineas: `170-185`
- Firma: `public static void createAccounts(List<Account> newListAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `convertMappingLeadToAccount`
- Lineas: `186-201`
- Firma: `public static void convertMappingLeadToAccount(List<Account> newListAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getLeadByExternalId`
- Lineas: `202-217`
- Firma: `public static Lead[] getLeadByExternalId(Set<String> setAccountIds) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: Lead[] lstLead = [SELECT Id
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `setValuesOfConvertLead`
- Lineas: `218-226`
- Firma: `public static void setValuesOfConvertLead(Map<String,Lead> mapAccountIdByLeads,Account objAccount) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/AccountRecordTypeAssigner.cls
- Metodo/Elemento: `apply`
- Lineas: `3-78`
- Firma: `public static void apply(List<Account> newList, Map<Id, Account> oldMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: SELECT Id, ID_ASESOR__c; SELECT ExternalId__c, Division__c
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.

### classes/EventLogger.cls
- Metodo/Elemento: `error`
- Lineas: `19-21`
- Firma: `public static void error(Map<String, String> logErrorMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `error`
- Lineas: `27-37`
- Firma: `public static void error(Map<String, String> logErrorMap, List<Object> values) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `setMedalliaData`
- Lineas: `45-52`
- Firma: `public static WebServiceTrackingLog__c setMedalliaData(WebServiceTrackingLog__c log, Map<String, String> logErrorMap) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `newLog`
- Lineas: `60-68`
- Firma: `public static WebServiceTrackingLog__c newLog(String message, String request, List<Object> values, Id contextId, String type) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getTimestamp`
- Lineas: `73-75`
- Firma: `public static String getTimestamp() {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `cast`
- Lineas: `81-89`
- Firma: `public static List<String> cast(List<Object> values) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `populateLocation`
- Lineas: `94-105`
- Firma: `public static void populateLocation(WebServiceTrackingLog__c log) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getPrettyMethod`
- Lineas: `111-113`
- Firma: `public static String getPrettyMethod(String method) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `insertLogs`
- Lineas: `119-126`
- Firma: `public static void insertLogs(List<WebServiceTrackingLog__c> logsToInsert) {`
- Funcion tecnica: Metodo/elemento participante en la orquestacion o transformacion del proceso.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: Database.SaveResult[] insertList = Database.insert (logsToInsert, false);
- Side effects detectados: No detectados en el cuerpo del metodo/elemento.
- Metodo/Elemento: `getRecordTypeId`
- Lineas: `132-134`
- Firma: `public static Id getRecordTypeId(String developerName) {`
- Funcion tecnica: Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.
- Query/Read detectado: No detectado en el cuerpo del metodo/elemento.
- DML/Ejecucion detectada: No detectado en el cuerpo del metodo/elemento.
- Side effects detectados: return Schema.SObjectType.WebServiceTrackingLog__c.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();

## 11. Matriz tecnica granular archivo -> metodo -> query -> dml -> side effects
| Archivo | Metodo/Elemento | Lineas | Query/Read | DML/Ejecucion | Side effects |
|---|---|---:|---|---|---|
| classes/PSTA_SegmentacionClientes_sch.cls | execute | 14-17 | - | Id batchJobId = Database.executeBatch(new PSTA_SegmentacionClientes_bch(),Integer.valueOf(System.Label.PSTA_Segmentacion_Registros_Batch)); | - |
| classes/PSTA_SegmentacionClientes_bch.cls | start | 14-18 | - | - | - |
| classes/PSTA_SegmentacionClientes_bch.cls | execute | 20-44 | List<Account> lstClientes  = [SELECT Id,<br>(SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c | - | - |
| classes/PSTA_SegmentacionClientes_bch.cls | finish | 46-49 | - | if(!Test.isRunningTest()) Database.executeBatch(batch); | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getQueryCuentas | 17-21 | String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'].Consulta__c ; | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getConfiguracionContratosPostventa | 39-44 | return [SELECT TipoContratos__c, EstatusContrato__c | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getStringQuery | 46-59 | - | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getConfiguracionContacto | 61-67 | SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getConfiguracionPatrimonialReactivo | 70-78 | SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getQueryAllBBM | 80-83 | String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'].Consulta__c ; | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getQueryStatusCuentas | 85-89 | String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'].Consulta__c ; | - | - |
| classes/PSTA_SegmentacionClientesSelector_cls.cls | getQueryStatusCuentas | 97-110 | return 'SELECT Id, ' + | - | - |
| classes/PSTA_SegmentacionClientes_cls.cls | segmentacionClientes | 14-20 | - | - | - |
| classes/PSTA_SegmentacionClientes_cls.cls | updateRecords | 22-38 | - | Database.SaveResult[] updateList = Database.update(lstRecords, false); | - |
| classes/PSTA_SegmentacionClientes_cls.cls | saveLogError | 39-45 | - | - | EventLogger.error(new Map<String, String>{'contextId' => null, |
| classes/PSTA_FechaPrimerContacto_cls.cls | procesarFechas | 14-52 | - | - | - |
| classes/PSTA_Segmentacion_cls.cls | procesarSegmentoPorCambioAsesor | 19-76 | SELECT Id, Cargo__c, Division__c | - | - |
| classes/PSTA_Segmentacion_cls.cls | determinarSegmento | 78-92 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | PSTA_AgrupacionPriorizacionMensual_bch | 15-18 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | start | 20-22 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | execute | 24-29 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | finish | 31-36 | - | Database.executeBatch(batch);*/ | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | PSTA_AgrupacionPriorizacionMensual_bch | 43-46 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | start | 48-50 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | execute | 52-57 | - | - | - |
| classes/PSTA_AgrupacionPriorizacionMensual_bch.cls | finish | 59-63 | - | Database.executeBatch(batch); | - |
| classes/PSTA_PriorizacionMensual_cls.cls | agrupacionBanqueroPorCuentas | 16-31 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | priorizarCuentas | 35-55 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | debePriorizarContacto | 56-60 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | debePriorizarContacto | 61-68 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | obtenerSegmentoPorConfig | 70-81 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | getClausuleQueryBySegmento | 82-99 | - | - | - |
| classes/PSTA_PriorizacionMensual_cls.cls | updateRecords | 100-116 | - | Database.SaveResult[] updateList = Database.update(lstRecords, false); | - |
| classes/PSTA_PriorizacionMensual_cls.cls | saveLogError | 118-124 | - | - | EventLogger.error(new Map<String, String>{'contextId' => null, |
| classes/PSTA_PriorizacionSelector_cls.cls | getQueryCuentasPriorizacionMensual | 16-24 | String baseQuery = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Mensual'].Consulta__c ; | - | - |
| classes/PSTA_PriorizacionSelector_cls.cls | getQueryCuentasPriorizacionDiaria | 44-48 | String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'].Consulta__c ; | - | - |
| classes/PSTA_PriorizacionSelector_cls.cls | getConfiguracionContacto | 68-74 | SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c | - | - |
| classes/PSTA_PriorizacionSelector_cls.cls | getDiasLaborales | 76-78 | return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id; | - | - |
| triggers/AccountTrigger.trigger | AccountTrigger | 22-44 | - | - | if (Trigger.isUpdate && Trigger.isBefore) {<br>OD_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);<br>PSTA_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap); |
| classes/PSTA_Account_thr.cls | onBeforeUpdate | 13-20 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | actualizarFechaSiguienteContacto | 25-49 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | actualizarFechaSiguienteVisita | 51-73 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | actualizarFechaNoQuiereSerContactado | 75-100 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | getMapSegmentoByFrecuenciaContacto | 102-113 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | getMapSegmentoByFrecuenciaVisita | 115-126 | - | - | - |
| classes/PSTA_ListadoClientes_cls.cls | getMapSegmentoByFrecuenciaNoContacto | 128-139 | - | - | - |
| classes/PSTA_ListaClientesSelector_cls.cls | getDiasLaborales | 16-18 | return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id; | - | - |
| classes/PSTA_ListaClientesSelector_cls.cls | getConfiguracionPostVenta | 20-26 | SELECT Segmento__c, FrecReinicioNoReqContacto__c, FrecuenciaContacto__c, FrecuenciaVisita__c | - | - |
| classes/OD_Account_thr.cls | onBeforeInsert | 14-20 | - | - | - |
| classes/OD_Account_thr.cls | onBeforeUpdate | 21-25 | - | - | - |
| classes/OD_Account_cls.cls | processToChangeOwnerFromAccount | 17-125 | - | - | system.debug(Service_Utility_Trigger.isCorrectRecordTypeId(acc));<br>if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){<br>usersByIdMap = Service_Utility_Trigger.getUsersByOwnerIds(uniqueOwnerIds); |
| classes/OD_Account_cls.cls | checkTotalPercent | 129-169 | - | - | - |
| classes/OD_Account_cls.cls | createAccounts | 170-185 | - | - | - |
| classes/OD_Account_cls.cls | convertMappingLeadToAccount | 186-201 | - | - | - |
| classes/OD_Account_cls.cls | getLeadByExternalId | 202-217 | Lead[] lstLead = [SELECT Id | - | - |
| classes/OD_Account_cls.cls | setValuesOfConvertLead | 218-226 | - | - | - |
| classes/AccountRecordTypeAssigner.cls | apply | 3-78 | SELECT Id, ID_ASESOR__c<br>SELECT ExternalId__c, Division__c | - | - |
| classes/EventLogger.cls | error | 19-21 | - | - | - |
| classes/EventLogger.cls | error | 27-37 | - | - | - |
| classes/EventLogger.cls | setMedalliaData | 45-52 | - | - | - |
| classes/EventLogger.cls | newLog | 60-68 | - | - | - |
| classes/EventLogger.cls | getTimestamp | 73-75 | - | - | - |
| classes/EventLogger.cls | cast | 81-89 | - | - | - |
| classes/EventLogger.cls | populateLocation | 94-105 | - | - | - |
| classes/EventLogger.cls | getPrettyMethod | 111-113 | - | - | - |
| classes/EventLogger.cls | insertLogs | 119-126 | - | Database.SaveResult[] insertList = Database.insert (logsToInsert, false); | - |
| classes/EventLogger.cls | getRecordTypeId | 132-134 | - | - | return Schema.SObjectType.WebServiceTrackingLog__c.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId(); |

## 12. Codigo numerado archivo por archivo
En esta seccion se replica el codigo con numeracion de lineas para facilitar trazabilidad exacta durante la revision tecnica.

### classes/PSTA_SegmentacionClientes_sch.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   PSTA_SegmentacionClientes_sch_tst
0006: * Description       :   Clase exclusiva para la periodicidad de la segmentacion de clientes
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author             Description
0009: * 1.0         06-Jun-2025       Canche Isaac           Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: global class PSTA_SegmentacionClientes_sch implements Schedulable {
0013:     
0014:     global void execute(SchedulableContext sc) {
0015: 
0016:         Id batchJobId = Database.executeBatch(new PSTA_SegmentacionClientes_bch(),Integer.valueOf(System.Label.PSTA_Segmentacion_Registros_Batch));
0017:     }
0018:     
0019: }
```

### classes/PSTA_SegmentacionClientes_bch.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   PSTA_SegmentacionClientes_bch_tst
0006: * Description       :   Batch para la segmentacion de clientes.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         09-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: global class PSTA_SegmentacionClientes_bch implements Database.Batchable<sObject>{
0013:     global static ConfiguracionActinver__c config = PSTA_SegmentacionClientesSelector_cls.getConfiguracionContratosPostventa();
0014:     public Database.QueryLocator start(Database.BatchableContext BC) {
0015: 
0016: 
0017:         return Database.getQueryLocator(PSTA_SegmentacionClientesSelector_cls.getQueryCuentas());
0018:     }
0019: 
0020:     public void execute(Database.BatchableContext BC, List<Account> scope) {
0021:         System.debug('#### PSTA_SegmentacionClientes_bch[execute]: '+scope.size());
0022:         String[] setStatusValidos  = config.EstatusContrato__c.split(';');
0023:         String[] setTipoContratoValidos   = config.TipoContratos__c.split(';');
0024:         List<Account> lstClientes  = [SELECT Id, 
0025:                                         FechaUltimoContacto__c,
0026:                                         FechaUltimaVisita__c,
0027:                                         BanqueroAsignado__c, 
0028:                                         SaldoIntegral__c, 
0029:                                         Segmento__c, 
0030:                                         (SELECT Id, Status__c, AccountOpeningDate__c, TypeOfContract__c, Saldo__c 
0031:                                         FROM Contracts 
0032:                                         WHERE Status__c IN :setStatusValidos AND TypeOfContract__c IN :setTipoContratoValidos AND Saldo__c != null AND AccountOpeningDate__c != null ORDER BY AccountOpeningDate__c ASC), 
0033:                                         TYPEOF BanqueroAsignado__r.BusinessUnitMember 
0034:                                         WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c 
0035:                                         END
0036:                                     FROM Account 
0037:                                     WHERE Id IN :scope];
0038: 
0039:         List<Account> lstClientesToUpdate = PSTA_SegmentacionClientes_cls.segmentacionClientes(lstClientes);
0040: 
0041:         if (!lstClientesToUpdate.isEmpty()) {
0042:             PSTA_SegmentacionClientes_cls.updateRecords(lstClientesToUpdate);
0043:         } 
0044:     }
0045: 
0046:     public void finish(Database.BatchableContext BC) {
0047:         PSTA_AgrupacionPriorizacionMensual_bch batch = new PSTA_AgrupacionPriorizacionMensual_bch();
0048:         if(!Test.isRunningTest()) Database.executeBatch(batch);
0049:     }
0050: }
```

### classes/PSTA_SegmentacionClientesSelector_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   
0006: * Description       :   Clase selector que contiene todas las SOQL o DML del batch de la segmentacion de clientes.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         12-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public without sharing class PSTA_SegmentacionClientesSelector_cls {
0013: 
0014:     public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
0015:     public static final Id idConfigContratosPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('PSTA_ConfiguracionContratosPostventa').getRecordTypeId();
0016:     
0017:     public static String getQueryCuentas( ) {
0018:         String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Segmentacion'].Consulta__c ;
0019:         
0020:         return consulta;
0021:     }
0022:     /* public static String getQueryCuentas(String setStatusValidos, String setTipoContratoValidos ) {
0023:         String[] lstAsesores = new List<String>{'65052','64505','64609','65401','6027','64066','65334','60357','60714','66432','52230','63703','22','66529','66531','68742','295','67272','65352','68741','66548','67526','51294','52425','64537','61230','50385','68492','60349','52335','50755','64073','66','63646','60376','5506','66805','64153','52458','67313','66568','65525','65172','10016','66557','61167','60308','64635','52471','64452','66666','62185','64737','66549','63845','67951','67875','67386','67359','68170','62525','52266','62299','60352','60368','67262','66530','60346','60353','64491','63658','63480','52287','62674','64461','68009','64458','62300','30007','52213','69004','64031','60420','98060','63174','67009','61373','64627','62847','62427','64591','64444','66447','63167','65280','65403','66436','66431','64964','67853','69181','67780','64441','66063','67387','67376','67358','63180','65010','128','60172','52603','67926','53728','69341','63601','64714','61108','63967','52557','62639','66965','68150'};
0024:         String strAsesores  = PSTA_SegmentacionClientesSelector_cls.getStringQuery(lstAsesores);
0025: 
0026:         return 'SELECT Id, ' +
0027:                   'FechaUltimoContacto__c, ' +
0028:                   'FechaUltimaVisita__c, ' +
0029:                   'BanqueroAsignado__c, ' +
0030:                   'SaldoIntegral__c, ' +
0031:                   'Segmento__c, '+ 
0032:                   'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
0033:                   'WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c ' +
0034:                   'END ' +
0035:                   'FROM Account WHERE BanqueroAsignado__c != null AND Person_Type__c = \'FISICA\' AND ID_Asesor__c != null' ;// AND Id_Asesor__c IN ' +strAsesores;
0036:     } */
0037: 
0038: 
0039:     public static ConfiguracionActinver__c getConfiguracionContratosPostventa(){
0040:         return [SELECT TipoContratos__c, EstatusContrato__c 
0041:                              FROM ConfiguracionActinver__c 
0042:                              WHERE RecordTypeId =: idConfigContratosPostVentaRecordType 
0043:                              LIMIT 1];
0044:     }
0045: 
0046:     public static String getStringQuery(List<String> strConjunto){
0047:         String strOr = '(';
0048:         Integer intTamanio = 0;
0049:         for(String elemento : strConjunto){
0050:             strOr += '\'' + elemento + '\'';
0051:             
0052:             if(intTamanio < (strConjunto.size() - 1)){
0053:                 strOr += ',';
0054:                 intTamanio++;
0055:             }
0056:         }
0057:         strOr += ')';
0058:         return strOr;
0059:     }
0060: 
0061:     public static List<ConfiguracionActinver__c> getConfiguracionContacto() {
0062:         return [
0063:             SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
0064:             FROM ConfiguracionActinver__c
0065:             WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
0066:         ];
0067:     }
0068: 
0069: 
0070:     public static ConfiguracionActinver__c getConfiguracionPatrimonialReactivo() {
0071:         return [
0072:             SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
0073:             FROM ConfiguracionActinver__c
0074:             WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
0075:             AND Segmento__c = 'Patrimonial reactivo'
0076:             LIMIT 1
0077:         ];
0078:     }
0079: 
0080:     public static String getQueryAllBBM(){
0081:         String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Registro_Resumen_Global'].Consulta__c ;
0082:         return consulta;
0083:     }
0084: 
0085:     public static String getQueryStatusCuentas() {
0086:         String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Reinicio_Estatus_Contacto'].Consulta__c ;
0087:         return consulta;
0088:         
0089:     }
0090:     /* public static String getQueryAllBBM(){
0091: 
0092:        return 'SELECT Id, Name, BusinessUnitMemberId, TYPEOF BusinessUnitMember WHEN Banker THEN Division__c, Cargo__c, ExternalId__c, Id, Name END ' +
0093:               'FROM BranchUnitBusinessMember ' +
0094:               'WHERE ExternalId__c != null';
0095:     }
0096: 
0097:     public static String getQueryStatusCuentas() {
0098:         return 'SELECT Id, ' +
0099:                   'FechaUltimoContacto__c, ' +
0100:                   'FechaSiguienteContacto__c, ' +
0101:                   'Name,' +
0102:                   'BanqueroAsignado__c,' +
0103:                   'EstatusContacto__c,' +
0104:                   'PriorizacionContacto__c,' +
0105:                   'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
0106:                   'WHEN Banker THEN Division__c, ExternalId__c, Id, Cargo__c ' +
0107:                   'END ' +
0108:                   'FROM Account ' +
0109:                   'WHERE Person_Type__c = \'FISICA\' AND FechaSiguienteContacto__c != null AND FechaSiguienteContacto__c <= TODAY';
0110:     } */
0111: }
```

### classes/PSTA_SegmentacionClientes_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   
0006: * Description       :   Clase para la segmentacion de clientes
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         09-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public without sharing class PSTA_SegmentacionClientes_cls {
0013: 
0014:     public static List<Account> segmentacionClientes(List<Account> lstClientes) {
0015: 
0016:         List<Account> lstClientesParaActualizar        =  PSTA_FechaPrimerContacto_cls.procesarFechas(lstClientes);
0017: 
0018:         return lstClientesParaActualizar;
0019: 
0020:     }
0021: 
0022:     public static void updateRecords(List<SObject> lstRecords){
0023:         Map<String, String> mapErrors = new Map<String, String>();
0024:         Database.SaveResult[] updateList = Database.update(lstRecords, false);
0025:         for(Database.SaveResult saveResult : updateList){
0026:             if(!saveResult.isSuccess()){
0027:                 mapErrors = new Map<String, String>();
0028:                 Integer intCount = 0;
0029:                 for(Database.Error error : saveResult.getErrors()){
0030:                     mapErrors.put('Numero de errores: ' + intCount, error.getMessage());
0031:                     intCount++;
0032:                 }
0033:             }
0034:         }
0035:         if(!mapErrors.isEmpty()){
0036:             saveLogError(mapErrors, 'Error durante Actualizacion de segmento de cuenta', 'ERROR_BATCH_SEGMENTACION_001', '');
0037:         }
0038:     }
0039:     public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
0040:         EventLogger.error(new Map<String, String>{'contextId' => null,
0041:                                                     'type' => '',
0042:                                                     'errorCode' => errorCode,
0043:                                                     'message'   => message,
0044:                                                     'request'   => JSON.serializePretty(mapErrors)});
0045:     }
0046: 
0047: }
```

### classes/PSTA_FechaPrimerContacto_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   PSTA_FechaPrimerContacto_cls_tst
0006: * Description       :   Clase helper que actualiza la fecha de ultimo contacto de la cuenta en caso de no tener con la fecha de apertura del primer contrato
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         16-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public class PSTA_FechaPrimerContacto_cls {
0013: 
0014:     public static List<Account> procesarFechas(List<Account> lstCuentas) {
0015: 
0016:         
0017:         for(Account cuenta : lstCuentas) {
0018:             System.debug('#Contratos: '+cuenta.contracts.size());
0019:             
0020:             Banker banker = (Banker)cuenta.BanqueroAsignado__r.BusinessUnitMember;
0021:             if (PSTA_Segmentacion_cls.determinarSegmento(banker) == null) {
0022:                 continue;
0023:             }
0024: 
0025:             cuenta.Segmento__c = PSTA_Segmentacion_cls.determinarSegmento(banker);
0026:             if(cuenta.contracts.size() > 0) {
0027:                 Decimal saldoTotal = 0;
0028:                 for(Contract contrato : cuenta.contracts) {
0029:                     saldoTotal += Decimal.valueOf(contrato.Saldo__c);
0030:                 }
0031: 
0032:                 cuenta.SaldoIntegral__c = saldoTotal;
0033:             
0034: 
0035:                 Date fechaMasAntigua = cuenta.contracts[0].AccountOpeningDate__c;
0036:                 cuenta.FechaAntiguedad__c = fechaMasAntigua;
0037: 
0038:                 if(cuenta.FechaUltimoContacto__c == null) {
0039:                     cuenta.FechaUltimoContacto__c   = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimoContacto__c;
0040:                     cuenta.FechaUltimaVisita__c     = fechaMasAntigua != null ? fechaMasAntigua : cuenta.FechaUltimaVisita__c;
0041:                 }
0042:                 
0043:             }
0044: 
0045: 
0046:             cuenta.ContactoPriorizadoEsteMes__c = false;
0047:             cuenta.PriorizacionContacto__c      = false;
0048:             cuenta.PriorizacionVisita__c        = false;
0049: 
0050:         }
0051:         return lstCuentas;
0052:     }
0053:     
0054:     
0055: 
0056: }
```

### classes/PSTA_Segmentacion_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   
0006: * Description       :   Clase helper que asigna una division o segmento a un cliente
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         16-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public class PSTA_Segmentacion_cls {
0013:     
0014:     public static Boolean bypassTriggerExecution = false;
0015: 
0016:     public static final ConfiguracionActinver__c objConfigPatrimonialReactivo   = PSTA_SegmentacionClientesSelector_cls.getConfiguracionPatrimonialReactivo();
0017: 
0018:     
0019:     public static void procesarSegmentoPorCambioAsesor(List<Account> lstCuentas, Map<Id, Account> oldCuentas) {
0020: 
0021:         if (bypassTriggerExecution) {
0022:             system.debug('bypassTriggerExecution true');
0023:             return;
0024:         }
0025: 
0026:         // 1. Recopilar todos los IDs de BusinessUnitMember (Bankers)
0027:         Set<Id> bankerIds = new Set<Id>();
0028:         for(Account cuentaNueva : lstCuentas) {
0029:             Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
0030:             
0031:             boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
0032:             boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
0033:             
0034:             if((cambioBanquero || cambioOwner) && 
0035:             cuentaNueva.BanqueroAsignado__r != null && 
0036:             cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
0037:             cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
0038:                 
0039:                 bankerIds.add(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);
0040:             }
0041:         }
0042: 
0043:         if(bankerIds.isEmpty()) return;
0044: 
0045:         // 2. Hacer una sola consulta para todos los Bankers
0046:         Map<Id, Banker> bankersMap = new Map<Id, Banker>([
0047:             SELECT Id, Cargo__c, Division__c 
0048:             FROM Banker 
0049:             WHERE Id IN :bankerIds
0050:         ]);
0051:         
0052:         for(Account cuentaNueva : lstCuentas) {
0053:             Account cuentaOld = oldCuentas.get(cuentaNueva.Id);
0054:             
0055:             boolean cambioBanquero = cuentaNueva.BanqueroAsignado__c != cuentaOld.BanqueroAsignado__c;
0056:             boolean cambioOwner = cuentaNueva.OwnerId != cuentaOld.OwnerId;
0057:         
0058:             if( (cambioBanquero || cambioOwner) && 
0059:             cuentaNueva.BanqueroAsignado__r != null && 
0060:             cuentaNueva.BanqueroAsignado__r.BusinessUnitMember != null &&
0061:             cuentaNueva.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
0062: 
0063:                 
0064:                 Banker banker = bankersMap.get(cuentaNueva.BanqueroAsignado__r.BusinessUnitMember.Id);
0065: 
0066:                 //Banker banker = (Banker)cuentaNueva.BanqueroAsignado__r.BusinessUnitMember;
0067:                 String nuevoSegmento = determinarSegmento(banker);
0068:                 
0069:                 if(nuevoSegmento != null && nuevoSegmento != cuentaOld.Segmento__c) {
0070: 
0071:                     cuentaNueva.Segmento__c = nuevoSegmento;
0072:                 }
0073:             }
0074:         }
0075:         
0076:     }
0077:     
0078:     public static String determinarSegmento(Banker banquero) {
0079: 
0080:         String cargoBanquero = banquero.Cargo__c != null ? banquero.Cargo__c.replaceAll(' ', '') : '';
0081:         Set<String> rolesValidosReactivo = PSTA_UtilityClass.splitValuesMultiPickList(objConfigPatrimonialReactivo.Rol__c);
0082:         String resultado;
0083:         
0084:         if (banquero.Division__c != null) {
0085:             resultado = rolesValidosReactivo.contains(cargoBanquero) ? objConfigPatrimonialReactivo.Segmento__c : banquero.Division__c;
0086:             return resultado;
0087:         }
0088:         
0089:         resultado = rolesValidosReactivo.contains(cargoBanquero) ? objConfigPatrimonialReactivo.Segmento__c : null;
0090:         return resultado;
0091: 
0092:     }
0093: 
0094: }
```

### classes/PSTA_AgrupacionPriorizacionMensual_bch.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   PSTA_AgrupacionPriorizacionMensual_bch_tst
0006: * Description       :   Batch para la priorizacion mensual de clientes.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         08-Jul-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>{
0013:     public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento;
0014:     public String strConditions;
0015:     global PSTA_AgrupacionPriorizacionMensual_bch() {
0016:         this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
0017:         this.strConditions = PSTA_PriorizacionMensual_cls.getClausuleQueryBySegmento(this.mapConfigPorSegmento);
0018:     }
0019: 
0020:     global Database.QueryLocator start(Database.BatchableContext BC) {
0021:         return Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual(this.strConditions));
0022:     }
0023: 
0024:     global void execute(Database.BatchableContext BC, List<Account> lstClientes) {
0025:         System.debug('scope: ' + lstClientes);
0026:         List<Account> lstClientesActualizar = PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapConfigPorSegmento);
0027:         System.debug('Clientes a actualizar: ' + lstClientesActualizar);
0028:         if(lstClientesActualizar.size() > 0) PSTA_PriorizacionMensual_cls.updateRecords(lstClientesActualizar);
0029:     }
0030: 
0031:     global void finish(Database.BatchableContext BC) {
0032: 
0033:         /*PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
0034:         Database.executeBatch(batch);*/
0035:         System.debug('Finaliza batch PSTA_AgrupacionPriorizacionMensual_bch');
0036:     }
0037: }
0038: /*global class PSTA_AgrupacionPriorizacionMensual_bch implements Database.Batchable<sObject>, Database.Stateful{
0039:     
0040:     public Map<Id, List<Account>> mapAsesorPorCuentas;
0041:     public Map<String, ConfiguracionActinver__c> mapConfigPorSegmento; 
0042: 
0043:     global PSTA_AgrupacionPriorizacionMensual_bch() {
0044:         this.mapAsesorPorCuentas = new Map<Id, List<Account>>();
0045:         this.mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
0046:     }
0047: 
0048:     global Database.QueryLocator start(Database.BatchableContext BC) {
0049:         return null;//Database.getQueryLocator(PSTA_PriorizacionSelector_cls.getQueryCuentasPriorizacionMensual());
0050:     }
0051: 
0052:     global void execute(Database.BatchableContext BC, List<sObject> scope) {
0053:         List<Account> lstClientes = (List<Account>) scope;
0054: 
0055:         //PSTA_PriorizacionMensual_cls.agrupacionBanqueroPorCuentas(lstClientes, this.mapAsesorPorCuentas);
0056:             
0057:     }
0058: 
0059:     global void finish(Database.BatchableContext BC) {
0060: 
0061:         PSTA_ProcesarPriorizacionMensual_bch batch = new PSTA_ProcesarPriorizacionMensual_bch(this.mapAsesorPorCuentas, this.mapConfigPorSegmento);
0062:         Database.executeBatch(batch);
0063:     }
0064: }*/
```

### classes/PSTA_PriorizacionMensual_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   PSTA_PriorizacionMensual_cls_tst
0006: * Description       :   Clase controlador para la priorizacion mensual.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         09-Jul-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public class PSTA_PriorizacionMensual_cls {
0013: 
0014:     public static Id defaultBusinessHoursId = PSTA_PriorizacionSelector_cls.getDiasLaborales();
0015: 
0016:     public static List<Account> agrupacionBanqueroPorCuentas(List<Account> lstCuentas, Map<String, ConfiguracionActinver__c> mapConfiguraciones) {
0017:         List<Account> lstToUpdate = new List<Account>();
0018:         for(Account cuenta : lstCuentas) {
0019:             if( cuenta.BanqueroAsignado__r != null && 
0020:                 cuenta.BanqueroAsignado__r.BusinessUnitMember != null &&
0021:                 cuenta.BanqueroAsignado__r.BusinessUnitMember instanceof Banker) {
0022:                 if (!mapConfiguraciones.containsKey(cuenta.Segmento__c)) continue;
0023:                 ConfiguracionActinver__c config = mapConfiguraciones.get(cuenta.Segmento__c);
0024:                 cuenta.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cuenta.FechaSiguienteContacto__c, Date.today());
0025:                 cuenta.PriorizacionVisita__c = debePriorizarContacto(cuenta.FechaSiguienteVisita__c, Date.today());
0026:                 if(cuenta.PriorizacionVisita__c || cuenta.ContactoPriorizadoEsteMes__c) lstToUpdate.add(cuenta);
0027:                 
0028:             }
0029:         }
0030:         return lstToUpdate;
0031:     }
0032: 
0033:     
0034: 
0035:     public static List<Account> priorizarCuentas(List<Id> lstAsesores,Map<Id, List<Account>> mapCuentasPorAsesor, Map<String, ConfiguracionActinver__c> mapConfiguraciones){
0036:         List<Account> lstCuentasParaActualizar = new List<Account>();
0037:         Date hoy = Date.today();
0038:         for (Id asesor : lstAsesores) {
0039:             List<Account> clientes = mapCuentasPorAsesor.get(asesor);
0040:             if (clientes == null || clientes.isEmpty()) continue;
0041:             
0042:             // Obtenemos el segmento del primer cliente (todos tienen mismo asesor y segmento)
0043:             String segmentoAsesor = clientes[0].Segmento__c;
0044:             if (!mapConfiguraciones.containsKey(segmentoAsesor)) continue;
0045:             
0046:             ConfiguracionActinver__c config = mapConfiguraciones.get(segmentoAsesor);
0047:             
0048:             for (Account cliente : clientes) {
0049:                 cliente.ContactoPriorizadoEsteMes__c = debePriorizarContacto(cliente, config, hoy);
0050:                 lstCuentasParaActualizar.add(cliente);
0051:             }
0052:         }
0053: 
0054:         return lstCuentasParaActualizar;
0055:     }
0056: 	public static Boolean debePriorizarContacto( Date dtFechaSiguiente, Date dtFechaEjecucion) {
0057:         Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(dtFechaSiguiente, dtFechaEjecucion, defaultBusinessHoursId);
0058:         Boolean cumpleFrecuencia = lngDiasEntreFechas >= 0;
0059:         return cumpleFrecuencia;
0060:     }
0061:     public static Boolean debePriorizarContacto(Account cliente, ConfiguracionActinver__c config, Date hoy) {
0062:         
0063: 
0064:         Long lngDiasEntreFechas = PSTA_UtilityClass.obtenerDiasLaboralesEntreFechas(cliente.FechaSiguienteContacto__c, hoy, defaultBusinessHoursId);
0065:         Boolean cumpleFrecuencia = lngDiasEntreFechas >= config.FrecuenciaContacto__c;
0066:         
0067:         return /*contactoEnMesActual || */cumpleFrecuencia;
0068:     }
0069: 
0070:     public static Map<String,ConfiguracionActinver__c> obtenerSegmentoPorConfig() {
0071:         Map<String, ConfiguracionActinver__c> mapConfiguraciones = new Map<String, ConfiguracionActinver__c>();
0072:         List<ConfiguracionActinver__c> lstConfiguraciones = PSTA_PriorizacionSelector_cls.getConfiguracionContacto();
0073: 
0074:         for (ConfiguracionActinver__c configuracion : lstConfiguraciones) {
0075:             if (String.isNotBlank(configuracion.Segmento__c)) {
0076:                 mapConfiguraciones.put(configuracion.Segmento__c.trim(), configuracion);
0077:             }
0078:         }
0079: 
0080:         return mapConfiguraciones;
0081:     }
0082: 	public static String getClausuleQueryBySegmento(Map<String, ConfiguracionActinver__c> mapConfiguraciones){
0083:         Map<String, ConfiguracionActinver__c> mapConfigPorSegmento = PSTA_PriorizacionMensual_cls.obtenerSegmentoPorConfig();
0084:         String cadena = 'AND (';
0085:         String strOr = '';
0086:         Integer intTamanio = 0;
0087:         for(String segmento : mapConfigPorSegmento.keySet()){
0088:             strOr += '(Segmento__c = \'' + segmento + '\' AND SaldoIntegral__c >= ' + mapConfigPorSegmento.get(segmento).RangoMontoMinimo__c;
0089:             strOr += ' AND SaldoIntegral__c <= ' + + mapConfigPorSegmento.get(segmento).RangoMontoMaximo__c + ')';
0090:             system.debug('contador: ' + intTamanio);
0091:             if(intTamanio < (mapConfigPorSegmento.keySet().size() - 1)){
0092:                 strOr += ' OR ';
0093:                 intTamanio++;
0094:             }
0095:         }
0096:         cadena += strOr + ')';
0097:         System.debug('cadena: ' + cadena);
0098:         return cadena;
0099:     }
0100:     public static void updateRecords(List<SObject> lstRecords){
0101:         Map<String, String> mapErrors = new Map<String, String>();
0102:         Database.SaveResult[] updateList = Database.update(lstRecords, false);
0103:         for(Database.SaveResult saveResult : updateList){
0104:             if(!saveResult.isSuccess()){
0105:                 mapErrors = new Map<String, String>();
0106:                 Integer intCount = 0;
0107:                 for(Database.Error error : saveResult.getErrors()){
0108:                     mapErrors.put('Numero de errores:' + intCount, error.getMessage());
0109:                     intCount++;
0110:                 }
0111:             }
0112:         }
0113:         if(!mapErrors.isEmpty()){
0114:             saveLogError(mapErrors, 'Error durante Actualizacion de priorizacion mensual de cuenta', 'ERROR_BATCH_PRIORIZACION_MENSUAL_001', '');
0115:         }
0116:     }
0117: 
0118:     public static void saveLogError(Map<String, String> mapErrors, String message, String errorCode, String type){
0119:         EventLogger.error(new Map<String, String>{'contextId' => null,
0120:                                                     'type' => '',
0121:                                                     'errorCode' => errorCode,
0122:                                                     'message'   => message,
0123:                                                     'request'   => JSON.serializePretty(mapErrors)});
0124:     }
0125: 
0126: }
```

### classes/PSTA_PriorizacionSelector_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post venta
0005: * Clase test		:   PSTA_PriorizacionSelecto_cls_tst
0006: * Description       :   Clase de consultas para la priorizacion mensual y diaria.
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         14-Jul-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public without sharing class PSTA_PriorizacionSelector_cls {
0013:     
0014:     public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
0015: 
0016:     public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
0017:         
0018:         String baseQuery = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Mensual'].Consulta__c ;
0019:         
0020:         // Reemplazar el placeholder {0} con las condiciones dinámicas
0021:         return String.format(baseQuery, new List<String>{strConditionsBySegment});
0022:             
0023:         
0024:     }
0025: 
0026:     /* public static String getQueryCuentasPriorizacionMensual(String strConditionsBySegment) {
0027:         return 'SELECT Id, ' +
0028:                   'FechaUltimoContacto__c, ' +
0029:                   'FechaSiguienteContacto__c, ' +
0030:                   'FechaSiguienteVisita__c, ' +
0031:                   'BanqueroAsignado__c, ' +
0032:                   'SaldoIntegral__c, ' +
0033:                   'ContactoPriorizadoEsteMes__c, ' +
0034:                   'PriorizacionVisita__c, ' +
0035:                   'Segmento__c, ' +
0036:                   'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
0037:                   'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
0038:                   'END ' +
0039:                   'FROM Account ' +
0040:                   'WHERE Segmento__c != null AND SaldoIntegral__c != null AND FechaSiguienteContacto__c != null AND ContactoPriorizadoEsteMes__c = false AND FechaSiguienteVisita__c != null AND Person_Type__c = \'FISICA\' ' + 
0041:             	  strConditionsBySegment + ' AND ((FechaSiguienteContacto__c <= THIS_MONTH ) OR (FechaSiguienteVisita__c  <= THIS_MONTH ))';
0042:     } */
0043: 
0044:     public static String getQueryCuentasPriorizacionDiaria() {
0045:         // Obtener la consulta base de la Custom Label
0046:         String consulta = [SELECT Consulta__c FROM PSTA_Consultas__mdt WHERE DeveloperName = 'PSTA_Query_Priorizacion_Diaria'].Consulta__c ;
0047:         return consulta;
0048:     }
0049: 
0050:     /* public static String getQueryCuentasPriorizacionDiaria() {
0051:         return 'SELECT Id, ' +
0052:                   'FechaUltimoContacto__c, ' +
0053:                   'BanqueroAsignado__c, ' +
0054:                   'SaldoIntegral__c, ' +
0055:                   'FechaSiguienteContacto__c, ' +
0056:                   'FechaSiguienteVisita__c, ' +
0057:                   'ContactoPriorizadoEsteMes__c, ' +
0058:                   'PriorizacionContacto__c, ' +
0059:                   'PriorizacionVisita__c, ' +
0060:                   'Segmento__c, ' +
0061:                   'TYPEOF BanqueroAsignado__r.BusinessUnitMember ' +
0062:                   'WHEN Banker THEN Id, Division__c, ExternalId__c, Cargo__c ' +
0063:                   'END ' +
0064:                   'FROM Account ' +
0065:                   'WHERE ContactoPriorizadoEsteMes__c = true AND PriorizacionContacto__c = false AND EstatusContacto__c = \'Pendiente\' AND FechaSiguienteContacto__c != null AND Segmento__c != null AND SaldoIntegral__c != null AND Person_Type__c = \'FISICA\' ORDER BY SaldoIntegral__c DESC';
0066:     } */
0067: 
0068:     public static List<ConfiguracionActinver__c> getConfiguracionContacto() {
0069:         return [
0070:             SELECT Segmento__c, RangoMontoMaximo__c, RangoMontoMinimo__c, FrecReinicioNoReqContacto__c, Rol__c, FrecuenciaContacto__c, FrecuenciaVisita__c, ClientesContactarPorDia__c 
0071:             FROM ConfiguracionActinver__c
0072:             WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
0073:         ];
0074:     }
0075: 
0076:     public static Id getDiasLaborales(){
0077:         return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
0078:     }
0079: 
0080: }
```

### triggers/AccountTrigger.trigger
```text
0001: /**
0002:  *   ------------------------------------------------------------------------------------------------
0003:  *  Name     AccountTrigger
0004:  *  Author   Tate Shi
0005:  *  Date     Created: 12/09/2021
0006:  *  Group    PWC
0007:  *   ------------------------------------------------------------------------------------------------
0008:  *  Description Account trigger.
0009:  *   ------------------------------------------------------------------------------------------------
0010:  *  Changes
0011:  *  12/09/2021 Tate Shi
0012:  *             Class creation.
0013:  *  03/10/2022 luis.felipe.ortiz@pwc.com
0014:  *             Addition of ON/OFF behavior based on metadata.
0015:  *  13/11/2024 andres.hernandez@vasscompany.com
0016:  *             Realiza mejora framework en Trigger Contract agregando nueva Metadata
0017:  *  23/06/2025 isaac.alonzo@vasscompany.com
0018:  *             Se agrega la actualizacion de la fecha de siguiente contacto y visita para POSTVENTA      
0019:  *  14/01/2026 Se agrega actualizacion de RecordType usando Metadata para evitar Código duro (Gerardo Bautista)
0020:  *   ------------------------------------------------------------------------------------------------
0021:  **/
0022: trigger AccountTrigger on Account(before insert, before update, After insert, After update) {
0023:     
0024:     /*F3_Triggers__mdt triggerMetadata = F3_Triggers__mdt.getInstance(System.label.F3_AccountTrigger);
0025:     if (triggerMetadata == null || triggerMetadata.F3_isActive__c) {
0026:         new AccountTrigger_Handler().run();
0027:     }*/
0028:     //Llamado de metadata para validar si esta activo el trigger que se va ejecutar
0029:     Trigger_Management__mdt  triggerIsActive = Trigger_Management__mdt.getInstance(System.label.AccountTrigger);
0030:     if (triggerIsActive != null && triggerIsActive.IsActive__c) {
0031:         if (Trigger.isUpdate && Trigger.isBefore) {
0032:             OD_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
0033:             PSTA_Account_thr.onBeforeUpdate(Trigger.new,Trigger.oldMap);
0034:             // Nuevo llamado para extraer el recordType
0035:             AccountRecordTypeAssigner.apply(Trigger.new, Trigger.oldMap);
0036:             
0037:         }
0038:         if (Trigger.isInsert && Trigger.isBefore) {
0039:             OD_Account_thr.onBeforeInsert(Trigger.new);
0040:             // Nuevo llamado para extraer el recordType
0041:             AccountRecordTypeAssigner.apply(Trigger.new, null);
0042:         }        
0043:     }
0044: }
```

### classes/PSTA_Account_thr.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   
0006: * Description       :   Clase para el control de acciones sobre el trigger de cuentas para procesos de POSTVENTA
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         12-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public  class PSTA_Account_thr {
0013:    public static void onBeforeUpdate(List<Account> newListAccount, Map<Id,Account> oldMapAccount){
0014:         system.debug('*********************START BEFORE UPDATE ACCOUNT PSTA*********************');
0015:         PSTA_ListadoClientes_cls.actualizarFechaSiguienteContacto(newListAccount,oldMapAccount);
0016:         PSTA_ListadoClientes_cls.actualizarFechaSiguienteVisita(newListAccount,oldMapAccount);
0017:         PSTA_ListadoClientes_cls.actualizarFechaNoQuiereSerContactado(newListAccount,oldMapAccount);
0018:         PSTA_Segmentacion_cls.procesarSegmentoPorCambioAsesor(newListAccount, oldMapAccount);
0019:         system.debug('*********************END BEFORE UPDATE ACCOUNT PSTA*********************');
0020:     }
0021: }
```

### classes/PSTA_ListadoClientes_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   
0006: * Description       :   Clase que ejecuta
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         12-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public class PSTA_ListadoClientes_cls {
0013: 
0014:     public static Boolean bypassTriggerExecution = false;
0015: 
0016: 
0017:     public static final String ESTATUS_PENDIENTE                    = 'Pendiente';
0018:     public static final String ESTATUS_CONTACTO_NO_EXITOSO          = 'Contacto no exitoso';
0019:     public static final String ESTATUS_NO_QUIERE_SER_CONTACTADO     = 'Cliente no quiere ser contactado';
0020:     public static final String ESTATUS_CONTACTO_EFECTIVO_EXITOSO    = 'Contacto efectivo exitoso';
0021: 
0022: 
0023:     private static Id businessHoursId = PSTA_ListaClientesSelector_cls.getDiasLaborales();
0024: 
0025:     public static void actualizarFechaSiguienteContacto(List<Account> lstClientes, Map<Id, Account> oldMap) {
0026: 
0027:         if(bypassTriggerExecution == true) {
0028:             return;
0029:         }
0030:         
0031:         Map<String, Integer> mapSegmentoByFrecuenciaContacto = getMapSegmentoByFrecuenciaContacto();
0032:         
0033:         for(Account cuentaNueva : lstClientes) {
0034:             Account cuentaVieja = oldMap.get(cuentaNueva.Id);
0035: 
0036:             if(cuentaNueva.FechaUltimoContacto__c != null  && cuentaVieja.FechaUltimoContacto__c != cuentaNueva.FechaUltimoContacto__c)  {
0037:                 
0038:                 Integer frecuencia = mapSegmentoByFrecuenciaContacto.get(cuentaNueva.Segmento__c);
0039:                 cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
0040:                     cuentaNueva.FechaUltimoContacto__c,
0041:                     frecuencia,
0042:                     businessHoursId
0043:                  );
0044:                 
0045:                 
0046:             }
0047:         }
0048:         
0049:     }
0050: 
0051:     public static void actualizarFechaSiguienteVisita(List<Account> lstClientes, Map<Id, Account> oldMap) {
0052: 
0053:         if(bypassTriggerExecution == true) {
0054:             return;
0055:         }
0056: 
0057:         Map<String, Integer> mapSegmentoByFrecuenciaVisita = getMapSegmentoByFrecuenciaVisita();
0058:         
0059:         for(Account cuentaNueva : lstClientes) {
0060:             Account cuentaVieja = oldMap.get(cuentaNueva.Id);
0061: 
0062:             if(cuentaVieja.FechaUltimaVisita__c != cuentaNueva.FechaUltimaVisita__c) {
0063:                 
0064:                 Integer frecuencia = mapSegmentoByFrecuenciaVisita.get(cuentaNueva.Segmento__c);
0065:                 cuentaNueva.FechaSiguienteVisita__c = PSTA_UtilityClass.agregarDiasLaborales(
0066:                     cuentaNueva.FechaUltimaVisita__c,
0067:                     frecuencia,
0068:                     businessHoursId
0069:                  );
0070:                 
0071:             }
0072:         }
0073:     }
0074: 
0075:     public static void actualizarFechaNoQuiereSerContactado(List<Account> lstClientes, Map<Id, Account> oldMap) {
0076: 
0077:         if(bypassTriggerExecution == true) {
0078:             return;
0079:         }
0080:         
0081:         Map<String, Integer> mapSegmentoByFrecuenciaNoContacto = getMapSegmentoByFrecuenciaNoContacto();
0082:         
0083:         for(Account cuentaNueva : lstClientes) {
0084:             Account cuentaVieja = oldMap.get(cuentaNueva.Id);
0085:             
0086:             
0087:             if(cuentaVieja.EstatusContacto__c != cuentaNueva.EstatusContacto__c && cuentaNueva.EstatusContacto__c == ESTATUS_NO_QUIERE_SER_CONTACTADO && cuentaVieja.FechaNoRequiereSerContacto__c != cuentaNueva.FechaNoRequiereSerContacto__c) {
0088:                 
0089:                 Integer frecuencia = mapSegmentoByFrecuenciaNoContacto.get(cuentaNueva.Segmento__c);
0090:                 cuentaNueva.FechaSiguienteContacto__c = PSTA_UtilityClass.agregarDiasLaborales(
0091:                     System.today(),
0092:                     frecuencia,
0093:                     businessHoursId
0094:                 );
0095:                 
0096:                 cuentaNueva.FechaUltimoContacto__c = System.today();
0097:                 
0098:             }
0099:         }
0100:     }
0101: 
0102:     public static Map<String,Integer> getMapSegmentoByFrecuenciaContacto() {
0103:         List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
0104:         Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
0105:         for(ConfiguracionActinver__c config : lstConfigPostventa) {
0106:             mapMapSegmentoByFrecuencia.put(
0107:                 config.Segmento__c, 
0108:                 Integer.valueOf(config.FrecuenciaContacto__c)
0109:             );
0110:         }
0111: 
0112:         return mapMapSegmentoByFrecuencia;
0113:     }
0114: 
0115:     public static Map<String,Integer> getMapSegmentoByFrecuenciaVisita() {
0116:         List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
0117:         Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
0118:         for(ConfiguracionActinver__c config : lstConfigPostventa) {
0119:             mapMapSegmentoByFrecuencia.put(
0120:                 config.Segmento__c, 
0121:                 Integer.valueOf(config.FrecuenciaVisita__c)
0122:             );
0123:         }
0124: 
0125:         return mapMapSegmentoByFrecuencia;
0126:     }
0127: 
0128:     public static Map<String,Integer> getMapSegmentoByFrecuenciaNoContacto() {
0129:         List<ConfiguracionActinver__c> lstConfigPostventa = PSTA_ListaClientesSelector_cls.getConfiguracionPostVenta();
0130:         Map<String, Integer> mapMapSegmentoByFrecuencia = new Map<String, Integer>();
0131:         for(ConfiguracionActinver__c config : lstConfigPostventa) {
0132:             mapMapSegmentoByFrecuencia.put(
0133:                 config.Segmento__c, 
0134:                 Integer.valueOf(config.FrecReinicioNoReqContacto__c)
0135:             );
0136:         }
0137: 
0138:         return mapMapSegmentoByFrecuencia;
0139:     }
0140: }
```

### classes/PSTA_ListaClientesSelector_cls.cls
```text
0001: /******************************************************************************* 
0002: * Developed by      :   VASS México
0003: * Author            :   Canche Isaac
0004: * Project           :   Post Venta
0005: * Clase test		:   
0006: * Description       :   Clase SOQL para la segmentacion de clientes
0007: *--------------------------------------------------------------------------
0008: * No.            Date              Author                Description
0009: * 1.0         16-Jun-2025       Canche Isaac              Creación
0010: *--------------------------------------------------------------------------
0011: *******************************************************************************/
0012: public without sharing class PSTA_ListaClientesSelector_cls {
0013: 
0014:     public static final Id idConfigContactoPostVentaRecordType = Schema.SObjectType.ConfiguracionActinver__c.getRecordTypeInfosByDeveloperName().get('ContactoPostventa').getRecordTypeId();
0015: 
0016:     public static Id getDiasLaborales(){
0017:         return [SELECT Id FROM BusinessHours WHERE Name = 'Postventa'].Id;
0018:     }
0019: 
0020:     public static List<ConfiguracionActinver__c> getConfiguracionPostVenta() {
0021:         return [
0022:             SELECT Segmento__c, FrecReinicioNoReqContacto__c, FrecuenciaContacto__c, FrecuenciaVisita__c 
0023:             FROM ConfiguracionActinver__c
0024:             WHERE RecordTypeId =: idConfigContactoPostVentaRecordType
0025:         ];
0026:     }
0027: 
0028: 
0029: }
```

### classes/OD_Account_thr.cls
```text
0001: /**
0002: * @File Name : OD_Account_thr.cls
0003: * @Description :Clase Handler del Trigger AccountTrigger.apxt
0004: * @Author : Andrés Hernandez Rios
0005: * @Last Modified By :
0006: * @Last Modified On : November 13, 2024
0007: * @Modification Log :
0008: *==============================================================================
0009: * Ver | Date | Author | Modification
0010: *==============================================================================
0011: * 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
0012: **/
0013: public without sharing class OD_Account_thr {
0014:     public static void onBeforeInsert(List<Account> newListAccount){
0015:         system.debug('*********************BEFORE INSERT ACCOUNT*********************');
0016:         OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,null);
0017:         OD_Account_cls.createAccounts(newListAccount);
0018:         OD_Account_cls.checkTotalPercent(newListAccount);
0019:         OD_Account_cls.convertMappingLeadToAccount(newListAccount);
0020:     }
0021:     public static void onBeforeUpdate(List<Account> newListAccount,Map<Id,Account> oldMapAccount){
0022:         system.debug('*********************BEFORE UPDATE ACCOUNT*********************');
0023:         OD_Account_cls.processToChangeOwnerFromAccount(newListAccount,oldMapAccount);
0024:         OD_Account_cls.checkTotalPercent(newListAccount);
0025:     }
0026: }
```

### classes/OD_Account_cls.cls
```text
0001: /**
0002: * @File Name : OD_Account_cls.cls
0003: * @Description :Clase service para el trigger de Account OD_Account_thr.apxc
0004: * @Author : Andrés Hernandez Rios
0005: * @Last Modified By :
0006: * @Last Modified On : November 13, 2024
0007: * @Modification Log :
0008: *==============================================================================
0009: * Ver | Date | Author | Modification
0010: *==============================================================================
0011: * 1.0 | November 13, 2024 |Andrés Hernández Ríos| Initial Version
0012: **/
0013: public without sharing class OD_Account_cls {
0014:     public static Boolean bypassTriggerExecution = false;
0015:   
0016:     // MÉTODO QUE PROCESA UNA LISTA DE CUENTAS (ACCOUNT) PARA CAMBIAR EL PROPIETARIO (OWNERID) Y LLENAR EL CAMPO BANQUERO.
0017:     public static void processToChangeOwnerFromAccount(List<Account> newListAccount,Map<Id,Account> oldMapAccount) {
0018:         // MAPAS PARA ALMACENAR DATOS RELACIONADOS CON USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER DE LOS BANQUEROS.
0019:         Map<String,BranchUnitBusinessMember> bankersBranchUnitMap = new Map<String,BranchUnitBusinessMember> ();
0020:         Map<String,BranchUnitBusinessMember> bankersBranchUnitOwnerMap = new Map<String,BranchUnitBusinessMember> ();
0021:         Map<String,User> usersByNominaMap = new Map<String,User>();
0022:         Map<String,Contact> contactsByNominaMap = new Map<String,Contact>();
0023:         Map<Id,User> usersByIdMap = new Map<Id,User>();
0024:         
0025:         // CONJUNTOS PARA ALMACENAR LOS ID ÚNICOS DE ASESORES Y PROPIETARIOS.
0026:         Set<String> uniqueAdvisorIds = new Set<String>();
0027:         Set<Id> uniqueOwnerIds = new Set<Id>();
0028:         
0029:         
0030:         // SI EL FLAG BYSPASS ESTÁ ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN LOS CONTRATOS.
0031:         if (bypassTriggerExecution) {
0032:             system.debug('BYPASS ACTIVADO, NO SE EJECUTARÁ EL TRIGGER EN CUENTAS');
0033:             return;
0034:         }
0035:         
0036:         // ITERAMOS SOBRE CADA CUENTA EN LA LISTA PROPORCIONADA
0037:         for(Account acc : newListAccount){
0038:             // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
0039:             system.debug(Service_Utility_Trigger.isCorrectRecordTypeId(acc));
0040:             if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){
0041:                 system.debug(acc.ID_ASESOR__c);
0042:                 // AGREGAMOS AL CONJUNTO DE ASESORES ÚNICOS SI TIENE EL ID_ASESOR
0043:                 if(String.isNotBlank(acc.ID_ASESOR__c)){
0044:                     uniqueAdvisorIds.add(acc.ID_ASESOR__c);
0045:                 } 
0046:                 // AGREGAMOS AL CONJUNTO DE PROPIETARIOS ÚNICOS SI TIENE EL OWNERID
0047:                 if(String.isNotBlank(acc.OwnerId)){
0048:                     uniqueOwnerIds.add(acc.OwnerId);
0049:                 }
0050:             }                
0051:         }
0052:         
0053:         // SI HAY PROPIETARIOS ÚNICOS, OBTENEMOS LOS USUARIOS CORRESPONDIENTES.
0054:         if(!uniqueOwnerIds.isEmpty()){
0055:             usersByIdMap = Service_Utility_Trigger.getUsersByOwnerIds(uniqueOwnerIds);
0056:             bankersBranchUnitOwnerMap = Service_Utility_Trigger.getBranchUnitByOwnerId(uniqueOwnerIds);
0057:         }
0058:         
0059:         // SI HAY ASESORES ÚNICOS, OBTENEMOS LOS USUARIOS, CONTACTOS Y BRANCHUNITBUSINESSMEMBER.
0060:         if(!uniqueAdvisorIds.isEmpty()){
0061:             usersByNominaMap = Service_Utility_Trigger.getUsersByNomina(uniqueAdvisorIds);
0062:             contactsByNominaMap = Service_Utility_Trigger.getContactsByNomina(uniqueAdvisorIds);
0063:             bankersBranchUnitMap = Service_Utility_Trigger.getBranchUnitByCFYJobCode(uniqueAdvisorIds);
0064:         }
0065:         system.debug('bankersBranchUnitOwnerMap'+bankersBranchUnitOwnerMap);
0066:         system.debug('bankersBranchUnitMap:'+bankersBranchUnitMap);
0067:         // PROCESAMOS CADA CUENTA NUEVAMENTE PARA CAMBIAR EL PROPIETARIO Y REALIZAR VALIDACIONES.
0068:         for(Account acc : newListAccount){
0069:             
0070:             // VERIFICAMOS SI LA CUENTA TIENE UN TIPO DE REGISTRO VÁLIDO
0071:             if(Service_Utility_Trigger.isCorrectRecordTypeId(acc)){
0072:                 // SI ENCONTRAMOS EL USUARIO CON EL ID_ASESOR, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
0073:                 if(usersByNominaMap.containsKey(acc.ID_ASESOR__c)){
0074: 
0075:                     if(oldMapAccount != null && oldMapAccount.containsKey(acc.Id) && oldMapAccount.get(acc.Id).OwnerId != acc.OwnerId){
0076:                         system.debug('*************ENCUENTRA EL USUARIO PERO HAY CAMBIO PROPIETARIO*************');
0077:                         acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id; 
0078:                         if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
0079:                             acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
0080:                         }else{
0081:                             acc.addError('Hay un error en Banker ó no hay relación en el cambio de Propietario, favor de verificar');
0082:                         }
0083:                     }else{
0084:                         system.debug('*************ENCUENTRA EL USUARIO CON EL ID_ASESOR*************'+usersByNominaMap.get(acc.ID_ASESOR__c).Name);
0085:                         acc.OwnerId = usersByNominaMap.get(acc.ID_ASESOR__c).Id;  
0086:                         if(bankersBranchUnitMap.containskey(acc.ID_Asesor__c)){
0087:                             acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;              
0088:                         }else{
0089:                             acc.addError('Hay un error en Banker ó no hay relación en la actualización de Id Asesor, favor de verificar');
0090:                         }
0091:                     }
0092:                 }   
0093:                 
0094:                 // SI ENCONTRAMOS EL CONTACTO CON EL ID_ASESOR PERO NO EL USUARIO, VERIFICAMOS SI HAY UNA UNIDAD DE SUCURSAL.
0095:                 else if(contactsByNominaMap.containsKey(acc.ID_ASESOR__c)){
0096:                     system.debug('*************ENCUENTRE EL CONTACTO SIN LICENCIA CON EL ID_ASESOR*************');                
0097:                     // SI HAY UNA UNIDAD DE SUCURSAL RELACIONADA CON EL ASESOR, ACTUALIZAMOS LA CUENTA.
0098:                     if(bankersBranchUnitMap.containsKey(acc.ID_ASESOR__c)){
0099:                         acc.BanqueroAsignado__c = bankersBranchUnitMap.get(acc.ID_ASESOR__c).Id;
0100:                         acc.OwnerId = usersByNominaMap.get(Service_Utility_Trigger.DEFAULT_USER_NAME).Id;                    
0101:                     } else {
0102:                         // SI NO SE ENCUENTRA LA UNIDAD DE SUCURSAL, AGREGAMOS UN ERROR.
0103:                         acc.addError('Hay un error en Banker ó no hay relación Id Asesor, favor de verificar (Contacto Temporal)');
0104:                     }
0105:                 }
0106:                 
0107:                 // SI ENCONTRAMOS EL USUARIO CON EL OWNERID ORIGINAL, ACTUALIZAMOS EL OWNERID DE LA CUENTA CON EL ID DEL USUARIO.
0108:                 else if(usersByIdMap.containsKey(acc.OwnerId)){
0109:                     system.debug('*************ENCUENTRA EL USUARIO CON EL OWNERID*************');
0110:                     acc.OwnerId = usersByIdMap.get(acc.OwnerId).Id;
0111:                     if(bankersBranchUnitOwnerMap.containskey(acc.OwnerId)){
0112:                         acc.BanqueroAsignado__c = bankersBranchUnitOwnerMap.get(acc.OwnerId).Id;              
0113:                     }else{
0114:                         acc.addError('Hay un error en Banker ó no hay relación Propietario, favor de verificar');
0115:                     }             
0116:                 }
0117:                 
0118:                 // SI NO SE ENCUENTRA NI EL USUARIO NI EL CONTACTO RELACIONADO, AGREGAMOS UN ERROR.
0119:                 else {
0120:                     acc.adderror('No se encontró el usuario ni el contacto de alguna cuenta');                
0121:                 }
0122:             }            
0123:         }  
0124:          bypassTriggerExecution = true;
0125:     }
0126:     /**
0127: 	 * Check if the total percentage is above 100%
0128: 	 */
0129: 	public static void checkTotalPercent(List<Account> newListAccount) {
0130: 		Decimal decActinverMexico = 0;
0131: 		Decimal decActinverMadrid = 0;
0132: 		Decimal decActinverSecurities = 0;
0133: 		Decimal decInstitucionesNacionales = 0;
0134: 		Decimal decInstitucionesInternaciononales = 0;
0135: 
0136: 		for (Account accObj : newListAccount) {
0137: 			// if all the fields are null, skip the check
0138: 			if (
0139: 				accObj.Actinver_Mexico__c == null &&
0140: 				accObj.Actinver_Madrid__c == null &&
0141: 				accObj.Actinver_Securities__c == null &&
0142: 				accObj.Instituciones_Nacionales__c == null &&
0143: 				accObj.Instituciones_Internaciononales__c == null
0144: 			) {
0145: 				continue;
0146: 			}
0147: 
0148: 			// Only persona accout need this check
0149: 			if (accObj.IsPersonAccount) {
0150: 				decActinverMexico = (accObj.Actinver_Mexico__c == null) ? 0 : accObj.Actinver_Mexico__c;
0151: 				decActinverMadrid = (accObj.Actinver_Madrid__c == null) ? 0 : accObj.Actinver_Madrid__c;
0152: 				decActinverSecurities = (accObj.Actinver_Securities__c == null) ? 0 : accObj.Actinver_Securities__c;
0153: 				decInstitucionesNacionales = (accObj.Instituciones_Nacionales__c == null) ? 0 : accObj.Instituciones_Nacionales__c;
0154: 				decInstitucionesInternaciononales = (accObj.Instituciones_Internaciononales__c == null)
0155: 					? 0
0156: 					: accObj.Instituciones_Internaciononales__c;
0157: 
0158: 				if (
0159: 					(decActinverMexico +
0160: 					decActinverMadrid +
0161: 					decActinverSecurities +
0162: 					decInstitucionesNacionales +
0163: 					decInstitucionesInternaciononales) != 100
0164: 				) {
0165: 					accObj.addError(Label.CheckTotalPercent);
0166: 				}
0167: 			}
0168: 		}
0169: 	}
0170:     public static void createAccounts(List<Account> newListAccount) {
0171:         for (Account a : newListAccount) {
0172:             if (a.Person_Type__c == 'MORAL') {
0173:                 a.Name = a.BusinessName__c;
0174:                 a.PersonBirthdate = null;
0175:                 System.debug(JSON.serializePretty(a));
0176:             }
0177:             if (a.Person_Type__c == 'FISICA') {
0178:                 if (a.Nombre_Completo_Actinver__c != null) {
0179:                     a.FirstName = a.Nombre_Completo_Actinver__c.length() >= 40
0180:                         ? a.Nombre_Completo_Actinver__c.substring(0, 39)
0181:                         : a.Nombre_Completo_Actinver__c;
0182:                 }
0183:             }
0184:         }
0185:     }
0186:     public static void convertMappingLeadToAccount(List<Account> newListAccount) {
0187:         system.debug('############### convertMappingLeadToAccount ###################');
0188:         Map<String,Lead> mapAccountIdByLeads = new Map<String,Lead>();
0189:         Set<String> setAccountIds = new Set<String>();
0190:         Lead[] lstLead = new List<Lead>();
0191:         for(Account objAccount : newListAccount)  setAccountIds.add(objAccount.ExternalIdLead__c);
0192: 
0193:         system.debug('#### setAccountIds: '+setAccountIds);
0194:         setAccountIds.remove(null);
0195:         if(!setAccountIds.isEmpty()) lstLead = getLeadByExternalId(setAccountIds);
0196: 
0197:         if(!lstLead.isEmpty()){
0198:             for(Lead objLead :lstLead) mapAccountIdByLeads.put(objLead.F3_Consecutivo_ID__c,objLead);
0199:             for(Account objAccount : newListAccount) setValuesOfConvertLead(mapAccountIdByLeads, objAccount);
0200:         } 
0201:     }
0202:     public static Lead[] getLeadByExternalId(Set<String> setAccountIds) {
0203:         Lead[] lstLead = [SELECT Id
0204:                     , toLabel(F3_Estado_Civil__c)   //objAccount.MaritalStatus__c
0205:                     , toLabel(Estado_Nacimiento__c) //objAccount.Birth_City__c
0206:                     , toLabel(Gender__c)            //objAccount.Gender__c
0207:                     , toLabel(F3_Nacionalidad__c)   //objAccount.Nationality__c
0208:                     , toLabel(Pais_Nacimiento__c)   //objAccount.Country_Birth__c
0209:                     , toLabel(Tipo_de_Persona__c)   //objAccount.Person_Type__c
0210:                     , F3_Consecutivo_ID__c
0211:                     , Fecha_Nacimiento_Prospecto__c 
0212:                 FROM Lead 
0213:                 WHERE F3_Consecutivo_ID__c IN :setAccountIds];
0214: 
0215:         system.debug('#### lstLead: '+lstLead.size());
0216:         return lstLead;
0217:     }
0218:     public static void setValuesOfConvertLead(Map<String,Lead> mapAccountIdByLeads,Account objAccount) {
0219:             Lead objLead = mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) != null ? mapAccountIdByLeads.get(objAccount.ExternalIdLead__c) : new Lead();
0220:             objAccount.MaritalStatus__c = objLead.F3_Estado_Civil__c;
0221:             objAccount.Birth_City__c    = objLead.Estado_Nacimiento__c;
0222:             objAccount.Nationality__c   = objLead.F3_Nacionalidad__c;
0223:             objAccount.Country_Birth__c = objLead.Pais_Nacimiento__c;
0224:             objAccount.Person_Type__c   = objLead.Tipo_de_Persona__c;
0225:             if(objAccount.IsPersonAccount) objAccount.PersonBirthdate = objLead.Fecha_Nacimiento_Prospecto__c;
0226:     }
0227: }
```

### classes/AccountRecordTypeAssigner.cls
```text
0001: public class AccountRecordTypeAssigner {
0002: 
0003:     public static void apply(List<Account> newList, Map<Id, Account> oldMap) {
0004:         if (newList == null || newList.isEmpty()) return;
0005: 
0006:         // 1) OwnerIds
0007:         Set<Id> ownerIds = new Set<Id>();
0008:         for (Account a : newList) {
0009:             if (a.OwnerId != null) ownerIds.add(a.OwnerId);
0010:         }
0011:         if (ownerIds.isEmpty()) return;
0012: 
0013:         // 2) Users -> ID_ASESOR__c
0014:         Map<Id, User> usersById = new Map<Id, User>([
0015:             SELECT Id, ID_ASESOR__c
0016:             FROM User
0017:             WHERE Id IN :ownerIds
0018:         ]);
0019: 
0020:         // 3) Nominas
0021:         Set<String> nominas = new Set<String>();
0022:         for (User u : usersById.values()) {
0023:             if (String.isNotBlank(u.ID_ASESOR__c)) nominas.add(u.ID_ASESOR__c.trim());
0024:         }
0025: 
0026:         // 4) Bankers por ExternalId__c (nomina)
0027:         Map<String, Banker> bankerByNomina = new Map<String, Banker>();
0028:         if (!nominas.isEmpty()) {
0029:             for (Banker b : [
0030:                 SELECT ExternalId__c, Division__c
0031:                 FROM Banker
0032:                 WHERE ExternalId__c IN :nominas
0033:             ]) {
0034:                 bankerByNomina.put(b.ExternalId__c, b);
0035:             }
0036:         }
0037: 
0038:         // 5) Caches CMDT
0039:         Map<String, String> divisionToDev = getDivisionToRtDevName();
0040:         Map<String, String> defaults = getDefaults();
0041:         Map<String, Id> rtIds = getAccountRtIds();
0042: 
0043:         for (Account a : newList) {
0044:             Account oldA = (oldMap == null ? null : oldMap.get(a.Id));
0045: 
0046:         Boolean shouldRecalc =
0047:         oldMap == null ||                // insert
0048:         a.RecordTypeId == null ||        // sin RT
0049:         (oldA != null && a.OwnerId != oldA.OwnerId) ||                // cambió owner
0050:         (oldA != null && a.ID_ASESOR__c != oldA.ID_ASESOR__c);        // ✅ cambió asesor
0051: 
0052:             if (!shouldRecalc) continue;
0053: 
0054:             User u = usersById.get(a.OwnerId);
0055:             String nomina = (u != null) ? u.ID_ASESOR__c : null;
0056: 
0057:             String targetDevName;
0058: 
0059:             // División
0060:             if (String.isNotBlank(nomina)) {
0061:                 Banker b = bankerByNomina.get(nomina.trim());
0062:                 if (b != null && String.isNotBlank(b.Division__c)) {
0063:                     targetDevName = divisionToDev.get(b.Division__c.trim());
0064:                 }
0065:             }
0066: 
0067:             // Fallback
0068:             if (String.isBlank(targetDevName)) {
0069:                 String key = a.IsPersonAccount ? 'DEFAULT_PERSON' : 'DEFAULT_BUSINESS';
0070:                 targetDevName = defaults.get(key);
0071:             }
0072: 
0073:             Id rtId = rtIds.get(targetDevName);
0074:             if (rtId != null) {
0075:                 a.RecordTypeId = rtId;
0076:             }
0077:         }
0078:     }
0079: 
0080:     private static Map<String, String> getDivisionToRtDevName() {
0081:         Map<String, String> m = new Map<String, String>();
0082:         for (AdvisorDivision_RecordType__mdt r : [
0083:             SELECT Division__c, RecordTypeDeveloperName__c
0084:             FROM AdvisorDivision_RecordType__mdt
0085:         ]) {
0086:             if (String.isNotBlank(r.Division__c)) {
0087:                 m.put(r.Division__c.trim(), r.RecordTypeDeveloperName__c);
0088:             }
0089:         }
0090:         return m;
0091:     }
0092: 
0093:     private static Map<String, String> getDefaults() {
0094:         Map<String, String> m = new Map<String, String>();
0095:         for (Account_RecordType_Config__mdt r : [
0096:             SELECT Key__c, RecordTypeDeveloperName__c
0097:             FROM Account_RecordType_Config__mdt
0098:         ]) {
0099:             m.put(r.Key__c, r.RecordTypeDeveloperName__c);
0100:         }
0101:         return m;
0102:     }
0103: 
0104:     private static Map<String, Id> getAccountRtIds() {
0105:         Map<String, Id> m = new Map<String, Id>();
0106:         for (Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfos()) {
0107:             if (rti.isAvailable()) {
0108:                 m.put(rti.getDeveloperName(), rti.getRecordTypeId());
0109:             }
0110:         }
0111:         return m;
0112:     }
0113: }
```

### classes/EventLogger.cls
```text
0001: /****************************************************************************************************
0002: Desarrollado por :  VASS MÉXICO
0003: Proyecto         :  Actinver
0004: Descripción      :  Clase para guardar registros de errores en eventos como WS o excepciones
0005: 
0006: Cambios (Versiones)
0007: -----------------------------------------------------------------------------------------------------
0008: No.     Fecha           Autor                   Descripción
0009: -----   ----------      --------------------    -----------------------------------------------------
0010: 1.0     2024-08-14      VASS MÉXICO			    Creación de la Clase.            /survys?BR=001                            
0011: */
0012: public without sharing class EventLogger {
0013:     private static final String CLASSNAME = EventLogger.class.getName();
0014: 	private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');
0015:     /**
0016: 	* @description: Logs an error associated to a map with error information. Result in a WebServiceTrackingLog__c record being inserted
0017: 	* @param Map<String String> logErrorMap 
0018: 	**/
0019: 	public static void error(Map<String, String> logErrorMap) {
0020: 		error(logErrorMap, new List<Object>());
0021: 	}
0022:     /**
0023: 	* @description: Registra un error asociado a un mapa con información de error y una lista de información asociada. Resultado en la inserción de un registro WebServiceTrackingLog__c
0024: 	* @param Map<String String> logErrorMap 
0025: 	* @param List<Object> values 
0026: 	**/
0027: 	public static void error(Map<String, String> logErrorMap, List<Object> values) {
0028: 		String type = logErrorMap.get('type');
0029: 		WebServiceTrackingLog__c log = newLog(logErrorMap.get('message'), logErrorMap.get('request'), values, logErrorMap.get('contextId'), type);
0030: 		if(type == 'Medallia') {
0031: 			setMedalliaData(log, logErrorMap);
0032: 		}
0033:         // if(type == 'Generico'){
0034: 		// 	setTransferData(log, logErrorMap);
0035: 		// }
0036: 		insertLogs(new List<WebServiceTrackingLog__c>{ log });
0037: 	}
0038: 	/**
0039: 	* @description: Add customized onboarding error information to new log
0040: 	* @param WebServiceTrackingLog__c log 
0041: 	* @param Map<String String> logErrorMap 
0042: 	* @param String type 
0043: 	* @return WebServiceTrackingLog__c 
0044: 	**/
0045: 	public static WebServiceTrackingLog__c setMedalliaData(WebServiceTrackingLog__c log, Map<String, String> logErrorMap) {
0046: 		log.RecordTypeId = getRecordTypeId('Medallia');
0047: 		if(logErrorMap.get('contextId') != null && logErrorMap.get('contextId') != '') {
0048: 			log.Visita__c = Id.valueOf(logErrorMap.get('contextId'));
0049: 		}
0050: 		log.Code__c = (logErrorMap.get('errorCode') != null && logErrorMap.get('errorCode') != '') ? logErrorMap.get('errorCode') : '';
0051: 		return log;
0052: 	}
0053: 	/**
0054: 	* @description: Crear nuevo registro con información básica
0055: 	* @param String message 
0056: 	* @param List<Object> values 
0057: 	* @param Id contextId 
0058: 	* @return WebServiceTrackingLog__c 
0059: 	**/
0060: 	public static WebServiceTrackingLog__c newLog(String message, String request, List<Object> values, Id contextId, String type) {
0061:         WebServiceTrackingLog__c log = new WebServiceTrackingLog__c();
0062:         log.Name        = 'Log ' + getTimestamp();
0063:         log.Message__c  = (message != null && message != '') ? message + (!values.isEmpty() ? ' ; ' + cast(values) : '') : '';
0064:         log.Request__c  = !String.isBlank(request) ? request : '';
0065:         log.Type__c     = (type != null && type != '') ? type : '';
0066:         populateLocation(log);
0067:         return log;
0068:     }
0069:     /**
0070:     * @description: Devuelve una marca de tiempo formateada
0071:     * @return String 
0072:     **/
0073:     public static String getTimestamp() {
0074:         return String.valueOf(System.now().format('dd/MM/yyyy HH:mm:ss'));
0075:     }
0076:      /**
0077:     * @description: Lista de formato de información asociada
0078:     * @param List<Object> values 
0079:     * @return List<String> 
0080:     **/
0081:     public static List<String> cast(List<Object> values) {
0082:         List<String> result = new List<String>();
0083: 		if(values != null) {
0084: 			for(Object value : values) {
0085: 				result.add(' ' + value);
0086: 			}
0087: 		}
0088:         return result;
0089:     }
0090:     /**
0091:     * @description: Agrega la ubicación del punto en el que ocurrió el error.
0092:     * @param WebServiceTrackingLog__c log 
0093:     **/
0094:     public static void populateLocation(WebServiceTrackingLog__c log) {
0095:         List<String> traceList = new DmlException().getStackTraceString().split('\n');
0096:         for(String line : traceList) {
0097:             Matcher matcher = STACK_LINE.matcher(line);
0098:             if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.')) {
0099:                 log.Class__c = matcher.group(1);
0100:                 log.Method__c = getPrettyMethod(matcher.group(2));
0101:                 log.Line__c = Integer.valueOf(matcher.group(4));
0102:                 return;
0103:             }
0104:         }
0105:     }
0106:     /**
0107:     * @description: Embellezca el campo del método para evitar nombres nulos o no deseados
0108:     * @param String method 
0109:     * @return String 
0110:     **/
0111:     public static String getPrettyMethod(String method) {
0112:         return (method == null) ? 'anonymous' : method;
0113:     }
0114: 
0115:     /**
0116:     * @description: Inserta nuevos registros de error con la información proporcionada.
0117:     * @param List<WebServiceTrackingLog__c> logsToInsert 
0118:     **/
0119:     public static void insertLogs(List<WebServiceTrackingLog__c> logsToInsert) {
0120: 		Database.SaveResult[] insertList = Database.insert (logsToInsert, false);
0121: 		for(Database.SaveResult saveResult : insertList) {
0122: 			if(!saveResult.isSuccess()) {
0123: 				System.debug('Unable to save Log: ' + saveResult.getErrors());
0124: 			}
0125: 		}
0126:     }
0127:      /**
0128:     * @description : Obtener ID de tipo de registro por nombre de desarrollador
0129:     * @param String developerName 
0130:     * @return Id 
0131:     **/
0132:     public static Id getRecordTypeId(String developerName) {
0133:         return Schema.SObjectType.WebServiceTrackingLog__c.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
0134:     }
0135: }
```
