$ErrorActionPreference = 'Stop'
python tools/static_check.py
python tools/platform_static_check.py
python tools/generate_source_sbom.py
python tools/execution_phase_check.py
dotnet restore WealthManagement.slnx
dotnet build WealthManagement.slnx -c Release --no-restore
dotnet test WealthManagement.slnx -c Release --no-build --collect:'XPlat Code Coverage'
