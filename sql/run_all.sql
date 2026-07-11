
/*
  run_all.sql
  Purpose: SQLCMD-mode master build script.
  Instructions:
    1. Open this file in SSMS from inside the sql folder.
    2. Select Query > SQLCMD Mode.
    3. Execute the script.
  Warning: The first script drops the training database for a clean rebuild.
*/
:On Error exit
:r .\00_reset_database.sql
:r .\01_create_database.sql
:r .\02_create_schemas.sql
:r .\03_create_tables.sql
:r .\04_create_constraints.sql
:r .\05_load_reference_data.sql
:r .\06_load_sample_data.sql
:r .\07_create_views.sql
:r .\08_create_functions.sql
:r .\09_create_procedures.sql
:r .\10_create_indexes.sql
:r .\11_security_setup.sql
:r .\13_validation_tests.sql

PRINT N'Build and validation sequence finished. Run 12_analysis_queries.sql and 15_master_demo.sql separately for presentation.';
GO
