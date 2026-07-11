namespace WealthManagement.Application.Abstractions;

public interface ICurrentUserContext
{
    bool IsAuthenticated { get; }
    string UserId { get; }
    string DisplayName { get; }
    IReadOnlySet<string> Roles { get; }
    int? AdvisorId { get; }
    Guid CorrelationId { get; }
    bool IsInRole(string role);
}
