# Feature Landscape

**Domain:** B2B Invoice Payment Portal (Salesforce B2B Commerce / LWR)
**Researched:** 2026-03-27

---

## Table Stakes

Features users expect from any B2B invoice payment portal. Missing any of these and the product feels incomplete or unusable for AP clerks and AR managers.

| Feature | Why Expected | Complexity | PRD Status | Notes |
|---------|--------------|------------|------------|-------|
| Invoice List View with sorting and filtering | Every AR portal (Billtrust, Versapay, Gaviti) has this. AP clerks need to find invoices fast. | Medium | In PRD (5.1) | Tabs for Open/Paid/Prior Year are a nice touch but standard pattern |
| Multi-invoice selection and bulk payment | Core value prop of any B2B portal. Paying invoices one-by-one is a dealbreaker. | Medium | In PRD (5.1.5) | Selection persistence across pagination is important -- PRD covers this |
| Multiple payment methods (ACH + Credit Card) | Industry standard. Versapay, Billtrust, Bill360 all support ACH + card minimum. | Low | In PRD (5.2.3) | Radio toggle between ACH/CC is the right UX for a demo asset |
| Invoice PDF download | AP clerks need records for their own systems. Every portal offers this. | Low | In PRD (5.1.4) | Single PDF + ZIP for multi-select is correct approach |
| Invoice balance and status visibility | Customers expect real-time balance visibility. Status tracking (Open/In Progress/Paid) is baseline. | Low | In PRD (5.1.1, 7.4) | Portal_Status__c overlay is well-designed |
| Post-payment invoice balance updates | Payments must reflect immediately. Stale balances destroy trust. | Medium | In PRD (5.4) | Leveraging standard Invoice.Balance auto-calculation is smart |
| Saved payment methods | Every major portal supports stored payment methods. Repeat payers expect this. | Low | In PRD (5.3.4) | Handled by SF Payments SDK -- minimal custom work |
| Billing address pre-population | Reduces friction. Every checkout flow does this. | Low | In PRD (5.3.1) | Pre-populated from Account BillingAddress |
| Payment confirmation with transaction details | Users need proof of payment for their records. | Low | In PRD (5.4) | paymentConfirmation LWC covers this |
| Error handling with user-friendly messages | Raw SDK errors or silent failures are unacceptable. | Medium | In PRD (11.1, 11.2) | Error_Log__c for internal logging is good practice |
| Account-scoped invoice visibility (security) | Bill-to/sold-to customers must only see their own invoices. Fundamental security requirement. | Medium | In PRD (6.3) | BillingAccountId + Sold_To_Account__c scoping |
| Server-side pagination | Required for performance with hundreds of invoices. Client-side pagination fails at scale. | Low | In PRD (5.1.6) | 20 per page default is appropriate |
| Configurable settings without code changes | Demo/POC assets must be easily customized per org. | Low | In PRD (10) | Custom Metadata approach is the right Salesforce pattern |
| WCAG 2.1 AA accessibility | Legal and ethical requirement. B2B buyers increasingly mandate accessibility compliance. | Medium | In PRD (6.5) | SF Payments SDK handles its own a11y; custom LWCs need audit |
| Site theme inheritance (no custom CSS) | For a reusable demo asset, hardcoded branding is a deployment blocker. | Low | In PRD (6.2) | SLDS theme type + designTokens from CSS properties is correct |

## Differentiators

Features that set this portal apart from basic B2B payment portals. Not universally expected, but high-value for demo impact and real-world utility.

