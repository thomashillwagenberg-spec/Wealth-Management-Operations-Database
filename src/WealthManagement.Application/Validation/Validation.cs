namespace WealthManagement.Application.Validation;

public sealed record ValidationFailure(string Field, string Code, string Message);

public sealed class ValidationResult
{
    public static readonly ValidationResult Success = new(Array.Empty<ValidationFailure>());

    public ValidationResult(IReadOnlyList<ValidationFailure> failures) => Failures = failures;

    public IReadOnlyList<ValidationFailure> Failures { get; }
    public bool IsValid => Failures.Count == 0;
}

public interface IRequestValidator<in T>
{
    ValidationResult Validate(T request);
}

public sealed class RequestValidationException : Exception
{
    public RequestValidationException(IReadOnlyList<ValidationFailure> failures)
        : base("The request did not pass validation.") => Failures = failures;

    public IReadOnlyList<ValidationFailure> Failures { get; }
}

public sealed class AccessDeniedException : Exception
{
    public AccessDeniedException(string message) : base(message) { }
}

public sealed class ResourceNotFoundException : Exception
{
    public ResourceNotFoundException(string message) : base(message) { }
}

public sealed class ConcurrencyConflictException : Exception
{
    public ConcurrencyConflictException(string message) : base(message) { }
}

public sealed class DuplicateOperationException : Exception
{
    public DuplicateOperationException(string message) : base(message) { }
}

public sealed class BusinessRuleException : Exception
{
    public BusinessRuleException(string message) : base(message) { }
}
