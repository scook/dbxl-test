@isTest
private class PtInvoicesControllerTest {
    static testMethod void testPtlInvoicesController() {     
        // Retrieve a closed/won stage
        String stagename = [Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true and IsWon = true limit 1].MasterLabel;
        
        String apexTestLabel = 'ApexTestPtlInvoicesController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel, ShippingStreet = '123 Test Street',
                                       ShippingCity = 'Encinitas',
                                       ShippingState = 'CA',
                                       ShippingPostalCode = '92024',
                                       BillingStreet = '123 Test Street',
                                       BillingCity = 'Encinitas',
                                       BillingState = 'CA',
                                       BillingPostalCode = '92024',
                                       Reason_for_no_NCES_ID__c = 'International - No NCES ID'  );
        insert account;
         
        Contact[] contacts = [Select id from Contact where isDeleted = false and lastname = :apexTestLabel];
        if (contacts != null && contacts.size() > 0) delete contacts;
        Contact contact = new Contact(firstname = 'Albert', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id);
        insert contact;

        Opportunity newOppRecurring = new Opportunity(name = 'ApexTestPtlInvoicesController-recurring',
                                            closedate = System.today(),
                                            pymt__sitequote_expiration__c = Date.today().addDays(30),
                                            stagename =  'Opportunity',
                                            amount = 1000,
                                            License_Level__c = 'Site',
                                            Lead_Source_Detail__c = 'Test Partner',                                                                                        
                                            pymt__tax__c = 50,
                                            pymt__shipping__c = 150,
                                            pymt__recurring_amount__c = 100,
                                            pymt__frequency__c = 1,
                                            pymt__period__c = 'Month',
                                            pymt__occurrences__c = 12,
                                            pymt__SiteQuote_Recurring_Setup__c = 'Recurring Payments = Total Amount', 
                                            accountid = account.id
                                            );
        insert newOppRecurring;
                                                
        Test.setCurrentPage(Page.PtlInvoices);
        PtlInvoicesController controller = new PtlInvoicesController();
        PtlInvoicesController.Invoice[] invoices = controller.invoices;
        controller.selectedInvoiceId = newOppRecurring.Id;
        controller.viewInvoice();
        
        PtlInvoicesController.joinStringArray(new String[]{'a','b'},',');
    }
}