| Feature | Value Proposition | Complexity | PRD Status | Notes |
|---------|-------------------|------------|------------|-------|
| Credit/debit invoice netting | Most basic portals only handle debit invoices. Auto-applying credit memos against debits in a single transaction is a significant differentiator. Versapay and Billtrust support this, but many smaller portals do not. | High | In PRD (5.2.2) | This is one of the hardest features to get right -- negative amounts, netting logic, and summary math all need to be precise |
| Short pay with reason codes | AP clerks frequently short-pay invoices (freight disputes, pricing errors). Capturing structured reasons inline rather than via email follow-up is high-value for AR teams. Not all portals offer this. | Medium | In PRD (5.2.1, 5.2.2) | Required reason + optional comments is the right pattern. Configurable reason codes via Custom Metadata is excellent. |
| Overpay support | Less common than short pay. Enables pre-paying or rounding up. Shows flexibility. Good demo talking point. | Medium | In PRD (5.2.2) | Same validation pattern as short pay -- reason required |
| PaymentLink with guest checkout | Sales reps sending payment links to customers without requiring portal login is a strong differentiator. Reduces friction for one-time or infrequent payers. Billtrust and TreviPay offer similar capabilities. | High | In PRD (5.5) | Currently deferred to v2 in PROJECT.md -- but it IS in the PRD. This is the single highest-impact differentiator for the demo. |
| Merchant-absorbed processing fee tracking | Most portals either pass fees to customers (surcharge) or ignore them. Tracking merchant-absorbed fees per invoice line for accounting without exposing to customers is a nuanced, valuable capability. | Low | In PRD (5.2.4) | Prorated fee allocation on Invoice_Payment_Line__c is a nice detail |
| CSV export of filtered invoice list | Not all portals offer export. Useful for AP clerks who need to reconcile in Excel/ERP. | Low | In PRD (5.1.4) | Table stakes for enterprise, differentiator for demo assets |
| Editable payment amounts per invoice | Most basic portals are "pay full balance or nothing." Letting users adjust amounts per line in a multi-invoice payment is a strong UX differentiator. | Medium | In PRD (5.2.1) | Pre-populated with Balance, editable with validation. This is where short pay/overpay logic lives. |
| Unmanaged package deployment (under 30 min) | For a demo asset, deployment speed IS the feature. Competitors are SaaS products; this is an in-org Salesforce-native asset. | Medium | In PRD (6.1) | This is the meta-differentiator -- the entire value prop of "reusable demo asset" |

## Anti-Features

Features to explicitly NOT build. These are either out of scope for a demo/POC, add complexity without proportional value, or conflict with the project's positioning.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Real-time ERP integration | This is a demo asset, not a production middleware. ERP sync is assumed pre-existing. Building sync logic would quadruple scope and vary per customer. | Document the assumption: invoices are synced to SF Invoice objects before portal use. Provide sample data loading scripts for demos. |
| Automated dunning/collections workflows | Dunning is a separate product category (Gaviti, Versapay Collections). Adding it conflates the demo message and adds massive scope. | Keep focus on "self-service payment." AR managers already have dunning tools. |
| Multi-currency support | Single currency per org is a Salesforce limitation for many features. Multi-currency adds testing complexity across every monetary calculation. | Document as a v2/production consideration. Demo orgs are single currency. |
| Mobile-native app | B2B invoice payment is overwhelmingly a desktop workflow for AP clerks. Responsive web covers the occasional tablet/phone use case. | Ensure LWC components are responsive. LWR handles basic responsive layout. |
| Express checkout (Apple Pay, Google Pay) | Consumer payment patterns, not B2B. AP clerks pay from business bank accounts, not personal wallets. Adds SDK complexity for zero demo value. | ACH + Credit Card covers B2B payment methods. Mention in "future considerations" only. |
| Early payment discount logic | Discount structures are highly customer-specific and require contract/pricing engine integration. Adds significant complexity for a niche demo scenario. | If needed for a specific demo, handle via manual invoice adjustment before portal use. |
| Volume discounts | Same rationale as early payment discounts -- contract-specific, pricing-engine territory. | Out of scope. |
| Concurrent payment conflict handling | Single-user payment assumption is stated and appropriate for a demo. Building optimistic locking/conflict resolution is production-grade work. | Document the assumption. For production, recommend server-side balance validation at payment creation time (already partially in PRD). |
| Customer-facing surcharge/fee display | Surcharge laws vary by state/country. Compliance complexity is enormous. Merchant-absorbed model avoids this entirely. | Merchant-absorbed fee tracking (already in PRD) is the right call. |
| Dispute management workflow | Major feature of Versapay and Billtrust. Requires messaging UI, workflow engine, status tracking, notifications. Entire product domain on its own. | Short pay reason codes serve as a lightweight "dispute signal." AR teams follow up offline. |
| Autopay / scheduled recurring payments | Strong feature in production portals (Bill360, Versapay). But requires scheduling infrastructure, retry logic, notification system, and payment method management. Disproportionate complexity for a demo asset. | Mention as v2 consideration. Demo focuses on ad-hoc self-service payment. |
| Payment history / activity log | Production portals show full payment history per invoice. Useful but adds another page/component, query logic, and UX. | Paid Invoices tab partially covers this. Full history is a v2 feature. |
| Email notifications (payment receipts, reminders) | Expected in production. Requires email templates, delivery infrastructure, preference management. | Out of scope for demo. Salesforce platform can add this via Flow post-deployment. |

## Feature Dependencies

