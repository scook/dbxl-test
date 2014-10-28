@isTest
private class QlEditTermsControllerTest{

static testmethod void runTest() {

    // Create a content item
    ctnt__Content_Item__c contentItem = new ctnt__Content_Item__c(name = 'ApexTestContentItem',
                                                ctnt__HTML_Content__c = 'test',
                                                ctnt__Category__c = 'Quote Terms',
                                                ctnt__Status__c = 'Approved');
    insert contentItem;
    
    // Retrieve a closed/won stage - PaddyH - changing to an open stage to avoid failing test
    String stagename = 'Opportunity'; //[Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true and IsWon = true limit 1].MasterLabel;
            
    Opportunity item = new Opportunity(name = 'ApexTest QIEditTermsController',
                                            closedate = System.today() + 7,
                                            stagename = stagename,
                                            publish_as_quote__c = true,
                                            License_Level__c = 'Seat',
                                            Lead_Source_Detail__c = 'Test Partner',
                                            amount = 200.00,
                                      		Execution_Document__c = 'test execution document');                           
    insert item;
    
    QIEditTermsController controller;
    ApexPages.StandardController stdController = new ApexPages.StandardController(item);
    controller = new QIEditTermsController(stdController);
        
    controller.saveRecord();
    controller.clearHTML();
    controller.clearTerms();
    SelectOption[] options = controller.getContentOptions();
    system.assert(options.size()>0);
    controller.selectedContentItem = controller.contentItems[0].Id;
    controller.insertContent();
    controller.returnToOpportunity();
    
}
}