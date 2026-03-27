# Architecture Patterns

**Domain:** B2B Invoice Payment Portal on Salesforce B2B Commerce (LWR)
**Researched:** 2026-03-27

## Recommended Architecture

The portal follows a four-page LWC architecture with two Apex service controllers, one external SDK integration point, and a thin custom data model layered on top of standard Salesforce objects. The entire system runs within a B2B Commerce LWR Experience Cloud site -- no external services, no middleware, no separate frontend.

```
+-------------------------------------------------------------------+
|                  B2B Commerce LWR Experience Site                  |
|                                                                   |
|  +------------------+    +----------------------+                 |
|  | invoiceListView  |--->| invoicePaymentDetail |                 |
|  | (Page LWC)       |    | (Page LWC)           |                 |
|  +--------+---------+    +----------+-----------+                 |
|           |                         |                             |
|           v                         v                             |
|  +------------------+    +----------------------+                 |
|  | invoiceService   |    | paymentService       |                 |
|  | (Apex Controller)|    | (Apex Controller)    |                 |
|  +--------+---------+    +----------+-----------+                 |
|           |                    |          |                        |
|           v                    v          v                        |
|  +------------------+  +-----------+ +------------------------+   |
|  | Invoice (Std)    |  | Payment   | | Invoice_Payment_Line__c|   |
|  | InvoiceLine (Std)|  | (Std)     | | (Custom Junction)      |   |
|  +------------------+  | PaymentLI | +------------------------+   |
|                        | (Std)     |                              |
|                        +-----------+                              |
|                                                                   |
|  +----------------------+    +----------------------+             |
|  | paymentSubmission    |--->| paymentConfirmation  |             |
|  | (Page LWC)           |    | (Page LWC)           |             |
|  +----------+-----------+    +----------------------+             |
|             |                                                     |
|             v                                                     |
|  +------------------------------------------+                     |
|  | Salesforce Payments SDK v7.0.0           |                     |
|  | (SFPayments -> Checkout -> confirm())    |                     |
|  | Loaded via basePath /sfsites/assets/...  |                     |
|  +------------------------------------------+                     |
|             |                                                     |
|             v                                                     |
|  +------------------------------------------+                     |
|  | Payment Gateway (Stripe via SF Payments) |                     |
|  | PCI iframe rendering, tokenization       |                     |
|  +------------------------------------------+                     |
+-------------------------------------------------------------------+
```

### Component Boundaries

| Component | Type | Responsibility | Communicates With | Data Owned |
|-----------|------|---------------|-------------------|------------|
| **invoiceListView** | Page-level LWC | Invoice table display: tabs (Open/Paid/Prior Year), date range filtering, server-side pagination, row selection via checkboxes, action buttons (Pay, Download, Export) | invoiceService (Apex wire/imperative), invoicePaymentDetail (navigation with selected invoice IDs) | Selection state, filter state, active tab |
| **invoicePaymentDetail** | Page-level LWC | Editable payment amounts per invoice, short pay/overpay reason codes, payment method toggle (ACH/CC), credit invoice netting, payment summary calculation | invoiceService (re-query balances), paymentSubmission (navigation with payment payload) | Payment amounts, reasons, comments, method choice |
| **paymentSubmission** | Page-level LWC | SDK mounting, billing address form, saved payment method display, payment confirmation trigger | Salesforce Payments SDK (SFPayments.checkout, checkout.confirm), paymentService (createIntentFunction, post-payment processing), paymentConfirmation (navigation) | Billing address, SDK component instance |
| **paymentConfirmation** | Page-level LWC | Success/failure display, transaction details, retry on failure | paymentService (read confirmation data) | None (read-only display) |
| **invoiceService** | Apex Controller | SOQL queries against Invoice with account-scoped security (BillingAccountId, Sold_To_Account__c), pagination, filtering, PDF generation, CSV export | Invoice (Standard), InvoiceLine (Standard) | None (stateless queries) |
| **paymentService** | Apex Controller | PaymentIntent creation via Salesforce Payments API, processing fee calculation, Payment/PaymentLineItem/Invoice_Payment_Line__c record creation, Portal_Status__c updates | Payment (Standard), PaymentLineItem (Standard), Invoice_Payment_Line__c (Custom), Invoice (Standard - status update) | None (stateless, creates records) |
| **Invoice_Portal_Settings__mdt** | Custom Metadata | Org-level configuration: processing fee %, ACH/CC toggles, page size, short pay reasons, PaymentLink TTL | Read by invoicePaymentDetail, paymentService | Configuration values |

