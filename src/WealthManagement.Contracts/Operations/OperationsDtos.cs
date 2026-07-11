namespace WealthManagement.Contracts.Operations;

public sealed record VersionDto(
    string Application,
    string Version,
    string Environment,
    string Commit,
    DateTime BuildTimeUtc);

public sealed record HealthSummaryDto(
    string Status,
    DateTime CheckedAtUtc,
    IReadOnlyDictionary<string, string> Components);
