/* Requires an Azure SQL deployment and Entra principals. Not part of local automated tests. */
SELECT name, type_desc, authentication_type_desc FROM sys.database_principals WHERE authentication_type_desc='EXTERNAL';
SELECT name, is_enabled FROM sys.security_policies WHERE name='WealthManagementRowIsolation';
SELECT * FROM sys.sensitivity_classifications;
SELECT TOP(10) * FROM sys.database_firewall_rules;
/* Validate private connectivity from the application environment and verify public network access with Azure Resource Graph or CLI. */
