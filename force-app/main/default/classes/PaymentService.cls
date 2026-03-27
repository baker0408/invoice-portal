/**
 * PaymentService - Portal configuration access, processing fee calculation, and payment processing.
 *
 * Reads configurable settings from Invoice_Portal_Config__mdt (Custom Metadata Type).
 * Account scoping is enforced for all payment operations (DATA-04).
 */
public with sharing class PaymentService {

    /**
     * Resolve the current portal user's Account Id from their Contact record.
     * Returns null if the user is not a community/portal user with a linked Contact.
     */
    private static Id getAccountIdForCurrentUser() {
        List<User> users = [
            SELECT ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
              AND ContactId != null
            LIMIT 1
        ];
        if (users.isEmpty() || users[0].Contact.AccountId == null) {
            return null;
        }
        return users[0].Contact.AccountId;
    }

    /**
     * Retrieve the portal configuration from the Default Custom Metadata record.
     * Returns all 7 settings: processing fee %, fee enabled, ACH enabled, CC enabled,
     * invoices per page, PaymentLink TTL, and short pay reasons.
     *
     * @return Invoice_Portal_Config__mdt record with all configuration fields
     */
    @AuraEnabled(cacheable=true)
    public static Invoice_Portal_Config__mdt getPortalConfig() {
        return [
            SELECT Processing_Fee_Percent__c, Processing_Fee_Enabled__c,
                   ACH_Enabled__c, Credit_Card_Enabled__c, Invoices_Per_Page__c,
                   PaymentLink_TTL_Hours__c, Short_Pay_Reasons__c
            FROM Invoice_Portal_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
    }

    /**
     * Calculate the processing fee for a credit card payment.
     * Returns 0 for ACH payments or when processing fees are disabled.
     *
     * @param paymentTotal  The total payment amount
     * @param paymentMethod  'CreditCard' or 'ACH'
     * @return The processing fee amount, rounded to 2 decimal places
     */
    @AuraEnabled
    public static Decimal calculateProcessingFee(Decimal paymentTotal, String paymentMethod) {
        if (paymentMethod != 'CreditCard') {
            return 0;
        }

        Invoice_Portal_Config__mdt config = getPortalConfig();
        if (!config.Processing_Fee_Enabled__c) {
            return 0;
        }

        return (paymentTotal * config.Processing_Fee_Percent__c / 100).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Process a payment for selected invoices.
     * Stub for Phase 5 implementation.
     *
     * @param paymentPayloadJson  JSON string containing payment details
     */
    @AuraEnabled
    public static void processPayment(String paymentPayloadJson) {
        Id accountId = getAccountIdForCurrentUser();
        if (accountId == null) {
            throw new AuraHandledException('Unable to determine account context');
        }

        // Phase 5 implementation: create Payment, PaymentLineItem, Invoice_Payment_Line__c
        // records and update Portal_Status__c
    }
}
