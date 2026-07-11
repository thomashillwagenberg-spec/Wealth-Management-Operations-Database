#!/usr/bin/env bash
set -euo pipefail
command -v docker >/dev/null || { echo 'Docker is required.'; exit 1; }
[ -f .env ] || { echo 'Copy .env.example to .env and set a strong local password.'; exit 1; }
set -a; source .env; set +a
docker compose up -d sqlserver
for _ in {1..30}; do
  if docker inspect --format='{{.State.Health.Status}}' wm-sqlserver 2>/dev/null | grep -q healthy; then break; fi
  sleep 3
done
if ! docker inspect --format='{{.State.Health.Status}}' wm-sqlserver 2>/dev/null | grep -q healthy; then
  docker logs wm-sqlserver || true
  echo 'SQL Server did not become healthy.' >&2
  exit 1
fi
./scripts/init-database.sh
printf '\nDatabase ready. Start the API and web app with:\n'
printf 'dotnet run --project src/WealthManagement.Api\n'
printf 'dotnet run --project src/WealthManagement.Web\n'
