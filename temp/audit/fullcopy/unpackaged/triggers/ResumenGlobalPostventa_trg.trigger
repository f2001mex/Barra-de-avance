trigger ResumenGlobalPostventa_trg on ResumenGlobalPostventa__c (after insert, after update) {
    if (Trigger.isAfter) {
        PSTA_RResumenMes_thr.afterUpsert(Trigger.new);
    }
}