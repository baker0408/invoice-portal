# Salesforce Payments Client Side SDK - v7.0.0

> Source: https://salesforcecommercecloud.github.io/payments-sdk-doc/v7.0.0/html/

---

## Table of Contents

- [Getting Started](#getting-started)
- [Classes](#classes)
  - [Checkout](#checkout)
  - [Component](#component)
  - [Express](#express)
  - [SFPayments](#sfpayments)
  - [Setup](#setup)
- [Interfaces](#interfaces)
  - [Address](#address)
  - [AdyenLabels](#adyenlabels)
  - [BillingDetails](#billingdetails)
  - [ExpressButtonColors](#expressbuttoncolors)
  - [ExpressButtonLabels](#expressbuttonlabels)
  - [ExpressLineItem](#expresslineitem)
  - [ExpressStyle](#expressstyle)
  - [Labels](#labels)
  - [PaymentData](#paymentdata)
  - [PaymentIntentRequest](#paymentintentrequest)
  - [PaymentMethodSet](#paymentmethodset)
  - [PaymentMethodSpecificOptions](#paymentmethodspecificoptions)
  - [PaymentResponse](#paymentresponse)
  - [PaymentResponseFailureData](#paymentresponsefailuredata)
  - [PaymentResponseSuccessData](#paymentresponsesuccessdata)
  - [PaymentSetupRequest](#paymentsetuprequest)
  - [SDKConfig](#sdkconfig)
  - [SDKError](#sdkerror)
  - [SalesforcePaymentsCheckoutActions](#salesforcepaymentscheckoutactions)
  - [SalesforcePaymentsCheckoutConfig](#salesforcepaymentscheckoutconfig)
  - [SalesforcePaymentsCheckoutOptions](#salesforcepaymentscheckoutoptions)
  - [SalesforcePaymentsExpressActions](#salesforcepaymentsexpressactions)
  - [SalesforcePaymentsExpressConfig](#salesforcepaymentsexpressconfig)
  - [SalesforcePaymentsExpressOptions](#salesforcepaymentsexpressoptions)
  - [SalesforcePaymentsSetupActions](#salesforcepaymentssetupactions)
  - [SalesforcePaymentsSetupConfig](#salesforcepaymentssetupconfig)
  - [SalesforcePaymentsSetupOptions](#salesforcepaymentssetupoptions)
  - [SetupData](#setupdata)
  - [SetupResponse](#setupresponse)
  - [SetupResponseFailureData](#setupresponsefailuredata)
  - [SetupResponseSuccessData](#setupresponsesuccessdata)
  - [ShippingDetails](#shippingdetails)
  - [ShippingRate](#shippingrate)
  - [Theme](#theme)
  - [ThemeDesignTokens](#themedesigntokens)
  - [ThemeFont](#themefont)
  - [ThemeRule](#themerule)
- [Global Types](#global-types)
  - [Members / Enums](#members--enums)
  - [Methods / Type Definitions](#methods--type-definitions)
  - [Events](#events)
- [Tutorials](#tutorials)
  - [Error Reporting](#tutorial-error-reporting)
  - [Theme Configuration](#tutorial-theme-configuration)

---

## Getting Started

The Salesforce Payments JS SDK provides functionality for use in client side JS (browser) contexts to present payment components. These components integrate vendor JavaScript SDKs to deliver secure, contemporary payment interfaces.

### Step 1: Include the JS SDK

```javascript
import basePath from '@salesforce/community/basePath';
import { loadScript } from 'lightning/platformResourceLoader';

const sfpVersion = 'v7';
const SF_PAYMENTS_ASSETS_PATH = `${basePath}/sfsites/assets/payments`;

export function getSdkUrl(): string {
    return `${SF_PAYMENTS_ASSETS_PATH}/${sfpVersion}/sfp.js`;
}

function getMetadataUrl(): string {
    return `${SF_PAYMENTS_ASSETS_PATH}/metadata/${sfpVersion}.json`;
}

await loadScript(this, getSdkUrl());
```

### Step 2: Create SFPayments Object

```javascript
const sfp = new SFPayments();
```

Note: When using `defer` in script tags, wait until `SFPayments` becomes available.

### Step 3: Mount Payment Component

```javascript
const myCheckout = sfp.checkout(metadata, paymentMethodSet, config,
    paymentRequest, '.my-element', spmConfig, actions);
```

Requires: payments metadata, merchant payment method set, configuration, and lifecycle action handlers.

### Step 4: Confirm Payment

```javascript
const result = await myCheckout.confirm();
```

Returns payment authorization/capture details on success or error information on failure.

### Available Components

- **Checkout** - Primary payment processing component
- **Express** - Expedited payment option
- **Setup** - Payment method configuration

---

## Classes

### Checkout

The Checkout class is a component that presents a selection of payment methods determined by the payment method set and related configuration. It extends the [Component](#component) class.

#### Members

##### abortapplepay (Event Listener)

Aborts the Apple Pay payment app and hides its popup when the currently selected payment method is Apple Pay. Bubble this event to cancel a previously bubbled `showapplepay` event.

##### showapplepay (Event Listener)

Shows the Apple Pay payment app when the currently selected payment method is Apple Pay. Bubble this event to display the payment app before calling the `confirm()` function. If `confirm` is not called within 10 seconds, the payment app will automatically abort.

#### Methods

##### confirm(createIntentFunction, billingDetails, shippingDetails) → Promise

Confirms payment for the currently selected payment method using user-inputted values.

**Parameters:**

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `createIntentFunction` | `createIntentFunction` | Yes | Asynchronous function creating a Stripe PaymentIntent. Uses `SalesforcePaymentsCheckoutActions.createIntentFunction` if not provided. |
| `billingDetails` | `BillingDetails` | Yes | Billing information for the payment. Uses `PaymentIntentRequest.billingDetails` if not provided. |
| `shippingDetails` | `ShippingDetails` | Yes | Shipping information for the payment. |

**Returns:** Promise resolving with success/failure response or rejecting on error.

**Return Type:** `Promise.<PaymentResponse>`

##### destroy()

Destroys all elements and other data for this component.

**Since:** 3.0

**Inherited From:** [Component#destroy](#component)

---

### Component

The Component class serves as a base class component within the Payments SDK.

#### Methods

##### destroy()

Destroys all elements and other data for this component.

**Since:** 3.0

---

### Express

The Express class is a component that presents payment method options determined by the payment method set and its configuration. It extends the [Component](#component) class.

#### Methods

##### destroy()

Destroys all elements and other data associated with this component.

**Since:** 3.0

**Inherited From:** [Component#destroy](#component)

#### Related Interfaces & Types

The Express component works with numerous configuration interfaces including:

- SalesforcePaymentsExpressConfig
- SalesforcePaymentsExpressOptions
- SalesforcePaymentsExpressActions
- ExpressStyle
- ExpressButtonColors
- ExpressButtonLabels
- PaymentMethodSet

#### Events

The Express component can trigger various events such as:

- load
- paymentMethodSelected
- paymentconfirmed
- paymentmethoddetailschanged
- sfppaymentbuttonclick
- sfppaymentbuttonapprove
- sfppaymentbuttoncancel
- sfppaymentbuttonerror

---

### SFPayments

The SFPayments class is the primary interface for constructing and mounting Salesforce Payments components. It manages payment processing through checkout, express, and setup payment sheet components.

#### Constructor

##### new SFPayments(config)

Constructs a Salesforce Payments object.

**Parameter:**

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `config` | `SDKConfig` | Yes | SDK configuration information. Available since version 5.0. |

#### Methods

##### checkout(metadata, paymentMethodSet, config, paymentRequest, elementOrSelectorToMountTo) → Checkout

Creates and mounts a checkout payment sheet component to the DOM.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `metadata` | `Metadata` | Payment method metadata (since 4.0) |
| `paymentMethodSet` | `PaymentMethodSet` | Contains payment method details and vendor data |
| `config` | `SalesforcePaymentsCheckoutConfig` | Component configuration |
| `paymentRequest` | `PaymentIntentRequest` | Payment request details |
| `elementOrSelectorToMountTo` | `string \| HTMLElement` | Target DOM location |

**Returns:** Checkout component instance

##### express(metadata, paymentMethodSet, config, paymentRequest, elementOrSelectorToMountTo, expressType) → Express

Creates and mounts an express checkout component to the DOM.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `metadata` | `Metadata` | Payment method metadata (since 4.0) |
| `paymentMethodSet` | `PaymentMethodSet` | Payment method information and vendor data |
| `config` | `SalesforcePaymentsExpressConfig` | Component configuration |
| `paymentRequest` | `PaymentIntentRequest` | Payment request details |
| `elementOrSelectorToMountTo` | `string \| HTMLElement` | Target DOM location |
| `expressType` | `ExpressType` | Express checkout use case (since 2.0) |

**Returns:** Express component instance

##### handleRedirect() → Promise.<PaymentResponse>

Asynchronously handles redirects from third-party payment processors.

**Returns:** Promise resolving to PaymentResponse containing vendor payment status information.

##### setup(metadata, paymentMethodSet, config, paymentRequest, elementOrSelectorToMountTo) → Setup

Creates and mounts a saved payment method setup component to the DOM.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `metadata` | `Metadata` | Payment method metadata (since 4.0) |
| `paymentMethodSet` | `PaymentMethodSet` | Payment method information and vendor data |
| `config` | `SalesforcePaymentsSetupConfig` | Component configuration |
| `paymentRequest` | `PaymentSetupRequest` | Setup request details |
| `elementOrSelectorToMountTo` | `string \| HTMLElement` | Target DOM location (since 1.2) |

**Returns:** Setup component instance

---

### Setup

Payment sheet component to setup a saved payment method without making a payment at the time of setup. The Setup class extends the [Component](#component) class.

#### Methods

##### confirm(billingDetails) → Promise.<SetupResponse>

Confirms saved payment method setup for the currently selected payment method using user-entered values.

**Parameters:**

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `billingDetails` | `BillingDetails` | Yes | Billing information associated with the saved payment method. If omitted, the `PaymentSetupRequest.billingDetails` value is used instead. |

**Returns:** Promise resolving with a success/failure response to payment setup confirmation, or rejecting if confirmation encounters an error.

**Return Type:** `Promise.<SetupResponse>`

##### destroy()

Destroys all elements and associated data for this component.

**Since:** 3.0

**Inherited From:** [Component#destroy](#component)

---

## Interfaces

### Address

The Address interface provides a structured format for address information within the Payments SDK.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `line1` | string | required | Address line 1 (e.g., street, PO Box, or company name) |
| `line2` | string | optional | Address line 2 (e.g., apartment, suite, unit, or building) |
| `city` | string | required | City, district, suburb, town, or village |
| `state` | string | required | State, county, province, or region |
| `postalCode` | string | required | ZIP or postal code |
| `country` | string | required | Two-letter country code (ISO 3166-1 alpha-2) |

---

### AdyenLabels

The AdyenLabels interface provides additional optional labels for use in Adyen user interface controls.

**Since:** 3.0

#### Properties

All properties are optional strings.

**Bank Account Fields:**

| Name | Default |
|------|---------|
| `adyen.bankAccountTitle` | "Bank Account" |
| `adyen.usBankAccountHolderName` | "Account Holder" |
| `adyen.usBankAccountNumber` | "Account Number" |
| `adyen.usBankAccountHolderPlaceholder` | "Enter a name..." |
| `adyen.usBankAccountRoutingNumber` | "Bank Routing Number" |

**Error Messages:**

| Name | Default |
|------|---------|
| `adyen.usBankAccountHolderNameErrorMessage` | "Enter a valid account holder name" |
| `adyen.usBankAccountNumberErrorMessage` | "Enter a valid account number and try again" |
| `adyen.usBankAccountRoutingNumberErrorMessage` | "Enter a valid routing number and try again" |

**SEPA & BACS Labels:**

| Name | Default |
|------|---------|
| `adyen.sepaDebitHolderName` | "Account Holder" |
| `adyen.sepaDebitHolderPlaceholder` | "Enter a name..." |
| `adyen.bacsAccountHolderName` | — |
| `adyen.bacsAccountNumber` | — |
| `adyen.bacsSortCode` | — |
| `adyen.bacsEmailAddress` | — |

**Payment Status Messages:**

| Name | Default |
|------|---------|
| `adyen.paymentSuccessful` | "Payment was completed" |
| `adyen.paymentRefused` | "Payment refused" |
| `adyen.paymentFailed` | "Payment failed" |
| `adyen.paymentFailedUnknownError` | "We couldn't process your payment. Try again later." |

**Credit Card:**

| Name | Default |
|------|---------|
| `adyen.creditCardNameOnCard` | "Name on card" |
| `adyen.creditCardNameOnCardErrorMessage` | "Enter name as shown on card" |

---

### BillingDetails

The BillingDetails interface represents billing information associated with a payment.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `name` | string | optional | Full name |
| `email` | string | optional | Email address |
| `phone` | string | optional | Billing phone number (including extension) |
| `address` | Address | required | Billing address |

---

### ExpressButtonColors

The ExpressButtonColors interface defines color configuration options for express payment buttons across multiple payment providers.

**Since:** 4.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `applepay` | `ExpressButtonColorApplePay` | optional | Apple Pay express button color |
| `googlepay` | `ExpressButtonColorGooglePay` | optional | Google Pay express button color |
| `paypal` | `ExpressButtonColorPayPal` | optional | PayPal express button color |
| `venmo` | `ExpressButtonColorVenmo` | optional | Venmo express button color |

---

### ExpressButtonLabels

The ExpressButtonLabels interface defines label customization options for express payment buttons across different payment methods.

**Since:** 4.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `applepay` | `ExpressButtonLabelApplePay` | optional | Apple Pay express button type |
| `googlepay` | `ExpressButtonLabelGooglePay` | optional | Google Pay express button type |
| `paypal` | `ExpressButtonLabelPayPal` | optional | PayPal express button label |
| `venmo` | `ExpressButtonLabelVenmo` | optional | Venmo express button label |

---

### ExpressLineItem

The ExpressLineItem interface represents individual line items in an express checkout, displaying a breakdown of the total amount to the buyer in the express dialog before purchase.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `name` | string | The name of the line item surfaced to the buyer in the express dialog |
| `amount` | number | The amount in the currency's subunit (for example, cents, yen, etc.) |

---

### ExpressStyle

The ExpressStyle interface defines styling configuration for Express payment buttons.

**Since:** 2.0

#### Properties

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `buttonLayout` | `ExpressButtonLayout` | Yes | Express button layout direction |
| `buttonShape` | `ExpressButtonShape` | Yes | Express button shape |
| `buttonHeight` | `number` | Yes | Express button height in pixels |
| `buttonColors` | `ExpressButtonColors` | Yes | Express button colors (since 4.0) |
| `buttonLabels` | `ExpressButtonLabels` | Yes | Express button labels (since 4.0) |

---

### Labels

The Labels interface provides customizable text labels for UI controls in the Payments SDK. All properties are optional strings with predefined default values.

**Mixins:** Includes properties from the [AdyenLabels](#adyenlabels) interface.

#### Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `amountItemDescription` | string | Label for total item in Apple Pay/Google Pay requests | "Item" |
| `afterpayClearpayRedirect` | string | Afterpay/Clearpay redirect description | "To complete your payment, you'll be redirected to Afterpay." |
| `afterpayClearpayIconTitle` | string | Aria-label for Afterpay/Clearpay icon | "afterpay-clearpay-icon" |
| `afterpayClearpayTitle` | string | Afterpay/Clearpay payment method header | "Afterpay" |
| `afterpayTitle` | string | Afterpay payment method header | (varies) |
| `clearpayTitle` | string | Clearpay payment method header | (varies) |
| `afterpayClearpayDescription` | string | Afterpay/Clearpay descriptive text | "" |
| `bacsDebit` | string | Text above Bacs payment input | "" |
| `bacsDebitIconTitle` | string | Aria-label for Bacs icon | "Bacs icon" |
| `bacsDebitTitle` | string | Bacs payment method header | "Bacs" |
| `googlePayRedirect` | string | Google Pay next steps description | "To complete your payment, select a card when prompted." |
| `googlePayIconTitle` | string | Aria-label for Google Pay icon | "Google Pay icon" |
| `googlePayTitle` | string | Google Pay payment method header | "Google Pay" |
| `applePayRedirect` | string | Apple Pay next steps description | "To complete your payment, select a card when prompted." |
| `applePayIconTitle` | string | Aria-label for Apple Pay icon | "Apple Pay icon" |
| `applePayTitle` | string | Apple Pay payment method header | "Apple Pay" |
| `bancontactRedirect` | string | Bancontact redirect description | "To complete your payment, you'll be redirected to Bancontact." |
| `bancontactIconTitle` | string | Aria-label for Bancontact icon | "Bancontact icon" |
| `bancontactTitle` | string | Bancontact payment method header | "Bancontact" |
| `creditCardNumber` | string | Credit card number field label | "Card Number" |
| `creditCardExpiry` | string | Credit card expiration date label | "Expiration Date" |
| `creditCardCvc` | string | Credit card CVV/CVC field label | "CVV" |
| `creditCardCvcTooltip` | string | CVV/CVC field information tooltip | "Enter the 3 or 4-digit code found on the front or back of your card." |
| `creditCardIconTitle` | string | Aria-label for credit card icon | "Credit card icon" |
| `creditCardTitle` | string | Credit card payment method header | "Credit Card" |
| `creditCardNumberErrorMessage` | string | Credit card number error message | "Enter a valid card number" |
| `creditCardExpiryErrorMessage` | string | Credit card expiry error message | "Enter a valid date" |
| `creditCardCvvErrorMessage` | string | Credit card CVV error message | "Enter a valid CVV" |
| `epsBank` | string | Text above EPS bank input | "Bank Name" |
| `epsRedirect` | string | EPS bank redirect description | "To complete your payment, you'll be redirected to your bank." |
| `epsIconTitle` | string | Aria-label for EPS icon | "EPS icon" |
| `epsTitle` | string | EPS payment method header | "EPS" |
| `idealBank` | string | Text above iDEAL bank input | "Bank Name" |
| `idealRedirect` | string | iDEAL bank redirect description | "To complete your payment, you'll be redirected to your bank." |
| `idealIconTitle` | string | Aria-label for iDEAL icon | "iDEAL icon" |
| `idealTitle` | string | iDEAL payment method header | "iDEAL" |
| `klarnaRedirect` | string | Klarna redirect description | "To complete your payment, select an option and follow the prompts." |
| `klarnaIconTitle` | string | Aria-label for Klarna icon | "Klarna icon" |
| `klarnaTitle` | string | Klarna payment method header | "Klarna" |
| `sepaDebitIconTitle` | string | Aria-label for SEPA Debit icon | "SEPA Debit icon" |
| `sepaDebitTitle` | string | SEPA Debit payment method header | "SEPA Debit" |
| `sepaDebitIban` | string | SEPA Debit IBAN field label | "IBAN" |
| `sepaDebitIbanErrorMessage` | string | SEPA Debit IBAN error message | "Enter a valid International Bank Account Number (IBAN)" |
| `sepaDebitAuthorizationMandate` | string | SEPA Debit authorization mandate text | "By providing your IBAN and confirming this payment..." |
| `auBecsDebit` | string | Text above BECS Debit input | "" |
| `auBecsDebitIconTitle` | string | Aria-label for BECS icon | "BECS icon" |
| `auBecsDebitTitle` | string | BECS Debit payment method header | "BECS Debit" |
| `savePaymentMethodForFutureUse` | string | Save payment method checkbox label | "Save payment method for future use" |
| `makePaymentMethodDefault` | string | Set as default checkbox label | "Make payment method default" |
| `paypalTitle` | string | PayPal payment method header | "PayPal" |
| `paypalIconTitle` | string | Aria-label for PayPal icon | "PayPal icon" |
| `paypalRedirect` | string | PayPal redirect description | "You'll be redirected to PayPal where you will complete your order." |
| `venmoTitle` | string | Venmo payment method header | "Venmo" |
| `venmoIconTitle` | string | Aria-label for Venmo icon | "Venmo icon" |
| `venmoRedirect` | string | Venmo redirect description | "You'll be redirected to Venmo where you will complete your order." |
| `savedPaymentMethodEndingWith` | string | Saved payment method account text | "ending in {0}" |
| `savedPaymentMethodDefault` | string | Default badge text | "Default" |
| `cardTypeIconTitle` | string | Saved card descriptive title | "{0} icon" |
| `cardTypeVisa` | string | Visa brand label | "Visa" |
| `cardTypeMastercard` | string | MasterCard brand label | "MasterCard" |
| `cardTypeAmex` | string | American Express brand label | "American Express" |
| `cardTypeDiners` | string | Diners Club brand label | "Diners Club" |
| `cardTypeJcb` | string | JCB brand label | "JCB" |
| `cardTypeDiscover` | string | Discover brand label | "Discover" |
| `cardTypeUnionpay` | string | UnionPay brand label | "UnionPay" |
| `usBankAccount` | string | Text above ACH payment input | "" |
| `usBankAccountIconTitle` | string | Aria-label for ACH icon | "ACH icon" |
| `usBankAccountTitle` | string | ACH payment method header | "ACH/Bank Account" |
| `usBankAccountPaymentMethodTitle` | string | Saved ACH account descriptive text | "ACH/{0}" |
| `viewAll` | string | View all payment methods action | "View all ({0} more)" |
| `redirectNotification` | string | Default redirect notification | "To complete your payment, you'll be redirected." |
| `paymentAppDescription` | string | Payment app description | "To complete your payment, follow the directions in the popup." |
| `iconTitle` | string | Default alt attribute for icons | "{0} icon" |
| `finalAmountTitle` | string | Express button final amount title | "Final Amount" |
| `productAmountTitle` | string | Express button product amount title | "Product Amount" |
| `usBankAccountMotoAccountNumber` | string | ACH account number field label | "Account Number" |
| `usBankAccountMotoAccountType` | string | ACH account type field label | "Account Type" |
| `usBankAccountMotoSelectAccountType` | string | ACH select account type label | "Select Account Type" |
| `usBankAccountMotoPersonal` | string | ACH personal account type label | "Personal" |
| `usBankAccountMotoBusiness` | string | ACH business account type label | "Business" |
| `usBankAccountMotoConsentCollectionMethod` | string | ACH consent collection method label | "Consent Collection Method" |
| `usBankAccountMotoPhone` | string | ACH phone field label | "Phone" |
| `usBankAccountMotoWritten` | string | ACH written field label | "Written" |
| `usBankAccountMotoRoutingNumber` | string | ACH routing number field label | "Routing Number" |
| `usBankAccountMotoChecking` | string | ACH checking account type label | "Checking" |
| `usBankAccountMotoSavings` | string | ACH savings account type label | "Savings" |
| `usBankAccountMotoConsentMandateTitle` | string | ACH consent mandate title label | "Consent Mandate" |
| `usBankAccountMotoConsentMandateText` | string | ACH consent mandate text label | "" |
| `usBankAccountMotoAccountTypeError` | string | ACH account type error message | "Please select an account type." |
| `usBankAccountMotoRoutingNumberError` | string | ACH routing number error message | "Please enter a valid routing number." |
| `usBankAccountMotoAccountNumberError` | string | ACH account number error message | "Please enter a valid account number." |
| `usBankAccountMotoIframeTitle` | string | ACH iframe title label | "Bank transfer input from." |
| `shippingAddressUnserviceable` | string | Unserviceable address label | "Cannot ship to the selected address." |

---

### PaymentData

The PaymentData interface represents payment information.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `id` | string | required | Vendor payment identifier |
| `uuid` | string | optional | Generated unique identifier for the payment, if available |
| `paymentGatewayId` | string | optional | Identifier of the PaymentGateway for the payment, if available |
| `gatewayCustomerId` | string | optional | Identifier of the customer this payment object belongs to at the Vendor's side, if one exists |

---

### PaymentIntentRequest

The PaymentIntentRequest interface represents a request to confirm a payment.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `amount` | number | required | Payment amount in the requested currency |
| `currency` | string | required | 3 digit ISO 4217 payment currency code |
| `country` | string | required | 2 character ISO 3166 alpha-2 payment account country code. Used in payment request objects for Apple Pay and Google Pay. |
| `locale` | string | required | 2 character ISO 639 alpha-2 language code |
| `billingDetails` | BillingDetails | optional | Billing information to associate with payment. Can be omitted if not known at the time of the request. |

#### Code Example

```javascript
const request: PaymentIntentRequest = {
  amount: 10.99,
  currency: 'USD',
  country: 'US',
  locale: 'en',
}
```

---

### PaymentMethodSet

The PaymentMethodSet interface represents a Salesforce `MerchAccPaymentMethodSet` object. It contains payment methods to present, and vendor information to use to create user interface controls and confirm payments for those payment methods.

---

### PaymentMethodSpecificOptions

The PaymentMethodSpecificOptions interface provides payment method-specific configuration settings.

#### Properties

##### usBankAccountMoto (optional, Object)

Configuration for the Moto US Bank Account payment method.

**Sub-properties:**

| Name | Type | Optional | Default | Description |
|------|------|----------|---------|-------------|
| `formPath` | string | Yes | `undefined` | Path to ach-moto-form.html form |
| `consentCollectionOptions` | string | Yes | `undefined` | Consent collection options for ach-moto-form.html form |

##### usBankAccount (optional, Object)

Configuration for the US Bank Account payment method.

**Sub-properties:**

| Name | Type | Optional | Default | Description | Since |
|------|------|----------|---------|-------------|-------|
| `businessEnabled` | boolean | Yes | `false` | Enable US business bank accounts for the ACH payment method. Pass `true` to support both business and personal accounts, or `false` for personal accounts only. | 5.0 |

---

### PaymentResponse

The PaymentResponse interface represents the response returned when confirming a payment.

#### Members

##### data

**Type:** `PaymentResponseSuccessData | PaymentResponseFailureData`

Contains the response data, which varies based on whether the payment confirmation succeeded or failed.

##### responseCode

**Type:** `ResponseCode`

Indicates whether the payment confirmation operation succeeded or encountered a failure.

---

### PaymentResponseFailureData

Information about an unsuccessful payment confirmation.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `error` | any | required | Error message or object describing a potential cause for payment confirmation failure |
| `status` | string | optional | Status of the payment, if available |

---

### PaymentResponseSuccessData

Information about a successfully confirmed payment.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `paymentData` | PaymentData | required | Payment information |
| `paymentToken` | string | required | Payment token/identifier |
| `billingDetails` | BillingDetails | required | Billing details associated with the payment |
| `status` | string | optional | Status of the payment, if available |

---

### PaymentSetupRequest

The PaymentSetupRequest interface represents a request to confirm saved payment method setup.

**Since:** 1.2

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `currency` | string | optional | Optional 3 digit ISO 4217 payment currency code. If provided, used to filter presented payment methods. |
| `country` | string | required | 2 character ISO 3166 alpha-2 payment account country code. Used in payment request objects for Apple Pay and Google Pay. |
| `locale` | string | required | 2 character ISO 639 alpha-2 language code |
| `billingDetails` | BillingDetails | optional | Billing information to associate with payment. Can be omitted if not known at the time of the request. |

#### Code Example

```javascript
const request: PaymentSetupRequest = {
  currency: 'USD',
  country: 'US',
  locale: 'en',
}
```

---

### SDKConfig

The SDKConfig interface defines SDK configuration information.

**Since:** 5.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `report` | function | optional | Function for the SDK to call when an internal error is to be reported. |

---

### SDKError

The SDKError interface describes an SDK internal error.

**Since:** 5.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `code` | string | required | Unique error code |
| `vendor` | string | optional | When relevant, the vendor associated with the error |
| `type` | string | optional | When relevant, the type of error |
| `message` | string | optional | When relevant, a human readable message describing the error. Messages are not expected to be user-facing. |

---

### SalesforcePaymentsCheckoutActions

Actions for use by the checkout component.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `createIntentFunction` | `createIntentFunction` | Asynchronous function to create a Payment Intent to be confirmed. |
| `updateIntentFunction` | `updateIntentFunction` | Asynchronous function to update a Payment Intent. |

---

### SalesforcePaymentsCheckoutConfig

Configuration information for the Checkout component.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `labels` | `Labels` | optional | Labels for use in user interface controls. If not provided, many labels have default values which are used instead. |
| `theme` | `Theme` | optional | Theme information to influence the look & feel of user interface controls. If not provided, a light mode SLDS type theme is applied by default. (Since 2.0.0) |
| `actions` | `SalesforcePaymentsCheckoutActions` | required | Callback functions needed to handle checkout payments. |
| `options` | `SalesforcePaymentsCheckoutOptions` | required | Properties needed to handle checkout payments. |

---

### SalesforcePaymentsCheckoutOptions

Options that configure the behavior of the checkout component.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Default | Description |
|------|------|------------|---------|-------------|
| `returnUrl` | string | optional | — | URL to which to return after redirect to a 3rd party site to confirm payment asynchronously. Required for Afterpay/Clearpay, Bancontact, EPS, Ideal and Klarna. |
| `useManualCapture` | boolean | optional | `false` | Controls payment capture timing: `true` for manual capture or `false` for automatic capture as part of confirmation. |
| `showSaveAsDefaultCheckbox` | boolean | optional | `true` | Indicates whether to present the checkbox to save the payment method as the default saved payment method. (Since 2.0.0) |
| `savedPaymentMethods` | `Array.<SavedPaymentMethod>` | optional | — | Array of Salesforce SavedPaymentMethod objects for presentation. |
| `showSaveForFutureUsageCheckbox` | boolean | optional | `false` | Indicates whether to display the checkbox for saving the payment method for future usage. |
| `enforceSavedPaymentMethod` | boolean | optional | `false` | Enforces saving the payment method, regardless of the 'Save for Future Usage' checkbox. |
| `maximumInitialPaymentMethods` | number | optional | — | Maximum number of payment methods to initially show before a View All link is presented. Default is to not have a maximum. (Since 3.0) |
| `moto` | boolean | optional | `false` | Mail Order Telephone Order flag. When enabled, Payment Intent and Setup Intent confirmation occur client-side. (Since 4.0) |
| `preferLegacyForms` | boolean | optional | `true` | If legacy forms are preferred for payment method presentation. (Since 6.0) |
| `custom` | `PaymentMethodSpecificOptions` | optional | — | Payment method-specific configuration options. |

---

### SalesforcePaymentsExpressActions

Actions for use by the express component.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `createIntentFunction` | `createIntentFunction` | Asynchronous function to create a Payment Intent to be confirmed. |
| `updateIntentFunction` | `updateIntentFunction` | Asynchronous function to update a Payment Intent. |
| `expressButtonClickFunction` | `expressButtonClickFunction` | Asynchronous function to get the payment method clicked. |
| `onShippingAddressChangeFunction` | `shippingAddressChangeFunction` | Asynchronous function performs the shipping update calculations based on selected shipping address. |
| `onShippingOptionChangeFunction` | `shippingOptionChangeFunction` | Asynchronous function performs the shipping update calculations based on selected shipping option. |

---

### SalesforcePaymentsExpressConfig

Configuration information for the Express payment component.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `labels` | `Labels` | optional | Labels for use in user interface controls. If not provided, many labels have default values which are used instead. |
| `theme` | `Theme` | optional | Theme information to influence the look & feel of user interface controls. If not provided, a light mode SLDS type theme is applied by default. (Since 2.0.0) |
| `actions` | `SalesforcePaymentsExpressActions` | required | Callback functions needed to handle express payments. |
| `options` | `SalesforcePaymentsExpressOptions` | required | Properties needed to handle express payments. |

---

### SalesforcePaymentsExpressOptions

Options that configure the behavior of the express component.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Default | Description |
|------|------|------------|---------|-------------|
| `returnUrl` | string | optional | — | URL to which to return after redirect to a 3rd party site to confirm payment asynchronously. Required for Afterpay/Clearpay, Bancontact, EPS, Ideal and Klarna. |
| `useManualCapture` | boolean | optional | `false` | If payment capture will be performed manually at a later time. Pass `true` for manual capture, or `false` to capture payment automatically as part of payment confirmation. |
| `shippingAddressRequired` | boolean | optional | `false` | Collect the buyer's shipping address by setting this option to true. If `true`, you must also supply a valid `shippingRates` option. |
| `emailAddressRequired` | boolean | optional | `false` | Collect the buyer's email address by setting this option to true. |
| `phoneNumberRequired` | boolean | optional | `false` | Collect the buyer's phone number by setting this option to true. |
| `billingAddressRequired` | boolean | optional | `true` | Collect the buyer's billing address. |
| `businessName` | string | optional | — | The name of the merchant's business. The business name is used to signal to the buyer who they're paying. |
| `shippingRates` | `Array.<ShippingRate>` | optional | — | An array of ShippingRate objects. The first shipping rate listed appears in the express dialog as the default option. |
| `displayItems` | `Array.<ExpressLineItem>` | optional | — | An array of ExpressLineItem objects. These are shown as line items in the express dialog, if line items are supported. |
| `custom` | `PaymentMethodSpecificOptions` | optional | — | Payment method specific configuration options. |
| `maximumButtonCount` | number | optional | `undefined` | The maximum number of buttons to show, as an integer in [1, 5]. Default is `undefined`, which means unlimited. (Since 6.0) |

---

### SalesforcePaymentsSetupActions

Actions for use by the setup component.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `createSetupIntentFunction` | `createSetupIntentFunction` | Asynchronous function to create a SetupIntent to be confirmed. (Since 1.2.0) |

---

### SalesforcePaymentsSetupConfig

Setup component configuration information.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `labels` | `Labels` | optional | Labels for use in user interface controls. If not provided, many labels have default values which are used instead. |
| `theme` | `Theme` | optional | Theme information to influence the look & feel of user interface controls. If not provided, a light mode SLDS type theme is applied by default. (Since 2.0.0) |
| `actions` | `SalesforcePaymentsSetupActions` | required | Callback functions required to manage payment method setup. |
| `options` | `SalesforcePaymentsSetupOptions` | required | Configuration properties required to manage payment method setup. |

---

### SalesforcePaymentsSetupOptions

Options that configure the behavior of the setup component.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Default | Description |
|------|------|------------|---------|-------------|
| `returnUrl` | string | optional | — | URL to which to return after redirect to a 3rd party site to confirm payment asynchronously. Required for Afterpay/Clearpay, Bancontact, EPS, Ideal and Klarna. |
| `useManualCapture` | boolean | optional | `false` | If payment capture will be performed manually at a later time. Pass `true` for manual capture, or `false` to capture payment automatically as part of payment confirmation. |
| `showSaveAsDefaultCheckbox` | boolean | optional | `false` | Indicates whether to present the checkbox to save the payment method as the default saved payment method. (Since 2.0.0) |
| `preferLegacyForms` | boolean | optional | `true` | If legacy forms are preferred for payment method presentation. (Since 6.0) |

---

### SetupData

The SetupData interface represents payment method setup information.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `id` | string | required | Vendor setup identifier |
| `uuid` | string | optional | Generated unique identifier for the setup, if available |
| `paymentGatewayId` | string | optional | Identifier of the PaymentGateway for the setup, if available |
| `gatewayCustomerId` | string | optional | Identifier of the customer this setup object belongs to at the Vendor's side, if one exists |

---

### SetupResponse

The SetupResponse interface represents the response to a payment method setup confirmation request.

**Since:** 2.0

#### Members

##### data

**Type:** `SetupResponseSuccessData | SetupResponseFailureData`

Contains the response data, which varies based on whether the setup operation succeeded or failed.

##### responseCode

**Type:** `ResponseCode`

Provides an indicator of the operation outcome. This enumerated value signals whether the setup request completed successfully or encountered an error condition.

---

### SetupResponseFailureData

Information about an unsuccessful payment method setup confirmation.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `error` | any | required | Error message or object describing a potential cause for payment method setup confirmation failure |
| `status` | string | optional | Status of the setup, if available |

---

### SetupResponseSuccessData

Information about a successfully confirmed payment method setup.

**Since:** 2.0

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `paymentData` | `SetupData` | required | Setup information |
| `token` | string | required | Payment method token/identifier |
| `billingDetails` | `BillingDetails` | required | Billing details that were associated with the setup |
| `status` | string | optional | Status of the setup, if available |

---

### ShippingDetails

The ShippingDetails interface represents shipping information to associate with a payment.

#### Properties

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `name` | string | optional | Recipient name |
| `address` | Address | required | Shipping address |

---

### ShippingRate

The ShippingRate interface represents a shipping rate selected by a buyer in the express dialog. It serves as a property of the `shippingratechange` event object.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `id` | string | Unique identifier for the shipping rate |
| `amount` | number | The charge amount for shipping services |
| `displayName` | string | The name of the shipping rate, displayed to the buyer in the express dialog |

---

### Theme

The Theme interface controls the visual presentation of UI components.

**Since:** 2.0

#### Properties

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `type` | `ThemeType` | Yes | Overall theme style; defaults to `"slds"` |
| `mode` | `ThemeMode` | Yes | Light/dark appearance preference; defaults to `"light"` |
| `fonts` | `Array.<ThemeFont>` | Yes | Collection of font definitions referenced in styling rules |
| `designTokens` | `ThemeDesignTokens` | Yes | Name-value pairs mapping design token identifiers to CSS property values |
| `rules` | `ThemeRules` | Yes | CSS styling rules for customizing specific UI control appearances |

See also: [Theme Configuration Tutorial](#tutorial-theme-configuration)

---

### ThemeDesignTokens

ThemeDesignTokens is an interface providing key/value pairs of design token names and corresponding CSS values. The listed properties have specific meaning, but custom properties are supported as well.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `font-family` | string | Default font-family |
| `font-size-2` | string | Constant typography token for font size 2 |
| `font-size-3` | string | Constant typography token for font size 3 |
| `font-size-4` | string | Constant typography token for font size 4 |
| `font-size-5` | string | Constant typography token for font size 5 |
| `font-size-6` | string | Constant typography token for font size 6 |
| `font-weight-regular` | string | Most all body copy |
| `font-weight-bold` | string | Used sparingly for emphasized text within regular body copy |
| `line-height-text` | string | Unitless line-heights for reusability |
| `color-text-default` | string | Body text color |
| `color-text-error` | string | Error text for inputs and error misc |
| `color-text-placeholder` | string | Input placeholder text |
| `color-text-tooltip` | string | Tooltip text |
| `color-text-weak` | string | Color for text that is purposefully de-emphasized to create visual hierarchy |
| `color-background` | string | Default background color for the whole app |
| `color-brand` | string | Primary brand color |
| `color-text-brand-primary` | string | Text color found on any primary brand color |
| `color-background-error` | string | Color for UI elements related to errors |
| `color-text-inverse` | string | Inverse text color for dark backgrounds |
| `color-background-success` | string | Color for UI elements that have to do with success |
| `color-background-tooltip` | string | Color for tooltip UI elements |
| `color-background-warning` | string | Color for UI elements that have to do with warning |
| `color-text-icon-default` | string | Default icon color |
| `color-background-row-hover` | string | Used as the background color for the hover state on rows or items on list-like components |
| `color-border-input` | string | Border color on form elements |
| `palette-neutral-75` | string | Neutral 75 (Since 2.1) |
| `palette-neutral-95` | string | Neutral 95 |
| `border-radius-medium` | string | Icons in lists, record home icon, unbound input elements |
| `border-radius-small` | string | Checkboxes |
| `spacing-large` | string | Constant spacing token for size Large (Since 3.0) |
| `spacing-medium` | string | Constant spacing token for size Medium |
| `spacing-small` | string | Constant spacing token for size Small |
| `spacing-x-large` | string | Constant spacing token for size X Large |
| `spacing-x-small` | string | Constant spacing token for size X Small |
| `spacing-xx-small` | string | Constant spacing token for size XX Small |
| `spacing-xxx-small` | string | Constant spacing token for size XXX Small |

---

### ThemeFont

The ThemeFont interface represents font configuration for theme styling.

**Since:** 3.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `linkHref` | string | The `href` attribute value used in a link element with `rel="stylesheet"` to load `@font-face` declarations. |

---

### ThemeRule

The ThemeRule interface defines CSS properties for styling UI controls.

**Since:** 2.0

#### Properties

| Name | Type | Description |
|------|------|-------------|
| `background-color` | string | CSS `background-color` property |
| `border` | string | CSS `border` property |
| `border-radius` | string | CSS `border-radius` property |
| `box-shadow` | string | CSS `box-shadow` property |
| `color` | string | CSS `color` property |
| `fill` | string | CSS `fill` property |
| `font-family` | string | CSS `font-family` property |
| `font-size` | string | CSS `font-size` property |
| `font-variant` | string | CSS `font-variant` property |
| `font-variation` | string | CSS `font-variation` property |
| `font-weight` | string | CSS `font-weight` property |
| `letter-spacing` | string | CSS `letter-spacing` property |
| `line-height` | string | CSS `line-height` property |
| `margin` | string | CSS `margin` property |
| `opacity` | string | CSS `opacity` property |
| `outline` | string | CSS `outline` property |
| `padding` | string | CSS `padding` property |
| `text-decoration` | string | CSS `text-decoration` property |
| `text-shadow` | string | CSS `text-shadow` property |
| `text-transform` | string | CSS `text-transform` property |
| `transition` | string | CSS `transition` property |

---

## Global Types

### Members / Enums

#### DeliveryMethod

Object representing shipping/delivery options.

| Property | Type | Attributes | Description |
|----------|------|------------|-------------|
| `name` | string | required | Delivery method name |
| `currencyIsoCode` | string | required | Currency code |
| `id` | string | required | Unique identifier |
| `shippingFee` | string | required | Fee amount in specified currency |
| `carrier` | string | optional | Shipping carrier |
| `classOfService` | string | optional | Service class |

#### ExpressButtonColorApplePay

- `BLACK`
- `WHITE`
- `WHITE_OUTLINE`

#### ExpressButtonColorGooglePay

- `BLACK`
- `WHITE`

#### ExpressButtonColorPayPal

- `GOLD` (recommended)
- `BLUE`
- `SILVER`
- `WHITE`
- `BLACK`

#### ExpressButtonColorVenmo

- `BLUE`
- `SILVER`
- `WHITE`
- `BLACK`

#### ExpressButtonLabelPayPal

- `PAYPAL` (recommended)
- `CHECKOUT`
- `BUYNOW`
- `PAY`

#### ExpressButtonLabelVenmo

- `VENMO`
- `CHECKOUT`
- `BUYNOW`
- `PAY`

#### ExpressButtonLayout

- `HORIZONTAL` - Row-based layout
- `VERTICAL` - Column-based layout

#### ExpressButtonShape

- `PILL` - Large radius, pill-shaped
- `RECTANGLE` - Zero radius, rectangular

#### ExpressButtonTypeApplePay

- `ADD_MONEY`
- `BOOK`
- `BUY`
- `CHECK_OUT`
- `CONTRIBUTE`
- `DONATE`
- `ORDER`
- `PLAIN`
- `RELOAD`
- `RENT`
- `SUBSCRIBE`
- `SUPPORT`
- `TIP`
- `TOP_UP`

#### ExpressButtonTypeGooglePay

- `BOOK`
- `BUY`
- `CHECKOUT`
- `DONATE`
- `ORDER`
- `PAY`
- `PLAIN`
- `SUBSCRIBE`

#### ExpressType

- `BUY_NOW` (0)
- `PAY_NOW` (1)

#### ResponseCode

- `SUCCESS` (0)
- `FAILURE` (1)

#### ThemeMode

- `LIGHT`
- `DARK`

#### ThemeType

- `NONE`
- `PLAIN`
- `SLDS`
- `CGX`

---

### Methods / Type Definitions

#### createIntentFunction(data) → Promise

Creates payment intent.

**Parameters:**

The `data` parameter includes:

| Name | Type | Optional | Description |
|------|------|----------|-------------|
| `paymentMethod` | — | Yes | Payment method information |
| `returnUrl` | string | Yes | Return URL for redirects |
| `billingDetails` | BillingDetails | Yes | Billing information |
| `shippingDetails` | ShippingDetails | Yes | Shipping information |
| `lineItems` | Array | Yes | Line items for the payment |

**Returns:** Promise resolving with gateway payment object (Stripe PaymentIntent or PayPal order).

#### createSetupIntentFunction() → Promise

Creates a setup intent.

**Returns:** Promise resolving with Stripe SetupIntent object.

#### expressButtonClickFunction(paymentMethodType) → shippingRatesData

Handles express button click events.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `paymentMethodType` | string | The payment method type string |

**Returns:** Object containing:

| Name | Type | Description |
|------|------|-------------|
| `shippingRates` | Array | Array of shipping method options |
| `amount` | string | The payment amount |

#### shippingAddressChangeFunction(shippingAddress, callback) → void

Handles shipping address changes.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `shippingAddress` | Object | Address with `city`, `state`, `country`, `postal_code` properties |
| `callback` | `updateShippingAddress` | Callback function to update the shipping address |

#### shippingOptionChangeFunction(shippingRate, callback) → void

Processes shipping rate selection.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `shippingRate` | Object | Shipping rate with `id` and optional `displayName` |
| `callback` | `updateShippingRate` | Callback function to update the shipping rate |

#### updateShippingData(updatedData) → void

Updates shipping information.

**Parameters:**

The `updatedData` object includes:

| Name | Type | Description |
|------|------|-------------|
| `grandTotalAmount` | number | Updated grand total amount |
| `shippingMethods` | Array | Updated shipping methods |
| `lineItems` | Array | Updated line items |
| `selectedShippingMethod` | Object | Currently selected shipping method |

---

### Events

#### load

Fired when payment sheet finishes loading.

**Event Data:**

| Property | Description |
|----------|-------------|
| `selectedPaymentMethod` | Currently selected payment method |
| `mode` | Payment mode |
| `requirements` | Object containing: pay button, billing details, email, phone requirements |
| `save/default preferences` | Save and default payment method preferences |
| `saved method info` | Information about saved payment methods |

#### paymentMethodSelected

Triggered when user selects a payment method. Includes same properties as `load` event.

#### paymentconfirmed

Fired after Apple Pay/Google Pay confirmation. Contains a `PaymentResponse` object.

#### paymentmethoddetailschanged

Emitted when element value changes.

**Event Data:**

| Property | Description |
|----------|-------------|
| `elementType` | Type of element that changed |
| `empty` | Whether the element is empty |
| `complete` | Whether the element is complete |
| `value` | Current value |
| `error` | Error information, if any |

#### sfppaymentbuttonapprove

Triggered after payer approval.

**Event Data:**

| Property | Description |
|----------|-------------|
| `paymentData` | Object with `id`, `gatewayId`, `customer`, `uuid` |
| `paymentToken` | Payment token |
| `intent` | Payment intent |
| `billingDetails` | Billing details |
| `shippingDetails` | Shipping details |

#### sfppaymentbuttonbeforeapprove

Fired before payment execution post-approval.

**Event Data:**

| Property | Description |
|----------|-------------|
| `billingDetails` | Billing details |
| `shippingDetails` | Shipping details |
| `addValidation` | Function for synchronous/asynchronous validation |

#### sfppaymentbuttoncancel

Bubbled when express checkout is canceled.

#### sfppaymentbuttonclick

Fired on PayPal/Venmo button click.

**Event Data:**

| Property | Description |
|----------|-------------|
| `selectedPaymentMethod` | Selected payment method |
| `paymentMode` | Payment mode |
| `fundingSource` | Funding source |
| `addValidation` | Function for validation |

#### sfppaymentbuttonerror

Emitted on payment error.

**Event Data:**

| Property | Description |
|----------|-------------|
| `responseCode` | Response code |
| `error` | Error message |

#### sfppaymentbuttonready

Triggered when buttons are ready.

**Event Data:**

| Property | Description |
|----------|-------------|
| `responseCode` | Response code |
| `availableButtons` | Array of available button types |

#### sfppaymentcancelled

Fired on payment cancellation.

**Event Data:**

| Property | Description |
|----------|-------------|
| `responseCode` | Response code |
| `message` | Cancel message |

#### sfppaymenterror

Emitted on payment error.

**Event Data:**

| Property | Description |
|----------|-------------|
| `responseCode` | Response code |
| `error` | Error message |

#### sfppaymentmethodsrendered

Fired after rendering payment methods.

**Event Data:**

| Property | Description |
|----------|-------------|
| `rendered` | Array of rendered payment method types |

---

## Tutorials

### Tutorial: Error Reporting

Applications can subscribe to receive notification of errors that occur. These errors include not only ones which would be apparent due to a thrown error or rejected promise, but also errors for which only console messages are logged.

The SFPayments object supports an optional configuration with a `report` function to handle error notifications.

#### Important Notes on Error Objects

SDK error objects contain diagnostic information about what occurred. This error information isn't intended to be presented to the application user - even the `message` property. Developers should determine user-facing error messages based on error type constants rather than displaying the raw error details.

#### Error Codes

The SDK defines the following unique error codes:

| Error Code | Description |
|------------|-------------|
| `ACCOUNT_NOT_FOUND` | Account reference in Payment Method Set doesn't exist in the set |
| `CHECKOUT_COMPONENT_CREATION_ERROR` | Checkout component creation failed |
| `COMPONENT_CREATION_FAILED` | Vendor payment method component creation error |
| `EXPRESS_COMPONENT_CREATION_ERROR` | Express component creation failed |
| `HANDLE_REDIRECT_ERROR` | URL parameter redirect handling error |
| `PAYPAL_EXPRESS_ONSHIPPINGCHANGE_EVENT_TIMEOUT` | PayPal shipping change event timeout |
| `PAYPAL_ORDER_PATCH_ERROR` | PayPal order patching failed |
| `PAYPAL_SCRIPT_LOAD_ERROR` | PayPal JS SDK script loading failed |
| `SETUP_COMPONENT_CREATION_ERROR` | Setup component creation failed |
| `STRIPE_SCRIPT_LOAD_ERROR` | Stripe.js script loading failed |
| `STRIPE_EXPRESS_CLICK_EVENT_TIMEOUT` | Stripe express click event timeout |
| `STRIPE_EXPRESS_CONFIRM_EVENT_ERROR` | Stripe express confirm event error |
| `STRIPE_EXPRESS_SHIPPINGADDRESSCHANGE_EVENT_TIMEOUT` | Stripe shipping address change timeout |
| `STRIPE_EXPRESS_SHIPPINGRATECHANGE_EVENT_TIMEOUT` | Stripe shipping rate change timeout |
| `VENDOR_NOT_FOUND` | Unknown vendor referenced |
| `VENDOR_PAYMENT_METHOD_NOT_FOUND` | Unsupported payment method for vendor account |

#### Error Types

When applicable, errors include a `type` identifying common patterns:

| Error Type | Description |
|------------|-------------|
| `COMPONENT_CREATION_ERROR` | Top-level component creation failures |
| `EVENT_TIMEOUT` | Vendor component event timeouts |
| `PAYMENT_METHOD_SET` | Invalid Payment Method Set information |
| `SCRIPT_LOAD_ERROR` | Vendor script loading failures |

---

### Tutorial: Theme Configuration

Components like Checkout support optional theme configuration to influence their appearance and feel. Although HTML templates follow Salesforce Lightning Design System component blueprints, applications don't need to use Lightning look and feel or Lightning CSS.

The Theme object in SalesforcePaymentsConfig controls look and feel properties. It enables applications to provide minimal information for default themes, add details to override specific colors and styles, or add rules for enhanced control.

#### Theme Type

Three theme types are supported via the Theme `type` property:

| Type | Description |
|------|-------------|
| `slds` (default) | Application uses Salesforce Lightning Design System with Lightning CSS present. The SDK applies CSS rules alongside existing Lightning CSS. |
| `plain` | Application doesn't use Salesforce Lightning Design System. The SDK applies CSS shim rules for a plain appearance without Lightning CSS. |
| `none` | No Salesforce Lightning Design System or CSS shims applied. Provides maximum control over CSS in your application while retaining theme configuration options. |

#### Theme Mode

Two theme modes are supported via the Theme `mode` property:

| Mode | Description |
|------|-------------|
| `light` (default) | Dark-on-light rendering with light background. Default icons and properties apply to light backgrounds. |
| `dark` | Light-on-dark rendering with dark background. Default icons and properties apply to dark backgrounds. |

Custom CSS can override icons, but custom icons must follow all relevant brand guidelines.

#### Custom CSS Limitations

Custom CSS style rules on the page have limitations with vendor components rendered by the SDK. Vendor components often use `<iframe>` elements for security and privacy, preventing CSS cascading into those contexts. Vendors also limit surrounding applications' ability to override brand colors and styles.

#### Theme Design Tokens

The Theme `designTokens` property defines colors and styles for the SDK to apply, similar to Salesforce Lightning Design System Design Tokens. The SDK passes design token values to vendor components and applies them in SDK CSS rules.

Supported values are documented in [ThemeDesignTokens](#themedesigntokens). Not all values apply to all vendor components -- branded vendor buttons may enforce brand-specific fonts, preventing overrides.

##### Custom CSS Properties for Design Tokens

Design token values generate custom CSS properties (CSS variables) on component root elements, starting with `--sfpp`:

```css
element.style {
    --sfpp-font-family: "My Awesome Font",sans-serif;
}
```

These cascade to child elements. Custom CSS can reference them:

```css
font-family: var(--sfpp-font-family);
```

Custom design token properties (e.g., `'my-favorite-border': '3px dashed blue'`) generate `--sfpp-my-favorite-border` properties that the SDK ignores but applications can use in custom CSS.

#### Theme Rules

The Theme `rules` property defines CSS rule equivalents for specific component elements. Rules configure styles by component type based on Lightning component blueprints.

Examples include `formLabel` and `error` rules applying to label and error feedback elements in the Form Field blueprint.

The SDK passes theme rule values to vendor components, with button rules applying to buttons and input rules to inputs, allowing styles to cascade into vendor `<iframe>` elements.

##### Pseudo-classes

CSS pseudo-classes specify element states like `:hover` and `:focus`. Theme rules support nested objects for states:

```javascript
rules: {
    button: {
        'font-weight': 'normal',
        hover: {
            'font-weight': 'bold',
        },
    },
},
```

Nested rule values override only those properties; others from the base rule still apply.

##### Custom CSS Properties for Rules

Rule values generate custom CSS properties on component root elements with names including the rule configuration path:

```css
element.style {
    --sfpp-button-font-weight: normal;
    --sfpp-button-hover-font-weight: bold;
}
```

Custom CSS can reference these properties. The SDK's own CSS rules use these custom properties and can be overridden.

#### Vendor-specific Configuration

(TBD)

---

*Copyright 2023 salesforce.com, inc. All rights reserved.*