```
Invoice List View (5.1)
  |
  +--> Invoice Selection (5.1.5) -- required before any bulk action
  |     |
  |     +--> Pay Invoices action --> Invoice Payment Detail (5.2)
  |     |                              |
  |     |                              +--> Credit/Debit Netting (5.2.2) -- requires selection of both types
  |     |                              +--> Short Pay / Overpay (5.2.2) -- requires editable payment amounts
  |     |                              +--> Payment Method Selection (5.2.3)
  |     |                              |
  |     |                              +--> Payment Submission (5.3) -- requires valid payment detail state
  |     |                                     |
  |     |                                     +--> SF Payments SDK integration (5.3.2) -- core dependency
  |     |                                     +--> Saved Payment Methods (5.3.4) -- requires SDK
  |     |                                     +--> Billing Address (5.3.1) -- requires Account data
  |     |                                     |
  |     |                                     +--> Post-Payment Processing (5.4)
  |     |                                            |
  |     |                                            +--> Payment/PaymentLineItem creation
  |     |                                            +--> Invoice_Payment_Line__c creation
  |     |                                            +--> Invoice.Balance auto-update (platform)
  |     |                                            +--> Portal_Status__c update
  |     |                                            +--> Processing fee recording
  |     |                                            +--> Payment Confirmation (5.4 -> LWC)
  |     |
  |     +--> Download INVs action --> PDF generation (single or ZIP)
  |
  +--> Export List action --> CSV export (independent of selection)
  |
  +--> Filtering / Tabs / Pagination (independent, can build in parallel)

PaymentLink (5.5) -- independent track, deferred to v2
  |
  +--> Token generation (Apex)
  +--> Guest checkout flow (new LWC variant or mode)
  +--> Requires: Payment Submission (5.3) to exist first

Data Model Dependencies:
  Invoice (standard) --> custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c)
  Invoice_Payment_Line__c (custom) --> depends on Payment (standard) + Invoice (standard)
  Custom Metadata --> must be deployed before any configurable logic works

Apex Service Dependencies:
  invoiceService --> used by invoiceListView
  paymentService --> used by invoicePaymentDetail, paymentSubmission, paymentConfirmation
  paymentLinkController --> used by PaymentLink flow (v2)
```

## MVP Recommendation

For a demo-ready v1, prioritize in this order:

### Must Build (Phase 1 -- Core Flow)
1. **Data model deployment** -- Custom fields on Invoice, Invoice_Payment_Line__c object, Custom Metadata. Everything depends on this.
2. **Invoice List View** -- The landing page. Without it, nothing else is reachable. Include tabs, filtering, pagination, selection, and the three action buttons (Pay, Download, Export).
3. **Invoice Payment Detail** -- The core payment workflow page. Include editable payment amounts, credit netting, short pay/overpay with reasons, payment method toggle, and payment summary.
4. **Payment Submission** -- SF Payments SDK integration. The checkout component, saved methods, billing address, and payment processing.
5. **Post-Payment Processing** -- Payment/PaymentLineItem creation, Invoice_Payment_Line__c creation, balance updates, status updates, processing fee recording.
6. **Payment Confirmation** -- Success/failure display.

### Should Build (Phase 1, but lower priority)
7. **Invoice PDF download** -- Single PDF and ZIP multi-download.
8. **CSV export** -- Current filtered view export.
9. **Error handling polish** -- Error_Log__c, user-friendly messages, retry flows.

### Defer (v2)
10. **PaymentLink with guest checkout** -- Highest-impact differentiator but highest complexity. Requires token infrastructure, guest access patterns, and a separate entry point. Build after the core authenticated flow is solid.

**Rationale:** The core payment flow (list -> select -> detail -> pay -> confirm) is a single linear journey that must work end-to-end for any demo. PDF download and CSV export are side actions that add value but don't block the primary demo narrative. PaymentLink is architecturally independent and should be its own milestone.

## Sources

- [Gaviti: Best B2B Customer Payment Portals 2026](https://gaviti.com/best-b2b-customer-payment-portals/)
- [Billtrust: B2B Invoicing Guide](https://www.billtrust.com/resources/blog/b2b-invoicing)
- [Invoiced: Customer Payment Portal](https://www.invoiced.com/resources/blog/customer-payment-portal)
- [Versapay vs Billtrust Comparison](https://www.versapay.com/versapay-vs-billtrust)
- [SelectHub: Billtrust vs VersaPay 2025](https://www.selecthub.com/accounts-receivable-software/billtrust-vs-versapay/)
- [Bill360: B2B AR Automation](https://bill360.com/)
- [OnPhase: 2026 B2B Payment Trends](https://www.onphase.com/blog/2026-b2b-payment-trends-faster-rails-smarter-controls)
- [Rillion: Best B2B Payment Platforms 2026](https://www.rillion.com/blog/best-b2b-payment-platforms/)
- [PYMNTS: B2B Payments Speed Strategy](https://www.pymnts.com/news/b2b-payments/2026/for-b2b-payments-speed-is-the-new-strategy)
