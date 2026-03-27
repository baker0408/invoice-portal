# B2B Invoice Payment Portal

**Product Requirements Document**

Salesforce B2B Commerce (LWR) + Salesforce Payments SDK v7.0.0
*Reusable Demo Asset / Proof of Concept*

| | |
|---|---|
| **Version** | 1.0 |
| **Date** | March 24, 2026 |
| **Status** | Draft |
| **Classification** | Internal |

---

## 1. Overview

This PRD defines the requirements for a B2B Invoice Payment Portal built on the Salesforce B2B Commerce (LWR) Experience Cloud template. The portal enables bill-to and sold-to customers to view, filter, and pay invoices through a branded self-service experience. Payment processing is handled via the Salesforce Payments Client Side SDK (v7.0.0).

This asset is designed as a reusable, demo-ready proof of concept. It will be packaged as an unmanaged package for deployment into customer orgs and SE demo environments. It inherits theming and branding from the host B2B Commerce site; no standalone site or separate domain is required.

> **Note:** This solution uses the standard Salesforce Invoice object (API v48.0+) as the primary data model. Custom fields are added only where the standard object does not provide the needed capability. See Section 7 for the full field mapping.

---

## 2. Goals and Success Criteria

### 2.1 Primary Goals

- **Accelerate deal cycles:** Give SEs a working demo asset for B2B invoice payment scenarios that can be stood up in any org with a B2B Commerce site.
- **Prove the pattern:** Validate that Salesforce Payments SDK + B2B Commerce LWR can handle multi-invoice payment with overpay/short pay, credit memos, and processing fees.
- **Reusable asset:** Package as an unmanaged package deployable into any org running B2B Commerce with Salesforce Payments enabled.
- **Standard object alignment:** Build on the standard Invoice object to maximize compatibility with Revenue Cloud, Salesforce Billing, and ERP integration patterns.

### 2.2 Success Criteria

- End-to-end invoice payment flow completable in demo without code changes
- Supports credit card and ACH payment methods via Salesforce Payments SDK
- Processing fee calculated and displayed before payment confirmation
- Invoice balances and statuses update in Salesforce post-payment
- Inherits B2B site theming with zero custom CSS overrides required
- Deployable via unmanaged package in under 30 minutes
- Data model uses standard Invoice and InvoiceLine objects with minimal custom field additions

---

## 3. Scope

### 3.1 In Scope

- Invoice List View page (new B2B Commerce LWR page)
- Invoice Payment Detail page (multi-invoice selection and payment)
- Payment Submission page (Salesforce Payments SDK checkout component)
- Invoice PDF download
- Invoice list CSV export
- Multi-invoice payment with credit and debit invoice netting
- Debit invoice overpay and short pay with reason codes and comments
- Credit card processing fee tracking (merchant-absorbed, not customer-facing)
- Post-payment invoice balance and status updates
- PaymentLink generation with unauthenticated guest checkout support
- Unmanaged package with all metadata

### 3.2 Out of Scope

- ERP or external system real-time integration (invoices are assumed to be synced to Salesforce objects)
- Automated dunning or collections workflows
- Multi-currency support (single currency per org)
- Mobile-native app (responsive web only)
- Express checkout (Apple Pay, Google Pay) for invoice payments
- Volume discounts or early payment discount logic
- Concurrent payment conflict handling (single-user payment assumption)
- Customer-facing surcharge or processing fee display

---

## 4. User Personas

| Persona | Role | Goals | Pain Points |
|---|---|---|---|
| **AP Clerk** | Bill-to customer accounts payable | Pay multiple invoices in one session, apply credits, download records | Manual check processes, no visibility into invoice status, no self-service |
| **AR Manager** | Seller-side accounts receivable | Faster collections, reduced DSO, automated payment reconciliation | Phone/email payment coordination, manual posting, reconciliation errors |
| **Sales Rep** | Account owner / relationship manager | Send PaymentLinks to customers, reduce payment friction | No way to facilitate payments without AR involvement |

---

## 5. Functional Requirements

### 5.1 Invoice List View

The primary landing page for the portal. Displays all invoices associated with the logged-in customer account (bill-to or sold-to). Reference: Pepsi Invoice List View screenshot.

#### 5.1.1 Data Display

