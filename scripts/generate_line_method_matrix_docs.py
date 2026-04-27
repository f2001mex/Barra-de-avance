from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
SRC = ROOT / 'force-app' / 'main' / 'default'
DATE = '2026-03-13'

MANIFEST = {
    '1_PSTA_SegmentacionClientes_sch_fullcopy_ultra_detallado_linea_metodo_matriz_2026-03-13.md': {
        'base': DOCS / f'1_PSTA_SegmentacionClientes_sch_fullcopy_ultra_detallado_codigo_fuente_{DATE}.md',
        'process': 'PSTA_SegmentacionClientes_sch',
        'files': [
            'classes/PSTA_SegmentacionClientes_sch.cls',
            'classes/PSTA_SegmentacionClientes_bch.cls',
            'classes/PSTA_SegmentacionClientesSelector_cls.cls',
            'classes/PSTA_SegmentacionClientes_cls.cls',
            'classes/PSTA_FechaPrimerContacto_cls.cls',
            'classes/PSTA_Segmentacion_cls.cls',
            'classes/PSTA_AgrupacionPriorizacionMensual_bch.cls',
            'classes/PSTA_PriorizacionMensual_cls.cls',
            'classes/PSTA_PriorizacionSelector_cls.cls',
            'triggers/AccountTrigger.trigger',
            'classes/PSTA_Account_thr.cls',
            'classes/PSTA_ListadoClientes_cls.cls',
            'classes/PSTA_ListaClientesSelector_cls.cls',
            'classes/OD_Account_thr.cls',
            'classes/OD_Account_cls.cls',
            'classes/AccountRecordTypeAssigner.cls',
            'classes/EventLogger.cls',
        ],
    },
    '2_PSTA_ResetearEstatusContacto_sch_fullcopy_ultra_detallado_linea_metodo_matriz_2026-03-13.md': {
        'base': DOCS / f'2_PSTA_ResetearEstatusContacto_sch_fullcopy_ultra_detallado_codigo_fuente_{DATE}.md',
        'process': 'PSTA_ResetearEstatusContacto_sch',
        'files': [
            'classes/PSTA_ResetearEstatusContacto_sch.cls',
            'classes/ACT_BusinessHoursHelper_cls.cls',
            'classes/PSTA_ResetearEstatusContacto_bch.cls',
            'classes/PSTA_ResetearEstatusContacto_cls.cls',
            'classes/PSTA_AgrupacionPriorizacionDiaria_bch.cls',
            'classes/PSTA_PriorizacionDiaria_cls.cls',
            'classes/PSTA_PriorizacionSelector_cls.cls',
            'classes/PSTA_SegmentacionClientesSelector_cls.cls',
            'triggers/AccountTrigger.trigger',
            'classes/PSTA_Account_thr.cls',
            'classes/PSTA_ListadoClientes_cls.cls',
            'classes/PSTA_ListaClientesSelector_cls.cls',
            'classes/OD_Account_thr.cls',
            'classes/OD_Account_cls.cls',
            'classes/AccountRecordTypeAssigner.cls',
            'classes/EventLogger.cls',
        ],
    },
    '3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_linea_metodo_matriz_2026-03-13.md': {
        'base': DOCS / f'3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_codigo_fuente_{DATE}.md',
        'process': 'PV_GenerarTareasPeriodicas_sch',
        'files': [
            'classes/PV_GenerarTareasPeriodicas_sch.cls',
            'classes/ACT_BusinessHoursHelper_cls.cls',
            'classes/PV_GenerarTareasPeriodicas_bch.cls',
            'classes/PV_GenerarTareasPeriodicas.cls',
            'classes/PV_GenerarTareasPeriodicasSelector_cls.cls',
            'classes/PV_EjecutarAsignacionCadencias_Queueable.cls',
            'classes/PV_GenerarTareasPeriodicas_Request.cls',
            'flows/PV_AsignarCadencesCuentas_Flow.flow-meta.xml',
            'triggers/TriggerActionCadanceStepTracker.trigger',
            'classes/TriggerActionCadenceStepTracker_thr.cls',
            'classes/PSTA_GestionTareas_Helper.cls',
            'classes/PSTA_GestionTareas_soql.cls',
            'triggers/Task_trg.trigger',
            'classes/Task_thr.cls',
            'classes/PSTA_ChangeAccountInfo_ctr.cls',
            'classes/PSTA_ChangeAccountInfo_helper.cls',
            'classes/PSTA_ChangeAccountInfo_soql.cls',
            'flows/Flow_Avance_FAC.flow-meta.xml',
            'flows/FAC_Update_Task_Field_Avence.flow-meta.xml',
            'flows/FAC_Task_Update_InAccount.flow-meta.xml',
            'flows/FAC_Task_Update_InTask.flow-meta.xml',
            'classes/ACTCompleteCadenceForAccounts.cls',
        ],
    },
    '4_PSTA_RegistroResumenGlobal_sch_fullcopy_ultra_detallado_linea_metodo_matriz_2026-03-13.md': {
        'base': DOCS / f'4_PSTA_RegistroResumenGlobal_sch_fullcopy_ultra_detallado_codigo_fuente_{DATE}.md',
        'process': 'PSTA_RegistroResumenGlobal_sch',
        'files': [
            'classes/PSTA_RegistroResumenGlobal_sch.cls',
            'classes/ACT_BusinessHoursHelper_cls.cls',
            'classes/PSTA_RegistroResumenGlobal_bch.cls',
            'classes/PSTA_RegistroResumenGlobal_cls.cls',
            'classes/PSTA_SegmentacionClientesSelector_cls.cls',
            'classes/EventLogger.cls',
        ],
    },
}

