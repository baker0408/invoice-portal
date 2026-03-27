# Phase 1: Data Foundation - Research

**Researched:** 2026-03-27
**Domain:** Salesforce SFDX metadata (custom objects, fields, Custom Metadata Types, Apex controllers, permission sets)
**Confidence:** HIGH

## Summary

Phase 1 establishes the complete SFDX project scaffold and deploys all metadata that downstream phases depend on: custom fields on the standard Invoice object, the Invoice_Payment_Line__c custom junction object, the Invoice_Portal_Config__mdt Custom Metadata Type with default records, two Apex service controllers (InvoiceService and PaymentService), a shared TestDataFactory, permission sets, and test classes achieving 75%+ code coverage.

This is a greenfield phase with no existing code. All deliverables are SFDX source XML files and Apex classes written from scratch. The standard Invoice object is provided by Order Management (confirmed available in the dev org). Custom fields are added to the standard object via the `objects/Invoice/fields/` directory -- no custom Invoice object is created. The only custom object is Invoice_Payment_Line__c.

**Primary recommendation:** Build metadata XML files first (objects, fields, CMDT), then Apex service stubs with account-scoped security, then test classes -- in that order. Deploy incrementally via `sf project deploy start` to validate XML correctness early rather than discovering format errors late.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** API version v66.0 (Spring '26 GA) -- pinned in sfdx-project.json
- **D-02:** No namespace prefix -- unmanaged package, simpler deployment and API names
- **D-03:** All custom objects, fields, and metadata defined as SFDX source XML in force-app/ -- deployed to org via `sf project deploy start`, no manual creation needed
- **D-04:** User has a development org ready with B2B Commerce and Salesforce Payments licensed and enabled
- **D-05:** Source-driven development -- all metadata lives in the SFDX project and is deployed to the dev org via CLI
- **D-06:** Standard SFDX project structure with force-app/main/default/ as the primary source path

### Claude's Discretion
- Test data strategy: Claude will choose the best approach (likely a shared TestDataFactory.cls for consistency across test classes)
- Apex service layer pattern: Claude will determine whether to use a single controller pattern or service layer separation
- Permission set design: Claude will determine the appropriate permission model for custom fields and objects
- Custom Metadata Type structure: Claude will decide between single-record vs multi-record CMDT design

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Custom fields on Invoice: PO_Number__c, Portal_Status__c, Sold_To_Account__c | SFDX source format XML for custom fields on standard objects; field type definitions; picklist value sets |
| DATA-02 | Invoice_Payment_Line__c junction object with Payment__c, Invoice__c, Payment_Amount__c, Short_Pay_Reason__c, Comments__c, Processing_Fee__c | Custom object XML definition; lookup relationship fields; currency and picklist field types |
| DATA-03 | Custom Metadata for configurable settings (processing fee %, ACH/CC toggle, page size, short pay reasons, PaymentLink TTL) | Invoice_Portal_Config__mdt type definition; CMDT field types; default record XML |
| DATA-04 | All Apex queries enforce account scoping via BillingAccountId and Sold_To_Account__c | Apex controller patterns with `with sharing`; SOQL with WHERE clause filtering; security enforcement patterns |
</phase_requirements>

## Standard Stack

### Core (This Phase Only)

| Library/Technology | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Salesforce Platform (Apex) | API v66.0 | Apex controllers and test classes | Locked decision D-01; current GA release |
| SFDX Source Format | v66.0 | Metadata XML definitions | Locked decision D-03/D-05/D-06 |
| Salesforce CLI (`sf`) | v2.99.6 | Deployment and retrieval | Installed and verified on dev machine |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `sf project deploy start` | v2.99.6 | Deploy metadata to dev org | After each metadata file is created, to validate XML |
| `sf project generate` | v2.99.6 | Scaffold SFDX project | One-time project initialization |
| `sf apex run test` | v2.99.6 | Run Apex test classes | After test class creation to validate coverage |

**No npm packages needed for this phase.** LWC testing dependencies are not required until Phase 2+.

## Architecture Patterns

### Project Structure (Phase 1 Deliverables)

```
invoice-portal/
  sfdx-project.json                          # API v66.0, no namespace
  force-app/
    main/
      default/
        objects/
          Invoice/                            # Standard object -- custom fields only
            fields/
              PO_Number__c.field-meta.xml
              Portal_Status__c.field-meta.xml
              Sold_To_Account__c.field-meta.xml
          Invoice_Payment_Line__c/            # Custom junction object
            Invoice_Payment_Line__c.object-meta.xml
            fields/
              Payment__c.field-meta.xml
              Invoice__c.field-meta.xml
              Payment_Amount__c.field-meta.xml
              Short_Pay_Reason__c.field-meta.xml
              Comments__c.field-meta.xml
              Processing_Fee__c.field-meta.xml
        customMetadata/
          Invoice_Portal_Config.Default.md-meta.xml
        objects/
          Invoice_Portal_Config__mdt/         # CMDT type definition
            Invoice_Portal_Config__mdt.object-meta.xml
            fields/
              Processing_Fee_Percent__c.field-meta.xml
              Processing_Fee_Enabled__c.field-meta.xml
              ACH_Enabled__c.field-meta.xml
              Credit_Card_Enabled__c.field-meta.xml
              Invoices_Per_Page__c.field-meta.xml
              PaymentLink_TTL_Hours__c.field-meta.xml
              Short_Pay_Reasons__c.field-meta.xml
        classes/
          InvoiceService.cls
          InvoiceService.cls-meta.xml
          InvoiceServiceTest.cls
          InvoiceServiceTest.cls-meta.xml
          PaymentService.cls
          PaymentService.cls-meta.xml
          PaymentServiceTest.cls
          PaymentServiceTest.cls-meta.xml
          TestDataFactory.cls
          TestDataFactory.cls-meta.xml
        permissionsets/
          Invoice_Portal_User.permissionset-meta.xml
```

### Pattern 1: Custom Fields on Standard Objects (SFDX Source)

**What:** Custom fields on the standard Invoice object are defined as individual XML files in `objects/Invoice/fields/`. No object-meta.xml is needed for the standard Invoice object itself -- only the fields directory.

**When to use:** Adding custom fields to any standard Salesforce object.

**Example -- Text field (PO_Number__c):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>PO_Number__c</fullName>
    <label>PO Number</label>
    <type>Text</type>
    <length>50</length>
    <required>false</required>
    <externalId>false</externalId>
    <trackHistory>false</trackHistory>
    <description>Customer purchase order reference number</description>
</CustomField>
```

**Example -- Picklist field (Portal_Status__c):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Portal_Status__c</fullName>
    <label>Portal Status</label>
    <type>Picklist</type>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <description>Portal-specific status overlay for invoice display</description>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>Open</fullName>
                <default>true</default>
                <label>Open</label>
            </value>
            <value>
                <fullName>In Progress</fullName>
                <default>false</default>
                <label>In Progress</label>
            </value>
            <value>
                <fullName>Paid</fullName>
                <default>false</default>
                <label>Paid</label>
            </value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

**Example -- Lookup field (Sold_To_Account__c):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Sold_To_Account__c</fullName>
    <label>Sold To Account</label>
    <type>Lookup</type>
    <referenceTo>Account</referenceTo>
    <relationshipName>SoldToInvoices</relationshipName>
    <relationshipLabel>Sold To Invoices</relationshipLabel>
    <required>false</required>
    <deleteConstraint>SetNull</deleteConstraint>
    <description>Sold-to account when different from bill-to (BillingAccountId)</description>
</CustomField>
```

**Confidence:** HIGH -- standard SFDX source format documented in Metadata API Developer Guide.

### Pattern 2: Custom Object Definition (Invoice_Payment_Line__c)

**What:** The custom junction object requires an object-meta.xml defining the object itself, plus individual field XML files in the fields/ directory.

**Example -- Object definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Invoice Payment Line</label>
    <pluralLabel>Invoice Payment Lines</pluralLabel>
    <nameField>
        <label>Invoice Payment Line Name</label>
        <type>AutoNumber</type>
        <displayFormat>IPL-{0000}</displayFormat>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableActivities>false</enableActivities>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableHistory>false</enableHistory>
    <description>Junction object linking a Payment to individual Invoices with payment-specific metadata (reason codes, comments, processing fee allocation)</description>
</CustomObject>
```

**Example -- Lookup to Payment (Payment__c):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Payment__c</fullName>
    <label>Payment</label>
    <type>Lookup</type>
    <referenceTo>Payment</referenceTo>
    <relationshipName>InvoicePaymentLines</relationshipName>
    <relationshipLabel>Invoice Payment Lines</relationshipLabel>
    <required>true</required>
    <deleteConstraint>Restrict</deleteConstraint>
    <description>Parent payment record (standard Payment object)</description>
</CustomField>
```

**Example -- Currency field (Payment_Amount__c):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Payment_Amount__c</fullName>
    <label>Payment Amount</label>
    <type>Currency</type>
    <precision>18</precision>
    <scale>2</scale>
    <required>true</required>
    <description>Amount applied to this invoice from this payment</description>
</CustomField>
```

**Confidence:** HIGH -- standard SFDX metadata patterns.

### Pattern 3: Custom Metadata Type (Invoice_Portal_Config__mdt)

**What:** CMDT type defined as an object in `objects/Invoice_Portal_Config__mdt/`, with fields in its fields/ subdirectory. Default record defined in `customMetadata/`.

**Design decision (Claude's Discretion):** Use a single-record design with one "Default" record containing all settings. This is simpler for a demo asset where per-org customization is the expected usage pattern. Multi-record design (one record per setting) adds query complexity without benefit for 7 settings.

**Example -- CMDT record (Default):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Default</label>
    <protected>false</protected>
    <values>
        <field>Processing_Fee_Percent__c</field>
        <value xsi:type="xsd:double">2.9</value>
    </values>
    <values>
        <field>Processing_Fee_Enabled__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>ACH_Enabled__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Credit_Card_Enabled__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Invoices_Per_Page__c</field>
        <value xsi:type="xsd:double">20</value>
    </values>
    <values>
        <field>PaymentLink_TTL_Hours__c</field>
        <value xsi:type="xsd:double">72</value>
    </values>
    <values>
        <field>Short_Pay_Reasons__c</field>
        <value xsi:type="xsd:string">Sales Tax;Freight;Damaged;Pricing;Other</value>
    </values>
</CustomMetadata>
```

**Confidence:** HIGH -- CMDT XML format is well-documented and stable.

### Pattern 4: Account-Scoped Apex Service (InvoiceService)

**What:** Apex controller with `with sharing` enforcement, `@AuraEnabled(cacheable=true)` for read methods, account scoping via BillingAccountId and Sold_To_Account__c in all SOQL WHERE clauses.

**Design decision (Claude's Discretion):** Use a single controller pattern (not service layer separation). For a demo/POC with 2 controllers, adding a separate service layer adds files without adding value. The controllers ARE the service layer. Rename from "InvoiceController" to "InvoiceService" per PRD convention to indicate they contain business logic, not just wire-to-Apex mapping.

**Example -- InvoiceService.cls:**
```apex
public with sharing class InvoiceService {

    @AuraEnabled(cacheable=true)
    public static InvoiceListResult getInvoices(
        String tab,
        String dateFrom,
        String dateTo,
        Integer pageNumber,
        Integer pageSize
    ) {
        Id accountId = getAccountIdForCurrentUser();
        if (accountId == null) {
            throw new AuraHandledException('Unable to determine account context');
        }

        Integer offset = (pageNumber - 1) * pageSize;
        String baseCondition = '(BillingAccountId = :accountId OR Sold_To_Account__c = :accountId)';

        // Tab-specific WHERE clause additions
        String tabFilter = '';
        if (tab == 'open') {
            tabFilter = ' AND Balance > 0 AND Status = \'Posted\'';
        } else if (tab == 'paid') {
            tabFilter = ' AND (Status = \'Paid\' OR Balance = 0)';
        } else if (tab == 'priorYear') {
            Integer priorYear = Date.today().year() - 1;
            Date priorYearStart = Date.newInstance(priorYear, 1, 1);
            Date priorYearEnd = Date.newInstance(priorYear, 12, 31);
            tabFilter = ' AND InvoiceDate >= :priorYearStart AND InvoiceDate <= :priorYearEnd';
        }

        // Query with SECURITY_ENFORCED for FLS
        String query = 'SELECT Id, DocumentNumber, InvoiceDate, DueDate, '
            + 'TotalAmountWithTax, Balance, Status, PO_Number__c, Portal_Status__c '
            + 'FROM Invoice '
            + 'WHERE ' + baseCondition
            + ' AND Status NOT IN (\'Canceled\', \'Error\')'
            + tabFilter
            + ' WITH SECURITY_ENFORCED'
            + ' ORDER BY InvoiceDate DESC'
            + ' LIMIT :pageSize OFFSET :offset';

        List<Invoice> invoices = Database.query(query);

        // Count query for pagination
        String countQuery = 'SELECT COUNT() FROM Invoice '
            + 'WHERE ' + baseCondition
            + ' AND Status NOT IN (\'Canceled\', \'Error\')'
            + tabFilter
            + ' WITH SECURITY_ENFORCED';

        Integer totalCount = Database.countQuery(countQuery);

        InvoiceListResult result = new InvoiceListResult();
        result.invoices = invoices;
        result.totalCount = totalCount;
        result.pageNumber = pageNumber;
        result.pageSize = pageSize;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Invoice> getInvoicesByIds(List<Id> invoiceIds) {
        Id accountId = getAccountIdForCurrentUser();
        return [
            SELECT Id, DocumentNumber, InvoiceDate, DueDate,
                TotalAmountWithTax, Balance, Status, PO_Number__c, Portal_Status__c
            FROM Invoice
            WHERE Id IN :invoiceIds
                AND (BillingAccountId = :accountId OR Sold_To_Account__c = :accountId)
            WITH SECURITY_ENFORCED
        ];
    }

    private static Id getAccountIdForCurrentUser() {
        List<User> users = [
            SELECT ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            AND ContactId != null
            LIMIT 1
        ];
        if (users.isEmpty() || users[0].Contact.AccountId == null) {
            return null;
        }
        return users[0].Contact.AccountId;
    }

    public class InvoiceListResult {
        @AuraEnabled public List<Invoice> invoices;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
    }
}
```

**Confidence:** HIGH -- standard Apex patterns for B2B Commerce portal controllers.

### Pattern 5: PaymentService Stub

**What:** PaymentService as a stub in Phase 1 -- method signatures defined, account-scoped security enforced, but payment processing logic deferred to Phase 5. Test classes validate the security and stub behavior.

**Example -- PaymentService.cls (stub):**
```apex
public with sharing class PaymentService {

    @AuraEnabled
    public static Invoice_Portal_Config__mdt getPortalConfig() {
        return [
            SELECT Processing_Fee_Percent__c, Processing_Fee_Enabled__c,
                ACH_Enabled__c, Credit_Card_Enabled__c, Invoices_Per_Page__c,
                PaymentLink_TTL_Hours__c, Short_Pay_Reasons__c
            FROM Invoice_Portal_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Decimal calculateProcessingFee(Decimal paymentTotal, String paymentMethod) {
        if (paymentMethod != 'CreditCard') {
            return 0;
        }
        Invoice_Portal_Config__mdt config = getPortalConfig();
        if (!config.Processing_Fee_Enabled__c) {
            return 0;
        }
        return (paymentTotal * config.Processing_Fee_Percent__c / 100).setScale(2, RoundingMode.HALF_UP);
    }

    @AuraEnabled
    public static void processPayment(String paymentPayloadJson) {
        // Stub -- full implementation in Phase 5
        // Security check: verify all invoices belong to current user's account
        Id accountId = getAccountIdForCurrentUser();
        if (accountId == null) {
            throw new AuraHandledException('Unable to determine account context');
        }
        // Phase 5 will: create Payment, PaymentLineItem, Invoice_Payment_Line__c records
        // and update Portal_Status__c
    }

    private static Id getAccountIdForCurrentUser() {
        List<User> users = [
            SELECT ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            AND ContactId != null
            LIMIT 1
        ];
        if (users.isEmpty() || users[0].Contact.AccountId == null) {
            return null;
        }
        return users[0].Contact.AccountId;
    }
}
```

**Confidence:** HIGH.

### Pattern 6: Permission Set Design

**Design decision (Claude's Discretion):** Create a single permission set `Invoice_Portal_User` that grants:
- Read/Edit on Invoice custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c)
- CRUD on Invoice_Payment_Line__c and all its fields
- Read on Invoice_Portal_Config__mdt
- Apex class access for InvoiceService and PaymentService

A separate Admin permission set is not needed for Phase 1 -- admins use the System Administrator profile. If needed later, it can be added.

**Example -- Permission set XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Invoice Portal User</label>
    <description>Grants access to Invoice Portal custom fields, objects, and Apex classes</description>
    <hasActivationRequired>false</hasActivationRequired>
    <license>Salesforce</license>

    <!-- Custom fields on Invoice (standard object) -->
    <fieldPermissions>
        <field>Invoice.PO_Number__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice.Portal_Status__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice.Sold_To_Account__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Invoice_Payment_Line__c object -->
    <objectPermissions>
        <object>Invoice_Payment_Line__c</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Payment__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Invoice__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Payment_Amount__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Short_Pay_Reason__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Comments__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Invoice_Payment_Line__c.Processing_Fee__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Apex class access -->
    <classAccesses>
        <apexClass>InvoiceService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>PaymentService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

**Confidence:** HIGH.

### Pattern 7: TestDataFactory and Test Classes

**Design decision (Claude's Discretion):** Use a shared `TestDataFactory.cls` with `@IsTest` annotation that creates Account, Contact, User (portal user), Invoice, and Invoice_Payment_Line__c records. Test classes use `@TestSetup` to call TestDataFactory methods once per class.

**Key testing patterns for this phase:**
- Test classes MUST create their own data -- `SeeAllData=false` (default)
- Invoice records require a valid BillingAccountId -- create Account first
- Portal user context requires Contact on Account + Community User profile/permission set
- Use `System.runAs()` to test sharing enforcement
- CMDT records are accessible in test context without explicit creation (they deploy with the package)

**Example -- TestDataFactory.cls skeleton:**
```apex
@IsTest
public class TestDataFactory {

    public static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    public static List<Invoice> createInvoices(Id accountId, Integer count) {
        List<Invoice> invoices = new List<Invoice>();
        for (Integer i = 0; i < count; i++) {
            invoices.add(new Invoice(
                BillingAccountId = accountId,
                Status = 'Posted',
                InvoiceDate = Date.today().addDays(-i),
                DueDate = Date.today().addDays(30 - i)
            ));
        }
        insert invoices;
        return invoices;
    }

    public static Invoice_Payment_Line__c createPaymentLine(
        Id paymentId, Id invoiceId, Decimal amount
    ) {
        Invoice_Payment_Line__c line = new Invoice_Payment_Line__c(
            Payment__c = paymentId,
            Invoice__c = invoiceId,
            Payment_Amount__c = amount
        );
        insert line;
        return line;
    }
}
```

**Confidence:** HIGH for the pattern. MEDIUM for Invoice DML in test context -- the standard Invoice object may require specific field values or related records (like an Account with billing info) to insert successfully. This must be validated by deploying and running tests in the dev org.

### Anti-Patterns to Avoid

- **Master-Detail instead of Lookup on junction object:** Invoice_Payment_Line__c uses Lookup relationships (not Master-Detail) to both Payment and Invoice. Master-Detail would cascade deletes and change the sharing model in unwanted ways. Lookups with `deleteConstraint="Restrict"` prevent orphaned records while keeping the sharing model flexible.
- **Hardcoded config values:** Never hardcode processing fee percentage, page size, or short pay reasons in Apex. Always read from Invoice_Portal_Config__mdt.
- **Missing account scoping in ANY query:** Every single SOQL query that touches Invoice data must include the BillingAccountId/Sold_To_Account__c WHERE clause. No exceptions.
- **Global value sets for picklists:** Do not use GlobalValueSet for Portal_Status__c or Short_Pay_Reason__c. Inline value sets (defined in the field XML) are simpler for an unmanaged package and avoid cross-dependency issues during deployment.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Invoice balance tracking | Custom balance calculation trigger | Standard Invoice.Balance field | Auto-calculated by platform from PaymentLineItem records |
| Configuration storage | Custom Settings or Apex constants | Invoice_Portal_Config__mdt | Deploys with package, queryable without SOQL limits, admin-editable |
| Field-level security | Manual FLS checking per field | `WITH SECURITY_ENFORCED` in SOQL | Platform-enforced, throws exception on access violation |
| Test data patterns | Ad-hoc record creation in each test | TestDataFactory shared class | Consistent test data, single point of change, reduces test class size |
| AutoNumber naming | Custom sequence logic | AutoNumber nameField on Invoice_Payment_Line__c | Platform-managed, unique, no collision risk |

## Common Pitfalls

### Pitfall 1: Invoice Object Requires Order Management
**What goes wrong:** The standard Invoice object is only available when Order Management is enabled. Deploying custom fields to Invoice in an org without OM fails with "sObject type 'Invoice' is not supported."
**Why it happens:** Invoice is not a universally available standard object like Account or Contact.
**How to avoid:** Confirmed in CONTEXT.md D-04 that the dev org has Order Management. But add a comment in the SFDX project README noting this prerequisite.
**Warning signs:** Deploy fails with entity type errors on Invoice-related metadata.

### Pitfall 2: CMDT Records Not Writable in Apex Tests
**What goes wrong:** Custom Metadata Type records cannot be created via DML in Apex test methods. Attempting `insert new Invoice_Portal_Config__mdt(...)` throws an exception.
**Why it happens:** CMDT records are metadata, not data. They are read-only in Apex.
**How to avoid:** CMDT records deployed as part of the SFDX package ARE accessible in test context. The Default record defined in `customMetadata/Invoice_Portal_Config.Default.md-meta.xml` will be available to test classes automatically. Do NOT attempt to create CMDT records in TestDataFactory.
**Warning signs:** DmlException on CMDT insert in test class.

### Pitfall 3: Invoice DML in Test Context
**What goes wrong:** Creating Invoice records in test methods may fail if required standard fields are missing or if the org requires specific related records (like a BillingAccount with certain fields populated).
**Why it happens:** The Invoice object has platform-enforced requirements that vary by org configuration and OM setup.
**How to avoid:** Create a complete object graph in TestDataFactory: Account (with BillingAddress) -> Invoice (with BillingAccountId, Status, InvoiceDate, DueDate). Test the factory early by deploying and running a minimal test. If Invoice insert fails, check required fields in the org's Object Manager.
**Warning signs:** DmlException or REQUIRED_FIELD_MISSING when inserting Invoice in test context.

### Pitfall 4: Lookup Field deleteConstraint Must Match Object Availability
**What goes wrong:** `deleteConstraint="Restrict"` on a lookup to the standard Payment object may cause deployment issues if the Payment object has specific sharing or deletion rules.
**Why it happens:** Standard Payment object behavior varies by org configuration.
**How to avoid:** Use `deleteConstraint="Restrict"` for Payment__c and `deleteConstraint="SetNull"` for Invoice__c on the junction object. This prevents orphaned lines when a payment exists but allows cleanup if an invoice is deleted (rare in production but possible in dev/demo).
**Warning signs:** Deployment error mentioning deleteConstraint incompatibility.

### Pitfall 5: SFDX Source Format Path for Standard Object Custom Fields
**What goes wrong:** Putting custom field XML files in `objects/Invoice__c/fields/` instead of `objects/Invoice/fields/`. The standard Invoice object API name is `Invoice` (no `__c` suffix).
**Why it happens:** Developer habit of adding `__c` to all object names.
**How to avoid:** Use the exact API name: `objects/Invoice/fields/PO_Number__c.field-meta.xml`. No object-meta.xml file is needed for the standard Invoice object.
**Warning signs:** Deploy error saying the object doesn't exist, or fields created on a new custom object instead of the standard Invoice.

## Code Examples

All code examples are provided inline in the Architecture Patterns section above. Key files:
- Pattern 1: Custom field XML (3 examples covering Text, Picklist, Lookup)
- Pattern 2: Custom object XML + field XML (Currency, Lookup)
- Pattern 3: CMDT record XML
- Pattern 4: InvoiceService.cls (full implementation)
- Pattern 5: PaymentService.cls (stub)
- Pattern 6: Permission set XML
- Pattern 7: TestDataFactory.cls (skeleton)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `sfdx` v7 CLI commands | `sf` v2 CLI commands | 2023 | All deploy/retrieve uses `sf project deploy start`, not `sfdx force:source:push` |
| Custom Settings for config | Custom Metadata Types | 2017+ | CMDT deploys with packages; Custom Settings do not |
| Profile-based FLS | Permission Set-based FLS | 2020+ | Permission sets are the recommended approach for field access |
| Dynamic SOQL without binding | Parameterized binding in dynamic SOQL | Always | Prevents SOQL injection; use `:variable` syntax |

## Open Questions

1. **Invoice DML in test context -- required fields**
   - What we know: Invoice requires BillingAccountId at minimum. Status and dates are likely required.
   - What's unclear: Whether additional fields (like TotalAmount or CurrencyIsoCode) are required for insert in the specific dev org.
   - Recommendation: Create a minimal Invoice insert test first. If it fails, inspect the org's Invoice object for required field configuration and adjust TestDataFactory.

2. **Payment object availability for junction object lookup**
   - What we know: The standard Payment object should be available with Salesforce Payments enabled.
   - What's unclear: Whether the lookup from Invoice_Payment_Line__c to Payment will deploy without a Payment record existing.
   - Recommendation: Deploy the junction object early. Lookup fields to standard objects should deploy fine regardless of record existence. If issues arise, the lookup can reference the object API name and Salesforce resolves it at deploy time.

3. **CMDT naming convention: file name format**
   - What we know: CMDT record files follow the pattern `{TypeDeveloperName}.{RecordDeveloperName}.md-meta.xml`.
   - What's unclear: Whether the exact file name is `Invoice_Portal_Config.Default.md-meta.xml` or `Invoice_Portal_Config__mdt.Default.md-meta.xml`.
   - Recommendation: Use `Invoice_Portal_Config.Default.md-meta.xml` (without `__mdt` in the filename). The `__mdt` suffix is part of the object API name but CMDT record filenames drop it. Validate by deploying early.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Salesforce CLI (`sf`) | All deploys | Yes | v2.99.6 | -- |
| Node.js | SF CLI runtime | Yes | v22.18.0 | -- |
| npm | Package management | Yes | v10.9.3 | -- |
| Dev org with Order Management | Invoice object | Yes (per D-04) | -- | -- |
| Dev org with Salesforce Payments | Payment object | Yes (per D-04) | -- | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Apex Test Classes (platform-native) |
| Config file | None needed -- Apex tests run on the platform |
| Quick run command | `sf apex run test --test-level RunLocalTests --target-org dev-org -w 10` |
| Full suite command | `sf apex run test --test-level RunLocalTests --target-org dev-org -w 10 --code-coverage` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Custom fields (PO_Number__c, Portal_Status__c, Sold_To_Account__c) exist on Invoice and are accessible via SOQL | unit | `sf apex run test --tests InvoiceServiceTest --target-org dev-org -w 10` | Wave 0 |
| DATA-02 | Invoice_Payment_Line__c exists with all fields and is queryable | unit | `sf apex run test --tests PaymentServiceTest --target-org dev-org -w 10` | Wave 0 |
| DATA-03 | Invoice_Portal_Config__mdt records exist with configurable settings | unit | `sf apex run test --tests PaymentServiceTest.testGetPortalConfig --target-org dev-org -w 10` | Wave 0 |
| DATA-04 | InvoiceService returns account-scoped invoice data | unit | `sf apex run test --tests InvoiceServiceTest --target-org dev-org -w 10` | Wave 0 |
| DATA-04 | PaymentService stub exists with account-scoped security | unit | `sf apex run test --tests PaymentServiceTest --target-org dev-org -w 10` | Wave 0 |

### Sampling Rate
- **Per task commit:** Deploy to org and run `sf apex run test --test-level RunLocalTests --target-org dev-org -w 10`
- **Per wave merge:** Full test suite with coverage: `sf apex run test --test-level RunLocalTests --target-org dev-org -w 10 --code-coverage`
- **Phase gate:** All tests pass with 75%+ code coverage per class

### Wave 0 Gaps
- [ ] `InvoiceServiceTest.cls` -- covers DATA-01, DATA-04
- [ ] `PaymentServiceTest.cls` -- covers DATA-02, DATA-03, DATA-04
- [ ] `TestDataFactory.cls` -- shared test data creation

## Project Constraints (from CLAUDE.md)

- **Platform**: Salesforce B2B Commerce (LWR) -- all UI is LWC, all backend is Apex
- **Data Model**: Standard Invoice, InvoiceLine, Payment, PaymentLineItem objects -- minimal custom field additions only
- **Packaging**: Unmanaged package -- must be deployable without managed package dependencies
- **Project Structure**: SFDX project format (force-app/)
- **Security**: Invoice visibility scoped to logged-in user's account
- **GSD Workflow**: Do not make direct repo edits outside a GSD workflow unless user explicitly asks

## Sources

### Primary (HIGH confidence)
- `docs/invoice-portal-prd.md` -- Section 7 (Data Model), Section 9 (Component Architecture), Section 10 (Configuration)
- `.planning/research/STACK.md` -- Full technology stack with versions and rationale
- `.planning/research/ARCHITECTURE.md` -- Component boundaries, data flows, build order
- `.planning/research/PITFALLS.md` -- Domain pitfalls with prevention strategies
- `.planning/phases/01-data-foundation/01-CONTEXT.md` -- User decisions and discretion areas
- [Salesforce DX Project Structure and Source Format](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_source_file_format.htm)
- [CustomField Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/customfield.htm)
- [Custom Metadata Types Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_custommetadatatypes.htm)
- [PermissionSet Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionset.htm)

### Secondary (MEDIUM confidence)
- [Salesforce CLI Custom Metadata Plugin](https://github.com/salesforcecli/plugin-custom-metadata/) -- CMDT record file naming patterns
- [Decomposed Metadata Types](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_decomposed_md_types.htm) -- SFDX decomposition rules

### Tertiary (LOW confidence)
- CMDT record filename convention (with vs without `__mdt` suffix) -- needs deployment validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- fully constrained by platform and locked decisions
- Architecture: HIGH -- SFDX source format is well-documented; Apex patterns are standard
- Pitfalls: HIGH -- all pitfalls identified from prior research and platform knowledge
- CMDT file naming: MEDIUM -- format is standard but exact naming needs deployment validation

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable platform patterns, 30-day validity)
