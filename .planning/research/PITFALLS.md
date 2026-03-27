# Pitfalls Research

**Domain:** B2B Invoice Payment Portal on Salesforce B2B Commerce (LWR) with Payments SDK v7.0.0
**Researched:** 2026-03-27
**Confidence:** MEDIUM-HIGH (SDK docs verified from local copy; platform behaviors verified via Salesforce developer docs and community; some edge cases are LOW confidence where noted)

## Critical Pitfalls

### Pitfall 1: SDK Script Loading Race Condition in LWC Lifecycle

**What goes wrong:**
The Salesforce Payments SDK (`sfp.js`) is loaded via `loadScript()` in the LWC lifecycle. If `sfp.checkout()` is called before the script fully initializes, or if `renderedCallback` fires multiple times (which it does on every re-render), the checkout component gets mounted multiple times or fails silently. The `SFPayments` constructor may not be available on `window` when you expect it.

**Why it happens:**
LWC's `renderedCallback` fires after every render cycle, not just once. Developers treat it like `componentDidMount` and put SDK initialization there. Additionally, `loadScript()` can reject with an empty exception even when the script actually loaded (documented GitHub issue salesforce/lwc#2640). In Experience Cloud, CSP settings may also block the script load without a clear error.

**How to avoid:**
- Load the SDK in `connectedCallback` with a boolean guard (`this._sdkLoaded`) to prevent double-loading.
- Use a promise chain: `loadScript(this, getSdkUrl()).then(() => this._initCheckout())`.
- Guard `renderedCallback` with `if (this._checkoutMounted) return;` to prevent re-mounting.
- Verify CSP is set to "Relaxed CSP: Permit Access to Inline Scripts and Allowed Hosts" in the Experience Cloud site settings.
- Check `typeof SFPayments !== 'undefined'` before constructing.

**Warning signs:**
- Checkout component renders as blank white space.
- Console errors referencing `SFPayments is not defined`.
- Intermittent "works sometimes" behavior on the payment page.
- `STRIPE_SCRIPT_LOAD_ERROR` or `COMPONENT_CREATION_FAILED` in SDKConfig.report callback.

**Phase to address:**
Phase 1 (Foundation) -- establish the SDK loading pattern once in a shared utility module; all payment components import from it.

---

### Pitfall 2: Shadow DOM Prevents SDK Checkout Mounting to Target Element

**What goes wrong:**
`sfp.checkout()` requires a DOM element or CSS selector (`elementOrSelectorToMountTo`) to mount the payment iframe. In LWC's shadow DOM, a selector like `'.payment-container'` passed to the SDK will fail because `document.querySelector()` cannot pierce the shadow boundary. The SDK's internal DOM query finds nothing, and the checkout component never renders.

**Why it happens:**
The Salesforce Payments SDK uses standard DOM APIs internally to find the mount target. LWC uses synthetic shadow DOM (or native shadow DOM in newer releases), which encapsulates the component's DOM tree. The SDK cannot see elements inside the shadow root via `document.querySelector()`.

**How to avoid:**
- Pass the actual `HTMLElement` reference instead of a CSS selector string: `this.template.querySelector('.payment-container')`.
- Ensure the target `<div>` exists in the DOM before calling `sfp.checkout()` -- use `renderedCallback` with a guard, or use `requestAnimationFrame` after state change.
- Consider using Light DOM (`static renderMode = 'light'`) for the payment submission component so the SDK's internal queries work. This is documented as supported in LWR Experience Cloud sites.

**Warning signs:**
- Payment form area renders empty but no JavaScript errors appear.
- `CHECKOUT_COMPONENT_CREATION_ERROR` reported via SDKConfig.report.
- Works in a standalone HTML test page but fails when embedded in the LWC.

**Phase to address:**
Phase 1 (Foundation) -- the `paymentSubmission` LWC architecture must resolve this before any SDK integration work.

---

### Pitfall 3: Amount Format Mismatch -- Dollars vs. Subunits (Cents)

**What goes wrong:**
The PRD specifies that `PaymentIntentRequest.amount` should be "in subunit/cents" for the payment amount. However, the SDK documentation example shows `amount: 10.99` (dollars, not cents). If the Apex `createIntentFunction` returns the amount in dollars but Stripe expects cents (or vice versa), payments will be 100x too large or too small. A $500 invoice payment becomes $5.00 or $50,000.

**Why it happens:**
The SDK documentation is ambiguous. The `PaymentIntentRequest` docs say "Payment amount in the requested currency" without specifying subunit vs. major unit. The code example shows `amount: 10.99`. Stripe's API expects amounts in cents (integer). The SDK may or may not handle conversion internally depending on the payment gateway adapter. Developers assume one format and don't test with real gateway transactions.

