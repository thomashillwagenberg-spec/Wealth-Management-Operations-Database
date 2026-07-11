#!/usr/bin/env python3
"""Static consistency checks for the Wealth Management Operations Database.

This tool does not execute T-SQL and cannot replace SQL Server validation.
It checks repository completeness, CSV structure/counts, key relationships,
required concept coverage, and basic lexical integrity of SQL files.
"""

from __future__ import annotations

import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED_FILES = [
    "README.md", "LICENSE", ".gitignore", "project-manifest.json",
    "docs/project-overview.md", "docs/setup-guide.md",
    "docs/database-design.md", "docs/data-dictionary.md",
    "docs/security-design.md", "docs/backup-and-restore.md",
    "docs/azure-deployment-guide.md", "docs/testing-checklist.md",
    "docs/linkedin-launch-package.md", "docs/learning-modules.md",
    "docs/importing-data.md", "docs/source-verification.md",
    "sql/00_reset_database.sql", "sql/01_create_database.sql",
    "sql/02_create_schemas.sql", "sql/03_create_tables.sql",
    "sql/04_create_constraints.sql", "sql/05_load_reference_data.sql",
    "sql/06_load_sample_data.sql", "sql/07_create_views.sql",
    "sql/08_create_functions.sql", "sql/09_create_procedures.sql",
    "sql/10_create_indexes.sql", "sql/11_security_setup.sql",
    "sql/12_analysis_queries.sql", "sql/13_validation_tests.sql",
    "sql/14_backup_restore_examples.sql", "sql/15_master_demo.sql",
    "sql/16_import_csv_examples.sql", "sql/run_all.sql",
    "data/clients.csv", "data/securities.csv", "data/prices.csv",
    "data/transactions.csv", "data/expected_holdings.csv",
    "screenshots/screenshot-capture-guide.md",
]

EXPECTED_CSV_COUNTS = {
    "clients.csv": 30,
    "securities.csv": 25,
    "prices.csv": 175,
    "transactions.csv": 403,
    "expected_holdings.csv": 300,
}

EXPECTED_HEADERS = {
    "clients.csv": [
        "ClientID", "ClientCode", "FirstName", "LastName", "Email",
        "StateCode", "AdvisorID", "ClientSince", "IsActive"
    ],
    "securities.csv": [
        "SecurityID", "Symbol", "SecurityName", "AssetClassID",
        "SecurityType", "CurrencyCode", "IsActive"
    ],
    "prices.csv": [
        "SecurityPriceID", "SecurityID", "PriceDate", "ClosePrice", "PriceSource"
    ],
    "transactions.csv": [
        "TransactionID", "AccountID", "TransactionTypeID", "SecurityID",
        "TradeDate", "SettlementDate", "Quantity", "Price", "GrossAmount",
        "FeeAmount", "ExternalReference", "Notes"
    ],
    "expected_holdings.csv": [
        "CurrentHoldingID", "AccountID", "SecurityID", "Quantity", "AverageCost"
    ],
}

REQUIRED_SQL_PATTERNS = {
    "CREATE DATABASE": r"\bCREATE\s+DATABASE\b",
    "CREATE SCHEMA": r"\bCREATE\s+SCHEMA\b",
    "CREATE TABLE": r"\bCREATE\s+TABLE\b",
    "ALTER TABLE": r"\bALTER\s+TABLE\b",
    "INSERT": r"\bINSERT\s+INTO\b",
    "UPDATE": r"\bUPDATE\b",
    "DELETE": r"\bDELETE\s+FROM\b",
    "SELECT": r"\bSELECT\b",
    "WHERE": r"\bWHERE\b",
    "ORDER BY": r"\bORDER\s+BY\b",
    "GROUP BY": r"\bGROUP\s+BY\b",
    "HAVING": r"\bHAVING\b",
    "INNER JOIN": r"\bINNER\s+JOIN\b",
    "LEFT JOIN": r"\bLEFT\s+JOIN\b",
    "CASE": r"\bCASE\b",
    "Aggregate function": r"\b(SUM|COUNT|AVG|MIN|MAX)\s*\(",
    "Date function": r"\b(DATEADD|DATEDIFF|DATEFROMPARTS|YEAR|MONTH)\s*\(",
    "String function": r"\b(CONCAT|UPPER|LOWER|LTRIM|RTRIM|SUBSTRING)\s*\(",
    "Subquery": r"\(\s*SELECT\b",
    "CTE": r"\bWITH\s+[A-Za-z_][A-Za-z0-9_]*\s+AS\s*\(",
    "Window function": r"\bOVER\s*\(",
    "View": r"\bCREATE\s+OR\s+ALTER\s+VIEW\b",
    "Stored procedure": r"\bCREATE\s+OR\s+ALTER\s+PROCEDURE\b",
    "Function": r"\bCREATE\s+OR\s+ALTER\s+FUNCTION\b",
    "COMMIT": r"\bCOMMIT\s+TRANSACTION\b",
    "ROLLBACK": r"\bROLLBACK\s+TRANSACTION\b",
    "TRY...CATCH": r"\bBEGIN\s+TRY\b[\s\S]*?\bBEGIN\s+CATCH\b",
    "Temporary table": r"#(?:AccountValues|ReviewQueue|ValidationResults|ClientsCsvStage)",
    "Table variable": r"\bDECLARE\s+@[A-Za-z0-9_]+\s+TABLE\b",
    "Index": r"\bCREATE\s+(?:UNIQUE\s+)?INDEX\b",
    "Execution statistics": r"\bSET\s+STATISTICS\s+(?:IO|TIME)\s+ON\b",
    "Backup": r"\bBACKUP\s+DATABASE\b",
    "Restore": r"\bRESTORE\s+(?:VERIFYONLY|DATABASE|FILELISTONLY)\b",
    "User": r"\bCREATE\s+USER\b",
    "Role": r"\bCREATE\s+ROLE\b",
    "GRANT": r"\bGRANT\b",
    "DENY": r"\bDENY\b",
    "REVOKE": r"\bREVOKE\b",
    "Audit logging": r"\baudit\.ActivityLog\b",
}

