# ADR-003: Local hash-chained audit and optional Azure SQL ledger

**Status:** Accepted with optional enhancement

The cross-platform application extension uses an append-only audit table with a SHA-256 hash chain and serialized insertion. Azure SQL Ledger is provided as an optional Azure-only table because feature support, digest storage, operational review, and migration require deployment-specific decisions. A hash chain detects changes only when hashes are independently protected and verified.
