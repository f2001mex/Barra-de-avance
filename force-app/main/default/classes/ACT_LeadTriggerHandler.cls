public with sharing class ACT_LeadTriggerHandler {

    public class ConversionError {
        public String recordName;
        public String recordId;
        public String message;

        public ConversionError(String recordName, String recordId, String message) {
            this.recordName = recordName;
            this.recordId = recordId;
            this.message = message;
        }
    }

    public static void processLeadPhones(List<Lead> leads) {
        List<ConversionError> errors = new List<ConversionError>();

        for (Lead lead : leads) {
            try {
                // Obtener el número fuente: preferir Phone, si está vacío usar Numero_Telefono__c
                String sourcePhone = String.isNotBlank(lead.Phone) ? lead.Phone : lead.Numero_Telefono__c;
                
                // Ignorar leads sin número telefónico
                if (String.isBlank(sourcePhone)) {
                    continue;
                }

                // Extraer solo los dígitos del número
                String onlyDigits = sourcePhone.replaceAll('[^0-9]', '');

                // Ignorar números vacíos o compuestos solo por ceros
                if (onlyDigits == null || onlyDigits == '' || Pattern.matches('^0+$', onlyDigits)) {
                    continue;
                }

                // Validar que solo haya dígitos después de limpieza
                if (!Pattern.matches('^[0-9]+$', onlyDigits)) {
                    lead.Telephone__c = null;
                    errors.add(new ConversionError(lead.Name, lead.Id, 'Caracteres no válidos en el número'));
                    continue;
                }

                String rawPhone = onlyDigits;
                // Obtener lada limpiando caracteres no numéricos, si está presente
                String lada = lead.Lada__c != null ? String.valueOf(lead.Lada__c).replaceAll('[^0-9]', '') : null;

                // Aplicar reglas de negocio según longitud del número

                if (rawPhone.length() > 10) {
                    // Si tiene más de 10 dígitos, usarlo tal cual con prefijo '+'
                    lead.Telephone__c = '+' + rawPhone;

                } else if (rawPhone.length() == 10) {
                    // Número nacional completo (10 dígitos), se asume México +52
                    lead.Telephone__c = '+52' + rawPhone;

                } else if (rawPhone.length() == 7 && lada != null && lada.length() >= 3) {
                    // Si número de 7 dígitos y lada válido, concatenar lada y número con +52
                    lead.Telephone__c = '+52' + lada.right(3) + rawPhone;

                } else {
                    // Formato inválido, asignar null y agregar error
                    lead.Telephone__c = null;
                    errors.add(new ConversionError(lead.Name, lead.Id, 'Formato inválido para conversión'));
                }

            } catch (Exception e) {
                // Capturar cualquier excepción no manejada y registrar error
                lead.Telephone__c = null;
                errors.add(new ConversionError(lead.Name, lead.Id, 'Excepción: ' + e.getMessage()));
            }
        }

        // Enviar notificación por email si se encontraron errores
        if (!errors.isEmpty()) {
            sendErrorNotification(errors);
        }
    }

    private static void sendErrorNotification(List<ConversionError> errors) {
        List<String> recipients = new List<String>();

        // Obtener emails de usuarios activos con perfil System Administrator
        for (User u : [
            SELECT Email FROM User 
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = TRUE
        ]) {
            if (String.isNotBlank(u.Email) && !u.Email.contains('invalid')) {
                recipients.add(u.Email);
            }
        }
        // Agregar email del usuario que ejecuta el proceso
        recipients.add(UserInfo.getUserEmail());

        // Construir cuerpo del mensaje con listado de errores
        String body = 'Se encontraron errores al convertir el teléfono en registros de Prospecto:<br><br>';
        for (ConversionError err : errors) {
            body += 'Registro: <a href="' + Url.getOrgDomainUrl() + '/' + err.recordId + '">' + err.recordName + '</a> | Error: ' + err.message;
        }

        // Configurar y enviar email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Errores en la conversión de teléfono de Prospectos');
        mail.setHtmlBody(body);
        mail.setToAddresses(recipients);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}