### Data Flow

#### Flow 1: Invoice List Loading

```
User navigates to Invoices page
    |
    v
invoiceListView.connectedCallback()
    |
    v
@wire invoiceService.getInvoices(accountId, tab, filters, pageNum, pageSize)
    |
    v
Apex: SOQL on Invoice WHERE BillingAccountId = :accountId
      OR Sold_To_Account__c = :accountId
      WITH SECURITY_ENFORCED
      ORDER BY InvoiceDate DESC
      LIMIT :pageSize OFFSET :offset
    |
    v
Return List<Invoice> with calculated fields (Amount Paid = TotalAmountWithTax - Balance)
    |
    v
invoiceListView renders lightning-datatable with checkbox column
```

#### Flow 2: Invoice Selection to Payment Detail

```
User selects invoices via checkboxes -> clicks "Pay Invoices"
    |
    v
invoiceListView collects selected Invoice IDs
    |
    v
NavigationMixin.Navigate to invoicePaymentDetail page
    with state: { invoiceIds: JSON.stringify(selectedIds) }
    |
    v
invoicePaymentDetail.connectedCallback()
    |
    v
Imperative call: invoiceService.getInvoicesByIds(invoiceIds)
    (Re-queries to get fresh Balance values -- stale data guard)
    |
    v
Render editable table:
    - Debit invoices: Payment Amount pre-filled with Balance, editable
    - Credit invoices: Payment Amount = negative balance, read-only
    - Running total: sum of all Payment Amounts (credits net against debits)
```

#### Flow 3: Payment Submission (the critical path)

```
User clicks "Pay Now" on invoicePaymentDetail
    |
    v
invoicePaymentDetail validates all rows:
    - Payment Amount >= 0 and numeric
    - Reason required if Payment Amount != Balance
    - Comments required if Reason = "Other"
    - Total Payment > $0.00
    |
    v
NavigationMixin.Navigate to paymentSubmission page
    with state: { paymentPayload: JSON.stringify({
        invoices: [{id, paymentAmount, reason, comments}, ...],
        paymentMethod: 'ACH' | 'CreditCard',
        totalAmount: number
    })}
    |
    v
paymentSubmission.connectedCallback():
    1. Load SDK: loadScript(this, getSdkUrl())  -- basePath + /sfsites/assets/payments/v7/sfp.js
    2. Fetch metadata: fetch(getMetadataUrl())   -- basePath + /sfsites/assets/payments/metadata/v7.json
    3. Fetch PaymentMethodSet: imperative call to paymentService.getPaymentMethodSet()
    4. Fetch saved payment methods: paymentService.getSavedPaymentMethods(accountId)
    5. Pre-populate billing address from account BillingAddress
    |
    v
Mount checkout component:
    const sfp = new SFPayments({ report: errorHandler });
    const checkout = sfp.checkout(
        metadata,                           // from metadata fetch
        paymentMethodSet,                   // from Apex
        {
            labels: { /* suppress contact/shipping */ },
            theme: { type: 'slds', mode: 'light', designTokens: { /* from CSS vars */ } },
            actions: {
                createIntentFunction: async (intentRequest) => {
                    return await paymentService.createPaymentIntent({
                        amount: totalAmountInCents,
                        invoiceIds: [...],
                        processingFee: calculatedFee,
                        billingDetails: {...}
                    });
                },
                updateIntentFunction: async (intentId, updates) => {
                    return await paymentService.updatePaymentIntent(intentId, updates);
                }
            },
            options: {
                returnUrl: confirmationPageUrl,
                showSaveForFutureUsageCheckbox: true,
                showSaveAsDefaultCheckbox: true,
                preferLegacyForms: false,
                savedPaymentMethods: [...],   // from Apex
            }
        },
        {
            amount: totalAmountInCents,       // subunit (cents)
            currency: 'USD',
            country: 'US',
            locale: 'en'
        },
        '.payment-container'                  // DOM target
    );
    |
    v
User fills in payment details (rendered in PCI-compliant iframe by SDK)
    |
    v
User clicks "Submit Payment":
    const result = await checkout.confirm(
        createIntentFunction,    // optional override
        billingDetails,          // from billing address form
        null                     // no shipping
    );
    |
    v
SDK returns PaymentResponse:
    if (result.responseCode === ResponseCode.SUCCESS) {
        // result.data = { paymentData: {id, uuid, ...}, paymentToken, billingDetails, status }
        -> Call paymentService.processPayment(paymentResponseData, invoicePayload)
        -> Navigate to paymentConfirmation
    } else {
        // result.data = { error, status }
        -> Display user-friendly error, allow retry
    }
```

