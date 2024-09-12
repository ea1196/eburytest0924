public class TradeNotification_Helper {
    public static void sendNotification(List<Trade__c> trades) {
        // Query the Queue for 'Trade reviewers'
        String trdRevGroupName = Label.Trade_Reviewers;
        String q = Label.Queue;
        Group queue = [SELECT Id FROM Group WHERE Name = :trdRevGroupName AND Type = :q LIMIT 1];

        if (queue != null) {
            // Get the users in the queue
            List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queue.Id];

            // Collect the User IDs and email addresses
            Set<String> emailAddresses = new Set<String>();
            for (GroupMember member : groupMembers) {
                User user = [SELECT Email FROM User WHERE Id = :member.UserOrGroupId LIMIT 1];
                if (user.Email != null) {
                    emailAddresses.add(user.Email);
                }
            }

            List<String> emailList = new List<String>(emailAddresses);

            if (!emailList.isEmpty()) {

                // Prepare the notification
                for(Trade__c trade : trades){
                    String tradeLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + trade.Id;
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(emailList);
                    email.setSubject('New Trade Created');
                    email.setHtmlBody('A new trade has been created with the following data:<br>' +
                                        'Sell Currency: ' + trade.Sell_Currency__c + '<br>' +
                                        'Sell Amount: ' + trade.Sell_Amount__c + '<br>' +
                                        'Buy Currency: ' + trade.Buy_Currency__c + '<br>' +
                                        'Buy Amount: ' + trade.Buy_Amount__c + '<br>' +
                                        'Rate: ' + trade.Rate__c + '<br>' +
                                        'Booked Date: ' + trade.Booked_Date__c + '<br>' +
                                        'Link to trade: ' + tradeLink);
                    
                    // Send the notification
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                }
            }
        }
    }
}
