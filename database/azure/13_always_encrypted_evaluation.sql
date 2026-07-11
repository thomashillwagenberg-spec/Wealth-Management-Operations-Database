/*
  IMPLEMENTATION TEMPLATE, NOT DEPLOYED.

  Candidate: core.Client.Email.
  Do not encrypt account identifiers or numeric portfolio fields without testing joins, filtering, sorting,
  reporting procedures, driver enclave support, key rotation, and operational recovery.

  Provisioning sequence:
  1. Create an RSA-HSM or RSA key in Azure Key Vault with purge protection enabled.
  2. Grant the deployment identity only the required cryptographic permissions.
  3. Create a COLUMN MASTER KEY that references the Key Vault key.
  4. Create a COLUMN ENCRYPTION KEY.
  5. Migrate the candidate column through a controlled maintenance workflow using SqlPackage or SSMS.
  6. Add Column Encryption Setting=Enabled to the authorized application connection.
  7. Run equality, reporting, backup, restore, and key-rotation tests.

  This repository does not fabricate the Key Vault identifiers required by CREATE COLUMN MASTER KEY.
*/
