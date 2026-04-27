from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
SRC = ROOT / 'force-app' / 'main' / 'default'
DATE = '2026-03-13'

MANIFEST = {
    '1_PSTA_SegmentacionClientes_sch_fullcopy_ultra_detallado_codigo_fuente_2026-03-13.md': {
        'base': DOCS / f'1_PSTA_SegmentacionClientes_sch_fullcopy_ultra_detallado_{DATE}.md',
        'title': 'Anexo de codigo fuente completo',
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
    '2_PSTA_ResetearEstatusContacto_sch_fullcopy_ultra_detallado_codigo_fuente_2026-03-13.md': {
        'base': DOCS / f'2_PSTA_ResetearEstatusContacto_sch_fullcopy_ultra_detallado_{DATE}.md',
        'title': 'Anexo de codigo fuente completo',
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
    '3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_codigo_fuente_2026-03-13.md': {
        'base': DOCS / f'3_PV_GenerarTareasPeriodicas_sch_fullcopy_ultra_detallado_{DATE}.md',
        'title': 'Anexo de codigo fuente completo',
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
    '4_PSTA_RegistroResumenGlobal_sch_fullcopy_ultra_detallado_codigo_fuente_2026-03-13.md': {
        'base': DOCS / f'4_PSTA_RegistroResumenGlobal_sch_fullcopy_ultra_detallado_{DATE}.md',
        'title': 'Anexo de codigo fuente completo',
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

for out_name, cfg in MANIFEST.items():
    base_text = cfg['base'].read_text(encoding='utf-8')
    parts = [base_text.rstrip(), '', '## 9. ' + cfg['title'], 'Esta seccion agrega el codigo fuente completo de todos los artefactos que participan en el proceso analizado.']
    for rel in cfg['files']:
        path = SRC / rel
        if not path.exists():
            parts.extend(['', f'### Archivo no encontrado: {rel}', 'No existe localmente en el workspace actual.'])
            continue
        code = path.read_text(encoding='utf-8', errors='replace').rstrip()
        parts.extend([
            '',
            f'### {rel}',
            f'Ruta absoluta: {path}',
            '```text',
            code,
            '```',
        ])
    (DOCS / out_name).write_text('\n'.join(parts) + '\n', encoding='utf-8')
    print(DOCS / out_name)
