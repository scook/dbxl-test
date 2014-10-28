public with sharing class SiteInvoicesController {
    private AccessControllerWithoutSharing acwos = new AccessControllerWithoutSharing();
    public String selectedInvoiceId {get;set;}
    
    public class Invoice {
        public string name {get;set;}
        public string recordId {get;set;}
        public decimal totalAmount {get;set;}
        public decimal balance {get;set;}
        public boolean paidOff {get;set;}
        public Task closeDate {get;set;}
        public String currencyISOCode {get;set;}
        
    }
    
    public Boolean isMultiCurrencyOrg {get;set;}
    
    public Invoice[] invoices {get;set;}
    
    public SiteInvoicesController() {
        
        this.invoices = new Invoice[]{};
        this.isMultiCurrencyOrg = UserInfo.isMultiCurrencyOrganization();           
            
        // If logged in, find invoices for this user
        if (UserInfo.getUserId() <> null && UserInfo.getUserType() <> 'Guest') {
            User[] users = this.acwos.dbQuery('Select id, ContactId from User where id=\''+UserInfo.getUserId()+'\'');
            if (users <> null && users.size()>0) {
                String soql = '';
                if (Test.isRunningTest()) {
                    soql = 'Select id, name, '+ (this.isMultiCurrencyOrg?'CurrencyISOCode, ':'')+' pymt__Total_Amount__c, CloseDate, pymt__Balance__c from Opportunity where isDeleted = false limit 20';
                    
                } else {
                    
                    String contactId = users[0].ContactId;
                    String[] oppIds = new String[]{};
                    String oppIdsString = '';
                    if (contactId <> null && contactId <> '') {
                        OpportunityContactRole[] ocRoles = this.acwos.dbQuery('Select id, opportunityId from OpportunityContactRole where isDeleted = false and contactId = \''+String.escapeSingleQuotes(contactId)+'\'');
                        if (ocRoles <> null && ocRoles.size()>0) {
                            for (OpportunityContactRole ocRole :ocRoles) {
                                oppIds.add(ocRole.opportunityId);   
                            }
                            oppIdsString = joinStringArray(oppIds,'\',\'');
                            soql = 'Select id, name, pymt__Total_Amount__c, '+ (isMultiCurrencyOrg?' CurrencyIsoCode, ':'') + ' pymt__Balance__c, CloseDate from Opportunity where isDeleted = false and Publish_As_Invoice__c = true and Id in (\''+oppIdsString+'\')';
                        }                       
                    }
                }
                Opportunity[] opps = new Opportunity[]{};
                if (soql <> '') {
                    opps = this.acwos.dbQuery(soql);
                    if (opps <> null && opps.size()>0) {
                        for (Opportunity opp :opps) {
                            Invoice inv = new Invoice();
                            inv.name = opp.name;
                            inv.recordId = opp.Id;
                            inv.totalAmount = opp.pymt__Total_Amount__c;
                            inv.balance = opp.pymt__Balance__c;
                            inv.closeDate = new Task(ActivityDate = opp.CloseDate);
                            inv.paidOff = inv.balance == null || inv.balance <=0;
                            if (isMultiCurrencyOrg) {
                                inv.currencyISOCode = (String)opp.get('CurrencyIsoCode');  // override processor connection default currency value using multicurrency iso code on opp (if present).
                            } else {
                               pymt__Processor_Connection__c[] connections = [Select id, pymt__default_connection__c, pymt__processor_id__c, pymt__test_mode__c, pymt__Default_Currency__c,  
                                    pymt__PP_Merchant_Id__c from pymt__Processor_Connection__c where pymt__default_connection__c = true and isDeleted = false
                                ];
                                if (connections <> null && connections.size()>0) {
                                    inv.currencyISOCode = connections[0].pymt__Default_Currency__c;  
                                }
                            }
                            this.invoices.add(inv); 
                        }
                    }
                }
                
            }
        }
        
    }

    public static String joinStringArray(String[] stringArray, String connector) {
        if (stringArray == null) return '';
        String result = '';
        for (Integer index = 0; index < stringArray.size();index ++) {
            result += stringArray[index];
            if (index != stringArray.size() -1) { result += connector; }
        }
        return result;  
    }
        
    public PageReference viewInvoice() {
        PageReference nextPage;
        
        if (!pymt.Util.isNullOrEmpty(this.selectedInvoiceId)) {
            nextPage = Page.SiteInvoice;
            nextPage.getParameters().put('id',this.selectedInvoiceId);
        }   
        return nextPage;
    }    
}