**How to avoid:**
- Test with real gateway (Stripe test mode) early in development -- do NOT defer payment testing to the end.
- Document the expected amount format in the Apex `createIntentFunction` and the LWC. Add an explicit comment: "Amount is in [dollars/cents]."
- Add server-side validation: if amount > reasonable threshold (e.g., 1,000,000), log a warning -- likely a units mismatch.
- Verify in the PaymentIntent created on the Stripe dashboard that the amount matches expectations.

**Warning signs:**
- Payment amounts in Stripe dashboard are 100x off from invoice amounts.
- Test payments succeed but for obviously wrong amounts.
- Payment declined for "amount too large" on small invoices.

**Phase to address:**
Phase 2 (Payment Integration) -- must be validated with a real Stripe test-mode transaction, not mocked.

---

### Pitfall 4: Invoice.Balance Staleness During Multi-Step Payment Flow

**What goes wrong:**
A user selects invoices in the List View, navigates to Payment Detail, edits amounts, navigates to Payment Submission, and submits. The `Invoice.Balance` values were read minutes ago. If another process (ERP sync, another user, a scheduled job) modified the invoice balance in the interim, the payment creates records against stale data. The user pays $500 but the invoice balance was already updated to $300, resulting in a $200 overpayment that no one intended.

**Why it happens:**
The PRD explicitly calls out "single-user payment assumption" and defers concurrent conflict handling. But even without concurrent users, ERP syncs and scheduled batch jobs can modify invoice data. The multi-page flow with client-side state means the data could be minutes old by the time `checkout.confirm()` fires.

**How to avoid:**
- Re-query `Invoice.Balance` server-side in the `createIntentFunction` Apex method, immediately before creating the PaymentIntent.
- Compare the server-side balance against the client-submitted payment amounts. If any invoice balance changed, reject the intent and return an error that triggers the "Invoice state changed" UX flow (PRD Section 11.2).
- Set `Portal_Status__c = 'In Progress'` when the user enters the Payment Detail page, and clear it on timeout/abandonment. This won't prevent the problem but makes stale state visible.

**Warning signs:**
- Post-payment balance doesn't match expected zero or expected remaining balance.
- Discrepancies between Payment amounts and Invoice Balance changes.
- QA tests pass only when run in isolation, fail when run with data setup scripts.

**Phase to address:**
Phase 2 (Payment Integration) -- the `createIntentFunction` Apex method must include balance re-validation.

---

### Pitfall 5: preferLegacyForms Default is TRUE -- Payment Form Renders Outdated UI

**What goes wrong:**
The `SalesforcePaymentsCheckoutOptions.preferLegacyForms` defaults to `true` (confirmed in SDK docs, since v6.0). The PRD specifies setting it to `false` for modern form rendering. If this is missed or reverted, the checkout component renders older-style payment forms that may have different behavior, styling, and accessibility characteristics. The theming configuration (designTokens, rules) may not apply correctly to legacy forms.

**Why it happens:**
The default is `true` for backward compatibility. Developers copy examples from older SDK versions or Stack Exchange posts that don't include this option. The difference isn't immediately obvious in development -- legacy forms still "work" -- but they diverge from the design intent and may not inherit the B2B site theme correctly.

**How to avoid:**
- Explicitly set `preferLegacyForms: false` in the checkout config and add a code comment explaining why.
- Include this in the integration test checklist: verify the payment form matches expected modern layout.
- Document this in the unmanaged package setup guide as a "do not change" setting.

**Warning signs:**
- Payment form looks visually different from Salesforce Payments documentation screenshots.
- Theme designTokens (colors, fonts) don't apply to the payment form.
- ACH form fields render differently than expected.

**Phase to address:**
Phase 2 (Payment Integration) -- set during initial SDK configuration.

---

### Pitfall 6: Credit Invoice Netting Creates Negative or Zero PaymentIntent

**What goes wrong:**
When a user selects credit memos (negative amounts) alongside debit invoices, the net payment total could be zero or negative. A zero-dollar PaymentIntent will fail at the gateway. A negative amount is nonsensical. The SDK and Stripe will both reject these, but the error messages will be cryptic gateway errors rather than user-friendly explanations.

**Why it happens:**
The credit netting logic in the Payment Detail page calculates the total correctly for display, but doesn't gate the "Pay Now" flow against edge cases. The PRD says "Total Payment must be > $0.00 to proceed" (Section 5.2.5, rule 4), but the implementation might not catch all paths -- e.g., user edits a debit payment amount down to match the credit amount exactly.

