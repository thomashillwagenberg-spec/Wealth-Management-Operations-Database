using System.Text.RegularExpressions;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.Application.Validation;

public sealed partial class SubmitTradeRequestValidator : IRequestValidator<SubmitTradeRequest>
{
    public ValidationResult Validate(SubmitTradeRequest request)
    {
        var failures = new List<ValidationFailure>();
        var type = request.TransactionTypeCode?.Trim().ToUpperInvariant();

        if (request.AccountId <= 0) failures.Add(new("accountId", "positive", "Account ID must be positive."));
        if (request.SecurityId <= 0) failures.Add(new("securityId", "positive", "Security ID must be positive."));
        if (type is not ("BUY" or "SELL")) failures.Add(new("transactionTypeCode", "allowed", "Transaction type must be BUY or SELL."));
        if (request.Quantity <= 0 || request.Quantity > 1_000_000m) failures.Add(new("quantity", "range", "Quantity must be greater than zero and no more than 1,000,000."));
        if (request.Price <= 0 || request.Price > 10_000_000m) failures.Add(new("price", "range", "Price must be greater than zero and no more than 10,000,000."));
        if (request.FeeAmount < 0 || request.FeeAmount > 100_000m) failures.Add(new("feeAmount", "range", "Fee amount must be between zero and 100,000."));
        if (request.SettlementDate < request.TradeDate) failures.Add(new("settlementDate", "chronology", "Settlement date cannot precede trade date."));
        if (string.IsNullOrWhiteSpace(request.ExternalReference) || request.ExternalReference.Length > 30 || !ReferencePattern().IsMatch(request.ExternalReference))
            failures.Add(new("externalReference", "format", "External reference must be 1 to 30 letters, numbers, hyphens, or underscores."));
        if (string.IsNullOrWhiteSpace(request.IdempotencyKey) || request.IdempotencyKey.Length > 100 || !IdempotencyPattern().IsMatch(request.IdempotencyKey))
            failures.Add(new("idempotencyKey", "format", "Idempotency key must be 12 to 100 URL-safe characters."));
        if (request.Notes?.Length > 250) failures.Add(new("notes", "length", "Notes cannot exceed 250 characters."));

        return failures.Count == 0 ? ValidationResult.Success : new(failures);
    }

    [GeneratedRegex("^[A-Za-z0-9_-]{1,30}$", RegexOptions.CultureInvariant)]
    private static partial Regex ReferencePattern();

    [GeneratedRegex("^[A-Za-z0-9._~-]{12,100}$", RegexOptions.CultureInvariant)]
    private static partial Regex IdempotencyPattern();
}
