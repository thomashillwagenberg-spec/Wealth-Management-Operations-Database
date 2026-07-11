using System.Net.Http.Json;
using WealthManagement.Contracts.Audit;
using WealthManagement.Contracts.Common;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;
using WealthManagement.Contracts.Operations;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.Web.Api;

public sealed class WealthManagementApiClient(HttpClient client)
{
    public async Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientsAsync(CancellationToken ct = default) => await client.GetFromJsonAsync<List<ClientPortfolioSummaryDto>>("/api/portfolios/clients", ct) ?? [];
    public async Task<ClientPortfolioEnvelope?> GetClientAsync(int clientId, CancellationToken ct = default) => await client.GetFromJsonAsync<ClientPortfolioEnvelope>($"/api/portfolios/clients/{clientId}", ct);
    public async Task<IReadOnlyList<AssetAllocationDto>> GetAllocationAsync(int accountId, CancellationToken ct = default) => await client.GetFromJsonAsync<List<AssetAllocationDto>>($"/api/portfolios/accounts/{accountId}/allocation", ct) ?? [];
    public async Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAsync(bool exceptionsOnly = true, CancellationToken ct = default) => await client.GetFromJsonAsync<List<RiskAlignmentDto>>($"/api/portfolios/risk?exceptionsOnly={exceptionsOnly}", ct) ?? [];
    public async Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId = null, decimal minimumPct = 10m, CancellationToken ct = default)
    {
        var accountPart = accountId.HasValue ? $"&accountId={accountId.Value}" : string.Empty;
        return await client.GetFromJsonAsync<List<ConcentrationDto>>($"/api/portfolios/concentration?minimumPct={minimumPct.ToString(System.Globalization.CultureInfo.InvariantCulture)}{accountPart}", ct) ?? [];
    }
    public async Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken ct = default) =>
        await client.GetFromJsonAsync<List<AdvisorActivityDto>>($"/api/portfolios/advisor/{advisorId}/activity?startDate={startDate:yyyy-MM-dd}&endDate={endDate:yyyy-MM-dd}", ct) ?? [];
    public async Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(CancellationToken ct = default) => await client.GetFromJsonAsync<List<ComplianceDashboardDto>>("/api/portfolios/compliance-dashboard?requiringReviewOnly=true", ct) ?? [];
    public async Task<VersionDto?> GetVersionAsync(CancellationToken ct = default) => await client.GetFromJsonAsync<VersionDto>("/api/version", ct);
    public async Task<HealthSummaryDto?> GetHealthAsync(CancellationToken ct = default)
    {
        using var response = await client.GetAsync("/api/operations/health", ct);
        return await response.Content.ReadFromJsonAsync<HealthSummaryDto>(cancellationToken: ct);
    }
    public async Task<PagedResult<ComplianceAlertDto>?> GetAlertsAsync(int page = 1, int pageSize = 25, string? status = null, CancellationToken ct = default) => await client.GetFromJsonAsync<PagedResult<ComplianceAlertDto>>($"/api/compliance/alerts?page={page}&pageSize={pageSize}&status={Uri.EscapeDataString(status ?? string.Empty)}", ct);
    public async Task<PagedResult<AuditEventDto>?> GetAuditAsync(int page = 1, CancellationToken ct = default) => await client.GetFromJsonAsync<PagedResult<AuditEventDto>>($"/api/audit/events?page={page}&pageSize=50", ct);
    public async Task<UpdateComplianceAlertResponse?> UpdateAlertAsync(long alertId, UpdateComplianceAlertRequest request, CancellationToken ct = default)
    {
        using var response = await client.PutAsJsonAsync($"/api/compliance/alerts/{alertId}/status", request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<UpdateComplianceAlertResponse>(cancellationToken: ct);
    }
    public async Task<SubmitTradeResponse?> SubmitTradeAsync(SubmitTradeRequest request, CancellationToken ct = default)
    {
        using var message = new HttpRequestMessage(HttpMethod.Post, "/api/trades") { Content = JsonContent.Create(request) };
        message.Headers.TryAddWithoutValidation("Idempotency-Key", request.IdempotencyKey);
        using var response = await client.SendAsync(message, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<SubmitTradeResponse>(cancellationToken: ct);
    }
}

public sealed record ClientPortfolioEnvelope(ClientPortfolioSummaryDto Client, IReadOnlyList<AccountPortfolioValueDto> Accounts);