**How to avoid:**
- Validate net payment amount > $0.00 in three places: (1) client-side before enabling "Pay Now", (2) server-side in the `createIntentFunction` before calling the gateway, (3) display a specific error message ("Credits exceed debits -- no payment required") rather than a generic failure.
- Handle the "exact zero" case as a special flow: if credits fully offset debits, skip the payment gateway entirely and just create the allocation records server-side.

**Warning signs:**
- "Pay Now" button is enabled when the payment summary shows $0.00.
- Gateway error on submission that doesn't match the displayed amount.
- Untested edge case in QA matrix.

**Phase to address:**
Phase 2 (Payment Detail component) -- validation logic must handle all netting edge cases.

---

### Pitfall 7: Unmanaged Package Deploys But Invoice Object Dependencies Missing

**What goes wrong:**
The package deploys successfully but the Invoice List View shows no data or throws SOQL errors. The standard Invoice object requires Order Management to be enabled. If the target org doesn't have Order Management (or it's not fully configured), the Invoice object exists but isn't populated or accessible. Custom fields deploy but field-level security isn't automatically granted.

**Why it happens:**
Unmanaged packages don't enforce prerequisite checks. The package will install even if Order Management isn't enabled. Permission sets are included but not automatically assigned. Custom Metadata records deploy but may need manual activation. The "under 30 minutes" deployment target creates pressure to skip verification steps.

**How to avoid:**
- Create a pre-installation validation script (Apex or shell) that checks: Order Management enabled, Invoice object accessible, Salesforce Payments enabled, at least one PaymentMethodSet exists.
- Include field-level security for ALL custom fields in the permission set. Don't rely on profile-level access.
- Add a "Post-Install Verification" page/component that runs diagnostic checks and shows red/green status for each prerequisite.
- Document prerequisites prominently at the top of the setup guide, not buried in fine print.

**Warning signs:**
- Package installs without errors but invoice list is empty.
- "sObject type 'Invoice' is not supported" errors in Apex logs.
- Custom fields visible to admin but not to portal users.
- Payment form renders but "Submit Payment" fails silently.

