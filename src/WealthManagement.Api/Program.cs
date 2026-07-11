using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authorization;
using WealthManagement.Api.Authentication;
using WealthManagement.Api.Authorization;
using WealthManagement.Api.Endpoints;
using WealthManagement.Api.Middleware;
using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Services;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Trading;
using WealthManagement.Infrastructure;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 1_048_576);
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserContext, CurrentUserContext>();
builder.Services.AddApplicationAuthentication(builder.Configuration, builder.Environment);
builder.Services.AddAuthorizationBuilder()
    .AddPolicy(PolicyNames.PortfolioRead, p => p.RequireAuthenticatedUser().RequireRole(RoleNames.DatabaseAdministrator, RoleNames.AdvisorUser, RoleNames.ComplianceReviewer, RoleNames.ReportingAnalyst, RoleNames.ReadOnlyAuditor))
    .AddPolicy(PolicyNames.TradeSubmit, p => p.RequireAuthenticatedUser().RequireRole(RoleNames.DatabaseAdministrator, RoleNames.AdvisorUser))
    .AddPolicy(PolicyNames.ComplianceRead, p => p.RequireAuthenticatedUser().RequireRole(RoleNames.DatabaseAdministrator, RoleNames.ComplianceReviewer, RoleNames.ReadOnlyAuditor))
    .AddPolicy(PolicyNames.ComplianceManage, p => p.RequireAuthenticatedUser().RequireRole(RoleNames.DatabaseAdministrator, RoleNames.ComplianceReviewer))
    .AddPolicy(PolicyNames.AuditRead, p => p.RequireAuthenticatedUser().RequireRole(RoleNames.DatabaseAdministrator, RoleNames.ReadOnlyAuditor))
    .AddPolicy(PolicyNames.OperationsRead, p => p.RequireAuthenticatedUser());
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddScoped<PortfolioService>();
builder.Services.AddScoped<TradeService>();
builder.Services.AddScoped<ComplianceService>();
builder.Services.AddScoped<AuditService>();
builder.Services.AddSingleton<IRequestValidator<SubmitTradeRequest>, SubmitTradeRequestValidator>();
builder.Services.AddSingleton<IRequestValidator<ComplianceAlertQuery>, ComplianceAlertQueryValidator>();
builder.Services.AddSingleton<IRequestValidator<UpdateComplianceAlertRequest>, UpdateComplianceAlertRequestValidator>();
builder.Services.AddOpenApi();
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddCors(options => options.AddPolicy("ConfiguredOrigins", policy =>
{
    var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
    if (origins.Length > 0) policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
}));
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context => RateLimitPartition.GetFixedWindowLimiter(context.User.FindFirst("oid")?.Value ?? context.Connection.RemoteIpAddress?.ToString() ?? "anonymous", _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromMinutes(1), QueueLimit = 0, AutoReplenishment = true }));
    options.AddPolicy("trade", context => RateLimitPartition.GetFixedWindowLimiter(context.User.FindFirst("oid")?.Value ?? "anonymous", _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0, AutoReplenishment = true }));
});
builder.Services.AddHealthChecks().AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(), tags: LiveReadyTags);

var app = builder.Build();
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
app.UseExceptionHandler();
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseCors("ConfiguredOrigins");
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();
if (app.Environment.IsDevelopment()) app.MapOpenApi();
app.MapPortfolioEndpoints();
app.MapTradeEndpoints();
app.MapComplianceEndpoints();
app.MapAuditEndpoints();
app.MapOperationsEndpoints(app.Environment, app.Configuration);
app.Run();

public partial class Program
{
    internal static readonly string[] LiveReadyTags = ["live", "ready"];
}