EXPECTED_TABLES = {
    "core.Advisor", "core.Client", "core.RiskProfileType",
    "core.ClientRiskProfile", "core.AccountType", "core.InvestmentAccount",
    "market.AssetClass", "market.Security", "market.SecurityPrice",
    "trading.TransactionType", "trading.AccountTransaction",
    "trading.CurrentHolding", "compliance.ComplianceReview",
    "compliance.ComplianceAlert", "audit.ActivityLog",
}


def read_csv(name: str) -> tuple[list[str], list[dict[str, str]]]:
    path = ROOT / "data" / name
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return list(reader.fieldnames or []), list(reader)


def lexical_balance(text: str) -> tuple[bool, str]:
    """Check quotes, comments, and parentheses without parsing T-SQL."""
    i = 0
    parens = 0
    state = "normal"
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "normal":
            if ch == "'":
                state = "string"
            elif ch == "-" and nxt == "-":
                state = "line_comment"
                i += 1
            elif ch == "/" and nxt == "*":
                state = "block_comment"
                i += 1
            elif ch == "(":
                parens += 1
            elif ch == ")":
                parens -= 1
                if parens < 0:
                    return False, "closing parenthesis before matching opening parenthesis"
        elif state == "string":
            if ch == "'" and nxt == "'":
                i += 1
            elif ch == "'":
                state = "normal"
        elif state == "line_comment":
            if ch == "\n":
                state = "normal"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "normal"
                i += 1
        i += 1

    if state == "string":
        return False, "unterminated string literal"
    if state == "block_comment":
        return False, "unterminated block comment"
    if parens != 0:
        return False, f"unbalanced parentheses: net {parens}"
    return True, "quotes, comments, and parentheses balanced"


