User advisor = [
    SELECT Id, Name, ID_ASESOR__c, F3_Division__c
    FROM User
    WHERE Id = '0057V00000CFfSeQAL'
    LIMIT 1
];

List<ResumenGlobalPostventa__c> summaries = [
    SELECT Id, Name, Fecha__c, ExternalId_Nomina__c,
           Meta__c, MetaMensual__c, Contactados__c,
           ContactadosMensual__c, PorcentajeAvanceMensual__c
    FROM ResumenGlobalPostventa__c
    WHERE ExternalId_Nomina__c = :advisor.ID_ASESOR__c
      AND Fecha__c = THIS_MONTH
    ORDER BY Fecha__c DESC
];

System.debug('ADVISOR=' + JSON.serialize(advisor));
System.debug('SUMMARIES=' + JSON.serialize(summaries));
