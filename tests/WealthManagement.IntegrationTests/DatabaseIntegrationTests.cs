using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace WealthManagement.IntegrationTests;

public sealed class DatabaseIntegrationTests
{
    [SqlIntegrationFact]
    public async Task Original_seed_counts_and_holdings_reconciliation_match()
    {
        await using var connection = new SqlConnection(SqlTestConnections.Admin!);
        await connection.OpenAsync();
        var clients = await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM core.Client;");
        var holdings = await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM trading.CurrentHolding;");
        var mismatches = await connection.ExecuteScalarAsync<int>(@"WITH q AS
(
    SELECT atx.AccountID,atx.SecurityID,
           SUM(CASE tt.TransactionTypeCode WHEN 'BUY' THEN atx.Quantity WHEN 'SELL' THEN -atx.Quantity ELSE 0 END) Qty
    FROM trading.AccountTransaction atx
    JOIN trading.TransactionType tt ON tt.TransactionTypeID=atx.TransactionTypeID
    WHERE atx.SecurityID IS NOT NULL
    GROUP BY atx.AccountID,atx.SecurityID
)
SELECT COUNT(*)
FROM q
FULL JOIN trading.CurrentHolding h ON h.AccountID=q.AccountID AND h.SecurityID=q.SecurityID
WHERE ABS(COALESCE(q.Qty,0)-COALESCE(h.Quantity,0))>0.000001;");
        Assert.Equal(30, clients);
        Assert.Equal(300, holdings);
        Assert.Equal(0, mismatches);
    }

    [SqlIntegrationFact]
    public async Task Advisor_context_filters_curated_reporting_and_denies_raw_client_table()
    {
        await using var connection = await OpenApplicationAsync("advisor1@local.test");
        var visible = await connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM reporting.vw_ClientPortfolioSummary;");
        Assert.InRange(visible, 1, 29);
        await Assert.ThrowsAsync<SqlException>(() => connection.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM core.Client;"));
    }

    [SqlIntegrationFact]
    public async Task Advisor_object_scope_rejects_an_unrelated_advisor()
    {
        await using var connection = await OpenApplicationAsync("advisor1@local.test");
        var own = await connection.QuerySingleAsync<bool>("security.usp_CanAccessAdvisor", new { AdvisorId = 1 }, commandType: CommandType.StoredProcedure);
        var unrelated = await connection.QuerySingleAsync<bool>("security.usp_CanAccessAdvisor", new { AdvisorId = 2 }, commandType: CommandType.StoredProcedure);
        Assert.True(own);
        Assert.False(unrelated);
    }

    [SqlIntegrationFact]
    public async Task Trade_submission_is_idempotent_and_outer_rollback_removes_the_operation()
    {
        await using var connection = await OpenApplicationAsync("advisor1@local.test");
        await using var transaction = await connection.BeginTransactionAsync();
        var suffix = Guid.NewGuid().ToString("N")[..12];
        var args = new
        {
            IdempotencyKey = $"integration-{suffix}",
            RequestHash = new string('A', 64),
            AccountId = 1,
            TransactionTypeCode = "BUY",
            SecurityId = 1,
            TradeDate = new DateOnly(2026, 7, 10),
            SettlementDate = new DateOnly(2026, 7, 11),
            Quantity = 0.01m,
            Price = 100m,
            FeeAmount = 0m,
            ExternalReference = $"INT-{suffix}",
            Notes = "Synthetic integration validation"
        };
        var first = await connection.QuerySingleAsync<TradeResult>("trading.usp_SubmitTrade", args, transaction, commandType: CommandType.StoredProcedure);
        var replay = await connection.QuerySingleAsync<TradeResult>("trading.usp_SubmitTrade", args, transaction, commandType: CommandType.StoredProcedure);
        Assert.Equal(first.TransactionId, replay.TransactionId);
        Assert.Equal(first.CorrelationId, replay.CorrelationId);
        Assert.False(first.WasReplay);
        Assert.True(replay.WasReplay);
        await transaction.RollbackAsync();

        await using var admin = new SqlConnection(SqlTestConnections.Admin!);
        await admin.OpenAsync();
        Assert.Equal(0, await admin.ExecuteScalarAsync<int>("SELECT COUNT(*) FROM trading.AccountTransaction WHERE ExternalReference=@Reference;", new { Reference = args.ExternalReference }));
    }

    [SqlIntegrationFact]
    public async Task Oversell_is_rejected_without_creating_a_transaction()
    {
        await using var connection = await OpenApplicationAsync("advisor1@local.test");
        var suffix = Guid.NewGuid().ToString("N")[..12];
        var command = new CommandDefinition("trading.usp_SubmitTrade", new
        {
            IdempotencyKey = $"oversell-{suffix}", RequestHash = new string('B', 64), AccountId = 1,
            TransactionTypeCode = "SELL", SecurityId = 1, TradeDate = new DateOnly(2026, 7, 10),
            SettlementDate = new DateOnly(2026, 7, 11), Quantity = 999999m, Price = 100m,
            FeeAmount = 0m, ExternalReference = $"OVER-{suffix}", Notes = "Expected rejection"
        }, commandType: CommandType.StoredProcedure);
        await Assert.ThrowsAsync<SqlException>(() => connection.QuerySingleAsync<TradeResult>(command));
    }

    [SqlIntegrationFact]
    public async Task Compliance_update_uses_rowversion_and_rejects_a_stale_write()
    {
        await using var connection = await OpenApplicationAsync("compliance@local.test");
        var alert = await connection.QueryFirstAsync<AlertRow>("compliance.usp_ListAlerts", new { Page = 1, PageSize = 1, Status = (string?)null, Severity = (string?)null, ClientId = (int?)null }, commandType: CommandType.StoredProcedure);
        await using var transaction = await connection.BeginTransactionAsync();
        await connection.QuerySingleAsync("compliance.usp_UpdateAlertStatusSecure", new { alert.ComplianceAlertId, NewStatus = "IN_REVIEW", ResolutionNote = "Integration validation", ExpectedRowVersion = alert.RowVersion }, transaction, commandType: CommandType.StoredProcedure);
        await Assert.ThrowsAsync<SqlException>(() => connection.QuerySingleAsync("compliance.usp_UpdateAlertStatusSecure", new { alert.ComplianceAlertId, NewStatus = "RESOLVED", ResolutionNote = "Stale version", ExpectedRowVersion = alert.RowVersion }, transaction, commandType: CommandType.StoredProcedure));
        if (transaction.Connection is not null)
            await transaction.RollbackAsync();
    }

    [SqlIntegrationFact]
    public async Task Auditor_cannot_modify_compliance_records()
    {
        await using var compliance = await OpenApplicationAsync("compliance@local.test");
        var alert = await compliance.QueryFirstAsync<AlertRow>("compliance.usp_ListAlerts", new { Page = 1, PageSize = 1, Status = (string?)null, Severity = (string?)null, ClientId = (int?)null }, commandType: CommandType.StoredProcedure);
        await using var auditor = await OpenApplicationAsync("auditor@local.test");
        await Assert.ThrowsAsync<SqlException>(() => auditor.QuerySingleAsync("compliance.usp_UpdateAlertStatusSecure", new { alert.ComplianceAlertId, NewStatus = "RESOLVED", ResolutionNote = "Not authorized", ExpectedRowVersion = alert.RowVersion }, commandType: CommandType.StoredProcedure));
    }

    private static async Task<SqlConnection> OpenApplicationAsync(string userPrincipalName)
    {
        var connection = new SqlConnection(SqlTestConnections.Application!);
        await connection.OpenAsync();
        await connection.ExecuteAsync("security.usp_SetExecutionContext", new { UserPrincipalName = userPrincipalName, CorrelationId = Guid.NewGuid() }, commandType: CommandType.StoredProcedure);
        return connection;
    }

    private sealed record TradeResult(long TransactionId, Guid CorrelationId, bool WasReplay, string ResultMessage);
    private sealed record AlertRow(long ComplianceAlertId, byte[] RowVersion);
}
