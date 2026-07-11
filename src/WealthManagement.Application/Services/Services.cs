using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Audit;
using WealthManagement.Contracts.Common;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Portfolios;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.Application.Services;

public sealed class PortfolioService(IPortfolioRepository repository, IAccessControlRepository access)
{
    public Task<IReadOnlyList<ClientPortfolioSummaryDto>> GetClientsAsync(CancellationToken cancellationToken) => repository.GetClientSummariesAsync(cancellationToken);

    public async Task<(ClientPortfolioSummaryDto Client, IReadOnlyList<AccountPortfolioValueDto> Accounts)> GetClientAsync(int clientId, CancellationToken cancellationToken)
    {
        if (!await access.CanAccessClientAsync(clientId, cancellationToken)) throw new AccessDeniedException("The client is outside the caller's authorized scope.");
        var client = await repository.GetClientSummaryAsync(clientId, cancellationToken) ?? throw new ResourceNotFoundException("Client was not found.");
        return (client, await repository.GetClientAccountsAsync(clientId, cancellationToken));
    }

    public async Task<IReadOnlyList<AssetAllocationDto>> GetAllocationAsync(int accountId, CancellationToken cancellationToken)
    {
        if (!await access.CanAccessAccountAsync(accountId, cancellationToken)) throw new AccessDeniedException("The account is outside the caller's authorized scope.");
        return await repository.GetAccountAllocationAsync(accountId, cancellationToken);
    }

    public Task<IReadOnlyList<RiskAlignmentDto>> GetRiskAsync(bool exceptionsOnly, CancellationToken cancellationToken) => repository.GetRiskAlignmentAsync(exceptionsOnly, cancellationToken);

    public async Task<IReadOnlyList<ConcentrationDto>> GetConcentrationsAsync(int? accountId, decimal minimumPct, CancellationToken cancellationToken)
    {
        if (accountId is <= 0)
            throw new RequestValidationException([new ValidationFailure("accountId", "positive", "Account ID must be positive when supplied.")]);
        if (minimumPct is <= 0 or > 100)
            throw new RequestValidationException([new ValidationFailure("minimumPct", "range", "Minimum concentration must be greater than zero and no more than 100.")]);
        if (accountId.HasValue && !await access.CanAccessAccountAsync(accountId.Value, cancellationToken))
            throw new AccessDeniedException("The account is outside the caller's authorized scope.");
        return await repository.GetConcentrationsAsync(accountId, minimumPct, cancellationToken);
    }

    public async Task<IReadOnlyList<AdvisorActivityDto>> GetAdvisorActivityAsync(int advisorId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken)
    {
        if (advisorId <= 0)
            throw new RequestValidationException([new ValidationFailure("advisorId", "positive", "Advisor ID must be positive.")]);
        if (endDate < startDate || endDate.DayNumber - startDate.DayNumber > 366)
            throw new RequestValidationException([new ValidationFailure("dateRange", "range", "The activity range must be chronological and no longer than 366 days.")]);
        if (!await access.CanAccessAdvisorAsync(advisorId, cancellationToken))
            throw new AccessDeniedException("The advisor is outside the caller's authorized scope.");
        return await repository.GetAdvisorActivityAsync(advisorId, startDate, endDate, cancellationToken);
    }

    public Task<IReadOnlyList<ComplianceDashboardDto>> GetComplianceDashboardAsync(bool requiringReviewOnly, CancellationToken cancellationToken) => repository.GetComplianceDashboardAsync(requiringReviewOnly, cancellationToken);
}

public sealed class TradeService(ITradeRepository repository, IAccessControlRepository access, IRequestValidator<SubmitTradeRequest> validator)
{
    public async Task<SubmitTradeResponse> SubmitAsync(SubmitTradeRequest request, CancellationToken cancellationToken)
    {
        var result = validator.Validate(request);
        if (!result.IsValid) throw new RequestValidationException(result.Failures);
        if (!await access.CanAccessAccountAsync(request.AccountId, cancellationToken)) throw new AccessDeniedException("The account is outside the caller's authorized scope.");
        var normalized = request with { TransactionTypeCode = request.TransactionTypeCode.Trim().ToUpperInvariant(), ExternalReference = request.ExternalReference.Trim(), IdempotencyKey = request.IdempotencyKey.Trim() };
        var canonical = JsonSerializer.Serialize(normalized, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonical)));
        return await repository.SubmitAsync(normalized, hash, cancellationToken);
    }
}

public sealed class ComplianceService(IComplianceRepository repository, IRequestValidator<ComplianceAlertQuery> queryValidator, IRequestValidator<UpdateComplianceAlertRequest> updateValidator)
{
    public async Task<PagedResult<ComplianceAlertDto>> GetAlertsAsync(ComplianceAlertQuery query, CancellationToken cancellationToken)
    {
        var validation = queryValidator.Validate(query);
        if (!validation.IsValid) throw new RequestValidationException(validation.Failures);
        return await repository.GetAlertsAsync(query, cancellationToken);
    }

    public async Task<UpdateComplianceAlertResponse> UpdateAlertAsync(long alertId, UpdateComplianceAlertRequest request, CancellationToken cancellationToken)
    {
        if (alertId <= 0)
            throw new RequestValidationException([new ValidationFailure("alertId", "positive", "Alert ID must be positive.")]);
        var validation = updateValidator.Validate(request);
        if (!validation.IsValid) throw new RequestValidationException(validation.Failures);
        return await repository.UpdateAlertAsync(alertId, request with { NewStatus = request.NewStatus.Trim().ToUpperInvariant() }, cancellationToken);
    }
}

public sealed class AuditService(IAuditRepository repository)
{
    public Task<PagedResult<AuditEventDto>> GetEventsAsync(AuditEventQuery query, CancellationToken cancellationToken)
    {
        var failures = new List<ValidationFailure>();
        if (query.Page < 1) failures.Add(new("page", "range", "Page must be at least 1."));
        if (query.PageSize is < 1 or > 100) failures.Add(new("pageSize", "range", "Page size must be between 1 and 100."));
        if (query.FromUtc.HasValue && query.ToUtc.HasValue && query.ToUtc < query.FromUtc) failures.Add(new("dateRange", "chronology", "The end time cannot precede the start time."));
        if (query.ActorId?.Length > 254) failures.Add(new("actorId", "length", "Actor ID cannot exceed 254 characters."));
        if (query.ActionName?.Length > 80) failures.Add(new("actionName", "length", "Action name cannot exceed 80 characters."));
        if (query.EntityType?.Length > 80) failures.Add(new("entityType", "length", "Entity type cannot exceed 80 characters."));
        if (failures.Count > 0) throw new RequestValidationException(failures);
        return repository.GetEventsAsync(query, cancellationToken);
    }
}
