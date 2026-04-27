public with sharing class ACT_ContractPhone_hdl {

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

    public static List<ConversionError> errors = new List<ConversionError>();

    public static void buildContractPhones(List<Telefono_de_Contrato__c> records) {
        errors.clear(); // Limpia errores previos

        for (Telefono_de_Contrato__c record : records) {
            try {
                String phoneRaw = record.Phone__c;
                String ladaRaw = record.Lada__c;
                String countryCodeRaw = record.Area_Code__c;

                System.debug('Phone Raw: ' + phoneRaw);
                System.debug('Lada Raw: ' + ladaRaw);
                System.debug('Country Code Raw: ' + countryCodeRaw);

                if (String.isBlank(phoneRaw) || onlyZeros(phoneRaw)) {
                    record.ACT_Contract_Phone__c = null;
                    errors.add(new ConversionError(record.Name, record.Id, 'Número vacío o solo ceros'));
                    continue;
                }

                if (!containsOnlyDigits(phoneRaw) ||
                    (!String.isBlank(ladaRaw) && !containsOnlyDigits(ladaRaw)) ||
                    (!String.isBlank(countryCodeRaw) && !Pattern.matches('^[0-9+]+$', countryCodeRaw))) {
                    record.ACT_Contract_Phone__c = null;
                    errors.add(new ConversionError(record.Name, record.Id, 'Caracteres no válidos'));
                    continue;
                }

                Boolean isMexico = isCodigoPaisMexico(countryCodeRaw);

                String phone = cleanNumber(phoneRaw);
                String lada = cleanNumber(ladaRaw);
                String countryCode = cleanNumber(countryCodeRaw);

                lada = (lada == '0') ? null : lada;
                countryCode = (countryCode == '0') ? null : countryCode;

                String contractPhone;

                if (isMexico) {
                    // Reglas mexicanas
                    contractPhone = buildMexicanPhone(phone, lada);
                    if (contractPhone != null) {
                        record.ACT_Contract_Phone__c = '+52' + contractPhone;
                    } else {
                        record.ACT_Contract_Phone__c = null;
                        errors.add(new ConversionError(record.Name, record.Id, 'Formato inválido con reglas mexicanas'));
                    }
                } else {
                    // Para otros países
                    contractPhone = (countryCode != null ? countryCode : '') +
                                    (lada != null ? lada : '') +
                                    (phone != null ? phone : '');

                    record.ACT_Contract_Phone__c = String.isNotBlank(contractPhone) ? '+' + contractPhone : null;

                    if (String.isBlank(record.ACT_Contract_Phone__c)) {
                        errors.add(new ConversionError(record.Name, record.Id, 'Formato inválido para otro país'));
                    }
                }
            } catch (Exception e) {
                record.ACT_Contract_Phone__c = null;
                errors.add(new ConversionError(record.Name, record.Id, 'Excepción en la conversión - ' + e.getMessage()));
            }
        }

        //if (!errors.isEmpty()) {
        //    sendErrorNotification(errors);
        //}
    }

    private static void sendErrorNotification(List<ConversionError> errors) {
        List<String> adminEmails = new List<String>();
        for (User u : [
            SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
        ]) {
            if (String.isNotBlank(u.Email) && !u.Email.contains('invalid')) {
                adminEmails.add(u.Email);
            }
        }
        adminEmails.add(UserInfo.getUserEmail());
        
        String body = 'Se encontraron errores durante la conversión de teléfonos en los siguientes registros:<br><br>';
        for (ConversionError err : errors) {
            body += 'Nombre de registro: <a href="' + Url.getOrgDomainUrl() + '/' + err.recordId + '">' + err.recordName + '</a> | Error: ' + err.message;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Errores en la conversión de teléfono');
        email.setHtmlBody(body);
        email.setToAddresses(adminEmails);
        //email.setToAddresses(new List<String> {'miguel.sialer.santacruz@gmail.com'});

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    // Limpia ceros a la izquierda
    private static String cleanNumber(String value) {
        if (String.isBlank(value)) return null;
        return value.replaceFirst('^0+', '');
    }

    // Retorna true si contiene solo ceros
    private static Boolean onlyZeros(String value) {
        if (String.isBlank(value)) return true;
        String digitsOnly = value.replaceAll('[^0-9]', '');
        return String.isBlank(digitsOnly.replaceAll('0', ''));
    }

    // Retorna true si contiene solo dígitos
    private static Boolean containsOnlyDigits(String value) {
        return value != null && Pattern.matches('^[0-9]+$', value);
    }

    // Retorna true si el código es de México
    private static Boolean isCodigoPaisMexico(String rawCode) {
        if (String.isBlank(rawCode)) return true;
        if (rawCode.contains('+')) return false;
        String cleaned = rawCode.replaceAll('[^0-9]', '');
        return cleaned == '52' || cleaned == '052' || cleaned == '0052';
    }

    // Construcción del número para México
    private static String buildMexicanPhone(String phone, String lada) {
        if (String.isBlank(phone)) return null;

        Integer len = phone.length();

        if (len >= 10) {
            return phone.right(10);
        } else if (len == 8 && lada != null && lada.length() >= 2) {
            return lada.right(2) + phone;
        } else if (len == 7 && lada != null && lada.length() >= 3) {
            return lada.right(3) + phone;
        }

        return null;
    }
}