"""Custom error classes for DrSAI."""


class DrSAIError(Exception):
    """Base exception for DrSAI errors."""

    def __init__(self, message: str, code: str = "DRSAI_ERROR"):
        self.message = message
        self.code = code
        super().__init__(message)


class ConfigurationError(DrSAIError):
    """Configuration-related errors."""

    def __init__(self, message: str):
        super().__init__(message, code="CONFIGURATION_ERROR")


class GenerationError(DrSAIError):
    """Content generation errors."""

    def __init__(self, message: str):
        super().__init__(message, code="GENERATION_ERROR")


class ValidationError(DrSAIError):
    """Validation errors (meter, rhyme, quality)."""

    def __init__(self, message: str):
        super().__init__(message, code="VALIDATION_ERROR")


class InputError(DrSAIError):
    """User input validation errors."""

    def __init__(self, message: str):
        super().__init__(message, code="INPUT_ERROR")


class TimeoutError(DrSAIError):
    """Request timeout errors."""

    def __init__(self, message: str = "Request timed out"):
        super().__init__(message, code="TIMEOUT_ERROR")


class RateLimitError(DrSAIError):
    """Rate limit exceeded errors."""

    def __init__(self, message: str = "Rate limit exceeded", retry_after: int = 60):
        super().__init__(message, code="RATE_LIMITED")
        self.retry_after = retry_after
