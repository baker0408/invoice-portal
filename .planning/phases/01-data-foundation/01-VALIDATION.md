---
phase: 1
slug: data-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Apex Test Classes (Salesforce platform) |
| **Config file** | sfdx-project.json |
| **Quick run command** | `sf apex run test --synchronous --test-level RunSpecifiedTests --tests InvoiceServiceTest,PaymentServiceTest` |
| **Full suite command** | `sf apex run test --synchronous --test-level RunLocalTests` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command (specified test classes)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | DATA-01 | deployment | `sf project deploy start --dry-run` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | DATA-02 | deployment | `sf project deploy start --dry-run` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | DATA-03 | deployment | `sf project deploy start --dry-run` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | DATA-04 | unit | `sf apex run test --tests InvoiceServiceTest` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | DATA-04 | unit | `sf apex run test --tests PaymentServiceTest` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `force-app/main/default/classes/InvoiceServiceTest.cls` — test class for InvoiceService
- [ ] `force-app/main/default/classes/PaymentServiceTest.cls` — test class for PaymentService
- [ ] `sfdx-project.json` — SFDX project configuration

*Wave 0 creates test infrastructure alongside the Apex classes they test.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Custom fields visible in org | DATA-01 | Requires deployed org | Deploy to dev org, navigate to Invoice object setup, verify fields exist |
| CMDT records accessible | DATA-03 | Requires deployed org | Deploy to dev org, query Invoice_Portal_Config__mdt in Developer Console |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
