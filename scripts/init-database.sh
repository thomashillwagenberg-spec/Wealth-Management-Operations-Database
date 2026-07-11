#!/usr/bin/env bash
set -euo pipefail
: "${MSSQL_SA_PASSWORD:?Set MSSQL_SA_PASSWORD in the environment or an uncommitted .env file}"
: "${WM_APP_PASSWORD:?Set WM_APP_PASSWORD in the environment or an uncommitted .env file}"
wm_app_password_hex="$(printf %s "$WM_APP_PASSWORD" | od -An -tx1 | tr -d ' \n')"
container="${WM_SQL_CONTAINER:-wm-sqlserver}"
sqlcmd='if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then /opt/mssql-tools18/bin/sqlcmd; else /opt/mssql-tools/bin/sqlcmd; fi'
run_file() {
  local file="$1"
  echo "Running $file"
  if [[ "$file" == "database/local/25_create_local_application_login.sql" ]]; then
    docker exec -e SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" -e WM_APP_PASSWORD_HEX="$wm_app_password_hex" "$container" bash -lc "$sqlcmd -S localhost -U sa -C -b -i /workspace/$file"
  else
    docker exec -e SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" "$container" bash -lc "$sqlcmd -S localhost -U sa -C -b -i /workspace/$file"
  fi
}
for file in sql/00_reset_database.sql sql/01_create_database.sql sql/02_create_schemas.sql sql/03_create_tables.sql sql/04_create_constraints.sql sql/05_load_reference_data.sql sql/06_load_sample_data.sql sql/07_create_views.sql sql/08_create_functions.sql sql/09_create_procedures.sql sql/10_create_indexes.sql sql/11_security_setup.sql sql/13_validation_tests.sql database/local/20_application_extensions.sql database/security/21_identity_and_row_level_security.sql database/local/22_application_procedures.sql database/security/23_transaction_immutability_and_permissions.sql database/security/24_temporal_history.sql database/local/25_create_local_application_login.sql database/tests/20_application_validation.sql; do
  run_file "$file"
done
