#!/usr/bin/env python3
"""Static and structural checks for the expanded reference platform.

This checker intentionally does not claim to compile .NET, parse T-SQL with the
SQL Server engine, compile Bicep, authenticate with Entra, or deploy Azure.
"""
from __future__ import annotations

import csv
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools"))
from static_check import lexical_balance  # noqa: E402

REQUIRED = [
    "global.json",
    "Directory.Build.props",
    "Directory.Packages.props",
    "WealthManagement.slnx",
    "src/WealthManagement.Api/Program.cs",
    "src/WealthManagement.Web/Program.cs",
    "src/WealthManagement.Infrastructure/Data/SqlConnectionFactory.cs",
    "src/WealthManagement.Web/Components/Pages/Trade.razor",
    "database/local/20_application_extensions.sql",
    "database/security/21_identity_and_row_level_security.sql",
    "database/local/22_application_procedures.sql",
    "database/security/23_transaction_immutability_and_permissions.sql",
    "database/security/24_temporal_history.sql",
    "database/local/25_create_local_application_login.sql",
    "database/tests/20_application_validation.sql",
    "database/tests/30_azure_security_validation.sql",
    "database/azure/run_azure_schema.sql",
    "infra/bicep/main.bicep",
    "infra/bicep/modules/budget.bicep",
    "infra/bicep/parameters/dev.bicepparam",
    ".github/workflows/dotnet-ci.yml",
    ".github/workflows/codeql.yml",
    ".github/workflows/container-scan.yml",
    "docs/architecture/overview.md",
    "docs/security/threat-model.md",
    "docs/compliance/control-mapping.md",
    "docs/operations/production-readiness.md",
    "docs/operations/test-results.md",
    "docs/AZURE_SQL_REFERENCE_RESEARCH.md",
    "docs/AZURE_INSPIRED_FUNCTIONAL_PARITY_MATRIX.md",
    "docs/ORIGINALITY_AND_BRAND_REVIEW.md",
    "docs/claims.md",
    "docker-compose.yml",
    ".env.example",
]

EXPECTED_CSV_COUNTS = {
    "clients.csv": 30,
    "securities.csv": 25,
    "prices.csv": 175,
    "transactions.csv": 403,
    "expected_holdings.csv": 300,
}

TEXT_SUFFIXES = {
    ".cs", ".csproj", ".props", ".sql", ".bicep", ".bicepparam", ".json",
    ".yml", ".yaml", ".md", ".sh", ".ps1", ".razor", ".css", ".xml",
    ".example", ".slnx", ".gitignore", ".txt",
}


def balanced(text: str, open_char: str = "{", close_char: str = "}") -> bool:
    depth = 0
    state = "normal"
    quote = ""
    escape = False
    for char in text:
        if state == "string":
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == quote:
                state = "normal"
            continue
        if char in ('"', "'"):
            state = "string"
            quote = char
        elif char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth < 0:
                return False
    return depth == 0 and state == "normal"


def add(results: list[tuple[str, bool, str]], name: str, ok: bool, detail: str) -> None:
    results.append((name, ok, detail))


def read(path: str | Path) -> str:
    return (ROOT / path).read_text(encoding="utf-8", errors="strict")


