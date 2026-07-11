using WealthManagement.Contracts.Compliance;

namespace WealthManagement.Application.Validation;

public sealed class ComplianceAlertQueryValidator : IRequestValidator<ComplianceAlertQuery>
{
    private static readonly HashSet<string> Statuses = new(StringComparer.OrdinalIgnoreCase) { "OPEN", "IN_REVIEW", "RESOLVED", "DISMISSED" };
    private static readonly HashSet<string> Severities = new(StringComparer.OrdinalIgnoreCase) { "LOW", "MEDIUM", "HIGH", "CRITICAL" };

    public ValidationResult Validate(ComplianceAlertQuery request)
    {
        var failures = new List<ValidationFailure>();
        if (request.Page < 1) failures.Add(new("page", "range", "Page must be at least 1."));
        if (request.PageSize is < 1 or > 100) failures.Add(new("pageSize", "range", "Page size must be between 1 and 100."));
        if (request.Status is not null && !Statuses.Contains(request.Status)) failures.Add(new("status", "allowed", "Status is not recognized."));
        if (request.Severity is not null && !Severities.Contains(request.Severity)) failures.Add(new("severity", "allowed", "Severity is not recognized."));
        if (request.ClientId is <= 0) failures.Add(new("clientId", "positive", "Client ID must be positive."));
        return failures.Count == 0 ? ValidationResult.Success : new(failures);
    }
}

public sealed class UpdateComplianceAlertRequestValidator : IRequestValidator<UpdateComplianceAlertRequest>
{
    private static readonly HashSet<string> Statuses = new(StringComparer.OrdinalIgnoreCase) { "OPEN", "IN_REVIEW", "RESOLVED", "DISMISSED" };

    public ValidationResult Validate(UpdateComplianceAlertRequest request)
    {
        var failures = new List<ValidationFailure>();
        if (string.IsNullOrWhiteSpace(request.NewStatus) || !Statuses.Contains(request.NewStatus)) failures.Add(new("newStatus", "allowed", "Status is not recognized."));
        if (request.ResolutionNote?.Length > 500) failures.Add(new("resolutionNote", "length", "Resolution note cannot exceed 500 characters."));
        try
        {
            var bytes = Convert.FromBase64String(request.ExpectedRowVersion ?? string.Empty);
            if (bytes.Length != 8) failures.Add(new("expectedRowVersion", "format", "Row version must decode to eight bytes."));
        }
        catch (FormatException)
        {
            failures.Add(new("expectedRowVersion", "format", "Row version must be valid Base64."));
        }
        return failures.Count == 0 ? ValidationResult.Success : new(failures);
    }
}
