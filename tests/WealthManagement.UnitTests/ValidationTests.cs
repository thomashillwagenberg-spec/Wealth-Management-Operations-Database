using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Compliance;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.UnitTests;

public sealed class ValidationTests
{
    [Fact]
    public void Trade_validator_accepts_a_well_formed_synthetic_trade()
    {
        var request = new SubmitTradeRequest(1, "BUY", 1, new DateOnly(2026,7,10), new DateOnly(2026,7,11), 10, 100, 0, "UNIT-001", "unit-test-key-000001", null);
        Assert.True(new SubmitTradeRequestValidator().Validate(request).IsValid);
    }

    [Fact]
    public void Trade_validator_rejects_oversized_and_nonpositive_values()
    {
        var request = new SubmitTradeRequest(0, "WIRE", 0, new DateOnly(2026,7,11), new DateOnly(2026,7,10), -1, 0, -1, "bad ref!", "short", new string('x', 251));
        var result = new SubmitTradeRequestValidator().Validate(request);
        Assert.False(result.IsValid);
        Assert.Contains(result.Failures, x => x.Field == "settlementDate");
        Assert.Contains(result.Failures, x => x.Field == "idempotencyKey");
    }

    [Fact]
    public void Compliance_query_caps_page_size()
    {
        var result = new ComplianceAlertQueryValidator().Validate(new ComplianceAlertQuery(1, 101));
        Assert.Contains(result.Failures, x => x.Field == "pageSize");
    }

    [Fact]
    public void Row_version_must_be_exactly_eight_bytes()
    {
        var result = new UpdateComplianceAlertRequestValidator().Validate(new UpdateComplianceAlertRequest("RESOLVED", null, Convert.ToBase64String(new byte[7])));
        Assert.False(result.IsValid);
    }
}