def main() -> int:
    results: list[tuple[str, bool, str]] = []

    missing = [path for path in REQUIRED if not (ROOT / path).exists()]
    add(results, "Required platform files", not missing, "all required files found" if not missing else f"missing: {missing}")

    original = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "static_check.py")],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    original_ok = original.returncode == 0 and "71 passed; 0 failed" in original.stdout
    add(results, "Original SQL static checker", original_ok, "71 passed; 0 failed" if original_ok else (original.stderr or original.stdout)[-600:])

    csv_details: list[str] = []
    csv_ok = True
    for name, expected in EXPECTED_CSV_COUNTS.items():
        with (ROOT / "data" / name).open(encoding="utf-8-sig", newline="") as handle:
            count = sum(1 for _ in csv.DictReader(handle))
        csv_details.append(f"{name}={count}")
        csv_ok &= count == expected
    add(results, "Original synthetic CSV counts", csv_ok, "; ".join(csv_details))

    manifest = json.loads(read("project-manifest.json"))
    add(
        results,
        "Synthetic-data declaration",
        manifest.get("synthetic_data") is True and manifest.get("database_name") == "WealthManagementOperations",
        "manifest identifies the fixed synthetic database",
    )

    json_files = list(ROOT.rglob("*.json"))
    json_errors: list[str] = []
    for path in json_files:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            json_errors.append(f"{path.relative_to(ROOT)}: {exc}")
    add(results, "JSON syntax", not json_errors, f"parsed {len(json_files)} JSON files" if not json_errors else "; ".join(json_errors))

    xml_files = list(ROOT.rglob("*.csproj")) + [ROOT / "Directory.Build.props", ROOT / "Directory.Packages.props"]
    xml_errors: list[str] = []
    for path in xml_files:
        try:
            ET.fromstring(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            xml_errors.append(f"{path.relative_to(ROOT)}: {exc}")
    add(results, "MSBuild XML syntax", not xml_errors, f"parsed {len(xml_files)} project and props files" if not xml_errors else "; ".join(xml_errors))

    yaml_files = list((ROOT / ".github" / "workflows").glob("*.yml")) + [ROOT / "docker-compose.yml"]
    yaml_errors: list[str] = []
    for path in yaml_files:
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            yaml_errors.append(f"{path.relative_to(ROOT)}: {exc}")
    add(results, "YAML syntax", not yaml_errors, f"parsed {len(yaml_files)} workflow and Compose files" if not yaml_errors else "; ".join(yaml_errors))

    shell_files = list((ROOT / "scripts").glob("*.sh"))
    shell_errors: list[str] = []
    for path in shell_files:
        completed = subprocess.run(["bash", "-n", str(path)], text=True, capture_output=True, check=False)
        if completed.returncode != 0:
            shell_errors.append(f"{path.relative_to(ROOT)}: {completed.stderr.strip()}")
    add(results, "Shell syntax", not shell_errors, f"bash -n passed for {len(shell_files)} scripts" if not shell_errors else "; ".join(shell_errors))

    csharp = list((ROOT / "src").rglob("*.cs")) + list((ROOT / "tests").rglob("*.cs"))
    bad_cs = [str(path.relative_to(ROOT)) for path in csharp if not balanced(path.read_text(encoding="utf-8"))]
    add(results, "C# lexical brace check", not bad_cs, f"checked {len(csharp)} C# files" if not bad_cs else f"unbalanced: {bad_cs}")

    razor_files = list((ROOT / "src" / "WealthManagement.Web").rglob("*.razor"))
    suspicious_razor = []
    for path in razor_files:
        text = path.read_text(encoding="utf-8")
        if re.search(r'@onclick="[^"\n]*"[A-Z_]+"', text):
            suspicious_razor.append(str(path.relative_to(ROOT)))
    add(results, "Razor event-attribute review", not suspicious_razor, f"checked {len(razor_files)} Razor files for nested-quote defects" if not suspicious_razor else f"review: {suspicious_razor}")

    extension_sql = list((ROOT / "database").rglob("*.sql"))
    bad_sql: list[str] = []
    for path in extension_sql:
        ok, detail = lexical_balance(path.read_text(encoding="utf-8"))
        if not ok:
            bad_sql.append(f"{path.relative_to(ROOT)}: {detail}")
    add(results, "Extended SQL lexical check", not bad_sql, f"checked {len(extension_sql)} application, security, Azure, and test scripts" if not bad_sql else "; ".join(bad_sql))

    bicep = list((ROOT / "infra" / "bicep").rglob("*.bicep")) + list((ROOT / "infra" / "bicep").rglob("*.bicepparam"))
    bad_bicep = [str(path.relative_to(ROOT)) for path in bicep if not balanced(path.read_text(encoding="utf-8"))]
    add(results, "Bicep lexical brace check", not bad_bicep, f"checked {len(bicep)} Bicep files" if not bad_bicep else f"unbalanced: {bad_bicep}")

    endpoint_text = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "src" / "WealthManagement.Api" / "Endpoints").glob("*.cs"))
    direct_sql = "Dapper" in endpoint_text or "SqlConnection" in endpoint_text or re.search(r"\bSELECT\s+", endpoint_text, re.I)
    add(results, "Endpoint data-access boundary", not direct_sql, "API endpoints contain no direct SQL, Dapper, or SqlConnection use")

    projects = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "src").rglob("*.csproj"))
    add(results, "No Entity Framework replacement", "EntityFrameworkCore" not in projects, "wealth database remains Dapper and hand-written T-SQL")

    repositories = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "src" / "WealthManagement.Infrastructure" / "Repositories").glob("*.cs"))
    dangerous_interpolation = re.search(r'\$"[^"\n]*(SELECT|UPDATE|INSERT|DELETE)', repositories, re.I) is not None
    add(results, "No interpolated SQL in repositories", not dangerous_interpolation, "repository SQL uses constants, parameters, and stored procedures")

    auth = read("src/WealthManagement.Api/Authentication/AuthenticationExtensions.cs")
    add(results, "Development authentication production guard", "enableDevelopmentAuth && !environment.IsDevelopment()" in auth and "throw new InvalidOperationException" in auth, "fail-fast production guard found")

    api_program = read("src/WealthManagement.Api/Program.cs")
    auth_before_rate = api_program.find("app.UseAuthentication();") < api_program.find("app.UseRateLimiter();")
    add(results, "Authenticated rate-limit partitioning", auth_before_rate and '.RequireRateLimiting("trade")' in read("src/WealthManagement.Api/Endpoints/TradeEndpoints.cs"), "authentication runs before global and trade-specific rate limiting")

    api_settings = json.loads(read("src/WealthManagement.Api/appsettings.json"))
    add(results, "Production development-auth default", api_settings["Authentication"]["EnableDevelopmentAuth"] is False, "development authentication defaults to false")

    compose = read("docker-compose.yml")
    env_example = read(".env.example")
    add(results, "Low-privilege local application connection", "User ID=wm_application" in compose and "ConnectionStrings__WealthManagement" in compose and "User ID=sa" not in compose, "API uses wm_application rather than sa")
    add(results, "No committed local password", "SET_A_STRONG_LOCAL_ONLY_PASSWORD" in env_example and not (ROOT / ".env").exists(), "only .env.example placeholders are present")

    security_sql = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "database" / "security").glob("*.sql"))
    local_sql = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "database" / "local").glob("*.sql"))
    add(results, "Advisor row isolation", all(term in security_sql for term in ["CREATE SECURITY POLICY", "SESSION_CONTEXT", "AppUser"]), "SQL RLS and server-resolved application-user mapping found")
    add(results, "Trade idempotency", all(term in local_sql for term in ["IdempotencyRecord", "RequestHash", "usp_SubmitTrade"]), "serialized idempotency record and stored procedure found")
    add(results, "Optimistic concurrency", "rowversion" in (security_sql + local_sql).lower() and "ExpectedRowVersion" in local_sql, "rowversion and expected-version checks found")
    add(results, "Append-oriented audit design", all(term in local_sql for term in ["PreviousHash", "EventHash", "usp_AppendAuditEvent"]), "hash-chained audit procedure found")
    add(results, "Posted-transaction immutability", "trg_accounttransaction_immutable" in security_sql.lower() and "instead of update, delete" in security_sql.lower(), "immutable transaction trigger found")
    add(results, "Temporal workflow history", "SYSTEM_VERSIONING = ON" in security_sql and "ComplianceAlertHistory" in security_sql, "temporal history scripts found")

    bicep_corpus = "\n".join(path.read_text(encoding="utf-8") for path in bicep)
    security_terms = [
        "SystemAssigned", "privateEndpoints", "minimalTlsVersion", "publicNetworkAccess",
        "auditingSettings", "diagnosticSettings", "backupShortTermRetentionPolicies",
        "enableRbacAuthorization", "Microsoft.Consumption/budgets", "sqlVulnerabilityAssessments",
    ]
    absent = [term for term in security_terms if term not in bicep_corpus]
    add(results, "Azure security template coverage", not absent, "managed identity, private networking, TLS, auditing, diagnostics, backups, Key Vault RBAC, budgets, and vulnerability assessment found" if not absent else f"missing: {absent}")

    main_bicep = read("infra/bicep/main.bicep")
    add(results, "Cost-control defaults", "monthlyBudgetAmount int = 0" in main_bicep and "monthlyBudgetAmount > 0 && !empty(alertEmail)" in main_bicep, "budget requires an explicit amount and notification address")

    workflows = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / ".github" / "workflows").glob("*.yml"))
    workflow_terms = [
        "dotnet test", "static_check.py", "platform_static_check.py", "codeql-action",
        "dependency-review-action", "gitleaks", "sbom-action", "id-token: write",
        "az bicep build", "trivy-action",
    ]
    missing_workflow = [term for term in workflow_terms if term not in workflows]
    add(results, "DevSecOps workflow coverage", not missing_workflow, "build, tests, SQL review, SAST, dependency review, secret scan, SBOM, OIDC, Bicep, and container scanning found" if not missing_workflow else f"missing: {missing_workflow}")
    add(results, "No long-lived Azure workflow secret", "client-secret" not in workflows.lower() and "azure/login" in workflows and "id-token: write" in workflows, "deployment workflow uses OIDC pattern")

    test_sql = read("database/tests/20_application_validation.sql")
    test_count = len(re.findall(r"INSERT\s+(?:INTO\s+)?#Results", test_sql, re.I))
    add(results, "Extended database validation coverage", test_count >= 18, f"found {test_count} application database result assertions")

    test_projects = list((ROOT / "tests").glob("*.*/"))
    expected_test_dirs = {
        "WealthManagement.UnitTests", "WealthManagement.IntegrationTests",
        "WealthManagement.ArchitectureTests", "WealthManagement.SecurityTests",
    }
    actual_test_dirs = {path.name for path in (ROOT / "tests").iterdir() if path.is_dir()}
    add(results, "Four test layers present", expected_test_dirs <= actual_test_dirs, f"found: {sorted(actual_test_dirs)}")

    generated = [path for name in ("bin", "obj", "node_modules", ".vs", "__pycache__") for path in ROOT.rglob(name) if path.is_dir()]
    add(results, "No generated build folders", not generated, "no bin, obj, node_modules, .vs, or __pycache__ directories packaged" if not generated else f"found: {[str(path.relative_to(ROOT)) for path in generated]}")

    forbidden_ext = [
        path for path in ROOT.rglob("*") if path.is_file()
        and path.suffix.lower() in {".bak", ".mdf", ".ndf", ".ldf", ".pfx", ".p12", ".pem", ".key"}
    ]
    add(results, "No prohibited binary or key material", not forbidden_ext, "no database files, backups, certificates, or private keys found" if not forbidden_ext else f"found: {[str(path.relative_to(ROOT)) for path in forbidden_ext]}")

    secret_issues: list[str] = []
    private_key = re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")
    credential_connection = re.compile(r"(?:Password|Pwd)\s*=\s*(?!\$\{|SET_|<|\.\.\.|\{\{|@Microsoft\.KeyVault)[^;\s\"']+", re.I)
    token_pattern = re.compile(r"(?i)(?:api[_-]?key|client[_-]?secret|access[_-]?token)\s*[:=]\s*[\"']?[A-Za-z0-9_\-]{20,}")
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() in {".zip", ".png", ".jpg", ".jpeg", ".gif", ".ico"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if private_key.search(text) or credential_connection.search(text) or token_pattern.search(text):
            secret_issues.append(str(path.relative_to(ROOT)))
    add(results, "Secret-pattern scan", not secret_issues, "no committed private keys, credential-bearing connection strings, or token-like assignments found" if not secret_issues else f"review: {secret_issues}")

    placeholders: list[str] = []
    for path in ROOT.rglob("*"):
        if path.is_file() and (path.suffix.lower() in TEXT_SUFFIXES or path.name in {".gitignore"}):
            text = path.read_text(encoding="utf-8", errors="ignore")
            if re.search(r"\b(TODO|FIXME|CHANGEME)\b", text):
                placeholders.append(str(path.relative_to(ROOT)))
    add(results, "No unresolved placeholder markers", not placeholders, "no unresolved placeholder markers found" if not placeholders else f"found: {placeholders}")

    broken_links: list[str] = []
    link_pattern = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    for path in ROOT.rglob("*.md"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for raw_target in link_pattern.findall(text):
            target = raw_target.strip().split(" ", 1)[0].strip("<>")
            if not target or target.startswith(("http://", "https://", "mailto:", "#", "sandbox:")) or "[INSERT" in target:
                continue
            local_target = target.split("#", 1)[0]
            if not local_target:
                continue
            resolved = (path.parent / local_target).resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                broken_links.append(f"{path.relative_to(ROOT)} -> {target} (outside repository)")
                continue
            if not resolved.exists():
                broken_links.append(f"{path.relative_to(ROOT)} -> {target}")
    add(results, "Local Markdown links", not broken_links, "all repository-relative Markdown links resolve" if not broken_links else f"broken: {broken_links[:20]}")

    screenshots = [path for path in (ROOT / "screenshots").rglob("*") if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif"}]
    add(results, "No fabricated screenshots", not screenshots, "screenshot folder contains guidance only" if not screenshots else f"review: {[str(path.relative_to(ROOT)) for path in screenshots]}")

    original_runner = read("sql/run_all.sql")
    azure_runner = read("database/azure/run_azure_schema.sql")
    azure_includes = "\n".join(line.strip() for line in azure_runner.splitlines() if line.lstrip().lower().startswith(":r"))
    add(results, "Original learning sequence preserved", "00_reset_database.sql" in original_runner and "13_validation_tests.sql" in original_runner, "original SQLCMD sequence remains available")
    add(results, "Azure scripts separated", "00_reset_database.sql" not in azure_includes and "14_backup_restore_examples.sql" not in azure_includes and "01_create_database.sql" not in azure_includes, "Azure runner excludes local reset, database creation, and backup scripts")

    limitations = read("docs/known-limitations.md") + read("docs/operations/test-results.md")
    required_limits = ["not executed", "not deployed", ".NET", "SQL", "Bicep", "Entra"]
    add(results, "Verification limitations documented", all(term.lower() in limitations.lower() for term in required_limits), "build, database, infrastructure, identity, and deployment limitations are explicit")

    azure_research = read("docs/AZURE_SQL_REFERENCE_RESEARCH.md")
    official_links = re.findall(r"https://(?:learn\.microsoft\.com|azure\.microsoft\.com|www\.microsoft\.com|fluent2\.microsoft\.design|inclusive\.microsoft\.design)/[^)\s]+", azure_research)
    required_research_sections = [
        "Executive summary", "Official sources reviewed", "Important Azure SQL capabilities",
        "Relevant Azure architectural patterns", "Relevant Azure user-experience patterns",
        "Patterns appropriate for this project", "Patterns inappropriate for the current project",
        "Cost considerations", "Security considerations", "Reliability considerations",
        "Accessibility considerations", "Legal and brand-separation requirements",
        "Source-backed architecture recommendation",
    ]
    add(results, "Azure SQL research evidence", len(set(official_links)) >= 25 and all(section in azure_research for section in required_research_sections), f"found {len(set(official_links))} distinct official-source links and all required research sections")

    parity = read("docs/AZURE_INSPIRED_FUNCTIONAL_PARITY_MATRIX.md")
    parity_rows = sum(1 for line in parity.splitlines() if line.startswith("|") and not line.startswith(("| Azure or", "| ---")))
    add(results, "Azure-inspired parity matrix", parity_rows >= 25 and all(term in parity for term in ["Wealth-management equivalent", "Implementation approach", "Status", "Evidence"]), f"found {parity_rows} source-to-domain mapping rows")

    originality = read("docs/ORIGINALITY_AND_BRAND_REVIEW.md")
    originality_terms = [
        "Microsoft elements intentionally excluded", "Brand identity differences", "Navigation differences",
        "Page-structure differences", "Terminology differences", "Visual-design differences",
        "Source-code independence", "Independent-design test", "not legal advice",
    ]
    layout = read("src/WealthManagement.Web/Components/Layout/MainLayout.razor")
    add(results, "Originality and Microsoft brand separation", all(term in originality for term in originality_terms) and "Enterprise-style Azure reference application" not in layout and "WM Operations" in layout, "originality review, independent-design test, own product identity, and non-affiliation boundary found")

    claims = read("docs/claims.md")
    prohibited_claim_terms = ["ISO certified", "SOC 2 certified", "production-ready", "unhackable"]
    add(results, "Claims boundary documented", all(term in claims for term in prohibited_claim_terms), "unsafe certification and production claims are expressly prohibited")

    passed = sum(ok for _, ok, _ in results)
    failed = len(results) - passed
    for name, ok, detail in results:
        print(f"[{'PASS' if ok else 'FAIL'}] {name}: {detail}")
    print(f"\nPlatform static checks: {passed} passed; {failed} failed.")
    print("This checker did not compile .NET, execute T-SQL, build Bicep, authenticate with Entra, or deploy Azure resources.")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
