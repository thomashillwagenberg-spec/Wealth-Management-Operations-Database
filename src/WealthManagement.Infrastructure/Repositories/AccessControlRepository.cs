using System.Data;
using Dapper;
using WealthManagement.Application.Abstractions;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Repositories;

public sealed class AccessControlRepository(ISqlConnectionFactory connectionFactory, Microsoft.Extensions.Options.IOptions<DatabaseOptions> options) : IAccessControlRepository
{
    private readonly int _timeout = options.Value.CommandTimeoutSeconds;

    public Task<bool> CanAccessClientAsync(int clientId, CancellationToken cancellationToken) => ExecuteAsync("security.usp_CanAccessClient", new { ClientId = clientId }, cancellationToken);
    public Task<bool> CanAccessAccountAsync(int accountId, CancellationToken cancellationToken) => ExecuteAsync("security.usp_CanAccessAccount", new { AccountId = accountId }, cancellationToken);
    public Task<bool> CanAccessAdvisorAsync(int advisorId, CancellationToken cancellationToken) => ExecuteAsync("security.usp_CanAccessAdvisor", new { AdvisorId = advisorId }, cancellationToken);

    private async Task<bool> ExecuteAsync(string procedure, object parameters, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return await connection.QuerySingleAsync<bool>(new CommandDefinition(procedure, parameters, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken));
    }
}
