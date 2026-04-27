/**
**/
global class BIT_LinkSurveyWithVisit_sch implements Schedulable{
    global void execute(SchedulableContext sc){
        BIT_LinkSurveyWithVisit_bch batch = new BIT_LinkSurveyWithVisit_bch();
        Database.executeBatch(batch, 200);
    }
}