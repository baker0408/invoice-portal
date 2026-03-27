**Requirements**
Invoice list view for bill-to and sold-to customers
Invoice list view filter and pagination
Invoice PDF download
Invoice list CSV export
Multiple invoice payment, including credit and debit invoices
Debit invoice overpay or short pay with reasons and comments
Credit card payment processing fee
Invoice balance and status update after payments in Salesforce

**Solution**
Customer portal based on B2B Commerce template
Custom LWCs for experience
Invoice list view, invoice payment, payment form and submission
Service request creation, list view and detail
Salesforce Payments Integration:
- Custom PaymentLink generation
- PayNow LWC customization leveraging Salesforce Payments client side SDK for payment form 
- Removing contact info, shipping address
- Updated behavior for saved payment methods and billing address
- Added processing fee and leveraging B2B site to serve PaymentLink instead of a separate site
- Post payment process to trigger invoice updates and payment data capture and export
