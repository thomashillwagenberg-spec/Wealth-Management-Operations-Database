using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using WealthManagement.Application.Abstractions;
using WealthManagement.Contracts.Audit;
using WealthManagement.Contracts.Common;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.SecurityTests;

public sealed class SecurityBoundaryTests : IClassFixture<SecurityApplicationFactory>
{
    private static readonly HttpStatusCode[] HealthStatuses = [HttpStatusCode.OK, HttpStatusCode.ServiceUnavailable];
    private readonly SecurityApplicationFactory _factory;
    public SecurityBoundaryTests(SecurityApplicationFactory factory) => _factory = factory;

    [Fact]
    public async Task Anonymous_portfolio_request_is_rejected()
    {
        using var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/portfolios/clients");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Authenticated_advisor_can_use_curated_portfolio_endpoint()
    {
        using var client = AdvisorClient();
        var response = await client.GetAsync("/api/portfolios/clients");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Advisor_cannot_retrieve_an_unrelated_client()
    {
        using var client = AdvisorClient();
        var response = await client.GetAsync("/api/portfolios/clients/99");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Compliance_user_cannot_read_audit_events()
    {
        using var client = RoleClient("compliance@local.test");
        var response = await client.GetAsync("/api/audit/events?page=1&pageSize=10");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_cannot_submit_a_trade()
    {
        using var client = RoleClient("auditor@local.test");
        var request = new SubmitTradeRequest(1,"BUY",1,new DateOnly(2026,7,10),new DateOnly(2026,7,11),1,100,0,"SEC-001","security-test-key-0001",null);
        var response = await client.PostAsJsonAsync("/api/trades", request);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Client_supplied_role_data_does_not_authenticate_an_anonymous_request()
    {
        using var client = _factory.CreateClient();
        var body = new { accountId=1, transactionTypeCode="BUY", securityId=1, tradeDate="2026-07-10", settlementDate="2026-07-11", quantity=1, price=100, feeAmount=0, externalReference="SEC-002", idempotencyKey="security-test-key-0002", roles=new[]{"DatabaseAdministrator"} };
        var response = await client.PostAsJsonAsync("/api/trades", body);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }


    [Fact]
    public async Task Client_supplied_development_role_header_cannot_escalate_privilege()
    {
        using var client = AdvisorClient();
        client.DefaultRequestHeaders.Add("X-Dev-Roles", "DatabaseAdministrator,ReadOnlyAuditor");
        var response = await client.GetAsync("/api/audit/events?page=1&pageSize=10");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Injection_shaped_external_reference_is_rejected_as_validation_error()
    {
        using var client = AdvisorClient();
        var request = new SubmitTradeRequest(1,"BUY",1,new DateOnly(2026,7,10),new DateOnly(2026,7,11),1,100,0,"X';DROP_TABLE","security-test-key-injection",null);
        var response = await client.PostAsJsonAsync("/api/trades", request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("validation_failed", body, StringComparison.Ordinal);
        Assert.DoesNotContain("DROP TABLE", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Trade_endpoint_enforces_per_identity_rate_limit()
    {
        using var client = RoleClient("advisor1@local.test");
        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 11; i++)
        {
            var request = new SubmitTradeRequest(1,"BUY",1,new DateOnly(2026,7,10),new DateOnly(2026,7,11),1,100,0,$"RATE-{i:00}",$"security-rate-key-{i:0000}",null);
            statuses.Add((await client.PostAsJsonAsync("/api/trades", request)).StatusCode);
        }
        Assert.Contains(HttpStatusCode.TooManyRequests, statuses);
    }

    [Fact]
    public async Task Reporting_user_cannot_open_raw_compliance_workflow()
    {
        using var client = RoleClient("reporting@local.test");
        var response = await client.GetAsync("/api/compliance/alerts?page=1&pageSize=25");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_cannot_update_or_delete_compliance_history()
    {
        using var client = RoleClient("auditor@local.test");
        var update = new UpdateComplianceAlertRequest("RESOLVED", "Not permitted", Convert.ToBase64String(new byte[8]));
        var put = await client.PutAsJsonAsync("/api/compliance/alerts/1/status", update);
        var delete = await client.DeleteAsync("/api/compliance/alerts/1");
        Assert.Equal(HttpStatusCode.Forbidden, put.StatusCode);
        // No delete route exists anywhere under /api/compliance: unmatched routes return 404,
        // which proves the deletion surface is absent rather than merely forbidden.
        Assert.Equal(HttpStatusCode.NotFound, delete.StatusCode);
    }

    [Fact]
    public async Task Compliance_pagination_limit_is_enforced()
    {
        using var client = RoleClient("compliance@local.test");
        var response = await client.GetAsync("/api/compliance/alerts?page=1&pageSize=101");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Stale_row_version_returns_problem_details_conflict()
    {
        using var client = RoleClient("compliance@local.test");
        var request = new UpdateComplianceAlertRequest("RESOLVED", "Synthetic conflict", Convert.ToBase64String(new byte[8]));
        var response = await client.PutAsJsonAsync("/api/compliance/alerts/1/status", request);
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("concurrency_conflict", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Readiness_requires_authentication_but_auditor_can_read_audit_metadata()
    {
        using var anonymous = _factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/health/ready")).StatusCode);
        using var auditor = RoleClient("auditor@local.test");
        Assert.Equal(HttpStatusCode.OK, (await auditor.GetAsync("/api/audit/events?page=1&pageSize=10")).StatusCode);
    }

    [Fact]
    public async Task Advisor_cannot_query_an_unrelated_account_concentration()
    {
        using var client = AdvisorClient();
        var response = await client.GetAsync("/api/portfolios/concentration?accountId=99&minimumPct=10");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Advisor_cannot_query_an_unrelated_advisor_activity()
    {
        using var client = AdvisorClient();
        var response = await client.GetAsync("/api/portfolios/advisor/99/activity?startDate=2026-01-01&endDate=2026-07-01");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Authenticated_user_can_read_version_and_structured_health()
    {
        using var client = AdvisorClient();
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/version")).StatusCode);
        var health = await client.GetAsync("/api/operations/health");
        Assert.Contains(health.StatusCode, HealthStatuses);
    }

    [Fact]
    public async Task Liveness_endpoint_is_available_without_authentication()
    {
        using var client = _factory.CreateClient();
        var response = await client.GetAsync("/health/live");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private HttpClient AdvisorClient()
    {
        var client = RoleClient("advisor1@local.test");
        return client;
    }

    private HttpClient RoleClient(string user)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Dev-User", user);
        return client;
    }
}

public sealed class SecurityApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<IPortfolioRepository>();
            services.RemoveAll<ITradeRepository>();
            services.RemoveAll<IComplianceRepository>();
            services.RemoveAll<IAuditRepository>();
            services.RemoveAll<IAccessControlRepository>();
            services.AddSingleton<IPortfolioRepository, FakePortfolioRepository>();
            services.AddSingleton<ITradeRepository, FakeTradeRepository>();
            services.AddSingleton<IComplianceRepository, FakeComplianceRepository>();
            services.AddSingleton<IAuditRepository, FakeAuditRepository>();
            services.AddSingleton<IAccessControlRepository, FakeAccessRepository>();
        });
    }
}

file sealed class FakeAccessRepository : IAccessControlRepository
{
    public Task<bool> CanAccessClientAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult(clientId != 99);
    public Task<bool> CanAccessAccountAsync(int accountId, CancellationToken cancellationToken) => Task.FromResult(accountId != 99);
    public Task<bool> CanAccessAdvisorAsync(int advisorId, CancellationToken cancellationToken) => Task.FromResult(advisorId != 99);
}

file sealed class FakePortfolioRepository : IPortfolioRepository
{
    private static readonly ClientPortfolioSummaryDto Client = new(1,"CL-001","Synthetic Client",1,"Synthetic Advisor",1,1000,1100,100,10);
    public Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientSummariesAsync(CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ClientPortfolioSummaryDto>>([Client]);
    public Task<ClientPortfolioSummaryDto?> GetClientSummaryAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult<ClientPortfolioSummaryDto?>(clientId == 1 ? Client : null);
    public Task<IReadOnlyList<AccountPortfolioValueDto>> GetClientAccountsAsync(int clientId, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AccountPortfolioValueDto>>([]);
    public Task<IReadOnlyList<AssetAllocationDto>> GetAccountAllocationAsync(int accountId, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AssetAllocationDto>>([]);
    public Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAlignmentAsync(bool exceptionsOnly, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<RiskAlignmentDto>>([]);
    public Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId, decimal minimumPct, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ConcentrationDto>>([]);
    public Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<AdvisorActivityDto>>([]);
    public Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(bool requiringReviewOnly, CancellationToken cancellationToken) => Task.FromResult<IReadOnlyList<ComplianceDashboardDto>>([]);
}

file sealed class FakeTradeRepository : ITradeRepository
{
    public Task<SubmitTradeResponse> SubmitAsync(SubmitTradeRequest request, string requestHash, CancellationToken cancellationToken) => Task.FromResult(new SubmitTradeResponse(1,Guid.NewGuid(),false,"Synthetic trade recorded."));
}

file sealed class FakeComplianceRepository : IComplianceRepository
{
    public Task<PagedResult<ComplianceAlertDto>> GetAlertsAsync(ComplianceAlertQuery query, CancellationToken cancellationToken) => Task.FromResult(new PagedResult<ComplianceAlertDto>([],query.Page,query.PageSize,0));
    public Task<UpdateComplianceAlertResponse> UpdateAlertAsync(long alertId, UpdateComplianceAlertRequest request, CancellationToken cancellationToken)
    {
        if (request.ExpectedRowVersion == Convert.ToBase64String(new byte[8]))
            throw new WealthManagement.Application.Validation.ConcurrencyConflictException("The alert changed after it was read.");
        return Task.FromResult(new UpdateComplianceAlertResponse(alertId,request.NewStatus,null,DateTime.UtcNow,Convert.ToBase64String(new byte[8]),Guid.NewGuid()));
    }
}

file sealed class FakeAuditRepository : IAuditRepository
{
    public Task<PagedResult<AuditEventDto>> GetEventsAsync(AuditEventQuery query, CancellationToken cancellationToken) => Task.FromResult(new PagedResult<AuditEventDto>([],query.Page,query.PageSize,0));
}
