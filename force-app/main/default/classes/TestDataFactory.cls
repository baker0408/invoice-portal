/**
 * TestDataFactory - Shared test data creation for Invoice Portal test classes.
 *
 * Provides reusable factory methods for Account, Invoice, and Invoice_Payment_Line__c
 * records used across InvoiceServiceTest and PaymentServiceTest.
 */
@IsTest
public class TestDataFactory {

    /**
     * Create and insert a test Account with standard billing address fields.
     *
     * @return The inserted Account record
     */
    public static Account createAccount() {
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            BillingCountry = 'US'
        );
        insert acc;
        return acc;
    }

    /**
     * Create and insert test Invoice records linked to the given Account via BillingAccountId.
     * Invoices are created with Status='Posted' and staggered dates.
     *
     * @param accountId  The Account Id to set as BillingAccountId
     * @param count      Number of invoices to create
     * @return List of inserted Invoice records
     */
    public static List<Invoice> createInvoices(Id accountId, Integer count) {
        List<Invoice> invoices = new List<Invoice>();
        for (Integer i = 0; i < count; i++) {
            invoices.add(new Invoice(
                BillingAccountId = accountId,
                Status = 'Posted',
                InvoiceDate = Date.today().addDays(-i),
                DueDate = Date.today().addDays(30 - i)
            ));
        }
        insert invoices;
        return invoices;
    }

    /**
     * Create and insert test Invoice records with both BillingAccountId and Sold_To_Account__c.
     * Used for testing dual-account scoping.
     *
     * @param accountId       The Account Id to set as BillingAccountId
     * @param soldToAccountId The Account Id to set as Sold_To_Account__c
     * @param count           Number of invoices to create
     * @return List of inserted Invoice records
     */
    public static List<Invoice> createSoldToInvoices(Id accountId, Id soldToAccountId, Integer count) {
        List<Invoice> invoices = new List<Invoice>();
        for (Integer i = 0; i < count; i++) {
            invoices.add(new Invoice(
                BillingAccountId = accountId,
                Sold_To_Account__c = soldToAccountId,
                Status = 'Posted',
                InvoiceDate = Date.today().addDays(-i),
                DueDate = Date.today().addDays(30 - i)
            ));
        }
        insert invoices;
        return invoices;
    }

    /**
     * Create and insert an Invoice_Payment_Line__c junction record.
     *
     * @param paymentId  The Payment record Id
     * @param invoiceId  The Invoice record Id
     * @param amount     The payment amount for this line
     * @return The inserted Invoice_Payment_Line__c record
     */
    public static Invoice_Payment_Line__c createPaymentLine(Id paymentId, Id invoiceId, Decimal amount) {
        Invoice_Payment_Line__c line = new Invoice_Payment_Line__c(
            Payment__c = paymentId,
            Invoice__c = invoiceId,
            Payment_Amount__c = amount
        );
        insert line;
        return line;
    }
}
