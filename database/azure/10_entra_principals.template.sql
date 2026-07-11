/*
  TEMPLATE ONLY. Replace bracketed names after Azure deployment and execute as an Entra administrator.
  No password-based database user is created.
*/
CREATE USER [<app-service-managed-identity-name>] FROM EXTERNAL PROVIDER;
ALTER ROLE WealthManagementApplication ADD MEMBER [<app-service-managed-identity-name>];

/* Optional operational groups. Prefer Entra security groups over individual users. */
CREATE USER [<database-admin-entra-group>] FROM EXTERNAL PROVIDER;
ALTER ROLE DatabaseAdministrator ADD MEMBER [<database-admin-entra-group>];

CREATE USER [<auditor-entra-group>] FROM EXTERNAL PROVIDER;
ALTER ROLE ReadOnlyAuditor ADD MEMBER [<auditor-entra-group>];