**Phase to address:**
Phase 4 (Packaging) -- but prerequisite documentation should be drafted in Phase 1.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoding basePath for SDK URL | Faster initial setup | Breaks when deployed to a site with different basePath or community URL structure | Never -- always use `import basePath from '@salesforce/community/basePath'` |
| Storing payment state in URL params between pages | Simple page-to-page data passing | URL manipulation, state tampering, loss of complex objects (edited amounts, reasons) | Never for payment data -- use a server-side session/cache or platform events |
| Skipping `checkout.destroy()` on component disconnect | Saves a few lines of code | Memory leaks, orphaned iframes, stale event listeners that fire on navigation back | Never -- always call `destroy()` in `disconnectedCallback` |
| Using `WITH SECURITY_ENFORCED` instead of proper FLS checks | Simpler SOQL | Throws exception instead of gracefully handling missing field access; harder to debug in customer orgs with different permission sets | Only in POC; production should use `Security.stripInaccessible()` |
| Inline Apex constants for short pay reasons | Quick to implement | Cannot configure per-org without code changes; PRD requires Custom Metadata | Never -- Custom Metadata from day one per PRD Section 10 |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Salesforce Payments SDK `createIntentFunction` | Returning the wrong object shape -- SDK expects the raw gateway PaymentIntent object, not a wrapper | Return the exact Stripe PaymentIntent JSON from the Apex callout. The SDK passes this directly to Stripe.js for confirmation. |
| Salesforce Payments SDK `updateIntentFunction` | Not implementing it at all because "billing details don't change" | Must be implemented even if it's a no-op wrapper. The SDK calls it when the user modifies billing address fields in the payment form. Omitting it causes a runtime error. |
| SDK Theme with B2B Commerce site | Hardcoding designToken values instead of reading from site CSS custom properties | Use `getComputedStyle(document.documentElement).getPropertyValue('--lwc-colorBrand')` or equivalent to pull live values from the Experience Cloud theme. |
| Standard Payment/PaymentLineItem creation | Creating Payment records without linking to PaymentGateway or PaymentGroup | The standard data model expects Payment records to be associated with a PaymentGateway. Orphaned payments may not trigger platform balance recalculation on Invoice. |
| SDK metadata fetch | Hardcoding the metadata URL or skipping the metadata fetch entirely | Always fetch metadata from `${basePath}/sfsites/assets/payments/metadata/${sfpVersion}.json` -- this contains the PaymentMethodSet configuration the SDK needs to render the correct payment methods. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all invoices client-side then filtering | Invoice list appears fast with 20 records, slows dramatically as data grows | Server-side pagination from day one (PRD requires this). SOQL with LIMIT/OFFSET. Never fetch all records. | 200+ invoices per account |
| Not caching PaymentMethodSet and metadata | Every navigation to the payment page re-fetches SDK metadata and PaymentMethodSet from the server | Cache in a module-scoped variable or Apex cache. Metadata and PaymentMethodSet rarely change during a session. | Noticeable with slow networks or high-latency orgs |
| Synchronous PDF generation for ZIP download | Multi-invoice PDF download blocks the UI thread and times out the Apex governor limit | Use `@future` or Queueable Apex for PDF generation. Return a polling ID and check status from the client. | 5+ invoices selected for download (ContentVersion creation + ZIP assembly) |
| Re-querying all invoice data on every tab switch | Tab click triggers full SOQL re-query with new WHERE clause | Cache the first query result set client-side and filter locally for tab switches within the same session. Only re-query on explicit filter application or refresh. | Accounts with 100+ invoices across tabs |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| SOQL queries in Apex controllers without account scoping | Any authenticated portal user could see invoices from other accounts by manipulating request parameters | Every SOQL query MUST include `WHERE (BillingAccountId = :userAccountId OR Sold_To_Account__c = :userAccountId)`. Enforce this at the service layer, not the controller layer. Use `WITH SECURITY_ENFORCED` or `Security.stripInaccessible()`. |
| Trusting client-submitted invoice IDs without re-validation | User could submit payment for invoices belonging to another account by crafting the request | Re-query all submitted invoice IDs server-side in `createIntentFunction` and verify they belong to the current user's account before creating the PaymentIntent. |
| Exposing raw SDK error messages to end users | SDK error messages contain vendor names, internal codes, and gateway details that leak implementation information | Map all SDK error codes to user-friendly messages per PRD Section 11. Log raw errors server-side via `SDKConfig.report`. Display only generic messages client-side. |
| PaymentLink token containing invoice IDs in plaintext | Token interception reveals invoice IDs, amounts, and account information | Cryptographically sign tokens with HMAC. Encode a reference ID that maps to a server-side record, not the actual invoice data. Validate signature and expiry server-side before revealing any data. |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No loading state while SDK checkout mounts | User sees a blank area for 1-3 seconds, may think the page is broken or click away | Show a spinner or skeleton screen in the payment container div until the SDK `load` event fires. |
| Losing selection state on pagination | User selects invoices on page 1, navigates to page 2, returns to page 1 -- selections are gone | Maintain a Set of selected invoice IDs in component state. Re-apply checkbox state from the Set on each page render. PRD requires this ("Selection state persists across pagination"). |
| Short pay reason dropdown appearing unexpectedly | User types a payment amount, tabs to next field, and a dropdown appears where they didn't expect it | Use clear visual affordance: show the Reason column as disabled/greyed until Payment Amount differs from Balance. Animate the transition. Provide inline help text. |
| Payment form re-renders on billing address change | User edits billing address, the entire checkout component re-renders, clearing card data | The SDK handles this internally via `updateIntentFunction`. Do NOT destroy and re-create the checkout component on address change. Only call `updateIntentFunction`. |
| No confirmation before navigating away from Payment Detail | User has edited payment amounts for 15 invoices, accidentally clicks browser back -- all work lost | Add a `beforeunload` event listener and/or LWC navigation guard to warn before losing unsaved payment edits. |

## "Looks Done But Isn't" Checklist

