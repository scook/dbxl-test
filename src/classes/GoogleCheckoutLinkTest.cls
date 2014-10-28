@isTest
public class GoogleCheckoutLinkTest {

    public static testMethod void testBuildGoogleCheckoutURL() {
        String testname = 'ApexTestBuildGoogleCheckoutURL'; 
        Opportunity opp = new Opportunity(name = testname,
                                        stagename = 'Opportunity',
                                        closedate = System.today(), 
                                        Build_GoogleCheckout_URL__c = true,
                                        Lead_Source_Detail__c = 'Test Partner',
                                        amount = 101.00);
        insert opp;
        
        opp.amount = 0;
        update opp; 
        
        Opportunity resultOpp = [Select id, name, googleCheckoutURL__c from Opportunity where id = :opp.Id];
        
    }
    
}