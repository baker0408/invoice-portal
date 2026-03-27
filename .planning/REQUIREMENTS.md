# Requirements: B2B Invoice Payment Portal

**Defined:** 2026-03-27
**Core Value:** Customers can select and pay multiple invoices in a single session through a self-service portal — with credit/debit netting, short pay/overpay support, and real-time balance updates.

## v1 Requirements

### Invoice Management

- [ ] **INV-01**: User can view list of invoices with Invoice Date, Number, PO Number, Amount, Due Date, Amount Paid, Balance, and Status columns
- [ ] **INV-02**: User can switch between Open Invoices, Paid Invoices, and Prior Year Invoices tabs
- [ ] **INV-03**: User can filter invoices by date range (Date From / Date To)
- [ ] **INV-04**: User can sort invoices by Invoice Date, Number, Amount, Due Date, Balance, and Status
- [ ] **INV-05**: User can navigate paginated results (20 per page, server-side)
- [ ] **INV-06**: User can select individual invoices via checkbox or select-all on current page
- [ ] **INV-07**: User selection persists across pagination but resets on tab change
- [ ] **INV-08**: User can select invoices and click Pay Invoices to navigate to Payment Detail
- [ ] **INV-09**: User can download PDF for selected invoices (single PDF or ZIP for multiple)

### Payment Flow

- [ ] **PAY-01**: User sees selected invoices with Invoice Date, Number, Amount, Balance, Payment Amount, Balance Due, Reason, and Comments columns
- [ ] **PAY-02**: Payment Amount is pre-populated with Invoice.Balance and is editable
- [ ] **PAY-03**: Short pay (amount < balance) requires a reason code selection
- [ ] **PAY-04**: Overpay (amount > balance) requires a reason code selection
- [ ] **PAY-05**: Credit invoices (negative amounts) are auto-applied and read-only
- [ ] **PAY-06**: Reason = Other requires a comment (255 char max)
- [ ] **PAY-07**: User can toggle between ACH and Credit Card payment methods
- [ ] **PAY-08**: Payment summary displays Payment Total with credits netted against debits
- [ ] **PAY-09**: Pay Now button is disabled until all validation passes and total > $0.00
- [ ] **PAY-10**: Processing fee calculated internally for credit card payments (merchant-absorbed, not customer-facing)

### Payment Submission

- [ ] **SUB-01**: Payment form renders via SF Payments SDK v7.0.0 checkout component
- [ ] **SUB-02**: Amount Being Paid displays the payment total (read-only)
- [ ] **SUB-03**: Saved payment methods display above new payment form
- [ ] **SUB-04**: Billing address pre-populated from account BillingAddress
- [ ] **SUB-05**: User can save payment method for future use
- [ ] **SUB-06**: Submit Payment triggers checkout.confirm() and processes payment
- [ ] **SUB-07**: Success navigates to confirmation page with transaction details
- [ ] **SUB-08**: Failure displays user-friendly error message with retry option

### Post-Payment

- [ ] **POST-01**: Payment record created with PaymentResponse data
- [ ] **POST-02**: Invoice_Payment_Line__c records created linking Payment to each Invoice with applied amount
- [ ] **POST-03**: Short pay reason and comments stored on Invoice_Payment_Line__c
- [ ] **POST-04**: Invoice.Balance auto-updates via standard platform mechanics
- [ ] **POST-05**: Portal_Status__c updated (Open -> In Progress for partial, Paid for full)
- [ ] **POST-06**: Processing fee recorded on payment record for accounting

### Data Model

- [x] **DATA-01**: Custom fields on Invoice: PO_Number__c, Portal_Status__c, Sold_To_Account__c
- [x] **DATA-02**: Invoice_Payment_Line__c junction object with Payment__c, Invoice__c, Payment_Amount__c, Short_Pay_Reason__c, Comments__c, Processing_Fee__c
- [x] **DATA-03**: Custom Metadata for configurable settings (processing fee %, ACH/CC toggle, page size, short pay reasons, PaymentLink TTL)
- [ ] **DATA-04**: All Apex queries enforce account scoping via BillingAccountId and Sold_To_Account__c

### Theming

- [ ] **THEME-01**: All LWC components inherit styling from B2B Commerce site theme
- [ ] **THEME-02**: SF Payments SDK theme configured with type='slds' and designTokens from site CSS properties