| Column | Source Field | Sortable | Standard? | Notes |
|---|---|---|---|---|
| Invoice Date | Invoice.InvoiceDate | Yes | Yes | Default sort descending |
| Invoice Number | Invoice.DocumentNumber | Yes | Yes | Hyperlink to detail/PDF |
| DSD PO Number | Invoice.PO_Number__c | No | No | Custom field for customer reference |
| Invoice Amount | Invoice.TotalAmountWithTax | Yes | Yes | Supports negative (credits) |
| Due Date | Invoice.DueDate | Yes | Yes | Standard field |
| Amount Paid | Calculated | No | N/A | TotalAmountWithTax minus Balance |
| Invoice Balance | Invoice.Balance | Yes | Yes | Standard field, auto-calculated |
| Status | Invoice.Status | Yes | Yes | Posted, Paid, Canceled, Error |

> **Note:** The standard Invoice object uses 'Status' with values like Posted, Paid, Canceled, and Error. For the portal UX, we map Posted -> Open, and use a custom field (Portal_Status__c) to track In Progress for partially paid invoices. See Section 7 for the full mapping.

#### 5.1.2 Tabs

- **Open Invoices:** Default tab. Shows invoices where Balance > 0 and Status = Posted (or Portal_Status__c = In Progress).
- **Paid Invoices:** Shows invoices with Status = Paid or Balance = 0.
- **Prior Year Invoices:** Shows invoices from the previous calendar year regardless of status.

#### 5.1.3 Filtering

- Date range filter (Date From / Date To) with calendar picker inputs
- Apply Filters button executes filter; Clear button resets all filters

#### 5.1.4 Actions

- **Pay Invoices:** Navigates selected invoices to the Invoice Payment Detail page. Requires at least one invoice checkbox selected. Disabled if no invoices selected.
- **Download INVs:** Downloads PDF for each selected invoice. If single invoice selected, returns single PDF. If multiple, returns ZIP archive.
- **Export List:** Exports current filtered view as CSV file with all visible columns.

#### 5.1.5 Selection Behavior

- Checkbox column for row-level selection
- Header checkbox for select-all on current page
- Credit invoices (negative amounts) can be selected alongside debit invoices
- Selection state persists across pagination but resets on tab change

#### 5.1.6 Pagination

- Server-side pagination, 20 invoices per page
- Previous/Next navigation controls

### 5.2 Invoice Payment Detail

Displays selected invoices and allows the user to specify payment amounts, reasons, and comments before proceeding to payment. Reference: Pepsi Invoice Payment Detail screenshot.

#### 5.2.1 Invoice Line Items

| Column | Editable | Validation | Notes |
|---|---|---|---|
| Invoice Date | No | N/A | Invoice.InvoiceDate |
| Invoice Number | No | N/A | Invoice.DocumentNumber |
| Invoice Amount | No | N/A | Invoice.TotalAmountWithTax (original amount) |
| Invoice Balance | No | N/A | Invoice.Balance (standard auto-calculated field) |
| Payment Amount | Yes | Numeric, >= 0 | Pre-populated with Invoice.Balance |
| Balance Due | No | N/A | Calculated: Balance minus Payment Amount |
| Reason | Conditional | Required if short pay | Dropdown: Sales Tax, Freight, Damaged, Pricing, Other |
| Comments | Conditional | Required if Reason = Other | Free text, 255 char max |

#### 5.2.2 Payment Logic

- **Full Pay:** Payment Amount equals Invoice.Balance. Balance Due = $0.00. No reason or comment required.
- **Short Pay:** Payment Amount is less than Invoice.Balance. Balance Due > $0.00. Reason is required. If Reason = Other, Comments is required.
- **Overpay:** Payment Amount exceeds Invoice.Balance. Balance Due is negative. Reason is required.
- **Credit Invoices:** Invoices with negative TotalAmountWithTax are auto-applied. Payment Amount field is read-only and pre-filled with the negative balance. Credits net against the total.

#### 5.2.3 Payment Method Selection

- Radio button toggle: ACH or Credit Card
- Selection determines payment method passed to the Salesforce Payments SDK checkout component

#### 5.2.4 Payment Summary

- **Payment Total:** Sum of all Payment Amount values (credits net against debits). This is the amount the customer pays.
- **Processing Fee:** Absorbed by the merchant. Not displayed to or charged to the customer. Calculated internally as a configurable percentage (default: 2.9%) for credit card payments. Recorded on the payment record for merchant accounting purposes. Not applied for ACH.
- **Total Payment:** Equals Payment Total. No surcharge added to the customer-facing amount.

#### 5.2.5 Validation

