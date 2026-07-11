# Key and certificate rotation

## Key Vault secrets

1. Create a new secret version.
2. Validate application access in staging.
3. restart or refresh App Service references.
4. Observe authentication and dependency telemetry.
5. retire the previous version after the approved overlap window.

## Customer-managed TDE key option

`infra/bicep/cmk-option.bicep` creates the Key Vault key only. Before switching Azure SQL encryption protection, grant the SQL server identity the minimum cryptographic role, back up key material according to policy, test rotation and recovery, and document a break-glass owner. A disabled or deleted key can make a database unavailable.

## Always Encrypted

Column master key and column encryption key provisioning is intentionally not fabricated. Follow `database/azure/13_always_encrypted_evaluation.sql`, validate driver behavior, and test key recovery before enabling it.