CONTROL_WORDS = {'if', 'for', 'while', 'switch', 'catch', 'return', 'else', 'do', 'try'}
METHOD_RE = re.compile(r'^\s*(?:global|public|private|protected|webservice|testMethod|static|virtual|override|abstract|final|with sharing|without sharing|inherited sharing|transient|@AuraEnabled|@InvocableMethod|@InvocableVariable|@TestVisible|\s)+\s*(?:[\w<>,\[\]\.?]+\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*\((?P<params>[^)]*)\)\s*\{')
CONSTRUCTOR_TEMPLATE = r'^\s*(?:global|public|private|protected)\s+{name}\s*\((?P<params>[^)]*)\)\s*\{{'
TRIGGER_RE = re.compile(r'^\s*trigger\s+(?P<name>\w+)\s+on\s+(?P<object>\w+)\s*\((?P<events>[^)]*)\)')
FLOW_TAGS = ['actionCalls', 'assignments', 'decisions', 'recordLookups', 'recordUpdates', 'loops', 'start']


def load_text(path: Path) -> list[str]:
    return path.read_text(encoding='utf-8', errors='replace').splitlines()


def line_numbered(lines: list[str]) -> str:
    return '\n'.join(f'{idx+1:04d}: {line}' for idx, line in enumerate(lines))


def method_end(lines: list[str], start_idx: int) -> int:
    depth = 0
    seen_open = False
    for i in range(start_idx, len(lines)):
        line = lines[i]
        depth += line.count('{')
        if line.count('{'):
            seen_open = True
        depth -= line.count('}')
        if seen_open and depth <= 0:
            return i + 1
    return len(lines)


def parse_apex(path: Path, lines: list[str]) -> list[dict]:
    class_name = path.stem.split('.')[0]
    ctor_re = re.compile(CONSTRUCTOR_TEMPLATE.format(name=re.escape(class_name)))
    methods = []
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('*') or stripped.startswith('/*'):
            continue
        if '@' in stripped and stripped.startswith('@'):
            continue
        m = METHOD_RE.match(line)
        ctor = ctor_re.match(line)
        if ctor:
            name = class_name
            params = ctor.group('params').strip()
        elif m:
            name = m.group('name')
            params = m.group('params').strip()
            if name in CONTROL_WORDS:
                continue
        else:
            continue
        end = method_end(lines, idx)
        body = lines[idx:end]
        methods.append({
            'name': name,
            'start': idx + 1,
            'end': end,
            'signature': stripped,
            'params': params,
            'body': body,
        })
    return methods


