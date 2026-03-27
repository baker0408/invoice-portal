# Project Research Summary

**Project:** B2B Invoice Payment Portal
**Domain:** Salesforce B2B Commerce (LWR) -- Self-Service Invoice Payment
**Researched:** 2026-03-27
**Confidence:** HIGH

## Executive Summary

This project is a Salesforce-native B2B invoice payment portal built entirely on the B2B Commerce LWR Experience Cloud platform. There are no framework choices to make -- the stack is fully constrained to LWC for UI, Apex for server-side logic, and the Salesforce Payments SDK v7.0.0 for PCI-compliant payment processing (Stripe under the hood). The data model is thin: three custom fields on the standard Invoice object, one custom junction object (Invoice_Payment_Line__c), and one Custom Metadata Type for configuration. The architecture is a four-page LWC flow (List -> Detail -> Submit -> Confirm) backed by two Apex service controllers. Experts build this as a linear payment journey with server-side security enforcement at every data access point.

The recommended approach is a strict dependency-ordered build: data model first, then Apex services with tests, then the invoice list UI, then the payment flow with SDK integration, and finally packaging. The SDK integration (paymentSubmission component) is the highest-risk piece due to Shadow DOM mounting issues, async script loading race conditions, and amount format ambiguity between dollars and cents. These must be validated with real Stripe test-mode transactions early -- not deferred to end-of-project testing.

The key risks are: (1) the Payments SDK failing to mount in LWC Shadow DOM (pass HTMLElement references, not CSS selectors), (2) dollar-vs-cent amount confusion causing 100x payment errors (test with Stripe dashboard immediately), (3) stale invoice balances during the multi-step payment flow (re-validate server-side before creating PaymentIntent), and (4) unmanaged package deployment failing silently when target orgs lack Order Management prerequisites (build a diagnostic post-install checker). All four risks have known mitigations documented in the research.

## Key Findings

### Recommended Stack

