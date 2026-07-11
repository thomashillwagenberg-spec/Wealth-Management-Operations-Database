using WealthManagement.Api.Authorization;
using WealthManagement.Application.Services;
using WealthManagement.Contracts.Audit;

namespace WealthManagement.Api.Endpoints;

public static class AuditEndpoints
{
    public static IEndpointRouteBuilder MapAuditEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/audit/events", (int page, int pageSize, string? actorId, string? actionName, string? entityType, DateTime? fromUtc, DateTime? toUtc, AuditService service, CancellationToken ct) => service.GetEventsAsync(new AuditEventQuery(page == 0 ? 1 : page, pageSize == 0 ? 50 : pageSize, actorId, actionName, entityType, fromUtc, toUtc), ct)).RequireAuthorization(PolicyNames.AuditRead).WithTags("Audit evidence");
        return app;
    }
}