#### Flow 4: Post-Payment Processing (Server-Side)

```
paymentService.processPayment(paymentResponseData, invoicePayload)
    |
    v
1. Create Payment record:
    - PaymentNumber, Amount, PaymentDate, PaymentMethodId
    - Status = 'Processed'
    - AccountId from user context
    - GatewayRefNumber from paymentData.id
    |
    v
2. For each invoice in payload:
    a. Create PaymentLineItem (standard):
        - PaymentId = new Payment
        - LinkedEntityId = Invoice.Id
        - Amount = paymentAmount for this invoice
        - Type = 'Applied'
    b. Create Invoice_Payment_Line__c (custom junction):
        - Payment__c = new Payment
        - Invoice__c = Invoice.Id
        - Payment_Amount__c = paymentAmount
        - Short_Pay_Reason__c = reason (if short/overpay)
        - Comments__c = comments
        - Processing_Fee__c = prorated fee (CC only)
    |
    v
3. Update Invoice Portal_Status__c:
    - If new Balance = 0 -> Portal_Status__c = 'Paid'
    - If new Balance > 0 and Balance < TotalAmountWithTax -> Portal_Status__c = 'In Progress'
    (Invoice.Balance auto-recalculates from PaymentLineItems -- no manual calc needed)
    |
    v
4. Calculate and record processing fee:
    - If payment method = Credit Card:
        fee = totalPayment * (Processing_Fee_Percent / 100)
    - Store on Payment record (merchant internal, not customer-facing)
    - Prorate across Invoice_Payment_Line__c records
```

### Inter-Page Data Passing

Data flows between LWC pages via LWR navigation state. This is a critical architectural decision because LWR Experience Cloud pages are independent -- they do not share component state.

| From | To | Mechanism | Data Passed |
|------|----|-----------|-------------|
| invoiceListView | invoicePaymentDetail | NavigationMixin + page state | Selected Invoice IDs (JSON array) |
| invoicePaymentDetail | paymentSubmission | NavigationMixin + page state | Full payment payload: invoice details, amounts, reasons, payment method, total |
| paymentSubmission | paymentConfirmation | NavigationMixin + page state | Payment confirmation ID, success/failure status |

**Why page state over alternatives:**
- SessionStorage is an option but breaks if user opens multiple tabs
- URL params have length limits and expose data
- Custom Events do not work across LWR pages (different component trees)
- Platform cache (Apex) works but adds unnecessary server round-trips

**Fallback pattern:** If page state is lost (direct URL navigation, browser refresh), each page should gracefully redirect to invoiceListView rather than showing a broken state.

## Patterns to Follow

### Pattern 1: Account-Scoped Security at the Apex Layer

**What:** Every SOQL query in invoiceService and paymentService includes a WHERE clause filtering by the current user's account. Never rely on client-side filtering for security.

**When:** Every data access operation.

**Example:**
```apex
@AuraEnabled(cacheable=true)
public static InvoiceListResult getInvoices(
    String tab, String dateFrom, String dateTo,
    Integer pageNumber, Integer pageSize
) {
    Id accountId = getAccountIdForCurrentUser();

    String query = 'SELECT Id, DocumentNumber, InvoiceDate, DueDate, '
        + 'TotalAmountWithTax, Balance, Status, PO_Number__c, Portal_Status__c '
        + 'FROM Invoice '
        + 'WHERE (BillingAccountId = :accountId OR Sold_To_Account__c = :accountId) '
        + 'AND Status NOT IN (\'Canceled\', \'Error\') ';

    // Tab-specific filters
    if (tab == 'open') {
        query += 'AND Balance > 0 AND Status = \'Posted\' ';
    } else if (tab == 'paid') {
        query += 'AND (Status = \'Paid\' OR Balance = 0) ';
    } else if (tab == 'priorYear') {
        query += 'AND InvoiceDate >= :priorYearStart AND InvoiceDate <= :priorYearEnd ';
    }

    query += 'WITH SECURITY_ENFORCED ORDER BY InvoiceDate DESC '
        + 'LIMIT :pageSize OFFSET :offset';

    return Database.query(query);
}
```

### Pattern 2: SDK Lifecycle Management in LWC

**What:** The Payments SDK script must be loaded asynchronously after the LWC renders. The checkout component must be mounted to a DOM element that exists. The component must be destroyed on disconnect.

**When:** paymentSubmission component lifecycle.

