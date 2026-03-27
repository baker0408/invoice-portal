# B2B Invoice Payment Portal

## What This Is

A self-service invoice payment portal built on Salesforce B2B Commerce (LWR) Experience Cloud, using the Salesforce Payments Client Side SDK v7.0.0. Bill-to and sold-to customers can view, filter, and pay invoices through a branded portal experience. Designed as a reusable demo asset / proof of concept, packaged as an unmanaged package for deployment into customer orgs and SE demo environments.

## Core Value

Customers can select and pay multiple invoices in a single session through a self-service portal — with credit/debit netting, short pay/overpay support, and real-time balance updates — without any manual coordination with AR.

## Requirements

### Validated

- ✓ Invoice_Payment_Line__c junction object for short pay reasons, comments, and fee allocation — Phase 1
- ✓ Portal_Status__c custom field for portal-specific status overlay (Open, In Progress, Paid) — Phase 1
- ✓ Account-scoped invoice visibility via BillingAccountId and Sold_To_Account__c — Phase 1
- ✓ Configurable settings via Custom Metadata (processing fee %, ACH/CC toggle, page size, short pay reasons) — Phase 1

### Active

- [ ] Invoice List View with tabs (Open, Paid, Prior Year), date range filtering, sorting, and server-side pagination
- [ ] Invoice selection with checkbox column (single, multi, select-all) for payment and download actions
- [ ] Invoice PDF download (single PDF or ZIP for multiple)
- [ ] Invoice list CSV export of current filtered view
- [ ] Invoice Payment Detail page with editable payment amounts per invoice
- [ ] Multi-invoice payment with credit and debit invoice netting
- [ ] Short pay and overpay support with required reason codes and optional comments
- [ ] Payment method selection (ACH or Credit Card) with radio toggle
- [ ] Payment summary showing payment total (credits netted against debits)
- [ ] Payment Submission page powered by Salesforce Payments SDK v7.0.0 checkout component
- [ ] Saved payment methods display and selection
- [ ] Billing address form pre-populated from account BillingAddress
- [ ] Post-payment processing: Payment and PaymentLineItem record creation, Invoice balance/status updates
- [ ] Credit card processing fee calculation and recording (merchant-absorbed, not customer-facing)
- [ ] Payment confirmation page with transaction details and success/failure handling
- [ ] B2B Commerce site theme inheritance — no custom CSS overrides
- [ ] Salesforce Payments SDK theme configured with type='slds' and designTokens from site CSS properties
- [ ] Error handling with user-friendly messages (no raw SDK errors exposed)
- [ ] Unmanaged package with all metadata (custom fields, LWCs, Apex, permission sets, page layouts)

### Out of Scope

- PaymentLink generation and guest checkout — deferred to v2, not needed for initial demo asset
- ERP or external system real-time integration — invoices assumed synced to Salesforce already
- Automated dunning or collections workflows — not needed for demo/POC
- Multi-currency support — single currency per org
- Mobile-native app — responsive web only
- Express checkout (Apple Pay, Google Pay) — not needed for invoice payments
- Volume discounts or early payment discount logic — not required
- Concurrent payment conflict handling — single-user payment assumption
- Customer-facing surcharge or processing fee display — merchant-absorbed only

## Context

- Built on the standard Salesforce Invoice object (API v48.0+) — maximizes compatibility with Revenue Cloud, Salesforce Billing, and ERP integration patterns
- Custom fields on Invoice limited to PO_Number__c, Portal_Status__c, and Sold_To_Account__c
- One custom junction object: Invoice_Payment_Line__c (links Payment to Invoice with reason codes, comments, processing fee allocation)
- Invoice.Balance is auto-calculated by the platform based on related Payment objects — no custom recalculation needed
- Salesforce Payments SDK v7.0.0 handles all PCI-sensitive payment form rendering via iframes
- Reference design screenshots exist showing Pepsi-branded examples of Invoice List View, Invoice Payment Detail, and Payment Submission pages
- Target deployment time: under 30 minutes from package install to working demo
- Component architecture: invoiceListView, invoicePaymentDetail, paymentSubmission, paymentConfirmation (LWCs) + invoiceService, paymentService (Apex controllers)

## Constraints

- **Platform**: Salesforce B2B Commerce (LWR) Experience Cloud — all UI is LWC, all backend is Apex
- **Payment SDK**: Salesforce Payments Client Side SDK v7.0.0 — pinned version, loaded via community basePath
- **Data Model**: Standard Invoice, InvoiceLine, Payment, PaymentLineItem objects — minimal custom field additions only
- **Packaging**: Unmanaged package — must be deployable without managed package dependencies
- **Project Structure**: SFDX project format (force-app/)
- **Theming**: Must inherit from host B2B Commerce site theme — zero hardcoded colors, fonts, or spacing
- **Security**: Invoice visibility scoped to logged-in user's account. CSRF via platform tokens. No PCI data touches merchant page.
- **Performance**: Invoice list page load under 2 seconds for up to 500 invoices
- **Accessibility**: WCAG 2.1 AA compliance for all custom LWC components

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Standard Invoice object over custom object | Maximizes compatibility with Revenue Cloud, Billing, and ERP patterns. All target orgs have Order Management enabled. | -- Pending |
| Processing fee merchant-absorbed, not customer-facing | Simplifies UX, avoids surcharge compliance issues | -- Pending |
| PaymentLink/guest checkout deferred to v2 | Reduces v1 scope, authenticated portal flow covers primary demo need | -- Pending |
| SFDX project structure | Standard Salesforce development approach, supports unmanaged package creation | -- Pending |
| CSV-only export format | Demo/POC asset — sufficient for proof of concept | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-27 after Phase 1 completion*
