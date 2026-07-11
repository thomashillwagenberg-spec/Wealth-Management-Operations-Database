using System.Security.Claims;
using WealthManagement.Application.Abstractions;
using WealthManagement.Api.Middleware;

namespace WealthManagement.Api.Authorization;

public sealed class CurrentUserContext(IHttpContextAccessor accessor) : ICurrentUserContext
{
    private HttpContext? HttpContext => accessor.HttpContext;
    private ClaimsPrincipal User => HttpContext?.User ?? new ClaimsPrincipal();

    public bool IsAuthenticated => User.Identity?.IsAuthenticated == true;
    public string UserId => User.FindFirstValue("oid") ?? User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
    public string DisplayName => User.FindFirstValue("name") ?? User.Identity?.Name ?? UserId;
    public IReadOnlySet<string> Roles => User.FindAll(ClaimTypes.Role).Select(x => x.Value).Concat(User.FindAll("roles").Select(x => x.Value)).ToHashSet(StringComparer.Ordinal);
    public int? AdvisorId => int.TryParse(User.FindFirstValue("advisor_id"), out var value) ? value : null;
    public Guid CorrelationId => Guid.TryParse(HttpContext?.Items[CorrelationIdMiddleware.ItemName]?.ToString(), out var value) ? value : Guid.Empty;
    public bool IsInRole(string role) => Roles.Contains(role);
}
