using System.Data;
using Dapper;
using WealthManagement.Application.Abstractions;
using WealthManagement.Contracts.Audit;
using WealthManagement.Contracts.Common;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Repositories;

public sealed class AuditRepository(ISqlConnectionFactory connectionFactory, Microsoft.Extensions.Options.IOptions<DatabaseOptions> options) : IAuditRepository
{
    private readonly int _timeout = options.Value.CommandTimeoutSeconds;

    public async Task<PagedResult<AuditEventDto>> GetEventsAsync(AuditEventQuery query, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        var rows = (await connection.QueryAsync<AuditRow>(new CommandDefinition("audit.usp_GetAuditEvents", new { query.Page, query.PageSize, query.ActorId, query.ActionName, query.EntityType, query.FromUtc, query.ToUtc }, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
        var total = rows.Count == 0 ? 0 : rows[0].TotalCount;
        return new(rows.Select(x => x.ToDto()).ToList(), query.Page, query.PageSize, total);
    }

    private sealed record AuditRow(long AuditEventId, DateTime EventTime, string ActorId, string ActionName, string EntityType, string? EntityId, string Outcome, Guid CorrelationId, string? MetadataJson, long TotalCount)
    {
        public AuditEventDto ToDto() => new(AuditEventId, EventTime, ActorId, ActionName, EntityType, EntityId, Outcome, CorrelationId, MetadataJson);
    }
}