1. All Payment Amount fields must be numeric and >= 0
2. Reason is required for any row where Payment Amount != Invoice.Balance
3. Comments required when Reason = Other
4. Total Payment must be > $0.00 to proceed
5. Pay Now button is disabled until all validation passes

### 5.3 Payment Submission

The payment form page powered by the Salesforce Payments Client Side SDK (v7.0.0). Renders the checkout component with credit card or ACH fields based on prior selection. Reference: Pepsi Payment Submission screenshot.

#### 5.3.1 Page Layout

- **Amount Being Paid:** Displays the Payment Total amount. Read-only. No surcharge or processing fee is shown to the customer.
- **Payment Section:** Rendered by SFPayments.checkout() component. Shows saved payment methods (if any) and a new card/ACH entry form.
- **Billing Address:** Country, Street (with address lookup), City, State, Postal Code. Pre-populated from the account BillingAddress if available.
- **Save Payment Method:** Checkbox to save payment method for future use. Controlled via showSaveForFutureUsageCheckbox option.
- **Submit Payment:** Triggers checkout.confirm() and processes the payment.

#### 5.3.2 Salesforce Payments SDK Integration

The payment form leverages the SFPayments class from the Salesforce Payments Client Side SDK v7.0.0. Key integration points:

| SDK Component | Usage |
|---|---|
| **SFPayments()** | Instantiated on page load. SDKConfig.report function wired to error logging. |
| **sfp.checkout()** | Mounts checkout component to DOM element. Receives metadata, paymentMethodSet, config, paymentRequest, and target selector. |
| **checkout.confirm()** | Called on Submit Payment click. Passes createIntentFunction, billingDetails, and shippingDetails. Returns PaymentResponse. |
| **PaymentIntentRequest** | Amount (Total Payment in subunit/cents), currency (ISO 4217), country (ISO 3166), locale. billingDetails populated from form. |
| **handleRedirect()** | Handles return from third-party redirects if future payment methods require it. |

#### 5.3.3 SDK Configuration

The following SalesforcePaymentsCheckoutConfig options are applied:

- **labels:** Custom Labels object with contact info and shipping labels suppressed (empty strings).
- **theme:** Theme inherits from B2B site. Type = 'slds', mode auto-detected from site context. designTokens pulled from site CSS custom properties.
- **actions.createIntentFunction:** Apex callout to create PaymentIntent via PaymentLink API. Passes payment amount, invoice references, processing fee, and billing details.
- **actions.updateIntentFunction:** Updates PaymentIntent if billing details change during form entry.
- **options.showSaveForFutureUsageCheckbox:** true. Allows customers to save payment methods.
- **options.showSaveAsDefaultCheckbox:** true. Allows setting saved method as default.
- **options.returnUrl:** Set to the Payment Confirmation page URL within the B2B site.
- **options.preferLegacyForms:** false. Use modern form rendering.
- Contact info fields (name, email, phone) are suppressed from the payment form. These are sourced from the authenticated user context.
- Shipping address section is removed entirely. Not applicable for invoice payments.

#### 5.3.4 Saved Payment Methods

- Saved payment methods from previous transactions display above the new payment form
- Passed via options.savedPaymentMethods as an array of SavedPaymentMethod objects
- User can select a saved method or enter new payment details
- Saved methods show card brand icon, last 4 digits, and a Default badge if applicable

#### 5.3.5 Payment Response Handling

- **Success (ResponseCode.SUCCESS):** PaymentResponseSuccessData contains paymentData.id, paymentToken, billingDetails, and status. Navigate to confirmation page. Trigger post-payment processing.
- **Failure (ResponseCode.FAILURE):** PaymentResponseFailureData contains error details. Display user-friendly error message. Do not expose raw vendor error messages. Allow retry.

### 5.4 Post-Payment Processing

After successful payment confirmation, the following server-side processes execute:

1. Payment record created in Salesforce with PaymentResponse data (payment ID, token, amount, method, timestamp)
2. Invoice Payment Line Item records created linking the Payment to each Invoice with the applied amount
3. Invoice.Balance recalculated by the platform (standard auto-calculated field based on applied payments)
4. Portal_Status__c updated: Posted -> In Progress (partial pay) or Invoice Status -> Paid (balance = 0)
5. Short pay reason and comments stored on the Invoice_Payment_Line__c junction object
6. Processing fee calculated internally for credit card payments (merchant-absorbed, not customer-facing) and recorded on the payment record for accounting
7. Payment data exported to CSV for ERP consumption

