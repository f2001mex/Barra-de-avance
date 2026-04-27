/**
 * @description       : Clase para crear EmailMessage 
 * @author            : Martin Martinez.
 * @group             : VASS
 * @last modified on  : 02-12-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Version            : 1.0
**/
public with sharing class EmailMessageService {

    // Entrada de datos para Oportunidad y Lead
    public class EmailInput {
        @InvocableVariable(label='ID de Oportunidad' description='ID de la oportunidad a procesar.')
        public Id relatedId;

        @InvocableVariable(required=true label='ID de Plantilla de Correo' description='ID de la plantilla de correo que se desea utilizar.')
        public String emailTemplateId;

        @InvocableVariable(required=true label='Correo del Propietario' description='Correo del propietario de la oportunidad o lead.')
        public String ownerEmail;
        
        @InvocableVariable(required=true label='Correo del destinatario' description='Correo del destinatario de la oportunidad o lead.')
        public String clientEmail;

        @InvocableVariable(label='ID del Contacto' description='ID del contacto relacionado con la oportunidad, si aplica.')
        public Id contactId;

        @InvocableVariable(label='ID del Lead' description='ID del prospecto, si aplica.')
        public Id leadId;
    }

    // Método común para enviar correos (para Oportunidades o Leads)
    private static void sendEmail(Id relatedId, String emailTemplateId, String ownerEmail, String clientEmail, Id contactId, Id leadId) {
        try {
            // Validar parámetros necesarios
            if (String.isBlank(emailTemplateId) || String.isBlank(ownerEmail) || String.isBlank(clientEmail) || (contactId == null && leadId == null)) {
                System.debug('Faltan parámetros obligatorios.');
                return;
            }

            // Renderizar la plantilla de correo
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                emailTemplateId, 
                contactId != null ? contactId : leadId,  // 'WhoId' (puede ser el contacto o el lead)
                relatedId != null ? relatedId : null      // 'WhatId' (solo se asigna si relatedId no es null, caso contrario será null para lead)
            );

            // Crear el EmailMessage para registrar el correo enviado
            EmailMessage emailMessage = new EmailMessage(
                ToAddress = clientEmail,     // Dirección de correo del destinatario
                HtmlBody = email.getHtmlBody(),
                TextBody = email.getPlainTextBody(),
                Subject = email.getSubject(),
                FromAddress = ownerEmail,
                Status = '3',  // 3 significa "Enviado"
                Incoming = false
            );

            // Relacionar el correo con la Oportunidad (si es una oportunidad) o con el Lead (si es un lead)
            if (relatedId != null && leadId == null) {
                // En caso de ser oportunidad, usamos RelatedToId
                emailMessage.RelatedToId = relatedId;
            } else if (leadId != null) {
                // En caso de ser lead, usamos FromId
                emailMessage.FromId = leadId;
            }

            // Insertar el mensaje de correo
            insert emailMessage;
            System.debug('Correo enviado correctamente: ' + emailMessage.Subject);
        } catch (Exception ex) {
            System.debug('Error inesperado: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
        }
    }

    @InvocableMethod(label='Enviar Correos para Oportunidad o Prospecto' description='Envía correos basados en una plantilla a la oportunidad o al prospecto')
    public static void sendEmails(List<EmailInput> emailInputs) {
        try {
            if (emailInputs == null || emailInputs.isEmpty()) {
                System.debug('No se proporcionaron datos de entrada.');
                return;
            }

            // Recorrer la lista de entradas y procesarlas una por una
            for (EmailInput input : emailInputs) {
                // Verificamos si estamos procesando una Oportunidad o un Lead
                if (input.relatedId != null) {
                    // Si tenemos el ID de la oportunidad, enviamos el correo para la oportunidad
                    sendEmail(input.relatedId, input.emailTemplateId, input.ownerEmail, input.clientEmail, input.contactId, null);
                } else if (input.leadId != null) {
                    // Si tenemos el ID del lead, enviamos el correo para el lead
                    sendEmail(null, input.emailTemplateId, input.ownerEmail, input.clientEmail, null, input.leadId);
                } else {
                    System.debug('Error: No se proporcionó ID de oportunidad ni de lead.');
                }
            }

        } catch (Exception ex) {
            System.debug('Error inesperado al enviar correo: ' + ex.getMessage() + ' - Línea: ' + ex.getLineNumber());
        }
    }
}