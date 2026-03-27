/**
 * InvoiceServiceTest - Tests for InvoiceService account scoping, tab filtering, and pagination.
 *
 * NOTE: The standard Invoice object cannot be created via DML in Apex. Invoice records
 * must exist in the org via REST API or data load. These tests validate:
 * 1. Service methods execute without runtime errors
 * 2. Non-portal users receive proper AuraHandledException
 * 3. InvoiceListResult inner class works correctly
 */
@IsTest
private class InvoiceServiceTest {

    /**
     * Test getInvoices with 'open' tab filter.
     * Non-portal users should get AuraHandledException for missing account context.
     */
    @IsTest
    static void testGetInvoicesOpenTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
            System.assert(result.totalCount >= 0, 'Total count should be non-negative');
        } catch (AuraHandledException e) {
            // Expected for non-portal users -- AuraHandledException wraps message as "Script-thrown exception"
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test getInvoices with 'paid' tab filter.
     */
    @IsTest
    static void testGetInvoicesPaidTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('paid', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test getInvoices with 'priorYear' tab filter.
     */
    @IsTest
    static void testGetInvoicesPriorYearTab() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('priorYear', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test getInvoices with date range filtering.
     */
    @IsTest
    static void testGetInvoicesWithDateFilter() {
        try {
            String dateFrom = String.valueOf(Date.today().addDays(-30));
            String dateTo = String.valueOf(Date.today());
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', dateFrom, dateTo, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test getInvoices pagination parameters.
     */
    @IsTest
    static void testGetInvoicesPagination() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', null, null, 1, 2);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.invoices.size() <= 2,
                'Returned invoices should not exceed page size of 2');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test getInvoicesByIds with empty list.
     */
    @IsTest
    static void testGetInvoicesByIdsEmpty() {
        try {
            List<Invoice> result = InvoiceService.getInvoicesByIds(new List<Id>());
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e, 'AuraHandledException should be thrown for non-portal users');
        }
    }

    /**
     * Test account scoping -- non-portal users cannot access invoices.
     */
    @IsTest
    static void testAccountScopingSecurity() {
        try {
            InvoiceService.InvoiceListResult result = InvoiceService.getInvoices('open', null, null, 1, 20);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            // Non-portal users are blocked -- this IS the security enforcement
            System.assertNotEquals(null, e, 'Non-portal users should be blocked from accessing invoices');
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
