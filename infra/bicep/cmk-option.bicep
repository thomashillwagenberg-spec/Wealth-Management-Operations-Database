targetScope = 'resourceGroup'
/* Optional customer-managed-key reference architecture. Do not enable before testing rotation and recovery. */
param keyVaultName string
param sqlServerName string
param keyName string = 'sql-tde-key'
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = { name: keyVaultName }
resource key 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: vault
  name: keyName
  properties: { kty: 'RSA-HSM' keySize: 3072 keyOps: ['wrapKey','unwrapKey'] attributes: { enabled: true exportable: false } }
}
/* SQL server key registration and encryption-protector switch require the SQL server identity to receive Key Vault Crypto Service Encryption User. See docs/security/key-management.md. */
output keyUri string = key.properties.keyUriWithVersion
