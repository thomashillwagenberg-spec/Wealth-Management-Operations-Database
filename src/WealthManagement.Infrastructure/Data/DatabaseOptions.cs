namespace WealthManagement.Infrastructure.Data;

public sealed class DatabaseOptions
{
    public const string SectionName = "Database";
    public string ConnectionStringName { get; init; } = "WealthManagement";
    public int CommandTimeoutSeconds { get; init; } = 30;
    public bool RequireEncryptedConnection { get; init; } = true;
}
