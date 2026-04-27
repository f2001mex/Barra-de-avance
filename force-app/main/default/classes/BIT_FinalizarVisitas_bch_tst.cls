/**
 * @Developed by  : VASS México
 * @Autor         : Canche Isaac
 * @Project       : BIT - Bitacora Anfitrion - Actinver
 * @Descripcion   : Clase test de la clase batch FinalizarVisitas
**/
@isTest
public class BIT_FinalizarVisitas_bch_tst {
    
    @testSetup
    private static void testSetup() {
        Id idRTVisitaProspecto  = Schema.getGlobalDescribe().get('Servicio__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Asesor').getRecordTypeId();
        Id idRTVisitaTercero  = Schema.getGlobalDescribe().get('Visita__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Tercero').getRecordTypeId();


        BranchUnit varBU = BIT_UtilityDataTest.createBranchUnit();
        // Crea Visitas de prueba
        List<Visita__c> visitas = new List<Visita__c>();
        for (Integer i = 0; i < 5; i++) {
            Visita__c visita = new Visita__c(Etapa__c = 'Iniciado', CentroFinanciero__c = varBU.Id, RecordTypeId = idRTVisitaTercero);
            visitas.add(visita);
        }
        insert visitas;
        
        // Crea Servicios de prueba asociados a las Visitas
        List<Servicio__c> servicios = new List<Servicio__c>();
        for (Visita__c visita : visitas) {
            for (Integer j = 0; j < 3; j++) {
                Servicio__c servicio = new Servicio__c(Visita__c = visita.Id,RecordTypeId = idRTVisitaProspecto, Etapa__c = 'Registro de visita', TipoVisita__c='Cliente', Motivo__c ='Asesoría Negocios Actuales', Submotivo__c = 'Seguimiento a Cuenta', QuienAtiende__c ='Asesor');
                servicios.add(servicio);
            }
        }
        insert servicios;
    }

    @isTest
    static void testBatch() {
        // Ejecutar el batch
        Test.startTest();
        BIT_FinalizarVisitas_bch batch = new BIT_FinalizarVisitas_bch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verificar que las Visitas se hayan actualizado a 'Finalizado'
        /*for (Visita__c visita : [SELECT Id, Etapa__c, FinalizadaScheduler__c FROM Visita__c]) {
            System.assertEquals('Finalizado', visita.Etapa__c, 'La etapa de la visita debe ser "Finalizado"');
            System.assertEquals(true, visita.FinalizadaScheduler__c, 'Se indico que finalizo por scheduler');
        }
        
        // Verificar que los Servicios asociados también se hayan actualizado
        for (Servicio__c servicio : [SELECT Id, Etapa__c, FinalizadoScheduler__c FROM Servicio__c]) {
            System.assertEquals('Finalizado', servicio.Etapa__c, 'La etapa del servicio debe ser "Finalizado"');
            System.assertEquals(true, servicio.FinalizadoScheduler__c, 'Se indico que finalizo por scheduler');

        }*/
    }
}