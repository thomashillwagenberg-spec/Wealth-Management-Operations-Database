using WealthManagement.Contracts.Common;

namespace WealthManagement.Contracts.Audit;

public sealed record AuditEventDto(
    long AuditEventId,
    DateTime EventTime,
    string ActorId,
    string ActionName,
    string EntityType,
    string? EntityId,
    string Outcome,
    Guid CorrelationId,
    string? MetadataJson);

public sealed record AuditEventQuery(
    int Page = 1,
    int PageSize = 50,
    string? ActorId = null,
    string? ActionName = null,
    string? EntityType = null,
    DateTime? FromUtc = null,
    DateTime? ToUtc = null);
