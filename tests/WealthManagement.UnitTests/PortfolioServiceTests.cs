using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Services;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;

namespace WealthManagement.UnitTests;

public sealed class PortfolioServiceTests
{
    [Fact]
    public async Task Concentration_denies_an_unrelated_account()
    {
        var service = new PortfolioService(new EmptyPortfolioRepository(), new ScopedAccessRepository());
        await Assert.ThrowsAsync<AccessDeniedException>(() => service.GetConcentrationsAsync(99, 10m, CancellationToken.None));
    }

    [Fact]
    public async Task Advisor_activity_denies_an_unrelated_advisor()
    {
        var service = new PortfolioService(new EmptyPortfolioRepository(), new ScopedAccessRepository());
        await Assert.ThrowsAsync<AccessDeniedException>(() => service.GetAdvisorActivityAsync(99, new DateOnly(2026,1,1), new DateOnly(2026,7,1), CancellationToken.None));
    }

    [Fact]
    public async Task Advisor_activity_rejects_an_excessive_date_range()
    {
        var service = new PortfolioService(new EmptyPortfolioRepository(), new ScopedAccessRepository());
        await Assert.ThrowsAsync<RequestValidationException>(() => service.GetAdvisorActivityAsync(1, new DateOnly(2024,1,1), new DateOnly(2026,7,1), CancellationToken.None));
    }

    private sealed class ScopedAccessRepository : IAccessControlRepository
    {
        public Task<bool> CanAccessClientAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult(clientId == 1);
        public Task<bool> CanAccessAccountAsync(int accountId, CancellationToken cancellationToken) => Task.FromResult(accountId == 1);
        public Task<bool> CanAccessAdvisorAsync(int advisorId, CancellationToken cancellationToken) => Task.FromResult(advisorId == 1);
    }

    private sealed class EmptyPortfolioRepository : IPortfolioRepository
    {
        public Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientSummariesAsync(CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ClientPortfolioSummaryDto>>([]);
        public Task<ClientPortfolioSummaryDto?> GetClientSummaryAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult<ClientPortfolioSummaryDto?>(null);
        public Task<IReadOnlyList<AccountPortfolioValueDto>> GetClientAccountsAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AccountPortfolioValueDto>>([]);
        public Task<IReadOnlyList<AssetAllocationDto>> GetAccountAllocationAsync(int accountId, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AssetAllocationDto>>([]);
        public Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAlignmentAsync(bool exceptionsOnly, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<RiskAlignmentDto>>([]);
        public Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId, decimal minimumPct, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ConcentrationDto>>([]);
        public Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AdvisorActivityDto>>([]);
        public Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(bool requiringReviewOnly, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ComplianceDashboardDto>>([]);
    }
}
