"""One error shape for every failure: {"error": {"code": "...", "message": "..."}}.

The app shows `message` to the user, so messages say what happened and what
to do, in plain words.
"""

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class AppError(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message


def not_found(what: str) -> AppError:
    return AppError(404, "not_found", f"{what} was not found.")


def forbidden(message: str = "Your role cannot do this.") -> AppError:
    return AppError(403, "forbidden", message)


def error_body(code: str, message: str, details: object = None) -> dict:
    body = {"error": {"code": code, "message": message}}
    if details is not None:
        body["error"]["details"] = details
    return body


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def app_error(_: Request, exc: AppError):
        return JSONResponse(error_body(exc.code, exc.message), status_code=exc.status_code)

    @app.exception_handler(StarletteHTTPException)
    async def http_error(_: Request, exc: StarletteHTTPException):
        return JSONResponse(error_body(f"http_{exc.status_code}", str(exc.detail)), status_code=exc.status_code)

    @app.exception_handler(RequestValidationError)
    async def validation_error(_: Request, exc: RequestValidationError):
        details = [{"field": ".".join(map(str, e["loc"][1:])), "problem": e["msg"]} for e in exc.errors()]
        return JSONResponse(
            error_body("invalid_request", "Some fields are missing or wrong.", details), status_code=422)
