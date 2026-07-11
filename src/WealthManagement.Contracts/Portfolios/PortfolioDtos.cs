namespace WealthManagement.Contracts.Portfolios;

public sealed record ClientPortfolioSummaryDto(
    int ClientId,
    string ClientCode,
    string ClientName,
    int AdvisorId,
    string AdvisorName,
    int AccountCount,
    decimal TotalCostBasis,
    decimal TotalPortfolioValue,
    decimal UnrealizedGainLoss,
    decimal UnrealizedReturnPct);

public sealed record AccountPortfolioValueDto(
    int AccountId,
    string AccountNumber,
    int ClientId,
    string ClientCode,
    string ClientName,
    int AdvisorId,
    string AdvisorName,
    decimal TotalCostBasis,
    decimal PortfolioValue,
    decimal UnrealizedGainLoss,
    decimal UnrealizedReturnPct,
    DateOnly? ValuationDate);

public sealed record AssetAllocationDto(
    int AccountId,
    string AccountNumber,
    int ClientId,
    int AssetClassId,
    string AssetClassCode,
    string AssetClassName,
    bool IsEquityLike,
    decimal AssetClassValue,
    decimal AllocationPct);

public sealed record RiskAlignmentDto(
    int ClientId,
    string ClientCode,
    string ClientName,
    string RiskCode,
    string RiskName,
    decimal MinEquityPct,
    decimal MaxEquityPct,
    decimal EquityAllocationPct,
    string AlignmentStatus,
    decimal? DeviationPctPoints);

public sealed record ConcentrationDto(
    int AccountId,
    string AccountNumber,
    int SecurityId,
    string Symbol,
    string SecurityName,
    decimal MarketValue,
    decimal AccountValue,
    decimal ConcentrationPct);

public sealed record AdvisorActivityDto(
    int AdvisorId,
    string AdvisorName,
    DateOnly ActivityMonth,
    string TransactionTypeCode,
    long TransactionCount,
    decimal GrossAmount);
