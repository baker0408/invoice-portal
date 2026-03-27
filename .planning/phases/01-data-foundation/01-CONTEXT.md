# Phase 1: Data Foundation - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the complete SFDX project scaffold, all custom metadata (objects, fields, Custom Metadata Types), Apex service classes (InvoiceService, PaymentService), permission sets, and test infrastructure. Everything downstream UI phases depend on. No LWC components are built here.

</domain>

<decisions>
## Implementation Decisions

### SFDX Project Setup
- **D-01:** API version v66.0 (Spring '26 GA) — pinned in sfdx-project.json
- **D-02:** No namespace prefix — unmanaged package, simpler deployment and API names
- **D-03:** All custom objects, fields, and metadata defined as SFDX source XML in force-app/ — deployed to org via `sf project deploy start`, no manual creation needed
- **D-04:** User has a development org ready with B2B Commerce and Salesforce Payments licensed and enabled

### Deployment Approach
- **D-05:** Source-driven development — all metadata lives in the SFDX project and is deployed to the dev org via CLI
- **D-06:** Standard SFDX project structure with force-app/main/default/ as the primary source path

### Claude's Discretion
- Test data strategy: Claude will choose the best approach (likely a shared TestDataFactory.cls for consistency across test classes)
- Apex service layer pattern: Claude will determine whether to use a single controller pattern or service layer separation
- Permission set design: Claude will determine the appropriate permission model for custom fields and objects
- Custom Metadata Type structure: Claude will decide between single-record vs multi-record CMDT design

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### PRD and Data Model
- `docs/invoice-portal-prd.md` — Complete PRD with data model (Section 7), component architecture (Section 9), configuration settings (Section 10), and error handling (Section 11)
- `docs/invoice-portal-prd.md` Section 7.1-7.4 — Standard objects used, custom fields on Invoice, Invoice_Payment_Line__c junction object, status mapping

### Payments SDK
- `docs/payments-sdk.md` — Salesforce Payments Client Side SDK v7.0.0 full API reference

### Research
- `.planning/research/STACK.md` — Technology stack with versions and rationale
- `.planning/research/ARCHITECTURE.md` — Component boundaries, data flows, build order
- `.planning/research/PITFALLS.md` — Domain pitfalls with prevention strategies

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None — patterns will be established in this phase

### Integration Points
- Standard Invoice object (API v48.0+) — custom fields added to this object
- Standard Payment and PaymentLineItem objects — used in post-payment processing (Phase 5)
- B2B Commerce LWR site — LWC components will be added in Phases 2-4

</code_context>

<specifics>
## Specific Ideas

- User's dev org already has B2B Commerce and Salesforce Payments licensed — no org setup needed
- Everything deploys via Salesforce CLI (`sf project deploy start`) — no manual object creation
- Unmanaged package target — no namespace constraints on API names

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-data-foundation*
*Context gathered: 2026-03-27*
