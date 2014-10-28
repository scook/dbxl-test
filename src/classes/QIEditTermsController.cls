public with sharing class QIEditTermsController {

private final Opportunity item;
public ctnt__Content_Item__c[] contentItems = new ctnt__Content_Item__c[]{};
public string selectedContentItem {get;set;}
public Boolean appendContent {get;set;}
public Boolean hasContentItems {get;set;}

// The extension constructor initializes the private member
// variable acct by using the getRecord method from the standard
// controller.
public QIEditTermsController(ApexPages.StandardController stdController) {
    this.appendContent = false;    
    this.hasContentItems = false;
    if (stdController.getId() <> null) {
        this.item = (Opportunity)stdController.getRecord();
            this.contentItems = [Select id, name, ctnt__Description__c, ctnt__HTML_Content__c, ctnt__Category__c from ctnt__Content_Item__c where isDeleted = false 
                            and ctnt__Status__c = 'Approved' and (ctnt__Category__c includes ('Quote Terms') or ctnt__Category__c includes ('Invoice Terms')) and 
                            (ctnt__Publication_Date__c = null or ctnt__Publication_Date__c <= TODAY) and (ctnt__Expiration_Date__c = null or ctnt__Expiration_Date__c >= TODAY)];
        this.hasContentItems =  (this.contentItems <> null && this.contentItems.size()>0);
    }   
}
 

public PageReference saveRecord(){
    if (this.item == null) return null;

    this.item.QI_Terms_And_Conditions__c = pymt.Util.firstN(this.item.QI_Terms_And_Conditions__c,32768);    
    Database.SaveResult result = Database.update(item);
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Content saved.'));
    return null;
}

public SelectOption[] getContentOptions() {
    SelectOption[] results = new SelectOption[]{};
    if (this.contentItems <> null && this.contentItems.size()>0) {
        for (ctnt__Content_Item__c citem :this.contentItems) {
            if (this.item.Publish_As_Quote__c || this.item.Publish_As_Invoice__c) {
                if (this.item.Publish_As_Quote__c) {
                    if (citem.ctnt__Category__c <> null && citem.ctnt__Category__c.contains('Quote Terms')) {
                        results.add(new SelectOption(citem.Id, citem.name));
                    } 
                } else {
                    if (citem.ctnt__Category__c <> null && citem.ctnt__Category__c.contains('Invoice Terms')) {
                        results.add(new SelectOption(citem.Id, citem.name));
                    } 
                    
                }
            } else {
                String prefix = '';
                
                if (citem.ctnt__Category__c <> null && citem.ctnt__Category__c.contains('Quote Terms')) {
                    prefix = '(Quote Terms) ';
                }                   
                if (citem.ctnt__Category__c <> null && citem.ctnt__Category__c.contains('Invoice Terms')) {
                    prefix = '(Invoice Terms) ';
                }                   
                results.add(new SelectOption(citem.Id, prefix + citem.name));
            }
        }
    }   
    return results;
}

public PageReference insertContent() {
    if (this.selectedContentItem <> null && this.contentItems <> null && this.contentItems.size()>0) {
        for (ctnt__Content_Item__c item :this.contentItems) {
            if (item.Id == this.selectedContentItem) {
                if (this.appendContent) {
                    this.item.QI_Terms_And_Conditions__c += item.ctnt__HTML_Content__c;
                    this.item.QI_Terms_And_Conditions__c = pymt.Util.firstN(this.item.QI_Terms_And_Conditions__c,32768);
                } else {
                    this.item.QI_Terms_And_Conditions__c = item.ctnt__HTML_Content__c;                  
                }
                break;
            }
        }
    }
    return null;
}

public PageReference clearHTML(){
    if (this.item == null) return null;
    Database.SaveResult result = Database.update(item);
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Content cleared.'));
    return null;
}

public PageReference returnToOpportunity() {
    if (this.item == null) return null;
    PageReference retUrl = new PageReference('/'+this.item.Id);
    return retUrl;
    
}

public PageReference clearTerms() {
    this.item.QI_Terms_and_Conditions__c = '';
    ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Terms cleared. Click "Save" to record your changes.'));
    return null;    
}
}