> **Note:** The standard Invoice.Balance field is auto-calculated by the platform based on related Payment objects. Our post-payment process creates the appropriate Payment and PaymentLineItem records so the standard Balance field updates automatically without custom recalculation.

### 5.5 PaymentLink Generation

Sales reps or AR managers can generate a PaymentLink from the Salesforce backend that directs a customer to the Payment Submission page with pre-selected invoices. PaymentLinks support unauthenticated guest access.

- PaymentLink is generated via custom Apex action on the Invoice or Account record
- Link encodes selected invoice IDs and payment amount in a signed, expiring token
- Link routes to the B2B Commerce site Payment Submission page (no separate site needed)
- Authenticated users land directly on the payment form with invoices pre-loaded
- Unauthenticated users can access the payment form directly via the PaymentLink without logging in. The token grants read-only access to the encoded invoice data and payment form only. No portal navigation or invoice browsing is available in guest mode.
- Guest checkout uses the same Salesforce Payments SDK checkout component. Billing details (name, email, address) are collected on the payment form since no user context exists.
- PaymentLink tokens are single-use and expire after configurable TTL (default: 72 hours)

---

## 6. Non-Functional Requirements

### 6.1 Packaging and Deployment

- Delivered as an unmanaged package containing all custom fields, LWCs, Apex classes, permission sets, and page layouts
- No custom objects required for core invoice data (uses standard Invoice, InvoiceLine, Payment, PaymentLineItem)
- Post-install setup guide covers: enabling Salesforce Payments, configuring payment gateway, creating PaymentMethodSet, and adding the Invoice Portal page to the B2B site
- Target deployment time: under 30 minutes from package install to working demo

### 6.2 Theming and Branding

- All LWC components inherit styling from the B2B Commerce site theme (Experience Builder branding settings)
- Salesforce Payments SDK Theme object configured with type = 'slds' and designTokens sourced from site CSS custom properties
- No hardcoded colors, fonts, or spacing. All visual properties flow from the site theme.
- Dark mode support via Theme.mode = 'dark' if the host site uses dark mode

### 6.3 Security

- Invoice list, payment detail, and payment confirmation pages require authentication. No guest access to portal navigation.
- PaymentLink pages allow unauthenticated guest access. Guest sessions are scoped to the specific invoices encoded in the token. No browsing, filtering, or access to other invoices is permitted.
- Invoice visibility for authenticated users scoped to the logged-in user's account via BillingAccountId or ReferenceEntityId
- Payment form rendered via Salesforce Payments SDK iframes. No PCI data touches the merchant page.
- CSRF protection via standard Salesforce platform tokens
- PaymentLink tokens are cryptographically signed, single-use, and expire after configurable TTL (default: 72 hours)

### 6.4 Performance

- Invoice list page load under 2 seconds for up to 500 invoices
- Server-side pagination to limit payload size
- Payment SDK script loaded asynchronously after page render

### 6.5 Accessibility

- WCAG 2.1 AA compliance for all custom LWC components
- Salesforce Payments SDK components carry their own accessibility via Labels interface (aria-labels configured for all payment method icons and form fields)
- Keyboard navigation supported for invoice selection, payment amount entry, and form submission

---

## 7. Data Model

The portal is built on the standard Salesforce Invoice object (API v48.0+) and its related standard objects. Custom fields and one junction object are added only where the standard model does not provide the needed capability.

### 7.1 Standard Objects Used

#### Invoice (Standard)

The standard Invoice object provides the core invoice data. The following standard fields are used by the portal:

| API Name | Type | Portal Usage | Notes |
|---|---|---|---|
| DocumentNumber | Auto Number | Invoice Number column | System-generated, unique |
| InvoiceNumber | Text | Alternative display | Can be used if DocumentNumber not preferred |
| InvoiceDate | Date | Invoice Date column | Date invoice was issued |
| DueDate | Date | Due Date column | Payment due date |
| TotalAmount | Currency | Reference | Total before tax |
| TotalAmountWithTax | Currency | Invoice Amount column | Total including tax, supports negative for credits |
| Balance | Currency | Invoice Balance column | Auto-calculated: total minus applied payments |
| Status | Picklist | Status column | Standard values: Posted, Paid, Canceled, Error |
| BillingAccountId | Lookup(Account) | Account scoping | Bill-to account, used for security filtering |
| ReferenceEntityId | Lookup | Account scoping | Polymorphic reference, can point to sold-to account |
| Description | Text Area | Display only | Optional invoice description |

#### InvoiceLine (Standard)

