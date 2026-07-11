using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using WealthManagement.Application.Abstractions;
using WealthManagement.Infrastructure.Data;
using WealthManagement.Infrastructure.Health;
using WealthManagement.Infrastructure.Repositories;

namespace WealthManagement.Infrastructure;

public static class DependencyInjection
{
    private static readonly string[] ReadinessTags = ["ready"];

    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<DatabaseOptions>().Bind(configuration.GetSection(DatabaseOptions.SectionName)).ValidateDataAnnotations().ValidateOnStart();
        services.AddScoped<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<IPortfolioRepository, PortfolioRepository>();
        services.AddScoped<ITradeRepository, TradeRepository>();
        services.AddScoped<IComplianceRepository, ComplianceRepository>();
        services.AddScoped<IAuditRepository, AuditRepository>();
        services.AddScoped<IAccessControlRepository, AccessControlRepository>();
        services.AddHealthChecks().AddCheck<SqlDatabaseHealthCheck>("database", tags: ReadinessTags);
        return services;
    }
}
