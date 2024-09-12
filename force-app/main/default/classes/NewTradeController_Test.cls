@isTest
public class NewTradeController_Test {

    // Helper class to mock the HTTP response from Fixer.io API for success scenario
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"rates": {"USD": 1.0, "EUR": 0.85}}'); // Mocked USD to EUR exchange rate
            return res;
        }
    }
    
    @isTest
    static void testCreateNewTrade_Success() {
        // Set up mock HTTP response for a successful callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Execute the method with valid inputs
        Test.startTest();
        Trade__c newTrade = NewTradeController.createNewTrade('USD', 100, 'EUR');
        Test.stopTest();

        // Assert the trade was created with correct values
        System.assertEquals('USD', newTrade.Sell_Currency__c);
        System.assertEquals(100, newTrade.Sell_Amount__c);
        System.assertEquals('EUR', newTrade.Buy_Currency__c);
        System.assertEquals(85, newTrade.Buy_Amount__c); // Expected based on mock response
        System.assertNotEquals(null, newTrade.Booked_Date__c, 'Booked Date should not be null');
        System.assertNotEquals(null, newTrade.Rate__c, 'Rate should not be null');
    }

    @isTest
    static void testCreateNewTrade_NegativeAmount() {
        Test.startTest();
        try {
            NewTradeController.createNewTrade('USD', -10, 'EUR');
            System.assert(false, 'Exception should have been thrown for negative amount');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateNewTrade_EmptyCurrency() {
        Test.startTest();
        try {
            NewTradeController.createNewTrade('', 100, 'EUR');
            System.assert(false, 'Exception should have been thrown for empty currency');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateNewTrade_SameCurrency() {
        Test.startTest();
        try {
            NewTradeController.createNewTrade('USD', 100, 'USD');
            System.assert(false, 'Exception should have been thrown for same currency');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
}
