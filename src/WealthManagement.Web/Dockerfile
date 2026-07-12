FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore WealthManagement.slnx
RUN dotnet publish src/WealthManagement.Web/WealthManagement.Web.csproj -c Release -o /app/publish --no-restore

# Chiseled variant: no shell, no package manager, minimal OS surface; -extra includes ICU for globalization
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled-extra AS final
WORKDIR /app
COPY --from=build /app/publish .
# Chiseled images run as the built-in non-root 'app' user by default
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "WealthManagement.Web.dll"]
