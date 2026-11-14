from fastapi import Request
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session
from sqlalchemy.pool import NullPool, StaticPool

from app.core.config import Settings


def make_engine(settings: Settings):
    url = settings.database_url.get_secret_value()
    kwargs = {"pool_pre_ping": True, "hide_parameters": True}
    if settings.runtime_mode == "serverless" and url.startswith("postgresql"):
        # Supabase's pooler owns the pool; don't keep one per ephemeral function instance.
        kwargs["poolclass"] = NullPool
        kwargs["connect_args"] = {"connect_timeout": 10}
    if url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False, "timeout": 30}
        if ":memory:" in url:
            kwargs["poolclass"] = StaticPool
    engine = create_engine(url, **kwargs)
    if engine.dialect.name == "sqlite":

        @event.listens_for(engine, "connect")
        def configure_sqlite(connection, _):
            connection.execute("PRAGMA foreign_keys=ON")

    return engine


def get_db(request: Request):
    with Session(request.app.state.engine, expire_on_commit=False) as session:
        yield session
