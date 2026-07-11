namespace WealthManagement.Contracts.Security;

/// <summary>
/// Fixed synthetic identities available only to the Development environment.
/// The caller may select an identity, but roles and advisor scope are resolved
/// by the server from this catalog rather than accepted from request data.
/// </summary>
public sealed record DevelopmentIdentity(
    string UserPrincipalName,
    string DisplayName,
    IReadOnlyList<string> Roles,
    int? AdvisorId = null);

public static class DevelopmentIdentities
{
    public static IReadOnlyDictionary<string, DevelopmentIdentity> All { get; } =
        new Dictionary<string, DevelopmentIdentity>(StringComparer.OrdinalIgnoreCase)
        {
            ["advisor1@local.test"] = new("advisor1@local.test", "Avery Advisor", ["AdvisorUser"], 1),
            ["compliance@local.test"] = new("compliance@local.test", "Casey Compliance", ["ComplianceReviewer"]),
            ["reporting@local.test"] = new("reporting@local.test", "Riley Reporting", ["ReportingAnalyst"]),
            ["auditor@local.test"] = new("auditor@local.test", "Alex Auditor", ["ReadOnlyAuditor"]),
            ["admin@local.test"] = new("admin@local.test", "Dana Database Administrator", ["DatabaseAdministrator"])
        };

    public static bool TryGet(string? userPrincipalName, out DevelopmentIdentity identity)
    {
        if (!string.IsNullOrWhiteSpace(userPrincipalName) && All.TryGetValue(userPrincipalName.Trim(), out var found))
        {
            identity = found;
            return true;
        }

        identity = null!;
        return false;
    }
}
