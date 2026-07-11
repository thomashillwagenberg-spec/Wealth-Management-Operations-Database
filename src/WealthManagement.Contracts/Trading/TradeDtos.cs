namespace WealthManagement.Contracts.Trading;

public sealed record SubmitTradeRequest(
    int AccountId,
    string TransactionTypeCode,
    int SecurityId,
    DateOnly TradeDate,
    DateOnly SettlementDate,
    decimal Quantity,
    decimal Price,
    decimal FeeAmount,
    string ExternalReference,
    string IdempotencyKey,
    string? Notes);

public sealed record SubmitTradeResponse(
    long TransactionId,
    Guid CorrelationId,
    bool WasReplay,
    string ResultMessage);
