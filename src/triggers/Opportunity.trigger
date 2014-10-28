trigger Opportunity on Opportunity (before update,after update) {
    if (TriggerBase.shouldRunTrigger()) {
        TriggerFactory.createHandler(Opportunity.sObjectType);
    } 
}