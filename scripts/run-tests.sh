#!/usr/bin/env bash
set -euo pipefail
python3 tools/static_check.py
python3 tools/platform_static_check.py
python3 tools/generate_source_sbom.py
python3 tools/execution_phase_check.py
dotnet restore WealthManagement.slnx
dotnet build WealthManagement.slnx -c Release --no-restore
dotnet test WealthManagement.slnx -c Release --no-build --collect:'XPlat Code Coverage'
