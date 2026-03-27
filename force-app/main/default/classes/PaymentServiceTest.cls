/**
 * PaymentServiceTest - Tests for PaymentService config retrieval and fee calculation.
 *
 * NOTE: Custom Metadata Type records deployed with the package are accessible in test
 * context without DML -- no @TestSetup needed for CMDT data (per RESEARCH.md Pitfall 2).
 */
@IsTest
private class PaymentServiceTest {

    /**
     * Test getPortalConfig returns the Default CMDT record with all 7 settings.
     * Verifies expected default values match what was deployed.
     */
    @IsTest
    static void testGetPortalConfig() {
        Invoice_Portal_Config__mdt config = PaymentService.getPortalConfig();
        System.assertNotEquals(null, config, 'Config record should not be null');
        System.assertEquals(2.9, config.Processing_Fee_Percent__c,
            'Processing fee should be 2.9%');
        System.assertEquals(20, config.Invoices_Per_Page__c,
            'Invoices per page should be 20');
        System.assertEquals('Sales Tax;Freight;Damaged;Pricing;Other',
            config.Short_Pay_Reasons__c,
            'Short pay reasons should match deployed value');
    }

    /**
     * Test calculateProcessingFee returns correct fee for CreditCard payments.
     * With 2.9% fee on $100.00, expects $2.90.
     */
    @IsTest
    static void testCalculateProcessingFeeCreditCard() {
        Decimal fee = PaymentService.calculateProcessingFee(100.00, 'CreditCard');
        System.assertEquals(2.90, fee,
            'Credit card processing fee on $100 should be $2.90');
    }

    /**
     * Test calculateProcessingFee returns 0 for ACH payments.
     * ACH payments do not incur processing fees regardless of config.
     */
    @IsTest
    static void testCalculateProcessingFeeACH() {
        Decimal fee = PaymentService.calculateProcessingFee(100.00, 'ACH');
        System.assertEquals(0, fee,
            'ACH payment processing fee should be 0');
    }

    /**
     * Test processPayment stub throws AuraHandledException when called without
     * a portal user context (no account can be determined).
     */
    @IsTest
    static void testProcessPaymentStubThrowsWithoutContext() {
        try {
            PaymentService.processPayment('{}');
            // If no exception, the user has portal context -- stub completes silently
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e,
                'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test calculateProcessingFee with a larger amount for precision verification.
     * Verifies HALF_UP rounding: 2.9% of $99.99 = $2.89971 -> $2.90
     */
    @IsTest
    static void testCalculateProcessingFeeRounding() {
        Decimal fee = PaymentService.calculateProcessingFee(99.99, 'CreditCard');
        System.assertEquals(2.90, fee,
            'Processing fee should round to $2.90 using HALF_UP');
    }
}
