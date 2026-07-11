using WealthManagement.Api.Authorization;
using WealthManagement.Application.Services;
using WealthManagement.Contracts.Compliance;

namespace WealthManagement.Api.Endpoints;

public static class ComplianceEndpoints
{
    public static IEndpointRouteBuilder MapComplianceEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/compliance").WithTags("Compliance");
        group.MapGet("/alerts", (int page, int pageSize, string? status, string? severity, int? clientId, ComplianceService service, CancellationToken ct) => service.GetAlertsAsync(new ComplianceAlertQuery(page == 0 ? 1 : page, pageSize == 0 ? 25 : pageSize, status, severity, clientId), ct)).RequireAuthorization(PolicyNames.ComplianceRead);
        group.MapPut("/alerts/{alertId:long}/status", (long alertId, UpdateComplianceAlertRequest request, ComplianceService service, CancellationToken ct) => service.UpdateAlertAsync(alertId, request, ct)).RequireAuthorization(PolicyNames.ComplianceManage);
        return app;
    }
}
