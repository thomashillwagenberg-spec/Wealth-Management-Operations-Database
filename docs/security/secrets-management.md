# Secrets management

No production secret belongs in Git, Bicep parameter files, workflow YAML, or `appsettings.json`.

- Azure deployment uses GitHub OIDC federation, not a client secret.
- App Service uses managed identity for Azure SQL.
- The Web OIDC secret is referenced from Key Vault in the Bicep template.
- Local secrets belong in user secrets, environment variables, or an uncommitted `.env` file.
- `.env.example` contains placeholders only.
- Key Vault uses RBAC, soft delete, and production purge protection.
- Logs must never include tokens, passwords, connection strings, request bodies, or encryption keys.

A production pipeline should pin GitHub Actions to reviewed commit SHAs and use environment protection rules for staging and production.
