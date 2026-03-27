/**
 * InvoiceService - Account-scoped invoice queries with tab filtering and pagination.
 *
 * All SOQL queries enforce account scoping via BillingAccountId OR Sold_To_Account__c
 * to ensure users only see invoices belonging to their account (DATA-04).
 */
public with sharing class InvoiceService {

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
     * Query invoices for the current user's account with tab filtering, date range, and pagination.
     *
     * @param tab       Filter tab: 'open', 'paid', or 'priorYear'
     * @param dateFrom  Optional start date filter (YYYY-MM-DD string)
     * @param dateTo    Optional end date filter (YYYY-MM-DD string)
     * @param pageNumber  1-based page number
     * @param pageSize    Number of records per page
     * @return InvoiceListResult with invoices, totalCount, pageNumber, pageSize
     */
    @AuraEnabled(cacheable=true)
    public static InvoiceListResult getInvoices(String tab, String dateFrom, String dateTo, Integer pageNumber, Integer pageSize) {
        Id accountId = getAccountIdForCurrentUser();
        if (accountId == null) {
            throw new AuraHandledException('Unable to determine account context');
        }

        Integer offset = (pageNumber - 1) * pageSize;

        // Build dynamic SOQL with account scoping
        String baseWhere = '(BillingAccountId = :accountId OR Sold_To_Account__c = :accountId) AND Status NOT IN (\'Canceled\', \'Error\')';

        // Tab filters
        if (tab == 'open') {
            baseWhere += ' AND Balance > 0 AND Status = \'Posted\'';
        } else if (tab == 'paid') {
            baseWhere += ' AND (Status = \'Paid\' OR Balance = 0)';
        } else if (tab == 'priorYear') {
            Integer priorYear = Date.today().year() - 1;
            Date priorYearStart = Date.newInstance(priorYear, 1, 1);
            Date priorYearEnd = Date.newInstance(priorYear, 12, 31);
            baseWhere += ' AND InvoiceDate >= :priorYearStart AND InvoiceDate <= :priorYearEnd';
        }

        // Date range filters
        Date parsedDateFrom;
        Date parsedDateTo;
        if (String.isNotBlank(dateFrom)) {
            parsedDateFrom = Date.valueOf(dateFrom);
            baseWhere += ' AND InvoiceDate >= :parsedDateFrom';
        }
        if (String.isNotBlank(dateTo)) {
            parsedDateTo = Date.valueOf(dateTo);
            baseWhere += ' AND InvoiceDate <= :parsedDateTo';
        }

        String selectFields = 'Id, DocumentNumber, InvoiceDate, DueDate, TotalAmountWithTax, Balance, Status, PO_Number__c, Portal_Status__c';

        String query = 'SELECT ' + selectFields
            + ' FROM Invoice'
            + ' WHERE ' + baseWhere
            + ' WITH SECURITY_ENFORCED'
            + ' ORDER BY InvoiceDate DESC'
            + ' LIMIT :pageSize OFFSET :offset';

        String countQuery = 'SELECT COUNT() FROM Invoice WHERE ' + baseWhere + ' WITH SECURITY_ENFORCED';

        List<Invoice> invoices = Database.query(query);
        Integer totalCount = Database.countQuery(countQuery);

        InvoiceListResult result = new InvoiceListResult();
        result.invoices = invoices;
        result.totalCount = totalCount;
        result.pageNumber = pageNumber;
        result.pageSize = pageSize;
        return result;
    }

    /**
     * Query specific invoices by ID, scoped to the current user's account.
     * Only returns invoices belonging to the user's account -- never cross-account data.
     *
     * @param invoiceIds  List of Invoice record IDs to retrieve
     * @return List of Invoice records that belong to the user's account
     */
    @AuraEnabled(cacheable=true)
    public static List<Invoice> getInvoicesByIds(List<Id> invoiceIds) {
        Id accountId = getAccountIdForCurrentUser();
        if (accountId == null) {
            throw new AuraHandledException('Unable to determine account context');
        }

        return [
            SELECT Id, DocumentNumber, InvoiceDate, DueDate, TotalAmountWithTax,
                   Balance, Status, PO_Number__c, Portal_Status__c
            FROM Invoice
            WHERE Id IN :invoiceIds
              AND (BillingAccountId = :accountId OR Sold_To_Account__c = :accountId)
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Wrapper class for paginated invoice query results.
     */
    public class InvoiceListResult {
        @AuraEnabled public List<Invoice> invoices;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
    }
}
