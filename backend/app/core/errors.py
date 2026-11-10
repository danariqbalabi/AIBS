from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException


class ApiError(Exception):
    def __init__(self, status: int, code: str, message: str, *, retryable: bool = False):
        self.status = status
        self.code = code
        self.message = message
        self.retryable = retryable


def install_error_handlers(app: FastAPI) -> None:
    def response(request, status, code, message, fields=None, retryable=False):
        return JSONResponse(
            status_code=status,
            content={
                "error": {
                    "code": code,
                    "message": message,
                    "fields": fields or [],
                    "retryable": retryable,
                },
                "request_id": request.state.request_id,
            },
        )

    @app.exception_handler(ApiError)
    async def api_error(request: Request, exc: ApiError):
        return response(request, exc.status, exc.code, exc.message, retryable=exc.retryable)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError):
        # Do not reflect sensitive input values from Pydantic's full error dictionary.
        fields = [{"field": ".".join(map(str, e["loc"])), "type": e["type"]} for e in exc.errors()]
        return response(request, 422, "validation_error", "Periksa kembali isianmu.", fields)

    @app.exception_handler(HTTPException)
    async def http_error(request: Request, exc: HTTPException):
        codes = {404: "not_found", 405: "method_not_allowed", 401: "unauthorized"}
        return response(
            request,
            exc.status_code,
            codes.get(exc.status_code, "request_error"),
            "Permintaan tidak dapat diproses.",
        )