- [ ] **SDK Theme:** Payment form visually matches the B2B site brand colors -- verify by changing the site theme and confirming the payment form updates. Don't just check the default theme.
- [ ] **Account Scoping:** Verify a user from Account A cannot see invoices from Account B -- test with two portal users from different accounts, not just one.
- [ ] **Credit Invoice Netting:** Test selecting only credit memos (net negative), credits equal to debits (net zero), and credits exceeding debits -- all must be handled gracefully.
- [ ] **Permission Set Assignment:** After package install, verify the portal user profile has access to ALL custom fields, custom metadata, and Apex classes -- don't test only with System Admin.
- [ ] **Payment Form Destroy:** Navigate to the payment page, click browser back, navigate forward again -- verify no duplicate payment forms, no console errors, no orphaned iframes.
- [ ] **Server-side Balance Validation:** Modify an invoice balance directly in Salesforce while a user is on the Payment Detail page, then have them submit -- verify the error handling works.
- [ ] **CSV Export Encoding:** Export invoices with special characters in PO numbers or descriptions -- verify the CSV opens correctly in Excel without encoding issues.
- [ ] **Session Timeout:** Let a session expire while on the Payment Submission page, then click Submit -- verify graceful redirect to login, not a cryptic error.
- [ ] **Pagination + Selection:** Select invoices across 3 pages, proceed to Payment Detail -- verify all selected invoices appear, not just the last page's selection.
- [ ] **Dark Mode:** If the B2B site uses dark mode, verify the SDK checkout form renders correctly with `ThemeMode.DARK` -- text must be readable, inputs visible.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SDK mounting fails (shadow DOM) | LOW | Switch paymentSubmission component to Light DOM (`static renderMode = 'light'`) or pass HTMLElement reference instead of selector. No data model changes needed. |
| Amount units mismatch (dollars vs cents) | MEDIUM | Fix the conversion in `createIntentFunction`. Audit all test Stripe PaymentIntents for incorrect amounts. May need to void/refund test payments. |
| Invoice balance staleness | MEDIUM | Add server-side re-validation in `createIntentFunction`. If payments already processed against stale data, manual reconciliation needed. Add balance check as a required step in the Apex flow. |
| Missing account scoping in SOQL | HIGH | Security vulnerability. Must audit all Apex controllers, add WHERE clauses, redeploy, and verify no data exposure occurred. Consider this a P0 fix. |
| Unmanaged package missing prerequisites | LOW | Add a post-install diagnostic component. Update setup guide. No code changes needed, just documentation and verification tooling. |
| Payment form re-mounting on re-render | MEDIUM | Refactor SDK initialization to use guards and proper lifecycle management. Must also call `destroy()` properly. Test all navigation paths. |
| Credit netting edge cases | LOW | Add validation in three places (client, Apex, error handler). Straightforward logic fix. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SDK script loading race condition | Phase 1 (Foundation) | SDK loads reliably on first visit, page refresh, and navigation from other pages |
| Shadow DOM mount failure | Phase 1 (Foundation) | Checkout component renders in the LWR site (not just a standalone test) |
| Amount format mismatch | Phase 2 (Payment Integration) | Stripe dashboard shows correct dollar amount matching invoice balance |
| Invoice balance staleness | Phase 2 (Payment Integration) | Modify invoice balance mid-flow; error message displays; payment blocked |
| preferLegacyForms default | Phase 2 (Payment Integration) | Payment form matches modern SDK screenshots; theme tokens apply |
| Credit netting edge cases | Phase 2 (Payment Detail) | Test matrix covers: zero net, negative net, exact balance, credits-only |
| Account scoping missing | Phase 1 (Foundation) | Two-account test: User A sees 0 of User B's invoices in all queries |
| Package prerequisite failures | Phase 4 (Packaging) | Install in a clean org without Order Management; diagnostic page shows clear error |
| Payment form re-mount/destroy | Phase 2 (Payment Integration) | Navigate away and back to payment page 5x; no duplicates, no console errors |
| Client-side state loss | Phase 3 (UX Polish) | Select invoices, paginate, return -- selections preserved |

## Sources

- [Salesforce Payments SDK v7.0.0 Documentation](https://salesforcecommercecloud.github.io/payments-sdk-doc/v7.0.0/html/) -- local copy at `docs/payments-sdk.md`
- [Shadow DOM in LWC](https://developer.salesforce.com/docs/platform/lwc/guide/create-dom.html)
- [Light DOM in LWC](https://developer.salesforce.com/docs/platform/lwc/guide/create-light-dom.html)
- [loadScript rejecting with empty exception (GitHub Issue #2640)](https://github.com/salesforce/lwc/issues/2640)
- [B2B Commerce LWR Integration Architecture](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2c-comm-integration-arch.html)
- [Create a Custom Payment Component for B2B Commerce](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-integrate-payment-lwc.html)
- [Commerce LWR Storefront Performance Best Practices](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-storefront-performance-best-practices.html)
- [Prevent SOQL Injection Attacks](https://trailhead.salesforce.com/content/learn/modules/secure-serverside-development/mitigate-soql-injection)
- [Invoice Object Reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_invoice.htm)
- [B2B Commerce on LWR: Key Business Insights (Twistellar)](https://twistellar.com/blog/salesforce-b2b-commerce-on-lwr)
- [Payment Architecture for B2B Commerce](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-payment-integration.html)

---
*Pitfalls research for: B2B Invoice Payment Portal on Salesforce B2B Commerce (LWR)*
*Researched: 2026-03-27*
