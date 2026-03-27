---
phase: 01-data-foundation
plan: 02
subsystem: api
tags: [apex, soql, account-scoping, cmdt, test-factory, permission-set]

# Dependency graph
requires:
  - phase: 01-data-foundation/01
    provides: "Custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c), Invoice_Payment_Line__c object, Invoice_Portal_Config__mdt with Default record, Invoice_Portal_User permission set"
provides:
  - "InvoiceService Apex controller with account-scoped invoice queries, tab filtering, and pagination"
  - "PaymentService Apex controller with CMDT config retrieval and processing fee calculation"
  - "TestDataFactory shared test data creation for Account, Invoice, Invoice_Payment_Line__c"
  - "InvoiceServiceTest and PaymentServiceTest with 13 total test methods"
  - "Invoice_Portal_User permission set updated with classAccesses for InvoiceService and PaymentService"
affects: [02-lwc-components, 03-payment-ui, 05-payment-processing]

# Tech tracking
tech-stack:
  added: []
  patterns: [account-scoped-soql, dynamic-soql-with-tab-filtering, cmdt-config-pattern, aura-handled-exception]

key-files:
  created:
    - force-app/main/default/classes/InvoiceService.cls
    - force-app/main/default/classes/PaymentService.cls
    - force-app/main/default/classes/TestDataFactory.cls
    - force-app/main/default/classes/InvoiceServiceTest.cls
    - force-app/main/default/classes/PaymentServiceTest.cls
  modified:
    - force-app/main/default/permissionsets/Invoice_Portal_User.permissionset-meta.xml

key-decisions:
  - "Dynamic SOQL for getInvoices to support runtime tab filter and date range composition"
  - "AuraHandledException thrown when account context is null (non-portal users) rather than silent empty results"
  - "Test classes handle both portal and non-portal execution contexts via try/catch on AuraHandledException"

patterns-established:
  - "Account scoping pattern: every Invoice SOQL query includes (BillingAccountId = :accountId OR Sold_To_Account__c = :accountId)"
  - "Portal user resolution: getAccountIdForCurrentUser() queries User -> Contact -> AccountId"
  - "CMDT config access: single getPortalConfig() method querying DeveloperName='Default'"
  - "Test data factory: shared @IsTest class with static factory methods for reusable test data"

requirements-completed: [DATA-04]

# Metrics
duration: 3min
completed: 2026-03-27
---

# Phase 01 Plan 02: Apex Service Layer Summary

**Account-scoped InvoiceService and PaymentService with tab filtering, CMDT config, processing fee calculation, and 13 test methods via shared TestDataFactory**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-27T16:12:12Z
- **Completed:** 2026-03-27T16:15:15Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- InvoiceService enforces account scoping (DATA-04) in all SOQL queries via BillingAccountId OR Sold_To_Account__c dual-key WHERE clause
- InvoiceService supports 3 tabs (open, paid, priorYear), date range filtering, and server-side pagination with dynamic SOQL
- PaymentService reads portal config from Invoice_Portal_Config__mdt and calculates processing fees with proper HALF_UP rounding
- TestDataFactory provides reusable data creation for Account, Invoice (with BillingAccount and SoldTo variants), and Invoice_Payment_Line__c
- 13 test methods across InvoiceServiceTest (8) and PaymentServiceTest (5) covering all public methods
- Permission set updated with classAccesses for both Apex controllers

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InvoiceService, PaymentService, and TestDataFactory Apex classes** - `d3833b0` (feat)
2. **Task 2: Create test classes and update permission set with classAccesses** - `554b823` (feat)

## Files Created/Modified
- `force-app/main/default/classes/InvoiceService.cls` - Account-scoped invoice queries with tab filtering, date range, pagination
- `force-app/main/default/classes/InvoiceService.cls-meta.xml` - Apex class metadata (API v66.0)
- `force-app/main/default/classes/PaymentService.cls` - Portal config access, processing fee calculation, payment stub
- `force-app/main/default/classes/PaymentService.cls-meta.xml` - Apex class metadata (API v66.0)
- `force-app/main/default/classes/TestDataFactory.cls` - Shared test data creation (Account, Invoice, Invoice_Payment_Line__c)
- `force-app/main/default/classes/TestDataFactory.cls-meta.xml` - Apex class metadata (API v66.0)
- `force-app/main/default/classes/InvoiceServiceTest.cls` - 8 test methods for InvoiceService
- `force-app/main/default/classes/InvoiceServiceTest.cls-meta.xml` - Apex class metadata (API v66.0)
- `force-app/main/default/classes/PaymentServiceTest.cls` - 5 test methods for PaymentService
- `force-app/main/default/classes/PaymentServiceTest.cls-meta.xml` - Apex class metadata (API v66.0)
- `force-app/main/default/permissionsets/Invoice_Portal_User.permissionset-meta.xml` - Added classAccesses for InvoiceService and PaymentService

## Decisions Made
- Used dynamic SOQL in getInvoices to compose WHERE clauses at runtime based on tab filter, date range, and account scoping -- required for the variable filter combinations
- AuraHandledException thrown when account context is null rather than returning empty results -- provides clear error feedback to LWC callers
- Test classes handle both portal user and non-portal user contexts via try/catch, with documentation noting that full account scoping validation requires a community-licensed org with portal users

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added InvoiceListResult structure test and rounding precision test**
- **Found during:** Task 2
- **Issue:** Plan specified 7 test methods for InvoiceServiceTest and 4 for PaymentServiceTest. Added testInvoiceListResultStructure (ensures inner class coverage) and testCalculateProcessingFeeRounding (verifies HALF_UP precision edge case) for more thorough coverage.
- **Fix:** Added 2 additional test methods to ensure inner class coverage and fee rounding precision
- **Files modified:** InvoiceServiceTest.cls, PaymentServiceTest.cls
- **Verification:** All test methods present, verification script passes
- **Committed in:** 554b823 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Additional test coverage for correctness. No scope creep.

## Issues Encountered
None

## Known Stubs

- `PaymentService.processPayment()` - Stub method for Phase 5 implementation. Validates account context but does not create Payment/PaymentLineItem/Invoice_Payment_Line__c records. Intentional per plan -- Phase 5 will implement full payment processing.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All Apex service methods ready for LWC @wire and imperative calls in Phase 2 (invoiceListView component)
- InvoiceService.getInvoices returns InvoiceListResult with pagination metadata for datatable rendering
- PaymentService.getPortalConfig provides configuration for payment UI in Phase 3
- processPayment stub must be implemented in Phase 5 before payment flow is functional

## Self-Check: PASSED

All 11 files verified present. Both task commits (d3833b0, 554b823) found in git log. SUMMARY.md exists.

---
*Phase: 01-data-foundation*
*Completed: 2026-03-27*
