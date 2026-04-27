public with sharing class F4_SendLeadsToOutbound_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    //Query String
	private String query;
	private F3_Integration_Service__mdt serviceMetadata;
	private Outbound_Settings__mdt outboundMetadata;
    private boolean isTwice;

    public F4_SendLeadsToOutbound_Batch(String query, Boolean isTwice, F3_Integration_Service__mdt serviceMetadata, Outbound_Settings__mdt outboundMetadata) {
        this.query = query;
        this.isTwice = isTwice;
        this.serviceMetadata = serviceMetadata;
        this.outboundMetadata = outboundMetadata;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        new F4_SendLeadsToOutbound_Handler(serviceMetadata, outboundMetadata).sendLeadsToOutbound((List<CampaignMember>) scope, isTwice);
    }
  
    public void finish(Database.BatchableContext BC){
    
    }
}