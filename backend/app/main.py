import asyncio
import logging
from contextlib import asynccontextmanager, suppress
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1.analysis import router as analysis_router
from app.api.v1.auth import router as auth_router
from app.api.v1.catalog import router as catalog_router
from app.api.v1.drafts import router as draft_router
from app.api.v1.history import router as history_router
from app.api.v1.media import router as media_router
from app.api.v1.planning import router as planning_router
from app.api.v1.privacy import router as privacy_router
from app.api.v1.profiles import router as profile_router
from app.api.v1.summaries import router as summary_router
from app.core.auth import JWTVerifier
from app.core.config import Settings, get_settings
from app.core.database import make_engine
from app.core.errors import ApiError, install_error_handlers
from app.integrations.gemini import Gemini
from app.integrations.storage import SupabaseStorage
from app.services.privacy import cleanup_expired


def create_app(settings: Settings | None = None, *, engine=None) -> FastAPI:
    settings = settings or get_settings()
    database_engine = engine if engine is not None else make_engine(settings)

    @asynccontextmanager
    async def lifespan(app):
        async def retention():
            while True:
                try:
                    await asyncio.to_thread(cleanup_expired, database_engine, app.state.storage)
                except Exception:
                    logging.getLogger(__name__).warning("Photo retention cleanup will retry")
                await asyncio.sleep(900)

        task = asyncio.create_task(retention())
        try:
            yield
        finally:
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task
        if engine is None:
            database_engine.dispose()

    app = FastAPI(title="AIBS API", version="0.1.0", lifespan=lifespan)
    app.state.settings = settings
    app.state.engine = database_engine
    app.state.jwt_verifier = JWTVerifier(str(settings.supabase_url))
    app.state.demo_attempts = {}
    app.state.storage = SupabaseStorage(settings)
    app.state.gemini = Gemini(settings)
    app.include_router(auth_router)
    app.include_router(profile_router)
    app.include_router(privacy_router)
    app.include_router(catalog_router)
    app.include_router(draft_router)
    app.include_router(history_router)
    app.include_router(planning_router)
    app.include_router(media_router)
    app.include_router(analysis_router)
    app.include_router(summary_router)
    install_error_handlers(app)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
    )

    @app.middleware("http")
    async def request_id(request: Request, call_next):
        request.state.request_id = str(uuid4())
        response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.request_id
        return response

    @app.get("/health", tags=["operations"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/ready", tags=["operations"])
    def ready() -> dict[str, str]:
        try:
            with database_engine.connect() as connection:
                connection.execute(text("SELECT 1"))
        except Exception as exc:
            raise ApiError(
                503, "database_unavailable", "Layanan belum siap.", retryable=True
            ) from exc
        return {"status": "ready"}

    return app