**Example:**
```javascript
import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import basePath from '@salesforce/community/basePath';

export default class PaymentSubmission extends LightningElement {
    sdkLoaded = false;
    checkoutComponent = null;

    async renderedCallback() {
        if (this.sdkLoaded) return;
        this.sdkLoaded = true;

        const sdkUrl = `${basePath}/sfsites/assets/payments/v7/sfp.js`;
        await loadScript(this, sdkUrl);

        const metadataUrl = `${basePath}/sfsites/assets/payments/metadata/v7.json`;
        const metadataResponse = await fetch(metadataUrl);
        const metadata = await metadataResponse.json();

        // Mount after DOM is ready
        this.mountCheckout(metadata);
    }

    mountCheckout(metadata) {
        const sfp = new SFPayments({
            report: (error) => this.handleSdkError(error)
        });

        const container = this.template.querySelector('.payment-container');
        this.checkoutComponent = sfp.checkout(
            metadata,
            this.paymentMethodSet,
            this.buildConfig(),
            this.buildPaymentRequest(),
            container  // pass HTMLElement directly, not selector string
        );
    }

    disconnectedCallback() {
        if (this.checkoutComponent) {
            this.checkoutComponent.destroy();
            this.checkoutComponent = null;
        }
    }
}
```

**Critical note on DOM targeting:** In LWC Shadow DOM, CSS selector strings passed to `sfp.checkout()` will not resolve because the SDK searches `document` scope. Pass the actual `HTMLElement` reference from `this.template.querySelector()` instead.

### Pattern 3: Stale Data Guard Before Payment

**What:** Re-query Invoice.Balance server-side at payment creation time. If any balance has changed since the user loaded the payment detail page, abort and force a refresh.

**When:** Inside `createIntentFunction` and `processPayment`.

**Example:**
```apex
// In createIntentFunction (called by SDK before payment)
public static PaymentIntentResult createPaymentIntent(PaymentIntentInput input) {
    // Re-query fresh balances
    Map<Id, Invoice> freshInvoices = new Map<Id, Invoice>([
        SELECT Id, Balance FROM Invoice WHERE Id IN :input.invoiceIds
    ]);

    for (InvoicePaymentLine line : input.lines) {
        Decimal freshBalance = freshInvoices.get(line.invoiceId).Balance;
        if (freshBalance != line.expectedBalance) {
            throw new AuraHandledException(
                'Invoice balances have changed. Please refresh and try again.'
            );
        }
    }

    // Proceed with PaymentIntent creation...
}
```

### Pattern 4: Configuration via Custom Metadata

**What:** All tunable values (processing fee %, payment method toggles, page size, short pay reasons) live in Custom Metadata Type records, not hardcoded.

**When:** Any value an admin might need to change per org or demo.

**Rationale:** Custom Metadata deploys with the unmanaged package, is queryable in Apex without SOQL limits counting against governor limits, and can be modified in production without code deployment.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Client-Side Invoice Filtering for Security

**What:** Querying all invoices and filtering by account in JavaScript.

**Why bad:** Exposes other accounts' invoice data in network responses. A user with browser dev tools could see invoices they should not access. Violates B2B multi-tenant security expectations.

**Instead:** All security filtering happens in SOQL WHERE clauses in Apex. The client never receives data it should not see.

### Anti-Pattern 2: Storing Payment Payload in URL Parameters

**What:** Passing invoice IDs and payment amounts as URL query parameters between pages.

**Why bad:** URL length limits (~2000 chars) break with more than approximately 30 invoices. Payment amounts in URLs are visible in browser history, server logs, and analytics. Users can tamper with amounts.

**Instead:** Use LWR navigation state for inter-page data passing. Validate all amounts server-side regardless of what the client sends.

### Anti-Pattern 3: Custom Balance Calculation

**What:** Manually calculating Invoice.Balance by summing PaymentLineItems in Apex triggers.

**Why bad:** The standard Invoice.Balance field is auto-calculated by the platform based on related Payment objects. Custom calculation creates race conditions, duplicates platform logic, and breaks if Salesforce changes the calculation.

**Instead:** Create proper Payment and PaymentLineItem records and let the platform auto-calculate Balance. Only manage Portal_Status__c manually.

### Anti-Pattern 4: Hardcoded Theme Values in SDK Configuration

**What:** Passing literal color hex codes or pixel values to the SDK Theme.designTokens.

**Why bad:** Breaks when deployed to an org with different branding. The whole point of the unmanaged package is zero-config theming.

