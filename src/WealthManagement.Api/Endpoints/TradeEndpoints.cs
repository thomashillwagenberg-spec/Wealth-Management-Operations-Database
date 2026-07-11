using WealthManagement.Api.Authorization;
using WealthManagement.Application.Services;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.Api.Endpoints;

public static class TradeEndpoints
{
    public static IEndpointRouteBuilder MapTradeEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/trades", async (SubmitTradeRequest request, HttpRequest httpRequest, TradeService service, CancellationToken ct) =>
        {
            var headerKey = httpRequest.Headers["Idempotency-Key"].FirstOrDefault();
            var effective = string.IsNullOrWhiteSpace(headerKey) ? request : request with { IdempotencyKey = headerKey };
            var response = await service.SubmitAsync(effective, ct);
            return Results.Ok(response);
        }).RequireAuthorization(PolicyNames.TradeSubmit).RequireRateLimiting("trade").WithTags("Synthetic trade demonstration").DisableAntiforgery();
        return app;
    }
}
