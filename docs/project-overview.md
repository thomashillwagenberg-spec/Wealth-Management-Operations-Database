# Project overview

## Purpose

The Wealth Management Operations Database is a hands-on SQL Server portfolio project created by Thomas Wagenberg. It models the operational data needed by a fictional wealth-management firm while remaining understandable to a student learning database work.

## Intended audience

- Hiring managers for finance, operations, audit, compliance, and data roles
- Interviewers evaluating practical SQL ability
- Students learning SQL Server and SSMS
- GitHub reviewers who want to inspect runnable, ordered files

## Business capabilities

The database supports:

1. Client and advisor organization
2. Account and account-type tracking
3. Current risk-profile records
4. Security and historical price storage
5. Transaction capture
6. Current-holding records
7. Portfolio valuation and allocation reporting
8. Risk-alignment analysis
9. Compliance review and alert tracking
10. Basic activity logging and least-privilege access

## Deliverables

- Ordered T-SQL build scripts
- Synthetic CSV files
- Reporting views, functions, and stored procedures
- Index and execution-plan exercise
- Security-role demonstration
- Backup and restore example
- Azure SQL deployment guide
- Formal validation suite
- Fifteen learning modules
- GitHub and LinkedIn launch material
- Screenshot capture plan
- Static review tool and report

## Evidence standard

The repository separates three levels of confidence:

- **Static review completed:** filenames, references, expected data counts, required SQL concepts, and cross-file consistency were checked without a SQL Server engine.
- **Logic review completed:** generated relationships, transaction rules, and holdings quantities were checked in the artifact environment.
- **Execution not yet verified:** SQL Server parsing, permissions, query plans, backup/restore, and Azure deployment must be tested by Thomas in the target environment.

A portfolio claim should never move from “built” to “ran successfully” until the engine-level validation suite actually passes.
