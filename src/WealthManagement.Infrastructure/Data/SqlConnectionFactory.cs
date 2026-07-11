using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using WealthManagement.Application.Abstractions;

namespace WealthManagement.Infrastructure.Data;

public sealed class SqlConnectionFactory(
    IConfiguration configuration,
    IOptions<DatabaseOptions> options,
    ICurrentUserContext currentUser) : ISqlConnectionFactory
{
    private readonly DatabaseOptions _options = options.Value;

    public async Task<SqlConnection> OpenAsync(CancellationToken cancellationToken)
    {
        if (!currentUser.IsAuthenticated) throw new UnauthorizedAccessException("An authenticated user is required to open an application database session.");
        var connection = await OpenCoreAsync(cancellationToken);
        try
        {
            var command = new CommandDefinition(
                "security.usp_SetExecutionContext",
                new
                {
                    EntraObjectId = Guid.TryParse(currentUser.UserId, out var objectId) ? objectId : (Guid?)null,
                    UserPrincipalName = currentUser.UserId,
                    CorrelationId = currentUser.CorrelationId
                },
                commandType: CommandType.StoredProcedure,
                commandTimeout: _options.CommandTimeoutSeconds,
                cancellationToken: cancellationToken);
            await connection.ExecuteAsync(command);
            return connection;
        }
        catch
        {
            await connection.DisposeAsync();
            throw;
        }
    }


    private async Task<SqlConnection> OpenCoreAsync(CancellationToken cancellationToken)
    {
        var connectionString = configuration.GetConnectionString(_options.ConnectionStringName);
        if (string.IsNullOrWhiteSpace(connectionString)) throw new InvalidOperationException($"Connection string '{_options.ConnectionStringName}' is not configured.");
        var builder = new SqlConnectionStringBuilder(connectionString)
        {
            ConnectTimeout = Math.Clamp(new SqlConnectionStringBuilder(connectionString).ConnectTimeout, 5, 30)
        };
        if (_options.RequireEncryptedConnection)
        {
            builder.Encrypt = SqlConnectionEncryptOption.Mandatory;
            builder.TrustServerCertificate = false;
        }
        var connection = new SqlConnection(builder.ConnectionString);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }
}
