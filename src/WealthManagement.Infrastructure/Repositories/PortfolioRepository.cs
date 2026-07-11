using System.Data;
using Dapper;
using WealthManagement.Application.Abstractions;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Repositories;

public sealed class PortfolioRepository(ISqlConnectionFactory connectionFactory, Microsoft.Extensions.Options.IOptions<DatabaseOptions> options) : IPortfolioRepository
{
    private readonly int _timeout = options.Value.CommandTimeoutSeconds;

    public async Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientSummariesAsync(CancellationToken cancellationToken)
    {
        const string sql = "SELECT ClientID, ClientCode, ClientName, AdvisorID, AdvisorName, AccountCount, TotalCostBasis, TotalPortfolioValue, UnrealizedGainLoss, UnrealizedReturnPct FROM reporting.vw_ClientPortfolioSummary ORDER BY TotalPortfolioValue DESC;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<ClientPortfolioSummaryDto>(new CommandDefinition(sql, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<ClientPortfolioSummaryDto?> GetClientSummaryAsync(int clientId, CancellationToken cancellationToken)
    {
        const string sql = "SELECT ClientID, ClientCode, ClientName, AdvisorID, AdvisorName, AccountCount, TotalCostBasis, TotalPortfolioValue, UnrealizedGainLoss, UnrealizedReturnPct FROM reporting.vw_ClientPortfolioSummary WHERE ClientID = @ClientId;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ClientPortfolioSummaryDto>(new CommandDefinition(sql, new { ClientId = clientId }, commandTimeout: _timeout, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyList<AccountPortfolioValueDto>> GetClientAccountsAsync(int clientId, CancellationToken cancellationToken)
    {
        const string sql = "SELECT AccountID, AccountNumber, ClientID, ClientCode, ClientName, AdvisorID, AdvisorName, TotalCostBasis, PortfolioValue, UnrealizedGainLoss, UnrealizedReturnPct, ValuationDate FROM reporting.vw_AccountPortfolioValue WHERE ClientID = @ClientId ORDER BY PortfolioValue DESC;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<AccountPortfolioValueDto>(new CommandDefinition(sql, new { ClientId = clientId }, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<IReadOnlyList<AssetAllocationDto>> GetAccountAllocationAsync(int accountId, CancellationToken cancellationToken)
    {
        const string sql = "SELECT AccountID, AccountNumber, ClientID, AssetClassID, AssetClassCode, AssetClassName, IsEquityLike, AssetClassValue, AllocationPct FROM reporting.vw_PortfolioAllocation WHERE AccountID = @AccountId ORDER BY AllocationPct DESC;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<AssetAllocationDto>(new CommandDefinition(sql, new { AccountId = accountId }, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAlignmentAsync(bool exceptionsOnly, CancellationToken cancellationToken)
    {
        const string sql = "SELECT ClientID, ClientCode, ClientName, RiskCode, RiskName, MinEquityPct, MaxEquityPct, EquityAllocationPct, AlignmentStatus, DeviationPctPoints FROM reporting.vw_RiskAlignment WHERE @ExceptionsOnly = 0 OR AlignmentStatus <> 'ALIGNED' ORDER BY DeviationPctPoints DESC, ClientID;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<RiskAlignmentDto>(new CommandDefinition(sql, new { ExceptionsOnly = exceptionsOnly }, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId, decimal minimumPct, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<ConcentrationDto>(new CommandDefinition("reporting.usp_GetConcentration", new { AccountId = accountId, MinimumPct = minimumPct }, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<AdvisorActivityDto>(new CommandDefinition("reporting.usp_GetAdvisorActivitySecure", new { AdvisorId = advisorId, StartDate = startDate, EndDate = endDate }, commandType: CommandType.StoredProcedure, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }

    public async Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(bool requiringReviewOnly, CancellationToken cancellationToken)
    {
        const string sql = "SELECT ClientID, ClientCode, ClientName, ReviewCount, OverdueReviewCount, NextOpenReviewDueDate, AlertCount, OpenAlertCount, MaximumAlertSeverity, CAST(RequiresReview AS bit) AS RequiresReview FROM reporting.vw_ComplianceDashboard WHERE @Only = 0 OR RequiresReview = 1 ORDER BY RequiresReview DESC, OverdueReviewCount DESC, OpenAlertCount DESC;";
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        return (await connection.QueryAsync<ComplianceDashboardDto>(new CommandDefinition(sql, new { Only = requiringReviewOnly }, commandTimeout: _timeout, cancellationToken: cancellationToken))).AsList();
    }
}
