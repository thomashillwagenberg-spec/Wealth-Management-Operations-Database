/* Execute only after deployment to Azure SQL Database. */
SELECT DB_NAME() AS DatabaseName, DATABASEPROPERTYEX(DB_NAME(),'Edition') AS Edition, DATABASEPROPERTYEX(DB_NAME(),'ServiceObjective') AS ServiceObjective;
SELECT encrypt_option, auth_scheme, client_net_address FROM sys.dm_exec_connections WHERE session_id = @@SPID;
SELECT name, type_desc, authentication_type_desc FROM sys.database_principals WHERE name NOT LIKE '##%' ORDER BY name;
SELECT name, is_enabled FROM sys.security_policies;
SELECT schema_name(t.schema_id) AS SchemaName, t.name AS TableName, t.temporal_type_desc FROM sys.tables WHERE t.temporal_type <> 0;
SELECT COUNT(*) AS SensitivityClassifications FROM sys.sensitivity_classifications;
SELECT TOP (20) EventTime, ActorID, ActionName, EntityType, Outcome, CorrelationID FROM audit.AuditEvent ORDER BY AuditEventID DESC;
GO
