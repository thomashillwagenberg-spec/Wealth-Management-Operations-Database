/* Run in SSMS SQLCMD mode after the original sql/run_all.sql completes. */
:r .\20_application_extensions.sql
:r ..\security\21_identity_and_row_level_security.sql
:r .\22_application_procedures.sql
:r ..\security\23_transaction_immutability_and_permissions.sql
:r ..\security\24_temporal_history.sql
:r ..\tests\20_application_validation.sql
