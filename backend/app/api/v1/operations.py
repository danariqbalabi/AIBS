from secrets import compare_digest

from fastapi import APIRouter, Request

from app.core.errors import ApiError
from app.services.privacy import cleanup_expired

router = APIRouter()


@router.get("/api/internal/retention", include_in_schema=False)
def retention(request: Request):
    secret = request.app.state.settings.cron_secret
    if secret is None:
        raise ApiError(503, "cron_not_configured", "Pembersihan terjadwal belum dikonfigurasi.")
    expected = "Bearer " + secret.get_secret_value()
    actual = request.headers.get("authorization", "")
    if not compare_digest(actual.encode(), expected.encode()):
        raise ApiError(401, "unauthorized", "Akses ditolak.")
    result = cleanup_expired(request.app.state.engine, request.app.state.storage)
    if result["failed"]:
        raise ApiError(
            503,
            "retention_incomplete",
            "Sebagian pembersihan foto perlu dicoba kembali.",
            retryable=True,
        )
    return result
