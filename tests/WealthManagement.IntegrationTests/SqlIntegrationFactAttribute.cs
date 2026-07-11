namespace WealthManagement.IntegrationTests;

[AttributeUsage(AttributeTargets.Method)]
public sealed class SqlIntegrationFactAttribute : FactAttribute
{
    public SqlIntegrationFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(SqlTestConnections.Admin) || string.IsNullOrWhiteSpace(SqlTestConnections.Application))
            Skip = "WM_SQL_ADMIN_CONNECTION and WM_SQL_INTEGRATION_CONNECTION must both be configured.";
    }
}

internal static class SqlTestConnections
{
    public static string? Admin => Environment.GetEnvironmentVariable("WM_SQL_ADMIN_CONNECTION");
    public static string? Application => Environment.GetEnvironmentVariable("WM_SQL_INTEGRATION_CONNECTION");
}
