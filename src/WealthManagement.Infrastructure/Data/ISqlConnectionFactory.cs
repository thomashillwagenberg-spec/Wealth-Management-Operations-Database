using Microsoft.Data.SqlClient;

namespace WealthManagement.Infrastructure.Data;

public interface ISqlConnectionFactory
{
    Task<SqlConnection> OpenAsync(CancellationToken cancellationToken);
}
