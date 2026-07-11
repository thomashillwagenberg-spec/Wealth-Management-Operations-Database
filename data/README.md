# Synthetic data files

These UTF-8 CSV files support import practice and repository review.

| File | Purpose | Rows excluding header |
|---|---|---:|
| `clients.csv` | Fictional clients and assigned advisors | 30 |
| `securities.csv` | Invented securities and classifications | 25 |
| `prices.csv` | Seven synthetic price dates per security | 175 |
| `transactions.csv` | Deposits, purchases, sales, dividends, fees, and withdrawals | 403 |
| `expected_holdings.csv` | Expected current positions used for reconciliation | 300 |

## Important

- Every person, email, account identifier, symbol, price, and amount is fictional.
- The SQL build uses `05_load_reference_data.sql` and `06_load_sample_data.sql` for deterministic loading.
- CSV import practice is documented in `docs/importing-data.md` and `sql/16_import_csv_examples.sql`.
- `expected_holdings.csv` is an external check file, not the authoritative source for portfolio reporting.
- Do not replace these files with real client information.