def parse_trigger(lines: list[str]) -> list[dict]:
    items = []
    for idx, line in enumerate(lines):
        m = TRIGGER_RE.match(line)
        if m:
            items.append({
                'name': m.group('name'),
                'start': idx + 1,
                'end': method_end(lines, idx),
                'signature': line.strip(),
                'params': m.group('events').strip(),
                'body': lines[idx:method_end(lines, idx)],
            })
    return items


def parse_flow(lines: list[str]) -> list[dict]:
    items = []
    for tag in FLOW_TAGS:
        pattern = f'<{tag}>'
        idx = 0
        while idx < len(lines):
            if pattern in lines[idx]:
                start = idx
                name = tag
                end_tag = f'</{tag}>'
                j = idx
                element_name = None
                while j < len(lines):
                    if '<name>' in lines[j] and '</name>' in lines[j] and element_name is None:
                        element_name = re.sub(r'.*<name>(.*?)</name>.*', r'\1', lines[j]).strip()
                    if end_tag in lines[j]:
                        break
                    j += 1
                items.append({
                    'name': element_name or name,
                    'start': start + 1,
                    'end': min(j + 1, len(lines)),
                    'signature': f'{tag}:{element_name or name}',
                    'params': '',
                    'body': lines[start:min(j + 1, len(lines))],
                })
                idx = j + 1
            else:
                idx += 1
    return items


def classify_queries(body: list[str]) -> list[str]:
    queries = []
    text = '\n'.join(body)
    if 'SELECT ' in text or 'FROM ' in text:
        for line in body:
            s = line.strip()
            if 'SELECT ' in s or s.startswith('return [SELECT') or 'Database.query' in s or 'Database.getQueryLocator' in s:
                queries.append(s)
    return dedupe(queries)


def classify_dml(body: list[str]) -> list[str]:
    hits = []
    pats = ['insert ', 'update ', 'upsert ', 'delete ', 'undelete ', 'merge ', 'Database.update', 'Database.upsert', 'Database.insert', 'Database.executeBatch', 'System.enqueueJob', 'EventBus.publish']
    for line in body:
        s = line.strip()
        if any(p in s for p in pats):
            hits.append(s)
    return dedupe(hits)


def classify_side_effects(body: list[str]) -> list[str]:
    hits = []
    pats = ['EventLogger.error', 'Flow.Interview', 'Messaging.CustomNotification', 'BusinessHours.', 'assignTargetToSalesCadence', 'Trigger.', 'Schema.', 'PSTA_EnvioEncuestaMedallia_cls.sendSurvey']
    for line in body:
        s = line.strip()
        if any(p in s for p in pats):
            hits.append(s)
    return dedupe(hits)


def infer_purpose(file_rel: str, artifact: dict) -> str:
    n = artifact['name']
    sig = artifact['signature']
    if n == 'start':
        return 'Obtiene el universo inicial del proceso; normalmente arma QueryLocator o selecciona registros fuente.'
    if n == 'execute':
        return 'Ejecuta la logica principal del batch/scheduler/queueable sobre el scope o contexto actual.'
    if n == 'finish':
        return 'Cierra el proceso actual; puede encadenar batches, dejar trazas o completar efectos posteriores.'
    if n.startswith('get'):
        return 'Metodo orientado a lectura/consulta; centraliza acceso a configuracion, metadata o registros.'
    if n.startswith('update'):
        return 'Metodo orientado a persistencia; aplica DML parcial o total sobre registros preparados previamente.'
    if n.startswith('save'):
        return 'Metodo orientado a registro de errores, logging o persistencia auxiliar.'
    if 'Flow.Interview' in '\n'.join(artifact['body']):
        return 'Invoca un Flow desde Apex para continuar el proceso en capa declarativa.'
    if 'EventBus.publish' in '\n'.join(artifact['body']):
        return 'Publica eventos de plataforma para propagar el resultado del proceso a consumidores posteriores.'
    if file_rel.endswith('.trigger'):
        return 'Punto de entrada trigger; enruta el evento del objeto/plataforma a la clase manejadora.'
    if file_rel.endswith('.flow-meta.xml'):
        return 'Elemento declarativo del Flow que controla decisiones, lookups, updates o acciones estándar.'
    return 'Metodo/elemento participante en la orquestacion o transformacion del proceso.'


