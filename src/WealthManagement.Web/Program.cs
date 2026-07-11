using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Antiforgery;
using WealthManagement.Web.Middleware;
using WealthManagement.Web.Api;
using WealthManagement.Web.Components;
using WealthManagement.Contracts.Security;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddHttpContextAccessor();
builder.Services.AddAuthorization();
builder.Services.AddCascadingAuthenticationState();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
    {
        options.LoginPath = "/login";
        options.Cookie.Name = "wm-dev-auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Strict;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    });
}
else
{
    builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie(options =>
    {
        options.Cookie.Name = "__Host-wm-auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    })
    .AddOpenIdConnect(options =>
    {
        options.Authority = builder.Configuration["Authentication:Authority"] ?? throw new InvalidOperationException("Authentication:Authority is required.");
        options.ClientId = builder.Configuration["Authentication:ClientId"] ?? throw new InvalidOperationException("Authentication:ClientId is required.");
        options.ClientSecret = builder.Configuration["Authentication:ClientSecret"];
        options.ResponseType = "code";
        options.UsePkce = true;
        options.SaveTokens = true;
        options.GetClaimsFromUserInfoEndpoint = true;
        options.Scope.Add(builder.Configuration["Authentication:ApiScope"] ?? throw new InvalidOperationException("Authentication:ApiScope is required."));
        options.TokenValidationParameters.NameClaimType = "name";
        options.TokenValidationParameters.RoleClaimType = "roles";
    });
}

builder.Services.AddTransient<ApiAuthorizationHandler>();
builder.Services.AddHttpClient<WealthManagementApiClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Api:BaseUrl"] ?? "https://localhost:7187");
    client.Timeout = TimeSpan.FromSeconds(30);
}).AddHttpMessageHandler<ApiAuthorizationHandler>();

var app = builder.Build();
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error");
    app.UseHsts();
    app.UseHttpsRedirection();
}
app.UseStaticFiles();
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

if (app.Environment.IsDevelopment())
{
    app.MapPost("/dev-login", async (HttpContext context, IAntiforgery antiforgery) =>
    {
        await antiforgery.ValidateRequestAsync(context);
        var form = await context.Request.ReadFormAsync();
        var requestedUser = form["user"].ToString().Trim();
        if (!DevelopmentIdentities.TryGet(requestedUser, out var developmentIdentity))
            return Results.BadRequest("The selected synthetic development identity is not configured.");

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, developmentIdentity.UserPrincipalName),
            new(ClaimTypes.Name, developmentIdentity.DisplayName),
            new("oid", developmentIdentity.UserPrincipalName)
        };
        claims.AddRange(developmentIdentity.Roles.Select(role => new Claim(ClaimTypes.Role, role)));
        if (developmentIdentity.AdvisorId.HasValue)
            claims.Add(new Claim("advisor_id", developmentIdentity.AdvisorId.Value.ToString(System.Globalization.CultureInfo.InvariantCulture)));
        await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme)));
        return Results.Redirect("/");
    });

    app.MapPost("/dev-logout", async (HttpContext context, IAntiforgery antiforgery) =>
    {
        await antiforgery.ValidateRequestAsync(context);
        await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return Results.Redirect("/login");
    });
}
else
{
    app.MapGet("/account/login", () => Results.Challenge(new AuthenticationProperties { RedirectUri = "/" }, new[] { OpenIdConnectDefaults.AuthenticationScheme }));
    app.MapPost("/account/logout", async (HttpContext context, IAntiforgery antiforgery) =>
    {
        await antiforgery.ValidateRequestAsync(context);
        return Results.SignOut(new AuthenticationProperties { RedirectUri = "/" }, new[] { CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme });
    });
}

app.MapRazorComponents<App>().AddInteractiveServerRenderMode();
app.Run();

public partial class Program;
