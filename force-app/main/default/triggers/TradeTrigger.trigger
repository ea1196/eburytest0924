trigger TradeTrigger on Trade__c (after insert) {
    TradeNotification_Helper.sendNotification(Trigger.new);
}