def dedupe(items: list[str]) -> list[str]:
    seen = set()
    out = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out


def artifact_parser(path: Path, lines: list[str]) -> list[dict]:
    if path.suffix == '.cls':
        return parse_apex(path, lines)
    if path.suffix == '.trigger':
        return parse_trigger(lines)
    if path.name.endswith('.flow-meta.xml'):
        return parse_flow(lines)
    return []


def build_matrix(files: list[str]) -> list[str]:
    rows = ['| Archivo | Metodo/Elemento | Lineas | Query/Read | DML/Ejecucion | Side effects |', '|---|---|---:|---|---|---|']
    for rel in files:
        path = SRC / rel
        if not path.exists():
            rows.append(f'| {rel} | NO ENCONTRADO | - | - | - | - |')
            continue
        lines = load_text(path)
        artifacts = artifact_parser(path, lines)
        if not artifacts:
            rows.append(f'| {rel} | Archivo sin parser especifico | 1-{len(lines)} | - | - | - |')
            continue
        for art in artifacts:
            q = '<br>'.join(classify_queries(art['body'])[:3]) or '-'
            d = '<br>'.join(classify_dml(art['body'])[:3]) or '-'
            s = '<br>'.join(classify_side_effects(art['body'])[:3]) or '-'
            rows.append(f"| {rel} | {art['name']} | {art['start']}-{art['end']} | {q.replace('|','/')} | {d.replace('|','/')} | {s.replace('|','/')} |")
    return rows


for out_name, cfg in MANIFEST.items():
    base_text = cfg['base'].read_text(encoding='utf-8')
    sections = [base_text.rstrip(), '', '## 10. Desglose por metodo con lineas y comportamiento', 'Esta seccion agrega un inventario metodo por metodo, con lineas de inicio/fin, foco funcional y rastreo de query, DML y side effects.']
    for rel in cfg['files']:
        path = SRC / rel
        sections.extend(['', f'### {rel}'])
        if not path.exists():
            sections.append('Archivo no encontrado en el workspace actual.')
            continue
        lines = load_text(path)
        artifacts = artifact_parser(path, lines)
        if not artifacts:
            sections.append('No se pudo generar inventario estructurado para este archivo. Se conserva el anexo de codigo completo en la seccion previa.')
            continue
        for art in artifacts:
            sections.append(f"- Metodo/Elemento: `{art['name']}`")
            sections.append(f"- Lineas: `{art['start']}-{art['end']}`")
            sections.append(f"- Firma: `{art['signature']}`")
            sections.append(f"- Funcion tecnica: {infer_purpose(rel, art)}")
            q = classify_queries(art['body'])
            d = classify_dml(art['body'])
            s = classify_side_effects(art['body'])
            sections.append(f"- Query/Read detectado: {('; '.join(q[:5])) if q else 'No detectado en el cuerpo del metodo/elemento.'}")
            sections.append(f"- DML/Ejecucion detectada: {('; '.join(d[:5])) if d else 'No detectado en el cuerpo del metodo/elemento.'}")
            sections.append(f"- Side effects detectados: {('; '.join(s[:5])) if s else 'No detectados en el cuerpo del metodo/elemento.'}")
    sections.extend(['', '## 11. Matriz tecnica granular archivo -> metodo -> query -> dml -> side effects'])
    sections.extend(build_matrix(cfg['files']))
    sections.extend(['', '## 12. Codigo numerado archivo por archivo', 'En esta seccion se replica el codigo con numeracion de lineas para facilitar trazabilidad exacta durante la revision tecnica.'])
    for rel in cfg['files']:
        path = SRC / rel
        sections.extend(['', f'### {rel}'])
        if not path.exists():
            sections.append('Archivo no encontrado en el workspace actual.')
            continue
        lines = load_text(path)
        sections.extend(['```text', line_numbered(lines), '```'])
    (DOCS / out_name).write_text('\n'.join(sections) + '\n', encoding='utf-8')
    print(DOCS / out_name)
