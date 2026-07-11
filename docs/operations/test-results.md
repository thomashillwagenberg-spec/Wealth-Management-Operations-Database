# Test results

**Run date:** July 11, 2026

| Test | Execution method | Result | Evidence | Limitation |
|---|---|---|---|---|
| Original SQL repository checker | Python process | Passed through actual execution: 71 passed, 0 failed | `artifacts/test-results/original-static-check.txt` | Static and deterministic-data checks only |
| Expanded platform checker | Python process | Passed through actual execution: 45 passed, 0 failed | `artifacts/test-results/platform-static-check.txt` | No .NET, SQL, or Bicep engine |
| Execution-phase checker | Python process | Passed through actual execution: 26 passed, 0 failed | `artifacts/test-results/execution-phase-static-check.txt` | Static source and wiring checks only |
| Python tool syntax | `python3 -m py_compile` | Passed through actual execution | `artifacts/test-results/python-syntax.txt` | Does not exercise every runtime branch |
| Shell syntax | `bash -n scripts/*.sh` | Passed through actual execution | `artifacts/test-results/shell-syntax.txt` | Scripts were not operationally run |
| Source dependency inventory | Python SPDX generator | Passed through actual execution | `artifacts/sbom/source-dependency-inventory.spdx.json` | Declared direct dependencies only, not a resolved runtime SBOM |
| Repository whitespace review | `git diff --check` | Passed through actual execution | `artifacts/test-results/whitespace-review.txt` | Reviews source whitespace only |
| JSON, MSBuild XML, YAML | Python parsers | Passed through actual execution | Platform checker output | Not vendor schema or compiler validation |
| C#, Razor, SQL, Bicep structure | Repository static analysis | Passed through static analysis | Platform and execution-phase checker output | Not compilation or engine execution |
| Secret and prohibited-file scan | Repository static analysis | Passed through static analysis | Platform checker output | Not GitHub Advanced Security or a professional secret audit |
| .NET restore | Command attempted | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | `dotnet` unavailable |
| .NET build | Command attempted | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | `dotnet` unavailable |
| .NET unit, integration, architecture, security tests | Command attempted | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | `dotnet` unavailable |
| SQL Server build and database suites | Docker and `sqlcmd` commands attempted | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | Docker, SQL Server, and `sqlcmd` unavailable |
| API and Web startup | Required tool checks attempted | Blocked by missing service, tool, or credential | `environment-capabilities.txt` | .NET and Docker unavailable |
| Bicep build | Azure CLI command attempted | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | Azure CLI and Bicep unavailable |
| Azure what-if and deployment | Command availability attempted; deployment intentionally not run | Blocked by missing service, tool, or credential | `blocked-gate-attempts.txt` | No Azure CLI, credentials, or paid-resource authorization |
| Entra, managed identity, private networking | Not executed | Not executed | Architecture and Bicep source only | Requires deployed Azure environment |
| Backup restore, failover, performance, accessibility, penetration testing | Not executed | Not executed | Runbooks and test plans only | Requires appropriate infrastructure and specialist testing |

See `docs/operations/execution-verification.md` for gate-by-gate details.
