using WealthManagement.Contracts.Audit;
using WealthManagement.Contracts.Common;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.Application.Abstractions;

public interface IPortfolioRepository
{
    Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientSummariesAsync(CancellationToken cancellationToken);
    Task<ClientPortfolioSummaryDto?> GetClientSummaryAsync(int clientId, CancellationToken cancellationToken);
    Task<IReadOnlyList<AccountPortfolioValueDto>> GetClientAccountsAsync(int clientId, CancellationToken cancellationToken);
    Task<IReadOnlyList<AssetAllocationDto>> GetAccountAllocationAsync(int accountId, CancellationToken cancellationToken);
    Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAlignmentAsync(bool exceptionsOnly, CancellationToken cancellationToken);
    Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId, decimal minimumPct, CancellationToken cancellationToken);
    Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken);
    Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(bool requiringReviewOnly, CancellationToken cancellationToken);
}

public interface ITradeRepository
{
    Task<SubmitTradeResponse> SubmitAsync(SubmitTradeRequest request, string requestHash, CancellationToken cancellationToken);
}

public interface IComplianceRepository
{
    Task<PagedResult<ComplianceAlertDto>> GetAlertsAsync(ComplianceAlertQuery query, CancellationToken cancellationToken);
    Task<UpdateComplianceAlertResponse> UpdateAlertAsync(long alertId, UpdateComplianceAlertRequest request, CancellationToken cancellationToken);
}

public interface IAuditRepository
{
    Task<PagedResult<AuditEventDto>> GetEventsAsync(AuditEventQuery query, CancellationToken cancellationToken);
}

public interface IAccessControlRepository
{
    Task<bool> CanAccessClientAsync(int clientId, CancellationToken cancellationToken);
    Task<bool> CanAccessAccountAsync(int accountId, CancellationToken cancellationToken);
    Task<bool> CanAccessAdvisorAsync(int advisorId, CancellationToken cancellationToken);
}
