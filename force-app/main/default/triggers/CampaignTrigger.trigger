trigger CampaignTrigger on Campaign (after insert) {
    new CampaignTrigger_Handler().run();
}