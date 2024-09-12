public with sharing class NewTradeController {
    
    @AuraEnabled
    public static Trade__c createNewTrade(String sellCurrency, Decimal sellAmount, String buyCurrency) {
        // Validate inputs
        if (sellAmount <= 0) {
            throw new AuraHandledException('Sell Amount must be greater than zero.');
        }
        if (String.isEmpty(sellCurrency) || String.isEmpty(buyCurrency)) {
            throw new AuraHandledException('Currency fields cannot be empty.');
        }
        if (sellCurrency.equals(buyCurrency)) {
            throw new AuraHandledException('Sell Currency and Buy Currency cannot be the same.');
        }
    
        try {
            // Fetch latest rate from fixer.io API
            Decimal rate = getExchangeRate(sellCurrency, buyCurrency);
            
            // Calculate Buy Amount
            Decimal buyAmount = sellAmount * rate;
            
            // Create new Trade record
            Trade__c newTrade = new Trade__c(
                Sell_Currency__c = sellCurrency,
                Sell_Amount__c = sellAmount,
                Buy_Currency__c = buyCurrency,
                Buy_Amount__c = buyAmount,
                Rate__c = rate,
                Booked_Date__c = Date.today()
            );
            insert newTrade;
            
            return newTrade;
        } catch (Exception e) {
            // Log error and throw custom exception
            System.debug('Error creating new trade: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while creating the trade: ' + e.getMessage());
        }
    }
    
    

    
    @AuraEnabled
    public static Decimal getExchangeRate(String sellCurrency, String buyCurrency) {
        try {
            // Retrieve the access key from custom metadata
            String accessKey = getFixerAccessKey();
            
            // Construct the API URL
            String apiEndpoint = 'https://data.fixer.io/api/latest?access_key=' + accessKey + '&symbols=' + sellCurrency + ',' + buyCurrency;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiEndpoint);
            req.setMethod('GET');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> rates = (Map<String, Object>) result.get('rates');
                
                Decimal sellUnitValue = rates.containsKey(sellCurrency) ? (Decimal) rates.get(sellCurrency) : 0;
                Decimal buyUnitValue = rates.containsKey(buyCurrency) ? (Decimal) rates.get(buyCurrency) : 0;
                
                if (sellUnitValue == 0 || buyUnitValue == 0) {
                    throw new CalloutException('Currency rate not found for one of the provided currencies.');
                }
                
                return buyUnitValue / sellUnitValue;
            } else {
                throw new CalloutException('Failed to retrieve rates from Fixer.io: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error getting exchange rate: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while retrieving the exchange rate: ' + e.getMessage());
        }
    }
    

	// Helper method to retrieve Fixer API access key from custom metadata
	public static String getFixerAccessKey() {
		// Retrieve DeveloperName for the Metadata from a label as for best practices (avoid hardcoding)
		String fixerKey = Label.FixerAccessKey;

		// Query the custom metadata for the FixerKey configuration
		Configuration__mdt fixerConfig = [SELECT Value__c FROM Configuration__mdt WHERE DeveloperName = :fixerKey LIMIT 1];
		return fixerConfig.Value__c;
	}
}