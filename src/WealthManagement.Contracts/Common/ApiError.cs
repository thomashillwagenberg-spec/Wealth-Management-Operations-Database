namespace WealthManagement.Contracts.Common;

public sealed record ApiError(string Code, string Message, string? Field = null);
