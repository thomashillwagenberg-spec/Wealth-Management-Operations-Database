using System.Reflection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using WealthManagement.Api.Authorization;
using WealthManagement.Contracts.Operations;

namespace WealthManagement.Api.Endpoints;

public static class OperationsEndpoints
{
    public static IEndpointRouteBuilder MapOperationsEndpoints(this IEndpointRouteBuilder app, IWebHostEnvironment environment, IConfiguration configuration)
    {
        app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = check => check.Tags.Contains("live") }).AllowAnonymous();
        app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") }).RequireAuthorization(PolicyNames.OperationsRead);
        app.MapGet("/api/version", () =>
        {
            var assembly = Assembly.GetExecutingAssembly().GetName();
            return new VersionDto(assembly.Name ?? "WealthManagement.Api", assembly.Version?.ToString() ?? "0.0.0", environment.EnvironmentName, configuration["Build:Commit"] ?? "local", DateTime.TryParse(configuration["Build:TimeUtc"], out var time) ? time : DateTime.UnixEpoch);
        }).AllowAnonymous().WithTags("Operations");
        app.MapGet("/api/operations/health", async (HealthCheckService healthChecks, CancellationToken ct) =>
        {
            var report = await healthChecks.CheckHealthAsync(_ => true, ct);
            var components = report.Entries.ToDictionary(x => x.Key, x => x.Value.Status.ToString(), StringComparer.OrdinalIgnoreCase);
            var summary = new HealthSummaryDto(report.Status.ToString(), DateTime.UtcNow, components);
            return report.Status == HealthStatus.Unhealthy ? Results.Json(summary, statusCode: StatusCodes.Status503ServiceUnavailable) : Results.Ok(summary);
        }).RequireAuthorization(PolicyNames.OperationsRead).WithTags("Operations");
        return app;
    }
}
