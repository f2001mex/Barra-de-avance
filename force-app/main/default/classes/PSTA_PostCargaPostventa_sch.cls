global class PSTA_PostCargaPostventa_sch implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PSTA_PostCargaPostventa_bch(), 200);
    }
}
