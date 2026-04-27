public class PSTA_PostCargaPostventa_Request {
    public Id trackerId;
    public Id cadenceId;
    public Id accountId;
    public Id userId;
    public Boolean shouldReassign;

    public PSTA_PostCargaPostventa_Request(
        Id trackerId,
        Id cadenceId,
        Id accountId,
        Id userId,
        Boolean shouldReassign
    ) {
        this.trackerId = trackerId;
        this.cadenceId = cadenceId;
        this.accountId = accountId;
        this.userId = userId;
        this.shouldReassign = shouldReassign;
    }
}