The entire stack is Salesforce platform-native. No external frameworks, no npm dependencies in production, no middleware. The core runtime is Salesforce Platform API v66.0 (Spring '26), B2B Commerce LWR for the storefront, LWC for all UI components, and Apex for server-side logic. Payment processing uses the Salesforce Payments Client Side SDK v7.0.0 loaded via `loadScript()`. Development tooling is `sf` CLI v2 (sfdx v7 is deprecated), VS Code with Salesforce Extensions, and sfdx-lwc-jest for LWC unit testing.

**Core technologies:**
- **LWC on LWR Experience Cloud**: Only supported UI framework for B2B Commerce LWR sites (Aura incompatible)
- **Apex v66.0**: Two controllers (InvoiceService, PaymentService) handle all data access and business logic with `WITH SECURITY_ENFORCED`
- **Salesforce Payments SDK v7.0.0**: PCI-compliant iframe-based payment forms; abstracts Stripe; supports ACH and Credit Card
- **Standard Invoice/Payment objects**: Platform auto-calculates Invoice.Balance from PaymentLineItems -- no custom balance logic needed
- **Custom Metadata Types**: All configuration (fee %, payment toggles, page size, reason codes) deployable with unmanaged package
- **sfdx-lwc-jest**: LWC unit testing; Apex test classes required for 75% coverage deployment threshold

### Expected Features

**Must have (table stakes):**
- Invoice list with sorting, filtering, tabs (Open/Paid/Prior Year), and server-side pagination
- Multi-invoice selection with bulk payment (selection persistence across pagination)
- ACH + Credit Card payment methods via radio toggle
- Invoice PDF download (single + ZIP multi-download) and CSV export
- Real-time balance and status visibility with post-payment auto-update
- Saved payment methods and billing address pre-population
- Payment confirmation with transaction details
- Account-scoped invoice visibility (BillingAccountId + Sold_To_Account__c)
- WCAG 2.1 AA accessibility and site theme inheritance (zero custom CSS)

**Should have (differentiators):**
- Credit/debit invoice netting in a single payment transaction
- Short pay with configurable reason codes and optional comments
- Overpay support with required reason
- Editable payment amounts per invoice line in multi-invoice payments
- Merchant-absorbed processing fee tracking (prorated per invoice line)
- Unmanaged package deployable in under 30 minutes

**Defer (v2+):**
- PaymentLink with guest checkout (highest-impact differentiator but highest complexity; architecturally independent)
- Autopay/scheduled recurring payments
- Full payment history/activity log
- Email notifications (payment receipts, reminders)
- Multi-currency support

### Architecture Approach

The system is a four-page LWC architecture within a single B2B Commerce LWR Experience Cloud site. Each page is an independent LWC that communicates with the next via NavigationMixin page state (not URL params, not SessionStorage). Two stateless Apex controllers (InvoiceService for reads, PaymentService for writes/payment processing) enforce account-scoped security on every query. The Payments SDK mounts a PCI-compliant iframe into the paymentSubmission component. Post-payment, server-side Apex creates standard Payment/PaymentLineItem records (triggering automatic Invoice.Balance recalculation) plus custom Invoice_Payment_Line__c records for reason codes and fee tracking.

**Major components:**
1. **invoiceListView** (LWC) -- Invoice table with tabs, filters, pagination, row selection, and action buttons (Pay, Download, Export)
2. **invoicePaymentDetail** (LWC) -- Editable payment amounts per invoice, credit netting, short pay/overpay reasons, payment method toggle, running total
3. **paymentSubmission** (LWC) -- SDK mounting, billing address form, saved payment methods, payment confirmation trigger via `checkout.confirm()`
4. **paymentConfirmation** (LWC) -- Read-only success/failure display with transaction details
5. **InvoiceService** (Apex) -- Account-scoped SOQL queries, pagination, PDF generation, CSV export
6. **PaymentService** (Apex) -- PaymentIntent creation, balance re-validation, Payment/PaymentLineItem/Invoice_Payment_Line__c record creation, fee calculation, Portal_Status__c updates

### Critical Pitfalls

1. **SDK Shadow DOM mounting failure** -- Pass `this.template.querySelector('.payment-container')` (HTMLElement) to `sfp.checkout()`, never a CSS selector string. SDK cannot pierce LWC shadow boundary. Consider Light DOM for paymentSubmission.
2. **Amount format mismatch (dollars vs cents)** -- SDK docs are ambiguous. Test with Stripe test-mode transactions immediately in Phase 2. Verify amounts on Stripe dashboard. Add server-side sanity checks for amounts > 1,000,000.
3. **Invoice balance staleness** -- Re-query Invoice.Balance server-side in `createIntentFunction` before creating PaymentIntent. Compare against client-submitted amounts. Reject and force refresh if changed.
4. **SDK script loading race condition** -- Load in `connectedCallback` (not `renderedCallback`) with a boolean guard. Chain initialization via promise. Verify CSP settings allow inline scripts.
5. **Credit netting edge cases** -- Validate net payment > $0.00 in three places: client-side, `createIntentFunction`, and error handler. Handle zero-net case (credits fully offset debits) as a special non-gateway flow.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Foundation and Apex Services
**Rationale:** Everything depends on the data model. Both LWCs and Apex services require objects, fields, and metadata to exist. Apex services must be built and tested before LWCs can call them. This is the lowest-risk phase with the most predictable output.
**Delivers:** Deployable metadata (custom fields on Invoice, Invoice_Payment_Line__c object, Invoice_Portal_Config__mdt, permission sets) plus working InvoiceService and PaymentService Apex controllers with test classes.
**Addresses:** Configurable settings (CMDT), account-scoped security, server-side pagination, data model for all downstream features.
**Avoids:** Account scoping security pitfall (enforce from day one), inline constants anti-pattern (CMDT from day one).

### Phase 2: Invoice List View
**Rationale:** The list view is the application entry point. It validates the data model end-to-end (queries real Invoice data), exercises InvoiceService thoroughly, and produces a demo-able artifact early. It is also the prerequisite for the payment flow (users select invoices here).
**Delivers:** Fully functional invoice list page with tabs (Open/Paid/Prior Year), date range filtering, server-side pagination, multi-row selection with persistence across pages, and the three action buttons (Pay Invoices, Download, Export).
**Addresses:** Invoice list view, multi-invoice selection, PDF download, CSV export, pagination, filtering.
**Avoids:** Client-side filtering anti-pattern, selection state loss across pagination.

### Phase 3: Payment Detail and Submission
**Rationale:** This is the core value-delivery phase and the highest-risk phase. It integrates the Payments SDK (Shadow DOM, async loading, amount format), implements credit netting and short pay logic, and connects the multi-page navigation flow. Build this as one phase because the detail and submission components are tightly coupled -- the detail page produces the payload the submission page consumes.
**Delivers:** invoicePaymentDetail (editable amounts, netting, reasons, payment method toggle), paymentSubmission (SDK integration, billing address, saved methods, payment processing), paymentConfirmation (success/failure display), and the complete post-payment processing pipeline (Payment/PaymentLineItem/Invoice_Payment_Line__c creation, balance update, status update, fee recording).
**Addresses:** Credit netting, short pay/overpay, payment method selection, SDK integration, saved payment methods, billing address, payment confirmation, processing fee tracking, post-payment balance updates.
**Avoids:** SDK Shadow DOM mounting failure, amount format mismatch, balance staleness, script loading race condition, credit netting edge cases, preferLegacyForms default.

### Phase 4: Integration Testing and Polish
**Rationale:** With all components functional, this phase focuses on end-to-end validation, error handling polish, SDK theming with live B2B Commerce site CSS, and edge case testing. The "Looks Done But Isn't" checklist from PITFALLS.md drives the acceptance criteria.
**Delivers:** Polished error handling (user-friendly messages, Error_Log__c), SDK theme pulling designTokens from site CSS properties, navigation guards (unsaved changes warning), dark mode support, session timeout handling, and comprehensive test coverage.
**Addresses:** Error handling polish, site theme inheritance, WCAG 2.1 AA audit, all items from the "Looks Done But Isn't" checklist.
**Avoids:** Hardcoded theme values anti-pattern, raw SDK error exposure, payment form re-mount on address change.

### Phase 5: Packaging and Deployment
**Rationale:** Packaging is the final phase because the unmanaged package must contain all tested, polished components. This phase also creates the post-install diagnostic tool and deployment guide -- both identified as critical for the "under 30 minutes" deployment target.
**Delivers:** Unmanaged package, post-install diagnostic component (checks Order Management, Salesforce Payments, PaymentMethodSet prerequisites), setup guide, demo data scripts.
**Addresses:** Unmanaged package deployment target, prerequisite validation.
**Avoids:** Package deploying without prerequisite checks, custom fields missing FLS in permission sets.

### Phase Ordering Rationale

- **Data before services, services before UI**: The dependency graph is strict. SOQL queries require objects/fields. LWCs require Apex methods. Building bottom-up eliminates mocking overhead and catches data model issues early.
- **List before Payment**: The list page is simpler, lower-risk, and produces a demo-able artifact quickly. It also validates the data model and InvoiceService before the high-risk payment flow begins.
- **Payment Detail + Submission together**: These components share a data contract (the payment payload) and must be developed in tandem. Splitting them creates integration risk at the handoff point.
- **Polish as separate phase**: SDK theming requires a deployed B2B Commerce site. Error handling patterns are cross-cutting. Testing the "Looks Done But Isn't" checklist requires all components to exist. Separating polish from functional development prevents premature optimization.
- **Packaging last**: Cannot package incomplete work. The diagnostic tool requires knowledge of all prerequisite dependencies, which are only fully understood after building the complete system.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Payment Detail and Submission):** The Payments SDK integration is the highest-risk work. The amount format ambiguity (dollars vs cents) can only be resolved by testing against Stripe. The `createIntentFunction` return shape must match what the SDK expects (raw Stripe PaymentIntent JSON). The `updateIntentFunction` must be implemented even as a near-no-op. Research the exact SDK contract with a spike before full implementation.
- **Phase 5 (Packaging):** Unmanaged package creation and prerequisite validation for Order Management / Salesforce Payments enablement is org-configuration-dependent. Research specific packaging constraints and post-install script capabilities.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Data Foundation):** Standard SFDX metadata deployment. Well-documented Apex patterns. No unknowns.
- **Phase 2 (Invoice List View):** lightning-datatable with server-side pagination is a thoroughly documented pattern. No SDK dependencies.
- **Phase 4 (Integration Testing and Polish):** Error handling and theming patterns are documented in the research. Execution-focused, not research-dependent.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Fully constrained by platform. No decisions to make -- all technologies are mandated by Salesforce B2B Commerce LWR. Versions pinned. |
| Features | HIGH | Feature landscape well-mapped against 6+ competitor products (Billtrust, Versapay, Gaviti, Bill360, Invoiced). PRD alignment verified. Clear MVP/defer boundaries. |
| Architecture | HIGH | Four-page LWC architecture with two Apex controllers is straightforward. Data flow is linear. PRD and SDK docs provide detailed component specifications. |
| Pitfalls | MEDIUM-HIGH | SDK-specific pitfalls (Shadow DOM, amount format, script loading) are well-documented in community. Amount format ambiguity is the one area needing empirical validation -- cannot be resolved by reading docs alone. |

