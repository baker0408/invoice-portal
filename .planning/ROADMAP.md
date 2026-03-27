# Roadmap: B2B Invoice Payment Portal

## Overview

This roadmap delivers a self-service invoice payment portal on Salesforce B2B Commerce (LWR) in five phases. We start with the data foundation (custom objects, fields, metadata, Apex services), then build the invoice list view as the application entry point, followed by the payment detail page with credit netting and short pay logic, then the SDK-powered payment submission, and finally the server-side post-payment processing pipeline. Each phase delivers a verifiable capability that unblocks the next.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Data Foundation** - Custom objects, fields, metadata, Apex services, and permission sets
- [ ] **Phase 2: Invoice List View** - Tabbed invoice list with filtering, pagination, selection, PDF download, and CSV export
- [ ] **Phase 3: Payment Detail** - Editable payment amounts, credit netting, short pay/overpay reasons, and payment method selection
- [ ] **Phase 4: Payment Submission** - SDK-powered payment form with saved methods, billing address, and payment confirmation
- [ ] **Phase 5: Post-Payment Processing** - Payment record creation, invoice balance updates, status tracking, and fee recording

## Phase Details

### Phase 1: Data Foundation
**Goal**: All custom metadata, objects, fields, Apex services, and permission sets exist and are deployable -- enabling all downstream UI and business logic development
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04
**Success Criteria** (what must be TRUE):
  1. Custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c) exist on Invoice and are accessible via SOQL
  2. Invoice_Payment_Line__c junction object exists with all fields (Payment__c, Invoice__c, Payment_Amount__c, Short_Pay_Reason__c, Comments__c, Processing_Fee__c) and is queryable
  3. Invoice_Portal_Config__mdt Custom Metadata records exist with configurable settings (processing fee %, ACH/CC toggle, page size, short pay reasons)
  4. InvoiceService Apex controller returns account-scoped invoice data (filtered by BillingAccountId and Sold_To_Account__c) with passing test classes
  5. PaymentService Apex controller stub exists with account-scoped security enforcement and passing test classes
**Plans**: 2 plans
Plans:
- [ ] 01-01-PLAN.md -- SFDX project scaffold, Invoice custom fields, junction object, CMDT, permission set
- [ ] 01-02-PLAN.md -- InvoiceService, PaymentService, TestDataFactory, and test classes

### Phase 2: Invoice List View
**Goal**: Users can browse, filter, sort, and act on their invoices through a fully functional list page that serves as the portal entry point
**Depends on**: Phase 1
**Requirements**: INV-01, INV-02, INV-03, INV-04, INV-05, INV-06, INV-07, INV-08, INV-09, THEME-01
**Success Criteria** (what must be TRUE):
  1. User sees a paginated invoice table with all required columns (Invoice Date, Number, PO Number, Amount, Due Date, Amount Paid, Balance, Status) and can navigate pages
  2. User can switch between Open Invoices, Paid Invoices, and Prior Year Invoices tabs, and selection resets on tab change
  3. User can filter by date range and sort by any sortable column, with results updating via server-side queries
  4. User can select individual invoices or select-all on current page, with selections persisting across pagination, then click Pay Invoices to navigate to the payment detail page
  5. User can download PDF for selected invoices (single or ZIP) and the component inherits all styling from the B2B Commerce site theme with zero custom CSS
**Plans**: TBD
**UI hint**: yes

### Phase 3: Payment Detail
**Goal**: Users can review selected invoices, edit payment amounts, apply credit netting, provide short pay/overpay reasons, and choose a payment method before proceeding to payment submission
**Depends on**: Phase 2
**Requirements**: PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, PAY-06, PAY-07, PAY-08, PAY-09, PAY-10
**Success Criteria** (what must be TRUE):
  1. User sees all selected invoices with editable Payment Amount fields pre-populated with Invoice.Balance, and credit invoices displayed as read-only auto-applied rows
  2. User who enters a short pay or overpay amount is required to select a reason code, and selecting "Other" requires a comment (255 char max)
  3. User can toggle between ACH and Credit Card payment methods and sees a Payment Summary showing the net total (credits offset against debits)
  4. Pay Now button remains disabled until all validation passes and the net payment total exceeds $0.00
  5. Processing fee is calculated internally for credit card payments without being displayed to the user
**Plans**: TBD
**UI hint**: yes

### Phase 4: Payment Submission
**Goal**: Users can submit payment through the Salesforce Payments SDK, with saved payment methods, billing address pre-population, and clear success or failure feedback
**Depends on**: Phase 3
**Requirements**: SUB-01, SUB-02, SUB-03, SUB-04, SUB-05, SUB-06, SUB-07, SUB-08, THEME-02
**Success Criteria** (what must be TRUE):
  1. Payment form renders via Salesforce Payments SDK v7.0.0 checkout component within the LWC, displaying the payment total as read-only
  2. User sees saved payment methods above the new payment form and can select one, or enter new payment details with option to save for future use
  3. Billing address form is pre-populated from the account BillingAddress and the SDK theme uses type='slds' with designTokens from site CSS properties
  4. User can click Submit Payment to trigger checkout.confirm(), and on success is navigated to a confirmation page with transaction details
  5. On failure, user sees a user-friendly error message (no raw SDK errors) with a retry option
**Plans**: TBD
**UI hint**: yes

### Phase 5: Post-Payment Processing
**Goal**: Successful payments create all required Salesforce records, update invoice balances and statuses, and record processing fees -- completing the end-to-end payment lifecycle
**Depends on**: Phase 4
**Requirements**: POST-01, POST-02, POST-03, POST-04, POST-05, POST-06
**Success Criteria** (what must be TRUE):
  1. After successful payment, a Payment record exists with data from the PaymentResponse and Invoice_Payment_Line__c records link the Payment to each Invoice with the correct applied amount
  2. Short pay reason codes and comments are stored on the corresponding Invoice_Payment_Line__c records
  3. Invoice.Balance auto-updates via standard platform mechanics after Payment/PaymentLineItem creation (no custom recalculation)
  4. Portal_Status__c reflects the correct state: "In Progress" for partial payments, "Paid" for full payments
  5. Processing fee is recorded on the payment record and prorated across Invoice_Payment_Line__c records for accounting

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Foundation | 0/2 | Planning complete | - |
| 2. Invoice List View | 0/0 | Not started | - |
| 3. Payment Detail | 0/0 | Not started | - |
| 4. Payment Submission | 0/0 | Not started | - |
| 5. Post-Payment Processing | 0/0 | Not started | - |
