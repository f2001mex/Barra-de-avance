Map<String, Schema.SObjectField> f = Schema.SObjectType.ResumenGlobalPostventa__c.fields.getMap();
for (String k : f.keySet()) {
    if (k.toLowerCase().contains('nomina') || k.toLowerCase().contains('mensual')) {
        System.debug(k);
    }
}
System.debug('contains ExternalId_NominaFecha__c: ' + f.containsKey('ExternalId_NominaFecha__c'));
