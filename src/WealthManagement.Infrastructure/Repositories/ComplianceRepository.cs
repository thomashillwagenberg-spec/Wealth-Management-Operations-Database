using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Common;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Repositories;

public sealed class ComplianceRepository(ISqlConnectionFactory connectionFactory, Microsoft.Extensions.Options.IOptions<DatabaseOptions> options) : IComplianceRepository
{
    private readonly int _timeout = options.Value.CommandTimeoutSeconds;

    public async Task<PagedResult<ComplianceAlertDto>> GetAlertsAsync(ComplianceAlertQuery query, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        var rows = (await connection.QueryAsync<AlertRow>(new CommandDefinition("compliance.usp_ListAlerts", new { query.Page, query.PageSize, query.Status, query.Severity, query.ClientId }, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
        var total = rows.Count == 0 ? 0 : rows[0].TotalCount;
        return new(rows.Select(r => r.ToDto()).ToList(), query.Page, query.PageSize, total);
    }

    public async Task<UpdateComplianceAlertResponse> UpdateAlertAsync(long alertId, UpdateComplianceAlertRequest request, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        try
        {
            var row = await connection.QuerySingleAsync<UpdateAlertRow>(new CommandDefinition("compliance.usp_UpdateAlertStatusSecure", new { ComplianceAlertId = alertId, request.NewStatus, request.ResolutionNote, ExpectedRowVersion = Convert.FromBase64String(request.ExpectedRowVersion) }, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken));
            return row.ToDto();
        }
        catch (SqlException ex) when (ex.Number == 52122)
        {
            throw new ConcurrencyConflictException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 52121)
        {
            throw new ResourceNotFoundException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 52123)
        {
            throw new AccessDeniedException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 52124)
        {
            throw new BusinessRuleException(ex.Message);
        }
    }

    private sealed record UpdateAlertRow(long ComplianceAlertId, string AlertStatus, DateOnly? ResolvedDate, DateTime ModifiedAt, byte[] RowVersion, Guid CorrelationId)
    {
        public UpdateComplianceAlertResponse ToDto() => new(ComplianceAlertId, AlertStatus, ResolvedDate, ModifiedAt, Convert.ToBase64String(RowVersion), CorrelationId);
    }

    private sealed record AlertRow(long ComplianceAlertId, int ClientId, string ClientCode, string ClientName, int? AccountId, string? AccountNumber, long? TransactionId, string AlertType, string Severity, string AlertStatus, DateOnly AlertDate, DateOnly? ResolvedDate, string Description, DateTime ModifiedAt, byte[] RowVersion, long TotalCount)
    {
        public ComplianceAlertDto ToDto() => new(ComplianceAlertId, ClientId, ClientCode, ClientName, AccountId, AccountNumber, TransactionId, AlertType, Severity, AlertStatus, AlertDate, ResolvedDate, Description, ModifiedAt, Convert.ToBase64String(RowVersion));
    }
}