**Instead:** Read CSS custom properties from the B2B Commerce site at runtime:
```javascript
const computedStyle = getComputedStyle(document.documentElement);
const designTokens = {
    'color-brand': computedStyle.getPropertyValue('--lwc-brandPrimary').trim(),
    'font-family': computedStyle.getPropertyValue('--lwc-fontFamily').trim(),
    // ... etc
};
```

### Anti-Pattern 5: SDK Selector String in Shadow DOM

**What:** Passing a CSS selector string like `'.payment-container'` to `sfp.checkout()`.

**Why bad:** LWC uses Shadow DOM. The SDK's internal `document.querySelector()` call cannot reach into the shadow tree. The checkout component silently fails to mount with no visible error.

**Instead:** Pass the actual HTMLElement: `this.template.querySelector('.payment-container')`.

## Scalability Considerations

| Concern | Demo (50 invoices) | Mid-Scale (5K invoices) | Enterprise (50K+ invoices) |
|---------|---------------------|------------------------|---------------------------|
| **Invoice List Query** | Simple SOQL, no index needed | Add custom index on BillingAccountId + InvoiceDate | Skinny table, custom indexes, consider async SOQL for exports |
| **Pagination** | OFFSET-based works fine | OFFSET degrades past page 100; switch to keyset pagination | Keyset pagination mandatory; OFFSET is O(n) |
| **CSV Export** | Synchronous Apex, return immediately | Asynchronous (Queueable), email download link | Batch Apex with chunked output |
| **Multi-Invoice Payment** | Single DML transaction | Single DML up to ~50 invoices | Batch DML; may need Queueable for 200+ line items |
| **Concurrent Payments** | Not handled (single-user assumption) | Optimistic locking on Invoice.Balance | FOR UPDATE locks, retry logic, conflict resolution UI |

**For this POC/demo asset:** The "Demo" column is the target. OFFSET pagination, synchronous export, and single-user payment assumption are all appropriate. Document the scaling path but do not build it.

## Suggested Build Order

The dependency graph dictates a specific build sequence. Components higher in the list are prerequisites for those below.

```
Phase 1: Data Foundation
    Invoice_Payment_Line__c (custom object)
    Custom fields on Invoice (PO_Number__c, Portal_Status__c, Sold_To_Account__c)
    Invoice_Portal_Settings__mdt (Custom Metadata Type)
    Permission Sets
        |
        v
Phase 2: Backend Services
    invoiceService (Apex) -- queries, filtering, pagination, account scoping
    paymentService (Apex) -- payment intent, record creation, fee calc
    Test classes for both services
        |
        v
Phase 3: Invoice List UI
    invoiceListView (LWC) -- tabs, filters, datatable, selection, actions
    PDF download logic
    CSV export logic
        |
        v
Phase 4: Payment Flow UI
    invoicePaymentDetail (LWC) -- editable amounts, validation, summary
    paymentSubmission (LWC) -- SDK integration, billing address, confirm
    paymentConfirmation (LWC) -- success/failure display
        |
        v
Phase 5: Integration & Polish
    SDK theming (SLDS token extraction from site)
    Saved payment methods
    Error handling (SDK error -> user-friendly messages)
    End-to-end testing in a B2B Commerce site
        |
        v
Phase 6: Packaging
    Unmanaged package assembly
    Post-install setup guide
    Demo data scripts
```

**Why this order:**
1. **Data first** because both Apex services and LWCs depend on the data model existing. You cannot write SOQL queries or create records without the objects and fields.
2. **Apex before LWC** because LWCs call Apex methods via @wire and imperative calls. Having working, tested Apex lets you develop LWCs against real data instead of mocking.
3. **List before Payment** because the list page is the entry point -- users select invoices there. The payment detail page receives data from the list. Building list first validates the data model end-to-end.
4. **Payment flow last** because it depends on everything: data model, Apex services, and the SDK. The SDK integration is the highest-risk piece (PCI iframes, async script loading, Shadow DOM targeting) and benefits from having stable supporting code.
5. **Theming and polish** as a separate pass because the SDK theme configuration requires a deployed B2B Commerce site to test against. Getting the functional flow working first, then polishing the visual integration, avoids blocking on site configuration.

## Sources

- PRD Section 9: Component Architecture (docs/invoice-portal-prd.md)
- Salesforce Payments Client Side SDK v7.0.0 documentation (docs/payments-sdk.md)
- PROJECT.md constraints and context (.planning/PROJECT.md)
- Salesforce standard Invoice object documentation (training data, MEDIUM confidence)
- LWC Shadow DOM behavior with third-party scripts (training data, HIGH confidence -- well-documented platform behavior)
