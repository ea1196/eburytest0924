@isTest
public class TradeNotification_Helper_Test {
    @testSetup
    static void setupTestData() {
        // Create a test Queue (Group) and add members
        Group queue = new Group(Name = Label.Trade_Reviewers, Type = Label.Queue);
        insert queue;

        // Create test Users and add them to the Group
        User testUser1 = [SELECT Id, Email FROM User LIMIT 1]; // Get an active user from the org
        GroupMember gm = new GroupMember(GroupId = queue.Id, UserOrGroupId = testUser1.Id);
        insert gm;
    }

    @isTest
    static void testSendNotification() {
        // Create a test Trade record
        Trade__c trade = new Trade__c(
            Sell_Currency__c = 'USD',
            Sell_Amount__c = 1000,
            Buy_Currency__c = 'EUR',
            Buy_Amount__c = 850,
            Rate__c = 0.85,
            Booked_Date__c = Date.Today()
        );
        insert trade;

        // Fetch the test Trade created in the test setup
        List<Trade__c> trades = [SELECT Id, Sell_Currency__c, Sell_Amount__c, Buy_Currency__c, Buy_Amount__c, Rate__c, Booked_Date__c FROM Trade__c];

        // Call the method to be tested
        Test.startTest();
        TradeNotification_Helper.sendNotification(trades);
        Test.stopTest();

        // Verify the emails sent
        List<EmailMessage> sentEmails = [SELECT Id, Subject, Status FROM EmailMessage ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('New Trade Created', sentEmails[0].Subject, 'Email subject should match');
    }

    /**@isTest
    static void testNoEmailsSent() {
        // Create an empty trades list to test the no-trade scenario
        List<Trade__c> emptyTrades = new List<Trade__c>();

        // Call the method to be tested with no trades
        Test.startTest();
        TradeNotification_Helper.sendNotification(emptyTrades);
        Test.stopTest();

        // Assert that no emails were sent
        List<Messaging.SingleEmailMessage> sentEmails = Test.getSentEmails();
        System.assertEquals(0, sentEmails.size(), 'No emails should be sent when there are no trades.');
    }*/
}