**Overall confidence:** HIGH

### Gaps to Address

- **SDK amount format (dollars vs cents):** Documentation is ambiguous. Must be validated empirically with a Stripe test-mode transaction in Phase 3. Build a minimal spike early.
- **`createIntentFunction` return shape:** SDK expects the raw Stripe PaymentIntent object. The exact Apex-to-SDK contract (what fields, what format) needs validation against the SDK source or a working example.
- **Payment record linkage to PaymentGateway:** PITFALLS.md notes that orphaned Payment records (not linked to PaymentGateway/PaymentGroup) may not trigger platform balance recalculation. Validate whether the standard Invoice.Balance auto-recalculation requires specific Payment record relationships.
- **Light DOM vs Shadow DOM for paymentSubmission:** Two viable approaches for SDK mounting. Light DOM is simpler but has CSS scoping implications. HTMLElement passing works in Shadow DOM but requires careful lifecycle management. Decide during Phase 3 planning.
- **ZIP download governor limits:** Synchronous PDF generation for multi-invoice ZIP download may hit Apex CPU time limits with 5+ invoices. Phase 2 should start with synchronous and flag for async refactor if needed.

## Sources

### Primary (HIGH confidence)
- Salesforce Spring '26 Release Notes - API v66.0
- Salesforce Payments SDK v7.0.0 Documentation (local copy: docs/payments-sdk.md)
- B2B Commerce LWR Storefront Performance Best Practices (Salesforce developer docs)
- Build Custom Components for B2B Commerce (Salesforce developer docs)
- LWC Shadow DOM / Light DOM documentation (Salesforce developer docs)
- Create a Custom Payment Component for B2B Commerce (Salesforce developer docs)
- Invoice Object Reference (Salesforce developer docs)
- NavigationMixin for LWR (Salesforce developer docs)
- LWC Jest Testing Installation (Salesforce developer docs)

### Secondary (MEDIUM confidence)
- Gaviti, Billtrust, Versapay, Bill360, Invoiced competitor analysis (feature landscape)
- loadScript rejecting with empty exception (GitHub Issue salesforce/lwc#2640)
- Twistellar B2B Commerce on LWR analysis
- PYMNTS, OnPhase, Rillion B2B payment trend reports (2026)

### Tertiary (LOW confidence)
- SDK amount format behavior (ambiguous in docs, needs empirical validation)
- Payment record auto-balance recalculation prerequisites (inferred from object reference, not explicitly documented for this use case)

---
*Research completed: 2026-03-27*
*Ready for roadmap: yes*
