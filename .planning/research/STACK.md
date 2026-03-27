# Technology Stack

**Project:** B2B Invoice Payment Portal
**Researched:** 2026-03-27

## Recommended Stack

This project is fully constrained to the Salesforce platform. There is no "pick your framework" decision here -- you are building on B2B Commerce (LWR) Experience Cloud. The stack decisions are about which platform capabilities to use, how to structure the SFDX project, which SDK features to leverage, and what tooling to use for development and testing.

### Core Platform

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Salesforce Platform | API v66.0 (Spring '26) | Runtime platform | Current GA release as of March 2026. Use the latest API version for all metadata to get access to Complex Template Expressions (Beta) and latest LWC improvements. Pin to v66.0 in `sfdx-project.json`. | HIGH |
| B2B Commerce (LWR) | Spring '26 | Storefront template | Required by project scope. LWR compiles components at build time for better performance than Aura. Use LWR-specific navigation (`NavigationMixin` from `lightning/navigation`) and data providers where available. | HIGH |
| Lightning Web Components (LWC) | v66.0 | UI framework | The only option for LWR Experience Cloud sites. Aura components are not supported in LWR templates. All 4 page-level components (invoiceListView, invoicePaymentDetail, paymentSubmission, paymentConfirmation) are LWCs. | HIGH |
| Apex | v66.0 | Server-side logic | Required for SOQL queries, DML, PaymentIntent creation, and all business logic. Two controllers: `InvoiceService` and `PaymentService` plus `PaymentLinkController`. Use `with sharing` by default for security enforcement. | HIGH |

### Payment Processing

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Salesforce Payments Client Side SDK | v7.0.0 | Payment form rendering and processing | Pinned per PRD. Loaded via `loadScript()` from `${basePath}/sfsites/assets/payments/v7/sfp.js`. Handles all PCI-sensitive form rendering in iframes. | HIGH |
| SFPayments Checkout component | v7.0.0 | Primary payment UI | The `sfp.checkout()` method mounts the payment form. Supports credit card and ACH (US Bank Account). Configure with `preferLegacyForms: false` for modern form rendering. | HIGH |
| Stripe (via Salesforce Payments) | Gateway | Payment gateway | Salesforce Payments uses Stripe as the underlying gateway. The SDK abstracts Stripe -- you never interact with Stripe.js directly. PaymentIntent creation happens server-side via Apex calling the Salesforce Payments API. | HIGH |

### Data Model

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Standard Invoice object | API v48.0+ | Invoice data | Standard object from Order Management. Auto-calculated `Balance` field eliminates custom balance tracking. 3 custom fields only: `PO_Number__c`, `Portal_Status__c`, `Sold_To_Account__c`. | HIGH |
| Standard Payment object | API v48.0+ | Payment records | Platform-standard. Created in post-payment processing. Links to Invoice via PaymentLineItem. | HIGH |
| Standard PaymentLineItem | API v48.0+ | Payment-to-invoice link | Standard child of Payment. Records which invoices a payment was applied to. | HIGH |
| Invoice_Payment_Line__c | Custom | Junction with metadata | Custom junction because standard PaymentLineItem does not support reason codes, comments, or processing fee allocation. Only custom object in the project. | HIGH |
| Custom Metadata Type | N/A | Configuration | Use CMDT (not Custom Settings) for `Invoice_Portal_Config__mdt`. Stores: processing fee %, ACH/CC toggle, page size, short pay reasons, PaymentLink TTL. CMDT deploys with unmanaged packages; Custom Settings do not. | HIGH |

### Project Structure and Tooling

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Salesforce CLI (`sf`) | v2.x (latest) | CLI tooling | `sfdx` v7 is deprecated and no longer updated. All commands use `sf` namespace (e.g., `sf project deploy start`, `sf project retrieve start`). Install via `npm install -g @salesforce/cli`. | HIGH |
| SFDX Project Format | `sfdx-project.json` | Project structure | Standard `force-app/` directory layout. Required for unmanaged package creation and scratch org development. | HIGH |
| VS Code + Salesforce Extensions | Latest | IDE | The standard Salesforce development IDE. Provides LWC IntelliSense, Apex language server, deploy/retrieve integration, and LWC test runner integration. | HIGH |

### Testing

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| @salesforce/sfdx-lwc-jest | Latest (spring26 tag) | LWC unit testing | Official Salesforce Jest wrapper for LWC. Provides stubs for `lightning/*` base components. Install with `sf force lightning lwc test setup` or `npm install -D @salesforce/sfdx-lwc-jest`. Use release tag matching your org version. | HIGH |
| Jest | 29.x | Test runner | Bundled with sfdx-lwc-jest. Do not install separately -- let sfdx-lwc-jest manage the version to avoid conflicts. | HIGH |
| Apex Test Classes | N/A | Apex unit testing | Platform-native. Required for deployment (75% coverage minimum). Write test classes for `InvoiceService`, `PaymentService`, and `PaymentLinkController`. Use `@TestSetup` for test data. | HIGH |

### Supporting Libraries and Modules

| Library/Module | Purpose | When to Use | Confidence |
|----------------|---------|-------------|------------|
| `lightning/platformResourceLoader` | Script loading | `loadScript()` to load Payments SDK v7.0.0 JS file. The only way to load external scripts in LWC. | HIGH |
| `@salesforce/community/basePath` | Site base path | Construct the SDK URL: `${basePath}/sfsites/assets/payments/v7/sfp.js`. Also construct metadata URL for SDK initialization. | HIGH |
| `lightning/navigation` (NavigationMixin) | Page navigation | Navigate between invoice list, payment detail, submission, and confirmation pages. Use `NavigationMixin.Navigate` with `comm__namedPage` page references for Experience Cloud pages. | HIGH |
| `@salesforce/apex` | Apex method calls | Import and call `@AuraEnabled` methods imperatively or via `@wire`. Use imperative calls for mutations (create payment), `@wire` for reads (invoice queries). | HIGH |
| `lightning/uiApi` | Record data | Use `getRecord` wire adapter for simple record reads where SOQL is overkill (e.g., account billing address lookup). | MEDIUM |
| `lightning-datatable` | Data table | Invoice list view. Supports sorting, row selection with checkboxes, and custom column types. Native SLDS styling. | HIGH |
| `lightning-input` | Form inputs | Payment amount fields, date range filters, billing address form. Built-in validation support. | HIGH |
| `lightning-radio-group` | Radio selection | ACH vs. Credit Card payment method toggle. | HIGH |
| `lightning-combobox` | Dropdown | Short pay reason code selection. | HIGH |
| `lightning-spinner` | Loading state | Show during async operations (SDK loading, payment processing, invoice queries). | HIGH |
| `lightning-card` | Layout container | Wrap sections on payment detail and confirmation pages. Provides consistent SLDS card styling. | HIGH |

## SDK Integration Details

### Payments SDK Loading Pattern

```javascript
// paymentSubmission.js
import basePath from '@salesforce/community/basePath';
import { loadScript } from 'lightning/platformResourceLoader';

const SFP_VERSION = 'v7';
const SF_PAYMENTS_PATH = `${basePath}/sfsites/assets/payments`;

async connectedCallback() {
    await loadScript(this, `${SF_PAYMENTS_PATH}/${SFP_VERSION}/sfp.js`);
    const metadataResponse = await fetch(
        `${SF_PAYMENTS_PATH}/metadata/${SFP_VERSION}.json`
    );
    this.metadata = await metadataResponse.json();
    this.initializeCheckout();
}
```

### SDK Configuration Pattern

```javascript
initializeCheckout() {
    const sfp = new SFPayments({
        report: (error) => this.handleSdkError(error)
    });

    this.checkout = sfp.checkout(
        this.metadata,
        this.paymentMethodSet,
        {
            labels: { /* suppress contact/shipping labels */ },
            theme: {
                type: 'slds',
                mode: 'light', // or detect from site context
                designTokens: { /* pull from site CSS custom properties */ }
            },
            actions: {
                createIntentFunction: (data) => this.createPaymentIntent(data),
                updateIntentFunction: (data) => this.updatePaymentIntent(data)
            },
            options: {
                showSaveForFutureUsageCheckbox: true,
                showSaveAsDefaultCheckbox: true,
                returnUrl: `${window.location.origin}${basePath}/payment-confirmation`,
                preferLegacyForms: false,
                savedPaymentMethods: this.savedMethods
            }
        },
        {
            amount: this.paymentAmountInCents,
            currency: 'USD',
            country: 'US',
            locale: 'en'
        },
        this.template.querySelector('.payment-container')
    );
}
```

### Key SDK Considerations

- **Amount format:** `PaymentIntentRequest.amount` is in the requested currency (e.g., 10.99 for $10.99 per the SDK docs). However, verify this against your Apex PaymentIntent creation -- some Stripe integrations expect subunits (cents). The SDK docs show `amount: 10.99` in their example.
- **preferLegacyForms: false** -- Use modern form rendering. The default is `true` (legacy) since v6.0. Explicitly set to `false` for the latest UI.
- **Theme type: 'slds'** -- Required for B2B Commerce LWR sites where SLDS CSS is already loaded. Do not use `plain` or `none`.
- **Error handling:** Use `SDKConfig.report` to capture SDK internal errors. Map error codes (e.g., `STRIPE_SCRIPT_LOAD_ERROR`, `COMPONENT_CREATION_FAILED`) to user-friendly messages. Never expose raw SDK errors.
- **Destroy on unmount:** Call `checkout.destroy()` in `disconnectedCallback()` to clean up SDK resources.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| UI Framework | LWC | Aura Components | Aura is not supported in LWR Experience Cloud templates. Period. |
| UI Framework | LWC | Visualforce | Not compatible with Experience Cloud LWR sites. Legacy technology. |
| API Version | v66.0 (Spring '26) | v63.0 (Summer '25) | No reason to use an older version in a greenfield project. Always use current GA. |
| Payment SDK | v7.0.0 (pinned) | v6.x or earlier | PRD requires v7.0.0. v7 adds latest payment method support and modern form rendering. |
| CLI | `sf` v2 | `sfdx` v7 | `sfdx` v7 is deprecated and receives no updates. `sf` v2 is the only supported CLI. |
| Config Storage | Custom Metadata Types | Custom Settings | CMDT deploys with packages, supports versioning, and is the Salesforce-recommended approach. Custom Settings require manual setup post-install. |
| Config Storage | Custom Metadata Types | Custom Labels | Labels are for i18n text, not configuration values. Cannot store numbers or booleans natively. |
| Data Table | `lightning-datatable` | Custom HTML table | `lightning-datatable` provides built-in sorting, selection, pagination hooks, SLDS styling, and accessibility. Building custom wastes time. |
| Invoice Object | Standard Invoice | Custom Invoice__c | PRD mandates standard Invoice object. It provides auto-calculated Balance, platform integration with Revenue Cloud/Billing, and requires Order Management (which is confirmed available in target orgs). |
| Navigation | `NavigationMixin` | Direct URL manipulation | `NavigationMixin` is the platform-supported way to navigate in Experience Cloud. Direct URL manipulation breaks in different site configurations. |
| Testing | sfdx-lwc-jest | Cypress/Playwright | E2E testing of LWC on Experience Cloud requires a running org. Jest unit tests run locally without an org. E2E testing is useful but not a replacement for unit tests and is harder to set up for Salesforce. |

## What NOT to Use

| Technology | Why Avoid |
|------------|-----------|
| **Aura Components** | Incompatible with LWR Experience Cloud templates. Will not render. |
| **Visualforce** | Cannot be embedded in LWR sites. Legacy technology. |
| **Custom CSS overrides** | PRD explicitly requires zero custom CSS. All styling must inherit from B2B Commerce site theme. SDK theme uses `type: 'slds'` with `designTokens` from site CSS properties. |
| **`sfdx` v7 CLI** | Deprecated. No longer receives updates. Use `sf` v2 exclusively. |
| **Direct Stripe.js integration** | The Salesforce Payments SDK abstracts Stripe. Loading Stripe.js directly bypasses PCI compliance handled by the SDK's iframe approach. |
| **`fetch()` or `XMLHttpRequest` for data** | In B2B Commerce LWR, use wire adapters and `@AuraEnabled` Apex methods. Direct HTTP calls bypass platform security and caching. |
| **Custom Settings for configuration** | Does not deploy with unmanaged packages. Use Custom Metadata Types instead. |
| **Third-party npm packages in LWC** | LWC does not support npm module imports. All dependencies must be loaded as static resources or use platform-provided modules. |
| **`lightning/empApi` for real-time updates** | Overkill for this demo/POC. Invoice balance updates happen via standard platform mechanics after Payment record creation. No need for real-time push. |
| **Express checkout (Apple Pay/Google Pay)** | Explicitly out of scope per PRD. Do not use `sfp.express()`. Only use `sfp.checkout()`. |

## Project File Structure

```
force-app/
  main/
    default/
      classes/
        InvoiceService.cls
        InvoiceService.cls-meta.xml
        InvoiceServiceTest.cls
        InvoiceServiceTest.cls-meta.xml
        PaymentService.cls
        PaymentService.cls-meta.xml
        PaymentServiceTest.cls
        PaymentServiceTest.cls-meta.xml
        PaymentLinkController.cls
        PaymentLinkController.cls-meta.xml
        PaymentLinkControllerTest.cls
        PaymentLinkControllerTest.cls-meta.xml
      lwc/
        invoiceListView/
          invoiceListView.js
          invoiceListView.html
          invoiceListView.js-meta.xml
          __tests__/
            invoiceListView.test.js
        invoicePaymentDetail/
          invoicePaymentDetail.js
          invoicePaymentDetail.html
          invoicePaymentDetail.js-meta.xml
          __tests__/
            invoicePaymentDetail.test.js
        paymentSubmission/
          paymentSubmission.js
          paymentSubmission.html
          paymentSubmission.js-meta.xml
          __tests__/
            paymentSubmission.test.js
        paymentConfirmation/
          paymentConfirmation.js
          paymentConfirmation.html
          paymentConfirmation.js-meta.xml
          __tests__/
            paymentConfirmation.test.js
      objects/
        Invoice__c/           # Custom fields on standard Invoice
          fields/
            PO_Number__c.field-meta.xml
            Portal_Status__c.field-meta.xml
            Sold_To_Account__c.field-meta.xml
        Invoice_Payment_Line__c/
          Invoice_Payment_Line__c.object-meta.xml
          fields/
            Payment__c.field-meta.xml
            Invoice__c.field-meta.xml
            Payment_Amount__c.field-meta.xml
            Short_Pay_Reason__c.field-meta.xml
            Comments__c.field-meta.xml
            Processing_Fee__c.field-meta.xml
      customMetadata/
        Invoice_Portal_Config__mdt.Default.md-meta.xml
      permissionsets/
        Invoice_Portal_User.permissionset-meta.xml
        Invoice_Portal_Admin.permissionset-meta.xml
      layouts/
        Invoice_Payment_Line__c-Invoice_Payment_Line_Layout.layout-meta.xml
      experiences/
        # Site pages and routes for the B2B Commerce LWR site
sfdx-project.json
package.json              # Jest config, sfdx-lwc-jest dependency
jest.config.js            # LWC Jest configuration
```

## Installation Commands

```bash
# CLI setup (one-time)
npm install -g @salesforce/cli

# Project initialization
sf project generate --name invoice-portal --template standard

# Dev dependencies for testing
npm install -D @salesforce/sfdx-lwc-jest

# Run LWC tests
npm test
# or
sf force lightning lwc test run

# Deploy to org
sf project deploy start --source-dir force-app --target-org my-org

# Retrieve from org
sf project retrieve start --source-dir force-app --target-org my-org

# Create unmanaged package
sf package version create --package "Invoice Portal" --wait 10 --target-dev-hub my-hub
```

## sfdx-project.json Configuration

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "InvoicePortal",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT"
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "66.0"
}
```

## Sources

- [Salesforce Spring '26 Release Notes - API v66.0](https://developer.salesforce.com/blogs/2026/01/developers-guide-to-the-spring-26-release) -- HIGH confidence
- [Salesforce Payments SDK v7.0.0 Documentation](https://salesforcecommercecloud.github.io/payments-sdk-doc/v7.0.0/html/) -- HIGH confidence (local copy in docs/payments-sdk.md)
- [B2B Commerce LWR Storefront Performance Best Practices](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-storefront-performance-best-practices.html) -- HIGH confidence
- [Build Custom Components for B2B Commerce](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-lwc-for-lwr-container.html) -- HIGH confidence
- [Salesforce CLI Setup Guide v66.0](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/sfdx_setup.pdf) -- HIGH confidence
- [NavigationMixin for LWR](https://developer.salesforce.com/docs/platform/lwr/references/csr-reference/navigationmixin.html) -- HIGH confidence
- [LWC Jest Testing Installation](https://developer.salesforce.com/docs/platform/lwc/guide/unit-testing-using-jest-installation.html) -- HIGH confidence
- [Public Commerce LWR Component Library (GitHub)](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-public-lwr-library.html) -- HIGH confidence
- [Salesforce Spring '26 API v66.0 Details](https://www.conemis.com/news/salesforce-spring-26-release-api-version-66-0) -- MEDIUM confidence
