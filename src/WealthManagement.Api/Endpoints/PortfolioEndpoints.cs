using WealthManagement.Api.Authorization;
using WealthManagement.Application.Services;

namespace WealthManagement.Api.Endpoints;

public static class PortfolioEndpoints
{
    public static IEndpointRouteBuilder MapPortfolioEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/portfolios").RequireAuthorization(PolicyNames.PortfolioRead).WithTags("Portfolio reporting");
        group.MapGet("/clients", (PortfolioService service, CancellationToken ct) => service.GetClientsAsync(ct));
        group.MapGet("/clients/{clientId:int}", async (int clientId, PortfolioService service, CancellationToken ct) =>
        {
            var result = await service.GetClientAsync(clientId, ct);
            return Results.Ok(new { result.Client, result.Accounts });
        });
        group.MapGet("/accounts/{accountId:int}/allocation", (int accountId, PortfolioService service, CancellationToken ct) => service.GetAllocationAsync(accountId, ct));
        group.MapGet("/risk", (bool exceptionsOnly, PortfolioService service, CancellationToken ct) => service.GetRiskAsync(exceptionsOnly, ct));
        group.MapGet("/concentration", (int? accountId, decimal? minimumPct, PortfolioService service, CancellationToken ct) => service.GetConcentrationsAsync(accountId, minimumPct ?? 10m, ct));
        group.MapGet("/advisor/{advisorId:int}/activity", (int advisorId, DateOnly? startDate, DateOnly? endDate, PortfolioService service, CancellationToken ct) =>
        {
            var effectiveEnd = endDate ?? DateOnly.FromDateTime(DateTime.UtcNow);
            var effectiveStart = startDate ?? effectiveEnd.AddMonths(-12);
            return service.GetAdvisorActivityAsync(advisorId, effectiveStart, effectiveEnd, ct);
        });
        group.MapGet("/compliance-dashboard", (bool requiringReviewOnly, PortfolioService service, CancellationToken ct) => service.GetComplianceDashboardAsync(requiringReviewOnly, ct));
        return app;
    }
}
