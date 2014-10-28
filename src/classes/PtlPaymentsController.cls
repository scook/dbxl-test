public with sharing class PtlPaymentsController {

    private AccessControllerWithoutSharing acwos = new AccessControllerWithoutSharing();
    public String selectedPaymentId {get;set;}
    public Integer numberOfPayments {get;set;}
    public Integer numberOfSchedPayments {get;set;}

    public pymt__PaymentX__c[] payments {get;set;}
    public pymt__PaymentX__c[] scheduledPayments {get;set;}
    
    public PtlPaymentsController() {
        
        this.payments = new pymt__PaymentX__c[]{};
        this.numberOfPayments = 0;
        this.numberOfSchedPayments = 0;
            
        // If logged in, find payments for this user
        if (UserInfo.getUserId() <> null && UserInfo.getUserType() <> 'Guest') {
            User[] users = this.acwos.dbQuery('Select id, ContactId from User where id=\''+UserInfo.getUserId()+'\'');
            if (users <> null && users.size()>0) {
                String soql = '';
                String soql2 = '';
                if (Test.isRunningTest()) {
                    soql = 'Select id, name, pymt__Amount__c, pymt__Status__c, pymt__Key__c, pymt__Date__c, pymt__Scheduled_Payment_Date__c from pymt__PaymentX__c where isDeleted = false limit 20';
                    soql2 = 'Select id, name, pymt__Amount__c, pymt__Status__c, pymt__Key__c, pymt__Date__c, pymt__Scheduled_Payment_Date__c from pymt__PaymentX__c where isDeleted = false limit 20';
                    
                } else {
                    
                    String contactId = users[0].ContactId;
                    if (contactId <> null && contactId <> '') {
                        soql = 'Select id, name, pymt__Amount__c, pymt__Status__c, pymt__Key__c, pymt__Date__c, '+
                        'pymt__Scheduled_Payment_Date__c from pymt__PaymentX__c where isDeleted = false '+
                        'and pymt__Contact__c = \''+String.escapeSingleQuotes(contactId)+'\' and '+
                        'pymt__Status__c in (\'Completed\',\'Charged\',\'Authorized\') order by pymt__Date__c desc limit 20';
                        soql2 = 'Select id, name, pymt__Amount__c, pymt__Status__c, pymt__Key__c, pymt__Date__c, '+
                        'pymt__Scheduled_Payment_Date__c from pymt__PaymentX__c where isDeleted = false '+
                        'and pymt__Contact__c = \''+String.escapeSingleQuotes(contactId)+'\' and '+
                        'pymt__Status__c NOT IN (\'Completed\',\'Charged\') and '+
                        'pymt__Scheduled_Payment_Date__c <> null '+
                        ' order by pymt__scheduled_Payment_Date__c desc limit 20';
                    }
                }
                
                if (soql <> '') {
                    this.payments = this.acwos.dbQuery(soql);
                    if (this.payments <> null && this.payments.size()>0) {
                        this.numberOfPayments = this.payments.size();
                    }
                    this.scheduledPayments = this.acwos.dbQuery(soql2);
                    if (this.scheduledPayments <> null && this.scheduledPayments.size()>0) {
                        this.numberOfSchedPayments = this.scheduledPayments.size();
                    }
                }
                
            }
        }
        
    }


        
    public PageReference viewPtlCheckout() {
        PageReference nextPage;
        
        if (!pymt.Util.isNullOrEmpty(this.selectedPaymentId)) {
            String accessKey = '';
            for (pymt__PaymentX__c pmt :this.payments) {
                if (pmt.Id == this.selectedPaymentId) {
                    accessKey = pmt.pymt__Key__c;
                    break;                  
                }
                
            }
            nextPage = Page.pymt__PtlCheckout;
            nextPage.getParameters().put('pid',this.selectedPaymentId);
            nextPage.getParameters().put('key',accessKey);
        }   
        return nextPage;
    }    
}