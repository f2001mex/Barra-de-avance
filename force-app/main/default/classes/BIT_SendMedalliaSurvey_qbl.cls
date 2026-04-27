public class BIT_SendMedalliaSurvey_qbl implements System.Queueable{
    private Map<String,Set<Id>> params;

    public BIT_SendMedalliaSurvey_qbl(Map<String,Set<Id>> params) {
        this.params = params;
    }

    public void execute(System.QueueableContext objContext){
        Set<Id> lstId = params.get('idVisita');
        for(Id id :lstId) BIT_SendMedalliaSurvey_ctr.callout(id);
    }

}