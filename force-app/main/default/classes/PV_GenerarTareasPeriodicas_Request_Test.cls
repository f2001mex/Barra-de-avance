@isTest
public class PV_GenerarTareasPeriodicas_Request_Test {

    @isTest static void testConstructorAndFields() {
        String cadence = 'cadence123';
        String target = '001xxxxxxxxxxxx'; // Ejemplo Id de Account
        String user = '005xxxxxxxxxxxx';   // Ejemplo Id de User

        PV_GenerarTareasPeriodicas_Request request = new PV_GenerarTareasPeriodicas_Request(cadence, target, user);

        System.assertEquals(cadence, request.salesCadenceNameOrId, 'El campo salesCadenceNameOrId debe asignarse correctamente');
        System.assertEquals(target, request.targetId, 'El campo targetId debe asignarse correctamente');
        System.assertEquals(user, request.userId, 'El campo userId debe asignarse correctamente');
    }
}