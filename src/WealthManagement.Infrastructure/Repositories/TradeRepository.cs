using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using WealthManagement.Application.Abstractions;
using WealthManagement.Application.Validation;
using WealthManagement.Contracts.Trading;
using WealthManagement.Infrastructure.Data;

namespace WealthManagement.Infrastructure.Repositories;

public sealed class TradeRepository(ISqlConnectionFactory connectionFactory, Microsoft.Extensions.Options.IOptions<DatabaseOptions> options) : ITradeRepository
{
    private readonly int _timeout = options.Value.CommandTimeoutSeconds;

    public async Task<SubmitTradeResponse> SubmitAsync(SubmitTradeRequest request, string requestHash, CancellationToken cancellationToken)
    {
        await using var connection = await connectionFactory.OpenAsync(cancellationToken);
        try
        {
            return await connection.QuerySingleAsync<SubmitTradeResponse>(new CommandDefinition(
                "trading.usp_SubmitTrade",
                new
                {
                    request.IdempotencyKey,
                    RequestHash = requestHash,
                    request.AccountId,
                    request.TransactionTypeCode,
                    request.SecurityId,
                    request.TradeDate,
                    request.SettlementDate,
                    request.Quantity,
                    request.Price,
                    request.FeeAmount,
                    request.ExternalReference,
                    request.Notes
                },
                commandType: CommandType.StoredProcedure,
                commandTimeout: _timeout,
                cancellationToken: cancellationToken));
        }
        catch (SqlException ex) when (ex.Number is 52104 or 52105)
        {
            throw new DuplicateOperationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number == 51019 && ex.Message.Contains("unique", StringComparison.OrdinalIgnoreCase))
        {
            throw new DuplicateOperationException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number is 52103 or 52141)
        {
            throw new AccessDeniedException(ex.Message);
        }
        catch (SqlException ex) when (ex.Number is 51019 or 52106)
        {
            throw new BusinessRuleException(ex.Message);
        }
    }
}
