@isTest
private class PtlPaymentsControllerTest{
    static testMethod void testPtlPaymentsController() {
        
        
        String apexTestLabel = 'ApexTestPtlPaymentsController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel, 
                                       ShippingStreet = '123 Test Street',
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
                                      accountId = account.id
                                      );
        insert contact;

        pymt__PaymentX__c payment = new pymt__PaymentX__c(name = apexTestLabel,
                                        pymt__Status__c = 'Completed',
                                        pymt__Transaction_Type__c = 'Payment',
                                        pymt__Payment_Type__c = 'Cash',
                                        pymt__Amount__c = 4.00
                                        );
        insert payment;
                                                                                        
        Test.setCurrentPage(Page.PtlPayments);
        PtlPaymentsController controller = new PtlPaymentsController();
        controller.selectedPaymentId = controller.payments[0].Id;
        controller.viewPtlCheckout();
        
    }
    

}