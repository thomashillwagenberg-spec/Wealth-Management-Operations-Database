namespace WealthManagement.Api.Authorization;

public static class RoleNames
{
    public const string DatabaseAdministrator = "DatabaseAdministrator";
    public const string AdvisorUser = "AdvisorUser";
    public const string ComplianceReviewer = "ComplianceReviewer";
    public const string ReportingAnalyst = "ReportingAnalyst";
    public const string ReadOnlyAuditor = "ReadOnlyAuditor";
}

public static class PolicyNames
{
    public const string PortfolioRead = "portfolio.read";
    public const string TradeSubmit = "trade.submit";
    public const string ComplianceRead = "compliance.read";
    public const string ComplianceManage = "compliance.manage";
    public const string AuditRead = "audit.read";
    public const string OperationsRead = "operations.read";
}