## v2 Requirements

### PaymentLink & Guest Checkout

- **LINK-01**: Sales rep can generate PaymentLink from Invoice or Account record
- **LINK-02**: PaymentLink encodes invoice IDs and amount in signed, expiring token
- **LINK-03**: Authenticated users land on payment form with invoices pre-loaded
- **LINK-04**: Unauthenticated users can access payment form via token without login
- **LINK-05**: Guest checkout collects billing details on form (no user context)
- **LINK-06**: Tokens are single-use and expire after configurable TTL (default 72 hours)

### Export & Reporting

- **EXP-01**: Invoice list CSV export of current filtered view
- **EXP-02**: Payment data exported to CSV for ERP consumption

### Error Handling & Polish

- **ERR-01**: Error_Log__c object for SDK error logging
- **ERR-02**: User-friendly error messages for all failure scenarios
- **ERR-03**: Network timeout retry with exponential backoff
- **ERR-04**: Invoice state change detection with refresh prompt

### Packaging

- **PKG-01**: Unmanaged package with all metadata (custom fields, LWCs, Apex, permission sets, page layouts)
- **PKG-02**: Post-install setup guide
- **PKG-03**: Deployable in under 30 minutes

## Out of Scope

| Feature | Reason |
|---------|--------|
| ERP/external system real-time integration | Demo asset — invoices assumed synced to Salesforce already |
| Automated dunning/collections workflows | Separate product category, massive scope |
| Multi-currency support | Single currency per org, adds testing complexity |
| Mobile-native app | Responsive web only, B2B is desktop-dominant |
| Express checkout (Apple Pay, Google Pay) | Consumer payment patterns, not B2B |
| Volume/early payment discounts | Contract-specific, requires pricing engine |
| Concurrent payment conflict handling | Single-user payment assumption, production-grade work |
| Customer-facing surcharge/fee display | Surcharge compliance complexity, merchant-absorbed model avoids this |
| Dispute management workflow | Entire product domain, short pay reasons serve as lightweight signal |
| Autopay/scheduled recurring payments | Requires scheduling infrastructure, retry logic, notification system |
| Email notifications | Requires templates, delivery infrastructure, preference management |
| WCAG 2.1 AA accessibility | Deferred — SF Payments SDK handles its own a11y, custom LWCs need future audit |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 1 | Complete |
| DATA-02 | Phase 1 | Complete |
| DATA-03 | Phase 1 | Complete |
| DATA-04 | Phase 1 | Pending |
| INV-01 | Phase 2 | Pending |
| INV-02 | Phase 2 | Pending |
| INV-03 | Phase 2 | Pending |
| INV-04 | Phase 2 | Pending |
| INV-05 | Phase 2 | Pending |
| INV-06 | Phase 2 | Pending |
| INV-07 | Phase 2 | Pending |
| INV-08 | Phase 2 | Pending |
| INV-09 | Phase 2 | Pending |
| THEME-01 | Phase 2 | Pending |
| PAY-01 | Phase 3 | Pending |
| PAY-02 | Phase 3 | Pending |
| PAY-03 | Phase 3 | Pending |
| PAY-04 | Phase 3 | Pending |
| PAY-05 | Phase 3 | Pending |
| PAY-06 | Phase 3 | Pending |
| PAY-07 | Phase 3 | Pending |
| PAY-08 | Phase 3 | Pending |
| PAY-09 | Phase 3 | Pending |
| PAY-10 | Phase 3 | Pending |
| SUB-01 | Phase 4 | Pending |
| SUB-02 | Phase 4 | Pending |
| SUB-03 | Phase 4 | Pending |
| SUB-04 | Phase 4 | Pending |
| SUB-05 | Phase 4 | Pending |
| SUB-06 | Phase 4 | Pending |
| SUB-07 | Phase 4 | Pending |
| SUB-08 | Phase 4 | Pending |
| THEME-02 | Phase 4 | Pending |
| POST-01 | Phase 5 | Pending |
| POST-02 | Phase 5 | Pending |
| POST-03 | Phase 5 | Pending |
| POST-04 | Phase 5 | Pending |
| POST-05 | Phase 5 | Pending |
| POST-06 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39
- Unmapped: 0

---
*Requirements defined: 2026-03-27*
*Last updated: 2026-03-27 after roadmap creation*
