# Data-classification register

All packaged data is fictional. The classification reflects how equivalent real records would be treated.

| Data element | Example fields | Classification | Proposed handling |
|---|---|---|---|
| Identity and contact | Client name, email | Confidential | RLS, curated views, classification metadata, optional encryption |
| Account identifiers | Account number | Highly confidential | Masking as supplemental control, no raw reporting access |
| Portfolio and holdings | quantity, cost, value | Highly confidential | Least privilege, encrypted transport/storage, audited access |
| Transactions | type, amount, dates, reference | Highly confidential | Immutable posted records, idempotency, audit |
| Risk profile | score, objective, horizon | Highly confidential | Temporal history, access restrictions |
| Compliance | reviews, alerts, notes | Highly confidential | Role restrictions, concurrency, temporal history, audit |
| Authentication data | token, secret, key | Restricted | Never persisted in business logs or repository |

Classification, retention, and lawful basis require organizational privacy and legal owners.
