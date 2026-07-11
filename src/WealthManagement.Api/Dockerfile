FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore WealthManagement.slnx --locked-mode=false
RUN dotnet publish src/WealthManagement.Api/WealthManagement.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
# Built-in non-root user shipped with the .NET 8+ runtime images
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "WealthManagement.Api.dll"]
