---
phase: 01-data-foundation
plan: 01
subsystem: database
tags: [salesforce, sfdx, metadata-xml, custom-objects, cmdt, permission-sets]

# Dependency graph
requires: []
provides:
  - SFDX project scaffold with API v66.0
  - Invoice custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c)
  - Invoice_Payment_Line__c junction object with 6 fields
  - Invoice_Portal_Config__mdt CMDT with 7 settings and Default record
  - Invoice_Portal_User permission set (fields and objects only)
affects: [01-02, 02-apex-services, 03-lwc-components]

# Tech tracking
tech-stack:
  added: [sfdx-project-format, api-v66.0]
  patterns: [sfdx-source-xml, cmdt-single-record-config, lookup-over-master-detail]

key-files:
  created:
    - sfdx-project.json
    - force-app/main/default/objects/Invoice/fields/PO_Number__c.field-meta.xml
    - force-app/main/default/objects/Invoice/fields/Portal_Status__c.field-meta.xml
    - force-app/main/default/objects/Invoice/fields/Sold_To_Account__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/Invoice_Payment_Line__c.object-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Payment__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Invoice__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Payment_Amount__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Short_Pay_Reason__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Comments__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Payment_Line__c/fields/Processing_Fee__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/Invoice_Portal_Config__mdt.object-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/Processing_Fee_Percent__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/Processing_Fee_Enabled__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/ACH_Enabled__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/Credit_Card_Enabled__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/Invoices_Per_Page__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/PaymentLink_TTL_Hours__c.field-meta.xml
    - force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/Short_Pay_Reasons__c.field-meta.xml
    - force-app/main/default/customMetadata/Invoice_Portal_Config.Default.md-meta.xml
    - force-app/main/default/permissionsets/Invoice_Portal_User.permissionset-meta.xml
  modified: []

key-decisions:
  - "Lookup relationships (not Master-Detail) for both Payment__c and Invoice__c on junction object per RESEARCH.md anti-patterns"
  - "Single-record CMDT design with Default record for all 7 portal settings"
  - "Permission set defers classAccesses to Plan 02 when Apex classes are created"

patterns-established:
  - "SFDX source XML: all metadata as individual XML files in force-app/main/default/"
  - "CMDT single-record pattern: one Default record with all config values"
  - "Restricted picklists: Portal_Status__c and Short_Pay_Reason__c use restricted=true"

requirements-completed: [DATA-01, DATA-02, DATA-03]

# Metrics
duration: 2min
completed: 2026-03-27
---

# Phase 01 Plan 01: Data Foundation Metadata Summary

**SFDX project scaffold with Invoice custom fields, Invoice_Payment_Line__c junction object, Invoice_Portal_Config__mdt CMDT with defaults, and Invoice_Portal_User permission set -- all as deployable source XML**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-27T16:06:54Z
- **Completed:** 2026-03-27T16:09:26Z
- **Tasks:** 3
- **Files created:** 21

## Accomplishments
- SFDX project scaffold with API v66.0 and no namespace, ready for deployment
- Complete data model: 3 Invoice custom fields + Invoice_Payment_Line__c with 6 fields matching PRD Sections 7.2 and 7.3
- Invoice_Portal_Config__mdt CMDT with 7 configurable settings and Default record matching PRD Section 10 defaults
- Invoice_Portal_User permission set granting field and object access for all custom metadata

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SFDX project scaffold and Invoice custom fields** - `d8376ac` (feat)
2. **Task 2: Create Invoice_Payment_Line__c junction object with all fields** - `8f5766d` (feat)
3. **Task 3: Create CMDT type, default record, and permission set** - `eefbb3b` (feat)

## Files Created/Modified
- `sfdx-project.json` - SFDX project config with API v66.0, no namespace
- `force-app/main/default/objects/Invoice/fields/PO_Number__c.field-meta.xml` - Text(50) customer PO reference
- `force-app/main/default/objects/Invoice/fields/Portal_Status__c.field-meta.xml` - Picklist (Open, In Progress, Paid)
- `force-app/main/default/objects/Invoice/fields/Sold_To_Account__c.field-meta.xml` - Lookup(Account) for sold-to
- `force-app/main/default/objects/Invoice_Payment_Line__c/Invoice_Payment_Line__c.object-meta.xml` - Junction object definition
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Payment__c.field-meta.xml` - Lookup(Payment), Restrict delete
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Invoice__c.field-meta.xml` - Lookup(Invoice), SetNull delete
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Payment_Amount__c.field-meta.xml` - Currency(18,2), required
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Short_Pay_Reason__c.field-meta.xml` - Picklist with 5 reason codes
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Comments__c.field-meta.xml` - LongTextArea(255)
- `force-app/main/default/objects/Invoice_Payment_Line__c/fields/Processing_Fee__c.field-meta.xml` - Currency(18,2), optional
- `force-app/main/default/objects/Invoice_Portal_Config__mdt/Invoice_Portal_Config__mdt.object-meta.xml` - CMDT type definition
- `force-app/main/default/objects/Invoice_Portal_Config__mdt/fields/*.field-meta.xml` - 7 CMDT setting fields
- `force-app/main/default/customMetadata/Invoice_Portal_Config.Default.md-meta.xml` - Default config record
- `force-app/main/default/permissionsets/Invoice_Portal_User.permissionset-meta.xml` - Portal user permissions

## Decisions Made
- Used Lookup relationships (not Master-Detail) for both Payment__c and Invoice__c on the junction object, per RESEARCH.md anti-patterns guidance -- avoids cascade delete and ownership issues
- Single-record CMDT design with one Default record containing all 7 settings, simpler for demo/POC asset
- Permission set intentionally omits classAccesses -- Apex classes do not exist yet and will be added by Plan 02

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all metadata files are complete with production-ready values.

## Next Phase Readiness
- All metadata XML is ready for Plan 02 (Apex services) which depends on these objects and fields
- Permission set is ready for Plan 02 to add classAccesses for InvoiceService and PaymentService
- CMDT Default record values can be queried by PaymentService.getPortalConfig() in Plan 02

## Self-Check: PASSED

All 14 key files verified present. All 3 task commits verified in git log.

---
*Phase: 01-data-foundation*
*Completed: 2026-03-27*
