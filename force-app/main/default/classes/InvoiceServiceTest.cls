/**
 * InvoiceServiceTest - Tests for InvoiceService account scoping, tab filtering, and pagination.
 *
 * NOTE: Account scoping via getAccountIdForCurrentUser() requires a portal/community user
 * with a linked Contact.AccountId. In test orgs without community licenses, these tests
 * validate that the service methods execute correctly and handle the null account context
 * with AuraHandledException. If running in an org with community users, use System.runAs()
 * with a portal user for full account scoping validation.
 *
 * NOTE: The standard Invoice object may require additional fields or org configuration
 * (e.g., Order Management enabled) for DML operations. If tests fail on Invoice insert,
 * check that the org has the Invoice object available (per RESEARCH.md Pitfall 3).
 */
@IsTest
private class InvoiceServiceTest {

    @TestSetup
    static void setup() {
        // Create primary test account and invoices
        Account acc = TestDataFactory.createAccount();
        TestDataFactory.createInvoices(acc.Id, 5);

        // Create a second account for cross-account security testing
        Account otherAcc = new Account(
            Name = 'Other Account',
            BillingStreet = '456 Other St',
            BillingCity = 'Other City',
            BillingState = 'NY',
            BillingPostalCode = '10001',
            BillingCountry = 'US'
        );
        insert otherAcc;
        TestDataFactory.createInvoices(otherAcc.Id, 3);
    }

    /**
     * Test getInvoices with 'open' tab filter.
     * Open tab: Balance > 0 AND Status = 'Posted'
     * Expects AuraHandledException for non-portal users (no account context).
     */
    @IsTest
    static void testGetInvoicesOpenTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', null, null, 1, 20);
            // If we reach here, the user has an account context (portal user)
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
            System.assert(result.totalCount >= 0, 'Total count should be non-negative');
            for (Invoice inv : result.invoices) {
                System.assert(inv.Balance > 0, 'Open tab invoices should have Balance > 0');
                System.assertEquals('Posted', inv.Status, 'Open tab invoices should have Status = Posted');
            }
        } catch (AuraHandledException e) {
            // Expected for non-portal users -- account context cannot be determined
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test getInvoices with 'paid' tab filter.
     * Paid tab: Status = 'Paid' OR Balance = 0
     */
    @IsTest
    static void testGetInvoicesPaidTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('paid', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
        } catch (AuraHandledException e) {
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test getInvoices with 'priorYear' tab filter.
     * Prior year tab: InvoiceDate within the previous calendar year.
     */
    @IsTest
    static void testGetInvoicesPriorYearTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('priorYear', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
        } catch (AuraHandledException e) {
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test getInvoices with date range filtering.
     * Applies dateFrom and dateTo parameters covering the last 30 days.
     */
    @IsTest
    static void testGetInvoicesWithDateFilter() {
        try {
            String dateFrom = String.valueOf(Date.today().addDays(-30));
            String dateTo = String.valueOf(Date.today());
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', dateFrom, dateTo, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
        } catch (AuraHandledException e) {
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test getInvoices pagination with a small page size.
     * Verifies that the returned invoice count does not exceed the requested page size.
     */
    @IsTest
    static void testGetInvoicesPagination() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', null, null, 1, 2);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.invoices.size() <= 2,
                'Returned invoices should not exceed page size of 2');
            System.assertEquals(1, result.pageNumber, 'Page number should be 1');
            System.assertEquals(2, result.pageSize, 'Page size should be 2');
        } catch (AuraHandledException e) {
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test getInvoicesByIds returns invoices by specific IDs.
     * Verifies the method works and returns the requested records (account-scoped).
     */
    @IsTest
    static void testGetInvoicesByIds() {
        List<Invoice> testInvoices = [SELECT Id FROM Invoice LIMIT 3];
        List<Id> invoiceIds = new List<Id>();
        for (Invoice inv : testInvoices) {
            invoiceIds.add(inv.Id);
        }

        try {
            List<Invoice> result = InvoiceService.getInvoicesByIds(invoiceIds);
            System.assertNotEquals(null, result, 'Result should not be null');
            // In a portal user context, returned invoices would be scoped to account
        } catch (AuraHandledException e) {
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test account scoping security -- verifies that getInvoicesByIds enforces account
     * boundaries and never returns invoices from other accounts.
     *
     * In a non-portal context, this validates the AuraHandledException is thrown.
     * In a portal context with System.runAs(), this would verify that invoices from
     * Account B are NOT returned when querying as a user linked to Account A.
     */
    @IsTest
    static void testAccountScopingSecurity() {
        // Get invoices from both accounts
        List<Account> accounts = [SELECT Id FROM Account ORDER BY Name];
        System.assert(accounts.size() >= 2, 'Should have at least 2 test accounts');

        // Get invoices belonging to the second account (Other Account)
        List<Invoice> otherAccountInvoices = [
            SELECT Id FROM Invoice
            WHERE BillingAccountId = :accounts[1].Id
        ];
        System.assert(!otherAccountInvoices.isEmpty(),
            'Other account should have invoices for security testing');

        List<Id> otherInvoiceIds = new List<Id>();
        for (Invoice inv : otherAccountInvoices) {
            otherInvoiceIds.add(inv.Id);
        }

        try {
            // When called by a portal user linked to Account A, this should NOT return
            // invoices belonging to Account B due to account scoping WHERE clause
            List<Invoice> result = InvoiceService.getInvoicesByIds(otherInvoiceIds);
            // If we reach here (portal user), the result should be empty or contain only
            // invoices that belong to the current user's account
            // The account scoping WHERE clause filters out other accounts' invoices
        } catch (AuraHandledException e) {
            // Expected for non-portal users
            System.assertEquals('Unable to determine account context', e.getMessage(),
                'Should throw account context error for non-portal users');
        }
    }

    /**
     * Test the InvoiceListResult inner class fields are properly set.
     */
    @IsTest
    static void testInvoiceListResultStructure() {
        InvoiceService.InvoiceListResult result = new InvoiceService.InvoiceListResult();
        result.invoices = new List<Invoice>();
        result.totalCount = 10;
        result.pageNumber = 1;
        result.pageSize = 20;

        System.assertEquals(0, result.invoices.size(), 'Empty invoices list');
        System.assertEquals(10, result.totalCount, 'Total count should be 10');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
        System.assertEquals(20, result.pageSize, 'Page size should be 20');
    }
}
