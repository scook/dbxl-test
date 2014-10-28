public with sharing class QIEditSOWController {

private final Case item;

public QIEditSOWController(ApexPages.StandardController stdController) {
    
    if (stdController.getId() <> null) {
        this.item = (Case)stdController.getRecord();
    }   
}
 

public PageReference saveRecord(){
    if (this.item == null) return null;
    //this.item.HTML_Content__c = this.htmlContent;
    Database.SaveResult result = Database.update(item);
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Content saved.'));
    return null;
}

public PageReference clearHTML(){
    if (this.item == null) return null;
    //this.item.HTML_Content__c = '';
    Database.SaveResult result = Database.update(item);
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Content cleared.'));
    return null;
}

public PageReference returnToCase() {
    if (this.item == null) return null;
    PageReference retUrl = new PageReference('/'+this.item.Id);
    return retUrl;
    
}

Public static testmethod void runTest() {
    
    Case item = new Case();
    item.Description = 'ApexTest ContentItemController';
    insert item;
    
    QIEditSOWController controller;
    ApexPages.StandardController stdController = new ApexPages.StandardController(item);
    controller = new QIEditSOWController(stdController);
        
    controller.saveRecord();
    controller.clearHTML();
    controller.returnToCase();
    
}
}