def main() -> int:
    results: list[tuple[str, bool, str]] = []

    missing = [p for p in EXPECTED_FILES if not (ROOT / p).exists()]
    results.append((
        "Required files",
        not missing,
        "all required files found" if not missing else f"missing: {missing}"
    ))

    manifest = json.loads((ROOT / "project-manifest.json").read_text(encoding="utf-8"))
    results.append((
        "Manifest identity",
        manifest.get("project") == "Wealth Management Operations Database"
        and manifest.get("author") == "Thomas Wagenberg"
        and manifest.get("synthetic_data") is True,
        "project, author, and synthetic-data flag checked"
    ))

    csv_rows: dict[str, list[dict[str, str]]] = {}
    for name, expected_count in EXPECTED_CSV_COUNTS.items():
        header, rows = read_csv(name)
        csv_rows[name] = rows
        results.append((
            f"CSV {name}",
            header == EXPECTED_HEADERS[name] and len(rows) == expected_count,
            f"header={'OK' if header == EXPECTED_HEADERS[name] else 'MISMATCH'}; "
            f"rows={len(rows)} expected={expected_count}"
        ))

    clients = csv_rows["clients.csv"]
    securities = csv_rows["securities.csv"]
    prices = csv_rows["prices.csv"]
    transactions = csv_rows["transactions.csv"]
    holdings = csv_rows["expected_holdings.csv"]

    client_ids = {int(r["ClientID"]) for r in clients}
    security_ids = {int(r["SecurityID"]) for r in securities}
    account_ids = set(range(1, 51))
    transaction_ids = {int(r["TransactionID"]) for r in transactions}

    results.append((
        "CSV unique business identifiers",
        len({r["ClientCode"] for r in clients}) == len(clients)
        and len({r["Symbol"] for r in securities}) == len(securities)
        and len({r["ExternalReference"] for r in transactions}) == len(transactions),
        "client codes, symbols, and transaction references checked"
    ))

    price_pairs = {(int(r["SecurityID"]), r["PriceDate"]) for r in prices}
    results.append((
        "CSV price references",
        all(int(r["SecurityID"]) in security_ids and float(r["ClosePrice"]) > 0 for r in prices)
        and len(price_pairs) == len(prices),
        "all price security IDs exist, prices are positive, and dates are unique per security"
    ))

    tx_valid = True
    signed: defaultdict[tuple[int, int], float] = defaultdict(float)
    for row in transactions:
        account_id = int(row["AccountID"])
        ttype = int(row["TransactionTypeID"])
        security_text = row["SecurityID"].strip()
        quantity_text = row["Quantity"].strip()
        price_text = row["Price"].strip()
        if account_id not in account_ids or int(row["TransactionID"]) not in transaction_ids:
            tx_valid = False
        if float(row["GrossAmount"]) < 0 or float(row["FeeAmount"]) < 0:
            tx_valid = False
        if security_text:
            security_id = int(security_text)
            if security_id not in security_ids or not quantity_text or not price_text:
                tx_valid = False
            qty = float(quantity_text)
            price = float(price_text)
            if qty <= 0 or price <= 0 or ttype not in (2, 3):
                tx_valid = False
            signed[(account_id, security_id)] += qty if ttype == 2 else -qty
        elif quantity_text or price_text:
            tx_valid = False
    results.append(("CSV transaction rules", tx_valid, "references, amounts, and security-field rules checked"))

    holding_map = {
        (int(r["AccountID"]), int(r["SecurityID"])): float(r["Quantity"])
        for r in holdings
    }
    reconciliation_ok = (
        set(holding_map) == set(signed)
        and all(abs(signed[key] - holding_map[key]) <= 1e-9 for key in signed)
        and all(qty > 0 for qty in holding_map.values())
    )
    results.append((
        "Holdings reconciliation",
        reconciliation_ok,
        "current quantities equal BUY minus SELL quantities"
    ))

    sql_paths = sorted((ROOT / "sql").glob("*.sql"))
    sql_texts = {}
    for path in sql_paths:
        text = path.read_text(encoding="utf-8")
        sql_texts[path.name] = text
        ok, detail = lexical_balance(text)
        results.append((f"Lexical SQL check: {path.name}", ok, detail))

    corpus = "\n".join(sql_texts.values())
    for label, pattern in REQUIRED_SQL_PATTERNS.items():
        found = re.search(pattern, corpus, flags=re.IGNORECASE | re.MULTILINE) is not None
        results.append((f"SQL concept: {label}", found, "found" if found else "not found"))

    create_tables = set(
        f"{schema}.{table}"
        for schema, table in re.findall(
            r"\bCREATE\s+TABLE\s+([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)",
            sql_texts["03_create_tables.sql"],
            flags=re.IGNORECASE,
        )
    )
    results.append((
        "Expected table names",
        create_tables == EXPECTED_TABLES,
        f"found {len(create_tables)} of {len(EXPECTED_TABLES)} exact table names"
    ))

    run_all = sql_texts["run_all.sql"]
    expected_order = [
        f"{i:02d}_" for i in range(0, 12)
    ] + ["13_"]
    positions = [run_all.find(token) for token in expected_order]
    results.append((
        "Master build order",
        all(pos >= 0 for pos in positions)
        and positions == sorted(positions),
        "scripts 00 through 11 and 13 referenced in dependency order"
    ))

    forbidden = [
        "WideWorldImporters",
        "Adam Wilbert",
    ]
    forbidden_hits = [term for term in forbidden if term.lower() in corpus.lower()]
    results.append((
        "No copied course identifiers in SQL",
        not forbidden_hits,
        "no prohibited identifiers found" if not forbidden_hits else f"found: {forbidden_hits}"
    ))

    failed = [r for r in results if not r[1]]
    for name, passed, detail in results:
        print(f"[{'PASS' if passed else 'FAIL'}] {name}: {detail}")

    print()
    print(f"Static checks: {len(results) - len(failed)} passed; {len(failed)} failed.")
    print("This tool did not execute T-SQL against SQL Server.")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
