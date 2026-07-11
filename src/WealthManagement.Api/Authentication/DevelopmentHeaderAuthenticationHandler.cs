using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using WealthManagement.Contracts.Security;

namespace WealthManagement.Api.Authentication;

public sealed class DevelopmentHeaderAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder,
    IWebHostEnvironment environment) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string Scheme = "DevelopmentHeader";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!environment.IsDevelopment())
            return Task.FromResult(AuthenticateResult.Fail("Development authentication is disabled outside Development."));

        var requestedUser = Request.Headers["X-Dev-User"].ToString();
        if (string.IsNullOrWhiteSpace(requestedUser))
            return Task.FromResult(AuthenticateResult.NoResult());

        if (!DevelopmentIdentities.TryGet(requestedUser, out var identity))
            return Task.FromResult(AuthenticateResult.Fail("The requested synthetic development identity is not configured."));

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, identity.UserPrincipalName),
            new(ClaimTypes.Name, identity.DisplayName),
            new("oid", identity.UserPrincipalName)
        };

        claims.AddRange(identity.Roles.Select(role => new Claim(ClaimTypes.Role, role)));
        if (identity.AdvisorId.HasValue)
            claims.Add(new Claim("advisor_id", identity.AdvisorId.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)));

        var claimsIdentity = new ClaimsIdentity(claims, Scheme, ClaimTypes.Name, ClaimTypes.Role);
        return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(new ClaimsPrincipal(claimsIdentity), Scheme)));
    }
}
