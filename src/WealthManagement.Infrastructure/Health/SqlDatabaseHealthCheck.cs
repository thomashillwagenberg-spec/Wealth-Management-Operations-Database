using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Health;

public sealed class SqlDatabaseHealthCheck(IConfiguration configuration, IOptions<DatabaseOptions> options) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var databaseOptions = options.Value;
            var connectionString = configuration.GetConnectionString(databaseOptions.ConnectionStringName);
            if (string.IsNullOrWhiteSpace(connectionString))
                return HealthCheckResult.Unhealthy($"Connection string '{databaseOptions.ConnectionStringName}' is not configured.");

            var builder = new SqlConnectionStringBuilder(connectionString)
            {
                ConnectTimeout = Math.Clamp(new SqlConnectionStringBuilder(connectionString).ConnectTimeout, 5, 15)
            };
            if (databaseOptions.RequireEncryptedConnection)
            {
                builder.Encrypt = SqlConnectionEncryptOption.Mandatory;
                builder.TrustServerCertificate = false;
            }

            await using var connection = new SqlConnection(builder.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            var value = await connection.ExecuteScalarAsync<int>(new CommandDefinition("SELECT 1;", cancellationToken: cancellationToken));
            return value == 1 ? HealthCheckResult.Healthy("Azure SQL or SQL Server connectivity succeeded.") : HealthCheckResult.Unhealthy("Unexpected database probe result.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database connectivity failed.", ex);
        }
    }
}
