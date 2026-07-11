using WealthManagement.Contracts.Common;

namespace WealthManagement.Contracts.Compliance;

public sealed record ComplianceDashboardDto(
    int ClientId,
    string ClientCode,
    string ClientName,
    long ReviewCount,
    long OverdueReviewCount,
    DateOnly? NextOpenReviewDueDate,
    long AlertCount,
    long OpenAlertCount,
    string MaximumAlertSeverity,
    bool RequiresReview);

public sealed record ComplianceAlertDto(
    long ComplianceAlertId,
    int ClientId,
    string ClientCode,
    string ClientName,
    int? AccountId,
    string? AccountNumber,
    long? TransactionId,
    string AlertType,
    string Severity,
    string AlertStatus,
    DateOnly AlertDate,
    DateOnly? ResolvedDate,
    string Description,
    DateTime ModifiedAt,
    string RowVersion);

public sealed record ComplianceAlertQuery(
    int Page = 1,
    int PageSize = 25,
    string? Status = null,
    string? Severity = null,
    int? ClientId = null);

public sealed record UpdateComplianceAlertRequest(
    string NewStatus,
    string? ResolutionNote,
    string ExpectedRowVersion);

public sealed record UpdateComplianceAlertResponse(
    long ComplianceAlertId,
    string AlertStatus,
    DateOnly? ResolvedDate,
    DateTime ModifiedAt,
    string RowVersion,
    Guid CorrelationId);
