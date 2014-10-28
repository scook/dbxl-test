@isTest
private class TriggerBaseTest {
    private class TestTrigger extends TriggerBase {}
    
    public static testMethod void testTriggerBase_AllMethodsWithNullArguments_NoExceptions() {
        TestTrigger t = new TestTrigger();
        
        t.beforeInsert(null);
        t.afterInsert(null);
        
        t.beforeUpdate(null, null);
        t.afterUpdate(null, null);
        
        t.beforeDelete(null);
        t.afterDelete(null);
        
        t.bulkBefore();
        t.bulkAfter();
        
        t.andFinally();
    }
    
    public static testMethod void testShouldRunTrigger_SetToRunDuringTest_ReturnsTrue() {
        TestTrigger t = new TestTrigger();
        TriggerBase.runWhenRunningTest = true;
        System.assertEquals(true, TriggerBase.shouldRunTrigger());
    }
    
    public static testMethod void testShouldRunTrigger_Disabled_ReturnsFalse() {
        TestTrigger t = new TestTrigger();
        TriggerBase.runWhenRunningTest = true;
        TriggerBase.disabled = true;
        System.assertEquals(false, TriggerBase.shouldRunTrigger());
    }
}