/*
  25_create_local_application_login.sql
  Purpose: Create a least-privilege SQL login for local application mode.
  The password is supplied as a hex-encoded SQLCMD environment variable by scripts/init-database.sh.
  Azure uses managed identity instead of this local-only login.
*/
:setvar WM_APP_LOGIN "wm_application"
USE master;
GO
SET NOCOUNT ON;
GO
DECLARE @PasswordHex varchar(512) = '$(WM_APP_PASSWORD_HEX)';
IF @PasswordHex = '$(WM_APP_PASSWORD_HEX)' OR LEN(@PasswordHex) < 24 OR @PasswordHex LIKE '%[^0-9A-Fa-f]%'
    THROW 52300, 'WM_APP_PASSWORD_HEX must contain a sufficiently long hex-encoded local password.', 1;

DECLARE @Password varchar(128) = CONVERT(varchar(128), CONVERT(varbinary(256), @PasswordHex, 2));
DECLARE @LoginName sysname = N'$(WM_APP_LOGIN)';
DECLARE @Sql nvarchar(max);

IF SUSER_ID(@LoginName) IS NULL
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@LoginName) + N' WITH PASSWORD = ' + QUOTENAME(@Password,'''') + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @Sql;
END
ELSE
BEGIN
    SET @Sql = N'ALTER LOGIN ' + QUOTENAME(@LoginName) + N' WITH PASSWORD = ' + QUOTENAME(@Password,'''') + N';';
    EXEC sys.sp_executesql @Sql;
END;
GO
USE WealthManagementOperations;
GO
IF DATABASE_PRINCIPAL_ID(N'wm_application') IS NULL CREATE USER wm_application FOR LOGIN wm_application;
IF NOT EXISTS
(
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals r ON r.principal_id=drm.role_principal_id
    JOIN sys.database_principals m ON m.principal_id=drm.member_principal_id
    WHERE r.name=N'WealthManagementApplication' AND m.name=N'wm_application'
)
    ALTER ROLE WealthManagementApplication ADD MEMBER wm_application;
GO
PRINT N'Local least-privilege application login created or updated.';
GO
