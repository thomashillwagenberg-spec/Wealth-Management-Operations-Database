$ErrorActionPreference = 'Stop'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker is required.' }
if (-not (Test-Path .env)) { throw 'Copy .env.example to .env and set a strong local password.' }
Get-Content .env | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}
docker compose up -d sqlserver
$health = ''
for ($i = 0; $i -lt 30; $i++) {
    $health = docker inspect --format='{{.State.Health.Status}}' wm-sqlserver 2>$null
    if ($health -eq 'healthy') { break }
    Start-Sleep -Seconds 3
}
if ($health -ne 'healthy') {
    docker logs wm-sqlserver
    throw 'SQL Server did not become healthy.'
}
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    throw 'Git Bash or WSL bash is required to run scripts/init-database.sh from Windows.'
}
& bash ./scripts/init-database.sh
Write-Host 'Database ready.'
Write-Host 'dotnet run --project src/WealthManagement.Api'
Write-Host 'dotnet run --project src/WealthManagement.Web'
