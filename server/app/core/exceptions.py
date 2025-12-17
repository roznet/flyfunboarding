"""
Custom exception classes and handlers for consistent error responses.
"""
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import logging

logger = logging.getLogger(__name__)


class APIError(Exception):
    """Base API error with status code and detail."""

    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)


class NotFoundError(APIError):
    """Resource not found (404)."""

    def __init__(self, resource: str, identifier: str):
        super().__init__(404, f"{resource} '{identifier}' not found")


class AuthenticationError(APIError):
    """Authentication failed (401)."""

    def __init__(self, detail: str = "Invalid Bearer Token"):
        super().__init__(401, detail)


class AuthorizationError(APIError):
    """Authorization failed (403)."""

    def __init__(self, detail: str = "Access denied"):
        super().__init__(403, detail)


def register_exception_handlers(app: FastAPI) -> None:
    """Register custom exception handlers for consistent error responses."""

    @app.exception_handler(APIError)
    async def api_error_handler(request: Request, exc: APIError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail, "status_code": exc.status_code},
        )

    @app.exception_handler(HTTPException)
    async def http_exception_handler(
        request: Request, exc: HTTPException
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail, "status_code": exc.status_code},
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        """Handle Pydantic validation errors with user-friendly messages."""
        errors = []
        for error in exc.errors():
            field = ".".join(str(x) for x in error["loc"][1:])  # Skip 'body' prefix
            errors.append(f"{field}: {error['msg']}")
        return JSONResponse(
            status_code=422,
            content={
                "detail": "; ".join(errors),
                "status_code": 422,
                "errors": exc.errors(),  # Include full error details for debugging
            },
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        """Catch-all for unexpected errors."""
        logger.exception("Unhandled exception", exc_info=exc)
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "status_code": 500},
        )

