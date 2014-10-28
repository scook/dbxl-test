trigger Contract on Contract (after update) {
  if (TriggerBase.shouldRunTrigger()) {
        TriggerFactory.createHandler(Contract.sObjectType);
    } 

}