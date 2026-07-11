using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using WealthManagement.Application.Validation;

namespace WealthManagement.Api.Middleware;

public sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title, code) = exception switch
        {
            RequestValidationException => (StatusCodes.Status400BadRequest, "Request validation failed", "validation_failed"),
            BusinessRuleException => (StatusCodes.Status422UnprocessableEntity, "Business rule rejected the operation", "business_rule_rejected"),
            UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "Authentication is required", "unauthenticated"),
            AccessDeniedException => (StatusCodes.Status403Forbidden, "Access denied", "access_denied"),
            ResourceNotFoundException => (StatusCodes.Status404NotFound, "Resource not found", "not_found"),
            DuplicateOperationException => (StatusCodes.Status409Conflict, "Duplicate operation", "duplicate_operation"),
            ConcurrencyConflictException => (StatusCodes.Status409Conflict, "Concurrency conflict", "concurrency_conflict"),
            OperationCanceledException when httpContext.RequestAborted.IsCancellationRequested => (499, "Request cancelled", "request_cancelled"),
            SqlException => (StatusCodes.Status503ServiceUnavailable, "Database operation failed", "database_unavailable"),
            _ => (StatusCodes.Status500InternalServerError, "Unexpected server error", "unexpected_error")
        };

        if (status >= 500) logger.LogError(exception, "Request failed with code {ErrorCode}", code);
        else logger.LogWarning("Request failed with code {ErrorCode}: {Message}", code, exception.Message);

        var problem = new ProblemDetails
        {
            Status = status,
            Title = title,
            Type = $"https://errors.wealth-management.local/{code}",
            Detail = status >= 500 ? "The operation could not be completed. Use the correlation identifier when requesting support." : exception.Message,
            Instance = httpContext.Request.Path
        };
        problem.Extensions["code"] = code;
        problem.Extensions["correlationId"] = httpContext.Items[CorrelationIdMiddleware.ItemName]?.ToString();
        if (exception is RequestValidationException validation)
            problem.Extensions["errors"] = validation.Failures.GroupBy(x => x.Field).ToDictionary(x => x.Key, x => x.Select(y => new { y.Code, y.Message }).ToArray());

        httpContext.Response.StatusCode = status;
        await httpContext.Response.WriteAsJsonAsync(problem, cancellationToken);
        return true;
    }
}