Standard child object of Invoice. Used for PDF generation and detail views but not directly displayed in the portal list view.

#### Payment (Standard)

Standard Payment object used to record payment transactions. Created in post-payment processing with data from PaymentResponse.

#### PaymentLineItem (Standard)

Standard child of Payment. Links a payment to an invoice or invoice line. Used to record which invoices a payment was applied to and for how much.

### 7.2 Custom Fields on Invoice (Standard Object)

The following custom fields are added to the standard Invoice object to support portal-specific functionality not covered by standard fields:

| API Name | Type | Required | Description |
|---|---|---|---|
| PO_Number__c | Text(50) | No | Customer purchase order reference. Maps to DSD PO Number column in list view. |
| Portal_Status__c | Picklist | No | Portal-specific status overlay. Values: Open, In Progress, Paid. Defaults to Open when Invoice.Status = Posted. Updated to In Progress on partial payment. Standard Status field remains authoritative for platform logic. |
| Sold_To_Account__c | Lookup(Account) | No | Sold-to account if different from BillingAccountId. Used for account scoping when sold-to and bill-to differ. |

### 7.3 Custom Junction Object

#### Invoice_Payment_Line__c

Junction object linking a Payment to individual Invoices with payment-specific metadata that the standard PaymentLineItem does not support (reason codes, comments, processing fee allocation).

| API Name | Type | Required | Description |
|---|---|---|---|
| Payment__c | Lookup(Payment) | Yes | Parent payment record (standard Payment object) |
| Invoice__c | Lookup(Invoice) | Yes | Related invoice (standard Invoice object) |
| Payment_Amount__c | Currency | Yes | Amount applied to this invoice from this payment |
| Short_Pay_Reason__c | Picklist | No | Reason for short pay or overpay: Sales Tax, Freight, Damaged, Pricing, Other |
| Comments__c | Long Text(255) | No | Free text explanation, required when reason = Other |
| Processing_Fee__c | Currency | No | Prorated portion of the credit card processing fee for this line |

### 7.4 Status Mapping

The standard Invoice.Status field uses platform-defined values. The portal maps these to customer-facing labels:

| Invoice.Status | Portal Display | Logic |
|---|---|---|
| Posted | Open | Balance > 0 and no partial payments applied |
| Posted | In Progress | Balance > 0 and at least one Payment applied (Portal_Status__c = In Progress) |
| Paid | Paid | Balance = 0 or Status set to Paid by platform/process |
| Canceled | N/A | Not displayed in portal |
| Error | N/A | Not displayed in portal |

---

## 8. User Flow

The end-to-end invoice payment journey follows this sequence:

1. Customer logs into B2B Commerce site and navigates to Invoices page
2. Invoice List View loads with Open Invoices tab active, sorted by InvoiceDate descending
3. Customer optionally filters by date range, switches tabs, or exports the list
4. Customer selects one or more invoices (including credits) via checkboxes
5. Customer clicks Pay Invoices and navigates to Invoice Payment Detail
6. Customer adjusts payment amounts per invoice (full pay, short pay, or overpay)
7. Customer provides reason codes and comments for any short pay or overpay
8. Customer selects ACH or Credit Card and reviews the payment summary
9. Customer clicks Pay Now and navigates to Payment Submission
10. Payment form renders via Salesforce Payments SDK with amount, saved methods, and billing address
11. Customer enters or selects payment method and clicks Submit Payment
12. On success, confirmation page displays. Invoice Balance updates via standard platform mechanics. On failure, error displays with retry option.

---

## 9. Component Architecture

All UI is built as Lightning Web Components (LWC) for the B2B Commerce LWR Experience Cloud site.

| Component | Type | Responsibility |
|---|---|---|
| **invoiceListView** | Page-level LWC | Invoice table with tabs, filters, pagination, selection, and action buttons. Queries standard Invoice object. |
| **invoicePaymentDetail** | Page-level LWC | Selected invoice line items with editable payment amounts, reasons, payment method toggle, and summary |
| **paymentSubmission** | Page-level LWC | Mounts Salesforce Payments SDK checkout component, handles billing address, and processes payment confirmation |
| **paymentConfirmation** | Page-level LWC | Post-payment success/failure display with transaction details |
| **invoiceService** | Apex Controller | SOQL queries on standard Invoice object. Account-scoped security via BillingAccountId and Sold_To_Account__c. |
| **paymentService** | Apex Controller | PaymentIntent creation, processing fee calculation, standard Payment/PaymentLineItem record creation, Invoice_Payment_Line__c creation, payment data export |
| **paymentLinkController** | Apex Controller | PaymentLink generation, token validation, invoice pre-loading from standard Invoice records |

