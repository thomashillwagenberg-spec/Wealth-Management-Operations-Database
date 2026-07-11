/*
  Run in SQLCMD mode while connected directly to an empty Azure SQL database named WealthManagementOperations.
  Do not run sql/00_reset_database.sql, sql/01_create_database.sql, or local backup scripts in Azure SQL Database.
*/
:r ..\..\sql\02_create_schemas.sql
:r ..\..\sql\03_create_tables.sql
:r ..\..\sql\04_create_constraints.sql
:r ..\..\sql\05_load_reference_data.sql
:r ..\..\sql\06_load_sample_data.sql
:r ..\..\sql\07_create_views.sql
:r ..\..\sql\08_create_functions.sql
:r ..\..\sql\09_create_procedures.sql
:r ..\..\sql\10_create_indexes.sql
:r ..\..\sql\11_security_setup.sql
:r ..\local\20_application_extensions.sql
:r ..\security\21_identity_and_row_level_security.sql
:r ..\local\22_application_procedures.sql
:r ..\security\23_transaction_immutability_and_permissions.sql
:r ..\security\24_temporal_history.sql
:r .\11_sensitivity_classification.sql
:r ..\tests\20_application_validation.sql
