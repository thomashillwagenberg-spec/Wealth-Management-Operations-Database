using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Services;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Trading;

namespace WealthManagement.UnitTests;

public sealed class TradeServiceTests
{
    [Fact]
    public async Task Service_denies_an_account_outside_authorized_scope()
    {
        var service = new TradeService(new RecordingTradeRepository(), new DenyAccessRepository(), new SubmitTradeRequestValidator());
        var request = new SubmitTradeRequest(99,"BUY",1,new DateOnly(2026,7,10),new DateOnly(2026,7,11),1,10,0,"UNIT-ACCESS","unit-access-key-0001",null);
        await Assert.ThrowsAsync<AccessDeniedException>(() => service.SubmitAsync(request, CancellationToken.None));
    }

    [Fact]
    public async Task Service_normalizes_type_and_produces_a_sha256_hash()
    {
        var repository = new RecordingTradeRepository();
        var service = new TradeService(repository, new AllowAccessRepository(), new SubmitTradeRequestValidator());
        var request = new SubmitTradeRequest(1," buy ",1,new DateOnly(2026,7,10),new DateOnly(2026,7,11),1,10,0,"UNIT-HASH","unit-hash-key-00001",null);
        await service.SubmitAsync(request, CancellationToken.None);
        Assert.Equal("BUY", repository.Request!.TransactionTypeCode);
        Assert.Matches("^[A-F0-9]{64}$", repository.Hash!);
    }

    private sealed class RecordingTradeRepository : ITradeRepository
    {
        public SubmitTradeRequest? Request { get; private set; }
        public string? Hash { get; private set; }
        public Task<SubmitTradeResponse> SubmitAsync(SubmitTradeRequest request, string requestHash, CancellationToken cancellationToken)
        {
            Request=request; Hash=requestHash;
            return Task.FromResult(new SubmitTradeResponse(1,Guid.NewGuid(),false,"ok"));
        }
    }
    private sealed class AllowAccessRepository : IAccessControlRepository { public Task<bool> CanAccessClientAsync(int clientId,CancellationToken ct)=>Task.FromResult(true); public Task<bool> CanAccessAccountAsync(int accountId,CancellationToken ct)=>Task.FromResult(true); public Task<bool> CanAccessAdvisorAsync(int advisorId,CancellationToken ct)=>Task.FromResult(true); }
    private sealed class DenyAccessRepository : IAccessControlRepository { public Task<bool> CanAccessClientAsync(int clientId,CancellationToken ct)=>Task.FromResult(false); public Task<bool> CanAccessAccountAsync(int accountId,CancellationToken ct)=>Task.FromResult(false); public Task<bool> CanAccessAdvisorAsync(int advisorId,CancellationToken ct)=>Task.FromResult(false); }
}
