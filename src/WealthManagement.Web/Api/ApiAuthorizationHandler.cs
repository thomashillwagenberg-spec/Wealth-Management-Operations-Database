using System.Net.Http.Headers;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Components.Authorization;

namespace WealthManagement.Web.Api;

public sealed class ApiAuthorizationHandler(
    IHttpContextAccessor accessor,
    AuthenticationStateProvider authenticationStateProvider,
    IWebHostEnvironment environment) : DelegatingHandler
{
    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var context = accessor.HttpContext;
        var principal = context?.User;
        if (principal?.Identity?.IsAuthenticated != true)
            principal = (await authenticationStateProvider.GetAuthenticationStateAsync()).User;

        if (environment.IsDevelopment())
        {
            var user = principal.FindFirstValue("oid") ?? principal.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrWhiteSpace(user))
                request.Headers.TryAddWithoutValidation("X-Dev-User", user);
        }
        else
        {
            if (context is null)
                throw new InvalidOperationException("A server HTTP context is required to forward the production access token.");
            var token = await context.GetTokenAsync("access_token");
            if (string.IsNullOrWhiteSpace(token))
                throw new InvalidOperationException("No API access token is available for the authenticated session.");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        request.Headers.TryAddWithoutValidation("X-Correlation-ID", Guid.NewGuid().ToString("D"));
        return await base.SendAsync(request, cancellationToken);
    }
}