---

## 10. Configuration

The following settings are exposed as Custom Metadata or Custom Settings for org-level configuration without code changes:

| Setting | Type | Default | Description |
|---|---|---|---|
| Processing_Fee_Percent | Decimal | 2.9 | Credit card processing fee percentage (merchant-absorbed, not customer-facing) |
| Processing_Fee_Enabled | Boolean | true | Toggle processing fee tracking on/off |
| ACH_Enabled | Boolean | true | Show ACH as payment option |
| Credit_Card_Enabled | Boolean | true | Show credit card as payment option |
| Invoices_Per_Page | Integer | 20 | Pagination page size |
| PaymentLink_TTL_Hours | Integer | 72 | PaymentLink expiration in hours |
| Short_Pay_Reasons | Text | Sales Tax;Freight;Damaged;Pricing;Other | Semicolon-delimited picklist values |

---

## 11. Error Handling

The portal surfaces errors at two levels: application-level errors handled by the LWC layer, and payment-level errors reported by the Salesforce Payments SDK.

### 11.1 SDK Error Handling

The SDKConfig.report function captures internal SDK errors. Error codes from the SDK (e.g., STRIPE_SCRIPT_LOAD_ERROR, PAYPAL_ORDER_PATCH_ERROR, COMPONENT_CREATION_FAILED) are logged to a custom Error_Log__c object and surfaced as generic user-friendly messages. Raw SDK error messages are never displayed to end users.

### 11.2 Application Errors

| Scenario | User Message | System Action |
|---|---|---|
| Payment declined | Your payment could not be processed. Please try a different payment method. | Log error, allow retry |
| Network timeout | We encountered a connection issue. Please try again. | Retry with exponential backoff, log after 3 failures |
| Invoice state changed | One or more invoices have been updated. Please refresh and try again. | Re-query Invoice.Balance, clear payment form |
| Session expired | Your session has expired. Please log in again. | Redirect to login page |

---

## 12. Risks and Assumptions

### 12.1 Assumptions

- The target org has B2B Commerce (LWR) enabled with an active storefront
- Salesforce Payments is enabled and a payment gateway (Stripe) is configured
- The target org has Order Management enabled (standard Invoice object is available, API v48.0+)
- Invoice data is synced to the standard Invoice object from the source ERP prior to portal use
- Customer accounts have associated Contact records for portal login
- Single currency per org
- This is a demo/POC asset, not a production application. Export format is CSV only.
- Processing fees for credit card payments are merchant-absorbed, not passed to the customer
- No volume or early payment discount logic is required
- Single-user payment assumption: only one user will be making payments toward a given invoice at a time, so concurrent payment conflicts are not handled

### 12.2 Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| SDK version mismatch across orgs | Medium | Payment form fails to render | Pin SDK version in loadScript URL, document minimum org requirements |
| Invoice data staleness | Medium | Customer pays wrong amount | Validate Invoice.Balance server-side at payment creation, show error if changed |
| Guest checkout abuse | Low | Unauthorized payment attempts via expired or tampered PaymentLink tokens | Tokens are cryptographically signed, single-use, and TTL-bound. Rate limiting on guest payment endpoint. |
| B2B site theme incompatibility | Low | Payment form styling breaks | Use SDK Theme type = 'slds' as default, provide plain/none fallbacks |

---

## 13. Decisions Log

Previously open questions, now resolved:

| # | Question | Decision |
|---|---|---|
| 1 | Should the processing fee be passed to the customer as a surcharge? | No. Processing fee is merchant-absorbed. Not displayed to customers. Recorded internally for accounting. |
| 2 | What ERP export format(s) are needed? | CSV only. This is a demo/POC asset, not production. Sufficient for proof of concept. |
| 3 | Should PaymentLink support unauthenticated guest checkout? | Yes. PaymentLinks support guest access via signed, expiring tokens. Guest users see only the encoded invoices and payment form. |
| 4 | Are volume or early payment discounts needed? | No. Not required for this asset. |
| 5 | What happens if Invoice.Balance changes while user is in payment cart? | Edge case accepted. Single-user payment assumption means only one user pays a given invoice at a time. No concurrent conflict handling needed. |
| 6 | Should the package include a fallback custom Invoice object for orgs without OM? | No. All target orgs have Order Management enabled. Standard Invoice object is guaranteed. |
