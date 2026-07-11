# Importing CSV and Excel-compatible data

## Files included

- `clients.csv`
- `securities.csv`
- `prices.csv`
- `transactions.csv`
- `expected_holdings.csv`

All files are synthetic and encoded as UTF-8 with a header row.

## Recommended import pattern

Do not import an unfamiliar spreadsheet directly into a trusted production table.

Use this sequence:

1. Preserve the original file.
2. Inspect headers, delimiters, quoting, encoding, and date formats.
3. Load into a staging table using permissive text columns.
4. Use `TRY_CONVERT` to identify invalid rows.
5. Check required fields, duplicate business keys, valid reference codes, and ranges.
6. Reject or correct bad rows.
7. Load clean rows into target tables inside a transaction.
8. Reconcile source and target counts and totals.
9. Log who imported the data and when.
10. Archive or securely dispose of the source under policy.

`sql/16_import_csv_examples.sql` demonstrates staging and validation for `clients.csv`. The direct project build uses deterministic SQL insert scripts so it does not depend on a machine-specific path.

## SSMS Import Flat File Wizard

The exact menu labels can vary by SSMS version. The common workflow is:

1. Right-click the target database in Object Explorer.
2. Select **Tasks**.
3. Select **Import Flat File**.
4. Browse to the CSV.
5. Enter a new staging-table name such as `dbo.ClientImportStage`.
6. Review the detected column names and data types.
7. Change overly narrow or incorrect types.
8. Complete the import.
9. Run validation queries before moving rows into target tables.

Prefer a staging table rather than importing directly into `core.Client`.

## Excel guidance

1. Put one field in each column.
2. Use one header row.
3. Remove merged cells, subtotals, blank title rows, and decorative formatting.
4. Store dates in a consistent ISO-style format such as `2026-07-11`.
5. Keep identifiers such as account numbers as text.
6. Avoid formulas in the final exchange file; paste values where appropriate.
7. Choose **Save As**.
8. Select **CSV UTF-8 (Comma delimited)**.
9. Confirm Excel’s warning that only the active sheet is saved.
10. Close and reopen the CSV in a text editor to inspect it.

## Common errors and fixes

### “Cannot bulk load because the file could not be opened”

The file path is resolved by SQL Server. The service account must be able to see and read it. A path accessible only to your desktop session might not work.

### Date conversion failed

Use a staging text column and `TRY_CONVERT(date, value)`. Standardize the source to `YYYY-MM-DD`.

### Numeric conversion failed

Remove currency symbols, thousands separators, spaces, and text such as `N/A`. Decide whether blank means NULL or an error.

### Rows shifted into the wrong columns

A comma may appear inside unquoted text. Re-save as proper CSV with quote handling or clean the source.

### Leading zeros disappeared

Excel treated an identifier as a number. Format it as text before saving.

### Accented names look wrong

Use UTF-8 and specify the correct code page.

### Duplicate-key error

Identify whether the incoming row is a duplicate, an update, or a different record using a controlled business rule. Do not simply remove the constraint.

### Foreign-key error

Load parent reference data first or map the source code to a valid target key.

## Validation examples

```sql
SELECT *
FROM dbo.ClientImportStage
WHERE TRY_CONVERT(date, ClientSinceText) IS NULL;
```

```sql
SELECT ClientCode, COUNT(*) AS RowCount
FROM dbo.ClientImportStage
GROUP BY ClientCode
HAVING COUNT(*) > 1;
```

```sql
SELECT s.*
FROM dbo.ClientImportStage AS s
LEFT JOIN core.Advisor AS a
    ON a.AdvisorID = TRY_CONVERT(int, s.AdvisorIDText)
WHERE a.AdvisorID IS NULL;
```

## Privacy reminder

Real spreadsheet imports can contain PII and financial information. They require approved transfer methods, retention rules, encryption, access controls, and audit evidence. Do not use real client data in this portfolio.
