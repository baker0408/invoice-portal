# Phase 1: Data Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-27
**Phase:** 01-data-foundation
**Areas discussed:** SFDX project setup

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| SFDX project setup | Directory structure, API version, namespace, .gitignore conventions | ✓ |
| Apex service design | How InvoiceService and PaymentService are structured | |
| Config approach | Custom Metadata Type design | |
| Permission model | Permission sets, FLS, sharing rules | |

**User's note:** "Do I need to have the custom objects and fields created in advance, or can we use the Salesforce CLI to accomplish this? I have a development org ready to go that is licensed for B2B Commerce and Salesforce Payments"

**Response:** All custom metadata is defined as SFDX source XML in force-app/ and deployed via `sf project deploy start`. No manual creation needed.

---

## SFDX Project Setup

### API Version

| Option | Description | Selected |
|--------|-------------|----------|
| v66.0 (Recommended) | Spring '26 GA — current release | ✓ |
| v65.0 | Winter '26 — one release back | |
| Match my org | User specifies org version | |

**User's choice:** v66.0 (Recommended)

### Namespace

| Option | Description | Selected |
|--------|-------------|----------|
| No namespace (Recommended) | Unmanaged package, simpler deployment | ✓ |
| Use a namespace | Prefix all components | |

**User's choice:** No namespace (Recommended)

### Test Data

| Option | Description | Selected |
|--------|-------------|----------|
| Test factory class | Shared TestDataFactory.cls | |
| Per-test setup | Each test class creates own data | |
| You decide | Claude picks best approach | ✓ |

**User's choice:** You decide (Claude's discretion)

---

## Claude's Discretion

- Test data strategy
- Apex service layer pattern
- Permission set design
- Custom Metadata Type structure

## Deferred Ideas

None
