/**
 * Interface containing methods Trigger Handlers must implement to enforce best practice
 * and bulkification of triggers.
 */
virtual public class TriggerBase {
  public static Boolean disabled = false;
  public static Boolean runWhenRunningTest = false;
  
  public static Boolean shouldRunTrigger() {
    return (!disabled && (!Test.isRunningTest() || runWhenRunningTest));
  }

  public TriggerBase() {}
  /**
   * bulkBefore
   *
   * This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  virtual public void bulkBefore() {}
  
  /**
   * bulkAfter
   *
   * This method is called prior to execution of an AFTER trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  virtual public void bulkAfter() {}
  
  /**
   * beforeInsert
   *
   * This method is called iteratively for each record to be inserted during a BEFORE
   * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
   */
  virtual public void beforeInsert(SObject so) {}
  
  /**
   * beforeUpdate
   *
   * This method is called iteratively for each record to be updated during a BEFORE
   * trigger.
   */
  virtual public void beforeUpdate(SObject oldSo, SObject so) {}

  /**
   * beforeDelete
   *
   * This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   */
  virtual public void beforeDelete(SObject so) {}

  /**
   * afterInsert
   *
   * This method is called iteratively for each record inserted during an AFTER
   * trigger. Always put field validation in the 'After' methods in case another trigger
   * has modified any values. The record is 'read only' by this point.
   */
  virtual public void afterInsert(SObject so) {}

  /**
   * afterUpdate
   *
   * This method is called iteratively for each record updated during an AFTER
   * trigger.
   */
  virtual public void afterUpdate(SObject oldSo, SObject so) {}

  /**
   * afterDelete
   *
   * This method is called iteratively for each record deleted during an AFTER
   * trigger.
   */
  virtual public void afterDelete(SObject so) {}

  /**
   * andFinally
   *
   * This method is called once all records have been processed by the trigger. Use this 
   * method to accomplish any final operations such as creation or updates of other records.
   */
  virtual public void andFinally() {}
}