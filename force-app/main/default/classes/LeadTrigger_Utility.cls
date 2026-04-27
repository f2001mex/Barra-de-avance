/** ------------------------------------------------------------------------------------------------
 * @Name     LeadTrigger_Utility
 * @Author   Salvador Ramírez López (salvador.ramirez@vasscompany.com)
 * @Date     08/04/2025
 * @Group    VASS Latam
 *   ------------------------------------------------------------------------------------------------
 * @Description Clase de apoyo para la clase test LeadTrigger_Helper_Test
 * --------------------------------------------------------------------------
 * No.         Date             Author                             Description
 * 1.0         08/04/2025       salvador.ramirez@vasscompany.com   Class creation.
*--------------------------------------------------------------------------
 **/
public class LeadTrigger_Utility {
    public static Lead createLeadRTGeneral(){
        //Id recordTypeIdGeneral = ACTINVER_UtilityFactory_utils.getRecodType('Lead', 'Privada');
        Lead newLead = new Lead();
        newLead.FirstName = 'Test';
        newLead.LastName = 'Perez';
        newLead.MiddleName = 'Test';
        newLead.Suffix = 'Mendoza';
        newLead.OportunidadDeProspecto__c = true;
        newLead.LeadSource = 'Referenciado Cliente';
        newLead.F3_Nacionalidad__c = 'MX';
        newLead.Pais_Nacimiento__c = 'MX';
        newLead.F3_CURP__c = 'MOCV780623HDFSRC02';
        newLead.F3_RFC__c = 'MOCV780623';
        newLead.Email = 'josue.per@vasscompany.com';
        newLead.ClienteCreadoDeProspecto__c = true;
        newLead.Status = 'Contactado';
        newLead.Estado_Nacimiento__c = 'CHS';
        newLead.Prioridad__c = 'Baja';
        newLead.MobilePhone = '5544332299';
        newLead.Clasificacion_Persona__c = '4';
        newLead.MontoEstimadoDeInversion__c = 123;
        newLead.FechaEstimadaDeCierre__c = System.today().addDays(1);
        newLead.F3_Estado_Civil__c = '2';
        newLead.Fecha_Nacimiento_Prospecto__c = System.today().addyears(-40);
        newLead.Gender__c = '1';
        newLead.Tipo_de_Persona__c = '1';
        newLead.PostalCode = '12345';
        newLead.Phone = '2711768347';
        //newLead.RecordTypeId = recordTypeIdGeneral;
        newLead.F3_Consecutivo_ID__c = 'CRMPR-00000099';
        //insert newLead;
        return newLead;
    }
    public static F3_Integration_Service_Settings__c createService(){
        F3_Integration_Service_Settings__c service = new F3_Integration_Service_Settings__c();
        service.Name = 'crearClienteContrato';
        service.F3_URL__c = 'https://qa-api.actinver.com.mx/prospects/details';
        service.F3_Service_Type__c = 'ExternalRest';
        service.F3_Enable_Log__c = true;
        //insert service;
        return service;
    }
    public static User updateIDAsesorToUser(){
        User objUser = [SELECT ID, ID_ASESOR__C FROM USER WHERE ID = :System.UserInfo.getUserId()];
        objUser.ID_Asesor__c = '1234';
        return objUser;
    }
}