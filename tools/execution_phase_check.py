#!/usr/bin/env python3
"""Deeper static checks added during the execution and verification phase.

These checks validate source relationships and security invariants that do not
require external services. They never claim .NET compilation, SQL execution,
Bicep compilation, Entra validation, or Azure deployment.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def result(rows: list[tuple[str, bool, str]], name: str, ok: bool, detail: str) -> None:
    rows.append((name, ok, detail))


def module_parameters(path: Path) -> set[str]:
    required: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^param\s+([A-Za-z_][A-Za-z0-9_]*)\s+", line)
        if match and "=" not in line:
            required.add(match.group(1))
    return required


def module_calls(main_text: str) -> list[tuple[str, str, set[str]]]:
    calls: list[tuple[str, str, set[str]]] = []
    pattern = re.compile(r"module\s+(\w+)\s+'([^']+)'\s*=\s*\{", re.M)
    for match in pattern.finditer(main_text):
        start = match.end()
        depth = 1
        i = start
        while i < len(main_text) and depth:
            if main_text[i] == "{": depth += 1
            elif main_text[i] == "}": depth -= 1
            i += 1
        block = main_text[start:i - 1]
        params_match = re.search(r"params\s*:\s*\{(.*?)\n\s*\}", block, re.S)
        supplied = set(re.findall(r"(?m)^\s{4,}([A-Za-z_][A-Za-z0-9_]*)\s*:", params_match.group(1))) if params_match else set()
        calls.append((match.group(1), match.group(2), supplied))
    return calls


def main() -> int:
    rows: list[tuple[str, bool, str]] = []

    required_pages = {
        "Home.razor", "Clients.razor", "ClientPortfolio.razor", "Allocation.razor",
        "Risk.razor", "Concentration.razor", "AdvisorActivity.razor", "Compliance.razor",
        "Trade.razor", "Audit.razor", "Health.razor", "Login.razor"
    }
    page_names = {p.name for p in (ROOT / "src/WealthManagement.Web/Components/Pages").glob("*.razor")}
    result(rows, "Required demonstration pages", required_pages <= page_names, f"found {len(required_pages & page_names)}/{len(required_pages)} required pages")

    endpoints = "\n".join(p.read_text(encoding="utf-8") for p in (ROOT / "src/WealthManagement.Api/Endpoints").glob("*.cs"))
    required_routes = [
        'MapGroup("/api/portfolios")', 'MapGet("/clients"', "/accounts/{accountId:int}/allocation", "/risk", "/concentration",
        "/advisor/{advisorId:int}/activity", "/compliance-dashboard", "/api/trades", "/api/compliance",
        "/api/audit/events", "/health/live", "/health/ready", "/api/version", "/api/operations/health"
    ]
    missing_routes = [route for route in required_routes if route not in endpoints]
    result(rows, "Required API routes", not missing_routes, "all required routes present" if not missing_routes else f"missing: {missing_routes}")

    interfaces = read("src/WealthManagement.Application/Abstractions/Repositories.cs")
    access_methods = set(re.findall(r"Task<bool>\s+(CanAccess\w+Async)", interfaces))
    implementations = [
        ROOT / "src/WealthManagement.Infrastructure/Repositories/AccessControlRepository.cs",
        ROOT / "tests/WealthManagement.UnitTests/TradeServiceTests.cs",
        ROOT / "tests/WealthManagement.UnitTests/PortfolioServiceTests.cs",
        ROOT / "tests/WealthManagement.SecurityTests/SecurityBoundaryTests.cs",
    ]
    missing_impl: list[str] = []
    for path in implementations:
        text = path.read_text(encoding="utf-8")
        for method in access_methods:
            if method not in text:
                missing_impl.append(f"{path.relative_to(ROOT)}:{method}")
    result(rows, "Access-control interface implementations", not missing_impl, f"{len(access_methods)} access methods found in every implementation" if not missing_impl else f"missing: {missing_impl}")

    services = read("src/WealthManagement.Application/Services/Services.cs")
    result(rows, "Object-level client authorization", "CanAccessClientAsync" in services and "GetClientAsync" in services, "client-specific service path checks access")
    result(rows, "Object-level account authorization", services.count("CanAccessAccountAsync") >= 2, "allocation, concentration, and trade paths check account scope")
    result(rows, "Object-level advisor authorization", "CanAccessAdvisorAsync" in services, "advisor activity path checks advisor scope")

    dev_handler = read("src/WealthManagement.Api/Authentication/DevelopmentHeaderAuthenticationHandler.cs")
    dev_catalog = read("src/WealthManagement.Contracts/Security/DevelopmentIdentities.cs")
    web_handler = read("src/WealthManagement.Web/Api/ApiAuthorizationHandler.cs")
    result(rows, "Server-resolved development roles", "DevelopmentIdentities.TryGet" in dev_handler and "X-Dev-Roles" not in dev_handler and "X-Dev-Advisor-Id" not in dev_handler, "API accepts only a configured synthetic identity selector")
    result(rows, "Development identity catalog", all(x in dev_catalog for x in ["AdvisorUser", "ComplianceReviewer", "ReportingAnalyst", "ReadOnlyAuditor", "DatabaseAdministrator"]), "all five roles have fixed synthetic identities")
    result(rows, "Web does not forward development role claims", "X-Dev-Roles" not in web_handler and "X-Dev-Advisor-Id" not in web_handler, "web forwards only the configured identity key")

    security_tests = read("tests/WealthManagement.SecurityTests/SecurityBoundaryTests.cs")
    expected_security_tests = [
        "Anonymous_portfolio_request_is_rejected", "Advisor_cannot_retrieve_an_unrelated_client",
        "Client_supplied_development_role_header_cannot_escalate_privilege", "Reporting_user_cannot_open_raw_compliance_workflow",
        "Auditor_cannot_submit_a_trade", "Compliance_pagination_limit_is_enforced",
        "Stale_row_version_returns_problem_details_conflict", "Trade_endpoint_enforces_per_identity_rate_limit",
        "Advisor_cannot_query_an_unrelated_account_concentration", "Advisor_cannot_query_an_unrelated_advisor_activity"
    ]
    missing_tests = [name for name in expected_security_tests if name not in security_tests]
    result(rows, "Security test source coverage", not missing_tests, f"found {len(expected_security_tests)} required security test cases" if not missing_tests else f"missing: {missing_tests}")
    result(rows, "Known C# property defect removed", "request.RowVersion" not in security_tests, "compliance fake uses ExpectedRowVersion")

    sql_security = read("database/security/21_identity_and_row_level_security.sql") + read("database/security/23_transaction_immutability_and_permissions.sql")
    sql_procs = read("database/local/22_application_procedures.sql")
    sql_tests = read("database/tests/20_application_validation.sql")
    result(rows, "Advisor SQL object authorization", "security.usp_CanAccessAdvisor" in sql_security and re.search(r"GRANT\s+EXECUTE\s+ON(?:\s+OBJECT::)?security\.usp_CanAccessAdvisor", sql_security, re.I) is not None, "advisor access procedure and application grant are present")
    result(rows, "Idempotent replay continuity", "@ExistingCorrelationID AS CorrelationID" in sql_procs and "@FirstCorrelationID=@ReplayCorrelationID" in sql_tests, "replay returns and tests the original correlation identifier")
    result(rows, "Advisor activity input bounds", "DATEDIFF(DAY,@StartDate,@EndDate)>366" in sql_procs, "database procedure enforces a bounded chronological range")
    result(rows, "Application database assertions", len(re.findall(r"INSERT\s+(?:INTO\s+)?#Results", sql_tests, re.I)) >= 20, "extended SQL suite contains at least 20 machine-readable result rows")

    local_runner = read("scripts/init-database.sh")
    referenced = re.findall(r"(?:^|\s)(sql/[^\s]+\.sql|database/[^\s]+\.sql)", local_runner)
    missing_sql_files = [path for path in referenced if not (ROOT / path).exists()]
    result(rows, "Local SQL runner references", not missing_sql_files, f"all {len(referenced)} referenced SQL files exist" if not missing_sql_files else f"missing: {missing_sql_files}")

    main_path = ROOT / "infra/bicep/main.bicep"
    main_text = main_path.read_text(encoding="utf-8")
    module_issues: list[str] = []
    for module_name, relative_path, supplied in module_calls(main_text):
        module_path = main_path.parent / relative_path
        if not module_path.exists():
            module_issues.append(f"{module_name}: missing {relative_path}")
            continue
        required = module_parameters(module_path)
        if required != supplied:
            module_issues.append(f"{module_name}: missing={sorted(required-supplied)}, extra={sorted(supplied-required)}")
    result(rows, "Bicep module parameter wiring", not module_issues, "main.bicep supplies every declared module parameter exactly once" if not module_issues else "; ".join(module_issues))

    bicep = "\n".join(p.read_text(encoding="utf-8") for p in (ROOT / "infra/bicep").rglob("*.bicep"))
    bicep_requirements = [
        "Microsoft.Web/serverfarms", "Microsoft.Web/sites", "Microsoft.Sql/servers", "Microsoft.KeyVault/vaults",
        "Microsoft.OperationalInsights/workspaces", "Microsoft.Insights/components", "Microsoft.Storage/storageAccounts",
        "Microsoft.Network/virtualNetworks", "Microsoft.Network/privateEndpoints", "Microsoft.Network/privateDnsZones",
        "Microsoft.Insights/diagnosticSettings", "Microsoft.Insights/metricAlerts", "Microsoft.Authorization/locks",
        "Microsoft.Consumption/budgets", "Microsoft.Security/pricings", "Microsoft.Authorization/policyAssignments"
    ]
    absent_bicep = [x for x in bicep_requirements if x not in bicep]
    result(rows, "Bicep resource coverage", not absent_bicep, "all required resource families represented" if not absent_bicep else f"missing: {absent_bicep}")
    result(rows, "Audit storage private endpoint", "auditStorageEndpoint" in bicep and "blobPrivateDnsZoneId" in bicep, "protected audit storage has optional private connectivity")
    result(rows, "App and Key Vault diagnostics", "apiDiagnostics" in bicep and "webDiagnostics" in bicep and "scope: vault" in bicep, "application and vault diagnostics target Log Analytics")

    project_files = list(ROOT.rglob("*.csproj"))
    project_paths = {p.resolve() for p in project_files}
    broken_refs: list[str] = []
    for project in project_files:
        root = ET.parse(project).getroot()
        for node in root.findall(".//ProjectReference"):
            target = (project.parent / node.attrib["Include"]).resolve()
            if target not in project_paths:
                broken_refs.append(f"{project.relative_to(ROOT)} -> {node.attrib['Include']}")
    result(rows, "Project-reference integrity", not broken_refs, f"validated {len(project_files)} project files" if not broken_refs else f"broken: {broken_refs}")

    workflow_files = list((ROOT / ".github/workflows").glob("*.yml"))
    workflow_errors: list[str] = []
    for path in workflow_files:
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            workflow_errors.append(f"{path.name}: {exc}")
    workflow_text = "\n".join(p.read_text(encoding="utf-8") for p in workflow_files)
    result(rows, "Workflow YAML", not workflow_errors, f"parsed {len(workflow_files)} workflows" if not workflow_errors else "; ".join(workflow_errors))
    result(rows, "OIDC deployment boundary", "id-token: write" in workflow_text and "client-secret" not in workflow_text.lower(), "Azure workflow uses OIDC and no long-lived client secret")

    expected_outputs = [ROOT / "artifacts/sbom/source-dependency-inventory.spdx.json"]
    missing_outputs = [str(p.relative_to(ROOT)) for p in expected_outputs if not p.exists()]
    result(rows, "Source dependency inventory", not missing_outputs, "source-declared SPDX file exists" if not missing_outputs else f"missing: {missing_outputs}")
    if not missing_outputs:
        sbom = json.loads(expected_outputs[0].read_text(encoding="utf-8"))
        result(rows, "SPDX JSON structure", sbom.get("spdxVersion") == "SPDX-2.3" and len(sbom.get("packages", [])) >= 2, f"contains {len(sbom.get('packages', []))} packages including the application")

    if (ROOT / ".git").exists():
        git_diff = subprocess.run(["git", "diff", "--check"], cwd=ROOT, text=True, capture_output=True, check=False)
        result(rows, "Whitespace review", git_diff.returncode == 0, "git diff --check passed" if git_diff.returncode == 0 else git_diff.stdout + git_diff.stderr)
    else:
        trailing: list[str] = []
        excluded = {".zip", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".pdf", ".dll", ".pdb", ".md", ".txt", ".csv"}
        for path in ROOT.rglob("*"):
            if not path.is_file() or path.suffix.lower() in excluded or any(part in {"bin", "obj", "__pycache__"} for part in path.parts):
                continue
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (UnicodeDecodeError, OSError):
                continue
            for index, line in enumerate(lines, start=1):
                if line.rstrip(" \t") != line:
                    trailing.append(f"{path.relative_to(ROOT)}:{index}")
                    if len(trailing) >= 20:
                        break
            if len(trailing) >= 20:
                break
        result(rows, "Whitespace review", not trailing, "portable code/config trailing-whitespace scan passed" if not trailing else f"trailing whitespace: {trailing}")

    passed = sum(ok for _, ok, _ in rows)
    failed = len(rows) - passed
    for name, ok, detail in rows:
        print(f"[{'PASS' if ok else 'FAIL'}] {name}: {detail}")
    print(f"\nExecution-phase static checks: {passed} passed; {failed} failed.")
    print("Classification: static analysis only. This tool did not compile .NET, execute SQL, compile Bicep, authenticate with Entra, or deploy Azure.")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
